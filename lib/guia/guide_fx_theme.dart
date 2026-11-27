import 'package:flutter/material.dart';
import '../tema/cosmos_theme.dart';
import '../tema/healthy_theme.dart';

/// La guía solo lee el tema equipado; no lo modifica ni desbloquea Cosmos.
@immutable
class GuideFxTheme {
  const GuideFxTheme({
    required this.accent,
    required this.secondary,
    required this.background,
    required this.cosmos,
  });

  final Color accent;
  final Color secondary;
  final Color background;
  final bool cosmos;

  static GuideFxTheme fromAppearance({
    required bool cosmos,
    required bool dark,
    required bool christmas,
  }) {
    if (cosmos) {
      return const GuideFxTheme(
        accent: CosmosPalette.cyan,
        secondary: CosmosPalette.secondary,
        background: CosmosPalette.surface,
        cosmos: true,
      );
    }
    if (christmas) {
      return GuideFxTheme(
        accent: dark ? const Color(0xFF75D9AE) : const Color(0xFF087B58),
        secondary: const Color(0xFFFFD98E),
        background: dark ? const Color(0xFF1C302B) : Colors.white,
        cosmos: false,
      );
    }
    return GuideFxTheme(
      accent: dark ? const Color(0xFF6CD3A1) : const Color(0xFF078765),
      secondary: dark ? const Color(0xFF8CC9FC) : const Color(0xFF2F91B5),
      background: dark ? const Color(0xFF1B2935) : Colors.white,
      cosmos: false,
    );
  }

  static GuideFxTheme current() => fromAppearance(
    cosmos: HealthyAdaptive.isCosmos,
    dark: HealthyAdaptive.isDark,
    christmas: HealthyAdaptive.isChristmas,
  );
}
