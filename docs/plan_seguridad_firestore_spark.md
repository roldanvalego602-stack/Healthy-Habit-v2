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
