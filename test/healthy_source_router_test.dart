import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/healthy_source_router.dart';

void main() {
  test('preguntas ordinarias se resuelven localmente', () {
    expect(HealthySourceRouter.decide('¿Qué es un hábito?').route,
        HealthySourceRoute.local);
    expect(HealthySourceRouter.decide('Muéstrame mis desafíos').route,
        HealthySourceRoute.local);
  });

  test('búsqueda explícita enciclopédica conserva el tema', () {
    final route = HealthySourceRouter.decide('Busca en Wikipedia Marte');
    expect(route.route, HealthySourceRoute.encyclopedia);
    expect(route.query, 'Marte');
  });

  test('protege información personal y operaciones', () {
    for (final request in [
      'Busca en internet mi perfil',
      'Busca en internet borrar mi cuenta',
      'Busca en Wikipedia mi saldo',
      'Busca en internet comprar en tienda',
    ]) {
      expect(HealthySourceRouter.decide(request).route,
          HealthySourceRoute.privateData, reason: request);
    }
  });

  test('no usa wikipedia para consultas médicas sensibles', () {
    for (final request in [
      'Busca en Wikipedia dosis de insulina',
      'Busca en internet diagnóstico de alergia',
      'Consulta Wikipedia tratamiento para intoxicación',
    ]) {
      expect(HealthySourceRouter.decide(request).route,
          HealthySourceRoute.sensitive, reason: request);
    }
  });

  test('solicitud sin tema pide precisión', () {
    expect(HealthySourceRouter.decide('Busca en internet xy').route,
        HealthySourceRoute.clarification);
  });

  test('búsqueda de tema educativo general sigue permitida', () {
    expect(HealthySourceRouter.decide('Busca en Wikipedia hábitos').route,
        HealthySourceRoute.encyclopedia);
  });
}
