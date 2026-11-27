import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/mr_healthy_topic_service.dart';
import 'package:healthy_habit/páginas/chatbot/mr_healthy_choice_resolver.dart';
import 'package:healthy_habit/páginas/chatbot/healthy_assistant_reply.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MrHealthyResponseBank bank;

  setUpAll(() async {
    bank = MrHealthyResponseBank.fromJsonString(
      await rootBundle.loadString('assets/knowledge/mr_healthy_topics_v2.json'),
    );
  });

  HealthyAssistantReply? question(String topic, String input) {
    final prompts = <String, String>{
      'food_desayuno': 'Háblame de desayuno saludable',
      'food_cena': 'Háblame de cena saludable',
      'food_almuerzo': 'Háblame de comida casera',
      'food_fibra': 'Háblame de fibra alimentaria',
      'food_colacion': 'Háblame de colaciones',
      'ex_principiante': 'Háblame de empezar ejercicio',
      'ex_fuerza': 'Háblame de entrenamiento de fuerza',
      'ex_cardio': 'Háblame de ejercicio aerobico',
      'ex_motivacion': 'Háblame de motivacion ejercicio',
    };
    final first = bank.answer(prompts[topic]!)!;
    expect(first.knowledgeId, topic);
    return bank.answer(input,
      previousTopicId: topic,
      previousAssistantText: first.text);
  }

  test('rápido y sin leche no termina ofreciendo yogur', () {
    final reply = question('food_desayuno', 'Quiero algo rápido pero sin leche');
    expect(reply?.knowledgeId, 'food_desayuno');
    expect(reply?.text, contains('rápido y sin lácteos'));
    expect(reply?.text, isNot(contains('yogur')));
    expect(reply?.action, isEmpty);
  });

  test('económico y sin lácteos prioriza ambas condiciones', () {
    final reply = question('food_desayuno',
      'Me gustaría un desayuno económico y sin lácteos');
    expect(reply?.text, contains('económica y sin lácteos'));
    expect(reply?.text, isNot(contains('queso')));
  });

  test('económico y rápido devuelve una alternativa concreta', () {
    final reply = question('food_desayuno',
      'Prefiero algo barato y rápido');
    expect(reply?.text, contains('rápido y económico'));
  });

  test('cena vegetariana de bajo costo', () {
    final reply = question('food_cena',
      'La quiero vegetariana y barata');
    expect(reply?.text, contains('vegetariana y económica'));
    expect(reply?.text, contains('lentejas'));
  });

  test('comida para llevar con poco presupuesto', () {
    final reply = question('food_almuerzo',
      'Para llevar y con poco dinero');
    expect(reply?.text, contains('económica para llevar'));
  });

  test('fibra para llevar y barata', () {
    final reply = question('food_fibra',
      'Algo con fibra económico para llevar');
    expect(reply?.text, contains('bajo costo'));
  });

  test('colación económica sin refrigeración', () {
    final reply = question('food_colacion',
      'Necesito algo barato y sin refrigeración');
    expect(reply?.text, contains('sin refrigeración'));
  });

  test('ejercicio en casa y sin aparatos', () {
    final reply = question('ex_principiante',
      'En casa y sin equipo');
    expect(reply?.text, contains('en casa y sin equipo'));
    expect(reply?.text, contains('caminar en el sitio'));
  });

  test('cardio caminando con poco tiempo', () {
    final reply = question('ex_cardio',
      'Caminar, pero tengo poco tiempo');
    expect(reply?.text, contains('poco tiempo'));
  });

  test('evita combinar preferencias sin contexto ofrecido', () {
    final reply = bank.answer('Rápido pero sin leche',
      previousTopicId: 'food_desayuno',
      previousAssistantText: 'Bienvenido a Healthy Habit.');
    expect(reply, isNull);
  });

  test('negar una opción no la selecciona por accidente', () {
    final reply = question('food_desayuno', 'No quiero algo barato');
    expect(reply?.text, contains('descartar una alternativa'));
    expect(reply?.text, isNot(contains('Para un desayuno económico')));
  });

  test('para llevar no significa necesariamente sin refrigeración', () {
    final reply = question('food_colacion',
        'Algo económico para llevar');
    expect(reply?.text, isNot(contains('sin refrigeración')));
  });

  test('tres restricciones simultáneas piden priorización', () {
    final reply = question('food_desayuno',
        'Quiero algo rápido, económico y sin leche');
    expect(reply?.text, contains('imprescindibles'));
    expect(reply?.action, isEmpty);
  });

  test('elige una sola opción cuando no hay combinación válida', () {
    final reply = question('food_desayuno', 'La económica');
    expect(reply?.text, contains('desayuno económico'));
  });

  test('los comandos y consultas sensibles siguen fuera del selector', () {
    final first = bank.answer('Háblame de desayuno saludable')!;
    for (final input in [
      'tengo alergia a la leche y quiero algo rápido',
      '¿cuántas calorías exactas debo consumir?',
      'activar hábito rápido sin equipo',
      'eliminar cuenta',
    ]) {
      expect(bank.answer(input,
        previousTopicId: first.knowledgeId,
        previousAssistantText: first.text), isNull, reason: input);
    }
  });

  test('todas las combinaciones tienen contenido no vacío', () {
    expect(MrHealthyChoiceResolver.combinedResponses.length,
        greaterThanOrEqualTo(8));
    for (final topic in MrHealthyChoiceResolver.combinedResponses.entries) {
      expect(MrHealthyChoiceResolver.choices.containsKey(topic.key), isTrue);
      for (final item in topic.value.entries) {
        expect(item.key.split('+').length, 2);
        expect(item.value.trim(), isNotEmpty);
      }
    }
  });
}
