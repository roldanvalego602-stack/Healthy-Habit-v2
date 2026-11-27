# Healthy Habit — Identidad sonora original v1

Fecha: 26 de noviembre de 2026

## Enfoque de creación

Se diseñaron **11 efectos** cortos a partir de síntesis digital de ondas senoidales, armónicos, barridos de frecuencia y envolventes de amplitud. Las frecuencias, duraciones y combinaciones se definieron específicamente para este proyecto. No se copiaron efectos de Mixkit, videojuegos o grabaciones de terceros. La asistencia de IA en el diseño no garantiza exclusividad legal ni registro de derechos de autor.

## Motor y conexión

- Motor nativo: `android/app/src/main/kotlin/com/example/healthy_habit/HealthySoundEngine.kt`.
- Puente Flutter: `MainActivity.kt` con el canal `healthy_habit/retro_sounds`.
- Servicio Dart: `lib/servicios/healthy_retro_sound_service.dart`.
- Vista para reproducir y probar: **Perfil > Configuración > Experiencia visual > Escuchar sonidos originales**.
- Se respeta el interruptor `sonidosApp` de la cuenta. La selección se actualiza inmediatamente al confirmarse el guardado.
- Los efectos son **Android-only**. No agregan audios al paquete ni requieren conexión para reproducir una vez conocida la preferencia. La lectura inicial de preferencias sí puede consultar Firestore.
- Utilizan el canal de **sonidos de interfaz** del sistema Android. Su volumen puede depender del sistema y del dispositivo.

## Catálogo

| Identificador | Uso | Característica |
|---|---|---|
| tap | Navegación y pasos del tutorial | Microclic ascendente |
| open | Ficha de catálogo | Dos tonos ascendentes |
| guide | Abrir guía mágica | Tres destellos progresivos |
| talk | Respuestas del asistente | Dos señales breves |
| habit | Hábito completado | Tres notas breves ascendentes |
| reward | Recompensa | Destellos ascendentes |
| purchase | Compra confirmada | Confirmación de tienda |
| equip | Equipar accesorio | Barrido corto con acento |
| achievement | Logro y nivel | Secuencia de celebración |
| friend | Aceptar solicitud | Señal social amistosa |
| error | Error suave | Barrido descendente |

## Integración efectiva

Se reproducen efectos en la navegación inferior, en la guía contextual, en la apertura de fichas del catálogo, al aceptar solicitudes de amistad, al equipar accesorios y después de registrar un hábito confirmado. Los efectos de compra, recompensas y asistente conservan sus llamadas existentes y ahora utilizan el motor nuevo. Algunos efectos pueden probarse únicamente en Configuración hasta que se complete su integración específica.

## Pruebas en Ubuntu/Android

```bash
git fetch origin main
git merge --ff-only origin/main
flutter pub get
flutter analyze --no-fatal-infos lib
flutter run -t lib/main.dart
```

**Importante:** no basta Hot Reload porque hay clases Kotlin nuevas. Compila nuevamente.

1. Abre **Perfil > Configuración > Escuchar sonidos originales**.
2. Reproduce los 11 efectos con el volumen multimedia y los sonidos del sistema activados.
3. Desactiva **Sonidos de la app** y comprueba que no se reproduzcan.
4. Enciéndelos de nuevo y prueba una navegación, un registro confirmado y un equipamiento.
5. Comprueba que un error de sonido no impida guardar datos ni avanzar.

## Iteración siguiente

Ajustar timbres a partir del paquete de muestras WAV suministrado por separado, seleccionar la identidad definitiva e integrar los sonidos restantes solamente en eventos confirmados (no en taps que después fallan).

## Limitaciones

No se ha ejecutado `flutter analyze`, las pruebas ni una compilación Android en el entorno de edición del repositorio; requiere validación en dispositivo. Los WAV de muestra son únicamente para evaluación: la aplicación **genera el audio en tiempo real** y no requiere copiarlos al proyecto.
