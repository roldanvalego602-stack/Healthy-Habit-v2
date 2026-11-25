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
