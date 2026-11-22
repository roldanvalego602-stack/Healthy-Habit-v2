import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Navegación editorial. El círculo no representa proporciones dietéticas.
class MapaPlatoCatalogo extends StatelessWidget {
  const MapaPlatoCatalogo({
    super.key, required this.seleccionado, required this.onSeleccionar,
  });
  final String? seleccionado;
  final ValueChanged<String?> onSeleccionar;

  static const grupos = <String>[
    'Frutas y verduras', 'Cereales', 'Leguminosas y origen animal',
  ];
  static const colores = <Color>[
    Color(0xFF50B67A), Color(0xFFE5BC52), Color(0xFFD5866A),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Text('Toca una sección del plato',
        style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      Center(child: SizedBox(
        width: 238, height: 238,
        child: GestureDetector(
          onTapDown: (details) {
            final p = details.localPosition;
            final dx = p.dx - 119;
            final dy = p.dy - 119;
            final radius = math.sqrt(dx * dx + dy * dy);
            if (radius > 115) return;
            // El primer sector comienza en la parte superior.
            final angle = (math.atan2(dy, dx) + math.pi / 2 +
                2 * math.pi) % (2 * math.pi);
            final index = (angle / (2 * math.pi / 3)).floor().clamp(0, 2);
            final group = grupos[index];
            onSeleccionar(seleccionado == group ? null : group);
          },
          child: CustomPaint(
            painter: _PlatoPainter(seleccionado: seleccionado),
            child: const Center(
              child: CircleAvatar(
                radius: 31,
                backgroundColor: Colors.white,
                child: Icon(Icons.restaurant_rounded,
                  color: Color(0xFF14765B), size: 25),
              ),
            ),
          ),
        ),
      )),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
        children: [
          for (var i = 0; i < grupos.length; i++)
            ChoiceChip(
              key: ValueKey('plato-grupo-${grupos[i]}'),
              label: Text(grupos[i]),
              avatar: CircleAvatar(backgroundColor: colores[i], radius: 8),
              selected: seleccionado == grupos[i],
              onSelected: (_) => onSeleccionar(
                seleccionado == grupos[i] ? null : grupos[i]),
            ),
        ]),
      const SizedBox(height: 8),
      const Text(
        'Agrupación visual educativa, sin tamaños de porción ni prescripción.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11),
      ),
    ]);
  }
}

class _PlatoPainter extends CustomPainter {
  _PlatoPainter({required this.seleccionado});
  final String? seleccionado;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < 3; i++) {
      final group = MapaPlatoCatalogo.grupos[i];
      final selected = seleccionado == null || seleccionado == group;
      canvas.drawArc(
        rect, -math.pi / 2 + i * 2 * math.pi / 3,
        2 * math.pi / 3, true,
        Paint()..color = MapaPlatoCatalogo.colores[i].withValues(
          alpha: selected ? 1.0 : 0.24),
      );
    }
    canvas.drawCircle(center, radius, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6);
    for (var i = 0; i < 3; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / 3;
      canvas.drawLine(center, center + Offset(
        math.cos(angle) * radius, math.sin(angle) * radius),
        Paint()..color = Colors.white..strokeWidth = 5);
    }
  }

  @override
  bool shouldRepaint(covariant _PlatoPainter old) =>
      old.seleccionado != seleccionado;
}

class MapaMovimientoCatalogo extends StatelessWidget {
  const MapaMovimientoCatalogo({
    super.key, required this.seleccionado, required this.onSeleccionar,
  });
  final String? seleccionado;
  final ValueChanged<String?> onSeleccionar;

  static const zonas = <(String, IconData)>[
    ('Tren superior', Icons.fitness_center),
    ('Tren inferior', Icons.directions_walk),
    ('Zona media', Icons.accessibility_new),
    ('Flexibilidad', Icons.self_improvement),
    ('Cardio y movilidad', Icons.directions_run),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(children: [
        const Icon(Icons.accessibility_new_rounded, size: 55),
        const SizedBox(height: 7),
        const Text('¿Qué deseas trabajar?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final (zone, symbol) in zonas)
              ChoiceChip(
                label: Text(zone),
                avatar: Icon(symbol, size: 16),
                selected: seleccionado == zone,
                onSelected: (_) => onSeleccionar(
                  seleccionado == zone ? null : zone),
              ),
          ],
        ),
      ]),
    );
  }
}
