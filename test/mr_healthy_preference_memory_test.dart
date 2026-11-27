import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/mr_healthy_preference_memory.dart';
import 'package:healthy_habit/páginas/chatbot/mr_healthy_topic_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MrHealthyResponseBank bank;

  setUpAll(() async {
    bank = MrHealthyResponseBank.fromJsonString(
      await rootBundle.loadString('assets/knowledge/mr_healthy_topics_v2.json'),
    );
  });

  test('preserva sin lácteos en la siguiente preferencia económica', () {
    final memory = MrHealthyPreferenceMemory();
    final first = bank.answer('Háblame de desayuno saludable')!;
    final milkFree = bank.answer('sin lácteos',
      previousTopicId: first.knowledgeId,
      previousAssistantText: first.text)!;
    memory.record('sin lácteos', milkFree.knowledgeId);
    final nextQuestion = memory.compose('ahora algo más barato', milkFree.knowledgeId);
    expect(nextQuestion, contains('sin lacteos'));
    final next = bank.answer(nextQuestion,
      previousTopicId: milkFree.knowledgeId,
      previousAssistantText: milkFree.text);
    expect(next?.text, contains('económica y sin lácteos'));
    expect(next?.text, isNot(contains('yogur')));
    expect(next?.action, isEmpty);
    memory.record('ahora algo más barato', next!.knowledgeId);
    expect(memory.conditions, containsAll(['sin lacteos', 'economica']));
  });

  test('conserva ejercicio sin equipo y añade en casa', () {
    final memory = MrHealthyPreferenceMemory();
    final first = bank.answer('Háblame de empezar ejercicio')!;
    final equipment = bank.answer('sin equipo',
      previousTopicId: first.knowledgeId,
      previousAssistantText: first.text);
    // Si no se ofreció explícitamente, no se registra una respuesta inventada.
    expect(equipment, isNull);
    memory.record('sin equipo', first.knowledgeId);
    final question = memory.compose('quiero hacerlo en casa', first.knowledgeId);
    expect(question, contains('sin equipo'));
    final response = bank.answer(question,
      previousTopicId: first.knowledgeId,
      previousAssistantText: first.text);
    expect(response?.text, contains('en casa y sin equipo'));
  });

  test('no mantiene preferencias entre temas diferentes', () {
    final memory = MrHealthyPreferenceMemory();
    memory.record('sin lácteos', 'food_desayuno');
    expect(memory.compose('económica', 'food_cena'), 'económica');
    memory.record('vegetariana', 'food_cena');
    expect(memory.topicId, 'food_cena');
    expect(memory.conditions, {'vegetariana'});
  });

  test('el reinicio descarta todas las restricciones', () {
    final memory = MrHealthyPreferenceMemory();
    memory.record('sin lácteos', 'food_desayuno');
    memory.reset();
    expect(memory.topicId, isEmpty);
    expect(memory.conditions, isEmpty);
    expect(memory.compose('más barato', 'food_desayuno'), 'más barato');
  });

  test('no se añaden datos médicos ni financieros', () {
    final memory = MrHealthyPreferenceMemory();
    memory.record('sin lácteos', 'food_desayuno');
    for (final text in [
      'tengo alergia a la leche y quiero algo barato',
      'tengo diabetes y quiero algo económico',
      'consulta mi saldo',
      'comprar con poco dinero',
    ]) {
      expect(memory.compose(text, 'food_desayuno'), text);
      memory.record(text, 'food_desayuno');
    }
    expect(memory.conditions, {'sin lacteos'});
  });

  test('una negación elimina esa preferencia, no la selecciona', () {
    final memory = MrHealthyPreferenceMemory();
    memory.record('sin lácteos', 'food_desayuno');
    memory.record('ya no quiero sin lácteos', 'food_desayuno');
    expect(memory.conditions, isEmpty);
    expect(memory.compose('más barato', 'food_desayuno'), 'más barato');
  });

  test('no inventa una tercera condición ni combina sin contexto', () {
    final memory = MrHealthyPreferenceMemory();
    memory.record('sin lácteos', 'food_desayuno');
    memory.record('económico', 'food_desayuno');
    expect(memory.compose('rápido', 'food_desayuno'), 'rápido');
    expect(memory.compose('y si tengo alergia', 'food_desayuno'),
      'y si tengo alergia');
  });

  test('puede borrar el contexto explícitamente', () {
    final memory = MrHealthyPreferenceMemory();
    memory.record('sin lácteos', 'food_desayuno');
    memory.record('olvida eso', '');
    expect(memory.conditions, isEmpty);
  });
}
