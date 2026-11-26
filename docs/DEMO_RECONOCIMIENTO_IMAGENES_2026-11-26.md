# Healthy Habit — demostración de reconocimiento visual (26 nov 2026)

**Propósito:** presentar la detección de contenido de fotografías sin registrar hábitos, otorgar XP o Habit Coins ni habilitar beta general.

## Integración

- `lib/páginas/habitos/healthy_vision_demo_screen.dart`: laboratorio independiente con cámara/galería, vista previa, compresión a JPEG sin EXIF de máximo 250 KB y botón de análisis.
- `lib/páginas/inicio.dart`: acceso «Probar reconocimiento de imágenes» en la tarjeta de Mr. Healthy, **solo visible en depuración con el flag `HH_VISION_DEBUG`**.
- Se reutiliza `HealthyVisionPreviewPanel` y su selector de perfil (`Frutas y verduras`, `Hidratación`, `Comida`), lista de etiquetas y confianzas, y mensajes de cuota. Inicialmente se selecciona frutas/verduras para facilitar la exposición.
- No almacena fotografías, no llama a la API cuando solo se elige una imagen y no toca los registros, XP, monedas ni el inventario.
- `test/healthy_vision_demo_screen_test.dart` verifica que el laboratorio no se expone por defecto.

## Reutilización de Google Cloud Vision ya probado

El backend en `vision-functions/index.js` contiene `analyzeEvidencePreviewLive`, solo para el UID configurado en `HEALTHY_VISION_TEST_UID`, con 15 análisis por día UTC y al menos 60 segundos entre invocaciones. Hace `labelDetection` y `objectLocalization`, y devuelve un resultado **solo indicativo**: nunca `imageVerified=true` ni premios.

**Esta integración NO despliega funciones ni cambia permisos.** Requiere que el codebase `vision` ya esté desplegado correctamente en `cloud-firestore-d8c61` para usar el backend real. Si se recibe `not-found`, comprobar el despliegue; si aparece `permission-denied`, utilizar la misma cuenta autorizada en el piloto anterior. El proyecto Blaze puede facturar Vision. No copiar el UID ni credenciales al repositorio.

## Ejecución para la presentación en Android

Desde la raíz del proyecto, después de actualizar:

```bash
git fetch origin main
git merge --ff-only origin/main
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test test/healthy_vision_demo_screen_test.dart
flutter test test/healthy_vision_debug_test.dart
flutter run -t lib/main.dart --dart-define=HH_VISION_DEBUG=true --dart-define=HH_VISION_LIVE_BACKEND=true
```

En la aplicación: **Inicio → Mr. Healthy → Probar reconocimiento de imágenes → Galería/Cámara → Analizar con IA (sin XP)**. Esperar 60 segundos entre solicitudes, no hacer capturas de información personal.

Si el piloto real NO está disponible y se elige trabajar con emuladores, consultar `docs/VISION_EN_REGISTRO_REAL_DEBUG_2026-11-23.md` y utilizar `HH_VISION_EMULATOR_HOST` sin activar `HH_VISION_LIVE_BACKEND`. Esto necesita Auth/Functions Emulator y un proveedor Vision configurado explícitamente.

## Precauciones

- No activar esta función en builds de distribución ni eliminar `kDebugMode`.
- La etiqueta «agua», «fruta» o «comida» no prueba consumo ni cumplimiento de hábitos.
- La demo requiere acceso a red para llamar a Google Cloud Vision.
- Las cuotas son controles de costo, no reemplazan App Check.
- El código de beta de hábitos, reglas Firestore y compras reales permanecen sin cambios.
