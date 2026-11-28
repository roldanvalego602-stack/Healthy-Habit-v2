import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'beta_habit_gateway.dart';

class EvidencePhotoRequired implements Exception {
  const EvidencePhotoRequired();
  @override
  String toString() => 'Se necesita recuperar la fotografía original.';
}

/// Fotografías privadas de beta. No concede XP ni determina consumo.
/// El servidor comprueba Auth, App Check, cuota y propiedad del intento.
class BetaEvidenceService {
  const BetaEvidenceService();

  static const enabled = bool.fromEnvironment(
    'HH_BETA_EVIDENCE_CLIENT', defaultValue: false);
  static const maxBytes = 250 * 1024;

  String _uid() {
    if (!enabled || !BetaHabitGateway.enabled ||
        Firebase.app().options.projectId != BetaHabitGateway.projectId) {
      throw StateError('La evidencia de beta no está habilitada.');
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Inicia sesión para asociar la fotografía.');
    }
    return uid;
  }

  Future<Map<String, dynamic>> _call(
    String name, Map<String, dynamic> data,
  ) async {
    final uid = _uid();
    final result = await FirebaseFunctions.instanceFor(
      app: Firebase.app(), region: 'us-central1',
    ).httpsCallable(name, options: HttpsCallableOptions(
      timeout: const Duration(seconds: 35),
    )).call<Map<String, dynamic>>(data);
    if (_uid() != uid) {
      throw StateError('La sesión cambió durante el registro de evidencia.');
    }
    return Map<String, dynamic>.from(result.data);
  }

  Map<String, dynamic> _identity(
    String habitId, String attemptId, String operationId,
  ) {
    final id = RegExp(r'^[A-Za-z0-9_-]{16,128}$');
    if (!RegExp(r'^(alim|hidr|ener|bien)_00[1-9]$').hasMatch(habitId) ||
        !id.hasMatch(attemptId) || !id.hasMatch(operationId)) {
      throw ArgumentError('Identificadores de evidencia inválidos.');
    }
    return {'habitId': habitId, 'attemptId': attemptId,
      'operationId': operationId};
  }

  Future<Map<String, dynamic>> status({
    required String habitId, required String attemptId,
    required String operationId,
  }) => _call('getHabitEvidenceStatusBeta',
    _identity(habitId, attemptId, operationId));

  Future<Map<String, dynamic>> reserve({
    required String habitId, required String attemptId,
    required String operationId,
    bool visionConsent = false,
  }) => _call('reserveHabitEvidenceBeta', {
    ..._identity(habitId, attemptId, operationId),
    'visionConsent': visionConsent,
  });

  Future<Map<String, dynamic>> upload({
    required String habitId, required String attemptId,
    required String operationId, required Uint8List jpeg,
  }) {
    if (jpeg.lengthInBytes < 12 || jpeg.lengthInBytes > maxBytes ||
        jpeg[0] != 0xff || jpeg[1] != 0xd8 || jpeg[2] != 0xff ||
        jpeg[jpeg.lengthInBytes - 2] != 0xff ||
        jpeg[jpeg.lengthInBytes - 1] != 0xd9) {
      throw ArgumentError('Selecciona una imagen JPEG válida de hasta 250 KB.');
    }
    return _call('uploadReservedEvidenceBeta', {
      ..._identity(habitId, attemptId, operationId),
      'imageBase64': base64Encode(jpeg), 'contentType': 'image/jpeg',
    });
  }

  Future<Map<String, dynamic>> attach({
    required String habitId, required String attemptId,
    required String operationId,
  }) => _call('attachHabitEvidenceBeta',
    _identity(habitId, attemptId, operationId));
}
