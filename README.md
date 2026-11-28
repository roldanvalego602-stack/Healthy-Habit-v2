# Healthy Habit

Aplicación Flutter de seguimiento de hábitos saludables, gamificación y personalización, desarrollada como proyecto universitario.

## Seguimiento del proyecto

El documento central para consultar **todas las funcionalidades planificadas**, su estado de desarrollo, pruebas pendientes y prioridades es:

**[Inventario maestro de funcionalidades](docs/INVENTARIO_MAESTRO_FUNCIONALIDADES.md)**.

El inventario distingue implementación en código, pruebas reportadas, pilotos de demostración y funciones pendientes. No debe confundirse con una certificación de producción.

**Nuevos módulos (por validar en Android):** [modelo ONNX opcional de alimentos](docs/RECONOCIMIENTO_ONNX_ALIMENTOS.md) y [Entrena tu mente: Sudoku y sopa de letras](docs/ENTRENAMIENTO_MENTAL.md). Los ejercicios mentales guardan progreso local, sin acreditar XP ni monedas oficiales.

**Función central:** [implementación de evidencias fotográficas y pruebas de seguridad](docs/IMPLEMENTACION_EVIDENCIAS_2026-11-27.md). Incluye reconocimiento local, fotos privadas de beta, resultados visuales orientativos y limpieza temporal. Las callables de beta siguen deshabilitadas hasta auditoría de reglas y App Check.

Para las decisiones detalladas de UFO, chatbot y tienda, consultar [su hoja de ruta](docs/ROADMAP_UFO_CHATBOT_TIENDA.md).

El Easter egg de la cueva está documentado en [Archivo 001: Santuario del Titán](docs/EASTER_EGG_SANTUARIO_TITAN.md), con pistas, pruebas y restricciones de despliegue.

## Desarrollo local

**Versión de herramientas requerida:** Flutter **3.38.0** (Dart 3.10.x), fijada en `.fvmrc`. No basta con cambiar solo la versión de Dart: el proyecto también utiliza complementos y configuración Android compatibles con Flutter 3.38. `google_mlkit_image_labeling: 0.15.0` requiere Dart 3.8 o superior. La versión antigua 0.14.1 se descartó por fallos de compilación nativa al resolver AndroidX actualizado.

Si tu Flutter habitual muestra Dart **3.7.0**, instala la versión probada **en otra carpeta** para no romper tus demás proyectos en Linux:

```bash
mkdir -p "$HOME/SDK"
git clone --depth 1 --branch 3.38.0 https://github.com/flutter/flutter.git "$HOME/SDK/flutter-3.38.0"

# La variable solo afecta a esta terminal.
export PATH="$HOME/SDK/flutter-3.38.0/bin:$PATH"
hash -r
flutter --version
flutter doctor -v
```

El comando `flutter --version` debe mostrar Flutter **3.38.0**. Dentro de la carpeta de Healthy Habit:

```bash
git fetch origin main
git merge --ff-only origin/main
flutter clean
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test test/mental_daily_puzzles_test.dart
flutter test test/mental_training_widget_test.dart
flutter test test/healthy_specific_food_recognition_test.dart
flutter test test/healthy_food_model_service_test.dart
flutter run
```

Se requiere **JDK 17**, Android SDK y las licencias del Android SDK instaladas para compilar en Android. Si usas FVM, la misma versión del SDK puede instalarse con `fvm install` desde la raíz del repositorio y ejecutarse con `fvm flutter ...`; no es obligatorio utilizar FVM. No ejecutar `flutter upgrade` a la última versión de manera indiscriminada, porque la versión más reciente puede requerir otro Gradle.

> La compilación automatizada del APK y las pruebas Flutter usan la misma versión 3.38.0. No se ha hecho una certificación de precisión del reconocimiento visual con fotos reales.

Antes de distribuir una beta, revisar las restricciones en [cierre de avances y demostración](docs/CIERRE_AVANCES_Y_DEMO_2026-11-25.md).
