# Plan de cierre de seguridad Firestore — Healthy Habit (Spark)

Estado: BORRADOR DE AUDITORÍA, NO DESPLEGADO. Fecha: 2026-11-19.
Firebase project: `cloud-firestore-d8c61`. No Cloud Functions desplegadas (`firebase functions:list`).
La consola tiene una regla final `match /{document=**} { allow read, write: if request.auth != null; }` que invalida de hecho las restricciones del propietario. **No publicar reglas nuevas sin pruebas de regresión.**

## Hallazgos del código actual

1. `lib/páginas/ranking_screen.dart` consulta `users.orderBy('xp').limit(100)`; también `AmigosServicio.perfiles` consulta directamente documentos de `users` de otras cuentas. Cualquier `allow list` de `users` expone documentos completos, incluyendo configuraciones privadas.
2. `lib/páginas/perfil/amigos_servicio.dart` escribe en dos cuentas en un batch (`solicitudes`, `solicitudes_enviadas`, `following`, `followers`). Es necesario modelar permisos bidireccionales y comprobar transacciones de aceptación.
3. `lib/páginas/habitos/registrar_habito_screen.dart` incrementa XP, monedas, niveles y rachas directamente desde Flutter. Por lo tanto cualquier regla que permita al propietario cambiar estos campos le permite fabricar progresos con un cliente adulterado, incluso si hay condiciones de incremento.
4. `lib/páginas/tienda/shop_service.dart` compra desde el cliente mediante transacción que descuenta `habitCoins` y agrega `shopInventory`; también equipa `shopEquipped`.
5. `temporary_habit_evidence` guarda una imagen base64 dentro de documentos privados de Firestore y debe ser estrictamente de propietario. El vencimiento lógico a las 24 horas no es una garantía de borrado físico.
6. `/system/**` no debe ser escribible por cualquier usuario autenticado; deben identificarse los consumidores y decidir quién administra esos documentos.
7. `functions/index.js` contiene `adjustHabitCoins` administrativa y otras funciones, pero no están desplegadas. En Spark solo se pueden probar con el emulador; no depender de ellas en el móvil de producción.

## Arquitectura objetivo

- `users/{uid}`: perfil privado (correo, preferencias, economía, inventario, datos sensibles); sólo propietario puede leer su documento, y sus escrituras requieren campos permitidos.
- `public_profiles/{uid}`: nombre de pantalla, avatar, XP/nivel publicables. Es necesario migrar ranking, búsquedas, fichas públicas y seguidores ANTES de denegar consultas a `users`. Crear copia pública desde cliente **no garantiza que el ranking sea íntegro**: para un ranking de confianza se necesita un componente autoritativo o calificarlo como demostración.
- Subcolecciones de hábitos, intentos, logs, chat y evidencias: sólo propietario, con validación de tamaños/tipos sensibles cuando corresponda.
- Relaciones sociales: reglas por documento para solicitudes, seguimiento y aceptación; probar con dos cuentas. El bloqueo y las invitaciones todavía requieren modelar su esquema.
- `system/**`: lectura específica y escritura por un rol verificable o backend; no permitir edición indiscriminada.
- `match /{document=**}`: deny-all sin excepciones.

## Plan de migración sin interrupciones

1. Conservar una copia versionada de las reglas reales proporcionadas por el usuario (sin publicar) y tomar una exportación/backup adecuado de Firestore si hay datos importantes.
2. Crear reglas candidatas y tests en emulador, con casos negativos: usuario A lee/modifica evidencia de B; escribe monedas de B; cambia `system`; consulta chat de B; añade/acepta solicitudes ilegítimas.
3. Crear `public_profiles` y adaptar ranking, búsqueda y perfiles; definir claramente qué es público. Probar datos ausentes y compatibilidad.
4. Adaptar las operaciones sociales y la economía a reglas validadas; ninguna excepción global de autenticados.
5. Probar en dos cuentas de prueba la inscripción, login, hábitos, foto, compras, equipamiento, amigos y ranking.
6. Sólo entonces publicar reglas desde consola de Firebase con vista previa de cambios y mecanismo de reversión. No ejecutar `firebase deploy --only firestore` con reglas incompletas.

