/// Pasa a minúsculas, quita acentos y colapsa espacios.
String normalizeText(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp('[àáâãä]'), 'a')
      .replaceAll(RegExp('[èéêë]'), 'e')
      .replaceAll(RegExp('[ìíîï]'), 'i')
      .replaceAll(RegExp('[òóôõö]'), 'o')
      .replaceAll(RegExp('[ùúûü]'), 'u')
      .replaceAll('ñ', 'n')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[‘’]'), "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Indica si [text] contiene alguna de las palabras clave como palabra completa.
///
/// - Acepta el plural (`s`/`es`) de claves de más de 3 letras:
///   `mision` reconoce "misiones".
/// - Si la clave termina en `*` es una raíz y acepta cualquier terminación:
///   `hidrat*` reconoce "hidratar", "hidratarme" o "hidratado".
bool containsAnyKeyword(String text, List<String> keywords) {
  final normalized = normalizeText(text);
  return keywords.any((keyword) {
    final isStem = keyword.endsWith('*');
    final key = normalizeText(
      isStem ? keyword.substring(0, keyword.length - 1) : keyword,
    );
    if (key.isEmpty) return false;

    final suffix =
        isStem
            ? r'[a-z0-9]*'
            : key.length > 3
            ? r'(?:s|es)?'
            : '';
    return RegExp(
      r'(^|[^a-z0-9])' + RegExp.escape(key) + suffix + r'($|[^a-z0-9])',
    ).hasMatch(normalized);
  });
}
