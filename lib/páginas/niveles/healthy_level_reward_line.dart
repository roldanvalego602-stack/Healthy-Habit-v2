import 'package:flutter/material.dart';
import '../../tema/healthy_coin.dart';

/// La recompensa se distribuye en varias líneas cuando el dispositivo
/// es angosto o tiene texto ampliado por accesibilidad.
class HealthyLevelRewardLine extends StatelessWidget {
  const HealthyLevelRewardLine({super.key, required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 7,
    runSpacing: 6,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      const Text(
        'Próxima recompensa:',
        softWrap: true,
        style: TextStyle(
          color: Color(0xFFFFE49A),
          fontWeight: FontWeight.w700,
        ),
      ),
      HealthyCoinAmount(
        amount: '$coins',
        size: 18,
        suffix: ' Habit Coins',
        style: const TextStyle(
          color: Color(0xFFFFE49A),
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
