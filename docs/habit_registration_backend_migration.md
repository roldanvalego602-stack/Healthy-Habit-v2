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
