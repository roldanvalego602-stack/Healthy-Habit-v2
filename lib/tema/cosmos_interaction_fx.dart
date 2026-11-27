import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'cosmos_theme.dart';
import 'healthy_theme.dart';
import 'healthy_visual_mode.dart';

/// Cosmetic animation only. Never changes XP, coins, purchases or user data.
enum CosmosEffect { habit, reward, level, streak, purchase }

/// Finite burst of small orbital fragments, rendered in a single CustomPaint.
/// No timers, third-party assets, gesture interception or infinite animation.
class CosmosParticleBurst extends StatefulWidget {
  const CosmosParticleBurst({
    super.key,
    required this.effect,
    this.fullScreen = false,
    this.onFinished,
  });

  final CosmosEffect effect;
  final bool fullScreen;
  final VoidCallback? onFinished;

  @override
  State<CosmosParticleBurst> createState() => _CosmosParticleBurstState();
}

class _CosmosParticleBurstState extends State<CosmosParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds:
          widget.effect == CosmosEffect.level ? 1550 : 950),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onFinished?.call();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.status == AnimationStatus.dismissed) {
      if (HealthyAdaptive.isCosmos && HealthyVisualEffects.enabled(context)) {
        _controller.forward();
      } else {
        // No animation work in Lite or when animations are disabled.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onFinished?.call();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!HealthyAdaptive.isCosmos ||
        !HealthyVisualEffects.enabled(context)) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => CustomPaint(
            painter: _CosmosBurstPainter(
              progress: _controller.value,
              effect: widget.effect,
              fullScreen: widget.fullScreen,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _CosmosBurstPainter extends CustomPainter {
  const _CosmosBurstPainter({
    required this.progress,
    required this.effect,
    required this.fullScreen,
  });
  final double progress;
  final CosmosEffect effect;
  final bool fullScreen;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final random = math.Random(effect.index * 73 + 1907);
    final center = Offset(
      size.width * .5, size.height * (fullScreen ? .42 : .52));
    final scale = math.min(size.width, size.height);
    final maximumRadius = (fullScreen ? scale * .40 : scale * .55);
    final count = fullScreen ? 48 : 19;
    final easeOut = 1 - math.pow(1 - progress, 3).toDouble();
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final palette = switch (effect) {
      CosmosEffect.habit => [CosmosPalette.cyan, Colors.white,
        const Color(0xFFB1FFC9)],
      CosmosEffect.reward => [const Color(0xFFFFD98E),
        CosmosPalette.secondary, Colors.white],
      CosmosEffect.level => [CosmosPalette.cyan,
        CosmosPalette.magenta, Colors.white],
      CosmosEffect.streak => [const Color(0xFFFFD78A),
        const Color(0xFFFF99BF), Colors.white],
      CosmosEffect.purchase => [CosmosPalette.secondary,
        CosmosPalette.cyan, const Color(0xFFF8EAFF)],
    };
    if (effect == CosmosEffect.level) {
      final ring = Paint()
        ..color = CosmosPalette.cyan.withValues(alpha: opacity * .36)
        ..strokeWidth = fullScreen ? 3 : 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, maximumRadius * easeOut, ring);
      ring.color = CosmosPalette.secondary.withValues(alpha: opacity * .22);
      canvas.drawCircle(center, maximumRadius * easeOut * .69, ring);
    }

    for (var i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final velocity = .35 + .65 * random.nextDouble();
      final radius = maximumRadius * velocity * easeOut;
      final position = center + Offset(
        math.cos(angle) * radius,
        math.sin(angle) * radius - scale * .065 * progress,
      );
      final particleRadius = (fullScreen ? 2.2 : 1.5) +
          random.nextDouble() * (fullScreen ? 3.3 : 1.6);
      final color = palette[i % palette.length].withValues(
        alpha: opacity * (.48 + random.nextDouble() * .42),
      );
      canvas.drawCircle(position, particleRadius,
          Paint()..color = color);
      if (i % 4 == 0) {
        canvas.drawLine(
          position + Offset(-particleRadius * 2, 0),
          position + Offset(particleRadius * 2, 0),
          Paint()..color = color..strokeWidth = .9,
        );
        canvas.drawLine(
          position + Offset(0, -particleRadius * 2),
          position + Offset(0, particleRadius * 2),
          Paint()..color = color..strokeWidth = .9,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CosmosBurstPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.effect != effect ||
      oldDelegate.fullScreen != fullScreen;
}

/// Non-blocking full-screen moment, used only on a confirmed level-up.
/// The overlay removes itself when the finite animation completes.
class CosmosLevelOverlay {
  const CosmosLevelOverlay._();

  static void show(BuildContext context) {
    if (!HealthyAdaptive.isCosmos ||
        !HealthyVisualEffects.enabled(context)) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          child: CosmosParticleBurst(
            effect: CosmosEffect.level,
            fullScreen: true,
            onFinished: () {
              if (entry?.mounted == true) entry?.remove();
              entry?.dispose();
              entry = null;
            },
          ),
        ),
      ),
    );
    overlay.insert(entry);
  }
}