## Riesgo inherente en Spark

No hay Cloud Functions desplegables en Spark. Por tanto **la autoridad de XP/coins derivada de acciones del cliente no puede considerarse a prueba de trampas** sólo mediante reglas de Firestore. Para una demo universitaria se puede mitigar con límites, validaciones y pruebas, pero no afirmar integridad competitiva total. La solución robusta requiere un backend confiable o funciones en Blaze; no es necesario cambiar de plan para comenzar a proteger información privada.

## Comandos de inspección seguros

```bash
git status --short
firebase use
firebase functions:list --project cloud-firestore-d8c61
firebase emulators:start --only firestore,auth --project demo-healthy-habit
```
El comando del emulador puede requerir descargas Java; usa **demo-healthy-habit** para evitar cualquier escritura a producción.

## Prueba de la primera candidata local (sin despliegue)

La rama ahora incluye `firestore.candidate.rules`, `firebase.emulator.json` y pruebas en `tests/firestore/`. **No se ha cambiado `firebase.json` ni se han desplegado reglas.** La candidata es deliberadamente incompatible con consultas públicas de ranking y relaciones cruzadas; sirve únicamente para validar el aislamiento de documentos privados antes de migrar el modelo.

En una terminal, desde la raíz del repositorio:

```bash
git fetch origin
git merge --ff-only origin/feature/mr-healthy-voice-knowledge-motion
npm --prefix tests/firestore install
firebase emulators:exec --config firebase.emulator.json --only firestore --project demo-healthy-habit "npm --prefix tests/firestore test"
```

Si falla por requerir Java o descargar componentes, comprobar Java 21 y conectividad. Con `emulators:exec` la instancia de prueba se inicia y se cierra automáticamente. No es necesario mantener otra terminal con los emuladores encendidos.

Las pruebas esperan: propietario lee/crea sus propios documentos; usuario A no lee perfil, evidencia ni registros de B; A no modifica saldo de B; no se permite listar `users`; `system` no es editable; usuarios sin sesión no leen perfiles.

**Advertencia:** Estas pruebas NO validan compras, ranking, amistades o manipulación de economía propia. Una suite que pase no autoriza desplegar las reglas; hacen falta migración de datos públicos y pruebas de las transacciones reales. La app instalada en el teléfono NO debe conectarse accidentalmente al emulador de demo.

## Migración incremental hacia `public_profiles` (20-nov-2026)

**Código incorporado en la rama de trabajo; NO desplegado y sin pruebas Flutter ejecutadas por el asistente.**

- `HealthyPublicProfileService` escucha los cambios del documento privado del usuario autenticado y crea/actualiza `public_profiles/{uid}` con nombre, username, foto, bio, título y estadísticas publicables; excluye correo, inventario, monedas, historial, evidencias, configuración interna y progreso de logros privados.
- La preferencia `mostrarRachaAmigos=false` hace que las rachas públicas se registren como cero, no solo que se oculten en pantalla.
- Ranking, búsqueda de amigos, feed, vista pública y `AmigosServicio.perfiles` consultan `public_profiles`. La ficha propia permanece leyendo `users/{miUid}`.
- La candidata local permite a cualquier usuario autenticado leer/listar `public_profiles`, pero solo al propietario publicar su documento, limitado a claves seleccionadas. No es una política anti-trampas: XP público sigue viniendo de un cliente y debe verificarse con una arquitectura autoritativa si se desea clasificación competitiva.
- El llenado de `public_profiles` es gradual: **solo aparecerán en ranking y búsqueda aquellos usuarios que abran la versión actualizada y sincronicen su perfil**. No se ha ejecutado una migración masiva ni se han consultado documentos privados ajenos. En una demo todos los usuarios de prueba deben iniciar sesión después de actualizar.
- Las reglas candidatas aún NO incluyen permiso para el flujo social entre dos cuentas (`solicitudes`, `following`, `followers`). No publicarlas hasta completar y probar ese flujo.
- En producción siguen activas las reglas generales inseguras comunicadas por el usuario. La migración de lecturas de Flutter por sí sola NO protege documentos privados mientras el catch-all de producción permanezca.

