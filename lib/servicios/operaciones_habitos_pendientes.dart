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
/// Una solicitud ya confirmada por el usuario y guardada localmente.
class OperacionHabitoPendiente {
  const OperacionHabitoPendiente({
    required this.accion,
    required this.habitoId,
    required this.intentoId,
    this.penalizacionMaxima,
  });
  final String accion;
  final String habitoId;
  final String intentoId;
  final int? penalizacionMaxima;
}

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
    bool recoveryOnly = false,
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
        if (recoveryOnly) {
          throw StateError('No existe la operación pendiente a recuperar.');
        }
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

  /// Solo enumera solicitudes de la sesión actual. No crea ni envía nada.
  Future<List<OperacionHabitoPendiente>> listarPendientes() async {
    final uid = _userId();
    final preferences = SharedPreferencesAsync();
    final keys = await preferences.getKeys();
    final prefix = 'hh_demo_pending_v1_${uid}_';
    final items = <OperacionHabitoPendiente>[];
    for (final key in keys.where((key) => key.startsWith(prefix))) {
      final raw = await preferences.getString(key);
      if (raw == null) continue;
      final Object? decoded;
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        throw StateError('Hay una operación local dañada; '
            'no se enviará ninguna solicitud nueva.');
      }
      if (decoded is! Map<String, dynamic>) {
        throw StateError('Formato de operación local inválido.');
      }
      final action = decoded['action'];
      final habitId = decoded['habitId'];
      final attemptId = decoded['attemptId'];
      final operationId = decoded['operationId'];
      final maxPenalty = decoded['maxPenalty'];
      if (decoded['uid'] != uid || action is! String ||
          !const ['activar', 'registrar', 'cancelar'].contains(action) ||
          habitId is! String || attemptId is! String ||
          operationId is! String ||
          !RegExp(_habitPattern).hasMatch(habitId) ||
          !RegExp(_idPattern).hasMatch(attemptId) ||
          !RegExp(_idPattern).hasMatch(operationId) ||
          (action == 'cancelar' && (maxPenalty is! int ||
              maxPenalty < 0 || maxPenalty > 25)) ||
          _key(uid, action, habitId,
              action == 'activar' ? null : attemptId) != key) {
        throw StateError('Una operación pendiente tiene campos inválidos. '
            'No se reenviará automáticamente.');
      }
      items.add(OperacionHabitoPendiente(
        accion: action, habitoId: habitId, intentoId: attemptId,
        penalizacionMaxima: maxPenalty is int ? maxPenalty : null,
      ));
    }
    if (_userId() != uid) {
      throw StateError('Cambió la sesión al listar operaciones pendientes.');
    }
    return items;
  }

  /// Reenvía EXCLUSIVAMENTE una solicitud existente con su operationId.
  Future<Map<String, dynamic>> recuperar(
    OperacionHabitoPendiente item,
  ) => _run(
    action: item.accion,
    habitId: item.habitoId,
    attemptId: item.accion == 'activar' ? null : item.intentoId,
    maxPenalty: item.penalizacionMaxima,
    recoveryOnly: true,
    send: (service, saved) {
      final habitId = saved['habitId'] as String;
      final attemptId = saved['attemptId'] as String;
      final operationId = saved['operationId'] as String;
      switch (item.accion) {
        case 'activar':
          return service.activate(
            habitId: habitId, attemptId: attemptId, operationId: operationId);
        case 'registrar':
          return service.register(
            habitId: habitId, attemptId: attemptId, operationId: operationId);
        case 'cancelar':
          return service.cancel(
            habitId: habitId, attemptId: attemptId, operationId: operationId,
            maxPenalty: saved['maxPenalty'] as int);
        default:
          throw StateError('Acción pendiente no reconocida.');
      }
    },
  );

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
