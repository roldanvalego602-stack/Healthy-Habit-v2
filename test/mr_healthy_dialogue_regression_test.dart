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

  test('preguntas cotidianas de cinco dominios recuperan el tema correcto', () {
    const cases = <String, String>{
      'Me interesa tema cosmos': 'app_cosmos',
      '¿Qué es tienda?': 'app_tienda',
      'Explícame armario': 'app_armario',
      'Quiero aprender sobre el historial del chat': 'app_historial',
      'Necesito información de evidencia fotográfica': 'app_evidencia',
      '¿Qué sabes de desayuno saludable?': 'food_desayuno',
      'Háblame de proteínas': 'food_proteina',
      'Cuéntame sobre comida casera': 'food_almuerzo',
      '¿Qué es tamaño de porción?': 'food_porciones',
      '¿Qué sabes de proteína sin carne?': 'food_vegetariana',
      'Explícame entrenamiento de fuerza': 'ex_fuerza',
      '¿Qué sabes de salir a caminar?': 'ex_caminar',
      'Quiero saber de ejercicios en casa': 'ex_casa',
      'Me interesa movilidad articular': 'ex_movilidad',
      'Háblame de bebidas energéticas': 'risk_energetica',
      '¿Qué sabes de grasas saturadas?': 'risk_grasa',
      'Necesito información de comida ultraprocesada': 'risk_ultraprocesados',
      'Cuéntame sobre alimento con moho': 'risk_moho',
      '¿Qué es planeta rojo?': 'random_marte',
      'Cuéntame sobre fases lunares': 'random_luna',
      'Me interesa adivinanza': 'random_adivinanza',
    };
    for (final entry in cases.entries) {
      final reply = bank.answer(entry.key);
      expect(reply?.knowledgeId, entry.value, reason: entry.key);
      expect(reply?.action, isEmpty, reason: entry.key);
    }
  });

  test('reconoce artículos naturales en preguntas frecuentes', () {
    expect(bank.answer('¿Qué es la tienda?')?.knowledgeId, 'app_tienda');
    expect(bank.answer('¿Qué es el planeta rojo?')?.knowledgeId,
        'random_marte');
    expect(bank.answer('¿Qué sabes de una caminata?')?.knowledgeId,
        'ex_caminar');
    expect(bank.answer('Cuéntame sobre las fases lunares')?.knowledgeId,
        'random_luna');
  });

  test('seguimiento retiene tema y ofrece detalle diferente', () {
    final first = bank.answer('Háblame de desayuno saludable');
    expect(first?.knowledgeId, 'food_desayuno');
    final second = bank.answer('Dame un ejemplo',
        previousTopicId: first!.knowledgeId);
    expect(second?.knowledgeId, 'food_desayuno');
    expect(second?.text, isNot(equals(first.text)));
    expect(second?.text, contains('avena'));

    final third = bank.answer('¿Y si no tengo mucho dinero?',
        previousTopicId: first.knowledgeId, followUpDepth: 1);
    expect(third?.knowledgeId, 'food_desayuno');
    expect(third?.text, contains('Seguimos hablando'));
    expect(bank.answer('Dime más',
      previousTopicId: first.knowledgeId, followUpDepth: 3), isNull);
  });

  test('nuevo tema explícito prevalece sobre historial', () {
    expect(bank.answer('Cambiando de tema, ¿me ayudas?',
        previousTopicId: 'food_desayuno'), isNull);
    expect(bank.answer('Háblame de bebidas energéticas',
        previousTopicId: 'food_desayuno')?.knowledgeId, 'risk_energetica');
  });

  test('consultas clínicas y privadas nunca se responden desde el banco', () {
    for (final question in <String>[
      '¿Y si estoy embarazada?',
      '¿Qué hago si tengo diabetes?',
      '¿Y si tengo una alergia?',
      '¿Qué dosis exacta debo tomar?',
      '¿Cómo me curo una enfermedad?',
      '¿Qué pasa si me intoxiqué con comida?',
      '¿Cuál es mi contraseña?',
      '¿Qué es mi saldo en el banco?',
      '¿Cuántas calorías debo comer?',
    ]) {
      expect(bank.answer(question, previousTopicId: 'food_desayuno'),
          isNull, reason: question);
    }
  });

  test('órdenes y preguntas ambiguas no son operaciones disfrazadas', () {
    for (final question in <String>[
      'Comprar accesorios',
      'Eliminar cuenta',
      'Activar hábito',
      'Cancela mi compra',
      'Lo de ayer no me sirvió',
      '¿Qué debo hacer con mi información privada?',
    ]) {
      expect(bank.answer(question), isNull, reason: question);
    }
  });
}
