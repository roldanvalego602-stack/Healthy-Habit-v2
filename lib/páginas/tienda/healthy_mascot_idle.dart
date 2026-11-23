import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../tema/healthy_visual_mode.dart';

/// Pose de reposo calculada con funciones periódicas suaves.
/// En 0 y 1 coincide exactamente con la postura original.
@immutable
class HealthyIdlePose {
  const HealthyIdlePose({
    required this.angle,
    required this.lift,
    required this.scaleY,
  });

  final double angle;
  final double lift;
  final double scaleY;

  static HealthyIdlePose at(double progress) {
    final phase = progress * math.pi * 2;
    // Balanceo lateral de ±1.3° sin deformación horizontal.
    final angle = math.sin(phase) * (1.3 * math.pi / 180);
    // Respiración discreta: se eleva hasta 2 px, regresa al suelo
    // y conserva exactamente la postura al cerrar el ciclo.
    final breath = (1 - math.cos(phase)) / 2;
    return HealthyIdlePose(
      angle: angle,
      lift: -2.0 * breath,
      scaleY: 1.0 + 0.006 * breath,
    );
  }
}

/// Anima el conjunto completo (mascota + skin + cosméticos).
/// No altera la composición interna de HealthyMascotOutfit ni su tamaño.
///
/// Se detiene en modo Lite, al desactivar las animaciones de la app,
/// al solicitar menos movimiento en el sistema y al salir del escenario.
class HealthyMascotIdle extends StatefulWidget {
  const HealthyMascotIdle({
    super.key,
    required this.child,
    this.active = true,
  });

  final Widget child;
  final bool active;

  @override
  State<HealthyMascotIdle> createState() => _HealthyMascotIdleState();
}

class _HealthyMascotIdleState extends State<HealthyMascotIdle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    HealthyVisualController.instance.addListener(_syncAnimation);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Las preferencias y MediaQuery son dependencias de este contexto.
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant HealthyMascotIdle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _syncAnimation();
  }

  void _syncAnimation() {
    if (!mounted) return;
    final shouldPlay = widget.active &&
        TickerMode.of(context) &&
        HealthyVisualEffects.enabled(context);
    if (shouldPlay == _playing) return;
    _playing = shouldPlay;
    if (shouldPlay) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    HealthyVisualController.instance.removeListener(_syncAnimation);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Consultar la preferencia aquí permite reaccionar a cambios de Scope.
    final enabled = widget.active && HealthyVisualEffects.enabled(context);
    if (!enabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final pose = HealthyIdlePose.at(_controller.value);
        return Transform.translate(
          offset: Offset(0, pose.lift),
          child: Transform.rotate(
            angle: pose.angle,
            alignment: Alignment.bottomCenter,
            child: Transform.scale(
              scaleY: pose.scaleY,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
