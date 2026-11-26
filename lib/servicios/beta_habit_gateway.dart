import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cliente de preparación para las callables oficiales de beta cerrada.
///
/// No está conectado a la UI y permanece deshabilitado por defecto.
/// El backend exige App Check, Auth, UIDs permitidos y reglas verificadas.
/// Nunca usar con las reglas abiertas actuales de la base 'default'.
class BetaHabitGateway {
  const BetaHabitGateway();

  static const projectId = 'cloud-firestore-d8c61';
  static const enabled = bool.fromEnvironment(
    'HH_BETA_HABITS_CLIENT', defaultValue: false);

  static const _functions = <String, String>{
    'activar': 'activateOfficialHabitBeta',
    'cancelar': 'cancelOfficialHabitBeta',
    'registrar': 'registerOfficialHabitBeta',
  };

  void _validate() {
    if (!enabled) {
      throw StateError('El cliente de beta está deshabilitado.');
    }
    if (Firebase.app().options.projectId != projectId) {
      throw StateError('Proyecto Firebase distinto al esperado para beta.');
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Inicia sesión antes de operar con hábitos.');
    }
  }

  String newOperationId() => FirebaseFirestore.instanceFor(
    app: Firebase.app(), databaseId: 'default',
  ).collection('_local_operation_ids').doc().id;

  Future<Map<String, dynamic>> send(
    String action, Map<String, dynamic> payload,
  ) async {
    _validate();
    final callableName = _functions[action];
    if (callableName == null) {
      throw ArgumentError.value(action, 'action', 'Acción desconocida.');
    }
    final originalUser = FirebaseAuth.instance.currentUser!.uid;
    final result = await FirebaseFunctions.instanceFor(
      app: Firebase.app(), region: 'us-central1',
    ).httpsCallable(callableName).call<Map<String, dynamic>>(payload);
    if (FirebaseAuth.instance.currentUser?.uid != originalUser) {
      throw StateError('La sesión cambió; revisa la operación pendiente.');
    }
    return Map<String, dynamic>.from(result.data);
  }
}

/// Solicitudes únicas y recuperables. El operationId se conserva en disco
/// ANTES de llamar al servidor y no se reemplaza tras fallos de red.
/// Las operaciones con evidencia no se admiten en esta etapa.
class PendingBetaHabitOperations {
  const PendingBetaHabitOperations();
  static final Set<String> _inFlight = <String>{};
  static final RegExp _id = RegExp(r'^[A-Za-z0-9_-]{16,128}$');
  static final RegExp _habitId = RegExp(r'^(alim|hidr|ener|bien)_00[1-9]$');

  static String keyFor({
    required String uid,
    required String action,
    required String habitId,
    required String attemptId,
  }) {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(uid) ||
        !_habitId.hasMatch(habitId) ||
        !const {'activar', 'cancelar', 'registrar'}.contains(action) ||
        (action != 'activar' && !_id.hasMatch(attemptId))) {
      throw ArgumentError('Datos de identificación incorrectos.');
    }
    return 'hh_beta_pending_v1_${uid}_${action}_${habitId}_'
        '${action == 'activar' ? 'nueva' : attemptId}';
  }

  Future<Map<String, dynamic>> execute({
    required String action,
    required String habitId,
    String? attemptId,
    int? maxPenalty,
    String note = '',
    Map<String, dynamic>? interaction,
    bool recoveryOnly = false,
  }) async {
    const gateway = BetaHabitGateway();
    // Fail-closed antes de crear una operación pendiente.
    if (!BetaHabitGateway.enabled ||
        Firebase.app().options.projectId != BetaHabitGateway.projectId) {
      throw StateError('La beta no está habilitada para este proyecto.');
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Inicia sesión para guardar un hábito.');
    }
    if (action == 'cancelar' &&
        (maxPenalty == null || maxPenalty < 0 || maxPenalty > 25)) {
      throw ArgumentError('Penalización máxima inválida.');
    }
    if (note.length > 500 ||
        RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]').hasMatch(note)) {
      throw ArgumentError('Nota inválida.');
    }
    if (action != 'registrar' && (note.isNotEmpty || interaction != null)) {
      throw ArgumentError('Los datos de registro no pertenecen a esta acción.');
    }
    final requestAttempt = attemptId ?? '';
    final key = keyFor(
      uid: uid, action: action, habitId: habitId,
      attemptId: requestAttempt,
    );
    if (!_inFlight.add(key)) {
      throw StateError('Esta operación ya está siendo enviada.');
    }
    try {
      final prefs = SharedPreferencesAsync();
      final stored = await prefs.getString(key);
      late final Map<String, dynamic> data;
      if (stored == null) {
        if (recoveryOnly) {
          throw StateError('No existe una operación de beta pendiente.');
        }
        data = {
          'habitId': habitId,
          'attemptId': attemptId ?? gateway.newOperationId(),
          'operationId': gateway.newOperationId(),
          if (action == 'cancelar') 'maxPenalty': maxPenalty,
          if (action == 'registrar' && note.isNotEmpty) 'note': note,
          if (action == 'registrar' && interaction != null)
            'interaction': interaction,
        };
        await prefs.setString(key, jsonEncode(data));
      } else {
        final decoded = jsonDecode(stored);
        if (decoded is! Map ||
            decoded['habitId'] != habitId ||
            decoded['attemptId'] is! String ||
            !_id.hasMatch(decoded['attemptId'] as String) ||
            decoded['operationId'] is! String ||
            !_id.hasMatch(decoded['operationId'] as String) ||
            (action != 'activar' && decoded['attemptId'] != attemptId) ||
            (action == 'cancelar' && decoded['maxPenalty'] != maxPenalty) ||
            (action == 'registrar' &&
                (decoded['note'] ?? '') != note) ||
            (action == 'registrar' &&
                jsonEncode(decoded['interaction']) != jsonEncode(interaction))) {
          throw StateError('La solicitud guardada no coincide; no se duplicará.');
        }
        data = Map<String, dynamic>.from(decoded);
      }
      if (FirebaseAuth.instance.currentUser?.uid != uid) {
        throw StateError('Cambió la sesión; la operación queda pendiente.');
      }
      final result = await gateway.send(action, data);
      await prefs.remove(key);
      return result;
    } finally {
      _inFlight.remove(key);
    }
  }
}
