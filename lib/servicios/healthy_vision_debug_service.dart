import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'evidence_demo_service.dart';

/// Entorno de IA totalmente separado de la cuenta Firebase real.
/// Nunca llamar desde una compilación release ni usar un endpoint público.
class HealthyVisionDebugService {
  HealthyVisionDebugService._();

  static const enabledByFlag = bool.fromEnvironment(
    'HH_VISION_DEBUG', defaultValue: false,
  );
  static bool get enabled => kDebugMode && enabledByFlag;

  // Modo real de piloto: reutiliza exclusivamente la sesión Firebase actual.
  // Permanece apagado por defecto y no se habilita en release.
  static const useLiveBackend = bool.fromEnvironment(
    'HH_VISION_LIVE_BACKEND', defaultValue: false,
  );

  static const host = String.fromEnvironment(
    'HH_VISION_EMULATOR_HOST', defaultValue: '127.0.0.1',
  );
  static const _appName = 'healthy-vision-debug-secondary';
  static const _projectId = 'demo-healthy-habit';
  static Future<EvidenceDemoService>? _initializing;

  static String validateHost(String value) {
    if (!const {'127.0.0.1', 'localhost', '10.0.2.2'}.contains(value)) {
      throw StateError('Solo se permite conexión local al emulador de pruebas.');
    }
    return value;
  }

  static Future<EvidenceDemoService> connect() {
    if (!enabled) {
      throw StateError('Análisis experimental deshabilitado.');
    }
    return _initializing ??= _create().catchError((Object error) {
      _initializing = null;
      throw error;
    });
  }

  static Future<EvidenceDemoService> _create() async {
    final emulatorHost = validateHost(host);
    // Estos valores son FICTICIOS, solo sirven para que Android acepte
    // el formato. No utilizar google-services.json ni credenciales reales.
    const options = FirebaseOptions(
      apiKey: 'AIzaSy000000000000000000000000000000000',
      appId: '1:1234567890:android:mrhealthy-emulator-demo',
      messagingSenderId: '1234567890',
      projectId: _projectId,
    );
    final existing = Firebase.apps.where((app) => app.name == _appName);
    final app = existing.isEmpty
        ? await Firebase.initializeApp(name: _appName, options: options)
        : existing.first;
    if (app.options.projectId != _projectId) {
      throw StateError('El entorno secundario no corresponde al proyecto demo.');
    }
    final auth = FirebaseAuth.instanceFor(app: app);
    final functions = FirebaseFunctions.instanceFor(
      app: app, region: 'us-central1',
    );
    await auth.useAuthEmulator(
      emulatorHost, 9099, automaticHostMapping: false,
    );
    functions.useFunctionsEmulator(
      emulatorHost, 5001, automaticHostMapping: false,
    );
    if (auth.currentUser == null) {
      final credential = await auth.signInAnonymously();
      if (credential.user == null) {
        throw StateError('No se inició la sesión anónima del laboratorio.');
      }
    }
    return EvidenceDemoService.firebase(functions);
  }

  static Future<DemoVisualPreview> analyze(
    Uint8List bytes, String profileId,
  ) async {
    if (!enabled) throw StateError('Piloto deshabilitado.');
    if (useLiveBackend) {
      final app = Firebase.app();
      if (app.options.projectId != 'cloud-firestore-d8c61') {
        throw StateError('El piloto real exige el proyecto Healthy Habit.');
      }
      if (FirebaseAuth.instanceFor(app: app).currentUser == null) {
        throw StateError('Inicia sesión antes de analizar imágenes.');
      }
      final functions = FirebaseFunctions.instanceFor(
        app: app, region: 'us-central1',
      );
      // No se invocan emuladores ni se crea un usuario anónimo.
      final response = await functions.httpsCallable(
        'analyzeEvidencePreviewLive',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      ).call({
        'imageBase64': base64Encode(bytes),
        'profileId': profileId,
      });
      if (response.data is! Map) {
        throw const FormatException('Respuesta inválida del backend.');
      }
      return DemoVisualPreview.fromMap(
        Map<String, dynamic>.from(response.data as Map),
      );
    }
    final service = await connect();
    return service.previewPhoto(bytes, profileId);
  }
}
