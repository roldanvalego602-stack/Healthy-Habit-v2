# Migración de operaciones de hábitos a Firebase Admin

## Estado actual (sin despliegue)

Flutter ejecuta transacciones del cliente en:
- `lib/páginas/habitos/habit_action_service.dart`: activación y cancelación.
- `lib/páginas/habitos/registrar_habito_screen.dart`: registros,
  XP, niveles, rachas, monedas y evidencias temporales.

La candidata `firestore.candidate.rules` permite a propietarios escribir
`users/{uid}/user_habits/**` y determinados campos de perfil. Por tanto,
ni `latestStatus`, ni `progress`, ni recompensas almacenadas pueden
considerarse verificadas de forma independiente.

## Primera etapa implementada

`previewOfficialHabitRegistration` es un callable autenticado y
**exclusivamente de lectura**. Consulta el hábito y el intento bajo el
UID del token del usuario y rechaza IDs ajenos al catálogo oficial,
identificadores con rutas, intentos finalizados o cancelados,
progreso inválido y objetivos completos.

La lógica pura vive en `functions/habit_registration_policy.js` y
tiene cuatro pruebas en `functions/tests/habit_registration_policy.test.js`.

**Limitaciones:** la consulta lee documentos que el cliente actual puede
alterar. No autentica que ocurrió una actividad, no verifica fotos, no
concede XP, no registra hábitos y **no habilita la publicación de
popularidad**. La aplicación sigue usando los flujos existentes.

## Segundo paso: piloto transaccional aislado (solo emulador)

La función `registerDemoOfficialHabit` está disponible **únicamente** cuando
`FUNCTIONS_EMULATOR=true` y `GCLOUD_PROJECT=demo-healthy-habit`.

El código transaccional está en `functions/habit_registration_transaction.js`.
La primera versión del piloto habilitó exclusivamente `hidr_001` (agua al despertar).
El alcance actualizado con dos hábitos adicionales se detalla en el sexto paso.
El objetivo, la frecuencia y el premio de **10 XP por registro sin evidencia**
se definen en el servidor, nunca en la petición.

La operación utiliza:
- Un `operationId` único por registro (16 a 128 caracteres ASCII
  alfanuméricos, guion o guion bajo), que puede repetirse de forma segura
  por un reintento de red. Cada operación guardada tiene respuesta estable.
- Una marca `registration_days/YYYY-MM-DD` por intento y día UTC para
  impedir un segundo registro con otro ID el mismo día. Esto es un
  **criterio de prueba**, no la política horaria definitiva de Flutter.
- Una transacción del Admin SDK con lectura previa de usuario, hábito,
  intento, operación y día; después se escriben registro, progreso,
  finalización, XP y monedas por nivel conjuntamente.
- Umbrales de niveles y recompensas basados en `LevelSystem` y los valores
  del flujo actual. No se aceptan fotografías, XP, monedas ni objetivos
  enviados por el cliente.

Los archivos `functions/tests/habit_registration_transaction.test.js`
incluyen ocho pruebas unitarias adicionales: idempotencia, límites diarios,
finalización, cambios de nivel, operaciones malformadas y rechazo de intentos
cancelados.

**Limitaciones importantes:** el piloto no maneja la racha local, tiempos
de gracia, recuperación de hábitos, verificación de imágenes ni migraciones
de datos. Sus datos iniciales en el emulador todavía pueden ser escritos
por los propietarios bajo las reglas candidatas. Por eso no está listo
para usuarios reales, no debe sustituir el flujo Flutter y **no habilita
estadísticas públicas verificadas**.

## Pruebas de integración de Firestore (tercer paso)

Se añadió `functions/tests/habit_registration.integration.js`,
que utiliza Firestore Admin SDK contra **Firestore Emulator real**, no un
repositorio simulado. Estas pruebas no se ejecutan en `npm test` para evitar
dependencias accidentales de emuladores durante las pruebas unitarias.

Desde la raíz del repositorio, con Java, Firebase CLI y dependencias
de `functions` instaladas:

```bash
firebase emulators:exec --config firebase.emulator.json \
  --project demo-healthy-habit --only firestore \
  "cd functions && npm run test:integration"
```

