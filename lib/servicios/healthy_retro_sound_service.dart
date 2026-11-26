import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Sonidos originales sintetizados en Android: sin voz humana ni audios
/// tomados de videojuegos. No altera datos, XP, saldos ni registros.
class HealthyRetroSoundService {
  HealthyRetroSoundService._();

  static const MethodChannel _channel =
      MethodChannel('healthy_habit/retro_sounds');

  static Future<void> play(String kind) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (!const {'talk', 'purchase', 'reward', 'achievement', 'friend'}
        .contains(kind)) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final db = FirebaseFirestore.instanceFor(
          app: Firebase.app(), databaseId: 'default');
        final document = await db.collection('users').doc(user.uid).get();
        final settings = document.data()?['settings'];
        if (settings is Map && settings['sonidosApp'] == false) return;
      }
      await _channel.invokeMethod<void>('play', {'kind': kind});
    } on MissingPluginException {
      // Demo y pruebas de widgets sin Android: silencio intencional.
    } on PlatformException {
      // Nunca bloquear una acción real por un efecto ornamental.
    } catch (_) {
      // Desconexión o perfil no disponible: el sonido es opcional.
    }
  }
}
