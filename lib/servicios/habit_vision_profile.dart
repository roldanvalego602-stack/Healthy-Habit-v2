/// Selección conservadora del perfil visual según el hábito real.
/// No supone que una fotografía demuestre la acción del usuario.
class HabitVisionProfile {
  const HabitVisionProfile._();

  static String _normalize(String value) {
    const from = 'áéíóúüñ';
    const to = 'aeiouun';
    var normalized = value.toLowerCase().trim();
    for (var i = 0; i < from.length; i++) {
      normalized = normalized.replaceAll(from[i], to[i]);
    }
    return normalized;
  }

  static bool _hasTerm(String text, String term) =>
      RegExp('(^|[^a-z])' + RegExp.escape(term) + r'([^a-z]|$)')
          .hasMatch(text);

  /// Devuelve null si el hábito no tiene un perfil visual adecuado.
  /// El título prima sobre la categoría general.
  static String? suggest({required String title, required String category}) {
    final t = _normalize(title);
    final c = _normalize(category);

    // Reconocemos expresiones específicas, no cualquier actividad con
    // la palabra "salud" o "alimentación".
    if (_hasTerm(t, 'agua') || _hasTerm(t, 'hidratarse') ||
        _hasTerm(t, 'hidratacion') || _hasTerm(t, 'water')) {
      return 'hydration';
    }
    if (t.contains('fruta') || t.contains('verdura') ||
        _hasTerm(t, 'vegetales') || _hasTerm(t, 'manzana') ||
        _hasTerm(t, 'platano') || _hasTerm(t, 'banana') ||
        _hasTerm(t, 'ensalada')) {
      return 'fruit_vegetable';
    }
    if (_hasTerm(t, 'desayuno') || _hasTerm(t, 'almuerzo') ||
        _hasTerm(t, 'comida') || _hasTerm(t, 'cena') ||
        _hasTerm(t, 'alimentarse') || _hasTerm(t, 'comer')) {
      return 'meal';
    }

    // Otras actividades como ejercicio, sueño, lectura o caminar no
    // son evaluables mediante estos perfiles, aunque la categoría
    // asociada sea amplia o esté desactualizada.
    if (RegExp(r'\b(caminar|correr|ejercicio|entrenar|dormir|sueño|'
        r'leer|meditar|estudiar|pasos|respirar|estirar)\b')
        .hasMatch(t)) {
      return null;
    }

    if (c.contains('hidratacion')) return 'hydration';
    if (c.contains('fruta') || c.contains('verdura')) {
      return 'fruit_vegetable';
    }
    if (c == 'comida' || c == 'alimentacion' || c == 'nutricion') {
      return 'meal';
    }
    return null;
  }

  static String label(String? profile) {
    switch (profile) {
      case 'hydration':
        return 'Hidratación';
      case 'fruit_vegetable':
        return 'Frutas y verduras';
      case 'meal':
        return 'Comida';
      default:
        return 'Sin perfil compatible';
    }
  }
}
