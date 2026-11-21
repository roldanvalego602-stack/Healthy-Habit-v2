import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/habitos/personal_routines_screen.dart';

void main() {
  group('Rutinas personales', () {
    const exercise = PersonalRoutineStep(
      title: 'Sentadillas',
      type: 'counter',
      target: 12,
      unit: 'repeticiones',
    );
    const rest = PersonalRoutineStep(
      title: 'Descanso',
      type: 'timer',
      target: 45,
      unit: 'segundos',
    );

    test('serializa una rutina con contador y temporizador', () {
      const routine = PersonalRoutine(
        id: 'routine-1',
        title: 'Piernas',
        steps: [exercise, rest],
      );
      final decoded = PersonalRoutine.fromJson(routine.toJson());
      expect(decoded.id, 'routine-1');
      expect(decoded.title, 'Piernas');
      expect(decoded.steps, hasLength(2));
      expect(decoded.steps[0].type, 'counter');
      expect(decoded.steps[0].target, 12);
      expect(decoded.steps[1].type, 'timer');
      expect(decoded.steps[1].target, 45);
      expect(decoded.completedSessions, 0);
      expect(decoded.toJson().containsKey('xp'), isFalse);
      expect(decoded.toJson().containsKey('habitCoins'), isFalse);
    });

    test('incrementa sesiones sin crear recompensas', () {
      const routine = PersonalRoutine(
        id: 'routine-2',
        title: 'Hidratación personal',
        steps: [exercise],
      );
      final next = routine.copyWith(completedSessions: 1);
      expect(routine.completedSessions, 0);
      expect(next.completedSessions, 1);
      expect(next.toJson().containsKey('xpEarned'), isFalse);
    });

    test('edita rutinas sin perder identificador ni sesiones', () {
      const routine = PersonalRoutine(
        id: 'routine-3',
        title: 'Piernas',
        steps: [exercise],
        completedSessions: 4,
      );
      final edited = routine.copyWith(
        title: 'Piernas y descanso',
        steps: [exercise, rest],
      );
      expect(edited.id, 'routine-3');
      expect(edited.title, 'Piernas y descanso');
      expect(edited.steps, hasLength(2));
      expect(edited.completedSessions, 4);
      expect(routine.steps, hasLength(1));
      expect(edited.toJson().containsKey('habitCoins'), isFalse);
    });

    test('permite metas personales en mililitros sin XP', () {
      const goal = PersonalRoutine(
        id: 'water-1',
        title: 'Beber 2 litros',
        steps: [
          PersonalRoutineStep(
            title: 'Agua diaria',
            type: 'counter',
            target: 2000,
            unit: 'ml',
          ),
        ],
      );
      final decoded = PersonalRoutine.fromJson(goal.toJson());
      expect(decoded.steps.single.target, 2000);
      expect(decoded.steps.single.unit, 'ml');
      expect(decoded.toJson().containsKey('xp'), isFalse);
    });

    test('registra metas diarias por fecha sin duplicar progreso', () {
      const goal = PersonalRoutine(
        id: 'water-daily',
        title: 'Agua diaria',
        steps: [
          PersonalRoutineStep(
            title: 'Tomar agua',
            type: 'counter',
            target: 2000,
            unit: 'ml',
          ),
        ],
        dailyGoal: true,
        completedSessions: 2,
        completedDays: ['2026-11-18', '2026-11-19'],
      );
      expect(goal.completedOn(DateTime(2026, 11, 19)), isTrue);
      expect(goal.completedOn(DateTime(2026, 11, 20)), isFalse);
      final restored = PersonalRoutine.fromJson(goal.toJson());
      expect(restored.dailyGoal, isTrue);
      expect(restored.completedDays, hasLength(2));
      expect(restored.completedOn(DateTime(2026, 11, 19)), isTrue);
      expect(restored.toJson().containsKey('xp'), isFalse);
    });

    test('serializa el borrador del paso pendiente', () {
      const draft = PersonalRoutineDraft(
        date: '2026-11-20',
        stepIndex: 2,
        stepValue: 250,
      );
      final restored = PersonalRoutineDraft.fromJson(draft.toJson());
      expect(restored.date, '2026-11-20');
      expect(restored.stepIndex, 2);
      expect(restored.stepValue, 250);
      expect(restored.toJson().containsKey('habitCoins'), isFalse);
    });

    test('acepta rutinas antiguas sin historial diario', () {
      final oldData = <String, dynamic>{
        'id': 'legacy',
        'title': 'Mi rutina',
        'steps': [
          {'title': 'Caminar', 'type': 'timer', 'target': 300, 'unit': 'segundos'},
        ],
        'completedSessions': 3,
      };
      final restored = PersonalRoutine.fromJson(oldData);
      expect(restored.completedSessions, 3);
      expect(restored.dailyGoal, isFalse);
      expect(restored.completedDays, isEmpty);
    });

    test('normaliza herramientas y metas desconocidas', () {
      final step = PersonalRoutineStep.fromJson({
        'title': 'Actividad',
        'type': 'unknown',
        'target': -2,
        'unit': 'veces',
      });
      expect(step.type, 'counter');
      expect(step.target, 1);
    });
  });
}
