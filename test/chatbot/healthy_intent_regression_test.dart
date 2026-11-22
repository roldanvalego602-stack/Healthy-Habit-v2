import 'package:flutter_test/flutter_test.dart';

import '../../lib/páginas/chatbot/healthy_assistant_engine.dart';
import '../../lib/páginas/chatbot/healthy_hybrid_knowledge.dart';
import '../../lib/páginas/chatbot/healthy_intent_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final engine = const HealthyAssistantEngine();
  final knowledge = HealthyHybridKnowledge();

  setUpAll(() async => knowledge.load());

  HealthyAssistantReply resolve(String input) => engine.resolve(input,
    profile: const {'name': 'Ana', 'habitCoins': 135, 'xp': 40},
    habits: const [],
  );

  group('Consultas de saldo y operaciones seguras', () {
    for (final input in [
      '¿Cuántas Habit Coins tengo?',
      '¿Cuántas monedas tengo?',
      '¿Cuántos monedas tengo?',
      '¿Qué saldo tengo?',
      '¿Cuánto dinero me queda?',
      'Dime mis monedas',
    ]) {
      test('saldo: $input', () {
        expect(HealthyIntentRouter.asksForCoinBalance(input), isTrue);
        final reply = resolve(input);
        expect(reply.action, 'profile');
        expect(reply.text, contains('135 Habit Coins'));
      });
    }

    for (final input in [
      'Quiero borrar mi cuenta',
      'Eliminar mi perfil',
      'Quiero cerrar mi cuenta',
      '¿Cómo doy de baja mi cuenta?',
    ]) {
      test('eliminación de cuenta, nunca de hábito: $input', () {
        final reply = resolve(input);
        expect(reply.action, isNot('habits'));
        expect(reply.card, isNot('habit_remove'));
        expect(reply.text, contains('deshabilitada'));
        expect(reply.text, contains('No he eliminado'));
      });
    }

    test('borrar un hábito sí conserva la confirmación de hábitos', () {
      final reply = resolve('Quiero borrar un hábito');
      expect(reply.action, 'habits');
      expect(reply.card, 'habit_remove');
    });

    test('no confunde precio de tienda con saldo', () {
      expect(HealthyIntentRouter.asksForCoinBalance(
          '¿Cuánto cuesta comprar monedas?'), isFalse);
    });
  });

  group('Recuperación específica y seguimiento del huevo', () {
    test('la pregunta general devuelve la ficha general', () async {
      final reply = await knowledge.answer('¿Qué es el huevo?',
        operational: const HealthyAssistantReply(''));
      expect(reply?.knowledgeId, 'huevo');
    });

    test('preguntar si hace daño devuelve seguridad, no definición', () async {
      final reply = await knowledge.answer('¿El huevo me hace daño?',
        operational: const HealthyAssistantReply(''));
      expect(reply?.knowledgeId, 'huevo_seguridad');
      expect(reply?.text, contains('alergia'));
    });

    test('prepararlo con jamón devuelve una respuesta concreta', () async {
      final question = '¿Puedo preparar el huevo con jamón?';
      final operational = resolve(question);
      expect(operational.action, isEmpty);
      final reply = await knowledge.answer(question, operational: operational);
      expect(reply?.knowledgeId, 'huevo_jamon');
      expect(reply?.text, contains('jamón'));
    });

    test('«y si le pongo jamón» retiene el contexto del huevo', () async {
      final reply = await knowledge.answer('¿Y si le pongo jamón?',
        operational: const HealthyAssistantReply(''),
        lastKnowledgeId: 'huevo');
      expect(reply?.knowledgeId, 'huevo_jamon');
    });

    test('«prepararlo con jamón» comprende un pronombre de seguimiento', () async {
      final reply = await knowledge.answer('¿Puedo prepararlo con jamón?',
        operational: const HealthyAssistantReply(''),
        lastKnowledgeId: 'huevo_seguridad');
      expect(reply?.knowledgeId, 'huevo_jamon');
    });

    test('seguridad del huevo ofrece enlace permitido a la FDA', () async {
      final reply = await knowledge.answer('¿El huevo me hace daño?',
        operational: const HealthyAssistantReply(''));
      expect(reply?.action, 'source');
      expect(reply?.actionArgument, startsWith('https://www.fda.gov/'));
    });

    test('«y si me hace daño» retiene contexto sin repetir ficha', () async {
      final reply = await knowledge.answer('¿Y si me hace daño?',
        operational: const HealthyAssistantReply(''),
        lastKnowledgeId: 'huevo');
      expect(reply?.knowledgeId, 'huevo_seguridad');
    });

    test('«cuántos huevos» explica que no hay límite universal', () async {
      final reply = await knowledge.answer('¿Cuántos huevos puedo comer?',
        operational: const HealthyAssistantReply(''));
      expect(reply?.knowledgeId, 'huevo_frecuencia');
    });

    test('«qué más» propone nuevos aspectos sin repetir el huevo general', () async {
      final reply = await knowledge.answer('¿Qué más?',
        operational: const HealthyAssistantReply(''),
        lastKnowledgeId: 'huevo');
      expect(reply?.knowledgeId, 'huevo');
      expect(reply?.text, contains('tres cosas distintas'));
      expect(reply?.text, contains('jamón'));
    });

    test('tema ajeno no hereda contexto de alimento', () async {
      final reply = await knowledge.answer('¿Qué película me recomiendas?',
        operational: const HealthyAssistantReply(''),
        lastKnowledgeId: 'huevo');
      expect(reply, isNull);
    });
  });
}
