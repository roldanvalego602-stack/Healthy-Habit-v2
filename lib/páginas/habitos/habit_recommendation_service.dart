import 'modelo/habit.dart';

/// Resumen privado del historial de un hábito oficial del propio usuario.
/// No modifica XP, monedas ni registros.
class HabitUsageSignal {
  const HabitUsageSignal({
    required this.habitId,
    required this.category,
    required this.registrations,
    this.lastActivity,
  });

  final String habitId;
  final String category;
  final int registrations;
  final DateTime? lastActivity;
}

class HabitRecommendationService {
  const HabitRecommendationService();

  /// Orden determinista: afinidad sustentada en actividad realizada,
  /// hábitos activos y accesibilidad. Nunca presenta estadísticas globales.
  List<Habit> rank({
    required List<Habit> candidates,
    required List<HabitUsageSignal> history,
    required Set<String> activeCategories,
    required bool Function(Habit habit) isUnlocked,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final weights = <String, int>{};
    for (final signal in history) {
      if (signal.registrations <= 0 || signal.category.isEmpty) continue;
      final age = signal.lastActivity == null
          ? null
          : reference.difference(signal.lastActivity!).inDays;
      final recent = age != null && age >= 0 && age <= 14;
      final points = signal.registrations.clamp(1, 12).toInt() +
          (recent ? 6 : 0);
      weights.update(signal.category, (value) => value + points,
          ifAbsent: () => points);
    }
    final ordered = candidates.toList();
    final scores = {
      for (final habit in ordered)
        habit.id: (weights[habit.category] ?? 0) * 10 +
            (activeCategories.contains(habit.category) ? 12 : 0) +
            (isUnlocked(habit) ? 5 : 0),
    };
    ordered.sort((a, b) {
      final score = (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0);
      return score != 0 ? score : a.id.compareTo(b.id);
    });
    return ordered;
  }

  String explanation({
    required List<HabitUsageSignal> history,
    required Set<String> activeCategories,
  }) {
    final totals = <String, int>{};
    for (final item in history) {
      if (item.registrations > 0 && item.category.isNotEmpty) {
        totals.update(item.category, (value) => value + item.registrations,
            ifAbsent: () => item.registrations);
      }
    }
    if (totals.isNotEmpty) {
      final sorted = totals.keys.toList()
        ..sort((a, b) {
          final count = totals[b]!.compareTo(totals[a]!);
          return count != 0 ? count : a.compareTo(b);
        });
      return 'Según tus registros recientes e historial de ${sorted.first.toLowerCase()}, '
          'estas actividades podrían interesarte.';
    }
    if (activeCategories.isNotEmpty) {
      final category = activeCategories.toList()..sort();
      return 'Como tienes un hábito de ${category.first.toLowerCase()} activo, '
          'puedes explorar objetivos relacionados.';
    }
    return 'Empieza a tu ritmo: explora hábitos y elige tu primer objetivo.';
  }
}
