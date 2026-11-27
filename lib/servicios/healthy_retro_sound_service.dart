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

  static bool? _soundEnabled;
  static DateTime? _lastTap;

  /// Actualiza la preferencia sin esperar a que expire la caché de Firestore.
  static void setEnabled(bool value) {
    _soundEnabled = value;
    _readAt = DateTime.now();
  }
  static DateTime? _readAt;

  /// Reproduce una muestra directamente en Android y devuelve el diagnóstico.
  /// Solo se invoca por una acción explícita del usuario en Configuración.
  static Future<String> preview(String kind) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return 'La vista previa está disponible en Android.';
    }
    try {
      final result = await _channel.invokeMethod<String>(
        'preview', {'kind': kind});
      return result ?? 'Android no devolvió un diagnóstico de audio.';
    } on MissingPluginException {
      return 'Canal de audio no disponible. Cierra y recompila la app.';
    } on PlatformException catch (error) {
      return 'Error Android: ${error.message ?? error.code}';
    } catch (error) {
      return 'No se pudo reproducir: $error';
    }
  }

  static Future<void> play(String kind) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (!const {'talk', 'purchase', 'reward', 'achievement', 'friend', 'tap', 'guide', 'open', 'habit', 'equip', 'error'}
        .contains(kind)) {
      return;
    }
    // Evita acumulación de clics cuando alguien navega muy rápido.
    if (kind == 'tap') {
      final now = DateTime.now();
      if (_lastTap != null &&
          now.difference(_lastTap!) < const Duration(milliseconds: 85)) {
        return;
      }
      _lastTap = now;
    }
    try {
      // Caché corta: un tap no debe consultar Firestore por cada pulsación.
      final now = DateTime.now();
      if (_readAt == null ||
          now.difference(_readAt!) > const Duration(minutes: 3)) {
        _readAt = now;
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final db = FirebaseFirestore.instanceFor(
              app: Firebase.app(), databaseId: 'default');
            final document = await db.collection('users').doc(user.uid).get();
            final settings = document.data()?['settings'];
            _soundEnabled = settings is! Map ||
                settings['sonidosApp'] != false;
          } else {
            _soundEnabled = true;
          }
        } catch (_) {
          // Si no hay conexión, respetar la última preferencia conocida.
        }
      }
      if (_soundEnabled == false) return;
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
