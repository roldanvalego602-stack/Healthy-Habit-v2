import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Nueve diseños originales dibujados en Flutter: no requieren imágenes externas.
/// El UFO clásico conserva el recurso gráfico oficial de Healthy Habit.
class HealthyUfoSkinArt extends StatelessWidget {
  const HealthyUfoSkinArt({
    super.key, required this.id, this.size = 96, this.phase = 0,
  });

  final String id;
  final double size;
  final double phase;

  static const ids = <String>{
    'ufo_cosmos', 'ufo_neon', 'ufo_gold', 'ufo_shadow',
    'ufo_botanical', 'ufo_glitch', 'ufo_lava',
    'ufo_primitive', 'ufo_carrot',
  };

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Aspecto de OVNI: ${id.replaceAll('ufo_', '')}',
    image: true,
    child: SizedBox.square(
      dimension: size,
      child: RepaintBoundary(
        child: CustomPaint(painter: _UfoSkinPainter(id, phase)),
      ),
    ),
  );
}

class _UfoSkinPainter extends CustomPainter {
  const _UfoSkinPainter(this.id, this.phase);
  final String id;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final (primary, secondary, light) = switch (id) {
      'ufo_cosmos' => (const Color(0xFF40359A), const Color(0xFF15183E), const Color(0xFF73E5FF)),
      'ufo_neon' => (const Color(0xFF19212B), const Color(0xFF111119), const Color(0xFFCAFF40)),
      'ufo_gold' => (const Color(0xFFE6AA36), const Color(0xFF91521B), const Color(0xFFFFEEA1)),
      'ufo_shadow' => (const Color(0xFF434659), const Color(0xFF171929), const Color(0xFFAA91F9)),
      'ufo_botanical' => (const Color(0xFF4BA66D), const Color(0xFF185846), const Color(0xFFD8FF8F)),
      'ufo_glitch' => (const Color(0xFFAE42D7), const Color(0xFF24245A), const Color(0xFF29F4F4)),
      'ufo_lava' => (const Color(0xFFF17532), const Color(0xFF802B28), const Color(0xFFFFDB54)),
      'ufo_primitive' => (const Color(0xFF9B8666), const Color(0xFF53473A), const Color(0xFFD5E39B)),
      'ufo_carrot' => (const Color(0xFFFF8A32), const Color(0xFFBF4823), const Color(0xFFBFFF80)),
      _ => (const Color(0xFF34B7AD), const Color(0xFF215C64), const Color(0xFF91F4E0)),
    };
    final outline = Paint()
      ..color = const Color(0xFF122D31)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;
    final shadow = Paint()..color = const Color(0xFF182432).withValues(alpha: .19);
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 86), width: 57, height: 10), shadow);
    final flame = Paint()
      ..color = light.withValues(alpha: .36 + .12 * math.sin(phase * math.pi * 2).abs());
    final jet = Path()
      ..moveTo(34, 71)..quadraticBezierTo(38, 91, 45, 95)
      ..lineTo(55, 95)..quadraticBezierTo(62, 91, 66, 71)..close();
    canvas.drawPath(jet, flame);
    // Cabina abovedada con pasajero y ojos: mantiene la identidad amistosa.
    final glass = Paint()..shader = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [light.withValues(alpha: .95), primary.withValues(alpha: .9)],
    ).createShader(const Rect.fromLTWH(30, 13, 40, 47));
    const dome = Rect.fromLTWH(29, 16, 42, 47);
    canvas.drawOval(dome, glass);
    canvas.drawOval(dome, outline);
    canvas.drawOval(const Rect.fromLTWH(39, 33, 22, 23),
      Paint()..color = const Color(0xFF7AD27C));
    canvas.drawCircle(const Offset(45, 43), 2, Paint()..color = const Color(0xFF152B35));
    canvas.drawCircle(const Offset(55, 43), 2, Paint()..color = const Color(0xFF152B35));
    canvas.drawArc(const Rect.fromLTWH(46, 43, 8, 7), .15, 2.75, false,
      Paint()..color = const Color(0xFF224B3B)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    // Cuerpo principal, ala frontal y cinco puntos de luz.
    final hull = Paint()..shader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [primary, secondary],
    ).createShader(const Rect.fromLTWH(8, 45, 84, 34));
    const saucer = Rect.fromLTWH(8, 49, 84, 28);
    canvas.drawOval(saucer, hull);
    canvas.drawOval(saucer, outline);
    canvas.drawArc(const Rect.fromLTWH(14, 54, 72, 17), .20, 2.75, false,
      Paint()..color = light.withValues(alpha: .76)
        ..strokeWidth = 2..style = PaintingStyle.stroke);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(Offset(22 + i * 14, 64), 2.6,
        Paint()..color = i.isEven ? light : const Color(0xFFF8F4E3));
    }
    if (id == 'ufo_carrot' || id == 'ufo_botanical') {
      final leaf = Paint()..color = const Color(0xFF52BB57);
      final stem = Path()..moveTo(50, 18)..quadraticBezierTo(38, 1, 34, 10)
        ..quadraticBezierTo(37, 23, 50, 22)
        ..quadraticBezierTo(64, 1, 68, 9)
        ..quadraticBezierTo(67, 20, 50, 22)..close();
      canvas.drawPath(stem, leaf);
      canvas.drawLine(const Offset(50, 23), const Offset(50, 7),
        Paint()..color = const Color(0xFF247243)..strokeWidth = 2);
    }
    if (id == 'ufo_primitive') {
      final bone = Paint()..color = const Color(0xFFF4EBD1)..strokeWidth = 3.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(27, 60), const Offset(38, 70), bone);
      canvas.drawCircle(const Offset(26, 59), 3.7, bone);
      canvas.drawCircle(const Offset(39, 71), 3.7, bone);
    }
    if (id == 'ufo_cosmos' || id == 'ufo_glitch' || id == 'ufo_neon') {
      for (final star in const [Offset(15, 23), Offset(83, 24), Offset(75, 11)]) {
        final p = Paint()..color = light..strokeWidth = 1.8;
        canvas.drawLine(star.translate(-3, 0), star.translate(3, 0), p);
        canvas.drawLine(star.translate(0, -3), star.translate(0, 3), p);
      }
    }
    if (id == 'ufo_lava') {
      final p = Paint()..color = light;
      for (final x in [29.0, 50.0, 71.0]) {
        canvas.drawCircle(Offset(x, 77 + math.sin(x) * 3), 3.2, p);
      }
    }
    if (id == 'ufo_gold') {
      final p = Paint()..color = light..strokeWidth = 2.3;
      canvas.drawLine(const Offset(49, 9), const Offset(49, 2), p);
      canvas.drawCircle(const Offset(49, 4), 3.3, p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _UfoSkinPainter oldDelegate) =>
      oldDelegate.id != id || oldDelegate.phase != phase;
}
