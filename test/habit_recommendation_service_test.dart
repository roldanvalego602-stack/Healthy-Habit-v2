import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/habitos/habit_recommendation_service.dart';
import 'package:healthy_habit/páginas/habitos/modelo/habit.dart';

void main() {
  const service = HabitRecommendationService();
  const water = Habit(
    id: 'water', title: 'Agua', category: 'Hidratación',
    difficulty: 'Sencillo', subtitle: '', xp: 10, target: 7,
  );
  const fruit = Habit(
    id: 'fruit', title: 'Fruta', category: 'Alimentación',
    difficulty: 'Sencillo', subtitle: '', xp: 10, target: 7,
  );
  const sleep = Habit(
    id: 'sleep', title: 'Descanso', category: 'Bienestar',
    difficulty: 'Moderado', subtitle: '', xp: 15, target: 7,
  );

  test('prioriza la categoría con registros reales recientes', () {
    final result = service.rank(
      candidates: [sleep, fruit, water],
      history: [
        HabitUsageSignal(
          habitId: 'another-water',
          category: 'Hidratación',
          registrations: 8,
          lastActivity: DateTime(2026, 11, 19),
        ),
      ],
      activeCategories: {},
      isUnlocked: (_) => true,
      now: DateTime(2026, 11, 20),
    );
    expect(result.first.id, 'water');
    expect(result, hasLength(3));
  });

  test('no inventa intereses a partir de cero registros', () {
    const item = HabitUsageSignal(
      habitId: 'hydr',
      category: 'Hidratación',
      registrations: 0,
    );
    expect(service.explanation(
      history: [item], activeCategories: {},
    ), contains('Empieza a tu ritmo'));
    final result = service.rank(
      candidates: [fruit, water],
      history: [item],
      activeCategories: {},
      isUnlocked: (_) => true,
      now: DateTime(2026, 11, 20),
    );
    expect(result.map((habit) => habit.id), ['fruit', 'water']);
  });

  test('conserva como señal secundaria los hábitos activos', () {
    final result = service.rank(
      candidates: [fruit, water],
      history: [],
      activeCategories: {'Hidratación'},
      isUnlocked: (_) => true,
      now: DateTime(2026, 11, 20),
    );
    expect(result.first.id, 'water');
    expect(service.explanation(
      history: [], activeCategories: {'Hidratación'},
    ), contains('hidratación'));
  });

  test('filtra señales sin registros y desempata consistentemente', () {
    final result = service.rank(
      candidates: [sleep, water, fruit],
      history: [
        const HabitUsageSignal(
          habitId: 'bad', category: 'Bienestar', registrations: -4),
      ],
      activeCategories: {},
      isUnlocked: (_) => false,
      now: DateTime(2026, 11, 20),
    );
    expect(result.map((item) => item.id), ['fruit', 'sleep', 'water']);
  });
}
