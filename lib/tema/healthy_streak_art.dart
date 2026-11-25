import 'package:flutter/material.dart';

import '../servicios/daily_streak_display.dart';

/// Recursos ilustrados oficiales de Mr. Healthy.
/// Los PNG fueron añadidos por el equipo en protectores_racha/.
enum HealthyStreakArtState {
  inactive,
  active,
  atRisk,
  protected,
  lost,
  legendary,
  recovered,
  protectionConsumed,
}

class HealthyStreakArt {
  HealthyStreakArt._();

  static const String _base = 'assets/gamificacion/protectores_racha/';

  static const Map<HealthyStreakArtState, String> paths = {
    HealthyStreakArtState.inactive:
        '${_base}Mascota Saludable Sin Racha.png',
    HealthyStreakArtState.active:
        '${_base}¡Mr. Healthy en llamas!.png',
    HealthyStreakArtState.atRisk:
        '${_base}Mr. Healthy en riesgo.png',
    HealthyStreakArtState.protected:
        '${_base}Frutita Saludable Bajo Protección.png',
    HealthyStreakArtState.lost:
        '${_base}Mr. Healthy en Racha Perdida.png',
    HealthyStreakArtState.legendary:
        '${_base}Mr. Healthy_ Racha legendaria.png',
    HealthyStreakArtState.recovered:
        '${_base}healthy recuperado.png',
    HealthyStreakArtState.protectionConsumed:
        '${_base}healthy escudo roto.png',
  };

  /// El calendario alternativo queda como recurso para material educativo.
  static const String inactiveCalendar =
      '${_base}Frutita Sin Racha con Calendario.png';

  /// Clasificación visual conservadora: sin inventar protectores o riesgos.
  /// La racha numérica permanece bajo DailyStreakDisplay.
  static HealthyStreakArtState fromProfile(Map<String, dynamic> profile,
      {DateTime? now}) {
    final count = DailyStreakDisplay.current(profile, now: now);
    if (count >= 30) return HealthyStreakArtState.legendary;
    if (count > 0) return HealthyStreakArtState.active;
    final history = DailyStreakDisplay.longest(profile);
    return history > 0
        ? HealthyStreakArtState.lost
        : HealthyStreakArtState.inactive;
  }

  static String label(HealthyStreakArtState state) {
    switch (state) {
      case HealthyStreakArtState.inactive: return 'Sin racha';
      case HealthyStreakArtState.active: return 'Racha activa';
      case HealthyStreakArtState.atRisk: return 'Racha en riesgo';
      case HealthyStreakArtState.protected: return 'Racha protegida';
      case HealthyStreakArtState.lost: return 'Racha interrumpida';
      case HealthyStreakArtState.legendary: return 'Racha legendaria';
      case HealthyStreakArtState.recovered: return 'Racha recuperada';
      case HealthyStreakArtState.protectionConsumed:
        return 'Protección consumida';
    }
  }
}

/// Widget reutilizable. Las ilustraciones no alteran estados ni recompensas.
class HealthyStreakMascot extends StatelessWidget {
  const HealthyStreakMascot({
    super.key, required this.state, this.size = 96,
  });

  final HealthyStreakArtState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      HealthyStreakArt.paths[state]!,
      key: ValueKey('healthy-streak-art-${state.name}'),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: HealthyStreakArt.label(state),
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: size, height: size,
        child: Icon(Icons.local_fire_department_rounded,
            size: size * 0.55,
            color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
