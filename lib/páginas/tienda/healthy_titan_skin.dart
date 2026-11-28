import 'package:flutter/material.dart';

/// Ilustración original vectorial de Mr. Healthy Titán.
/// Se reutiliza tanto en el inventario como en el easter egg.
/// No descarga recursos ni modifica el perfil.
class HealthyTitanSkin extends StatelessWidget {
  const HealthyTitanSkin({super.key, this.size = 220, this.awakened = true});
  final double size;
  final bool awakened;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size * 1.17,
    child: CustomPaint(
      painter: _TitanPainter(awakened: awakened),
      isComplex: true,
    ),
  );
}

class _TitanPainter extends CustomPainter {
  const _TitanPainter({required this.awakened});
  final bool awakened;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 220, size.height / 257);
    final glow = Paint()..shader = RadialGradient(colors: [
      const Color(0xAA4DF1B4), const Color(0x0031D99A),
    ]).createShader(const Rect.fromLTWH(6, 2, 208, 253));
    if (awakened) canvas.drawOval(
      const Rect.fromLTWH(2, 10, 216, 233), glow);

    void ellipse(Rect r, Color c, {Color? edge, double stroke = 0}) {
      canvas.drawOval(r, Paint()..color = c);
      if (edge != null) canvas.drawOval(r, Paint()
        ..style = PaintingStyle.stroke..strokeWidth = stroke..color = edge);
    }
    void path(List<Offset> points, Color color, {Color? edge}) {
      final p = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) { p.lineTo(point.dx, point.dy); }
      p.close();
      canvas.drawPath(p, Paint()..color = color);
      if (edge != null) canvas.drawPath(p, Paint()
        ..color = edge..strokeWidth = 3..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round);
    }
    const deep = Color(0xFF134B37);
    const dark = Color(0xFF22694A);
    const green = Color(0xFF48C77F);
    const light = Color(0xFF98F1AD);
    const muscle = Color(0xFF61D989);
    const gold = Color(0xFFF6D57E);
    // Sombra y pies.
    ellipse(const Rect.fromLTWH(36, 232, 149, 15),
      const Color(0x66051418));
    path([const Offset(73,186),const Offset(102,191),
      const Offset(94,232),const Offset(55,237),const Offset(57,223)], deep);
    path([const Offset(124,190),const Offset(152,184),
      const Offset(170,224),const Offset(158,237),const Offset(124,229)], deep);
    ellipse(const Rect.fromLTWH(45,222,63,24), dark,edge:deep,stroke:3);
    ellipse(const Rect.fromLTWH(119,221,65,24), dark,edge:deep,stroke:3);
    // Brazos desproporcionados con bíceps delineados.
    ellipse(const Rect.fromLTWH(11,86,66,97), deep);
    ellipse(const Rect.fromLTWH(143,85,66,97), deep);
    ellipse(const Rect.fromLTWH(17,92,60,78), muscle,edge:deep,stroke:4);
    ellipse(const Rect.fromLTWH(143,91,60,78), muscle,edge:deep,stroke:4);
    ellipse(const Rect.fromLTWH(12,151,52,58), green,edge:deep,stroke:4);
    ellipse(const Rect.fromLTWH(157,150,52,58), green,edge:deep,stroke:4);
    ellipse(const Rect.fromLTWH(23,157,25,22), light);
    ellipse(const Rect.fromLTWH(169,156,25,22), light);
    // Torso en forma de pera musculosa.
    ellipse(const Rect.fromLTWH(52,54,117,157), deep);
    ellipse(const Rect.fromLTWH(58,61,105,143), green,edge:deep,stroke:3);
    ellipse(const Rect.fromLTWH(64,97,46,50), muscle);
    ellipse(const Rect.fromLTWH(112,97,46,50), muscle);
    ellipse(const Rect.fromLTWH(67,101,36,23), light);
    ellipse(const Rect.fromLTWH(119,101,32,23), light);
    // Abdomen de seis segmentos.
    for (var row=0;row<3;row++) {
      for(var col=0;col<2;col++) {
        final x=82.0+col*30, y=148.0+row*16;
        ellipse(Rect.fromLTWH(x,y,25,14),
          row==2 ? const Color(0xFF35AA6D) : muscle,
          edge:dark, stroke:1.8);
      }
    }
    // Cabeza de fruta y hoja de la mascota.
    ellipse(const Rect.fromLTWH(54,18,116,108), deep);
    ellipse(const Rect.fromLTWH(60,22,104,98), light,edge:deep,stroke:4);
    path([const Offset(108,34),const Offset(89,18),
      const Offset(103,0),const Offset(123,14),const Offset(118,33)],dark,
      edge:deep);
    path([const Offset(113,23),const Offset(126,4),
      const Offset(153,10),const Offset(146,27)],green,edge:deep);
    // Cejas de esfuerzo y ojos amables.
    canvas.drawLine(const Offset(77,59),const Offset(95,63),
      Paint()..color=deep..strokeWidth=6..strokeCap=StrokeCap.round);
    canvas.drawLine(const Offset(126,63),const Offset(145,59),
      Paint()..color=deep..strokeWidth=6..strokeCap=StrokeCap.round);
    ellipse(const Rect.fromLTWH(80,68,13,19),deep);
    ellipse(const Rect.fromLTWH(128,68,13,19),deep);
    ellipse(const Rect.fromLTWH(84,70,4,5),Colors.white);
    ellipse(const Rect.fromLTWH(132,70,4,5),Colors.white);
    final smile=Path()..moveTo(93,94)..quadraticBezierTo(110,110,130,94);
    canvas.drawPath(smile, Paint()..color=deep
      ..style=PaintingStyle.stroke..strokeWidth=4
      ..strokeCap=StrokeCap.round);
    ellipse(const Rect.fromLTWH(67,91,17,8),const Color(0x88FF9D82));
    ellipse(const Rect.fromLTWH(141,91,17,8),const Color(0x88FF9D82));
    // Emblema dorado de secreto, no es un artículo de tienda.
    path([const Offset(101,115),const Offset(111,111),
      const Offset(121,116),const Offset(119,126),
      const Offset(109,132),const Offset(100,125)],gold,edge:dark);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TitanPainter oldDelegate) =>
      oldDelegate.awakened != awakened;
}
