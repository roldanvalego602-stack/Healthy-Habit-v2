import 'package:flutter/material.dart';

import '../../tema/healthy_theme.dart';
import 'profile_avatar.dart';

/// Avatar y marco ornamental con geometría compartida.
/// El marco se dibuja POR FUERA de la fotografía, no dentro de ella.
/// No consulta Firebase: funciona igual en perfiles propios, públicos
/// y vista previa del armario.
class HealthyFramedAvatar extends StatelessWidget {
  const HealthyFramedAvatar({
    super.key,
    required this.size,
    required this.photoUrl,
    required this.preset,
    this.frameAsset,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 2,
    this.frameOverflow = 11,
    this.frameScale = 1.12,
  });

  /// Diámetro de la fotografía (no del marco exterior).
  final double size;
  final String? photoUrl;
  final String preset;
  final String? frameAsset;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;

  /// Espacio añadido alrededor de la foto para los ornamentos.
  final double frameOverflow;

  /// Compensa márgenes transparentes en los PNG ornamentales.
  final double frameScale;

  @override
  Widget build(BuildContext context) {
    final hasFrame = frameAsset != null && frameAsset!.isNotEmpty;
    final overflow = hasFrame ? frameOverflow : 0.0;
    final totalSize = size + overflow * 2;

    return SizedBox.square(
      key: const Key('healthy-framed-avatar'),
      dimension: totalSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: backgroundColor ?? HealthyAdaptive.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor ?? HealthyAdaptive.accent,
                width: borderWidth,
              ),
            ),
            child: ClipOval(
              child: HealthyProfileAvatar(
                photoUrl: photoUrl,
                preset: preset,
                size: size - 6,
              ),
            ),
          ),
          if (hasFrame)
            Positioned.fill(
              child: IgnorePointer(
                child: Transform.scale(
                  scale: frameScale,
                  child: Image.asset(
                    frameAsset!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
