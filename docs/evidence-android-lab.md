# Laboratorio Android de desafíos de Mr. Healthy

Estado: **experimental, solo emuladores**. No está integrado a la navegación de Healthy Habit, no envía fotografías, no usa visión artificial, no verifica hábitos y no entrega XP.

## Aislamiento

- Punto de entrada: `lib/demo/evidence_demo_main.dart` (distinto de `lib/main.dart`).
- La app Firebase que se crea usa nombre secundario y opciones explícitas con `projectId: demo-healthy-habit`. No usa `lib/firebase_options.dart` ni se conecta a Firestore desde el cliente.
- Los SDK de Authentication y Functions se conectan a `127.0.0.1:9099` y `127.0.0.1:5001`, respectivamente.
- `adb reverse` permite usar esas direcciones desde un teléfono Android conectado por USB.
- El endpoint `prepareEvidenceDemo` solo actúa cuando `FUNCTIONS_EMULATOR=true` y `GCLOUD_PROJECT=demo-healthy-habit`. Crea el hábito ficticio `demo-water/demo-attempt` únicamente para el UID del usuario anónimo del emulador y no modifica la economía.
- Cámara: la imagen se muestra desde memoria local del teléfono y **no se envía** a ningún servidor. No hay reconocimiento visual en esta fase.
- `checkEvidenceChallengeCode` solo prueba la lógica de consumo de un código escrito; su resultado siempre informa `imageVerified: false` y `xpAwarded: 0`.

## Requisitos Linux Mint

- Flutter, Android SDK, `adb`, dispositivo Android con depuración USB habilitada.
- Java >= 21 para Firestore Emulator.
- Firebase Emulator Suite con Authentication 9099, Functions 5001, Firestore 8080.

## Instrucciones

**Terminal 1**, desde la raíz de Healthy Habit:

```bash
firebase emulators:start --only auth,functions,firestore --project demo-healthy-habit
```

**Terminal 2**, conectar teléfono Android por USB y aceptar depuración, después:

```bash
adb devices
adb reverse tcp:9099 tcp:9099
adb reverse tcp:5001 tcp:5001
adb reverse --list
```

Si Flutter no detecta Android, revisar `flutter devices`. `adb reverse` requiere conexión ADB activa. No se requiere exponer el emulador a toda la red Wi-Fi.

**Terminal 3**, desde la raíz:

```bash
flutter pub get
flutter test test/evidence_demo_service_test.dart
flutter run -t lib/demo/evidence_demo_main.dart
```

La app debe mostrar **Mr. Healthy · laboratorio**, no la pantalla normal de Healthy Habit. Tocar «Conectar a Firebase local», elegir una de cinco alternativas, «Solicitar desafío», «Tomar fotografía de prueba» y, si se desea, «Probar consumo del código (sin analizar foto)».

La cámara solo muestra la foto localmente; el botón de comprobación no la analiza ni comprueba su actualidad. Después de comprobar el código, el desafío se consume. Para una nueva prueba, esperar caducidad o reiniciar los emuladores (los datos son efímeros si no se exportan).

## Seguridad y limitaciones

- Este es un prototipo de desarrollo. **No usar en una compilación de producción** ni conceder recompensas.
- Android permite tráfico HTTP sin cifrar solo en el manifiesto debug: `android/app/src/debug/AndroidManifest.xml`; esto no modifica el manifiesto release.
- Si la app arroja `UNAVAILABLE`, revisar emuladores, terminales, `adb reverse`, el puerto y la región.
- Si la app arroja `FAILED_PRECONDITION`, revisar que el intento siga activo y que no haya otro desafío sin caducar.
- Si la app arroja `CONFIGURATION_NOT_FOUND` o un fallo de autenticación, verificar Auth Emulator y sus registros.
- El funcionamiento del lado cliente dependerá de la compatibilidad del SDK FlutterFire en la instalación local. La integración de Android físico **aún no se ha probado** en este repositorio.
- Antes de verificación auténtica: OCR del código **en la imagen**; validación de objeto + contenido; consumo atómico al verificar; backend autoritativo para XP; reglas Firestore; cuota y retención de imágenes.

**No ejecutar `firebase deploy` para probar este laboratorio**.
