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
    apiKey: 'demo-key',
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

  await auth.useAuthEmulator(host, 9099);
  functions.useFunctionsEmulator(host, 5001);

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