Verifica: commit y reintento del mismo ID, dos registros simultáneos
con identificadores diferentes el mismo día, peticiones simultáneas
del mismo ID, finalización/cambio de nivel y separación de datos
entre usuarios. Los usuarios de prueba son exclusivos para cada caso.
El archivo aborta si no detecta Firestore Emulator y el proyecto demo.

**Sin despliegue, sin modificación a Flutter y sin publicación global.**
Una validación verde de la transacción no reemplaza la revisión de reglas
de producción ni garantiza que el cliente actual no pueda adulterar
estados que aún se escriben directamente desde Flutter.

## Cuarto paso: paridad del catálogo oficial y reglas de frecuencia

`functions/official_habit_catalog.js` refleja los **36 hábitos oficiales** de
`lib/páginas/habitos/catalogo.dart` (24 diarios y 12 semanales).
El catálogo de servidor incluye título, categoría, dificultad, objetivo,
registros por periodo, duración, requisitos de nivel, XP de referencia,
repetibilidad, descanso y periodos de gracia. Las pruebas en
`functions/tests/official_habit_catalog.test.js` comparan ambos catálogos
para detectar futuras divergencias.

`functions/habit_period_policy.js` incluye la función pura que identifica
el día UTC o una semana ISO iniciada en lunes, y valida el número
máximo de registros por periodo. Tiene pruebas en
`functions/tests/habit_period_policy.test.js`.

**Restricción deliberada:** conocer los 36 hábitos NO significa habilitar
todas sus escrituras. El sexto paso documenta los tres hábitos del piloto.
Los contadores transaccionales cubren sus límites de frecuencia, pero aún
falta reconciliar registros históricos y definir zonas horarias,
tolerancias, periodos perdidos y repeticiones.

El catálogo y la política de periodos son preparación **sin despliegue**.
La aplicación Flutter y las reglas de producción permanecen intactas.

## Quinto paso: contador transaccional por periodo

El piloto `registerDemoOfficialHabit` usa ahora la función de claves de
`habit_period_policy.js` dentro de la transacción de Firestore Admin.
Cada intento mantiene un documento
`registration_periods/{day_YYYY-MM-DD|week_YYYY-MM-DD}` con el conteo
de ese periodo. La lectura, el control del límite y la escritura del
contador ocurren junto con la operación idempotente, el registro, el
progreso y las recompensas, en **una sola transacción**.

Se sigue escribiendo y comprobando `registration_days/YYYY-MM-DD`
en el piloto diario para no aceptar dos registros en el mismo día
cuando existen marcas heredadas anteriores a los contadores nuevos.

Se añadieron tres pruebas unitarias y tres pruebas de integración contra
Firestore Emulator sobre el cambio de día, el bloqueo de marcas
heredadas y las peticiones concurrentes. Ejecutar:

```bash
cd functions && npm test && cd ..
firebase emulators:exec --config firebase.emulator.json \
  --project demo-healthy-habit --only firestore \
  "cd functions && npm run test:integration"
```

**Histórico:** hasta el quinto paso, el habilitado estaba limitado a
`hidr_001`. El sexto paso amplía la lista a tres hábitos experimentales. El periodo UTC es exclusivamente una
simplificación experimental y no sustituye la fecha local del usuario,
los periodos de gracia, las rachas, ni la reconciliación histórica.
Nunca desplegar esta prueba como registro funcional de producción.

## Sexto paso: varios registros por periodo en el piloto

La lista de escritura del callable de emulador admite ahora **tres hábitos**:

- `hidr_001`: beber agua al despertar, 1 registro/día UTC; mantiene
  también su marca de compatibilidad `registration_days`.
- `bien_007`: rutina diaria de bienestar, 2 registros/día UTC.
- `alim_004`: planificar mis comidas, 3 registros/semana ISO UTC.

Para los dos hábitos nuevos, cada registro crea su propio log y una
operación idempotente, pero **solo aumenta** `registration_periods/{key}.count`.
No se crea una marca `registration_days`, porque impediría correctamente
el segundo registro del mismo día. La transacción valida y actualiza
el contador, los datos del intento y las recompensas de forma atómica.

