import 'healthy_hybrid_knowledge.dart';

/// Seguimiento conversacional acotado. Solo formula preguntas y ofrece
/// métodos generales; nunca ejecuta acciones ni infiere datos del perfil.
class HealthyGuidedDialogue {
  const HealthyGuidedDialogue._();

  static String _normalize(String text) =>
      HealthyKnowledgeIndex.normalize(text);

  static final RegExp _sensitive = RegExp(
    r'\b(suicid\w*|autolesi\w*|matarme|medicamento|dosis|'
    r'tratamiento|diagnostico|alergia|dolor|intoxicacion|'
    r'embarazo|insulina|cuenta|perfil|saldo|xp|monedas|'
    r'comprar|compra|borrar|borra|eliminar|elimina|'
    r'activar|agregar|registrar|cancela|cancelar|'
    r'habito|habitos|tienda|contrasena)\b',
  );

  static const _askCriterion =
      '¿Qué criterio quieres priorizar: costo, tiempo, facilidad '
      'o beneficio? No asumiré precios ni resultados.';

  static String? _pair(String input) {
    final clean = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length < 5 || clean.length > 100) return null;
    final parts = clean.split(RegExp(r'\s+(?:y|vs\.?|versus|o)\s+',
      caseSensitive: false));
    if (parts.length != 2) return null;
    if (parts.any((p) => p.trim().length < 2 || p.trim().length > 36)) {
      return null;
    }
    if (parts.any((p) => _sensitive.hasMatch(_normalize(p)))) return null;
    return '${parts[0].trim()} | ${parts[1].trim()}';
  }

  /// Siempre requiere que la respuesta anterior del asistente contenga
  /// una pregunta de este flujo. Un simple «sí» no activa nada.
  static String? reply(
    String input, {
    String previousUserMessage = '',
    String previousAssistantText = '',
  }) {
    final current = _normalize(input);
    final assistant = _normalize(previousAssistantText);
    final previousUser = _normalize(previousUserMessage);
    if (current.isEmpty || current.length > 110 ||
        assistant.isEmpty || _sensitive.hasMatch(current)) return null;

    if (assistant.contains(
        'que alternativas estas considerando') &&
        assistant.contains('costo tiempo facilidad o beneficio')) {
      final pair = _pair(input);
      if (pair == null) {
        if (const {'no se', 'no lo se', 'aun no se', 'ninguna'}
            .contains(current)) {
          return 'Podemos comenzar por definir dos alternativas. '
              'Escríbelas juntas, por ejemplo «caminar y bicicleta». '
              'No elegiré una por ti.';
        }
        return 'Indica dos alternativas concretas separadas por «y». '
            'Por ejemplo, «caminar y bicicleta». '
            'Después elegiremos un criterio para compararlas.';
      }
      return 'Alternativas anotadas: ${pair.replaceAll(' | ', ' y ')}. '
          '$_askCriterion';
    }

    if (assistant.contains('alternativas anotadas') &&
        assistant.contains('que criterio quieres priorizar')) {
      final pair = _pair(previousUserMessage);
      if (pair == null || _sensitive.hasMatch(previousUser)) return null;
      final criterion = switch (current) {
        'costo' || 'precio' || 'economia' || 'economico' => 'costo',
        'tiempo' || 'rapidez' => 'tiempo',
        'facilidad' || 'facil' || 'dificultad' => 'facilidad',
        'beneficio' || 'beneficios' || 'resultado' => 'beneficio',
        _ => '',
      };
      if (criterion.isEmpty) {
        return 'No identifiqué ese criterio. Elige uno: '
            'costo, tiempo, facilidad o beneficio.';
      }
      final options = pair.split(' | ');
      final guidance = switch (criterion) {
        'costo' => 'Anota el costo real de cada opción, '
            'incluidos gastos adicionales; no tengo precios confirmados.',
        'tiempo' => 'Estima preparación, traslado y ejecución de cada '
            'opción según tus circunstancias.',
        'facilidad' => 'Compara materiales necesarios, experiencia '
            'previa y esfuerzo para empezar.',
        _ => 'Define el resultado que buscas y una forma observable '
            'de comprobarlo en cada opción.',
      };
      return 'Comparación guiada de ${options[0]} y ${options[1]} '
          '(criterio: $criterion). $guidance '
          'No puedo decidir cuál gana sin datos verificables. '
          '¿Tienes un dato concreto de ambas opciones para compararlas?';
    }

    if (assistant.contains('tienes un dato concreto de ambas opciones') &&
        const {'no', 'no tengo', 'todavia no', 'aun no', 'no se'}
            .contains(current)) {
      return 'Sin esos datos no sería fiable escoger una opción. '
          'Puedes obtenerlos y comparar después, o elegir un '
          'criterio distinto. No hace falta decidir ahora.';
    }
    return null;
  }
}
