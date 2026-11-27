import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'healthy_theme.dart';
import 'healthy_visual_mode.dart';

/// Único identificador comercial del tema. No habilitar sin inventario.
const cosmosShopId = 'theme_cosmos';
const cosmosSlot = 'app_theme';

class CosmosPalette {
  static const background = Color(0xFF060816);
  static const surface = Color(0xFF141E3A);
  static const surfaceAlt = Color(0xFF1C2850);
  static const primary = Color(0xFF85CCFF);
  static const secondary = Color(0xFFC59FFF);
  static const cyan = Color(0xFF57E5FF);
  static const magenta = Color(0xFFEE91E8);
  static const text = Color(0xFFF4F7FF);
  static const muted = Color(0xFFB6C8E3);
  static const border = Color(0xFF647BB9);
}

/// Fondo de estrellas deterministas, nebulosas y dos astros orbitantes.
/// CustomPainter usa un solo controlador y no crea un widget por estrella.
class CosmosBackground extends StatefulWidget {
  const CosmosBackground({super.key});
  @override
  State<CosmosBackground> createState() => _CosmosBackgroundState();
}

class _CosmosBackgroundState extends State<CosmosBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, duration: const Duration(seconds: 24))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context) ||
        HealthyVisualController.instance.isLite;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _CosmosPainter(reduce ? null : _controller),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CosmosPainter extends CustomPainter {
  _CosmosPainter(this.motion) : super(repaint: motion);
  final Animation<double>? motion;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = CosmosPalette.background);
    canvas.drawRect(rect, Paint()..shader = const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF0F1A3B), Color(0xFF060816), Color(0xFF21113B)],
    ).createShader(rect));

    final t = (motion?.value ?? .18) * math.pi * 2;
    void glow(Offset center, double radius, Color color) {
      canvas.drawCircle(center, radius,
        Paint()..shader = RadialGradient(colors: [
          color.withValues(alpha: .27),
          color.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: center, radius: radius)));
    }

    glow(Offset(size.width * (.12 + .025 * math.sin(t)),
        size.height * .16), size.width * .8,
        const Color(0xFF3659D4));
    glow(Offset(size.width * (.90 + .03 * math.cos(t)),
        size.height * .79), size.width * .7,
        const Color(0xFF9E34A0));
    final random = math.Random(1729);
    final stars = (size.width * size.height / 2800).round().clamp(35, 145);
    for (var i = 0; i < stars; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = .45 + random.nextDouble() * 1.45;
      final phase = random.nextDouble() * math.pi * 2;
      final alpha = (.36 + .32 * math.sin(t + phase)).clamp(.12, .75);
      canvas.drawCircle(Offset(x, y + 6 * math.sin(t + phase)),
        radius, Paint()..color = Colors.white.withValues(alpha: alpha));
    }
    final moon = Offset(size.width * .83, size.height * .23);
    canvas.drawCircle(moon, 28,
      Paint()..color = const Color(0xFF7C98DD).withValues(alpha: .17));
    canvas.drawCircle(moon, 19,
      Paint()..color = const Color(0xFF9CC4F4).withValues(alpha: .20));
    final orbit = Offset(size.width * .22, size.height * .70);
    canvas.save();
    canvas.translate(orbit.dx, orbit.dy);
    canvas.rotate(.30);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero,
      width: 126, height: 38),
      Paint()..color = CosmosPalette.cyan.withValues(alpha: .20)
        ..style = PaintingStyle.stroke..strokeWidth = 1.6);
    canvas.drawCircle(Offset.zero, 26,
      Paint()..color = const Color(0xFF8065D8).withValues(alpha: .45));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CosmosPainter old) =>
      old.motion != motion;
}

/// Decorador para tarjetas existentes; conserva controles y accesibilidad.
/// Una sola animación para el brillo del borde, sin cambiar el layout.
class CosmosCardShell extends StatefulWidget {
  const CosmosCardShell({super.key, required this.child});
  final Widget child;
  @override
  State<CosmosCardShell> createState() => _CosmosCardShellState();
}

class _CosmosCardShellState extends State<CosmosCardShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this, duration: const Duration(seconds: 5));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = HealthyAdaptive.isCosmos &&
        !HealthyVisualController.instance.isLite &&
        !MediaQuery.disableAnimationsOf(context);
    if (animate && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!animate && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (!HealthyAdaptive.isCosmos) return widget.child;
    final lite = HealthyVisualController.instance.isLite ||
        MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: CosmosPalette.cyan.withValues(
            alpha: lite ? .32 : .24 + .27 * _pulse.value), width: 1.1),
          boxShadow: lite ? null : [
            BoxShadow(color: CosmosPalette.secondary.withValues(
              alpha: .055 + .055 * _pulse.value), blurRadius: 15),
          ],
        ),
        child: child,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          const Positioned(
            right: 7, top: 4,
            child: IgnorePointer(
              child: Icon(Icons.auto_awesome_rounded,
                size: 13, color: Color(0x6678E8FF)),
            ),
          ),
          const Positioned(
            left: 8, bottom: 7,
            child: IgnorePointer(
              child: Icon(Icons.circle, size: 5,
                color: Color(0x77C59FFF)),
            ),
          ),
        ],
      ),
    );
  }
}
