import 'package:flutter/material.dart';

/// Moneda oficial de Healthy Habit. No representa dinero real.
/// Usa la versión premium solo para saldos explícitamente premium.
class HealthyCoinIcon extends StatelessWidget {
  const HealthyCoinIcon({
    super.key,
    this.size = 22,
    this.premium = false,
  });

  static const asset = 'assets/monedas/h coin.png';
  static const premiumAsset = 'assets/monedas/h coin premium.png';

  final double size;
  final bool premium;

  @override
  Widget build(BuildContext context) => Image.asset(
    premium ? premiumAsset : asset,
    key: ValueKey(premium ? 'healthy-premium-coin' : 'healthy-habit-coin'),
    width: size,
    height: size,
    fit: BoxFit.contain,
    semanticLabel: premium ? 'Moneda premium Healthy Habit'
        : 'Habit Coin de Healthy Habit',
    errorBuilder: (context, error, stack) => SizedBox(
      width: size,
      height: size,
      child: Icon(Icons.image_not_supported_outlined,
        size: size * .7, color: Colors.grey),
    ),
  );
}

/// Cantidad acompañada por la moneda visual, sin alterar datos o saldos.
class HealthyCoinAmount extends StatelessWidget {
  const HealthyCoinAmount({
    super.key,
    required this.amount,
    this.size = 20,
    this.style,
    this.premium = false,
    this.suffix = '',
    this.mainAxisSize = MainAxisSize.min,
  });

  final String amount;
  final double size;
  final TextStyle? style;
  final bool premium;
  final String suffix;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: mainAxisSize,
    children: [
      HealthyCoinIcon(size: size, premium: premium),
      const SizedBox(width: 5),
      Flexible(
        child: Text('$amount$suffix',
          overflow: TextOverflow.ellipsis, style: style),
      ),
    ],
  );
}
