import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/niveles/levels_system.dart';

void main() {
  group('Sistema de niveles de Healthy Habit', () {
    test('empieza en nivel 1 con cero XP', () {
      expect(LevelSystem.fromXp(0).number, 1);
      expect(LevelSystem.fromXp(-10).number, 1);
    });

    test('cambia de nivel al alcanzar el umbral', () {
      expect(LevelSystem.fromXp(99).number, 1);
      expect(LevelSystem.fromXp(100).number, 2);
      expect(LevelSystem.fromXp(249).number, 2);
      expect(LevelSystem.fromXp(250).number, 3);
    });

    test('calcula XP restantes al siguiente nivel', () {
      expect(LevelSystem.remainingXp(0), 100);
      expect(LevelSystem.remainingXp(99), 1);
      expect(LevelSystem.remainingXp(100), 150);
    });

    test('calcula progreso dentro del nivel', () {
      expect(LevelSystem.progress(0), 0.0);
      expect(LevelSystem.progress(50), 0.5);
      expect(LevelSystem.progress(100), 0.0);
      expect(LevelSystem.progress(175), 0.5);
    });

    test('ultimo nivel no tiene nivel siguiente', () {
      expect(LevelSystem.fromXp(10500).number, 20);
      expect(LevelSystem.nextLevel(10500), isNull);
      expect(LevelSystem.remainingXp(10500), 0);
      expect(LevelSystem.progress(10500), 1.0);
    });
  });
}
