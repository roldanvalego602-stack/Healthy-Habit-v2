import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
      await _channel.invokeMethod<void>('play', {'kind': kind});
    } on MissingPluginException {
      // Demo y pruebas de widgets sin Android: silencio intencional.
    } on PlatformException {
      // Nunca bloquear una acción real por un efecto ornamental.
    }
  }
}
