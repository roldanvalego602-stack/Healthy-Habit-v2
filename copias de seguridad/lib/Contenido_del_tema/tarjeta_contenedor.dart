import 'package:flutter/material.dart';
import 'colores.dart';

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
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(24),
        border:
            colorFondo == AppColores.blanco
                ? Border.all(color: AppColores.bordeGris, width: 1)
                : null,
      ),
      child: child,
    );
  }
}
