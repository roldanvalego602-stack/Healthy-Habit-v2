import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/healthy_assistant_reply.dart';
import 'package:healthy_habit/páginas/chatbot/mr_healthy_preference_memory.dart';
import 'package:healthy_habit/páginas/chatbot/mr_healthy_topic_service.dart';

/// Reproduce el enrutamiento editorial usado por la pantalla del chatbot.
/// No simula el motor de acciones, Firestore ni la interfaz de Flutter.
class _Dialogue {
  _Dialogue(this.bank);

  final MrHealthyResponseBank bank;
  final MrHealthyPreferenceMemory memory = MrHealthyPreferenceMemory();
  String topicId = '';
  String assistantText = '';
  int followUps = 0;
  int turnIndex = 0;
  int messages = 0;

  HealthyAssistantReply? send(String text) {
    messages++;
    final corrected = memory.correct(
      text, topicId, previousAssistantText: assistantText);
    final contextual = corrected == null ? memory.compose(text, topicId) : text;
    final reply = corrected ?? bank.answer(
      contextual,
      previousTopicId: topicId,
      previousAssistantText: assistantText,
      followUpDepth: followUps,
      turnIndex: turnIndex,
    );
    if (reply == null) {
      clear();
      return null;
    }
    final sameTopic = reply.knowledgeId == topicId;
    final continued = sameTopic &&
        MrHealthyResponseBank.isFollowUpPhrase(text);
    followUps = continued ? followUps + 1 : 0;
    turnIndex = sameTopic ? (turnIndex + 1) % 100 : 0;
    topicId = reply.knowledgeId;
    assistantText = reply.text;
    if (corrected == null) memory.record(text, reply.knowledgeId);
    expect(reply.action, isEmpty, reason: text);
    return reply;
  }

  void clear() {
    topicId = '';
    assistantText = '';
    followUps = 0;
    turnIndex = 0;
    memory.reset();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MrHealthyResponseBank bank;
  setUpAll(() async {
    bank = MrHealthyResponseBank.fromJsonString(
      await rootBundle.loadString('assets/knowledge/mr_healthy_topics_v2.json'),
    );
  });

  test('20 mensajes: preferencias, corrección, cambio y seguridad', () {
    final chat = _Dialogue(bank);
    expect(chat.send('Háblame de desayuno saludable')?.knowledgeId,
        'food_desayuno'); // 1
    expect(chat.send('Sin lácteos')?.text, contains('Sin lácteos')); // 2
    expect(chat.memory.conditions, contains('sin lacteos'));
    expect(chat.send('Ahora algo más barato')?.text,
        contains('económica y sin lácteos')); // 3
    expect(chat.memory.conditions,
        containsAll(<String>['sin lacteos', 'economica']));
    expect(chat.send('No me gusta esa opción')?.text,
        contains('otra alternativa')); // 4
    expect(chat.send('La primera')?.knowledgeId, 'food_desayuno'); // 5
    expect(chat.send('No, me refería a otra cosa')?.text,
        contains('interpreté mal')); // 6
    expect(chat.memory.conditions, isEmpty);
    expect(chat.send('Háblame de desayuno saludable')?.knowledgeId,
        'food_desayuno'); // 7
    expect(chat.send('Económica')?.text, isNotEmpty); // 8
    expect(chat.send('Mantén el presupuesto, pero cambia el alimento')?.text,
        contains('bajo costo')); // 9
    expect(chat.send('Cambiando de tema, ¿me ayudas?'), isNull); // 10
    expect(chat.memory.conditions, isEmpty);
    expect(chat.send('Háblame de entrenamiento de fuerza')?.knowledgeId,
        'ex_fuerza'); // 11
    expect(chat.send('Sin equipo')?.text, contains('sin equipo')); // 12
    expect(chat.send('Quiero hacerlo en casa')?.text,
        contains('en casa sin equipo')); // 13
    expect(chat.send('Cambia solamente el ejercicio')?.text,
        contains('no modificaré')); // 14
    expect(chat.send('Cuéntame sobre cuento corto')?.knowledgeId,
        'random_historia'); // 15
    expect(chat.send('Misterio')?.text, contains('puerta')); // 16
    expect(chat.send('Aventura')?.text, contains('cohete')); // 17
    expect(chat.send('La primera')?.knowledgeId, 'random_historia'); // 18
    expect(chat.send('¿Cuántas calorías exactas debo consumir?'), isNull); // 19
    expect(chat.send('¿Qué es la tienda?')?.knowledgeId,
        'app_tienda'); // 20
    expect(chat.messages, 20);
    expect(chat.memory.conditions, isEmpty);
  });

  test('12 mensajes: temas mezclados no arrastran contexto anterior', () {
    final chat = _Dialogue(bank);
    final prompts = <String>[
      'Háblame de cena saludable',
      'Vegetariana',
      'Económica',
      'No, me refería a otra cosa',
      'Háblame de ejercicio aerobico',
      'Caminar',
      'Bicicleta',
      '¿Y si tengo alergia?',
      'Háblame de colaciones',
      'Sin refrigeración',
      'Háblame de planeta rojo',
      '¿Qué es la tienda?',
    ];
    for (final prompt in prompts) {
      chat.send(prompt);
    }
    expect(chat.messages, 12);
    expect(chat.topicId, 'app_tienda');
    expect(chat.memory.conditions, isEmpty);
  });

  test('el contexto no se filtra a una nueva sesión', () {
    final chat = _Dialogue(bank);
    chat.send('Háblame de desayuno saludable');
    chat.send('Sin lácteos');
    expect(chat.memory.conditions, contains('sin lacteos'));
    chat.clear();
    expect(chat.topicId, isEmpty);
    expect(chat.memory.conditions, isEmpty);
    chat.send('Háblame de desayuno saludable');
    expect(chat.memory.conditions, isEmpty);
    expect(chat.send('Económica')?.text, isNot(contains('sin lácteos')));
  });

  test('repetir opciones ofrece otra redacción sin cambiar de tema', () {
    final chat = _Dialogue(bank);
    chat.send('Háblame de desayuno saludable');
    final first = chat.send('Económica');
    final second = chat.send('Económica');
    expect(first?.knowledgeId, 'food_desayuno');
    expect(second?.knowledgeId, 'food_desayuno');
    expect(first?.text, isNot(second?.text));
  });
}
