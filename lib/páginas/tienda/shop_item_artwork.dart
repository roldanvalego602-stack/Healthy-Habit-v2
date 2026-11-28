import 'package:flutter/material.dart';
import '../../tema/healthy_asset_catalog.dart';
import '../../tema/healthy_cosmetics.dart';
import '../../tema/healthy_streak_items.dart';
import 'shop_service.dart';
import 'healthy_ufo_skin_art.dart';
import 'healthy_leaf_aura.dart';
import 'healthy_special_auras.dart';
import 'healthy_achievement_display.dart';
import 'healthy_titan_skin.dart';

/// Usa las imágenes reales subidas por el equipo y conserva el emoji
/// como respaldo para los cosméticos que todavía no tienen ilustración.
class ShopItemArtwork extends StatelessWidget {
  const ShopItemArtwork({super.key, required this.item, this.size = 78});

  final ShopItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (HealthyUfoSkinArt.ids.contains(item.id)) {
      return HealthyUfoSkinArt(id: item.id, size: size);
    }
    if (item.id == 'skin_titan_secret') {
      return SizedBox.square(dimension: size,
        child: FittedBox(fit: BoxFit.contain,
          child: HealthyTitanSkin(size: size)));
    }
    if (item.id == 'theme_cosmos') {
      return SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const RadialGradient(colors: [
              Color(0xFF5366B5), Color(0xFF1E194A), Color(0xFF060816),
            ]),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF57E5FF), width: 1.5),
          ),
          child: Center(child: Icon(
            Icons.auto_awesome_rounded,
            color: const Color(0xFFBAABFF), size: size * .54)),
        ),
      );
    }
    // El artículo histórico sigue retirado de la venta, pero su imagen
    // oficial se muestra si aparece en inventarios antiguos.
    if (item.id == 'achievement_display') {
      return HealthyAchievementDisplay(width: size, height: size);
    }
    if (item.id == 'streak_guard') {
      return HealthyStreakItemIcon(
        item: HealthyStreakItem.shield,
        size: size,
      );
    }
    if (item.id == 'leaf_aura') {
      return SizedBox.square(
        dimension: size,
        child: const HealthyLeafAuraThumbnail(),
      );
    }
    if (item.id == 'stellar_aura' || item.id == 'golden_aura') {
      return SizedBox.square(
        dimension: size,
        child: HealthySpecialAuraThumbnail(
          kind: item.id == 'stellar_aura'
              ? HealthySpecialAura.stellar
              : HealthySpecialAura.golden,
        ),
      );
    }
    final asset = HealthyCosmetics.assetFor(item.id) ??
        HealthyAssetCatalog.shopImages[item.id];
    return SizedBox.square(
      dimension: size,
      child: asset == null
          ? Center(child: Text(item.emoji,
              style: TextStyle(fontSize: size * 0.56)))
          : Image.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Text(item.emoji,
                  style: TextStyle(fontSize: size * 0.56)),
              ),
            ),
    );
  }
}