Se añadieron cinco pruebas unitarias y tres de integración para
comprobar exactamente los límites, el reinicio de periodos y las
solicitudes concurrentes. Ejecutarlas con `npm test` y
`npm run test:integration` dentro del emulador, como se explica arriba.

**Limitaciones:** solo demo y emulador. El límite se calcula respecto
al día UTC y la semana ISO (lunes UTC), no a la zona local. Aún no se
verifica la distribución de registros durante el periodo, la duración,
los días de gracia, las rachas ni las evidencias. No deben habilitarse
otros hábitos ni considerarse confiable la popularidad global hasta
completar esas condiciones y bloquear las escrituras cliente.

## Séptimo paso: calendario IANA, rachas y tolerancias (piloto)

`functions/habit_calendar_policy.js` determina días civiles y semanas ISO
en una zona IANA explícita (por ejemplo `America/Monterrey`) usando
`Intl.DateTimeFormat`. No utiliza el huso horario del dispositivo cliente.
Las pruebas incluyen medianoche UTC, horario de verano, semanas que
cruzan el año, periodos omitidos y fechas inválidas.

El piloto de escritura admite `calendarTimeZone` en el documento del
**intento**. Cuando es distinto de `UTC`, exige que el mismo valor
esté presente en el documento de usuario y en el hábito. No acepta
la zona desde `request.data`. Los intentos antiguos sin zona explícita
permanecen en UTC para no cambiar silenciosamente sus contadores;
en particular `hidr_001` conserva las marcas de día heredadas y no
acepta todavía una zona distinta de UTC.

Cada intento mantiene una racha de **periodos completados**, separada de
la racha global actual de Flutter:
- `periodStreak`: incrementa solo cuando el contador del periodo
  alcanza el cupo del catálogo (1, 2 o 3 registros del piloto).
- `lastCompletedPeriod`: clave del último periodo completado.
- `gracePeriodsUsed`: número acumulado de periodos omitidos tolerados
  por el piloto, solo informativo; no entrega XP ni monedas.
- La tolerancia `gracePeriods` viene del catálogo; si se omiten más
  periodos que los tolerados, la racha del intento se reinicia a uno.

Los tres campos se actualizan con la transacción que concede XP por
registro, sin recompensar adicionalmente una tolerancia o completar el
periodo. **No se aplica ningún cambio a `currentStreak` o
`lastStreakDate` del perfil**, porque aún falta conciliar la semántica
de racha global de Flutter.

Las nuevas pruebas están en
`functions/tests/habit_calendar_policy.test.js`, en el conjunto unitario
de transacciones y en `functions/tests/habit_registration.integration.js`.

**Corrección de pruebas del séptimo paso:** `bien_007` es un hábito
**difícil** y dispone de `gracePeriods: 0`, por lo que una racha
interrumpida debe reiniciarse. `alim_004` es **moderado** y dispone de
`gracePeriods: 1`; las pruebas de gracia deben usar este hábito y
completar sus tres registros semanales. La lógica del servidor no se
modificó: se corrigieron las expectativas de las pruebas.

**Límite de seguridad:** los documentos actuales de hábitos, intentos
y perfil pueden ser escritos desde el cliente según las reglas
candidatas. El bloqueo de zona se realiza como validación de consistencia,
**no como garantía criptográfica de integridad**. Para producción deberá
fijarse la zona mediante una operación administrada, manejar cambios de
zona con un procedimiento de migración y proteger los campos de rachas
y economía con reglas revisadas. El piloto solo se ejecuta en el
emulador con proyecto demo; no publicarlo en producción.

## Octavo paso: fijación transaccional del calendario (solo emulador)

Se añadió `functions/habit_calendar_activation.js` y la callable
`lockDemoHabitCalendar`, accesible **solo** cuando
`FUNCTIONS_EMULATOR=true` y `GCLOUD_PROJECT=demo-healthy-habit`.

Petición autenticada: `{habitId, attemptId, timeZone}`. Admite
exclusivamente `bien_007` y `alim_004` del piloto y una zona IANA
válida. Su transacción de Admin SDK lee perfil, hábito e intento y fija
`calendarTimeZone` en los tres documentos con el mismo valor. Repetir
la petición con idéntica zona devuelve `alreadyConfigured: true`.
Si existe otra zona, rechaza la operación sin sobrescribirla.

