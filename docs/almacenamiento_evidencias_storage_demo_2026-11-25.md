# Laboratorio privado de fotografías con Storage Emulator

Fecha: 25 de noviembre de 2026.

## Etapa implementada: aislamiento del archivo, sin recompensas

Se creó `storage.evidence.demo.rules`, incluido **solo** en
`firebase.lockdown.emulator.json` para `demo-healthy-habit`.
El emulador de Storage escucha en `127.0.0.1:9199`.

Las únicas operaciones permitidas son:
- Crear una imagen en `habit-evidence/{uid}/{attemptId}/{evidenceId}`
  para el UID autenticado, con IDs válidos, sin sobrescribir, entre
  1 B y 256 000 B y MIME `image/jpeg`, `image/png` o `image/webp`.
- Leer una imagen propia por ruta exacta (`get`); listado denegado.
- Borrar una imagen propia; todas las demás rutas denegadas.

Las reglas de Storage **solo** validan metadatos, tamaño y ruta.
No analizan el contenido real ni prueban que el usuario realizó
el hábito. Un cliente modificado puede enviar bytes falsos con
un MIME permitido. La inspección del contenido y la relación
con el registro oficial requieren una fase de servidor independiente.

`lib/servicios/evidence_storage_demo_service.dart` restringe
el proyecto a `demo-healthy-habit`, las banderas del laboratorio
y el host del emulador; reconoce cabeceras JPEG, PNG o WebP,
exige un máximo de 250 KB, y envía la imagen directamente a
Storage Emulator. Devuelve **solo una ruta privada**, nunca una
URL pública. Permite borrar el objeto por UID/IDs en modo demo.

**El servicio aún no se llama desde `RegistrarHabitoScreen`.**
La pantalla mantiene bloqueadas las fotografías oficiales.

## Seguridad y fases pendientes

Antes de conectar la subida al formulario es indispensable:

1. Generar una reserva de evidencia vinculada por el servidor a
   `uid / habitId / attemptId / operationId`.
2. Comprobar desde Functions la existencia y contenido de la imagen
   antes de asociar su ruta a un `log` oficial.
3. Diseñar un protocolo de cancelación y reintentos para evitar
   archivos huérfanos y discrepancias entre Firestore y Storage.
4. Ejecutar eliminación administrativa automática de imágenes
   vencidas, aun si el usuario jamás abre la aplicación.
5. Evitar URLs públicas y gestionar metadatos EXIF; establecer
   consentimiento, privacidad y política de retención.
6. Mantener `xpAwarded` y monedas independientes de la imagen.
   **Una fotografía no significa automáticamente evidencia verificada.**
7. Probar seguridad adversarial: otros UID, sobrescrituras, tamaños,
   archivos falsos, expiración, doble subida, caída de red y recuperación.

Por estas razones no se ha habilitado la subida en la pantalla
ni el aumento de XP. Tampoco se han tocado las reglas reales
de Storage/Firestore ni se ha publicado ninguna Function.

## Validación local obligatoria

Primero actualizar:

```bash
git fetch origin main
git merge --ff-only origin/main
flutter analyze lib/servicios/evidence_storage_demo_service.dart
```

Luego validar las reglas privadas contra Firebase Auth y Storage
Emulator. Este comando inicia **solo** dos emuladores y usa
el proyecto demo; no despliega servicios:

```bash
npm --prefix tools/firestore-tests run test:evidencias-storage:emulador
```

Resultado esperado: **1 escenario aprobado**, 0 fallidos.
La prueba comprueba propietario, lectura, borrado, bloqueo
de otros usuarios, segunda subida, MIME no permitido,
tamaño excesivo y ruta no autorizada.

No usar `firebase deploy`. No conectar la nueva interfaz
a un bucket real ni iniciar Storage sin su emulador.


## Segunda etapa: reserva autenticada por operación

Ahora existe `reserveHabitEvidenceDemo` (Functions Emulator, proyecto
`demo-healthy-habit` exclusivamente). El backend exige
`{habitId, attemptId, operationId}`, obtiene el UID de Auth y
comprueba que el perfil, el hábito y su intento **existan y estén activos**.
Crea en una transacción un documento interno:

