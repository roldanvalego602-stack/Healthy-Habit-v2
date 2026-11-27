import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Fondo con recorte real, sin reemplazar ni copiar el widget señalado.
class HealthyGuideSpotlightPainter extends CustomPainter {
  const HealthyGuideSpotlightPainter({
    required this.target,
    required this.phase,
    required this.accent,
  });

  final Rect? target;
  final double phase;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final canvasRect = Offset.zero & size;
    canvas.saveLayer(canvasRect, Paint());
    canvas.drawRect(canvasRect, Paint()..color = const Color(0xCB071420));
    if (target != null) {
      final hole = RRect.fromRectAndRadius(
        target!.inflate(7), const Radius.circular(18));
      canvas.drawRRect(hole, Paint()..blendMode = BlendMode.clear);
    }
    canvas.restore();
    if (target == null) return;

    final ring = RRect.fromRectAndRadius(
      target!.inflate(7 + 2 * math.sin(phase * 2 * math.pi).abs()),
      const Radius.circular(19));
    canvas.drawRRect(ring, Paint()
      ..color = accent.withValues(alpha: .20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
    canvas.drawRRect(ring, Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3);
  }

  @override
  bool shouldRepaint(covariant HealthyGuideSpotlightPainter old) =>
      target != old.target || phase != old.phase || accent != old.accent;
}
