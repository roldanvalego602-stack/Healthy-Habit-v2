import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'evidence_demo_screen.dart';

/// Punto de entrada alternativo: NO importa firebase_options.dart de producción.
/// Úsalo únicamente en Android debug con emuladores locales.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const projectId = 'demo-healthy-habit';
  const host = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );
  const options = FirebaseOptions(
    // Formato válido para el SDK nativo Android, pero clave ficticia.
    // SOLO se utiliza con Firebase Auth Emulator; nunca con producción.
    apiKey: 'AIzaSy000000000000000000000000000000000',
    appId: '1:1234567890:android:mrhealthy-emulator-demo',
    messagingSenderId: '1234567890',
    projectId: projectId,
  );

  // Aplicación secundaria: no se usa la configuración de Firebase productiva.
  final app = await Firebase.initializeApp(
    name: 'mr-healthy-emulator-demo',
    options: options,
  );
  final auth = FirebaseAuth.instanceFor(app: app);
  final functions = FirebaseFunctions.instanceFor(
    app: app,
    region: 'us-central1',
  );

  // Android emulado: pasa EMULATOR_HOST=10.0.2.2.
  // Teléfono USB: adb reverse y EMULATOR_HOST=127.0.0.1.
  // Desactivar el remapeo automático evita que un teléfono físico intente
  // conectarse a 10.0.2.2, una IP reservada para el emulador Android.
  await auth.useAuthEmulator(host, 9099, automaticHostMapping: false);
  functions.useFunctionsEmulator(host, 5001, automaticHostMapping: false);

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Mr. Healthy - laboratorio',
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF168F69),
    ),
    home: EvidenceDemoScreen(auth: auth, functions: functions),
  ));
}