`users/{uid}/habit_evidence_reservations/{operationId}`

que contiene la ruta `habit-evidence/{uid}/{attemptId}/{operationId}`,
su dueño, hábito, intento, estado `pending` y vencimiento a **una hora**.
El cliente no tiene permisos directos de lectura ni de escritura
sobre esa colección con las reglas restrictivas del laboratorio.

La operación es idempotente: un segundo intento con los mismos IDs
recibe la misma ruta y fecha; identificadores cruzados se rechazan.
La reserva tampoco cambia monedas, XP, rachas ni progreso.

`EvidenceStorageDemoService.upload` ahora exige `habitId`,
solicita la reserva al callable, comprueba la ruta y expiración,
y solo después llama a Storage Emulator. El servicio sigue
**sin conectarse** a la pantalla de registro oficial.

### Restricciones que siguen pendientes

- **Las reglas de Storage todavía no exigen la reserva** para admitir
  una subida del dueño. Un cliente modificado podría omitir el callable.
  Es necesario imponer el vínculo en el servidor/reglas antes de habilitar
  fotos en la pantalla.
- **Reservar no confirma la evidencia**: aún faltan inspección de bytes,
  vínculo al log oficial y limpieza de archivos o reservas huérfanas.
- La fecha de expiración de Firestore **no borra el archivo de Storage**.
  No hay todavía proceso automático de purga; la retención efectiva
  no está garantizada.
- La aplicación no debe generar ni publicar URL de descarga. La ruta
  privada y las reglas son una protección de acceso, no una garantía de
  anonimato si se filtran contenidos o tokens.
- No se asignan recompensas por reservar o cargar fotografías.

### Pruebas del contrato de reserva

El archivo `tools/firestore-tests/habitos_cliente_integral.test.mjs`
incluye ahora un **octavo escenario** para comprobar activación previa,
pertenencia al intento, idempotencia, rechazo de campos monetarios,
bloqueo de Firestore directo y ausencia de cambios económicos.

```bash
git fetch origin main
git merge --ff-only origin/main

flutter analyze \
  lib/servicios/evidence_storage_demo_service.dart \
  lib/servicios/official_habit_emulator_service.dart

npm --prefix functions test
npm --prefix tools/firestore-tests run test:cliente-integral:emulador
npm --prefix tools/firestore-tests run test:evidencias-storage:emulador
```

Resultado esperado: 8 pruebas integrales del cliente aprobadas,
más 1 prueba aislada de reglas de Storage. **Pendiente de ejecución
local en esta versión.** No iniciar `firebase deploy`.


## Tercera etapa: asociación comprobada y limpieza administrativa

Se añadió `attachHabitEvidenceDemo`, disponible solo dentro del proyecto
`demo-healthy-habit` con **Functions y Storage Emulator** activos.
La asociación se efectúa **después** de confirmar el registro económico:

1. Comprueba reserva, operación de registro y log oficial del UID
   autenticado, con el mismo hábito, intento e identificador.
2. Lee el archivo real mediante Admin SDK, comprueba su existencia,
   el tipo declarado, el tamaño y las firmas básicas de JPEG/PNG/WebP.
   Esta validación de cabecera **no garantiza que una foto sea auténtica**
   ni evita contenido engañoso.
3. Actualiza atómicamente solo el log y el estado de la reserva:
   `hasEvidence: true`, `evidencePath`,
   `evidenceVerified: false`, tamaño, tipo y vencimiento.
   El saldo, el XP y los límites de registro **no cambian**.
4. Repetir una asociación terminada devuelve `alreadyAttached: true`
   sin volver a acreditar recompensas. El cliente no puede inventar
   `evidenceVerified`.

`lib/servicios/official_habit_emulator_service.dart` expone ahora
`attachEvidence(...)`, pero sigue **sin invocarse desde la pantalla
de registro**. No hay todavía subida desde el formulario oficial.

Existe `functions/habit_evidence_cleanup.js`, utilizado por
`functions/scripts/limpiar_evidencias_demo.js`.
Es una limpieza **administrativa y por lotes**, independiente de que
el usuario abra Flutter. Solo funciona con Firestore y Storage Emulator.
Para reservas vencidas, elimina los objetos privados, retira la
referencia a la imagen de los logs vinculados y finalmente borra
las reservas. Los fallos dejan información para reintentar la limpieza.

