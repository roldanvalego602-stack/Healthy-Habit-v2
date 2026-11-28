import 'package:flutter/material.dart';
import 'shop_service.dart';

enum ShopRarity { comun, pocoComun, raro, epico, legendario }

extension ShopRarityPresentation on ShopRarity {
  String get label => switch (this) {
    ShopRarity.comun => 'Común',
    ShopRarity.pocoComun => 'Poco común',
    ShopRarity.raro => 'Raro',
    ShopRarity.epico => 'Épico',
    ShopRarity.legendario => 'Legendario',
  };

  Color get accent => switch (this) {
    ShopRarity.comun => const Color(0xFF465B60),
    ShopRarity.pocoComun => const Color(0xFF12694B),
    ShopRarity.raro => const Color(0xFF184F8D),
    ShopRarity.epico => const Color(0xFF653B9F),
    ShopRarity.legendario => const Color(0xFF795113),
  };

  Color get darkAccent => switch (this) {
    ShopRarity.comun => const Color(0xFFD7E5E5),
    ShopRarity.pocoComun => const Color(0xFF89E5B5),
    ShopRarity.raro => const Color(0xFF9CC9FF),
    ShopRarity.epico => const Color(0xFFD1B8FF),
    ShopRarity.legendario => const Color(0xFFFFDF8B),
  };
}

/// Las rarezas distinguen complejidad visual, no afectan las recompensas.
/// El secreto Titán permanece fuera de la tienda comercial.
ShopRarity rarityFor(ShopItem item) {
  if (item.id == 'skin_titan_secret' ||
      item.id == 'ufo_gold' || item.id == 'theme_cosmos') {
    return ShopRarity.legendario;
  }
  if (item.id == 'skin_christmas_cartoon' ||
      item.id == 'ufo_lava' || item.id == 'ufo_glitch' ||
      item.id == 'golden_aura') {
    return ShopRarity.epico;
  }
  if (item.id.startsWith('ufo_') ||
      item.id == 'stellar_aura' || item.price >= 260) {
    return ShopRarity.raro;
  }
  if (item.price >= 155) return ShopRarity.pocoComun;
  return ShopRarity.comun;
}

class ShopRarityChip extends StatelessWidget {
  const ShopRarityChip({super.key, required this.item, this.compact = false});
  final ShopItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rarity = rarityFor(item);
    final color = Theme.of(context).brightness == Brightness.dark
        ? rarity.darkAccent : rarity.accent;
    return Semantics(
      label: 'Rareza: ${rarity.label}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 10, vertical: compact ? 4 : 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: .95),
          border: Border.all(color: color, width: 1.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(rarity.label,
          style: TextStyle(color: color, fontWeight: FontWeight.w800,
            fontSize: compact ? 10 : 12)),
      ),
    );
  }
}