### Comprobaciones recomendadas

```bash
git fetch origin
git merge --ff-only origin/feature/mr-healthy-voice-knowledge-motion
flutter analyze --no-fatal-infos lib test
flutter test test/healthy_public_profile_service_test.dart
firebase emulators:exec --config firebase.emulator.json --only firestore --project demo-healthy-habit "npm --prefix tests/firestore test"
flutter run
```

Con dos usuarios de prueba, iniciar sesión en la versión nueva en ambas cuentas; confirmar ranking, búsqueda, vistas públicas, ocultación de rachas y perfil propio. Las pruebas del emulador verifican permisos básicos, NO la totalidad de flujos Flutter. **No ejecutar `firebase deploy` aún.**

## Candidata de seguridad social (20-nov-2026)

La candidata `firestore.candidate.rules` ya no usa una autorización recursiva genérica para todas las subcolecciones de `users`. Enumera colecciones privadas y añade reglas específicas para `solicitudes`, `solicitudes_enviadas`, `following` y `followers`.

Las creaciones de solicitudes y seguidores verifican documentos espejo del mismo batch mediante `getAfter()`; los seguimientos nuevos exigen una solicitud previa y su retirada en el batch. Las lecturas de listas de solicitudes/seguidores se limitan al propietario; consultas puntuales permiten comprobaciones de vínculo para el usuario interesado. Las eliminaciones exigen la eliminación simultánea del espejo.

Se añadieron cinco pruebas de redes sociales al emulador: envío válido, falsificación, seguimiento sin solicitud, aceptación válida y acceso ilegítimo a seguidores. **Pendiente ejecutar la suite completa (14 casos) y verificar aceptación/rechazo/cancelación y dejar de seguir desde Flutter.**

Limitación: colecciones privadas enumeradas temporalmente (`user_habits`, `temporary_habit_evidence`, `achievements`, `challenges`, `friends`). Antes de desplegar habrá que localizar y especificar otras colecciones que utiliza la app (incluidas interacciones globales), y asegurar que las consultas y escrituras esperadas pasen. Los datos de XP y monedas siguen vulnerables a autoediciones por el propietario. No desplegar.

Para ejecutar las 14 pruebas con el emulador local:

```bash
git fetch origin
git merge --ff-only origin/feature/mr-healthy-voice-knowledge-motion
firebase emulators:exec --config firebase.emulator.json --only firestore --project demo-healthy-habit "npm --prefix tests/firestore test"
```

## Ampliación de pruebas sociales (20-nov-2026)

Las primeras 14 pruebas (incluidas las cinco sociales) pasaron en el emulador, confirmado por el usuario. Se añadieron **cuatro casos pendientes de ejecutar** en `tests/firestore/rules.test.cjs`: cancelar una solicitud (con sus dos reflejos), rechazar una solicitud, impedir eliminación unilateral de un seguimiento y dejar de seguir mediante batch. Suite esperada: 18 pruebas.

El servicio social de Flutter conserva sus operaciones originales por batches; la política de Firebase sigue como candidata local y NO está desplegada. Verificar `flutter analyze`, `flutter test` y pruebas manuales con dos cuentas de prueba antes de cualquier publicación.

## Auditoría de economía (20-nov-2026, sin cambio de reglas)

**18/18 pruebas de reglas sociales aprobadas en emulador, resultado confirmado por el usuario.** El siguiente bloqueo antes de producción es la economía:

