import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'logros_service.dart';
import '../../tema/healthy_visual_mode.dart';

Color colorRareza(RarezaLogro rareza) {
  switch (rareza) {
    case RarezaLogro.frecuente: return const Color(0xFFBECBD5);
    case RarezaLogro.pocoFrecuente: return const Color(0xFF61C7FF);
    case RarezaLogro.especial: return const Color(0xFFE5ACFF);
    case RarezaLogro.epico: return const Color(0xFFAB7CFF);
    case RarezaLogro.legendario: return const Color(0xFFFFD075);
  }
}

/// Cinco medallas vectoriales: forma, adornos y animación crecen con la rareza.
class LogroInsignia extends StatefulWidget {
  const LogroInsignia({
    super.key, required this.rareza, required this.icono,
    required this.desbloqueado, this.size = 90,
  });
  final RarezaLogro rareza;
  final IconData icono;
  final bool desbloqueado;
  final double size;

  @override
  State<LogroInsignia> createState() => _LogroInsigniaState();
}

class _LogroInsigniaState extends State<LogroInsignia>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2800));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant LogroInsignia oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final enabled = widget.desbloqueado &&
      widget.rareza != RarezaLogro.frecuente &&
      TickerMode.of(context) && HealthyVisualEffects.enabled(context);
    if (enabled) {
      if (!_animation.isAnimating) _animation.repeat();
    } else {
      _animation.stop();
      _animation.value = 0;
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tone = widget.desbloqueado
        ? colorRareza(widget.rareza) : const Color(0xFF7D8997);
    return Semantics(
      label: 'Insignia ${widget.rareza.etiqueta}, ${widget.desbloqueado ? "desbloqueada" : "bloqueada"}',
      image: true,
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) => Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(widget.size),
                  painter: _EmblemPainter(
                    rareza: widget.rareza,
                    unlocked: widget.desbloqueado,
                    phase: _animation.value,
                  ),
                ),
                Icon(widget.icono,
                  size: widget.size * 0.30, color: tone,
                  shadows: widget.desbloqueado && HealthyVisualEffects.allowDecorativeShadows
                      ? [Shadow(color: tone.withValues(alpha: 0.6), blurRadius: 9)] : null,
                ),
                if (!widget.desbloqueado)
                  Positioned(
                    right: widget.size * 0.08,
                    bottom: widget.size * 0.08,
                    child: Icon(Icons.lock_rounded, color: Colors.white70,
                      size: widget.size * 0.15),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter({
    required this.rareza, required this.unlocked, required this.phase,
  });
  final RarezaLogro rareza;
  final bool unlocked;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final color = unlocked ? colorRareza(rareza) : const Color(0xFF687685);
    final pulse = (math.sin(phase * math.pi * 2) + 1) / 2;
    const center = Offset(50, 52);

    if (unlocked && rareza.index >= 2) {
      canvas.drawCircle(center, 32 + 4 * pulse,
        Paint()..color = color.withValues(alpha: 0.15 + 0.12 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    }

    // Poco frecuente: pináculos laterales; especial: hojas + cristal.
    if (rareza == RarezaLogro.pocoFrecuente) {
      for (final x in [12.0, 88.0]) {
        canvas.drawLine(Offset(x, 39), Offset(x, 63),
          Paint()..strokeWidth = 3..strokeCap = StrokeCap.round
            ..color = color.withValues(alpha: 0.7));
      }
      _diamond(canvas, const Offset(50, 14), 5, color);
    } else if (rareza == RarezaLogro.especial) {
      for (final side in [-1.0, 1.0]) {
        for (var i = 0; i < 3; i++) {
          canvas.drawOval(Rect.fromCenter(
            center: Offset(50 + side * (34 + i * 2), 35 + i * 10.0),
            width: 6, height: 11),
            Paint()..color = color.withValues(alpha: 0.55));
        }
      }
      _diamond(canvas, const Offset(50, 13), 8, color);
    } else if (rareza == RarezaLogro.epico) {
      // Épico: órbita y fragmentos cristalinos.
      canvas.drawOval(Rect.fromCenter(center: center, width: 90, height: 51),
        Paint()..color = color.withValues(alpha: 0.55)
          ..strokeWidth = 1.8..style = PaintingStyle.stroke);
      for (var i = 0; i < 5; i++) {
        final a = i * math.pi * 2 / 5 + (unlocked ? phase * math.pi * 2 : 0);
        _diamond(canvas, Offset(50 + math.cos(a) * 43, 52 + math.sin(a) * 28),
          4.5, color.withValues(alpha: unlocked ? 0.85 : 0.38));
      }
    } else if (rareza == RarezaLogro.legendario) {
      // Legendario: corona, alas y aureola rotatoria.
      canvas.drawCircle(center, 41, Paint()
        ..color = color.withValues(alpha: 0.6)
        ..strokeWidth = 1.4..style = PaintingStyle.stroke);
      for (final side in [-1.0, 1.0]) {
        for (var i = 0; i < 4; i++) {
          canvas.drawLine(
            Offset(50 + side * 28, 35 + i * 9.0),
            Offset(50 + side * (46 - i * 2), 16 + i * 10.0),
            Paint()..strokeWidth = 3.3 - i * 0.4
              ..strokeCap = StrokeCap.round..color = color.withValues(alpha: 0.77));
        }
      }
      for (var i = 0; i < 9; i++) {
        final angle = math.pi * 2 * i / 9 + (unlocked ? phase * math.pi * 2 : 0);
        canvas.drawCircle(
          Offset(50 + math.cos(angle) * 41, 52 + math.sin(angle) * 41),
          i.isEven ? 2.0 : 1.2,
          Paint()..color = color.withValues(alpha: unlocked ? 0.85 : 0.3));
      }
    }

    final sides = rareza.index >= 3 ? 8 : 6;
    final outer = _poly(center, 34, sides);
    final inner = _poly(center, 29, sides);
    canvas.drawPath(outer, Paint()
      ..color = color.withValues(alpha: 0.3)..strokeWidth = 3
      ..style = PaintingStyle.stroke);
    canvas.drawPath(inner, Paint()
      ..shader = const RadialGradient(colors: [
        Color(0xFF30465A), Color(0xFF101A29),
      ]).createShader(const Rect.fromLTWH(17, 19, 66, 66)));
    canvas.drawPath(inner, Paint()
      ..color = color.withValues(alpha: unlocked ? 0.94 : 0.4)
      ..strokeWidth = rareza.index >= 2 ? 3 : 2
      ..style = PaintingStyle.stroke);

    if (rareza.index >= 2) {
      canvas.drawPath(_poly(center, 22, sides), Paint()
        ..color = color.withValues(alpha: 0.3)..strokeWidth = 1
        ..style = PaintingStyle.stroke);
    }

    if (rareza == RarezaLogro.legendario) {
      final crown = Path()..moveTo(36, 17)..lineTo(35, 5)
        ..lineTo(44, 12)..lineTo(50, 1)..lineTo(56, 12)
        ..lineTo(65, 5)..lineTo(64, 17)..close();
      canvas.drawPath(crown, Paint()..color = color);
      _diamond(canvas, const Offset(50, 11), 3.5,
        const Color(0xFFE58C7A));
    }

    if (unlocked && rareza.index >= 2) {
      final number = rareza == RarezaLogro.legendario ? 9
        : rareza == RarezaLogro.epico ? 6 : 3;
      for (var i = 0; i < number; i++) {
        final a = math.pi * 2 * i / number +
          (rareza.index >= 3 ? phase * math.pi * 2 : 0);
        canvas.drawCircle(Offset(50 + math.cos(a) * 38,
          52 + math.sin(a) * 38), 1.5,
          Paint()..color = color.withValues(alpha: 0.3 + 0.6 * pulse));
      }
    }
    canvas.restore();
  }

  Path _poly(Offset c, double r, int sides) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final a = -math.pi / 2 + i * math.pi * 2 / sides;
      final x = c.dx + r * math.cos(a);
      final y = c.dy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  void _diamond(Canvas canvas, Offset center, double r, Color color) {
    final path = Path()..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r * 0.75, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r * 0.75, center.dy)..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _EmblemPainter old) =>
    rareza != old.rareza || unlocked != old.unlocked || phase != old.phase;
}
