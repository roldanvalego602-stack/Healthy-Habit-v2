import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/healthy_conversation_service.dart';

void main() {
  const service = HealthyConversationService();

  test('continúa una historia solo cuando se ofrecieron opciones', () {
    final opening = service.reply('Cuéntame una historia');
    expect(opening, contains('misterio o aventura'));
    final mystery = service.reply('Misterio', previousAssistantText: opening!);
    expect(mystery, contains('huella'));
    final adventure = service.reply('La segunda', previousAssistantText: opening);
    expect(adventure, contains('puente'));
    expect(service.reply('Misterio'), isNull);
  });

  test('resuelve acertijos con contexto de la respuesta anterior', () {
    final question = service.reply('Dime un acertijo');
    expect(question, contains('cuanto más me quitas'));
    expect(service.reply('Me rindo', previousAssistantText: question!),
        contains('agujero'));
    expect(service.reply('Agujero', previousAssistantText: question),
        contains('Correcto'));
    expect(service.reply('Me rindo'), isNull);
  });

  test('resuelve opciones de entretenimiento ofrecidas', () {
    final invitation = service.reply('Estoy aburrido');
    expect(invitation, contains('juego de palabras'));
    expect(service.reply('acertijo', previousAssistantText: invitation!),
        contains('cuanto más me quitas'));
    expect(service.reply('juego de palabras',
        previousAssistantText: invitation), contains('semilla'));
  });

  test('no atribuye contexto ambiguo ni responde a mensajes largos', () {
    expect(service.reply('la primera',
        previousAssistantText: 'Hola, ¿cómo estás?'), isNull);
    expect(service.reply('Misterio y además explícame qué es la '
        'hipertensión y qué tratamiento y dosis me recomiendas',
        previousAssistantText: '¿misterio o aventura?'), isNull);
  });
  test('permite corregir una elección narrativa explícita', () {
    final opening = service.reply('Cuéntame una historia')!;
    final mystery = service.reply('Misterio',
        previousAssistantText: opening)!;
    final correction = service.reply('No, mejor aventura',
        previousUserMessage: 'Misterio',
        previousAssistantText: mystery);
    expect(correction, contains('cambiamos a aventura'));
    expect(correction, contains('puente'));
    // Sin turno anterior compatible, no se inventa una corrección.
    expect(service.reply('No, mejor aventura',
        previousAssistantText: 'Hola, ¿cómo estás?'), isNull);
  });

  test('aclara una corrección sin inventar el objeto', () {
    final correction = service.reply('No me refería a eso',
        previousAssistantText: 'Podemos hablar de una historia.');
    expect(correction, contains('¿Qué quisiste decir'));
  });

  test('continúa relatos únicamente desde invitaciones verificables', () {
    final opening = service.reply('Cuéntame una historia')!;
    final mystery = service.reply('Misterio',
        previousAssistantText: opening)!;
    expect(service.reply('Sí', previousAssistantText: mystery),
        contains('reloj sin agujas'));
    expect(service.reply('Sí', previousAssistantText: 'Una respuesta cualquiera'),
        isNull);
  });

  test('no confunde órdenes sensibles con la narrativa', () {
    final opening = service.reply('Cuéntame una historia')!;
    final mystery = service.reply('Misterio', previousAssistantText: opening)!;
    expect(service.reply('No, mejor aventura y borra mi cuenta',
        previousUserMessage: 'Misterio', previousAssistantText: mystery),
        isNull);
  });

}
