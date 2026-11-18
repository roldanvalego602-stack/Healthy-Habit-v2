import 'package:flutter/material.dart';
import 'colores.dart';

class AppEstilosTexto {
  // Títulos Grandes
  static const TextStyle tituloGrande = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AppColores.textoOscuro,
    letterSpacing: -0.5,
  );

  // Subtítulos de sección
  static const TextStyle tituloSeccion = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColores.textoOscuro,
  );

  // Títulos de tarjetas
  static const TextStyle tituloTarjeta = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColores.textoOscuro,
  );

  // Texto de cuerpo / descripción
  static const TextStyle cuerpo = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColores.textoGris,
  );

  // Etiquetas pequeñas (p.ej. XP, Categoría)
  static const TextStyle etiqueta = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  );
}