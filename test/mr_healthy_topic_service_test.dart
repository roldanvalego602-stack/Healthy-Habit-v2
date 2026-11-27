import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/mr_healthy_topic_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MrHealthyResponseBank bank;

  setUpAll(() async {
    final raw = await rootBundle.loadString(
      'assets/knowledge/mr_healthy_topics_v2.json');
    bank = MrHealthyResponseBank.fromJsonString(raw);
  });

  test('115 temas y al menos diez mil formulaciones distintas', () {
    expect(bank.topics.length, 115);
    expect(bank.recognizedPhrasings, greaterThanOrEqualTo(10000));
    expect(bank.topics.map((x) => x.id).toSet().length, bank.topics.length);
    for (final topic in bank.topics) {
      expect(topic.terms.length, greaterThanOrEqualTo(4));
      expect(topic.answer.trim(), isNotEmpty);
      expect(topic.followUp.endsWith('?'), isTrue);
    }
  });

  test('entender preguntas reales de las cinco categorías', () {
    const prompts = <String, String>{
      '¿Cómo funciona el tema cosmos?': 'app_cosmos',
      '¿Qué sabes de etiqueta nutricional?': 'food_etiqueta',
      'Explícame entrenamiento de fuerza': 'ex_fuerza',
      '¿Qué me puedes decir de bebidas energéticas?': 'risk_energetica',
      'Cuéntame sobre el planeta rojo': 'random_marte',
    };
    for (final entry in prompts.entries) {
      final answer = bank.answer(entry.key);
      expect(answer?.knowledgeId, entry.value, reason: entry.key);
      expect(answer?.text, isNotEmpty);
      expect(answer?.action, isEmpty);
    }
  });

  test('puede seguir una pregunta sobre el mismo tema hasta tres veces', () {
    final first = bank.answer('Háblame de bebidas energéticas');
    expect(first?.knowledgeId, 'risk_energetica');
    final follow = bank.answer('¿Qué más?',
      previousTopicId: first!.knowledgeId);
    expect(follow?.text, contains('bebida deportiva'));
    final again = bank.answer('Explícame más',
      previousTopicId: first.knowledgeId, followUpDepth: 2);
    expect(again?.knowledgeId, first.knowledgeId);
    expect(bank.answer('¿Y después?',
      previousTopicId: first.knowledgeId, followUpDepth: 3), isNull);
  });

  test('mantiene el contexto en respuestas elípticas', () {
    final main = bank.answer('Háblame de bebidas energéticas');
    final continued = bank.answer('¿Y si la tomo en la noche?',
      previousTopicId: main!.knowledgeId);
    expect(continued?.knowledgeId, 'risk_energetica');
    expect(continued?.text, contains('Seguimos hablando'));
    final choice = bank.answer('Una económica',
      previousTopicId: 'food_desayuno');
    expect(choice?.text, contains('avena'));
  });

  test('no inventa recomendaciones clínicas ni cantidades exactas', () {
    for (final input in [
      '¿Cuántas calorías tiene la avena por porción?',
      '¿Qué dosis exacta debo tomar de vitaminas?',
      'Tengo alergia alimentaria y me cuesta respirar',
      '¿Cómo debo curarme la diabetes?',
    ]) {
      expect(bank.answer(input), isNull, reason: input);
    }
  });

  test('no interpreta operaciones como preguntas educativas', () {
    for (final input in [
      'comprar accesorios',
      'eliminar cuenta',
      'agregar hábito',
      'cancelar actividad diaria',
    ]) {
      expect(bank.answer(input), isNull, reason: input);
    }
  });

  test('preguntas ambiguas no obligan a inventar una respuesta', () {
    expect(bank.answer('¿Qué opinas de eso que vimos ayer?'), isNull);
    expect(bank.answer('¿Cuánto debería comer para bajar 10 kilos?'), isNull);
    expect(bank.answer('¿Cuál es mi contraseña?'), isNull);
  });

  test('el servicio no concede acciones ni pagos', () {
    final answer = bank.answer('¿Qué es Habit Coins?');
    expect(answer?.action, isEmpty);
    expect(answer?.card, 'topic');
    expect(answer?.actionArgument, 'app_monedas');
    expect(answer?.knowledgeId, 'app_monedas');
  });

  test('rechaza banco corrupto o versión incompatible', () {
    expect(() => MrHealthyResponseBank.fromJsonString(
      '{"schemaVersion":99,"language":"es","entries":[]}'),
      throwsFormatException);
  });
}
