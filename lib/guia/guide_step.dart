import 'package:flutter/material.dart';
import 'guide_gesture.dart';

/// Un paso es únicamente información de presentación y ubicación.
/// La guía nunca ejecuta un onPressed de un control de la pantalla.
class HealthySpotlightStep {
  const HealthySpotlightStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.targetKey,
    this.extract = false,
    this.gesture,
  });

  final String title;
  final String description;
  final IconData icon;
  final GlobalKey? targetKey;
  /// Captura visual temporal; nunca habilita los botones originales.
  final bool extract;
  /// Gesto opcional. Si se omite, el motor escoge uno según el paso.
  final HealthyGuideGesture? gesture;

  HealthyGuideGesture effectiveGesture(int index, int total) {
    if (gesture != null) return gesture!;
    if (index == 0) return HealthyGuideGesture.greet;
    if (extract) return HealthyGuideGesture.inspect;
    if (index == total - 1) return HealthyGuideGesture.farewell;
    return HealthyGuideGesture.point;
  }
}
