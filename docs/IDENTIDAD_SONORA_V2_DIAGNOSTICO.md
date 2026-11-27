# Healthy Habit — corrección de reproducción e identidad sonora v2

## Qué fallaba y qué se corrigió

1. El motor anterior usaba `AudioAttributes.USAGE_ASSISTANCE_SONIFICATION`. En algunos teléfonos, ese canal está silenciado o tiene un volumen distinto del multimedia. La v2 usa `USAGE_MEDIA`.
2. Las muestras anteriores tenían una amplitud pequeña y compartían estructuras rítmicas parecidas. La v2 eleva el nivel útil con limitación de picos y dispone de 7 familias de timbres: suave, cristal, madera, campana, digital, aire y grave.
3. El motor ocultaba los errores dentro de `catch`, y el puente respondía éxito antes de reproducir. La biblioteca ahora ofrece un método `preview` con el estado real de inicialización y escritura de AudioTrack.
4. La pantalla permite escuchar las muestras y leer el mensaje diagnóstico. La preferencia `sonidosApp` se sincroniza con la cuenta al abrir Configuración.
5. Si se utiliza scrcpy con `--no-audio`, el audio no se transmitirá a la laptop. Para verificar el altavoz del teléfono, escucha directamente el OPPO; para escuchar en Ubuntu usa scrcpy 5.0.1 sin `--no-audio`, si el sistema lo soporta.

## Sonidos y propósito

| Efecto | Identidad | Evento |
|---|---|---|
| tap | golpe de madera suave | navegación |
| open | aire y cristal | catálogo |
| guide | destellos cristalinos superpuestos | ayuda mágica |
| talk | dos sílabas electrónicas | chatbot |
| habit | golpe + confirmación ascendente | hábito completado |
| reward | cristales ascendentes | premio |
| purchase | doble clic tangible y campana | compra |
| equip | cierre mecánico suave | armario |
| achievement | celebración grave y cristalina | subir nivel |
| friend | dos voces cálidas convergentes | amistad |
| error | dos notas graves descendentes | error sin sobresalto |

## Aplicar cambios

```bash
git fetch origin main
git merge --ff-only origin/main
flutter pub get
flutter analyze --no-fatal-infos lib
flutter run -t lib/main.dart
```

Se modificaron clases Kotlin. **Hot Reload no instala estos cambios**; debe reconstruirse la aplicación Android.

En el OPPO, sube el **volumen multimedia**, entra en `Perfil > Configuración > Experiencia visual > Escuchar sonidos originales`, y reproduce cada efecto. La pantalla presentará un diagnóstico tipo `Reproducción enviada a Android: guide (... ms)`, o un error concreto.

Si hay resultado positivo pero no se oye, revisa Bluetooth, dispositivos de salida, volumen multimedia y modo No molestar. Si solo falla en scrcpy con `--no-audio`, la fuente del problema es la reproducción remota, no necesariamente la app.

## Límites de validación

No se dispone de un entorno Flutter/Gradle/OPPO en la sesión de edición, así que estos cambios aún no se han compilado ni probado físicamente aquí. La prueba concluyente es ejecutar `flutter analyze`, compilar Android y escuchar en el teléfono. Las muestras WAV proporcionadas aparte están sintetizadas con los mismos parámetros y sirven para evaluación auditiva; la app genera sus propias muestras en el dispositivo.
