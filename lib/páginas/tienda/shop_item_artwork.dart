import 'package:flutter/material.dart';
import '../../tema/healthy_asset_catalog.dart';
import '../../tema/healthy_cosmetics.dart';
import 'shop_service.dart';
import 'healthy_leaf_aura.dart';
import 'healthy_special_auras.dart';

/// Usa las imágenes reales subidas por el equipo y conserva el emoji
/// como respaldo para los cosméticos que todavía no tienen ilustración.
class ShopItemArtwork extends StatelessWidget {
  const ShopItemArtwork({super.key, required this.item, this.size = 78});

  final ShopItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
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
