import 'package:flutter/material.dart';

/// Ilustraciones aprobadas de los objetos de protección de racha.
/// Son recursos visuales: no conceden, consumen ni restauran días de racha.
enum HealthyStreakItem {
  shield,
  freezeCrystal,
  recoveryHeart,
}

class HealthyStreakItems {
  HealthyStreakItems._();

  static const String _folder = 'assets/gamificacion/protectores_racha/';

  static const Map<HealthyStreakItem, String> paths = {
    HealthyStreakItem.shield: '${_folder}Escudo Verde con Calendario.png',
    HealthyStreakItem.freezeCrystal:
        '${_folder}Cristal de hielo con copo de nieve сия.png',
    HealthyStreakItem.recoveryHeart: '${_folder}corazón.png',
  };

  static String label(HealthyStreakItem item) => switch (item) {
        HealthyStreakItem.shield => 'Escudo de racha',
        HealthyStreakItem.freezeCrystal => 'Cristal de congelación',
        HealthyStreakItem.recoveryHeart => 'Corazón de recuperación',
      };

  static IconData fallback(HealthyStreakItem item) => switch (item) {
        HealthyStreakItem.shield => Icons.shield_outlined,
        HealthyStreakItem.freezeCrystal => Icons.ac_unit_rounded,
        HealthyStreakItem.recoveryHeart => Icons.favorite_outline_rounded,
      };
}

class HealthyStreakItemIcon extends StatelessWidget {
  const HealthyStreakItemIcon({
    super.key,
    required this.item,
    this.size = 72,
  });

  final HealthyStreakItem item;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        HealthyStreakItems.paths[item]!,
        key: ValueKey('streak-item-${item.name}'),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        semanticLabel: HealthyStreakItems.label(item),
        errorBuilder: (context, error, stackTrace) => SizedBox(
          width: size,
          height: size,
          child: Icon(
            HealthyStreakItems.fallback(item),
            size: size * .65,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
}
