import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../páginas/tienda/shop_service.dart';
import '../páginas/tienda/healthy_ufo_skin_art.dart';

/// Presentación animada del OVNI original. No modifica el archivo PNG.
/// El propulsor está dibujado con Flutter para que reaccione al movimiento.
class HealthyUfoVisual extends StatelessWidget {
  const HealthyUfoVisual({
    super.key,
    required this.phase,
    this.dragging = false,
    this.tilt = 0,
  });

  final Animation<double> phase;
  final bool dragging;
  final double tilt;

  static const asset = 'assets/UFO/Mascota de Hábitos Saludables en Ovni.png';

  @override
  Widget build(BuildContext context) {
    // Sin Firebase (p. ej. pruebas widget), conserva el OVNI original.
    if (Firebase.apps.isEmpty) return _visual(context, null);
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, session) {
        if (session.data == null) return _visual(context, null);
        return StreamBuilder<ShopState>(
          key: ValueKey('ufo-inventario-${session.data!.uid}'),
          stream: ShopService.instance.watch(),
          builder: (context, snapshot) {
            final state = snapshot.data;
            final id = state?.equipped['ufo_skin'];
            return _visual(context, id != null &&
                HealthyUfoSkinArt.ids.contains(id) && state!.owns(id)
                ? id : null);
          },
        );
      },
    );
  }

  Widget _visual(BuildContext context, String? skinId) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: phase,
      builder: (context, _) {
        final t = reduceMotion ? 0.0 : phase.value * math.pi * 2;
        final hover = dragging || reduceMotion ? 0.0 : math.sin(t) * 3.5;
        final thrust = dragging ? 1.0 : (reduceMotion ? .35 : .45 + .18 * math.sin(t));
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: 1,
              left: 12,
              right: 12,
              height: 24,
              child: CustomPaint(
                painter: _UfoThrustPainter(
                  intensity: thrust,
                  phase: reduceMotion ? 0 : phase.value,
                ),
              ),
            ),
            Positioned.fill(
              bottom: 10,
              child: Transform.translate(
                offset: Offset(0, hover),
                child: Transform.rotate(
                  angle: reduceMotion ? 0 : tilt,
                  child: skinId == null
                      ? Image.asset(
                          asset,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFF23BAAD),
                          ),
                        )
                      : FittedBox(
                          fit: BoxFit.contain,
                          child: HealthyUfoSkinArt(
                            id: skinId,
                            size: 80,
                            phase: reduceMotion ? 0 : phase.value,
                          ),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UfoThrustPainter extends CustomPainter {
  const _UfoThrustPainter({required this.intensity, required this.phase});
  final double intensity;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;
    final beam = Paint()
      ..color = const Color(0xFF41E7EA).withValues(alpha: .12 + .25 * intensity)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final streak = Paint()
      ..color = const Color(0xFF25C6E3).withValues(alpha: .3 + .6 * intensity)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = -2; i <= 2; i++) {
      final x = center + i * size.width * .105;
      final stagger = ((phase + (i + 2) * .17) % 1);
      final start = 2 + stagger * 8;
      final finish = math.min(size.height - 1, start + 6 + 5 * intensity);
      canvas.drawLine(Offset(x, start), Offset(x, finish), i.isEven ? beam : streak);
    }
    final ring = Paint()
      ..color = const Color(0xFF3BE9D1).withValues(alpha: .18 + .35 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center, size.height - 4),
        width: size.width * (.48 + phase * .12),
        height: 6,
      ),
      ring,
    );
  }

  @override
  bool shouldRepaint(covariant _UfoThrustPainter oldDelegate) =>
      intensity != oldDelegate.intensity || phase != oldDelegate.phase;
}
