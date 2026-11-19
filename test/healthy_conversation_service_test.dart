import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/healthy_conversation_service.dart';

void main() {
  const service = HealthyConversationService();

  test('responde a preguntas imaginativas sin fingir identidad real', () {
    final result = service.reply('¿Soy una princesa?')!;
    expect(result, contains('cuento'));
    expect(result, contains('comprobar'));
  });

  test('presenta su identidad sin simular ser humano', () {
    final result = service.reply('Háblame sobre ti')!;
    expect(result, contains('Mr. Healthy'));
    expect(result, contains('programa'));
  });

  test('reconoce varias formas de conversación cotidiana', () {
    final questions = [
      '¿Cómo estás?',
      '¿Eres un robot?',
      'Estoy feliz',
      'Estoy aburrida',
      'Cuéntame un cuento',
      'Dime un acertijo',
      '¿Qué piensas de mí?',
      '¿Cuál es tu color favorito?',
      'Dime algo curioso',
      '¿Qué no puedes hacer?',
      'Me ayudas a decidir',
      'No lo sé',
      'Era broma',
      'Te quiero',
    ];
    for (final question in questions) {
      expect(service.reply(question), isNotNull, reason: question);
    }
  });

  test('puede seguir el contexto reciente del acertijo', () {
    final answer = service.reply('Me rindo',
        previousUserMessage: 'Dime un acertijo');
    expect(answer, contains('agujero'));
  });

  test('conserva contexto de chiste para peticiones breves', () {
    final answer = service.reply('Otro chiste',
        previousUserMessage: 'Cuéntame un chiste');
    expect(answer, contains('tomate'));
  });

  test('no absorbe preguntas que deben manejar servicios verificables', () {
    expect(service.reply('¿Cuántas monedas tengo?'), isNull);
    expect(service.reply('Agregar el hábito de caminar'), isNull);
    expect(service.reply('¿Qué calorías tiene la avena?'), isNull);
    expect(service.reply('¿Cómo está el clima hoy?'), isNull);
  });
}