Para bloquear un calendario nuevo se requiere intento activo sin
progreso, XP acumulado, racha ni historial de gracia. No se migra
ningún registro previo. Además, el registro experimental ahora
**rechaza el UTC implícito** cuando alguna de las tres entidades
ya dispone de un calendario explícito diferente. `hidr_001`
conserva UTC y las marcas históricas del piloto.

Pruebas: `functions/tests/habit_calendar_activation.test.js` para
validación e idempotencia, además de pruebas de integración sobre
la activación, la protección de historiales y dos peticiones de
zonas distintas concurrentes.

**Advertencia:** esta es una comprobación transaccional experimental,
NO un bloqueo de seguridad de los documentos frente al cliente.
Las reglas candidatas todavía permiten alterar datos de perfil e
intentos desde Flutter. Antes de producción habrá que mover también
la activación y mutación de hábitos al servidor, restringir reglas y
auditar cambios de calendario para evitar reiniciar contadores
ilegítimamente. No se modificó el cliente Flutter ni se desplegaron
reglas.

## Noveno paso: activación por Admin SDK (solo emulador)

`functions/habit_activation_transaction.js` implementa
`activateDemoHabit`, disponible también mediante la callable
`activateDemoOfficialHabit` **solo** si
`FUNCTIONS_EMULATOR=true` y `GCLOUD_PROJECT=demo-healthy-habit`.

La petición autenticada `{habitId,attemptId,operationId}` admite únicamente
`hidr_001`, `bien_007` y `alim_004`. Los identificadores deben
ser únicos e idempotentes (16–128 caracteres). No se reciben XP,
costes, requisitos, progreso ni propiedades del hábito desde el cliente.

En una transacción de Admin SDK se leen perfil, hábito, intento nuevo,
intento anterior, consulta de hábitos activos y operación idempotente.
Se validan espacios, desbloqueo por nivel, saldo, repetibilidad,
enfriamiento y estado del último intento; después se crea el intento,
actualiza el índice de hábito y el contador de mutaciones del perfil,
y guarda la operación de activación. La consulta de hábitos activos
utiliza `latestStatus == inProgress` como en el esquema existente.

Para los pilotos `bien_007` y `alim_004` se copia el calendario de
perfil a hábito e intento al activar. La activación heredada de
`hidr_001` sigue en UTC. Esto permite comprobar la compatibilidad
de la activación y el primer registro en el emulador, pero todavía
no constituye una migración de perfiles reales.

Se añadieron pruebas unitarias en
`functions/tests/habit_activation_transaction.test.js` y
cuatro pruebas de integración adicionales: reintentos, competencia
por el último espacio, nivel insuficiente y primer registro con
el mismo calendario.

**Riesgos pendientes:** los campos de economía y de estado aún son
escribibles por clientes bajo las reglas candidatas. Las validaciones
de nivel, espacios y estado del servidor no pueden considerarse
confiables en producción hasta migrar cancelación, registro y
activación junto con reglas revisadas. Esta funcionalidad no se usa
desde Flutter y no debe desplegarse como una activación pública.

## Décimo paso: cancelación transaccional con confirmación de penalización

`functions/habit_cancellation_transaction.js` implementa el piloto
`cancelDemoHabit`, publicado solo en el emulador como
`cancelDemoOfficialHabit` cuando se ejecuta `demo-healthy-habit`
con `FUNCTIONS_EMULATOR=true`.

La petición autenticada acepta exclusivamente
`{habitId, attemptId, operationId, maxPenalty}` y solo los tres
hábitos permitidos. `maxPenalty` es la cantidad máxima de Habit Coins
que el usuario confirmó en pantalla (**0 a 25**, obligatoria). El
servidor calcula la penalización real sin aceptar importes del
cliente: hábitos difíciles `min(saldo, 25)`; moderados y sencillos
**0 Habit Coins**. Si el saldo cambió y el cobro calculado excede lo
confirmado, se rechaza toda la operación.

