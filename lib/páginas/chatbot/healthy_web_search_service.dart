import 'package:cloud_functions/cloud_functions.dart';

/// Búsqueda voluntaria en una fuente concreta, no un motor de IA generativa.
class HealthyWebSearchResult {
  const HealthyWebSearchResult({
    required this.title, required this.excerpt, required this.url,
  });
  final String title;
  final String excerpt;
  final String url;
}

class HealthyWebSearchService {
  const HealthyWebSearchService();

  /// Solo se activa con una orden explícita de consulta externa.
  static String? extractQuery(String input) {
    final match = RegExp(
      r'^\s*(?:busca en internet|buscar en internet|'
      r'consulta wikipedia|busca en wikipedia|'
      r'buscar en wikipedia|investiga en wikipedia)\s*'
      r'(?::|sobre|acerca de)?\s*(.+)$',
      caseSensitive: false,
    ).firstMatch(input);
    final query = match?.group(1)?.trim() ?? '';
    return query.isEmpty ? null : query;
  }

  Future<List<HealthyWebSearchResult>> search(String query) async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('searchMrHealthyEncyclopedia',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 12)));
    final response = await callable.call(<String, dynamic>{'query': query});
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['provider'] != 'Wikipedia') {
      throw const FormatException('Fuente externa no reconocida.');
    }
    final items = data['results'];
    if (items is! List) {
      throw const FormatException('Resultados no válidos.');
    }
    return items.map((entry) {
      final record = Map<String, dynamic>.from(entry as Map);
      final url = (record['url'] ?? '').toString();
      final parsed = Uri.tryParse(url);
      if (parsed == null || parsed.scheme != 'https' ||
          parsed.host != 'es.wikipedia.org') {
        throw const FormatException('Enlace de fuente no permitido.');
      }
      return HealthyWebSearchResult(
        title: (record['title'] ?? '').toString(),
        excerpt: (record['excerpt'] ?? '').toString(),
        url: url,
      );
    }).toList(growable: false);
  }

  static String formatResults(List<HealthyWebSearchResult> results) {
    if (results.isEmpty) {
      return 'No encontré artículos enciclopédicos relacionados. '
          'Prueba con un término más específico. '
          'Esta búsqueda solo consulta Wikipedia en español.';
    }
    final buffer = StringBuffer(
      'Consulta externa · Wikipedia en español\n'
      'Estos son fragmentos de resultados, no una respuesta médica '
      'ni hechos verificados independientemente.\n\n');
    for (final item in results) {
      buffer.writeln('• ${item.title}');
      if (item.excerpt.isNotEmpty) buffer.writeln(item.excerpt);
      buffer.writeln('Fuente: ${item.url}\n');
    }
    return buffer.toString().trimRight();
  }
}
