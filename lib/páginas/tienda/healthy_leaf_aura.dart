import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../tema/healthy_visual_mode.dart';

/// Aura vegetal: modifica el ambiente alrededor del personaje, no su skin.
/// La pintura utiliza el lienzo fijo del personaje (280 x 275) y también
/// funciona como miniatura en el catálogo.
class HealthyLeafAura extends StatefulWidget {
  const HealthyLeafAura({super.key, required this.child});

  final Widget child;

  @override
  State<HealthyLeafAura> createState() => _HealthyLeafAuraState();
}

class _HealthyLeafAuraState extends State<HealthyLeafAura>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    HealthyVisualController.instance.addListener(_sync);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant HealthyLeafAura oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (!mounted) return;
    final playing = TickerMode.of(context) &&
        HealthyVisualEffects.enabled(context);
    if (_playing == playing) return;
    _playing = playing;
    if (playing) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    HealthyVisualController.instance.removeListener(_sync);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animated = HealthyVisualEffects.enabled(context);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => CustomPaint(
        key: const Key('healthy-aura-hojas'),
        painter: _LeafAuraPainter(
          progress: animated ? _controller.value : 0,
          foreground: false,
        ),
        foregroundPainter: _LeafAuraPainter(
          progress: animated ? _controller.value : 0,
          foreground: true,
        ),
        child: child,
      ),
    );
  }
}

/// Vista previa sin animación, sin recursos adicionales y sin sustituir
/// al personaje. Los anillos y hojas son los del efecto real.
class HealthyLeafAuraThumbnail extends StatelessWidget {
  const HealthyLeafAuraThumbnail({super.key});

  @override
  Widget build(BuildContext context) => const CustomPaint(
    key: Key('healthy-aura-hojas-miniatura'),
    painter: _LeafAuraPainter(progress: 0, foreground: false, thumbnail: true),
    foregroundPainter:
        _LeafAuraPainter(progress: 0, foreground: true, thumbnail: true),
  );
}

class _LeafAuraPainter extends CustomPainter {
  const _LeafAuraPainter({
    required this.progress,
    required this.foreground,
    this.thumbnail = false,
  });

  final double progress;
  final bool foreground;
  final bool thumbnail;

  static const _lime = Color(0xFFB9FF70);
  static const _green = Color(0xFF3CD774);
  static const _deep = Color(0xFF087C4B);
  static const _positions = <Offset>[
    Offset(31, 77),
    Offset(254, 80),
    Offset(18, 164),
    Offset(267, 165),
    Offset(47, 222),
    Offset(241, 217),
    Offset(50, 31),
    Offset(235, 28),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width / 280, size.height / 275);
    if (!foreground) {
      _environment(canvas);
    } else {
      _leafParticles(canvas);
    }
    canvas.restore();
  }

  void _environment(Canvas canvas) {
    // Luz ambiental verde, con centro transparente para mantener legibles
    // el rostro, la skin y los accesorios.
    final pulse = 0.92 + math.sin(progress * math.pi * 2) * 0.08;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(140, 137), width: 248, height: 246),
      Paint()
        ..shader = RadialGradient(colors: [
          _green.withValues(alpha: thumbnail ? .06 : .055),
          _green.withValues(alpha: .16 * pulse),
          _lime.withValues(alpha: .08 * pulse),
          Colors.transparent,
        ], stops: const [0, .54, .78, 1]).createShader(
          const Rect.fromLTWH(0, 2, 280, 268),
        ),
    );

    // Halo que rodea la silueta desde atrás. Dos trazos suaves producen
    // un borde visible sin dibujar encima de la cara.
    final contour = Path()
      ..moveTo(140, 21)
      ..cubicTo(82, 8, 29, 50, 31, 117)
      ..cubicTo(8, 167, 42, 215, 72, 228)
      ..quadraticBezierTo(140, 274, 208, 228)
      ..cubicTo(246, 207, 266, 156, 249, 111)
      ..cubicTo(251, 53, 200, 13, 140, 21)
      ..close();
    canvas.drawPath(contour, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..color = _green.withValues(alpha: .35 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13));
    canvas.drawPath(contour, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..color = _lime.withValues(alpha: .62 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Suelo: efecto circular bajo los pies, no pegado al torso.
    final ground = Rect.fromCenter(
      center: const Offset(140, 250), width: 207, height: 31,
    );
    canvas.drawOval(ground.inflate(9), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = _green.withValues(alpha: .32 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawOval(ground, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = _lime.withValues(alpha: .85));
    canvas.drawOval(ground.deflate(9), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = _green.withValues(alpha: .5));
  }

  void _leafParticles(Canvas canvas) {
    for (var i = 0; i < _positions.length; i++) {
      final origin = _positions[i];
      final phase = progress * math.pi * 2 + i * .79;
      final dx = math.cos(phase) * (thumbnail ? 3 : 8);
      final dy = math.sin(phase) * (thumbnail ? 3 : 6);
      final point = origin.translate(dx, dy);
      final angle = phase * .45 + i * .4;
      final radius = thumbnail ? 7.0 : (i.isEven ? 8.0 : 5.5);
      _leaf(canvas, point, angle, radius);
      if (i.isEven) {
        _sparkle(canvas,
          origin.translate(14 + math.sin(phase) * 2, -12),
          2.6 + (math.sin(phase) + 1) * 1.2);
      }
    }
  }

  void _leaf(Canvas canvas, Offset point, double angle, double radius) {
    canvas.save();
    canvas.translate(point.dx, point.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(-radius, 0)
      ..quadraticBezierTo(-1.2 * radius, -radius, radius, 0)
      ..quadraticBezierTo(0, radius, -radius, 0)
      ..close();
    canvas.drawPath(path, Paint()
      ..color = _green.withValues(alpha: .45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawPath(path, Paint()..color = _green);
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = _lime);
    canvas.drawLine(Offset(-radius * .65, 0), Offset(radius * .68, 0),
      Paint()..color = _deep..strokeWidth = 1.1);
    canvas.restore();
  }

  void _sparkle(Canvas canvas, Offset center, double radius) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx + radius * .24,
          center.dy - radius * .24, center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx + radius * .24,
          center.dy + radius * .24, center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx - radius * .24,
          center.dy + radius * .24, center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx - radius * .24,
          center.dy - radius * .24, center.dx, center.dy - radius)
      ..close();
    canvas.drawPath(path, Paint()..color = _lime.withValues(alpha: .9));
  }

  @override
  bool shouldRepaint(covariant _LeafAuraPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.foreground != foreground ||
      oldDelegate.thumbnail != thumbnail;
}