- `registrar_habito_screen.dart`: cada log otorga 10 XP sin evidencia o 15 XP con evidencia. La misma transacción escribe `users/{uid}.xp`, `currentXp`, `level`, `habitCoins`, `claimedLevelRewards` y rachas; escribe `attempts/{id}`, `logs/{id}` y posible evidencia.
- `desafios_screen.dart`: cuando un desafío cumple su política en Flutter, la transacción incrementa `users/{uid}.xp` y `habitCoins`, y cambia `challenges/{id}.status` a `claimed`. La validación cliente puede eludirse con solicitudes directas.
- `shop_service.dart`: comprar descuenta `habitCoins` y agrega un artículo a `shopInventory` en una transacción; equipar actualiza `shopEquipped`. El catálogo de precios se define en Flutter y no es fuente de confianza para Firestore Rules.

**Vulnerabilidad demostrable por inspección:** `firestore.candidate.rules` permite `allow update: if owner(uid)` en `users/{uid}`. Un usuario autenticado puede cambiar sus propios `habitCoins`, `xp`, `level` e inventario arbitrariamente mediante un cliente modificado, saltándose la aplicación. Las reglas de producción actuales son incluso más permisivas. Ninguna de las 18 pruebas anteriores aborda este ataque.

**Criterio de aceptación antes de publicar:** (1) operaciones de perfil cotidiano nunca permiten modificar economía por accidente; (2) compras válidas descuentan el precio correcto y añaden exactamente el artículo; (3) un cliente modificado no puede aumentar saldo/XP arbitrariamente ni reclamar repetidamente; (4) registros válidos siguen operando; (5) el resultado puede ejecutarse en Spark sin funciones desplegadas.

**Decisión de arquitectura pendiente:** Firestore Rules no puede confiar en constantes y cálculos del código Flutter; para una economía enteramente autoritativa se necesita un servidor de confianza. En Spark puede optarse por límites, contadores por operaciones y validaciones con `getAfter()`, aclarando que no se elimina todo riesgo de trampas, o por un backend alojado en otro servicio. No bloquear compras normales ni publicar reglas incompletas. La siguiente fase consiste en modelar esas transiciones y añadir casos negativos al emulador.

## Primera mitigación de compras en la candidata local (20-nov-2026)

Se añadió `validInventoryChange()` a `firestore.candidate.rules` para actualizaciones de `users/{uid}` que cambien `shopInventory`.

Las reglas exigen:
- Dueño autenticado, un único artículo nuevo, mantener los artículos existentes.
- Artículo conocido del catálogo pagado y precio exacto de `ShopService` (12 productos con precio mayor a cero).
- Saldo entero suficiente y decremento igual al precio, sin editar otros campos en esa operación.
- Los dos artículos gratuitos (sunglasses, bandana) no requieren compra: `ShopState.owns` ya los considera propios de manera virtual.

Se han agregado **cinco pruebas nuevas**: compra legítima, artículos falsos/descuento, compra múltiple, duplicado y un *test de vulnerabilidad conocida* que demuestra que el propio usuario aún puede inflar su saldo y XP en una actualización independiente. **Total esperado ahora: 23 casos**. Esta última prueba pasa precisamente porque la vulnerabilidad aún existe; no confundirla con garantía de seguridad.

### Limitaciones no resueltas

1. El usuario todavía puede alterar su propia economía directamente en `users/{uid}` si no cambia `shopInventory`, o manipular recompensas de hábitos/desafíos. Ningún cambio de esta fase demuestra integridad monetaria total.
2. La lógica completa de XP/HC en Spark exige diseñar validación de transacciones de recompensa enlazada con registros, o cambiar a backend confiable. Incluso con validaciones en reglas no se verifica que la actividad física/alimentaria haya ocurrido.
3. El precio del catálogo está duplicado en reglas y Flutter, por lo que **cada cambio de precio requiere actualizar ambos y añadir pruebas**.
4. La candidata sigue sin estar lista para producción por coberturas pendientes de colecciones y operaciones, además de la vulnerabilidad económica conocida.

