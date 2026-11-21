import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import 'shop_demo_bootstrap.dart';

/// Puente de pruebas hacia Cloud Functions Emulator, jamás producción.
/// El modo real sigue intacto hasta disponer de un servidor de producción.
class OfficialHabitEmulatorService {
  const OfficialHabitEmulatorService();

  static bool get enabled => ShopDemoBootstrap.officialHabitsEnabled;

  FirebaseFunctions get _functions {
    ShopDemoBootstrap.validateOfficialHabitsMode();
    if (!enabled ||
        Firebase.app().options.projectId != ShopDemoBootstrap.demoProjectId) {
      throw StateError('No se permite invocar operaciones oficiales fuera de demo.');
    }
    return FirebaseFunctions.instanceFor(
      app: Firebase.app(), region: 'us-central1');
  }

  String newOperationId() => FirebaseFirestore.instanceFor(
    app: Firebase.app(), databaseId: 'default',
  ).collection('_local_operation_ids').doc().id;

  Future<Map<String, dynamic>> _call(
    String callable, Map<String, dynamic> payload,
  ) async {
    final response = await _functions.httpsCallable(callable).call(payload);
    final raw = response.data;
    if (raw is! Map) {
      throw StateError('Respuesta inválida de Functions Emulator.');
    }
    return Map<String, dynamic>.from(raw);
  }

  Future<Map<String, dynamic>> activate({
    required String habitId,
    required String attemptId,
    required String operationId,
  }) => _call('activateOfficialHabitDemo', {
    'habitId': habitId,
    'attemptId': attemptId,
    'operationId': operationId,
  });

  Future<Map<String, dynamic>> cancel({
    required String habitId,
    required String attemptId,
    required String operationId,
    required int maxPenalty,
  }) => _call('cancelOfficialHabitDemo', {
    'habitId': habitId,
    'attemptId': attemptId,
    'operationId': operationId,
    'maxPenalty': maxPenalty,
  });

  Future<Map<String, dynamic>> register({
    required String habitId,
    required String attemptId,
    required String operationId,
  }) => _call('registerOfficialHabitDemo', {
    'habitId': habitId,
    'attemptId': attemptId,
    'operationId': operationId,
  });
}
