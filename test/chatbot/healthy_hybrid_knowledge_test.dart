import 'package:flutter_test/flutter_test.dart';

import '../../lib/páginas/chatbot/healthy_assistant_engine.dart';
import '../../lib/páginas/chatbot/healthy_hybrid_knowledge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final hybrid = HealthyHybridKnowledge();
  late HealthyKnowledgeIndex index;

  setUpAll(() async {
    index = await hybrid.load(); // Asset real declarado en pubspec.yaml.
  });

  test('dataset local tiene IDs únicos y fuentes estructuradas', () {
    expect(index.cards.length, greaterThanOrEqualTo(15));
    expect(index.cards.map((card) => card.id).toSet().length,
        index.cards.length);
    expect(index.cards.every((card) =>
        card.title.isNotEmpty && card.answer.isNotEmpty &&
        card.sourceName.isNotEmpty), isTrue);
  });

  test('tolera tildes y formas alternativas de una pregunta', () {
    expect(index.search('¿Qué alimentos me dan más fibra?')?.card.id, 'fibra');
    expect(index.search('Háblame de las hojuelas de avena')?.card.id, 'avena');
    expect(index.search('Quiero mejorar mi hidratación')?.card.id, 'hidratacion');
  });

  test('las palabras aisladas no relacionadas no generan respuestas', () {
    expect(index.search('¿Cuál es el origen de Saturno?'), isNull);
    expect(index.looksEducational('¿Qué película ganó premios?'), isFalse);
  });

  test('la consulta educativa devuelve respuesta y fuente local', () async {
    final answer = await hybrid.answer('¿Qué es la avena?',
        operational: const HealthyAssistantReply(''));
    expect(answer, isNotNull);
    expect(answer!.text, contains('Avena:'));
    expect(answer.text, contains('Referencia para consultar:'));
    expect(answer.card, 'knowledge');
    expect(answer.action, 'source');
    expect(answer.actionArgument, startsWith('https://'));
  });

  test('nunca inventa calorías ni gramos por porción', () async {
    final answer = await hybrid.answer('¿Cuántas calorías tiene la avena?',
        operational: const HealthyAssistantReply(''));
    expect(answer!.text, contains('no daré una cifra inventada'));
    expect(answer.text, isNot(contains(' kcal por ')));
  });

  test('las operaciones del perfil tienen prioridad sobre el dataset', () async {
    final operational = const HealthyAssistantEngine().resolve(
      '¿Cuántas Habit Coins tengo?',
      profile: {'name': 'Ana', 'xp': 40, 'habitCoins': 125},
      habits: [],
    );
    expect(operational.action, 'profile');
    final educational = await hybrid.answer('¿Cuántas Habit Coins tengo?',
        operational: operational);
    expect(educational, isNull);
  });

  test('ninguna ficha educativa genera órdenes de compra', () async {
    final answer = await hybrid.answer('¿Por qué caminar es bueno?',
        operational: const HealthyAssistantReply(''));
    expect(answer?.action, isNot('shop'));
    expect(answer?.action, isNot('habits'));
    expect(answer?.action, isNot('edit_profile'));
  });

  test('el motor funcional conserva confirmaciones para hábitos', () {
    final operational = const HealthyAssistantEngine().resolve(
      'Quiero agregar un hábito',
      profile: {'name': 'Ana', 'xp': 40, 'habitCoins': 125},
      habits: [],
    );
    expect(operational.action, 'habits');
    expect(operational.card, 'habit_add');
  });

  test('rechaza versiones desconocidas del dataset', () {
    expect(() => HealthyKnowledgeIndex.fromJsonString(
      '{"schemaVersion":2,"language":"es","entries":[]}'),
      throwsFormatException,
    );
  });
}
