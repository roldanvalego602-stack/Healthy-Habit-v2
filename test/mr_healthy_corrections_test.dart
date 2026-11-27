import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/mr_healthy_preference_memory.dart';

void main() {
  test('preserva presupuesto y cambia solo la sugerencia alimentaria', () {
    final memory = MrHealthyPreferenceMemory();
    memory.record('prefiero un desayuno económico', 'food_desayuno');
    final answer = memory.correct(
      'Mantén el presupuesto, pero cambia el alimento',
      'food_desayuno',
      previousAssistantText: 'Prueba avena con fruta.');
    expect(answer?.knowledgeId, 'food_desayuno');
    expect(answer?.text, contains('bajo costo'));
    expect(answer?.text, contains('huevo bien cocido'));
    expect(memory.conditions, contains('economica'));
    expect(answer?.action, isEmpty);
  });

  test('no atribuye un presupuesto que nunca se mencionó', () {
    final memory = MrHealthyPreferenceMemory();
    memory.record('sin lácteos', 'food_desayuno');
    final answer = memory.correct(
      'Mantén el presupuesto y cambia la comida', 'food_desayuno');
    expect(answer?.text, contains('necesito saber'));
    expect(memory.conditions, contains('sin lacteos'));
    expect(memory.conditions, isNot(contains('economica')));
  });

  test('respeta sin lácteos cuando conserva el presupuesto', () {
    final memory = MrHealthyPreferenceMemory();
    memory.record('económico y sin lácteos', 'food_desayuno');
    final answer = memory.correct(
      'Mantén el presupuesto, cambia el alimento',
      'food_desayuno',
      previousAssistantText: 'Avena con fruta.');
    expect(answer?.text, contains('sin lácteos'));
    expect(answer?.action, isEmpty);
  });

  test('puede cambiar solo el ejercicio sin alterar preferencias', () {
    final memory = MrHealthyPreferenceMemory();
    memory.record('sin equipo', 'ex_fuerza');
    final answer = memory.correct('Cambia solamente el ejercicio', 'ex_fuerza');
    expect(answer?.text, contains('no modificaré tus hábitos registrados'));
    expect(answer?.text, contains('no usar equipo'));
    expect(memory.conditions, contains('sin equipo'));
    expect(answer?.action, isEmpty);
  });

  test('ante una corrección abierta solicita aclaración y limpia supuestos', () {
    final memory = MrHealthyPreferenceMemory();
    memory.record('económico', 'food_desayuno');
    final answer = memory.correct('No, me refería a otra cosa', 'food_desayuno');
    expect(answer?.text, contains('¿Qué parte interpreté mal'));
    expect(memory.conditions, isEmpty);
    expect(answer?.action, isEmpty);
  });

  test('no traslada preferencias de un tema a otro', () {
    final memory = MrHealthyPreferenceMemory();
    memory.record('económico', 'food_desayuno');
    expect(memory.correct('Mantén presupuesto y cambia alimento',
      'food_cena'), isNull);
    expect(memory.correct('Cambia solamente el ejercicio',
      'ex_fuerza'), isNull);
  });

  test('no responde como corrector ante acciones o asuntos clínicos', () {
    final memory = MrHealthyPreferenceMemory();
    memory.record('económico', 'food_desayuno');
    for (final message in <String>[
      'eliminar cuenta',
      'comprar accesorios',
      'estoy embarazada y cambia la comida',
      'tengo alergia y quiero otro alimento',
      '¿cuántas calorías debo consumir?',
    ]) {
      expect(memory.correct(message, 'food_desayuno'), isNull,
        reason: message);
    }
  });

  test('las correcciones no generan compras, registros ni saldos', () {
    final memory = MrHealthyPreferenceMemory();
    memory.record('económico', 'food_cena');
    final response = memory.correct(
      'Conserva el presupuesto, cambia el platillo',
      'food_cena',
    );
    expect(response?.action, isEmpty);
    expect(response?.card, 'topic');
    expect(response?.actionArgument, 'food_cena');
  });
}