Para ejecutar la nueva suite:

```bash
git fetch origin
git merge --ff-only origin/feature/mr-healthy-voice-knowledge-motion
firebase emulators:exec --config firebase.emulator.json --only firestore --project demo-healthy-habit "npm --prefix tests/firestore test"
```

No desplegar `firestore.candidate.rules` ni alterar las reglas actuales hasta cerrar todas las brechas y completar regresión con Flutter.

## Corrección tras suite 22/23 (20-nov-2026)

Resultado reportado por el usuario: 22 pruebas aprobadas y una fallida (`no se puede comprar dos veces un artículo ya adquirido`). La prueba descubrió una vía real: se podía disminuir `habitCoins` sin modificar el inventario y, por tanto, sin entrar en `validInventoryChange()`. Algunos casos negativos además agotaban las 1,000 expresiones del evaluador por las 12 ramas de precio independientes.

Corrección candidata: catálogo expresado como `rules.Map.get()`; el artículo añadido se obtiene como diferencia de listas mediante `removeAll()`. Cualquier reducción de `habitCoins` o modificación de `shopInventory` debe satisfacer la validación de compra. Esto evita la reducción sin compra y la segunda compra sin artículo nuevo, sin agotar la evaluación con 12 comparaciones repetidas. La referencia oficial de Firebase confirma que ambos métodos forman parte del lenguaje de reglas: https://firebase.google.com/docs/reference/rules/rules.List y https://firebase.google.com/docs/reference/rules/rules.Map.

Se añadieron dos pruebas nuevas para débitos sin adquisición y compras mezcladas con XP arbitraria. **La suite esperada ahora es de 25 pruebas, pendiente de ejecutar.** La prueba de vulnerabilidad conocida que incrementa libremente el saldo y XP sigue demostrando un problema pendiente; las reglas aún no están listas para desplegar.

## Validación de payloads malformados y límite de confianza (20-nov-2026)

El usuario confirmó **25/25 tests aprobados** en el emulador. Varios rechazos mostraron `evaluation error at L90:24` porque `validInventoryDetails` intentaba hacer `removeAll` aun con el campo `shopInventory` ausente o malformado. Se separaron condiciones de existencia/tipo (`validInventoryChange`) y cálculos de listas (`validInventoryDetails`) para rechazar esas solicitudes sin realizar operaciones sobre tipos inválidos. Se añadieron dos casos adversarios. **Total esperado: 27 pruebas, pendientes de ejecutar en el emulador.**

### Límite de confianza por resolver

Los dos vectores restantes son independientes de la validación del inventario:

1. **Autoinflación:** `users/{uid}` sigue admitiendo un aumento directo de `xp` y `habitCoins` sin adjuntar un registro o desafío válido. La prueba de vulnerabilidad conocida verifica ese hecho.
2. **Falsificación de origen:** `user_habits/{path=**}` y `challenges/{path=**}` permiten al propietario crear intentos, logs y estados arbitrarios. Vincular la recompensa a uno de esos documentos en `getAfter()` no demostraría, por sí solo, que sea auténtico.

**Restricción de diseño:** no prohibir todas las modificaciones de `xp` y `habitCoins` sin modificar simultáneamente las transacciones de `registrar_habito_screen.dart` y `desafios_screen.dart`. Rompería el registro y los canjes legítimos. La economía plenamente resistente a clientes modificados requiere autoridad externa (backend confiable) o un modelo sustancialmente más restrictivo y validado por Firestore Rules, con límites explícitos sobre pruebas de acciones humanas. Para la entrega en Spark, documentar cualquier garantía parcial, no presentar la economía como infalsificable.

**Operación segura:** continuar en emulador; `firebase.json` y reglas de producción no se han modificado en este cambio.

## Sexta etapa — contratos de recompensas (sin cambios de producción)

