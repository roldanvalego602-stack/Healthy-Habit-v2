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
      vsync: this, duration: const Duration(seconds: 24));
    HealthyVisualController.instance.addListener(_syncMotion);
  }

  void _syncMotion() {
    if (!mounted) return;
    final animate = !HealthyVisualController.instance.isLite &&
        !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    if (animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void dispose() {
    HealthyVisualController.instance.removeListener(_syncMotion);
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
      final alpha = (.36 + .32 * math.sin(t + phase)).clamp(.12, .75).toDouble();
      canvas.drawCircle(Offset(x, y + 6 * math.sin(t + phase)),
        radius, Paint()..color = Colors.white.withValues(alpha: alpha));
    }
    // Una estrella fugaz por ciclo, con cola translucida.
    final cycle = motion?.value ?? 0.0;
    if (cycle > .43 && cycle < .62) {
      final progress = (cycle - .43) / .19;
      final head = Offset(
        size.width * (1.16 - 1.22 * progress),
        size.height * (.12 + .30 * progress),
      );
      final tail = head + Offset(size.width * .18, -size.height * .055);
      final opacity = (math.sin(progress * math.pi) * .78).clamp(0.0, .78).toDouble();
      canvas.drawLine(tail, head,
        Paint()..color = CosmosPalette.cyan.withValues(alpha: opacity)
          ..strokeWidth = 1.9
          ..strokeCap = StrokeCap.round);
      canvas.drawCircle(head, 2.4,
        Paint()..color = Colors.white.withValues(alpha: opacity));
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
    HealthyVisualController.instance.addListener(_syncMotion);
  }

  void _syncMotion() {
    if (!mounted) return;
    final animate = HealthyAdaptive.isCosmos &&
        !HealthyVisualController.instance.isLite &&
        !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    if (animate && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!animate && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void dispose() {
    HealthyVisualController.instance.removeListener(_syncMotion);
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

/// Microórbita exclusiva para iconos de hábitos y recompensas.
class CosmosOrbitingIcon extends StatefulWidget {
  const CosmosOrbitingIcon({
    super.key, required this.icon, this.size = 20,
  });
  final IconData icon;
  final double size;

  @override
  State<CosmosOrbitingIcon> createState() => _CosmosOrbitingIconState();
}

class _CosmosOrbitingIconState extends State<CosmosOrbitingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbit;
  @override
  void initState() {
    super.initState();
    _orbit = AnimationController(
      vsync: this, duration: const Duration(seconds: 7));
    HealthyVisualController.instance.addListener(_syncMotion);
  }

  void _syncMotion() {
    if (!mounted) return;
    final animate = HealthyAdaptive.isCosmos &&
        !HealthyVisualController.instance.isLite &&
        !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    if (animate && !_orbit.isAnimating) {
      _orbit.repeat();
    } else if (!animate && _orbit.isAnimating) {
      _orbit.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void dispose() {
    HealthyVisualController.instance.removeListener(_syncMotion);
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(widget.icon,
      size: widget.size, color: CosmosPalette.cyan);
    if (!HealthyAdaptive.isCosmos) return icon;
    return AnimatedBuilder(
      animation: _orbit,
      builder: (context, child) {
        final a = _orbit.value * math.pi * 2;
        return Transform.translate(
          offset: Offset(1.8 * math.cos(a), 2.7 * math.sin(a)),
          child: Transform.rotate(
            angle: .06 * math.sin(a), child: child),
        );
      },
      child: icon,
    );
  }
}

/// Barra de progreso del tema Cosmos: energía luminosa con valores reales.
/// Es puramente presentacional, no altera XP ni porcentajes.
class CosmosEnergyBar extends StatelessWidget {
  const CosmosEnergyBar({
    super.key, required this.value, this.height = 9,
    this.color = CosmosPalette.cyan,
  });
  final double value;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;
    if (!HealthyAdaptive.isCosmos) {
      return LinearProgressIndicator(
        value: progress,
        minHeight: height,
        backgroundColor: HealthyAdaptive.surfaceAlt,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      );
    }
    return Semantics(
      label: 'Progreso',
      value: '${(progress * 100).round()} por ciento',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFF17284E)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          CosmosPalette.secondary, color,
                          const Color(0xFFE5F9FF),
                        ]),
                        boxShadow: const [
                          BoxShadow(color: Color(0x6657E5FF),
                            blurRadius: 7),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