En una sola transacción Admin SDK se comprueban la operación
idempotente, el usuario, el hábito y su intento activo. Se guardan
`cancelled`, `cancelledAt`, `cancellationPenalty`, los estados
del hábito, el nuevo saldo, la versión del perfil y la operación
idempotente. Los reintentos con el mismo ID devuelven el resultado
guardado sin volver a cobrar. Dos IDs concurrentes no pueden
cancelar el mismo intento dos veces.

Las pruebas cubren penalizaciones, límites confirmados, reintentos,
cancelación moderada sin cobro, competencia concurrente y rechazo
de registros tras cancelar. Ejecutar suites unitarias y de integración
en el emulador como en los pasos anteriores.

**Importante:** el cliente Flutter todavía usa su propia cancelación
y las reglas candidatas permiten escrituras directas. Aunque la
transacción de Admin SDK impide los cobros duplicados dentro del
piloto, esto **no constituye seguridad de producción**. Falta
reconciliar flujos de Flutter, reglas Firestore y permisos de escritura
en un mismo despliegue controlado.

## Undécimo paso: reglas estrictas aisladas y auditoría de compatibilidad

Se añadió **`firestore.strict-habits.rules`**, derivado de la candidata,
como un escenario estricto **separado** para Firestore Emulator. Ni
`firebase.json` ni `firebase.emulator.json` se modificaron. El
archivo `firebase.strict-habits.emulator.json` selecciona exclusivamente
esta variante. No desplegarla todavía.

### Cambios de autorización en el escenario estricto

- `users/{uid}`: el propietario conserva lectura y edición de datos
  personales básicos y cosméticos permitidos, pero no puede cambiar
  `xp`, `currentXp`, `level`, `habitCoins`, `habitSlots`,
  `habitMutationVersion`, rachas, calendario ni inventario. La
  eliminación del perfil queda bloqueada para impedir restablecer saldos
  mediante borrado y recreación.
- `users/{uid}/user_habits/{path=**}`: el propietario puede leer,
  pero no crear, modificar ni eliminar hábitos, intentos, logs y
  contadores. Solo Admin SDK podrá mantenerlos en esta variante.
- `users/{uid}/achievements/{path=**}`: lectura del propietario;
  sin escritura cliente para premios.
- `public_profiles/{uid}`: los campos de XP, nivel, rachas, hábitos
  completados y predicciones de logro quedan inmóviles frente a
  actualizaciones del propietario. Las altas nuevas solo permiten
  métricas iniciales nulas y prohíben estadísticas de nivel/logro
  inventadas. La eliminación también queda bloqueada.
- Las subcolecciones `habit_activation_operations`,
  `habit_cancellation_operations` y `registration_operations`
  no reciben permisos de escritura cliente; siguen controladas por
  el servidor.

### Compatibilidad pendiente con Flutter

Estas reglas **romperían intencionalmente** operaciones actuales:
activación/cancelación por `HabitActionService`, registro desde
`registrar_habito_screen.dart`, compra desde la tienda y actualización
de XP/rachas/recompensas y estadísticas públicas por el cliente.
Las compras de la tienda necesitan una API de servidor y pruebas
antifraude antes de activar esta variante. Las reglas sociales,
lecturas de hábitos, cosméticos ya adquiridos, creación inicial de
perfil y cambios básicos de datos personales mantienen su estructura.

La suite `tests/firestore/strict_habits.test.cjs` contiene nueve
pruebas de acceso, falsificación de progreso, economía, premios,
métricas públicas, operaciones privadas y compatibilidad de lecturas
y personalización. Ejecutar **por separado** desde la raíz:

```bash
firebase emulators:exec \
  --config firebase.strict-habits.emulator.json \
  --project demo-healthy-habit-strict \
  --only firestore \
  "cd tests/firestore && npm run test:strict"
```

Este entorno utiliza otro proyecto demo y otras reglas; **no mezclar**
con las pruebas anteriores `tests/firestore/rules.test.cjs`.
Aunque pasen todas las pruebas, eso no autoriza un despliegue:
faltan migrar la tienda, los flujos directos de Flutter, y la fuente
del ranking público. Las reglas estrictas son una especificación
ejecutable de la seguridad deseada, no todavía una configuración
lista para producción.

## Duodécimo paso: compras idempotentes con Admin SDK (solo emulador)

