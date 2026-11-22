import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'healthy_visual_mode.dart';

/// Flotación decorativa contenida: no modifica el layout ni captura gestos.
/// Se detiene en Lite, al reducir movimiento y cuando TickerMode está apagado.
class HealthyFloat extends StatefulWidget {
  const HealthyFloat({
    super.key,
    required this.child,
    this.distance = 4,
    this.duration = const Duration(milliseconds: 2600),
    this.enabled = true,
  });

  final Widget child;
  final double distance;
  final Duration duration;
  final bool enabled;

  @override
  State<HealthyFloat> createState() => _HealthyFloatState();
}

class _HealthyFloatState extends State<HealthyFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    HealthyVisualController.instance.addListener(_onVisualModeChanged);
  }

  void _onVisualModeChanged() {
    if (!mounted) return;
    _sync();
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant HealthyFloat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    _sync();
  }

  void _sync() {
    final shouldRun = widget.enabled &&
        HealthyVisualEffects.enabled(context) && TickerMode.of(context);
    if (shouldRun == _running) return;
    _running = shouldRun;
    if (shouldRun) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    HealthyVisualController.instance.removeListener(_onVisualModeChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_running) return widget.child;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -math.sin(_controller.value * math.pi * 2) *
              widget.distance),
          child: child,
        ),
      ),
    );
  }
}

/// Solo para símbolos pequeños y decorativos (fuego, trofeo, moneda).
/// No se utiliza en el texto ni en controles interactivos.
class HealthyGlowIcon extends StatelessWidget {
  const HealthyGlowIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 24,
    this.float = true,
  });

  final IconData icon;
  final Color color;
  final double size;
  final bool float;

  @override
  Widget build(BuildContext context) {
    final decorated = Icon(
      icon,
      color: color,
      size: size,
      shadows: HealthyVisualEffects.enabled(context)
          ? [Shadow(color: color.withValues(alpha: 0.45), blurRadius: 11)]
          : null,
    );
    return HealthyFloat(
      enabled: float,
      distance: 2.5,
      child: decorated,
    );
  }
}
