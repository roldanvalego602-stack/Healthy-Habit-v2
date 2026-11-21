import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Puente experimental: nunca envía precios ni saldos al servidor.
/// Requiere Firebase Auth, Firestore y Functions en un proyecto DEMO.
class DemoShopPurchaseGateway {
  DemoShopPurchaseGateway._();

  static const requested = bool.fromEnvironment(
    'HH_DEMO_SHOP_PURCHASE', defaultValue: false);
  static const demoProjectId = 'demo-healthy-habit';
  static const emulatorHost = String.fromEnvironment(
    'HH_FUNCTIONS_EMULATOR_HOST', defaultValue: '127.0.0.1');
  static const emulatorPort = int.fromEnvironment(
    'HH_FUNCTIONS_EMULATOR_PORT', defaultValue: 5001);

  // Conservar el ID si una llamada falla por conectividad.
  static final _pending = <String, String>{};

  static void requireDemoProject(bool enabled, String projectId) {
    if (!enabled || projectId != demoProjectId) {
      throw StateError(
        'Compras experimentales bloqueadas: se requiere '
        'Firebase demo-healthy-habit y una compilación de prueba.');
    }
  }

  static Map<String, String> purchasePayload(
      String itemId, String operationId) {
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(itemId) ||
        !RegExp(r'^[A-Za-z0-9_-]{16,128}$').hasMatch(operationId)) {
      throw ArgumentError('Identificadores de compra inválidos.');
    }
    return {'itemId': itemId, 'operationId': operationId};
  }

  static String _newOperationId() {
    final random = Random.secure();
    final suffix = List<int>.generate(16, (_) => random.nextInt(256))
        .map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return 'shop_${DateTime.now().microsecondsSinceEpoch}_$suffix';
  }

  static Future<void> purchase(String itemId) async {
    // Fallar cerrado antes de instanciar FirebaseFunctions.
    requireDemoProject(requested, Firebase.app().options.projectId);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Inicia sesión de prueba para comprar artículos.');
    }
    if (emulatorHost.isEmpty || emulatorPort < 1 || emulatorPort > 65535) {
      throw StateError('Configuración del emulador inválida.');
    }
    final key = '${user.uid}:$itemId';
    final operationId = _pending.putIfAbsent(key, _newOperationId);
    final payload = purchasePayload(itemId, operationId);

    final functions = FirebaseFunctions.instanceFor(
      app: Firebase.app(), region: 'us-central1');
    functions.useFunctionsEmulator(emulatorHost, emulatorPort);
    final response = await functions
        .httpsCallable('purchaseDemoShopItem')
        .call<Map<String, dynamic>>(payload);
    final result = response.data;
    if (result['itemId'] != itemId ||
        result['price'] is! int ||
        result['balanceAfter'] is! int ||
        (result['price'] as int) <= 0 ||
        (result['balanceAfter'] as int) < 0) {
      throw StateError('Respuesta inesperada del servidor de compras.');
    }
    _pending.remove(key);
  }
}
