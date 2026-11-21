import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Contrato del modo aislado de tienda. No contiene credenciales reales.
class ShopDemoBootstrap {
  ShopDemoBootstrap._();

  static const enabled = bool.fromEnvironment(
    'HH_SHOP_DEMO_FIREBASE', defaultValue: false);
  static const purchaseEnabled = bool.fromEnvironment(
    'HH_DEMO_SHOP_PURCHASE', defaultValue: false);
  static const demoProjectId = 'demo-healthy-habit';
  static const host = String.fromEnvironment(
    'HH_EMULATOR_HOST', defaultValue: '127.0.0.1');

  static void validateMode(bool demo, bool purchase) {
    if (demo != purchase) {
      throw StateError(
        'El modo de tienda demo exige activar juntos '
        'HH_SHOP_DEMO_FIREBASE y HH_DEMO_SHOP_PURCHASE.');
    }
  }

  static void validateHost(String value) {
    // Restringir a loopback / gateway Android Emulator; no endpoints
    // públicos o de red local sin revisión específica.
    if (value != '127.0.0.1' && value != 'localhost' &&
        value != '10.0.2.2') {
      throw StateError('Host del emulador no autorizado.');
    }
  }

  static FirebaseOptions get demoOptions => FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: kIsWeb
        ? '1:1234567890:web:abcdef1234567890'
        : '1:1234567890:android:abcdef1234567890',
    messagingSenderId: '1234567890',
    projectId: demoProjectId,
    authDomain: 'demo-healthy-habit.firebaseapp.com',
  );

  static void validateInitializedProject(String projectId) {
    if (projectId != demoProjectId) {
      throw StateError(
        'Firebase no se inició en demo-healthy-habit. '
        'Se bloquea el arranque de prueba.');
    }
  }
}