Se añade `functions/official_shop_catalog.js` con los **20 artículos**
del catálogo actual de `lib/páginas/tienda/shop_service.dart`:
**18 artículos pagados y dos gratuitos** (`sunglasses`, `bandana`).
El catálogo del servidor es la fuente de precios para la transacción;
`functions/tests/shop_purchase_transaction.test.js` comprueba
automáticamente su paridad con la declaración de Flutter.

`functions/shop_purchase_transaction.js` implementa
`purchaseDemoShopItem`, publicado como callable del mismo nombre
**solo en Functions Emulator y proyecto demo-healthy-habit**.
Petición: `{itemId, operationId}` (identificador de operación de
16–128 caracteres). No recibe precios, saldos ni inventarios del
cliente. Rechaza artículos gratuitos, duplicados, inventarios
inválidos y saldos insuficientes.

La transacción lee el perfil y la operación idempotente,
valida precio y estado del inventario y escribe conjuntamente
`users/{uid}.habitCoins`, `shopInventory` y
`shop_purchase_operations/{operationId}`. Un reintento con la
misma operación y artículo devuelve el resultado guardado.
Solicitudes simultáneas no deben poder gastar más saldo del
disponible ni adquirir dos veces el mismo artículo. El propietario
únicamente recibe sus propios cambios.

**Semántica de `streak_guard`:** Flutter actualmente lo representa
en el inventario como artículo único. El piloto replica esa
semántica y **no habilita consumos, recargas ni protección de rachas**
hasta definir un sistema separado de consumibles.

Se agregaron ocho pruebas unitarias de catálogo, compras y casos
malformados, cinco pruebas de integración en el emulador sobre
idempotencia, concurrencia, falta de saldo e aislamiento de usuario,
y una comprobación adicional a las reglas estrictas que prohíbe
que el cliente cree documentos `shop_purchase_operations`.

Comandos de validación desde la raíz del repositorio:

```bash
cd functions && npm test && cd ..
firebase emulators:exec --config firebase.emulator.json \
  --project demo-healthy-habit --only firestore \
  "cd functions && npm run test:integration"
firebase emulators:exec --config firebase.strict-habits.emulator.json \
  --project demo-healthy-habit-strict --only firestore \
  "cd tests/firestore && npm run test:strict"
```

**No desplegar:** `ShopService.buy` todavía escribe directamente
en Firestore, y la tienda actual sigue utilizando las reglas
candidatas. El callable del piloto no se conecta a Flutter y
se deshabilita fuera del emulador. Para producción hará falta
migrar el cliente y todas las otras vías de escritura de economía,
revisar el canje de consumibles y coordinar el despliegue de
reglas estrictas en la misma versión.

## Siguientes requisitos para una operación de escritura confiable

1. Versionar el catálogo oficial en el servidor como fuente autorizada
   de IDs, objetivos, dificultad, desbloqueos y penalizaciones. No
   confiar en los datos del hábito enviados por el cliente.
2. Introducir una transacción de Admin SDK para activar, cancelar y
   registrar, con control de idempotencia (ID único de operación),
   validación de estado, límites y cupos; no repetir una recompensa.
3. Calcular XP, monedas, niveles y rachas exclusivamente en el servidor,
   sin aceptar importes de la petición. Fijar reglas sobre el huso horario,
   frecuencia y número de registros por periodo.
4. Tratar el contenido de la imagen como evidencia pendiente de
   comprobación, no como verificación de actividad; regular tamaño,
   acceso y caducidad de su almacenamiento.
5. Crear pruebas integrales en emulador para registros repetidos,
   solicitudes concurrentes, cancelaciones, accesos de terceros,
   manipulación de XP y monedas, y migración de intentos existentes.
6. Cambiar los clientes Flutter a los callables nuevos y bloquear
   **en la misma entrega** las escrituras directas sobre estados,
   registros y economía mediante reglas revisadas y desplegadas.
7. Reconciliar datos históricos y solo entonces habilitar la creación
   de agregados de popularidad con una política de privacidad adecuada.

No desplegar `firestore.candidate.rules` en producción: actualmente
incluye políticas vulnerables de economía y se destina únicamente al
emulador de pruebas.