Esta limpieza **no está programada automáticamente**. La vida útil
de una hora es un vencimiento lógico, no eliminación garantizada.
Tampoco se limita la creación de archivos no reservados desde un
cliente modificado: las reglas actuales de Storage protegen dueño,
tamaño y MIME, pero aún no consultan la reserva. Se requiere
endurecer este punto y establecer una programación administrativa
revisada antes de habilitar fotografías en el formulario o producción.

### Pruebas de esta etapa

```bash
git fetch origin main
git merge --ff-only origin/main

flutter analyze \
  lib/servicios/official_habit_emulator_service.dart \
  lib/servicios/evidence_storage_demo_service.dart

npm --prefix functions test
npm --prefix tools/firestore-tests run test:cliente-integral:emulador
npm --prefix tools/firestore-tests run test:evidencias-storage:emulador
```

El escenario integral ahora incluye asociación de un PNG real con
reserva y registro previo, recuperación idempotente y bloqueo de
campos económicos. **Resultado esperado: 9 escenarios integrales
aprobados y 1 de Storage; aún no se ha ejecutado localmente.**

Para practicar la limpieza administrativa con los emuladores
aislados (no ejecutar contra datos reales), en una terminal iniciar
Auth, Firestore y Storage desde la configuración `firebase.lockdown.emulator.json`
con las reglas generadas, y en otra:

```bash
GCLOUD_PROJECT=demo-healthy-habit \
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
FIREBASE_STORAGE_EMULATOR_HOST=127.0.0.1:9199 \
npm --prefix functions run limpiar:evidencias:demo
```

No ejecutar `firebase deploy`. En ausencia de registros vencidos,
el comando debe informar cero archivos eliminados.


## Cuarta etapa: escritura exclusiva del servidor y vigilancia local

Para cerrar la brecha que permitía omitir la reserva desde un cliente
modificado, `storage.evidence.demo.rules` **deniega ahora todas las
creaciones, modificaciones y eliminaciones directas** para clientes,
incluidos los propietarios. Solo se conserva la lectura privada por
ruta exacta. El Admin SDK del emulador es responsable de las escrituras.

Se incorporó `uploadReservedEvidenceDemo` al Functions Emulator:

- Recibe exactamente `habitId`, `attemptId`, `operationId`,
  `imageBase64` y `contentType`; el UID proviene de Auth.
- Valida la reserva del servidor, su titular, ruta, estado `pending`
  y vencimiento. No permite subida sin reserva.
- Valida los bytes, firma básica y tamaño máximo de 250 KB.
  El servidor guarda el objeto con precondición de creación única.
- Ante un reintento con el mismo archivo comprueba que coincidan
  tamaño, MIME y bytes; nunca sustituye un objeto existente.
- **No concede XP, monedas ni verificación**, y la asociación al
  registro sigue siendo una operación separada.
- El servicio de Flutter deja de escribir o borrar directamente en
  Storage y envía la imagen al callable exclusivo de pruebas.

La pantalla oficial todavía **no llama** este servicio. No se ha
activado el registro fotográfico de usuarios.

### Vigilante de limpieza local

La utilidad `functions/scripts/vigilar_evidencias_demo.js` invoca
la limpieza administrativa al iniciar y cada minuto **mientras ese
proceso esté encendido**. Utiliza únicamente Firestore y Storage
Emulator, y rechaza otros proyectos. Se detiene mediante Ctrl+C.
No es una tarea en la nube, no sobrevive al apagado del laboratorio
ni supone garantía de eliminación automática en producción.

Para probarlo, iniciar primero los emuladores de Firestore, Storage,
Functions y Auth con `firebase.lockdown.emulator.json` y la
vista previa de reglas restrictivas, y en otra terminal ejecutar:

```bash
GCLOUD_PROJECT=demo-healthy-habit \
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
FIREBASE_STORAGE_EMULATOR_HOST=127.0.0.1:9199 \
npm --prefix functions run vigilar:evidencias:demo
```

