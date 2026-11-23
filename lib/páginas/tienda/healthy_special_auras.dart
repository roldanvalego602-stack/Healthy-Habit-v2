import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../tema/healthy_visual_mode.dart';

/// Variantes ambientales. Ninguna altera los píxeles de la mascota ni
/// sustituye su imagen; se pintan alrededor y detrás del conjunto equipado.
enum HealthySpecialAura { stellar, golden }

class HealthySpecialAuraEffect extends StatefulWidget {
  const HealthySpecialAuraEffect({
    super.key,
    required this.kind,
    required this.child,
  });

  final HealthySpecialAura kind;
  final Widget child;

  @override
  State<HealthySpecialAuraEffect> createState() =>
      _HealthySpecialAuraEffectState();
}

class _HealthySpecialAuraEffectState extends State<HealthySpecialAuraEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );
    HealthyVisualController.instance.addListener(_sync);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant HealthySpecialAuraEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (!mounted) return;
    final enabled = TickerMode.of(context) &&
        HealthyVisualEffects.enabled(context);
    if (_playing == enabled) return;
    _playing = enabled;
    if (enabled) {
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
      builder: (context, child) {
        final phase = animated ? _controller.value : 0.0;
        return CustomPaint(
          key: ValueKey(widget.kind == HealthySpecialAura.stellar
              ? 'healthy-aura-estelar' : 'healthy-aura-dorada'),
          painter: _SpecialAuraPainter(
            kind: widget.kind, phase: phase, foreground: false),
          foregroundPainter: _SpecialAuraPainter(
            kind: widget.kind, phase: phase, foreground: true),
          child: child,
        );
      },
    );
  }
}

/// Miniatura de los mismos vectores. Sin animación ni archivo PNG adicional.
class HealthySpecialAuraThumbnail extends StatelessWidget {
  const HealthySpecialAuraThumbnail({super.key, required this.kind});

  final HealthySpecialAura kind;

  @override
  Widget build(BuildContext context) => CustomPaint(
    key: ValueKey(kind == HealthySpecialAura.stellar
        ? 'healthy-aura-estelar-miniatura' : 'healthy-aura-dorada-miniatura'),
    painter: _SpecialAuraPainter(
      kind: kind, phase: 0, foreground: false, thumbnail: true),
    foregroundPainter: _SpecialAuraPainter(
      kind: kind, phase: 0, foreground: true, thumbnail: true),
  );
}

class _SpecialAuraPainter extends CustomPainter {
  const _SpecialAuraPainter({
    required this.kind,
    required this.phase,
    required this.foreground,
    this.thumbnail = false,
  });

  final HealthySpecialAura kind;
  final double phase;
  final bool foreground;
  final bool thumbnail;

  static const _violet = Color(0xFF9D78FF);
  static const _cyan = Color(0xFF6EDAFF);
  static const _pink = Color(0xFFF4B5FF);
  static const _gold = Color(0xFFFFD461);
  static const _amber = Color(0xFFE8A934);
  static const _cream = Color(0xFFFFF3C2);

