import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'official_habit_emulator_service.dart';
import 'shop_demo_bootstrap.dart';

/// Diario local de operaciones pendientes, únicamente para el emulador demo.
///
/// El identificador se guarda ANTES de contactar con Functions. Si se pierde
/// la respuesta, el siguiente intento reutiliza exactamente la solicitud
/// anterior; el backend determina si ya se había procesado.
class PendingOfficialHabitOperations {
  const PendingOfficialHabitOperations();

  static final _ongoing = <String>{};
  static const _idPattern = r'^[A-Za-z0-9_-]{16,128}$';
  static const _habitPattern = r'^[A-Za-z0-9_-]{1,128}$';

  String _userId() {
    ShopDemoBootstrap.validateOfficialHabitsMode();
    if (!OfficialHabitEmulatorService.enabled ||
        Firebase.app().options.projectId != ShopDemoBootstrap.demoProjectId) {
      throw StateError('El diario de operaciones solo está disponible '
          'en demo-healthy-habit.');
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Inicia sesión en el emulador antes de registrar hábitos.');
    }
    return uid;
  }

  String _key(String uid, String action, String habitId, String? attemptId) {
    if (!RegExp(_habitPattern).hasMatch(uid) ||
        !RegExp(_habitPattern).hasMatch(habitId) ||
        (attemptId != null && !RegExp(_idPattern).hasMatch(attemptId))) {
      throw StateError('Identificador inválido para la operación pendiente.');
    }
    return 'hh_demo_pending_v1_${uid}_${action}_${habitId}_'
        '${attemptId ?? 'nueva'}';
  }

  Future<Map<String, dynamic>> _run({
    required String action,
    required String habitId,
    String? attemptId,
    int? maxPenalty,
    required Future<Map<String, dynamic>> Function(
      OfficialHabitEmulatorService, Map<String, dynamic>) send,
  }) async {
    final uid = _userId();
    final key = _key(uid, action, habitId, attemptId);
    if (!_ongoing.add(key)) {
      throw StateError('Ya se está enviando esta operación. No la repitas.');
    }
    try {
      final preferences = SharedPreferencesAsync();
      final existing = await preferences.getString(key);
      late final Map<String, dynamic> pending;
      if (existing != null) {
        final decoded = jsonDecode(existing);
        if (decoded is! Map<String, dynamic> ||
            decoded['action'] != action ||
            decoded['habitId'] != habitId ||
            decoded['uid'] != uid ||
            decoded['attemptId'] is! String ||
            !RegExp(_idPattern).hasMatch(decoded['attemptId']) ||
            decoded['operationId'] is! String ||
            !RegExp(_idPattern).hasMatch(decoded['operationId']) ||
            (action != 'activar' && decoded['attemptId'] != attemptId) ||
            (action == 'cancelar' && decoded['maxPenalty'] is! int)) {
          throw StateError('La operación pendiente local está dañada. '
              'No se enviará una operación nueva para evitar duplicados.');
        }
        pending = decoded;
      } else {
        final service = const OfficialHabitEmulatorService();
        pending = {
          'uid': uid,
          'action': action,
          'habitId': habitId,
          'attemptId': attemptId ?? service.newOperationId(),
          'operationId': service.newOperationId(),
          if (maxPenalty != null) 'maxPenalty': maxPenalty,
        };
        // Si falla el almacenamiento, NO llamar al servidor.
        await preferences.setString(key, jsonEncode(pending));
      }
      // Evitar que el cambio de sesión durante un await actúe sobre otro UID.
      if (_userId() != uid) {
        throw StateError('Cambió la sesión. Se conserva la operación pendiente.');
      }
      final answer = await send(const OfficialHabitEmulatorService(), pending);
      // Si falla la limpieza tras recibir éxito, la próxima llamada será
      // idempotente: se conserva el mismo operationId.
      await preferences.remove(key);
      return answer;
    } finally {
      _ongoing.remove(key);
    }
  }

  Future<Map<String, dynamic>> activate(String habitId) => _run(
    action: 'activar', habitId: habitId,
    send: (service, saved) => service.activate(
      habitId: habitId,
      attemptId: saved['attemptId'] as String,
      operationId: saved['operationId'] as String,
    ),
  );

  Future<Map<String, dynamic>> register(
    String habitId, String attemptId,
  ) => _run(
    action: 'registrar', habitId: habitId, attemptId: attemptId,
    send: (service, saved) => service.register(
      habitId: habitId,
      attemptId: saved['attemptId'] as String,
      operationId: saved['operationId'] as String,
    ),
  );

  Future<Map<String, dynamic>> cancel(
    String habitId, String attemptId, int maxPenalty,
  ) => _run(
    action: 'cancelar', habitId: habitId, attemptId: attemptId,
    maxPenalty: maxPenalty,
    send: (service, saved) => service.cancel(
      habitId: habitId,
      attemptId: saved['attemptId'] as String,
      operationId: saved['operationId'] as String,
      maxPenalty: saved['maxPenalty'] as int,
    ),
  );
}
