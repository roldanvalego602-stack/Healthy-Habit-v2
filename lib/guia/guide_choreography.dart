import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'guide_fx_theme.dart';

/// Un solo CustomPainter para destellos y acentos. Sin timers, imágenes,
/// aleatoriedad por fotograma ni widgets por partícula.
class GuideChoreographyPainter extends CustomPainter {
  const GuideChoreographyPainter({
    required this.target,
    required this.phase,
    required this.intro,
    required this.fx,
    required this.motion,
  });

  final Rect? target;
  final double phase;
  /// Progreso 0..1 de entrada al paso (no se anima en modo Lite).
  final double intro;
  final GuideFxTheme fx;
  final bool motion;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = target;
    if (rect == null || rect.isEmpty) return;
    final visible = rect.intersect(Offset.zero & size);
    if (visible.isEmpty) return;

    final center = visible.center;
    final radius = math.max(visible.width, visible.height) / 2 + 19;
    final progress = motion ? phase : 0.22;
    final arrival = motion ? Curves.easeOutCubic.transform(
      intro.clamp(0.0, 1.0)) : 1.0;
    final base = (0.18 + 0.16 * math.sin(progress * math.pi * 2).abs()) *
        arrival;

    // Halo suave, contenido en torno al objetivo.
    canvas.drawCircle(center, radius * 1.25,
      Paint()..shader = RadialGradient(colors: [
        fx.accent.withValues(alpha: base),
        fx.accent.withValues(alpha: 0),
      ]).createShader(Rect.fromCircle(
        center: center, radius: radius * 1.25,
      )));

    // Los círculos de llegada se expanden solo en un paso nuevo.
    if (motion && intro < 1.0) {
      final ring = radius * (.66 + .37 * arrival);
      canvas.drawCircle(center, ring, Paint()
        ..color = fx.secondary.withValues(alpha: .45 * (1 - arrival))
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke);
    }

    final count = fx.cosmos ? 11 : 6;
    for (var i = 0; i < count; i++) {
      final theta = math.pi * 2 * i / count +
          (motion ? progress * (fx.cosmos ? .30 : .12) : 0);
      final radial = radius * (.90 + .12 * math.sin(i * 2.2 + progress * 6));
      final point = Offset(center.dx + radial * math.cos(theta),
          center.dy + radial * math.sin(theta));
      if (point.dx < 10 || point.dy < 55 ||
          point.dx > size.width - 10 ||
          point.dy > size.height - 15) {
        continue;
      }
      final shimmer = motion
          ? (.35 + .4 * math.sin(progress * math.pi * 2 + i).abs())
          : .4;
      final color = i.isEven ? fx.accent : fx.secondary;
      final diameter = (fx.cosmos ? 1.8 : 1.35) + (i % 3) * .4;
      canvas.drawCircle(point, diameter, Paint()
        ..color = color.withValues(alpha: shimmer * arrival));
      if (fx.cosmos && i % 3 == 0) {
        canvas.drawLine(point.translate(-3, 0), point.translate(3, 0),
          Paint()..color = color.withValues(alpha: shimmer * .55)
            ..strokeWidth = .7);
        canvas.drawLine(point.translate(0, -3), point.translate(0, 3),
          Paint()..color = color.withValues(alpha: shimmer * .55)
            ..strokeWidth = .7);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GuideChoreographyPainter old) =>
      target != old.target ||
      phase != old.phase ||
      intro != old.intro ||
      fx.accent != old.fx.accent ||
      fx.secondary != old.fx.secondary ||
      fx.cosmos != old.fx.cosmos ||
      motion != old.motion;
}
