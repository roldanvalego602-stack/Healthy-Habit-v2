import 'package:flutter_test/flutter_test.dart';

import '../../lib/páginas/chatbot/healthy_chat_context.dart';

void main() {
  group('Memoria educativa temporal del chat Flutter', () {
    test('recupera huevo para dos seguimientos y luego expira', () {
      final context = HealthyChatContext();
      context.recordEducationalReply(
        input: 'Háblame del huevo',
        knowledgeId: 'huevo',
        previousReference: '',
      );
      final first = context.referenceFor('¿Y si lo preparo con jamón?');
      expect(first, 'huevo');
      context.recordEducationalReply(
        input: '¿Y si lo preparo con jamón?',
        knowledgeId: 'huevo_jamon',
        previousReference: first,
      );
      final second = context.referenceFor('¿Es peligroso comerlo crudo?');
      expect(second, 'huevo_jamon');
      context.recordEducationalReply(
        input: '¿Es peligroso comerlo crudo?',
        knowledgeId: 'huevo_coccion',
        previousReference: second,
      );
      expect(context.referenceFor('¿Y si lo cocino?'), isEmpty);
    });

    test('consultar monedas no hereda alimento', () {
      final context = HealthyChatContext();
      context.recordEducationalReply(
        input: 'Qué es el huevo',
        knowledgeId: 'huevo',
        previousReference: '',
      );
      expect(context.referenceFor('¿Y mis monedas?'), isEmpty);
      expect(context.referenceFor('Quiero borrar mi cuenta'), isEmpty);
    });

    test('se pierde el contexto al abrir conversación nueva', () {
      final context = HealthyChatContext();
      context.recordEducationalReply(
        input: 'Huevo',
        knowledgeId: 'huevo',
        previousReference: '',
      );
      context.reset();
      expect(context.knowledgeId, isEmpty);
      expect(context.referenceFor('¿Y con jamón?'), isEmpty);
    });

    test('órdenes cortas de modificación requieren aclaración', () {
      for (final phrase in [
        'Elimínalo', 'Quítalo', 'Bórralo',
        'Agrégalo', 'Hazlo ya',
      ]) {
        expect(HealthyChatContext.needsActionClarification(phrase), isTrue,
            reason: phrase);
      }
    });

    test('una solicitud explícita de hábito no se bloquea', () {
      expect(
        HealthyChatContext.needsActionClarification(
            'Quiero eliminar el hábito de caminar'),
        isFalse,
      );
      expect(
        HealthyChatContext.needsActionClarification(
            '¿Cuántas Habit Coins tengo?'),
        isFalse,
      );
    });

    test('el tema del catálogo puede conservarse sin historial privado', () {
      final context = HealthyChatContext();
      context.recordEducationalReply(
        input: 'Háblame del huevo',
        knowledgeId: 'huevo',
        previousReference: '',
      );
      expect(context.referenceFor('¿Y si le pongo jamón?'), 'huevo');
    });
  });
}