El usuario confirmó **27/27 pruebas del emulador aprobadas**. Las trazas `PERMISSION_DENIED` en casos negativos son esperadas; aún existen mensajes `evaluation error` que requieren revisión separada antes del despliegue.

Se agregaron tres pruebas para registrar contratos observables:
1. Actualización conjunta de perfil, intento y log de hábito, conservando los 10 XP legítimos.
2. Reclamación de un desafío completado, con actualización conjunta de XP, Habit Coins y estado.
3. Prueba explícita de vulnerabilidad: el propietario todavía puede fabricar un documento de desafío `completed` con premios y progreso falsos.

**Suite esperada: 30 pruebas**. Estos tests de compatibilidad no equivalen a protección contra un cliente modificado; por ahora son una línea base para diseñar reglas más estrictas sin romper hábitos o tienda. Si se cambia la política de XP, estas pruebas deberán ampliarse para comprobar valores, límites y documentos relacionados mediante `getAfter()`.

**Próximo bloqueo de arquitectura:** el flujo de desafíos permite crear y editar el origen de las recompensas desde Flutter. Antes de cerrar la escritura directa de XP/HC hay que decidir una autoridad de premios y revisar funciones que crean/actualizan desafíos. Ningún cambio sobre la colección de producción o sobre `firebase.json` se realizó aquí.

## Séptima etapa — protección del origen de desafíos (candidata)

El usuario confirmó **30/30 pruebas aprobadas**. Se añadieron reglas específicas de `users/{uid}/challenges/{challengeId}` para limitar la creación por clientes a desafíos de demostración (`demoSeed: true`, `progressVerified: false`, `progressSource: demo`) con progreso inicial cero, premios acotados y estado `available` o `locked`. El cliente puede aceptar desafíos demo modificando únicamente `status` y `acceptedAt`, pero no puede declararlos completados ni verificarlos. No puede borrar desafíos. Se permite marcar `claimed` solo un desafío que **ya estaba** verificado y completado (por una autoridad distinta del cliente), con modificación únicamente de `status` y `claimedAt`. Esto **no implementa** aún el proceso que produce progreso verificado.

La prueba anterior que documentaba la creación fraudulenta ahora exige su rechazo; se agregan cuatro pruebas sobre alta/aceptación demo, intento de modificación de recompensas y verificación, borrado y creación directamente verificada. **Total esperado: 34 pruebas** en el emulador, todavía sin ejecutar.

**Limitaciones abiertas:** los premios de desafíos verificados preexistentes aún pueden sumarse arbitrariamente en `users/{uid}` porque no está protegida la transacción de economía; el usuario todavía puede modificar XP/HC directamente. Los datos creados con reglas antiguas no quedan automáticamente validados ni saneados. Deben auditarse colecciones globales y flujos de app antes del despliegue. No publicar esta candidata.

## Auditoría de compatibilidad: reacciones entre amigos

**34/34 pruebas** confirmadas por el usuario. La auditoría de código identificó una ruta de producción no cubierta por la candidata: `lib/páginas/perfil/interaction_service.dart` utiliza la colección global `interactions`; el `deny all` impediría enviar, listar, leer y responder reacciones al publicar las reglas nuevas.

Se agregó un `match /interactions/{interactionId}` **solo en la candidata** que autoriza: emisor autenticado crea con `fromUid` igual a su UID, sin poder fijar estados de aceptación; destinatario consulta con filtro `toUid`, marca `leido` o responde, sin alterar participantes ni eliminar documentos. `createdAt` conserva compatibilidad con `Timestamp.fromDate(DateTime.now())` con tolerancia de cinco minutos al reloj del cliente. Los valores de respuesta admitidos `aceptado` y `rechazado` deben contrastarse en pruebas manuales con la interfaz de reacciones.

Se agregaron cinco pruebas, **total esperado: 39 pruebas**, pendientes de ejecución. No significa que toda la aplicación esté auditada: restan otras rutas y el modelo de economía sigue vulnerable a modificaciones del propio usuario. La publicación continúa bloqueada.
