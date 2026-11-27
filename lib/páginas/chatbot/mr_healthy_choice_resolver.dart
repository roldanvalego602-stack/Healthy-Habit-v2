import 'healthy_assistant_reply.dart';
import 'healthy_hybrid_knowledge.dart';

/// Interpreta selecciones de opciones que Mr. Healthy haya ofrecido realmente.
/// No ejecuta acciones ni intenta hacer recomendaciones clínicas.
class MrHealthyChoiceResolver {
  const MrHealthyChoiceResolver._();

  static String _normalize(String raw) =>
      HealthyKnowledgeIndex.normalize(raw);

  static final RegExp _sensitive = RegExp(
    r'\b(embaraz\w*|alergia\w*|diabetes|intoxic\w*|'
    r'atragant\w*|asfixia|desmay\w*|medicamento\w*|'
    r'dosis|autolesion|suicid\w*|calorias exactas|'
    r'cuantas calorias|cuanto debo|mi saldo|mi contrasena)\b',
  );

  /// Solo existen menús para preguntas ya documentadas y verificables.
  static const Map<String, List<String>> choices = {
    'food_desayuno': ['rapida', 'economica', 'sin lacteos'],
    'food_cena': ['economica', 'vegetariana'],
    'food_almuerzo': ['para llevar', 'en casa'],
    'food_proteina': ['economica', 'vegetariana'],
    'food_fibra': ['economica', 'para llevar'],
    'food_agua': ['recordatorios', 'sabor'],
    'ex_principiante': ['en casa', 'caminar'],
    'ex_casa': ['con silla', 'sin equipo'],
    'ex_fuerza': ['con equipo', 'sin equipo'],
    'ex_motivacion': ['tiempo', 'cansancio', 'aburrimiento'],
    'random_historia': ['misterio', 'aventura'],
    'random_aburrido': ['adivinanza', 'historia', 'reto creativo'],
    'app_tienda': ['accesorio', 'tema', 'inventario'],
    'app_cosmos': ['comprar', 'volver al anterior'],
  };

