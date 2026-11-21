import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/habitos/habit_popularity_service.dart';

void main() {
  group('Popularidad pública verificada', () {
    test('acepta únicamente conteos verificados y positivos', () {
      final score = HabitPopularity.fromMap('alim_001', {
        'activeUsers': 24,
        'verified': true,
      });
      expect(score, isNotNull);
      expect(score!.habitId, 'alim_001');
      expect(score.activeUsers, 24);
    });

    test('no muestra cifras sin verificar o inexistentes', () {
      expect(HabitPopularity.fromMap('alim_001',
          {'activeUsers': 10, 'verified': false}), isNull);
      expect(HabitPopularity.fromMap('alim_001',
          {'activeUsers': 0, 'verified': true}), isNull);
      expect(HabitPopularity.fromMap('alim_001',
          {'activeUsers': -1, 'verified': true}), isNull);
      expect(HabitPopularity.fromMap('alim_001',
          {'verified': true}), isNull);
      expect(HabitPopularity.fromMap('alim_001',
          {'activeUsers': 3.5, 'verified': true}), isNull);
      expect(HabitPopularity.fromMap('alim_001',
          {'activeUsers': '100', 'verified': true}), isNull);
    });
  });
}
