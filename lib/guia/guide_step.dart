import 'package:flutter/material.dart';

/// Un paso es únicamente información de presentación y ubicación.
/// La guía nunca ejecuta un onPressed de un control de la pantalla.
class HealthySpotlightStep {
  const HealthySpotlightStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.targetKey,
  });

  final String title;
  final String description;
  final IconData icon;
  final GlobalKey? targetKey;
}
