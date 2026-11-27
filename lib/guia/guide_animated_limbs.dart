import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'guide_gesture.dart';

/// Capa vectorial independiente del sprite, sin paquetes ni imágenes nuevas.
/// Los puntos están normalizados a la caja del personaje y se recortan
/// dentro de ella: evita sobrepasar los botones del recorrido.
class GuideAnimatedLimbs extends StatelessWidget {
  const GuideAnimatedLimbs({
    super.key,
    required this.gesture,
    required this.phase,
    required this.motion,
    required this.facesLeft,
    required this.accent,
  });

  final HealthyGuideGesture gesture;
  final Animation<double> phase;
  final bool motion;
  final bool facesLeft;
  final Color accent;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: phase,
      builder: (_, __) => CustomPaint(
        key: const ValueKey('guide-articulated-limbs'),
        painter: GuideLimbPainter(
          gesture: gesture,
          phase: motion ? phase.value : 0,
          motion: motion,
          facesLeft: facesLeft,
          accent: accent,
        ),
      ),
    ),
  );
}

/// Brazos con hombro, codo y mano independientes; la pose se calcula
/// de forma determinista a partir del gesto y la fase de animación.
class GuideLimbPainter extends CustomPainter {
  const GuideLimbPainter({
    required this.gesture,
    required this.phase,
    required this.motion,
    required this.facesLeft,
    required this.accent,
  });

  final HealthyGuideGesture gesture;
  final double phase;
  final bool motion;
  final bool facesLeft;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final unit = size.width;
    final wave = motion ? math.sin(phase * 2 * math.pi) : 0.0;
    final stroke = (unit * .070).clamp(3.2, 8.2).toDouble();

    // El sprite es la capa frontal; estas extremidades quedan detrás.
    final arm = Paint()
      ..color = const Color(0xFF42B879)
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final edge = Paint()
      ..color = const Color(0xFF147D56)
      ..strokeWidth = stroke + 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final glove = Paint()..color = const Color(0xFF85E0A4);
    final gloveEdge = Paint()
      ..color = const Color(0xFF147D56)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final leftShoulder = Offset(unit * .26, size.height * .55);
    final rightShoulder = Offset(unit * .74, size.height * .55);

    Offset hand(bool left) {
      final side = left ? -1.0 : 1.0;
      switch (gesture) {
        case HealthyGuideGesture.greet:
          final active = left == facesLeft;
          return active
              ? Offset(unit * (.5 + side * (.34 + .035 * wave)),
                  size.height * (.17 + .035 * wave))
              : Offset(unit * (.5 + side * .39), size.height * .73);
        case HealthyGuideGesture.present:
          return Offset(unit * (.5 + side * .42),
              size.height * (.42 - .035 * wave));
        case HealthyGuideGesture.point:
          final active = left == facesLeft;
          return active
              ? Offset(unit * (.5 + side * (.47 + .015 * wave)),
                  size.height * (.35 - .02 * wave))
              : Offset(unit * (.5 + side * .37), size.height * .72);
        case HealthyGuideGesture.inspect:
          return Offset(unit * (.5 + side * (.38 + .02 * wave)),
              size.height * (.32 + .015 * wave));
        case HealthyGuideGesture.celebrate:
          return Offset(unit * (.5 + side * (.33 + .015 * wave)),
              size.height * (.13 + .025 * wave));
        case HealthyGuideGesture.farewell:
          final active = left != facesLeft;
          return active
              ? Offset(unit * (.5 + side * (.32 + .04 * wave)),
                  size.height * (.18 + .035 * wave))
              : Offset(unit * (.5 + side * .38), size.height * .73);
      }
    }

    void drawArm(Offset shoulder, Offset wrist, bool left) {
      final sign = left ? -1.0 : 1.0;
      final elbow = Offset(
        (shoulder.dx + wrist.dx) / 2 + sign * unit * .065,
        (shoulder.dy + wrist.dy) / 2 + size.height * .045,
      );
      final path = Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..quadraticBezierTo(elbow.dx, elbow.dy, wrist.dx, wrist.dy);
      canvas.drawPath(path, edge);
      canvas.drawPath(path, arm);
      canvas.drawCircle(wrist, stroke * .72, glove);
      canvas.drawCircle(wrist, stroke * .72, gloveEdge);
      // Pequeña hoja en la mano, en lugar de dedos falsamente articulados.
      final leaf = Path()
        ..moveTo(wrist.dx - sign * stroke * .12, wrist.dy)
        ..quadraticBezierTo(wrist.dx + sign * stroke * .45,
            wrist.dy - stroke * .9, wrist.dx + sign * stroke * .65,
            wrist.dy - stroke * .25)
        ..quadraticBezierTo(wrist.dx + sign * stroke * .22,
            wrist.dy + stroke * .2, wrist.dx - sign * stroke * .12,
            wrist.dy);
      canvas.drawPath(leaf, Paint()..color = accent.withValues(alpha: .8));
    }

    // Se dibujan antes del sprite principal para que el hombro se esconda.
    drawArm(leftShoulder, hand(true), true);
    drawArm(rightShoulder, hand(false), false);

    if (gesture == HealthyGuideGesture.celebrate) {
      for (final x in [.15, .5, .85]) {
        final center = Offset(unit * x,
            size.height * (.09 + (motion ? .015 * wave : 0)));
        canvas.drawCircle(center, unit * .018,
            Paint()..color = accent.withValues(alpha: .7));
      }
    }
  }

  @override
  bool shouldRepaint(covariant GuideLimbPainter old) =>
      gesture != old.gesture ||
      phase != old.phase ||
      motion != old.motion ||
      facesLeft != old.facesLeft ||
      accent != old.accent;
}
