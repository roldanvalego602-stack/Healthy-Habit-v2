import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../tema/healthy_visual_mode.dart';
import '../tienda/healthy_mascot_live.dart';

/// Animación propia del chat, sin sustituir el atuendo actual de la mascota.
class MrHealthyChatAvatar extends StatefulWidget {
  const MrHealthyChatAvatar({super.key, this.size = 52, this.isTyping = false});
  final double size;
  final bool isTyping;

  @override
  State<MrHealthyChatAvatar> createState() => _MrHealthyChatAvatarState();
}

class _MrHealthyChatAvatarState extends State<MrHealthyChatAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _running = false;

  Duration get _duration => widget.isTyping
      ? const Duration(milliseconds: 1450)
      : const Duration(milliseconds: 3200);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    HealthyVisualController.instance.addListener(_updateMode);
  }

  void _updateMode() {
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
    final shouldRun = HealthyVisualEffects.enabled(context) &&
        TickerMode.of(context);
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
    HealthyVisualController.instance.removeListener(_updateMode);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mascot = HealthyMascotLive(size: widget.size);
    if (!_running) return mascot;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: mascot,
        builder: (context, child) {
          final phase = _controller.value * math.pi * 2;
          final tilt = math.sin(phase) * (widget.isTyping ? .07 : .045);
          final lift = (1 - math.cos(phase)) * (widget.isTyping ? 2.5 : 1.4);
          final scale = 1 + math.sin(phase).abs() *
              (widget.isTyping ? .025 : .012);
          return Transform.translate(
            offset: Offset(0, -lift),
            child: Transform.rotate(
              angle: tilt,
              alignment: Alignment.bottomCenter,
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
      ),
    );
  }
}
