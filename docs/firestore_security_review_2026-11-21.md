# Revisión de reglas Firestore — Healthy Habit

Fecha: 2026-11-21

## Riesgo confirmado

El conjunto actualmente desplegado por el usuario contiene:
`match /{document=**} { allow read, write: if request.auth != null; }`.

Esto autoriza a **cualquier cuenta autenticada** a leer y escribir
documentos de otros usuarios, incluyendo información privada, XP,
interacciones y configuración. Las reglas específicas para
`users/{uid}` no limitan la regla global por la semántica OR de
coincidencias en Firestore.

Existe una segunda regla peligrosa para la lógica del producto:
`match /system/{document=**} { allow read, write: if request.auth != null; }`;
cualquier cuenta puede modificar configuración global.

## Estado del entregable

Archivo **NO DESPLEGADO**, candidato para validación:
`docs/firestore_social_candidate.rules`.

Es un borrador deliberadamente restrictivo, **no una regla lista para
pegar en producción**. Se revisaron las rutas principales utilizadas
por los servicios de amigos, feed, reacciones, hábitos en pareja,
desafíos, hábitos personales, perfiles y estadísticas.

El borrador conserva escritura del documento personal `users/{uid}`
para evitar bloquear pantallas que actualizan estadísticas y
preferencias. **Esto sigue permitiendo que el cliente falsifique XP,
monedas y niveles de su propia cuenta**: un servidor con reglas seguras
para la gamificación requiere establecer quién puede cambiar esos
campos, preferiblemente un backend autorizado, y comprobar la lógica
de actualización actual.

El perfil público se conserva de lectura general autenticada para la
búsqueda y el feed. Su escritura por propietario también requiere
limitar campos de progreso que no deben ser autoacreditables.

## Matriz mínima en Firebase Emulator

Operación | Resultado esperado
---|---
A lee su documento privado | PERMITIR
A lee/escribe documento privado de B | DENEGAR
A consulta perfiles públicos | PERMITIR
A modifica `public_profiles/B` | DENEGAR
A crea solicitud entrante para B + espejo enviada propia en lote | PERMITIR
A crea solicitud atribuyéndose la identidad de B | DENEGAR
A crea directamente `users/A/friends/B` sin solicitud | DENEGAR
B acepta una solicitud real de A en transacción | PERMITIR
A crea amistad sin eliminar solicitud | DENEGAR
B rechaza solicitud y elimina ambos espejos en lote | PERMITIR
A cancela su solicitud y elimina espejos en lote | PERMITIR
A y B eliminan ambos documentos de amistad | PERMITIR
C elimina `friends` de A y B | DENEGAR
A envía reacción a B si tienen amistad | PERMITIR
A envía reacción a C sin amistad | DENEGAR
A consulta reacciones recibidas por B | DENEGAR
B marca su propia reacción como leída | PERMITIR
A marca una reacción recibida por B | DENEGAR
A crea invitación a hábito para B si son amigos | PERMITIR
A crea invitación para C sin amistad | DENEGAR
B acepta la invitación pendiente de A | PERMITIR
C acepta la invitación entre A y B | DENEGAR
A cancela su invitación pendiente | PERMITIR
A o B termina una invitación aceptada | PERMITIR
C modifica o borra invitaciones de terceros | DENEGAR
A escribe `system/global` | DENEGAR
Usuario no autenticado lee perfiles privados o invitaciones | DENEGAR

Comprobar además:
- La búsqueda de `public_profiles` y los listeners `.where('toUid',
  isEqualTo: uid)`, `.where('senderUid', isEqualTo: uid)` y
  `.where('recipientUid', isEqualTo: uid)`.
- El número de lecturas `existsAfter/getAfter` dentro de operaciones
  atómicas: Firestore limita accesos durante una transacción.
- Los campos exactos que actualizan `user_habits`,
  `achievements`, `challenges`, `temporary_habit_evidence`,
  catálogo, tienda, perfil y logros.
- Todos los paths de primer nivel que no aparecen en el borrador.
- Si la app escribe en `system`, exigir permisos de administrador y
  no confiar en una bandera editable en `users/{uid}`.
- Validez de datos publicados y resistencia a spam en reacciones.

## Siguiente secuencia de despliegue

1. Hacer una copia fechada de las reglas actuales en un archivo local
   seguro o en el historial del proyecto.
2. Ejecutar la matriz anterior en Firebase Emulator mediante dos
   usuarios simulados y una cuenta intrusa.
3. Corregir reglas y clientes sin añadir permisos amplios.
4. Validar todos los flujos existentes de Healthy Habit en el
   emulador, no sólo las pantallas sociales.
5. Revisar la migración de seguimientos heredados sin generar
   amistades consentidas de forma implícita.
6. Publicar mediante proceso controlado y repetir las pruebas con dos
   cuentas de pruebas. **Ninguna regla se despliega automáticamente**.

## Referencia

- https://firebase.google.com/docs/firestore/security/rules-structure
- https://firebase.google.com/docs/firestore/security/rules-query
- https://firebase.google.com/docs/firestore/manage-data/transactions
