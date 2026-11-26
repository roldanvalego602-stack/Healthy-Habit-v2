import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/servicios/operaciones_habitos_pendientes.dart';

void main() {
  test('la operación tradicional no exige evidencia', () {
    const item = OperacionHabitoPendiente(
      accion: 'registrar',
      habitoId: 'alim_001',
      intentoId: 'intento_demo_123456789',
    );
    expect(item.conEvidencia, false);
  });

  test('la operación fotográfica distingue el reintento', () {
    const item = OperacionHabitoPendiente(
      accion: 'registrar',
      habitoId: 'alim_001',
      intentoId: 'intento_demo_123456789',
      conEvidencia: true,
    );
    expect(item.conEvidencia, true);
  });
}
