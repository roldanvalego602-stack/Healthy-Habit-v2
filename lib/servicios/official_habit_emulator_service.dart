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
    late final HttpsCallableResult<dynamic> response;
    try {
      response = await _functions.httpsCallable(callable).call(payload);
    } on FirebaseFunctionsException catch (error) {
      // Solo el modo demo puede llamar este servicio. No revelar datos
      // de usuario ni payloads, pero sí conservar el código útil.
      final hint = error.code == 'internal'
          ? 'Revisa la terminal de Functions Emulator y busca '
              '[official-demo-callable].'
          : error.code == 'unavailable'
              ? 'Comprueba que Functions Emulator esté activo en el puerto 5001.'
              : error.message ?? 'Consulta los registros del emulador.';
      throw StateError('Error de servidor de pruebas '
          '(${error.code}) al ejecutar $callable. $hint');
    }
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
    String note = '',
    Map<String, dynamic>? interaction,
  }) => _call('registerOfficialHabitDemo', {
    'habitId': habitId,
    'attemptId': attemptId,
    'operationId': operationId,
    if (note.isNotEmpty) 'note': note,
    if (interaction != null) 'interaction': interaction,
  });

  /// Reserva privada de imagen para un registro pendiente.
  /// No acredita XP, no crea el registro ni verifica la fotografía.
  Future<Map<String, dynamic>> reserveEvidence({
    required String habitId,
    required String attemptId,
    required String operationId,
  }) => _call('reserveHabitEvidenceDemo', {
    'habitId': habitId,
    'attemptId': attemptId,
    'operationId': operationId,
  });

  /// Asocia una foto ya subida a un registro confirmado, sin XP adicional.
  /// Requiere reserva y objeto válidos en los emuladores.
  Future<Map<String, dynamic>> attachEvidence({
    required String habitId,
    required String attemptId,
    required String operationId,
  }) => _call('attachHabitEvidenceDemo', {
    'habitId': habitId,
    'attemptId': attemptId,
    'operationId': operationId,
  });

  /// Reclamo seguro: el backend determina el usuario y las monedas.
  /// Únicamente en el Firebase Emulator del proyecto demo.
  Future<Map<String, dynamic>> claimDailyStreakReward({
    required String day,
  }) {
    if (!RegExp(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$').hasMatch(day)) {
      throw ArgumentError('Selecciona un día válido para recoger el premio.');
    }
    return _call('claimDailyStreakReward', {'day': day});
  }
}
