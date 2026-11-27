import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'guide_character_pose.dart';

/// Línea curva de señalamiento visual. No consume eventos de toque.
class GuidePointerPainter extends CustomPainter {
  const GuidePointerPainter({
    required this.pose,
    required this.target,
    required this.progress,
    required this.accent,
  });

  final GuideCharacterPose pose;
  final Rect? target;
  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final destination = target;
    if (destination == null) return;
    final start = Offset(
      pose.facesLeft ? pose.bounds.left + 8 : pose.bounds.right - 8,
      pose.pointsUp ? pose.bounds.top + 34 : pose.bounds.bottom - 27,
    );
    final end = destination.center;
    final distance = (end - start).distance;
    if (distance < 20) return;

    // Evitar el texto de la tarjeta: la línea es corta y tenue;
    // la posición de la mascota ya evita su rectángulo.
    final direction = end - start;
    final control = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2 -
          math.min(55, distance * .18) * (pose.pointsUp ? -1 : 1),
    );
    final path = Path()..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    final opacity = (.57 + .21 * math.sin(progress * 2 * math.pi))
        .clamp(0.0, 1.0).toDouble();
    canvas.drawPath(path, Paint()
      ..color = accent.withValues(alpha: opacity * .33)
      ..strokeWidth = 9
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);
    canvas.drawPath(path, Paint()
      ..color = accent.withValues(alpha: opacity)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    final toward = direction / distance;
    final head = end - toward * 11;
    final tangent = Offset(-toward.dy, toward.dx);
    final arrow = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo((head + tangent * 5).dx, (head + tangent * 5).dy)
      ..moveTo(end.dx, end.dy)
      ..lineTo((head - tangent * 5).dx, (head - tangent * 5).dy);
    canvas.drawPath(arrow, Paint()
      ..color = accent.withValues(alpha: opacity)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke);
    canvas.drawCircle(end, 3.5, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant GuidePointerPainter old) =>
      pose.position != old.pose.position ||
      target != old.target ||
      progress != old.progress ||
      accent != old.accent;
}