  static const _stars = <Offset>[
    Offset(35, 52), Offset(246, 54), Offset(17, 128),
    Offset(260, 135), Offset(45, 198), Offset(237, 203),
    Offset(68, 18), Offset(212, 18),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width / 280, size.height / 275);
    if (foreground) {
      kind == HealthySpecialAura.stellar
          ? _stellarParticles(canvas) : _goldenParticles(canvas);
    } else {
      _ambient(canvas);
    }
    canvas.restore();
  }

  void _ambient(Canvas canvas) {
    final color = kind == HealthySpecialAura.stellar ? _violet : _gold;
    final secondary = kind == HealthySpecialAura.stellar ? _cyan : _amber;
    final pulse = .92 + .08 * math.sin(phase * math.pi * 2);

    // Halo periférico: el centro queda casi transparente y las prendas,
    // los ojos y las extremidades permanecen al frente.
    final ambientRect = const Rect.fromLTWH(3, 4, 274, 257);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(140, 132), width: 252, height: 245),
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: .025),
            color.withValues(alpha: .12 * pulse),
            secondary.withValues(alpha: .16 * pulse),
            Colors.transparent,
          ],
          stops: const [0, .56, .8, 1],
        ).createShader(ambientRect),
    );

    final silhouette = Path()
      ..moveTo(140, 18)
      ..cubicTo(86, 4, 29, 49, 30, 118)
      ..cubicTo(8, 167, 36, 215, 72, 228)
      ..quadraticBezierTo(140, 273, 208, 228)
      ..cubicTo(247, 207, 269, 156, 249, 112)
      ..cubicTo(251, 53, 202, 7, 140, 18)
      ..close();
    canvas.drawPath(silhouette, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..color = color.withValues(alpha: .26 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    canvas.drawPath(silhouette, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kind == HealthySpecialAura.stellar ? 3 : 4
      ..color = secondary.withValues(alpha: .65 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    final ground = Rect.fromCenter(
      center: const Offset(140, 249), width: 208, height: 32);
    canvas.drawOval(ground.inflate(9), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..color = color.withValues(alpha: .34 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11));
    canvas.drawOval(ground, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kind == HealthySpecialAura.stellar ? 3 : 4
      ..color = secondary.withValues(alpha: .9));
    canvas.drawOval(ground.deflate(9), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = color.withValues(alpha: .6));

    if (kind == HealthySpecialAura.stellar) {
      _orbit(canvas, secondary);
    } else {
      _rays(canvas);
    }
  }

  void _orbit(Canvas canvas, Color color) {
    // Órbita luminosa en la región exterior, detrás de la mascota.
    final orbit = Rect.fromCenter(
      center: const Offset(140, 141), width: 252, height: 84);
    canvas.save();
    canvas.translate(140, 141);
    canvas.rotate(-.22 + math.sin(phase * math.pi * 2) * .04);
    canvas.translate(-140, -141);
    canvas.drawArc(orbit, .16, math.pi * .8, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.8
      ..color = color.withValues(alpha: .64)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawArc(orbit, math.pi + .16, math.pi * .76, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5
      ..color = _pink.withValues(alpha: .55));
    canvas.restore();
  }

  void _rays(Canvas canvas) {
    // Rayos discretos detrás del borde, como una corona de luz.
    final center = const Offset(140, 135);
    for (var i = 0; i < 14; i++) {
      final angle = math.pi * 2 * (i + .35) / 14;
      final dir = Offset(math.cos(angle), math.sin(angle));
      final start = center + Offset(dir.dx * 109, dir.dy * 105);
      final finish = center + Offset(dir.dx * (121 + i % 3 * 5),
          dir.dy * (115 + i % 3 * 5));
      canvas.drawLine(start, finish, Paint()
        ..color = _gold.withValues(alpha: .5)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = i.isEven ? 3 : 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
  }

  void _stellarParticles(Canvas canvas) {
    for (var i = 0; i < _stars.length; i++) {
      final t = phase * math.pi * 2 + i * .82;
      final origin = _stars[i];
      final point = origin.translate(
        math.cos(t) * (thumbnail ? 2 : 7),
        math.sin(t) * (thumbnail ? 2 : 8));
      final radius = (i % 3 == 0 ? 8.0 : 5.2) *
          (.9 + .1 * math.sin(t));
      _spark(canvas, point, radius,
          i.isEven ? _cyan : _pink);
      if (i.isEven) {
        canvas.drawCircle(point.translate(10, -12), 1.5,
          Paint()..color = _cream.withValues(alpha: .9));
      }
    }
  }

  void _goldenParticles(Canvas canvas) {
    for (var i = 0; i < _stars.length; i++) {
      final t = phase * math.pi * 2 + i * .8;
      final origin = _stars[i];
      final point = origin.translate(
        math.cos(t) * (thumbnail ? 2 : 5),
        math.sin(t) * (thumbnail ? 2 : 6));
      if (i.isEven) {
        _spark(canvas, point, i % 3 == 0 ? 9 : 6, _gold);
      } else {
        _laurel(canvas, point, -.7 + i * .34 + .14 * math.sin(t));
      }
    }
  }

  void _spark(Canvas canvas, Offset point, double radius, Color color) {
    final path = Path()
      ..moveTo(point.dx, point.dy - radius)
      ..quadraticBezierTo(point.dx + radius * .22, point.dy - radius * .2,
          point.dx + radius, point.dy)
      ..quadraticBezierTo(point.dx + radius * .22, point.dy + radius * .2,
          point.dx, point.dy + radius)
      ..quadraticBezierTo(point.dx - radius * .22, point.dy + radius * .2,
          point.dx - radius, point.dy)
      ..quadraticBezierTo(point.dx - radius * .22, point.dy - radius * .2,
          point.dx, point.dy - radius)
      ..close();
    canvas.drawPath(path, Paint()
      ..color = color.withValues(alpha: .32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: .9));
    canvas.drawCircle(point, 1.6, Paint()..color = Colors.white);
  }

  void _laurel(Canvas canvas, Offset center, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final shape = Path()
      ..moveTo(-7, 0)
      ..quadraticBezierTo(-3, -8, 8, -3)
      ..quadraticBezierTo(3, 6, -7, 0)
      ..close();
    canvas.drawPath(shape, Paint()..color = _amber);
    canvas.drawPath(shape, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _cream);
    canvas.drawLine(const Offset(-5, 0), const Offset(5, -2),
      Paint()..color = const Color(0xFFA76A1C)..strokeWidth = 1);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpecialAuraPainter oldDelegate) =>
      kind != oldDelegate.kind ||
      phase != oldDelegate.phase ||
      foreground != oldDelegate.foreground ||
      thumbnail != oldDelegate.thumbnail;
}
