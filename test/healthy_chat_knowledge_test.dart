import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/healthy_knowledge_base.dart';
import 'package:healthy_habit/páginas/chatbot/nutri_respuestas_service.dart';

void main() {
  group('Mr. Healthy - curated knowledge', () {
    const kb = HealthyKnowledgeBase();

    test('answers common nutrition questions', () {
      expect(kb.answer('¿Qué son las proteínas?'), contains('proteínas'));
      expect(kb.answer('¿Qué nutrientes tienen las lentejas?'), isNotNull);
      expect(kb.answer('¿Cómo comer barato?'), contains('presupuesto'));
    });

    test('answers activity questions without inventing individualized plans', () {
      expect(kb.answer('¿Qué es el entrenamiento de fuerza?'), contains('músculos'));
      expect(kb.answer('¿Cómo hago sentadillas?'), contains('sentadilla'));
    });

    test('does not fabricate answers for unrelated questions', () {
      expect(kb.answer('¿Qué ocurrió en Marte ayer?'), isNull);
    });
  });

  group('Mr. Healthy - conversation safety', () {
    test('recognizes discriminatory hostile statements', () {
      expect(NutriRespuestasService.ataqueDiscriminatorio('Odio a los gays'), isTrue);
      expect(NutriRespuestasService.ataqueDiscriminatorio('Los negros son inferiores'), isTrue);
    });

    test('does not flag neutral questions about identity', () {
      expect(NutriRespuestasService.ataqueDiscriminatorio('¿Qué significa ser gay?'), isFalse);
      expect(NutriRespuestasService.ataqueDiscriminatorio('¿Cómo combatir el racismo?'), isFalse);
    });

    test('responds without endorsing discrimination', () {
      final service = NutriRespuestasService();
      expect(service.moderar('Odio a los gays', ''), contains('No voy a respaldar'));
    });

    test('can change moods and retains an educational answer', () {
      final service = NutriRespuestasService();
      service.cambiarHumor('serio');
      final serious = service.responder('¿Qué son los carbohidratos?', nombre: '', perfil: {});
      service.cambiarHumor('motivador');
      final motivated = service.responder('¿Qué son los carbohidratos?', nombre: '', perfil: {});
      expect(serious, contains('energía'));
      expect(motivated, contains('energía'));
      expect(motivated, isNot(serious));
    });

    test('ignores an unsupported mood', () {
      final service = NutriRespuestasService();
      service.cambiarHumor('serio');
      service.cambiarHumor('furioso');
      expect(service.humor, 'serio');
    });
  });
}
