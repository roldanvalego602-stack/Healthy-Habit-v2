import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/habitos/habit_action_service.dart';

void main() {
  group('Reglas compartidas de acciones de hábitos', () {
    final free = HabitActionService.findCatalogHabit('alim_001');
    final medium = HabitActionService.findCatalogHabit('alim_002');
    test('identifica hábitos exclusivamente del catálogo oficial', () {
      expect(free, isNotNull);
      expect(free!.title, 'Incluir una fruta');
      expect(
        HabitActionService.findCatalogHabit('Incluir una fruta')?.id,
        'alim_001',
      );
      expect(HabitActionService.findCatalogHabit('habito_inventado'), isNull);
    });

    test('mantiene desbloqueos por dificultad y nivel', () {
      expect(HabitActionService.isUnlocked(free!,
          xp: 0, coins: 0, activeIds: <String>{}), isTrue);
      // No se supone que todos los hábitos sean accesibles desde el nivel 1.
      final locked = HabitActionService.findCatalogHabit('alim_007');
      if (locked != null && locked.unlockType == 'level') {
        expect(HabitActionService.isUnlocked(locked,
            xp: 0, coins: 0, activeIds: <String>{}),
            locked.requiredLevel == 1);
      }
    });

    test('penaliza únicamente los hábitos difíciles', () {
      expect(HabitActionService.cancellationFee(free!, 300), 0);
      final difficult = HabitActionService.findCatalogHabit('alim_009');
      if (difficult != null &&
          HabitActionService.isDifficult(difficult)) {
        expect(HabitActionService.cancellationFee(difficult, 100), 25);
        expect(HabitActionService.cancellationFee(difficult, 12), 12);
        expect(HabitActionService.cancellationFee(difficult, 0), 0);
      }
    });

    test('no declara un costo de abandono para hábitos sencillos', () {
      expect(HabitActionService.isDifficult(medium!), isFalse);
      expect(HabitActionService.cancellationFee(medium, 5), 0);
    });
  });
}
