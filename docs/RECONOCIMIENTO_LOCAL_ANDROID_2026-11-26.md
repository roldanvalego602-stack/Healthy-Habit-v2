# Healthy Habit — reconocimiento de fotografías en Android (26 nov 2026)

## Implementación vigente en main

Hay **dos motores independientes**:

1. **Google ML Kit local (nuevo, sin flags):** disponible desde Inicio → tarjeta de Mr. Healthy → «Probar reconocimiento de imágenes» y dentro del registro de un hábito al elegir una foto. Cámara y galería, detección REAL de etiquetas y porcentaje de confianza. Procesa la foto en Android y no la sube a Cloud Vision. No otorga XP, monedas ni certifica que un hábito se haya cumplido.
2. **Google Cloud Vision (piloto anterior):** mantiene su acceso restringido por flag `HH_VISION_DEBUG`, despliegue del codebase `vision` y configuración de Firebase. La opción Cloud es independiente y **no es necesaria** para la demo local.

## Ejecución en Android

```bash
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test test/healthy_vision_demo_screen_test.dart
flutter run -t lib/main.dart
```

El proyecto agrega `google_mlkit_image_labeling: 0.14.1` (API `ImageLabeler`, compatible con Dart anterior a 3.8) y un módulo de procesamiento local. El SDK Android mínimo actual es 23. **Requiere reconstruir la aplicación**, no basta con hot reload.

Durante la demostración: abrir Inicio, seleccionar «Probar reconocimiento de imágenes», tomar o elegir fotografía de fruta, comida o botella, y pulsar «Reconocer fotografía». La app muestra las etiquetas detectadas y su confianza. Los nombres de etiquetas del modelo pueden estar en inglés; el sistema no garantiza una identificación correcta en cada imagen.

## Precauciones

- ML Kit interpreta la fotografía; no prueba consumo ni hábitos completados.
- Una foto sin detecciones confiables devuelve un resultado vacío; no se fabrican etiquetas.
- El modelo base se distribuye con la app Android (sin petición a Cloud Vision).
- No se escribe resultado de análisis en Firestore ni se comparte con otros usuarios.
- **No está confirmada la compilación en dispositivo real**: ejecutar los comandos anteriores antes de presentarlo.
- La vía Cloud conserva permisos restringidos y cuotas; no habilitarla sin desplegar y probar App Check.
