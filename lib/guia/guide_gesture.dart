import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Acciones visuales de Mr. Healthy. No modifican controles ni registros.
enum HealthyGuideGesture { greet, present, point, inspect, celebrate, farewell }

@immutable
class HealthyGuideMotion {
  const HealthyGuideMotion({
    required this.lift,
    required this.rotation,
    required this.scale,
    required this.signal,
  });

  final double lift;
  final double rotation;
  final double scale;
  final double signal;

  /// Calcula una pose determinista a partir del tipo de gesto.
  /// phase pertenece a [0, 1) y arrival a [0, 1].
  static HealthyGuideMotion at(
    HealthyGuideGesture gesture,
    double phase,
    double arrival, {
    required bool enabled,
    required double direction,
  }) {
    if (!enabled) {
      return const HealthyGuideMotion(
        lift: 0, rotation: 0, scale: 1, signal: 1);
    }
    final t = phase * math.pi * 2;
    final appear = Curves.easeOutCubic.transform(arrival.clamp(0.0, 1.0));
    final sway = math.sin(t);
    final bob = math.sin(t).abs();
    switch (gesture) {
      case HealthyGuideGesture.greet:
        return HealthyGuideMotion(
          lift: -4 * bob - (1 - appear) * 12,
          rotation: .08 * sway,
          scale: .95 + .05 * appear + .015 * sway,
          signal: .65 + .35 * bob);
      case HealthyGuideGesture.present:
        return HealthyGuideMotion(
          lift: -3 * bob,
          rotation: direction * (.065 + .025 * sway),
          scale: 1 + .013 * sway,
          signal: .75 + .25 * bob);
      case HealthyGuideGesture.point:
        return HealthyGuideMotion(
          lift: -2.5 * bob,
          rotation: direction * (.12 + .02 * sway),
          scale: 1 + .02 * sway,
          signal: .75 + .25 * bob);
      case HealthyGuideGesture.inspect:
        return HealthyGuideMotion(
          lift: -3 * bob,
          rotation: direction * (.11 + .023 * sway),
          scale: 1 + .032 * bob,
          signal: .8 + .2 * bob);
      case HealthyGuideGesture.celebrate:
        return HealthyGuideMotion(
          lift: -5 * bob,
          rotation: .09 * sway,
          scale: 1 + .045 * bob,
          signal: .7 + .3 * bob);
      case HealthyGuideGesture.farewell:
        return HealthyGuideMotion(
          lift: -3 * bob,
          rotation: -.09 * sway,
          scale: 1 - .025 * bob,
          signal: .7 + .3 * bob);
    }
  }
}

extension HealthyGuideGestureDisplay on HealthyGuideGesture {
  IconData get symbol => switch (this) {
    HealthyGuideGesture.greet => Icons.waving_hand_rounded,
    HealthyGuideGesture.present => Icons.auto_awesome_rounded,
    HealthyGuideGesture.point => Icons.arrow_outward_rounded,
    HealthyGuideGesture.inspect => Icons.zoom_in_rounded,
    HealthyGuideGesture.celebrate => Icons.stars_rounded,
    HealthyGuideGesture.farewell => Icons.waving_hand_outlined,
  };

  String get semanticAction => switch (this) {
    HealthyGuideGesture.greet => 'saluda',
    HealthyGuideGesture.present => 'presenta esta sección',
    HealthyGuideGesture.point => 'señala el elemento',
    HealthyGuideGesture.inspect => 'examina el elemento ampliado',
    HealthyGuideGesture.celebrate => 'celebra el avance',
    HealthyGuideGesture.farewell => 'se despide',
  };
}
