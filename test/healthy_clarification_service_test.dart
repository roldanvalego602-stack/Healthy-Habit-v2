import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/healthy_clarification_service.dart';
import 'package:healthy_habit/páginas/chatbot/nutri_respuestas_service.dart';

void main() {
  test('una pregunta ambigua solicita el referente exacto', () {
    expect(HealthyClarificationService.respond('el otro'),
        contains('por su nombre'));
  });

  test('las preguntas sobre datos recientes no se inventan', () {
    final response = HealthyClarificationService.respond(
        '¿Cuál es la última noticia sobre la misión?');
    expect(response, contains('podría cambiar'));
    expect(response, contains('Wikipedia'));
    expect(response, isNot(contains('noticias en vivo')));
  });

  test('una comparación solicita opciones y criterios', () {
    expect(HealthyClarificationService.respond(
        '¿Cuál es mejor entre estas opciones?'), contains('alternativas'));
  });

  test('una respuesta breve conserva la petición de aclaración', () {
    final response = HealthyClarificationService.respond(
      'Una explicación',
      previousAssistantText: '¿Quieres una definición, una idea práctica '
          'o ayuda con alguna función de Healthy Habit?',
    );
    expect(response, contains('¿Sobre qué tema'));
  });

  test('las preguntas sanitarias no generan diagnósticos', () {
    final response = HealthyClarificationService.respond(
        'Me duele mucho la cabeza y no sé qué hacer');
    expect(response, contains('No puedo determinar una causa'));
    expect(response, contains('atención médica'));
  });

  test('las preguntas conceptuales sin ficha piden un término', () {
    final response = HealthyClarificationService.respond(
        '¿Qué significa una palabra desconocida?');
    expect(response, contains('concepto exacto'));
  });

  test('el fallback es estable sin inventar datos', () {
    final service = NutriRespuestasService();
    final first = service.responder('Explica el protocolo imaginario ZX-92',
        nombre: '', perfil: const {});
    final second = service.responder('Explica el protocolo imaginario ZX-92',
        nombre: '', perfil: const {});
    expect(first, second);
    expect(first, contains('información suficiente'));
  });

  test('mantiene las respuestas conocidas y la identidad del asistente', () {
    final service = NutriRespuestasService();
    expect(service.responder('¿Quién eres?', nombre: '', perfil: const {}),
        contains('Soy Mr. Healthy'));
    expect(service.responder('¿Qué hora es?', nombre: '', perfil: const {}),
        contains('hora local'));
  });
}