No iniciar dos vigilantes simultáneamente. Esta implementación
limpia las reservas vencidas conocidas; todavía debe realizarse
una auditoría de archivos huérfanos históricos que no tengan
reservas, y diseñarse una programación gestionada para despliegue
futuro, sin comprometer cuotas ni política de privacidad.

### Nuevas pruebas

```bash
git fetch origin main
git merge --ff-only origin/main
flutter analyze \
  lib/servicios/evidence_storage_demo_service.dart \
  lib/servicios/official_habit_emulator_service.dart
npm --prefix functions test
npm --prefix tools/firestore-tests run test:cliente-integral:emulador
npm --prefix tools/firestore-tests run test:evidencias-storage:emulador
```

El total esperado sigue siendo 9 escenarios integrales y 1 escenario
de Storage, además de los tests de funciones. Las pruebas ahora
exigen que incluso el propietario no pueda subir directamente,
y verifican que solo la Function con reserva puede crear el objeto.
**Aún deben ejecutarse localmente y no se declara su éxito.**

No ejecutar `firebase deploy` ni cambiar el proyecto de pruebas.


## Quinta etapa: control transaccional de concurrencia

Tras confirmar los 9 escenarios anteriores, se ha añadido una
serialización de subidas por estado de reserva:

`pending -> uploading -> uploaded -> attached`

La Function `uploadReservedEvidenceDemo` adquiere el estado
`uploading` mediante una transacción de Firestore antes de tocar
Storage. Una solicitud paralela que encuentra ese estado recibe
`aborted` para reintentar; una solicitud que encuentra `uploaded`
solo tiene éxito si los bytes y el MIME son idénticos. La asociación
`attachHabitEvidenceDemo` exige `uploaded`.

Se conserva la precondición de Storage `ifGenerationMatch: 0`,
pero la exclusión de solicitudes concurrentes del mismo registro
depende de Firestore y no de las diferencias de implementación del
Storage Emulator. Los campos económicos no se modifican.

La limpieza administrativa evita eliminar una reserva en estado
`uploading` durante los cinco minutos posteriores al inicio de
la subida. Una reserva bloqueada o un fallo de ACK necesita todavía
un procedimiento de recuperación/inspección independiente antes
de habilitar fotografías en la pantalla. La limpieza permanece
local y no es una programación gestionada de Firebase.

Se añadió una **décima prueba integral** con dos fotografías
distintas enviadas simultáneamente para la misma reserva. Una debe
ganar, la otra debe recibir conflicto o reintento y un tercer
envío idéntico debe reconocerse como repetido. También se añadió
una prueba unitaria de purga de reserva vencida y desvinculación
sin modificar XP.

Validación requerida:

```bash
git fetch origin main
git merge --ff-only origin/main

npm --prefix functions test
npm --prefix tools/firestore-tests run test:cliente-integral:emulador
npm --prefix tools/firestore-tests run test:evidencias-storage:emulador
```

Resultado esperado: **10 pruebas integrales y 1 prueba de reglas
de Storage aprobadas**, además de las pruebas unitarias de Functions.
No se han ejecutado localmente en esta versión.


## Sexta etapa: recuperación conservadora de subida interrumpida

Se agregó recuperación para una reserva que permanezca en `uploading`
más de cinco minutos, siempre que no haya vencido su reserva:

- Una transacción adquiere exclusivamente el estado `recovering`.
  Las demás solicitudes quedan bloqueadas durante la inspección.
- Si el objeto ya existe con **los mismos bytes, tamaño y MIME**,
  se marca `uploaded` sin escribir ni sustituir el archivo.
- Si el objeto no existe, se libera como `pending`; el cliente
  podrá reintentar la subida completa con el mismo ID.
- Si el objeto tiene otros bytes, se rechaza y permanece bloqueado
  para revisión administrativa. No se sustituye.
- Una subida con menos de cinco minutos de antigüedad se deja intacta.

Esta recuperación no usa un token de verificación de hábito, no
incrementa XP, no genera monedas y no conecta todavía la pantalla
oficial. Requiere mantener el Storage Emulator y Firestore Emulator
activos en `demo-healthy-habit`.

Pruebas nuevas: `functions/tests/habit_evidence_recovery.test.js`.

