import 'package:flutter/material.dart';

import '../../tema/healthy_asset_catalog.dart';

/// Cabecera común del perfil propio y de los perfiles públicos.
///
/// Las ilustraciones de 1200×450 utilizan exactamente esta proporción,
/// evitando un recorte diferente entre ambas pantallas. Se recomienda
/// reservar 12% a cada lado y la franja inferior central para el avatar.
class ProfileBanner extends StatelessWidget {
  const ProfileBanner({
    super.key,
    required this.bannerStyle,
    required this.label,
    required this.fallbackColors,
  });

  static const double aspectRatio = 8 / 3;
  static const double sideSafeMargin = .12;

  final String bannerStyle;
  final String label;
  final List<Color> fallbackColors;

  @override
  Widget build(BuildContext context) {
    final asset = HealthyAssetCatalog.banners[bannerStyle];
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: fallbackColors),
      ),
    );
    return AspectRatio(
      key: const ValueKey('healthy-profile-banner'),
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (asset == null)
              fallback
            else
              Image.asset(
                asset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => fallback,
              ),
            Positioned(
              left: 13,
              top: 12,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
