import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'modelos/catalogo_item.dart';

/// Imagen compartida entre tarjetas y detalle para una transición Hero.
/// La ilustración de reserva es editorial; no pretende ser una fotografía.
class CatalogoMedia extends StatelessWidget {
  const CatalogoMedia({
    super.key,
    required this.item,
    required this.altura,
    this.usarHero = false,
    this.radio = 16,
  });

  final CatalogoItem item;
  final double altura;
  final bool usarHero;
  final double radio;

  static IconData icono(CatalogoItem item) {
    switch (item.id) {
      case 'huevo':
        return Icons.egg_alt_rounded;
      case 'avena':
      case 'arroz_integral':
      case 'tortilla_maiz':
        return Icons.grain_rounded;
      case 'pollo':
      case 'frijoles':
      case 'lentejas':
      case 'garbanzos':
        return Icons.restaurant_rounded;
    }
    if (item.categoria == 'Bebidas') {
      return Icons.water_drop_rounded;
    }
    if (item.categoria == 'Ejercicios') {
      return Icons.fitness_center_rounded;
    }
    if (item.etiquetas.contains('Sueño')) {
      return Icons.bedtime_rounded;
    }
    if (item.etiquetas.contains('Seguridad')) {
      return Icons.health_and_safety_rounded;
    }
    return item.categoria == 'Alimentos'
        ? Icons.eco_rounded
        : Icons.spa_rounded;
  }

  Color get _color {
    switch (item.categoria) {
      case 'Alimentos':
        return const Color(0xFF27765A);
      case 'Ejercicios':
        return const Color(0xFF326D91);
      case 'Bebidas':
        return const Color(0xFF2D91B2);
      default:
        return const Color(0xFF7A66A7);
    }
  }

  Widget _alternativa() => Container(
    height: altura,
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_color.withValues(alpha: 0.75), _color],
      ),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          right: -10,
          top: -16,
          child: Icon(
            icono(item),
            size: altura * 0.88,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        Center(
          child: Container(
            height: (altura * 0.48).clamp(38.0, 78.0),
            width: (altura * 0.48).clamp(38.0, 78.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(
              icono(item),
              color: Colors.white,
              size: (altura * 0.29).clamp(23.0, 43.0),
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    Widget media;
    if (item.imagen.isEmpty) {
      media = _alternativa();
    } else if (item.imagen.toLowerCase().endsWith('.svg')) {
      media = SvgPicture.asset(
        item.imagen,
        width: double.infinity,
        height: altura,
        fit: BoxFit.cover,
        semanticsLabel: 'Ilustración de ${item.titulo}',
        errorBuilder: (_, __, ___) => _alternativa(),
      );
    } else {
      media = Image.asset(
        item.imagen,
        width: double.infinity,
        height: altura,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        semanticLabel: 'Imagen de ${item.titulo}',
        errorBuilder: (_, __, ___) => _alternativa(),
      );
    }

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: SizedBox(
        height: altura,
        width: double.infinity,
        child: media,
      ),
    );
    return usarHero
        ? Hero(tag: 'catalogo-${item.id}', child: image)
        : image;
  }
}
