import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'beta_evidence_service.dart';
import 'beta_habit_gateway.dart';

/// Evaluación opcional en nube de una foto YA vinculada.
/// El cliente no manda imágenes ni detecciones: el servidor lee Storage.
class BetaEvidenceVisionService {
  const BetaEvidenceVisionService();

  static const enabledByBuild = bool.fromEnvironment(
    'HH_BETA_VISION_CLIENT', defaultValue: false);

  static bool get enabled =>
      enabledByBuild && BetaEvidenceService.enabled &&
      BetaHabitGateway.enabled;

  Future<Map<String, dynamic>> analyze({
    required String habitId, required String attemptId,
    required String operationId,
  }) async {
    if (!enabled ||
        Firebase.app().options.projectId != BetaHabitGateway.projectId) {
      throw StateError('El análisis visual de beta no está habilitado.');
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Inicia sesión antes de analizar.');
    final regex = RegExp(r'^[A-Za-z0-9_-]{16,128}$');
    if (!RegExp(r'^(alim|hidr|ener|bien)_00[1-9]$')
            .hasMatch(habitId) ||
        !regex.hasMatch(attemptId) || !regex.hasMatch(operationId)) {
      throw ArgumentError('La evidencia no corresponde a un registro válido.');
    }
    final result = await FirebaseFunctions.instanceFor(
      app: Firebase.app(), region: 'us-central1',
    ).httpsCallable('analyzeAttachedHabitEvidenceBeta',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 45)))
      .call<Map<String, dynamic>>({
        'habitId': habitId, 'attemptId': attemptId,
        'operationId': operationId,
      });
    if (FirebaseAuth.instance.currentUser?.uid != uid) {
      throw StateError('Cambió la sesión al consultar la evaluación.');
    }
    final data = Map<String, dynamic>.from(result.data);
    if (data['imageVerified'] != false ||
        data['contentVerified'] != false ||
        data['xpAwarded'] != 0 ||
        data['coinsAwarded'] != 0) {
      throw const FormatException('Respuesta visual no autorizada.');
    }
    return data;
  }
}
