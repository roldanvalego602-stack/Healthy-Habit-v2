import 'package:flutter/material.dart';
import 'colores.dart';
import '../tema/healthy_theme.dart';

class TarjetaContenedor extends StatelessWidget {
  final Widget child;
  final Color colorFondo;
  final EdgeInsetsGeometry padding;

  const TarjetaContenedor({
    super.key,
    required this.child,
    this.colorFondo = AppColores.blanco,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final standard = colorFondo == AppColores.blanco;
    final actual = standard ? HealthyAdaptive.surface : colorFondo;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: actual,
        borderRadius: BorderRadius.circular(24),
        border:
            standard
                ? Border.all(color: HealthyAdaptive.border, width: 1)
                : null,
      ),
      child: child,
    );
  }
}