  static const Map<String, Map<String, String>> responses = {
    'food_desayuno': {
      'rapida': 'Una idea rápida es fruta con yogur natural y avena, '
          'si los toleras. También puedes preparar una tortilla con '
          'huevo bien cocido. ¿Quieres otra variante?',
      'economica': 'Para un desayuno económico puedes preparar avena '
          'con fruta de temporada, o frijoles con tortilla y verduras. '
          '¿Te gustaría algo todavía más sencillo?',
      'sin lacteos': 'Sin lácteos puedes combinar avena preparada con '
          'agua y fruta, o huevo bien cocido con verduras. '
          'Comprueba ingredientes si evitas lácteos por alergia. '
          '¿Quieres una versión rápida?',
    },
    'food_cena': {
      'economica': 'Una cena económica puede ser sopa de lentejas '
          'con verduras y tortilla. Ajusta cantidades a tu apetito.',
      'vegetariana': 'Puedes preparar garbanzos con verduras y arroz '
          'o una sopa de legumbres. No necesitas usar carne.',
    },
    'food_almuerzo': {
      'para llevar': 'Para llevar, una opción es arroz y frijoles con '
          'verduras. Usa un recipiente limpio y mantén los alimentos '
          'perecederos a una temperatura segura.',
      'en casa': 'En casa puedes preparar lentejas con verduras '
          'y tortillas, según tus gustos y disponibilidad.',
    },
    'food_proteina': {
      'economica': 'Entre las fuentes económicas de proteína suelen '
          'estar frijoles, lentejas y huevo bien cocido.',
      'vegetariana': 'Puedes combinar leguminosas, tofu y semillas. '
          'Una alimentación vegana requiere prestar atención a B12.',
    },
    'food_fibra': {
      'economica': 'Frijoles, lentejas y avena pueden aportar fibra '
          'sin exigir ingredientes costosos. Auméntala gradualmente.',
      'para llevar': 'Una fruta entera, avena preparada de forma '
          'segura o leguminosas bien conservadas pueden aportar fibra.',
    },
    'food_agua': {
      'recordatorios': 'Prueba dejar un vaso o botella cerca y '
          'asociar beber agua con pausas habituales. No fuerces '
          'una cantidad fija para todas las personas.',
      'sabor': 'Puedes añadir rodajas de fruta o hierbas limpias '
          'al agua. Evita conservar la bebida fuera de refrigeración '
          'durante demasiado tiempo.',
    },
    'ex_principiante': {
      'en casa': 'Para empezar en casa, prueba marcha suave en el '
          'sitio y levantarte de una silla estable con apoyo. '
          'Detente ante dolor o mareo.',
      'caminar': 'Prueba una caminata breve en una ruta segura '
          'y a ritmo cómodo. Aumenta progresivamente si te sientes bien.',
    },
    'ex_casa': {
      'con silla': 'Usa una silla firme y estable para practicar '
          'levantarte y sentarte con control. Evita muebles que se deslicen.',
      'sin equipo': 'Puedes caminar en el sitio y hacer flexiones '
          'contra pared, con movimientos suaves y sin dolor.',
    },
    'ex_fuerza': {
      'con equipo': 'Si tienes equipo, empieza con una carga ligera '
          'y prioriza técnica, control y descanso adecuado.',
      'sin equipo': 'Empieza con sentadillas asistidas y flexiones '
          'contra pared. Progresa solo cuando domines la técnica.',
    },
    'ex_motivacion': {
      'tiempo': 'Elige una actividad tan breve que puedas cumplir '
          'en tu rutina, incluso unos minutos cuentan.',
      'cansancio': 'Si estás cansado, puedes priorizar descanso '
          'o movimiento suave. No necesitas entrenar al máximo cada día.',
      'aburrimiento': 'Alterna actividades que disfrutes, como caminar '
          'con música, bailar o probar un recorrido diferente.',
    },
    'random_historia': {
      'misterio': 'La puerta de la estación espacial se abrió sola. '
          'Detrás apareció una luz verde y una nota: '
          '«No despiertes a la última semilla». ¿La investigamos?',
      'aventura': 'La semilla tomó un pequeño cohete de exploración '
          'y encontró un planeta cubierto de jardines flotantes. '
          '¿Quieres visitar la ciudad o seguir una señal desconocida?',
    },
    'random_aburrido': {
      'adivinanza': 'Adivinanza: cuanto más me quitas, '
          'más grande me hago. ¿Qué soy?',
      'historia': 'En un planeta lejano, un pequeño robot encontró '
          'un jardín que solo florecía cuando alguien compartía algo.',
      'reto creativo': 'Reto breve: inventa el nombre de un planeta '
          'y una costumbre extraña de sus habitantes.',
    },
    'app_tienda': {
      'accesorio': 'En Tienda puedes revisar accesorios disponibles, '
          'sus precios y sus requisitos. Comprar requiere tu confirmación.',
      'tema': 'Los temas premium se desbloquean con Habit Coins '
          'y después pueden equiparse desde la interfaz autorizada.',
      'inventario': 'Revisa tu Armario o inventario para consultar '
          'artículos adquiridos. No puedo confirmar una compra '
          'sin consultar datos reales de tu cuenta.',
    },
    'app_cosmos': {
      'comprar': 'Puedes localizar Cosmos en la Tienda y revisar '
          'su precio antes de confirmar la compra. '
          'No puedo comprarlo por ti desde esta respuesta.',
      'volver al anterior': 'En la tarjeta de Cosmos puedes '
          'desequiparlo para recuperar tu aspecto anterior, '
          'conservando el artículo adquirido.',
    },
  };

