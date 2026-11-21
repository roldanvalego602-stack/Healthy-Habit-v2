import 'modelos/catalogo_item.dart';

enum VistaCatalogo { lista, imagenes, detalles, explorar }

enum OrdenCatalogo {
  relevancia,
  nombre,
  proteina,
  grasas,
  carbohidratos,
  fibra,
}

class CatalogoExplorador {
  const CatalogoExplorador._();

  static String normalizar(String text) {
    var value = text.toLowerCase().trim();
    for (final group in <String, String>{
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u',
    }.entries) {
      value = value.replaceAll(group.key, group.value);
    }
    return value;
  }

  /// Respeta el valor por 100 g indicado por la ficha; no convierte
  /// alimentos crudos en cocidos ni compara porciones diferentes.
  static double? nutriente(CatalogoItem item, String campo) {
    final raw = item.detalles[campo];
    if (raw == null || !raw.contains('g')) return null;
    final match = RegExp(r'(\d+(?:[.,]\d+)?)\s*g').firstMatch(raw);
    if (match == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', '.'));
  }

  static String? campoOrden(OrdenCatalogo orden) {
    switch (orden) {
      case OrdenCatalogo.proteina: return 'Proteína';
      case OrdenCatalogo.grasas: return 'Grasas';
      case OrdenCatalogo.carbohidratos: return 'Carbohidratos';
      case OrdenCatalogo.fibra: return 'Fibra';
      case OrdenCatalogo.relevancia:
      case OrdenCatalogo.nombre: return null;
    }
  }

  static List<CatalogoItem> filtrar({
    required List<CatalogoItem> items,
    String consulta = '',
    String etiqueta = 'Todos',
    OrdenCatalogo orden = OrdenCatalogo.relevancia,
  }) {
    final query = normalizar(consulta);
    final terms = query.split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    final results = items.where((item) {
      final tags = [
        item.titulo, item.descripcion, item.categoria, item.dificultad,
        ...item.etiquetas, ...item.beneficios,
        ...item.detalles.values,
      ];
      final text = normalizar(tags.join(' '));
      return (etiqueta == 'Todos' || item.etiquetas.contains(etiqueta)) &&
          terms.every(text.contains);
    }).toList();
    if (orden == OrdenCatalogo.nombre) {
      results.sort((a, b) =>
        normalizar(a.titulo).compareTo(normalizar(b.titulo)));
    } else {
      final campo = campoOrden(orden);
      if (campo != null) {
        results.sort((a, b) {
          final aValue = nutriente(a, campo);
          final bValue = nutriente(b, campo);
          if (aValue == null && bValue == null) return 0;
          if (aValue == null) return 1;
          if (bValue == null) return -1;
          return bValue.compareTo(aValue);
        });
      }
    }
    return results;
  }

  static List<String> filtros(List<CatalogoItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      for (final tag in item.etiquetas.toSet()) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final tags = counts.keys.toList()..sort((a, b) {
      final count = counts[b]!.compareTo(counts[a]!);
      return count != 0 ? count : normalizar(a).compareTo(normalizar(b));
    });
    return ['Todos', ...tags];
  }

  // Grupos educativos, no proporciones de una recomendación dietética.
  static String grupoPlato(CatalogoItem item) {
    final group = grupoAlimento(item);
    if (group == 'Frutas y verduras') return 'Frutas y verduras';
    if (group == 'Cereales integrales' || group == 'Cereales') {
      return 'Cereales';
    }
    if (group == 'Leguminosas' || group == 'Alimentos de origen animal') {
      return 'Leguminosas y origen animal';
    }
    return 'Otros alimentos';
  }

  static String grupoAlimento(CatalogoItem item) {
    final explicit = item.detalles['Grupo del plato'];
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }
    switch (item.id) {
      case 'avena': return 'Cereales integrales';
      case 'lentejas': return 'Leguminosas';
      case 'huevo': return 'Alimentos de origen animal';
      default: return 'Otros alimentos';
    }
  }

  static String zonaEjercicio(CatalogoItem item) {
    final tags = item.etiquetas;
    final muscular = normalizar(item.detalles['Grupo muscular'] ?? '');
    if (tags.contains('Flexibilidad')) {
      return 'Flexibilidad';
    }
    if (tags.contains('Brazos') || tags.contains('Pecho') ||
        muscular.contains('brazos')) {
      return 'Tren superior';
    }
    if (tags.contains('Piernas') || tags.contains('Glúteos') ||
        muscular.contains('piernas')) {
      return 'Tren inferior';
    }
    if (tags.contains('Zona media') || muscular.contains('zona media')) {
      return 'Zona media';
    }
    return 'Cardio y movilidad';
  }

  static String grupoExploracion(CatalogoItem item) {
    if (item.categoria == 'Alimentos') {
      return grupoAlimento(item);
    }
    if (item.categoria == 'Ejercicios') {
      return zonaEjercicio(item);
    }
    if (item.etiquetas.contains('Sueño') ||
        item.etiquetas.contains('Recuperación')) {
      return 'Sueño y recuperación';
    }
    if (item.etiquetas.contains('Seguridad')) {
      return 'Prevención y seguridad';
    }
    return 'Bienestar cotidiano';
  }
}