```bash
git fetch origin main
git merge --ff-only origin/main
node --test functions/tests/habit_evidence_recovery.test.js
npm --prefix functions test
npm --prefix tools/firestore-tests run test:cliente-integral:emulador
```

**Falta validar en el equipo local.** Las diez pruebas integrales
anteriores fueron confirmadas por el usuario; las de esta etapa
todavía no. El proceso de limpieza sigue sin estar programado como
servicio persistente o producción.


## Séptima etapa: comprobación de caducidad con emuladores reales

El escenario `functions/tests-emulator/habit_evidence_cleanup.integration.js`
prueba la eliminación mediante Firebase Admin, Firestore Emulator
(base nombrada `default`) y Storage Emulator. No utiliza dobles
de prueba para el acceso a Firestore ni para los objetos de Storage.

Casos cubiertos:

1. Reserva `attached` vencida: borrar el objeto y quitar del log
   `hasEvidence` y la ruta, preservando `xpEarned`, XP y monedas.
2. Reserva `pending` vencida sin archivo: finalizar sin error.
3. Estado `uploading` vencido con bloqueo de menos de cinco minutos:
   conservar archivo y reserva temporalmente; tras envejecer el
   bloqueo, eliminarlos en otra ejecución.
4. Reserva `uploaded` vigente: conservar el objeto.
5. Nueva ejecución tras limpiar: cero registros eliminados.

Para ejecutar el escenario aislado:

```bash
npm --prefix tools/firestore-tests run test:evidencias-limpieza:emulador
```

El comando prepara reglas restrictivas e inicia solo Auth,
Firestore y Storage Emulator con `--project demo-healthy-habit`.
**Esperado: 1 prueba integral de limpieza aprobada**.
La prueba conserva las referencias ajenas y elimina únicamente los
objetos de prueba generados por su usuario temporal.

Las 10 pruebas integrales del cliente anteriores fueron aprobadas;
esta nueva validación sigue pendiente de ejecutarse en el equipo local.

**Límites aún abiertos:** el vigilante local no sobrevive al apagado,
una operación en estado `recovering` requiere diagnóstico si
se interrumpe, la limpieza no recorre archivos históricamente
huérfanos sin reserva, y aún falta autorizar el botón de fotografías
en la pantalla oficial. Nada se despliega en producción.


## Octava etapa: auditoría NO destructiva de archivos huérfanos

Se añadió `functions/habit_evidence_audit.js` y el ejecutable
`functions/scripts/auditar_evidencias_demo.js`. Se limitan a
`demo-healthy-habit` con Firestore y Storage Emulator activos.

La auditoría inspecciona **hasta 100 archivos de la primera página**
bajo `habit-evidence/`; clasifica:

- `valid`: existe reserva vinculada y no vencida.
- `orphan`: no existe reserva y el archivo tiene más de cinco minutos.
- `recentUnreserved`: no hay reserva pero el archivo puede ser reciente.
- `expired`: la reserva existe y ya venció.
- `inconsistent`: la reserva no coincide o carece de datos esenciales.
- `invalidPath`: ruta fuera del formato esperado.

Los hallazgos no se borran ni se modifican. `hasMore=true` indica que
el resultado es **parcial**; todavía no hay paginación entre todos los
objetos ni purga automática de huérfanos. La revisión manual debe
preceder cualquier eliminación.

Para analizar la lógica sin emuladores:

```bash
node --test functions/tests/habit_evidence_audit.test.js
```

Para ejecutar la auditoría no destructiva con emuladores **ya
iniciados**, en la carpeta raíz del repositorio:

```bash
GCLOUD_PROJECT=demo-healthy-habit \
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
FIREBASE_STORAGE_EMULATOR_HOST=127.0.0.1:9199 \
node functions/scripts/auditar_evidencias_demo.js
```

No se cambió `functions/package.json`, porque la instalación local
de Google Cloud Vision lo modifica. El formulario oficial de Flutter
tampoco se modificó: el usuario tiene cambios locales en
`registrar_habito_screen.dart` que deben conservarse.

No desplegar a producción. El resultado de las pruebas nuevas aún
debe confirmarse localmente.
