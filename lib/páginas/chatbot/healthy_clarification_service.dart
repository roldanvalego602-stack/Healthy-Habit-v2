import 'healthy_hybrid_knowledge.dart';

/// Aclaraciones locales para solicitudes que los motores especializados
/// no lograron resolver. Nunca genera datos, cifras ni acciones.
class HealthyClarificationService {
  const HealthyClarificationService._();

  static String respond(String input, {String previousAssistantText = ''}) {
    final q = HealthyKnowledgeIndex.normalize(input);
    final previous = HealthyKnowledgeIndex.normalize(previousAssistantText);

    if (q.isEmpty) {
      return 'Escribe qué necesitas y te ayudaré a identificar '
          'la función o información adecuada.';
    }

    // Evita aparentar continuidad cuando el tema anterior no estaba claro.
    if (const {
      'eso', 'esto', 'el otro', 'la otra', 'hazlo', 'igual',
      'lo mismo', 'asi', 'el primero', 'el segundo',
    }.contains(q)) {
      return '¿A qué te refieres con «$input»? '
          'Indica el tema o la opción por su nombre; '
          'no quiero asumir algo que no elegiste.';
    }

    if (const {
      'explicacion', 'una explicacion', 'explicame',
      'un ejemplo', 'ejemplo', 'paso a paso', 'consejo',
    }.contains(q) && (
      previous.contains('buscas una explicacion') ||
      previous.contains('quieres una definicion') ||
      previous.contains('que fuente conviene consultar')
    )) {
      return '¿Sobre qué tema quieres esa explicación? '
          'Escribe el concepto o una pregunta completa para '
          'que pueda comprobar si tengo información fiable.';
    }

    // Solo son preguntas de aclaración, nunca recomendaciones médicas.
    if (RegExp(
      r'\b(me duele|dolor|sintoma|sintomas|enfermo|enferma|'
      r'medicamento|tratamiento|diagnostico|dosis|alergia|'
      r'embarazo|intoxicacion|desmayo)\b',
    ).hasMatch(q)) {
      return 'No puedo determinar una causa ni indicar tratamientos '
          'a partir de ese mensaje. Si hay síntomas intensos o '
          'repentinos, busca atención médica. '
          '¿Buscas información educativa general o ayuda para '
          'encontrar atención profesional?';
    }

    if (RegExp(
      r'\b(ultimo|ultima|hoy|actual|actualidad|reciente|'
      r'noticias|precio del mercado|cotizacion|2026|2027)\b',
    ).hasMatch(q)) {
      return 'Ese dato podría cambiar con el tiempo y no tengo '
          'una fuente actual confirmada para responderlo. '
          'Por ahora puedo consultar Wikipedia en español '
          'si escribes «Busca en Wikipedia [tema]»; '
          'esa fuente no sustituye noticias ni datos en vivo.';
    }

    if (RegExp(r'\b(mejor|conviene|elegir|comparar|'
        r'cual compro|cual elegir|entre)\b').hasMatch(q)) {
      return 'Para comparar opciones necesito saber cuáles son '
          'y qué criterio importa más: costo, tiempo, facilidad '
          'o beneficio. ¿Qué alternativas estás considerando?';
    }

    if (RegExp(r'\b(como hacer|como creo|como logro|'
        r'como puedo|pasos para|ensename a)\b').hasMatch(q)) {
      return 'Puedo ayudarte a ordenar un procedimiento, pero '
          'no tengo instrucciones verificadas para esa solicitud. '
          '¿Cuál es el resultado que buscas y qué has intentado?';
    }

    if (RegExp(r'\b(que es|que significa|quien es|'
        r'por que|explicame|informacion|define)\b').hasMatch(q)) {
      return 'No encontré una explicación revisada de ese tema '
          'en mi conocimiento local. ¿Puedes escribir el concepto '
          'exacto o consultar «Busca en Wikipedia [tema]»? '
          'La consulta externa mostrará sus fuentes.';
    }

    if (q.split(' ').length <= 3) {
      return 'Necesito un poco más de contexto sobre «$input». '
          '¿Quieres una definición, una idea práctica '
          'o ayuda con alguna función de Healthy Habit?';
    }

    return 'No tengo información suficiente para responder esa '
        'solicitud con fiabilidad. Indícame qué resultado necesitas '
        'y un detalle adicional; así puedo buscar una respuesta '
        'local o decirte qué fuente conviene consultar.';
  }
}
