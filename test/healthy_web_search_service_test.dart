import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/healthy_web_search_service.dart';

void main() {
  test('solo las órdenes explícitas activan la consulta externa', () {
    expect(HealthyWebSearchService.extractQuery('Busca en internet sobre Marte'),
        'Marte');
    expect(HealthyWebSearchService.extractQuery('Consulta Wikipedia: fotosíntesis'),
        'fotosíntesis');
    expect(HealthyWebSearchService.extractQuery('Busca en Wikipedia hábitos'),
        'hábitos');
    expect(HealthyWebSearchService.extractQuery('¿Qué es la fotosíntesis?'),
        isNull);
    expect(HealthyWebSearchService.extractQuery('Busco mi perfil'), isNull);
  });

  test('presenta resultados con fuente verificable', () {
    final message = HealthyWebSearchService.formatResults(const [
      HealthyWebSearchResult(
        title: 'Marte',
        excerpt: 'Cuarto planeta del Sistema Solar.',
        url: 'https://es.wikipedia.org/wiki/Marte',
      ),
    ]);
    expect(message, contains('Wikipedia en español'));
    expect(message, contains('Cuarto planeta'));
    expect(message, contains('https://es.wikipedia.org/wiki/Marte'));
  });

  test('sin resultados informa el límite del proveedor', () {
    expect(HealthyWebSearchService.formatResults(const []),
        contains('solo consulta Wikipedia en español'));
  });
}