  static const Map<String, List<String>> synonyms = {
    'rapida': ['rapida', 'rapido', 'facil', 'sencilla', 'sencillo'],
    'economica': ['economica', 'economico', 'barata', 'barato',
      'poco dinero', 'bajo presupuesto'],
    'sin lacteos': ['sin lacteos', 'sin leche'],
    'vegetariana': ['vegetariana', 'vegetariano', 'sin carne'],
    'para llevar': ['para llevar', 'llevar al trabajo'],
    'en casa': ['en casa', 'desde casa', 'casera'],
    'recordatorios': ['recordatorios', 'recordar', 'olvido'],
    'sabor': ['sabor', 'saborizada', 'darle sabor'],
    'caminar': ['caminar', 'caminata', 'a pie'],
    'con silla': ['con silla', 'silla'],
    'sin equipo': ['sin equipo', 'sin aparatos', 'sin pesas'],
    'con equipo': ['con equipo', 'con pesas', 'mancuernas'],
    'tiempo': ['tiempo', 'poco tiempo', 'sin tiempo'],
    'cansancio': ['cansancio', 'cansado', 'cansada'],
    'aburrimiento': ['aburrimiento', 'aburrido', 'aburrida'],
    'misterio': ['misterio', 'misteriosa'],
    'aventura': ['aventura', 'aventuras'],
    'adivinanza': ['adivinanza', 'acertijo'],
    'historia': ['historia', 'cuento'],
    'reto creativo': ['reto creativo', 'reto'],
    'accesorio': ['accesorio', 'accesorios'],
    'tema': ['tema', 'temas'],
    'inventario': ['inventario', 'armario'],
    'comprar': ['comprar', 'compra'],
    'volver al anterior': ['volver al anterior', 'anterior',
      'desequipar', 'quitar tema'],
  };

  static bool _offered(String priorReply, List<String> available) {
    if (priorReply.trim().isEmpty) return false;
    final reply = _normalize(priorReply);
    return available.any((choice) {
      return (' $reply ').contains(' ${_normalize(choice)} ');
    });
  }

  static int? _ordinal(String q) {
    if (RegExp(r'^(la |el |opcion |prefiero la )?(primera|primero|1)$')
        .hasMatch(q)) return 0;
    if (RegExp(r'^(la |el |opcion |prefiero la )?(segunda|segundo|2)$')
        .hasMatch(q)) return 1;
    if (RegExp(r'^(la |el |opcion |prefiero la )?(tercera|tercero|3)$')
        .hasMatch(q)) return 2;
    return null;
  }

  static HealthyAssistantReply? answer(
    String input, {
    required String topicId,
    required String previousAssistantText,
  }) {
    final options = choices[topicId];
    if (options == null || previousAssistantText.trim().isEmpty) return null;
    final q = _normalize(input);
    if (q.isEmpty || _sensitive.hasMatch(q)) return null;

    final previous = _normalize(previousAssistantText);
    final eligible = _offered(previousAssistantText, options);
    if (!eligible) return null;

    String? option;
    final ordinal = _ordinal(q);
    if (ordinal != null) {
      // An ordinal is valid only if the previous reply enumerated options
      // in the same order; do not invent an implicit list.
      final positions = options.map((choice) =>
          previous.indexOf(_normalize(choice))).toList();
      if (positions.every((position) => position >= 0) &&
          positions.length > ordinal &&
          positions.toSet().length == positions.length) {
        final ordered = List<int>.generate(options.length, (i) => i)
          ..sort((a, b) => positions[a].compareTo(positions[b]));
        option = options[ordered[ordinal]];
      } else {
        return HealthyAssistantReply(
          'No quiero escoger una opción que no esté clara. '
          '¿Cuál prefieres: ${options.join(', ')}?',
          card: 'topic', actionArgument: topicId, knowledgeId: topicId,
        );
      }
    }

    if (option == null) {
      final matches = <String>[];
      for (final choice in options) {
        final aliases = synonyms[choice] ?? [choice];
        if (aliases.any((term) => (' $q ').contains(' ${_normalize(term)} '))) {
          matches.add(choice);
        }
      }
      if (matches.length == 1) option = matches.first;
    }

    if (option == null && RegExp(
        r'^(no me gusta|no quiero esa|no me convence|'
        r'otra opcion|prefiero otra|no esa|otra alternativa)\b'
      ).hasMatch(q)) {
      // Do not assume what "esa" refers to when multiple alternatives exist.
      return HealthyAssistantReply(
        'Entiendo. ¿Quieres probar otra alternativa: '
        '${options.join(', ')}? No hace falta elegir de inmediato.',
        card: 'topic', actionArgument: topicId, knowledgeId: topicId,
      );
    }

    if (option == null) return null;
    final text = responses[topicId]?[option];
    if (text == null) return null;
    return HealthyAssistantReply(
      '$text\n\n¿Quieres otra opción o prefieres cambiar de tema?',
      card: 'topic', actionArgument: topicId, knowledgeId: topicId,
    );
  }
}
