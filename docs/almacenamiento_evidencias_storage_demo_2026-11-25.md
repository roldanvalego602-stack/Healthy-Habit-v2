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
