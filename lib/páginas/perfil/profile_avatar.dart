import 'package:flutter/material.dart';

import '../../tema/healthy_theme.dart';
import '../../tema/healthy_asset_catalog.dart';

/// Avatar compartido de Perfil, Editar perfil y Perfil público.
/// Protege la interfaz de URLs de fotografía inválidas o inaccesibles.
class HealthyProfileAvatar extends StatelessWidget {
  const HealthyProfileAvatar({
    super.key,
    required this.photoUrl,
    this.size = 88,
    this.iconSize,
    this.preset = 'foto',
  });

  final String? photoUrl;
  final double size;
  final double? iconSize;
  /// Estilo gratuito guardado en Firestore (sin depender de Storage).
  final String preset;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim() ?? '';
    final validUrl = preset == 'foto' &&
        (Uri.tryParse(url)?.hasScheme ?? false) &&
        (url.startsWith('https://') || url.startsWith('http://'));
    final asset = HealthyAssetCatalog.avatars[preset];
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: asset != null
            ? Image.asset(
                asset,
                key: ValueKey('healthy-avatar-asset-$preset'),
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (context, error, stack) => _fallback(),
              )
            : validUrl
            ? Image.network(
                url,
                key: ValueKey('healthy-avatar-$url'),
                fit: BoxFit.cover,
                width: size,
                height: size,
                loadingBuilder: (context, child, loading) {
                  if (loading == null) return child;
                  return _fallback(withLoading: true);
                },
                errorBuilder: (context, error, stack) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback({bool withLoading = false}) => ColoredBox(
        color: HealthyAdaptive.mint,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              switch (preset) {
                'naturaleza' => Icons.spa_rounded,
                'agua' => Icons.water_drop_rounded,
                'energia' => Icons.bolt_rounded,
                _ => Icons.person_rounded,
              },
              size: iconSize ?? size * .60,
              color: HealthyAdaptive.accent,
            ),
            if (withLoading)
              Positioned(
                bottom: 5,
                right: 5,
                child: SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: HealthyAdaptive.accent,
                  ),
                ),
              ),
          ],
        ),
      );
}
