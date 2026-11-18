import 'package:flutter/material.dart';
import 'colores.dart';

class ChipRecompensa extends StatelessWidget {
  final String texto;
  final Color colorFondo;
  final Color colorTexto;

  const ChipRecompensa({
    super.key,
    required this.texto,
    this.colorFondo = AppColores.amarilloRacha,
    this.colorTexto = AppColores.textoOscuro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: colorTexto,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
