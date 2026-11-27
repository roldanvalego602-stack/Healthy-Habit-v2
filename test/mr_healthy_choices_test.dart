import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/mr_healthy_topic_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MrHealthyResponseBank bank;

  setUpAll(() async {
    final raw = await rootBundle.loadString(
      'assets/knowledge/mr_healthy_topics_v2.json',
    );
    bank = MrHealthyResponseBank.fromJsonString(raw);
  });

  test('elige la segunda propuesta efectivamente ofrecida', () {
    final initial = bank.answer('Háblame de desayuno saludable')!;
    final next = bank.answer('la segunda',
      previousTopicId: initial.knowledgeId,
      previousAssistantText: initial.text);
    expect(next?.knowledgeId, 'food_desayuno');
    expect(next?.text, contains('económico'));
    expect(next?.action, isEmpty);
  });

  test('interpreta restricciones de preferencia en el mismo hilo', () {
    final initial = bank.answer('Háblame de desayuno saludable')!;
    final noMilk = bank.answer('prefiero sin lácteos',
      previousTopicId: initial.knowledgeId,
      previousAssistantText: initial.text);
    expect(noMilk?.text, contains('Sin lácteos'));

    final cheap = bank.answer('prefiero algo barato',
      previousTopicId: initial.knowledgeId,
      previousAssistantText: initial.text);
    expect(cheap?.text, contains('económico'));
  });

  test('permite rechazar una opción sin asumir la alternativa', () {
    final initial = bank.answer('Háblame de desayuno saludable')!;
    final second = bank.answer('la segunda',
      previousTopicId: initial.knowledgeId,
      previousAssistantText: initial.text)!;
    final rejected = bank.answer('no me gusta esa opción',
      previousTopicId: second.knowledgeId,
      previousAssistantText: second.text);
    expect(rejected?.text, contains('otra alternativa'));
    expect(rejected?.action, isEmpty);
  });

  test('historias ofrecen ramas diferentes', () {
    final initial = bank.answer('Cuéntame sobre un cuento corto')!;
    final mystery = bank.answer('misterio',
      previousTopicId: initial.knowledgeId,
      previousAssistantText: initial.text);
    final adventure = bank.answer('aventura',
      previousTopicId: initial.knowledgeId,
      previousAssistantText: initial.text);
    expect(mystery?.text, contains('puerta'));
    expect(adventure?.text, contains('cohete'));
    expect(mystery?.text, isNot(adventure?.text));
  });

  test('no elige una opción nunca ofrecida', () {
    final initial = bank.answer('Háblame de desayuno saludable')!;
    expect(bank.answer('la segunda',
      previousTopicId: initial.knowledgeId,
      previousAssistantText: ''), isNull);
    expect(bank.answer('la segunda',
      previousTopicId: initial.knowledgeId,
      previousAssistantText: 'Hola, ¿qué tal?'), isNull);
  });

  test('no mezcla temas ni ejecuta compras', () {
    final initial = bank.answer('¿Qué es la tienda?')!;
    final answer = bank.answer('tema',
      previousTopicId: initial.knowledgeId,
      previousAssistantText: initial.text);
    expect(answer?.knowledgeId, 'app_tienda');
    expect(answer?.action, isEmpty);
    expect(bank.answer('la segunda',
      previousTopicId: 'food_desayuno',
      previousAssistantText: 'Solo hablamos de Marte.'), isNull);
  });

  test('preguntas médicas y consultas de saldo mantienen prioridad', () {
    final initial = bank.answer('Háblame de desayuno saludable')!;
    for (final question in [
      'estoy embarazada, la segunda',
      'tengo alergia a la leche',
      '¿cuántas calorías exactas debo consumir?',
      '¿cuál es mi saldo?',
    ]) {
      expect(bank.answer(question,
        previousTopicId: initial.knowledgeId,
        previousAssistantText: initial.text), isNull, reason: question);
    }
  });

  test('contexto breve sigue siendo opcional', () {
    final initial = bank.answer('Háblame de desayuno saludable');
    final follow = bank.answer('Dame un ejemplo',
        previousTopicId: initial!.knowledgeId);
    expect(follow?.knowledgeId, 'food_desayuno');
    expect(follow?.text, contains('avena'));
  });
}
