import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../tema/healthy_visual_mode.dart';

/// Mr. Healthy saluda con un pequeño balanceo y cobra energía al responder.
/// Respeta modo Lite, accesibilidad y TickerMode para evitar trabajo innecesario.
class MrHealthyChatAvatar extends StatefulWidget {
  const MrHealthyChatAvatar({
    super.key,
    this.size = 52,
    this.isTyping = false,
  });

  final double size;
  final bool isTyping;

  @override
  State<MrHealthyChatAvatar> createState() => _MrHealthyChatAvatarState();
}

class _MrHealthyChatAvatarState extends State<MrHealthyChatAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
    );
    HealthyVisualController.instance.addListener(_onVisualModeChanged);
  }

  Duration get _duration => widget.isTyping
      ? const Duration(milliseconds: 1450)
      : const Duration(milliseconds: 3200);

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
  void didUpdateWidget(covariant MrHealthyChatAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTyping != widget.isTyping) {
      _controller.duration = _duration;
      if (_running) _controller.repeat();
    }
    _sync();
  }

  void _sync() {
    final run = HealthyVisualEffects.enabled(context) &&
        TickerMode.of(context);
    if (run == _running) return;
    _running = run;
    if (run) {
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
    final avatar = Image.asset(
      'assets/mascot/healthy.png',
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.eco_rounded,
        size: widget.size * .85,
        color: Theme.of(context).colorScheme.primary,
      ),
    );

    if (!_running) return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Center(child: avatar),
    );

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          child: avatar,
          builder: (context, child) {
            final phase = _controller.value * math.pi * 2;
            // Gesto de saludo: balanceo suave y ligero salto.
            final rotation = math.sin(phase) *
                (widget.isTyping ? .075 : .045);
            final lift = (1 - math.cos(phase)) *
                (widget.isTyping ? 2.6 : 1.5);
            final scale = 1.0 + math.sin(phase).abs() *
                (widget.isTyping ? .035 : .012);
            return Transform.translate(
              offset: Offset(0, -lift),
              child: Transform.rotate(
                angle: rotation,
                alignment: Alignment.bottomCenter,
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
