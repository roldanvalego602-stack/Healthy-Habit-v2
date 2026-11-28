import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/healthy_guided_dialogue.dart';
import 'package:healthy_habit/páginas/chatbot/healthy_clarification_service.dart';

void main() {
  test('mantiene una comparación durante tres turnos explícitos', () {
    final first = HealthyClarificationService.respond(
      '¿Cuál es mejor?');
    expect(first, contains('¿Qué alternativas estás considerando?'));

    final second = HealthyGuidedDialogue.reply(
      'Caminar y bicicleta', previousAssistantText: first);
    expect(second, contains('Caminar y bicicleta'));
    expect(second, contains('¿Qué criterio quieres priorizar'));

    final third = HealthyGuidedDialogue.reply(
      'Tiempo',
      previousUserMessage: 'Caminar y bicicleta',
      previousAssistantText: second!,
    );
    expect(third, contains('criterio: tiempo'));
    expect(third, contains('traslado'));
    expect(third, contains('No puedo decidir'));
  });

  test('si falta información no elige ni inventa cifras', () {
    const previous = 'Comparación guiada de A y B. '
        '¿Tienes un dato concreto de ambas opciones para compararlas?';
    expect(HealthyGuidedDialogue.reply('No tengo',
      previousAssistantText: previous), contains('no sería fiable'));
  });

  test('opciones ambiguas requieren nombres concretos', () {
    final first = HealthyClarificationService.respond('¿Cuál es mejor?');
    expect(HealthyGuidedDialogue.reply('No sé',
      previousAssistantText: first), contains('dos alternativas'));
    expect(HealthyGuidedDialogue.reply('la otra',
      previousAssistantText: first), contains('separadas por'));
  });

  test('no hereda una conversación sin invitación verificable', () {
    expect(HealthyGuidedDialogue.reply('A y B',
      previousAssistantText: 'Hola, ¿en qué te ayudo?'), isNull);
    expect(HealthyGuidedDialogue.reply('Costo',
      previousUserMessage: 'A y B',
      previousAssistantText: 'No tengo una pregunta pendiente.'), isNull);
  });

  test('no reinterpreta operaciones ni datos sensibles', () {
    final first = HealthyClarificationService.respond('¿Cuál es mejor?');
    for (final input in [
      'borrar mi cuenta y confirmar',
      'medicamento y dosis',
      'comprar y eliminar',
    ]) {
      expect(HealthyGuidedDialogue.reply(input,
        previousAssistantText: first), isNull, reason: input);
    }
  });

  test('reconoce los cuatro criterios y exige datos', () {
    const previous = 'Alternativas anotadas: Avena y Cereal. '
        '¿Qué criterio quieres priorizar: costo, tiempo, facilidad '
        'o beneficio? No asumiré precios ni resultados.';
    for (final criterion in ['Costo', 'Tiempo', 'Facilidad', 'Beneficio']) {
      final answer = HealthyGuidedDialogue.reply(
        criterion,
        previousUserMessage: 'Avena y Cereal',
        previousAssistantText: previous,
      );
      expect(answer, contains('No puedo decidir'), reason: criterion);
    }
  });
  test('construye un plan orientativo de meta sin registrar acciones', () {
    final opening = HealthyGuidedDialogue.reply(
      'Ayúdame a planear una meta',
      previousAssistantText: 'Hola, ¿en qué te ayudo?',
    );
    expect(opening, contains('¿Qué meta concreta'));

    final goal = HealthyGuidedDialogue.reply(
      'Ordenar mi escritorio', previousAssistantText: opening!);
    expect(goal, contains('¿En qué plazo quieres intentarla'));

    final plan = HealthyGuidedDialogue.reply(
      'Esta semana',
      previousUserMessage: 'Ordenar mi escritorio',
      previousAssistantText: goal!,
    );
    expect(plan, contains('Plan orientativo'));
    expect(plan, contains('No he programado recordatorios'));

    final action = HealthyGuidedDialogue.reply(
      'Separar los libros',
      previousUserMessage: 'Esta semana',
      previousAssistantText: plan!,
    );
    expect(action, contains('Primer paso anotado'));
    expect(action, contains('No he modificado tus hábitos'));
  });

  test('rechaza metas sensibles o ambiguas sin guardar nada', () {
    final opening = HealthyGuidedDialogue.reply(
      'Quiero organizar una meta')!;
    expect(HealthyGuidedDialogue.reply('dosis de insulina',
        previousAssistantText: opening), isNull);
    expect(HealthyGuidedDialogue.reply('No sé',
        previousAssistantText: opening), contains('meta específica'));
    expect(HealthyGuidedDialogue.reply('Hoy',
        previousAssistantText: 'Hola'), isNull);
  });

  test('un plazo no reconocido requiere una opción clara', () {
    const prior = 'Meta propuesta: ordenar libros. '
        '¿En qué plazo quieres intentarla: hoy, esta semana o este mes?';
    expect(HealthyGuidedDialogue.reply('Algún día',
      previousAssistantText: prior,
      previousUserMessage: 'ordenar libros',
    ), contains('Elige un plazo sencillo'));
  });

}
