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

```bash
flutter pub get
flutter analyze --no-fatal-infos lib
flutter test
flutter run
```

Antes de distribuir una beta, revisar las restricciones en [cierre de avances y demostración](docs/CIERRE_AVANCES_Y_DEMO_2026-11-25.md).
