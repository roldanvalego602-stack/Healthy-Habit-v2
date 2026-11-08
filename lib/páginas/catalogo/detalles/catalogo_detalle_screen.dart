import 'package:flutter/material.dart';
import '../modelos/catalogo_item.dart';

class CatalogoDetalleScreen extends StatelessWidget {
  final CatalogoItem item;
  const CatalogoDetalleScreen({super.key, required this.item});

  static const _verde = Color(0xFF08B889);
  static const _oscuro = Color(0xFF193344);
  static const _fondo = Color(0xFFF5F8F6);
  static const _gris = Color(0xFF71879A);

  IconData get _icono {
    switch (item.icono) {
      case 'grain':
        return Icons.grain;
      case 'egg':
        return Icons.egg_outlined;
      case 'eco':
        return Icons.eco_outlined;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'bedtime':
        return Icons.bedtime_outlined;
      case 'health_and_safety':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.self_improvement;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _fondo,
        foregroundColor: _oscuro,
        elevation: 0,
        title: Text(
          item.categoria,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F7EF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(_icono, size: 36, color: _verde),
                ),
                const SizedBox(height: 16),
                Text(
                  item.titulo,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: _oscuro,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.descripcion,
                  style: const TextStyle(
                    fontSize: 15,
                    color: _gris,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(item.dificultad),
                    ...item.etiquetas.map(_chip),
                  ],
                ),
              ],
            ),
          ),
          if (item.detalles.isNotEmpty) ...[
            const SizedBox(height: 18),
            _seccion(
              'Datos importantes',
              Column(
                children:
                    item.detalles.entries
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    e.key,
                                    style: const TextStyle(color: _gris),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    e.value,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _oscuro,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _seccion(
            'Beneficios',
            _lista(item.beneficios, Icons.check_circle_outline),
          ),
          const SizedBox(height: 18),
          _seccion(
            item.categoria == 'Ejercicios'
                ? 'Cómo realizarlo'
                : item.categoria == 'Alimentos'
                ? 'Sugerencias de consumo'
                : 'Acciones recomendadas',
            _lista(item.pasos, Icons.arrow_forward_ios, numerada: true),
          ),
          const SizedBox(height: 18),
          _seccion(
            'Precauciones',
            _lista(item.precauciones, Icons.info_outline),
          ),
          const SizedBox(height: 18),
          _seccion(
            'Hábitos relacionados',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...item.habitosRelacionados.map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.link, color: _verde, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            h,
                            style: const TextStyle(color: _oscuro),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Text(
                  'Vinculación informativa. No activa hábitos ni concede XP.',
                  style: TextStyle(color: _gris, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _seccion(
            'Fuente de referencia',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fuente,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _oscuro,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  item.fuenteUrl,
                  style: const TextStyle(color: _verde, fontSize: 12),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Contenido educativo general; no sustituye asesoramiento médico o nutricional individualizado.',
                  style: TextStyle(color: _gris, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _chip(String s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFE4F7EF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      s,
      style: const TextStyle(
        color: Color(0xFF078765),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  );

  Widget _seccion(String titulo, Widget contenido) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _oscuro,
          ),
        ),
        const SizedBox(height: 14),
        contenido,
      ],
    ),
  );

  Widget _lista(List<String> textos, IconData icono, {bool numerada = false}) =>
      Column(
        children:
            textos
                .asMap()
                .entries
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        numerada
                            ? CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFFE4F7EF),
                              child: Text(
                                '${e.key + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _verde,
                                ),
                              ),
                            )
                            : Icon(icono, size: 19, color: _verde),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.value,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: _oscuro,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      );
}
