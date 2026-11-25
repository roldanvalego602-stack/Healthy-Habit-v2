import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/servicios/habit_reminder_policy.dart';

void main() {
  bool pending({
    String status = 'inProgress',
    String frequency = 'daily',
    int progress = 0,
    int target = 10,
    int requiredToday = 1,
    int registeredToday = 0,
  }) => HabitReminderPolicy.pendingDaily(
    status: status, frequency: frequency, progress: progress,
    target: target, requiredToday: requiredToday,
    registeredToday: registeredToday,
  );

  test('un hábito diario activo sin registro queda pendiente', () {
    expect(pending(), isTrue);
  });
  test('haber registrado el objetivo diario evita el aviso', () {
    expect(pending(registeredToday: 1), isFalse);
    expect(pending(requiredToday: 2, registeredToday: 1), isTrue);
    expect(pending(requiredToday: 2, registeredToday: 2), isFalse);
  });
  test('un hábito terminado, cancelado o semanal no se anuncia', () {
    expect(pending(status: 'completed'), isFalse);
    expect(pending(status: 'cancelled'), isFalse);
    expect(pending(frequency: 'weekly'), isFalse);
    expect(pending(progress: 10), isFalse);
  });
  test('objetivos inválidos no se anuncian', () {
    expect(pending(target: 0), isFalse);
    expect(pending(requiredToday: 0), isFalse);
  });
}
