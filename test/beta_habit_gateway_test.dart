import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/servicios/beta_habit_gateway.dart';

void main() {
  test('beta deshabilitada por defecto', () {
    expect(BetaHabitGateway.enabled, isFalse);
  });

  test('la clave de reintento separa acciones y evita doble activación', () {
    final activate = PendingBetaHabitOperations.keyFor(
      uid: 'usuarioA', action: 'activar', habitId: 'alim_001',
      attemptId: '',
    );
    final register = PendingBetaHabitOperations.keyFor(
      uid: 'usuarioA', action: 'registrar', habitId: 'alim_001',
      attemptId: 'attempt_123456789',
    );
    expect(activate, 'hh_beta_pending_v1_usuarioA_activar_alim_001_nueva');
    expect(register,
        'hh_beta_pending_v1_usuarioA_registrar_alim_001_attempt_123456789');
    expect(activate, isNot(register));
  });

  test('no admite IDs arbitrarios ni acciones de economía ajenas', () {
    expect(
      () => PendingBetaHabitOperations.keyFor(
        uid: 'usuarioA', action: 'premiar', habitId: 'alim_001',
        attemptId: 'attempt_123456789',
      ),
      throwsArgumentError,
    );
    expect(
      () => PendingBetaHabitOperations.keyFor(
        uid: 'usuarioA', action: 'registrar', habitId: '../../system',
        attemptId: 'attempt_123456789',
      ),
      throwsArgumentError,
    );
    expect(
      () => PendingBetaHabitOperations.keyFor(
        uid: 'usuarioA', action: 'cancelar', habitId: 'alim_001',
        attemptId: 'corto',
      ),
      throwsArgumentError,
    );
  });
}
