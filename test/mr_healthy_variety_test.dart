import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/mr_healthy_choice_resolver.dart';
import 'package:healthy_habit/páginas/chatbot/mr_healthy_topic_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MrHealthyResponseBank bank;

  setUpAll(() async {
    bank = MrHealthyResponseBank.fromJsonString(
      await rootBundle.loadString('assets/knowledge/mr_healthy_topics_v2.json'),
    );
  });

  test('treinta menús tienen respuestas para todas sus opciones', () {
    expect(MrHealthyChoiceResolver.choices.length, 30);
    for (final item in MrHealthyChoiceResolver.choices.entries) {
      final options = item.value;
      expect(options.length, greaterThanOrEqualTo(2), reason: item.key);
      final responses = MrHealthyChoiceResolver.responses[item.key];
      expect(responses, isNotNull, reason: item.key);
      for (final option in options) {
        expect(responses!.containsKey(option), isTrue,
            reason: '${item.key}/$option');
        expect(responses[option], isNotEmpty);
      }
    }
  });

  test('elige una comida según la lista, no palabras del cuerpo', () {
    final first = bank.answer('Háblame de plato equilibrado')!;
    expect(first.knowledgeId, 'food_plato');
    final second = bank.answer('la segunda',
      previousTopicId: first.knowledgeId,
      previousAssistantText: first.text);
    expect(second?.text, contains('Para la comida'));
  });

  test('varía las recomendaciones al repetir una misma preferencia', () {
    final first = bank.answer('Háblame de desayuno saludable')!;
    final initial = bank.answer('económica',
      previousTopicId: first.knowledgeId,
      previousAssistantText: first.text,
      turnIndex: 0);
    final alternate = bank.answer('económica',
      previousTopicId: first.knowledgeId,
      previousAssistantText: first.text,
      turnIndex: 1);
    expect(initial?.knowledgeId, 'food_desayuno');
    expect(alternate?.knowledgeId, 'food_desayuno');
    expect(initial?.text, isNot(alternate?.text));
    expect(initial?.action, isEmpty);
    expect(alternate?.action, isEmpty);
  });

  test('puede consultar catálogos, progreso y sesiones', () {
    final cases = <({String prompt, String select, String expected})>[
      (prompt: 'Háblame de pantalla principal',
       select: 'progreso', expected: 'En Progreso'),
      (prompt: 'Háblame de registrar hábito',
       select: 'temporizador', expected: 'temporizador'),
      (prompt: 'Háblame de catálogo',
       select: 'ejercicio', expected: 'fichas de actividad'),
      (prompt: 'Háblame de misiones',
       select: 'temporada', expected: 'temporada'),
    ];
    for (final item in cases) {
      final first = bank.answer(item.prompt)!;
      final second = bank.answer(item.select,
        previousTopicId: first.knowledgeId,
        previousAssistantText: first.text);
      expect(second?.text, contains(item.expected), reason: item.prompt);
      expect(second?.action, isEmpty);
    }
  });

  test('movimiento ofrece alternativas diferentes sin equipo', () {
    final first = bank.answer('Háblame de ejercicio sin equipo')!;
    final legs = bank.answer('piernas',
      previousTopicId: first.knowledgeId,
      previousAssistantText: first.text);
    final arms = bank.answer('brazos',
      previousTopicId: first.knowledgeId,
      previousAssistantText: first.text);
    expect(legs?.text, contains('piernas'));
    expect(arms?.text, contains('brazos'));
    expect(legs?.text, isNot(arms?.text));
  });

  test('una pregunta sin menú reciente no elige opciones', () {
    expect(bank.answer('la segunda',
      previousTopicId: 'food_plato',
      previousAssistantText: 'Una comida variada puede incluir verduras.'),
      isNull);
    expect(bank.answer('bicicleta',
      previousTopicId: 'ex_cardio',
      previousAssistantText: 'Hoy leímos sobre Marte.'),
      isNull);
  });

  test('una consulta sensible no entra al selector de preferencias', () {
    final first = bank.answer('Háblame de desayuno saludable')!;
    for (final input in [
      'estoy embarazada, prefiero la segunda',
      'tengo alergia a la leche',
      'dime mi saldo',
      '¿cuántas calorías debo consumir?',
      'comprar accesorios',
    ]) {
      expect(bank.answer(input,
        previousTopicId: first.knowledgeId,
        previousAssistantText: first.text), isNull, reason: input);
    }
  });

  test('cambios de tema no reutilizan el índice anterior', () {
    final breakfast = bank.answer('Háblame de desayuno saludable')!;
    final story = bank.answer('Cuéntame sobre cuento corto',
      previousTopicId: breakfast.knowledgeId,
      previousAssistantText: breakfast.text,
      turnIndex: 3);
    expect(story?.knowledgeId, 'random_historia');
    expect(story?.action, isEmpty);
  });
}
