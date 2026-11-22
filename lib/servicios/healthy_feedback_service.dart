import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

/// Efectos de compras y recompensas que respetan los ajustes de la cuenta.
/// No reproduce archivos sonoros externos; usa el clic del sistema operativo.
class HealthyFeedbackService {
  const HealthyFeedbackService._();

  static Future<bool> onReward() async {
    var enableSound = true;
    var enableHaptics = true;
    var enableCelebration = true;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final db = FirebaseFirestore.instanceFor(
          app: Firebase.app(), databaseId: 'default',
        );
        final doc = await db.collection('users').doc(user.uid).get();
        final raw = doc.data()?['settings'];
        if (raw is Map) {
          enableSound = raw['sonidosApp'] != false;
          enableHaptics = raw['vibracionHaptica'] != false;
          enableCelebration = raw['efectosRecompensa'] != false &&
              raw['modoDiscreto'] != true;
        }
      } catch (_) {
        // La compra ya se confirmó: el fallo al leer preferencias
        // no debe impedir que se use el artículo adquirido.
      }
    }
    if (enableSound) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
    if (enableHaptics) {
      try {
        await HapticFeedback.lightImpact();
      } catch (_) {}
    }
    return enableCelebration;
  }
}
