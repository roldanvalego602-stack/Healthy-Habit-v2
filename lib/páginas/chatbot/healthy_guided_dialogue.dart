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
    r'tienda|contrasena)\b',
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
    if (current.isEmpty || current.length > 110) return null;
    // Cancelar el diálogo no es cancelar un hábito ni una compra.
    if (assistant.contains('que meta concreta quieres organizar') &&
        const {'cancelar plan', 'olvida el plan', 'ya no quiero planear'}
            .contains(current)) {
      return 'De acuerdo, dejamos esa planificación. '
          'No se guardó ninguna meta ni se modificó tu cuenta.';
    }
    if (_sensitive.hasMatch(current)) return null;

    // El seguimiento solo responde a una invitación de esta misma
    // conversación. No marca progreso ni modifica tareas de la app.
    if (assistant.contains('primer paso anotado solo en esta conversacion') &&
        assistant.contains('no he modificado tus habitos')) {
      if (const {'ya lo hice', 'lo hice', 'terminado', 'lo termine',
          'completado', 'ya termine'}.contains(current)) {
        return 'Gracias por contarme cómo te fue. No he registrado '
            'este avance en Healthy Habit. ¿Quieres definir un siguiente '
            'paso pequeño o dar por terminada esta conversación?';
      }
      if (const {'no pude', 'no lo hice', 'no alcance',
          'me costo', 'se me olvido'}.contains(current)) {
        return 'Podemos reducir el esfuerzo sin tratarlo como un fracaso. '
            '¿Qué obstáculo apareció: tiempo, energía o materiales? '
            'No he cambiado tus hábitos ni tu racha.';
      }
      if (const {'quiero cambiar el paso', 'cambiar el paso',
          'otro paso', 'prefiero otro paso'}.contains(current)) {
        return 'De acuerdo. ¿Qué nueva acción pequeña prefieres? '
            'Solo la comentaremos aquí, sin modificar tu cuenta.';
      }
    }

    if (assistant.contains('que obstaculo aparecio') &&
        assistant.contains('tiempo energia o materiales')) {
      final suggestion = switch (current) {
        'tiempo' => 'Prueba reservar solo dos minutos en un momento libre.',
        'energia' => 'Considera una versión más sencilla o descansar primero.',
        'materiales' => 'Busca una acción que no requiera esos materiales.',
        _ => '',
      };
      if (suggestion.isEmpty) {
        return 'Para ajustar el primer paso, elige un obstáculo: '
            'tiempo, energía o materiales.';
      }
      return '$suggestion Es una sugerencia, no un cambio registrado. '
          '¿Qué primer paso te resultaría más viable?';
    }

    if (assistant.contains('que nueva accion pequena prefieres') ||
        assistant.contains('que primer paso te resultaria mas viable')) {
      if (current.length < 5 || current.length > 90) {
        return 'Describe una acción breve y concreta. '
            'No se guardará como hábito automáticamente.';
      }
      return 'Paso revisado en esta conversación: «${input.trim()}». '
          'No lo he guardado como hábito ni he programado avisos. '
          '¿Quieres probarlo y contarme el resultado después?';
    }

    if (assistant.contains('quieres definir un siguiente paso pequeno') &&
        const {'siguiente paso', 'otro paso', 'si', 'claro'}.contains(current)) {
      return '¿Qué nueva acción concreta quieres intentar? '
          'No he añadido actividades a tu cuenta.';
    }
    if (assistant.contains('que nueva accion concreta quieres intentar')) {
      if (current.length < 5 || current.length > 90) {
        return 'Escribe una acción breve y específica.';
      }
      return 'Siguiente paso propuesto: «${input.trim()}». '
          'Solo lo hemos descrito en el chat; no he registrado progreso.';
    }

    // Planificación orientativa en tres pasos. No crea registros de hábitos,
    // tareas ni recordatorios. Se limita a metas personales no clínicas.
    if (const {
      'ayudame a planear una meta', 'quiero planear una meta',
      'quiero organizar una meta', 'quiero organizar un objetivo',
      'ayudame a organizar un objetivo',
    }.contains(current)) {
      return 'Podemos definir un plan pequeño, sin modificar tu cuenta. '
          '¿Qué meta concreta quieres organizar?';
    }

    if (assistant.contains('que meta concreta quieres organizar')) {
      if (current.length < 8 || current.length > 90 ||
          const {'no se', 'todavia no se', 'ninguna'}.contains(current)) {
        return 'Describe una meta específica en una frase, por ejemplo '
            '«leer veinte páginas» o «ordenar mi escritorio».';
      }
      return 'Meta propuesta: ${input.trim()}. '
          '¿En qué plazo quieres intentarla: hoy, esta semana o este mes?';
    }

    if (assistant.contains('en que plazo quieres intentarla') &&
        assistant.contains('hoy esta semana o este mes')) {
      if (previousUser.isEmpty || previousUser.length > 90 ||
          _sensitive.hasMatch(previousUser)) return null;
      final deadline = switch (current) {
        'hoy' => 'hoy',
        'esta semana' || 'semana' => 'esta semana',
        'este mes' || 'mes' => 'este mes',
        _ => '',
      };
      if (deadline.isEmpty) {
        return 'Elige un plazo sencillo: hoy, esta semana o este mes. '
            'Si necesitas otro, podemos formular una meta más concreta.';
      }
      return 'Plan orientativo para «${previousUserMessage.trim()}» '
          '($deadline): 1) Define una primera acción de unos minutos. '
          '2) Reserva un momento disponible. '
          '3) Comprueba si la realizaste y ajusta la dificultad. '
          'No he programado recordatorios ni registrado progreso. '
          '¿Cuál será tu primer paso?';
    }

    if (assistant.contains('cual sera tu primer paso') &&
        assistant.contains('no he programado recordatorios')) {
      if (current.length < 4 || current.length > 90) {
        return 'Dime una primera acción específica y pequeña, '
            'sin datos personales ni información médica.';
      }
      return 'Primer paso anotado solo en esta conversación: '
          '«${input.trim()}». Puedes realizarlo cuando te resulte '
          'posible y después contarme cómo te fue. '
          'No he modificado tus hábitos ni creado un recordatorio.';
    }

    if (assistant.isEmpty) return null;

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
