import 'package:flutter/material.dart';

/// Catálogo visual de títulos. El estado de festival solo se desbloquea
/// mediante insignias emitidas por el servidor, no por la interfaz.
class HealthyProfileTitle {
  const HealthyProfileTitle(this.id, this.name, this.description, this.icon,
      {this.minLevel = 1, this.badgeId});
  final String id, name, description;
  final IconData icon;
  final int minLevel;
  final String? badgeId;

  bool available(int level, Set<String> verifiedBadges) =>
      level >= minLevel && (badgeId == null || verifiedBadges.contains(badgeId));
}

class HealthyProfileTitles {
  HealthyProfileTitles._();

  static const catalog = <HealthyProfileTitle>[
    HealthyProfileTitle('novato', 'Semilla saludable',
        'Tu primer título al comenzar.', Icons.spa_rounded),
    HealthyProfileTitle('cultivador', 'Cultivador de constancia',
        'Alcanza el nivel 3.', Icons.eco_rounded, minLevel: 3),
    HealthyProfileTitle('explorador', 'Explorador del bienestar',
        'Alcanza el nivel 5.', Icons.explore_rounded, minLevel: 5),
    HealthyProfileTitle('veterano', 'Leyenda saludable',
        'Alcanza el nivel 10.', Icons.military_tech_rounded, minLevel: 10),
    HealthyProfileTitle('primera_meta', 'Primer paso cumplido',
        'Desbloquea el logro Primera meta en el servidor.',
        Icons.verified_rounded, badgeId: 'primera_meta'),
    HealthyProfileTitle('racha_siete', 'Guardián de la constancia',
        'Consigue una racha oficial de 7 días.',
        Icons.local_fire_department_rounded, badgeId: 'racha_7'),
    HealthyProfileTitle('festival', 'Espíritu del festival',
        'Premio exclusivo de un festival oficial.',
        Icons.celebration_rounded, badgeId: 'festival_participant_2026'),
    HealthyProfileTitle('temporada', 'Campeón de temporada',
        'Participación premiada en una temporada oficial.',
        Icons.workspace_premium_rounded, badgeId: 'season_champion_01'),
  ];

  static HealthyProfileTitle? byName(String name) {
    for (final entry in catalog) {
      if (entry.name == name) return entry;
    }
    return null;
  }

  static String visibleTitle(
      String? selected, int level, Set<String> verifiedBadges) {
    final title = byName(selected ?? '');
    if (title != null && title.available(level, verifiedBadges)) {
      return title.name;
    }
    return catalog.first.name;
  }
}
