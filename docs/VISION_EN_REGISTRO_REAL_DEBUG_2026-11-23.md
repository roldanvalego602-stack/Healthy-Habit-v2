# Reconocimiento visual en Registrar hábito — piloto debug

## Qué se ha integrado

El formulario REAL de Healthy Habit presenta un panel de IA si:
- Flutter está ejecutándose en **debug**
- Se ha iniciado con `--dart-define=HH_VISION_DEBUG=true`
- El usuario ya ha adjuntado una fotografía de máximo 250 KB.

El botón **Analizar con IA (sin XP)** solicita una clasificación orientativa
contra la función `analyzeEvidencePreview` que **solo existe en Firebase
Functions Emulator y proyecto `demo-healthy-habit`**.
Para esta llamada se inicializa **una segunda FirebaseApp** con identificación
ficticia y autenticación anónima en Auth Emulator. Nunca se reutiliza el token
del usuario de producción, ni Firestore de producción para esta prueba.

El análisis es optativo y no registra el resultado, no añade XP,
no cambia el estado del intento ni concede Habit Coins.
Cambiar la fotografía o la categoría descarta el resultado anterior.

## Separación importante

**La aplicación principal sigue conectada a su Firebase habitual.**
Su botón «Registrar» o «Guardar registro» continúa operando
con los datos y recompensas reales. Para probar SOLO el
reconocimiento no pulses Guardar registro; únicamente adjunta
foto y presiona «Analizar con IA (sin XP)».

En el flujo existente, los registros normales siguen con
10 XP sin foto y 15 XP con foto. No se ha cambiado ese comportamiento,
ni se ofrece verificación de 20 XP.

## Prueba en teléfono físico conectado por USB

1. Ejecuta los emuladores en una terminal desde la raíz:
   `export HEALTHY_VISION_LIVE_DEMO=enabled`
   `firebase emulators:start --only auth,functions,firestore --project demo-healthy-habit`
   No habilites la variable hasta confirmar facturación y cuotas de Cloud Vision.
2. En otra terminal: `adb devices`, luego:
   `adb reverse tcp:9099 tcp:9099`
   `adb reverse tcp:5001 tcp:5001`
   `adb reverse tcp:8080 tcp:8080`
3. Ejecuta la **app principal** (NO el entrypoint del laboratorio):
   `flutter run -t lib/main.dart --dart-define=HH_VISION_DEBUG=true --dart-define=HH_VISION_EMULATOR_HOST=127.0.0.1`
4. Entra a cualquier intento activo de un hábito. Adjunta una foto,
   elige la categoría visual y pulsa **Analizar con IA (sin XP)**.
   No pulses **Guardar registro** para esta prueba.
5. Detén el emulador y ejecuta `unset HEALTHY_VISION_LIVE_DEMO` después.

Con un Android Emulator virtual, usa
`--dart-define=HH_VISION_EMULATOR_HOST=10.0.2.2`.
Solo se aceptan hosts loopback/Android Emulator; no URLs
externas ni IP LAN.

## Resultado esperado

- Coincidencia visual orientativa, o imagen no concluyente.
- Lista de etiquetas y porcentajes devueltos por Vision.
- Si el emulador o Cloud Vision falla, se muestra un error local
  sin impedir registrar el hábito normalmente.
- No aparecen resultados si el usuario sustituye la foto.
- Sin flag o en release, el panel ni siquiera se presenta.

## Verificación local

```bash
git pull --ff-only origin main
flutter test test/healthy_vision_debug_test.dart
flutter test test/evidence_visual_preview_test.dart
flutter analyze --no-fatal-infos lib/servicios/healthy_vision_debug_service.dart lib/páginas/habitos/healthy_vision_preview_panel.dart lib/páginas/habitos/registrar_habito_screen.dart
```

**No se ha ejecutado Flutter ni el análisis real de Cloud Vision desde
la conexión GitHub.** Comprobar compilación y funcionalidad en Android.
La integración es experimental y no debe activarse en builds públicas.

## Precauciones

- Cloud Vision es un servicio real y potencialmente facturable aunque
  se invoque desde Firebase Emulator.
- Evita fotografías personales, rostros, menores, documentos y datos privados.
- No se sube la foto a Firestore desde el botón experimental;
  se envía a Cloud Vision únicamente al pulsar Analizar.
- El registro normal *sí* tiene su propio almacenamiento de evidencias
  y no se modificó en esta fase.
- Firebase Installations puede imprimir `FIS_AUTH_ERROR` por las
  credenciales ficticias de la FirebaseApp secundaria; diagnosticar
  una posible falla real con el mensaje del panel y el emulador Functions.
