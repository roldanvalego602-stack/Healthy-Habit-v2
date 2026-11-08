import 'package:flutter/material.dart';

class HealthyLevel {
  final int number;
  final String name;
  final int requiredXp;
  final int rewardCoins;
  final IconData icon;
  final Color startColor;
  final Color endColor;
  final Color accentColor;
  final bool dark;

  const HealthyLevel({
    required this.number,
    required this.name,
    required this.requiredXp,
    required this.rewardCoins,
    required this.icon,
    required this.startColor,
    required this.endColor,
    required this.accentColor,
    required this.dark,
  });
}

class LevelSystem {
  LevelSystem._();

  static const List<HealthyLevel> levels = [
    HealthyLevel(
      number: 1,
      name: 'Primer paso',
      requiredXp: 0,
      rewardCoins: 0,
      icon: Icons.directions_walk,
      startColor: Color(0xFFFFFFFF),
      endColor: Color(0xFFEAF7F0),
      accentColor: Color(0xFF478F73),
      dark: false,
    ),
    HealthyLevel(
      number: 2,
      name: 'Buen comienzo',
      requiredXp: 100,
      rewardCoins: 25,
      icon: Icons.spa_outlined,
      startColor: Color(0xFFF9FFFC),
      endColor: Color(0xFFE4F5EC),
      accentColor: Color(0xFF478F73),
      dark: false,
    ),
    HealthyLevel(
      number: 3,
      name: 'En marcha',
      requiredXp: 250,
      rewardCoins: 25,
      icon: Icons.trending_up,
      startColor: Color(0xFFF2FFF8),
      endColor: Color(0xFFDDF4E9),
      accentColor: Color(0xFF398D6C),
      dark: false,
    ),
    HealthyLevel(
      number: 4,
      name: 'Explorador',
      requiredXp: 450,
      rewardCoins: 25,
      icon: Icons.explore_outlined,
      startColor: Color(0xFFEDFFF5),
      endColor: Color(0xFFD5F0E3),
      accentColor: Color(0xFF2F8868),
      dark: false,
    ),
    HealthyLevel(
      number: 5,
      name: 'Constante',
      requiredXp: 700,
      rewardCoins: 50,
      icon: Icons.check_circle_outline,
      startColor: Color(0xFFE8FAF1),
      endColor: Color(0xFFC8EEDB),
      accentColor: Color(0xFF238565),
      dark: false,
    ),
    HealthyLevel(
      number: 6,
      name: 'Constructor constante',
      requiredXp: 1000,
      rewardCoins: 50,
      icon: Icons.layers_outlined,
      startColor: Color(0xFFE1F8ED),
      endColor: Color(0xFFBCE9D4),
      accentColor: Color(0xFF238565),
      dark: false,
    ),
    HealthyLevel(
      number: 7,
      name: 'Ritmo firme',
      requiredXp: 1350,
      rewardCoins: 50,
      icon: Icons.monitor_heart_outlined,
      startColor: Color(0xFFDDF6EB),
      endColor: Color(0xFFAFE3CD),
      accentColor: Color(0xFF1F7E60),
      dark: false,
    ),
    HealthyLevel(
      number: 8,
      name: 'Impulso diario',
      requiredXp: 1750,
      rewardCoins: 50,
      icon: Icons.bolt_outlined,
      startColor: Color(0xFFD5F4E7),
      endColor: Color(0xFFA5DFC8),
      accentColor: Color(0xFF18785B),
      dark: false,
    ),
    HealthyLevel(
      number: 9,
      name: 'En crecimiento',
      requiredXp: 2200,
      rewardCoins: 75,
      icon: Icons.show_chart,
      startColor: Color(0xFFF0FAFE),
      endColor: Color(0xFFD8EDF6),
      accentColor: Color(0xFF468AA9),
      dark: false,
    ),
    HealthyLevel(
      number: 10,
      name: 'Persistente',
      requiredXp: 2700,
      rewardCoins: 75,
      icon: Icons.local_fire_department_outlined,
      startColor: Color(0xFFE7F6FD),
      endColor: Color(0xFFC6E5F3),
      accentColor: Color(0xFF367C9F),
      dark: false,
    ),
    HealthyLevel(
      number: 11,
      name: 'Disciplina activa',
      requiredXp: 3250,
      rewardCoins: 75,
      icon: Icons.adjust,
      startColor: Color(0xFF305A70),
      endColor: Color(0xFF173646),
      accentColor: Color(0xFFA7D8ED),
      dark: true,
    ),
    HealthyLevel(
      number: 12,
      name: 'Raíces fuertes',
      requiredXp: 3850,
      rewardCoins: 75,
      icon: Icons.forest_outlined,
      startColor: Color(0xFF295D58),
      endColor: Color(0xFF173E40),
      accentColor: Color(0xFFABE4CE),
      dark: true,
    ),
    HealthyLevel(
      number: 13,
      name: 'Ritmo sólido',
      requiredXp: 4500,
      rewardCoins: 100,
      icon: Icons.waves_outlined,
      startColor: Color(0xFF286251),
      endColor: Color(0xFF123D34),
      accentColor: Color(0xFFB5E9CD),
      dark: true,
    ),
    HealthyLevel(
      number: 14,
      name: 'Dominio diario',
      requiredXp: 5200,
      rewardCoins: 100,
      icon: Icons.wb_sunny_outlined,
      startColor: Color(0xFF205A48),
      endColor: Color(0xFF10382D),
      accentColor: Color(0xFFBDE9CB),
      dark: true,
    ),
    HealthyLevel(
      number: 15,
      name: 'Constancia superior',
      requiredXp: 5950,
      rewardCoins: 100,
      icon: Icons.military_tech_outlined,
      startColor: Color(0xFF235B49),
      endColor: Color(0xFF10362E),
      accentColor: Color(0xFFE9D58A),
      dark: true,
    ),
    HealthyLevel(
      number: 16,
      name: 'Maestro del hábito',
      requiredXp: 6750,
      rewardCoins: 100,
      icon: Icons.workspace_premium_outlined,
      startColor: Color(0xFF1C5141),
      endColor: Color(0xFF0B3028),
      accentColor: Color(0xFFF1D88A),
      dark: true,
    ),
    HealthyLevel(
      number: 17,
      name: 'Constructor experto',
      requiredXp: 7600,
      rewardCoins: 150,
      icon: Icons.diamond_outlined,
      startColor: Color(0xFF2C4965),
      endColor: Color(0xFF182A42),
      accentColor: Color(0xFFB8E0F4),
      dark: true,
    ),
    HealthyLevel(
      number: 18,
      name: 'Progreso imparable',
      requiredXp: 8500,
      rewardCoins: 150,
      icon: Icons.rocket_launch_outlined,
      startColor: Color(0xFF293E5B),
      endColor: Color(0xFF17243C),
      accentColor: Color(0xFFB9E8D4),
      dark: true,
    ),
    HealthyLevel(
      number: 19,
      name: 'Leyenda constante',
      requiredXp: 9500,
      rewardCoins: 150,
      icon: Icons.auto_awesome_outlined,
      startColor: Color(0xFF44345E),
      endColor: Color(0xFF211B39),
      accentColor: Color(0xFFDCC5F5),
      dark: true,
    ),
    HealthyLevel(
      number: 20,
      name: 'Maestro del progreso',
      requiredXp: 10500,
      rewardCoins: 300,
      icon: Icons.emoji_events_outlined,
      startColor: Color(0xFF344957),
      endColor: Color(0xFF192B36),
      accentColor: Color(0xFFF4D989),
      dark: true,
    ),
  ];

  static HealthyLevel fromXp(int xp) {
    final safeXp = xp < 0 ? 0 : xp;
    for (final level in levels.reversed) {
      if (safeXp >= level.requiredXp) return level;
    }
    return levels.first;
  }

  static HealthyLevel? nextLevel(int xp) {
    for (final level in levels) {
      if (level.requiredXp > xp) return level;
    }
    return null;
  }

  static int remainingXp(int xp) {
    final next = nextLevel(xp);
    if (next == null) return 0;
    return next.requiredXp - xp.clamp(0, next.requiredXp);
  }

  static double progress(int xp) {
    final current = fromXp(xp);
    final next = nextLevel(xp);

    if (next == null) return 1.0;

    final range = next.requiredXp - current.requiredXp;
    if (range <= 0) return 1.0;

    return ((xp - current.requiredXp) / range).clamp(0.0, 1.0);
  }
}
