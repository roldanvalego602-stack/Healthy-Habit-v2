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
    'app_inicio': ['habitos', 'progreso', 'tienda'],
    'app_habitos': ['agregar', 'registrar'],
    'app_registrar': ['contador', 'temporizador', 'fotografias'],
    'app_catalogo': ['alimentos', 'ejercicio'],
    'app_misiones': ['diarias', 'temporada'],
    'food_plato': ['desayuno', 'comida', 'cena'],
    'food_colacion': ['sin refrigeracion', 'en casa'],
    'food_carbo': ['integrales', 'refinados'],
    'food_verduras': ['comida', 'sopa'],
    'food_frutas': ['temporada', 'para llevar'],
    'ex_cardio': ['caminar', 'bicicleta', 'baile'],
    'ex_sin_equipo': ['piernas', 'brazos', 'movilidad'],
    'ex_plancha': ['rodillas', 'pared'],
    'ex_estirar': ['antes', 'despues'],
    'random_planeta': ['marte', 'luna'],
    'random_luna': ['fases', 'exploraciones'],
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
    'app_inicio': {
      'habitos': 'Para ver tus actividades, entra en Hábitos desde la navegación inferior. Allí aparecen las fichas y las herramientas de registro.',
      'progreso': 'En Progreso encontrarás un resumen de avances y estadísticas disponibles en tu cuenta; las cifras requieren conexión y permisos.',
      'tienda': 'La Tienda reúne recompensas virtuales que puedes revisar antes de comprar con Habit Coins.',
    },
    'app_habitos': {
      'agregar': 'Para agregar un hábito, abre Hábitos y busca el catálogo de actividades. Lee las condiciones antes de confirmarlo.',
      'registrar': 'Para registrar una actividad, abre un hábito que ya esté activo y usa su herramienta de registro. No inventes evidencia de una actividad.',
    },
    'app_registrar': {
      'contador': 'El contador sirve para marcar unidades o repeticiones si el hábito dispone de ese método. Confirma solo lo que hayas realizado.',
      'temporizador': 'El temporizador ayuda a medir sesiones basadas en tiempo. Puedes revisar el resultado antes de guardar el registro.',
      'fotografias': 'Si el registro admite fotografías, usa buena iluminación. Una etiqueta visual no demuestra por sí sola que completaste la actividad.',
    },
    'app_catalogo': {
      'alimentos': 'En Catálogo puedes buscar fichas de alimentos y revisar su descripción y datos disponibles. Comprueba las unidades antes de comparar.',
      'ejercicio': 'Las fichas de actividad del Catálogo ofrecen orientación general; adapta el ejercicio a tus capacidades y detente ante dolor.',
    },
    'app_misiones': {
      'diarias': 'Las misiones diarias se consultan en Desafíos. Revisa sus requisitos y el periodo de validez antes de reclamarlas.',
      'temporada': 'Los desafíos de temporada tienen metas y fechas propias. Consulta su estado en Desafíos para verificar si están disponibles.',
    },
    'food_plato': {
      'desayuno': 'Para desayunar puedes combinar avena, una fruta y alguna fuente de proteína que toleres. No necesitas una receta rígida.',
      'comida': 'Para la comida prueba combinar verduras, frijoles o lentejas y un cereal o tortilla, según tu apetito y presupuesto.',
      'cena': 'Para cenar considera una sopa de leguminosas con verduras o un plato sencillo de alimentos que te resulten cómodos.',
    },
    'food_colacion': {
      'sin refrigeracion': 'Una fruta entera o nueces, si no hay alergias, son opciones que pueden transportarse con facilidad y no requieren la misma conservación que un lácteo.',
      'en casa': 'En casa puedes preparar verduras con una salsa sencilla o yogur natural si lo toleras. No es obligatorio comer entre comidas.',
    },
    'food_carbo': {
      'integrales': 'Los cereales integrales suelen conservar más fibra. Revisa la etiqueta para saber qué ingredientes contiene realmente el producto.',
      'refinados': 'Los cereales refinados también aportan energía. Importan frecuencia, porciones y el conjunto de la alimentación, no una etiqueta de alimento prohibido.',
    },
    'food_verduras': {
      'comida': 'Puedes añadir verduras a arroz, frijoles o una tortilla. Elegir productos de temporada suele ayudar con el costo.',
      'sopa': 'Para una sopa sencilla, combina verduras bien lavadas y una leguminosa cocida; ajusta el sazón sin exceder la sal.',
    },
    'food_frutas': {
      'temporada': 'Las frutas de temporada suelen ser accesibles. Alterna variedades y prioriza fruta entera cuando te sea posible.',
      'para llevar': 'Para llevar elige una fruta entera lavada y protégela de golpes y contaminación durante el traslado.',
    },
    'ex_cardio': {
      'caminar': 'Caminar a ritmo cómodo es un comienzo accesible. Usa una ruta segura y progresa gradualmente.',
      'bicicleta': 'La bicicleta puede ayudarte con actividad aeróbica. Revisa frenos, usa protección adecuada y evita tráfico peligroso.',
      'baile': 'Bailar también cuenta como movimiento. Elige una canción y un ritmo que puedas mantener sin sentirte mal.',
    },
    'ex_sin_equipo': {
      'piernas': 'Para piernas puedes empezar sentándote y levantándote de una silla firme. Detente si aparece dolor.',
      'brazos': 'Para brazos puedes practicar empujes contra pared y controlar el movimiento sin forzar hombros ni muñecas.',
      'movilidad': 'Para movilidad prueba movimientos articulares suaves y pausas breves entre periodos de estar sentado.',
    },
    'ex_plancha': {
      'rodillas': 'Para empezar sobre rodillas, mantén una alineación cómoda y respira normalmente; termina ante dolor.',
      'pared': 'La variante contra pared permite entrenar estabilidad con menor carga. Apoya las manos en una superficie segura.',
    },
    'ex_estirar': {
      'antes': 'Antes de entrenar, haz un calentamiento con movimientos suaves relacionados con la actividad prevista.',
      'despues': 'Después del ejercicio puedes realizar estiramientos suaves sin rebotes ni molestias, si te resultan cómodos.',
    },
    'random_planeta': {
      'marte': 'Marte es un planeta rocoso conocido por su superficie rojiza y por sus exploraciones robóticas.',
      'luna': 'La Luna es el satélite natural de la Tierra; su exploración ayuda a entender la historia del Sistema Solar.',
    },
    'random_luna': {
      'fases': 'Las fases lunares dependen de cómo vemos desde la Tierra la parte iluminada por el Sol.',
      'exploraciones': 'Distintas misiones han estudiado la Luna con sondas, orbitadores y astronautas; podemos hablar de sus hallazgos generales.',
    },
  };

  /// Variantes editoriales para evitar repetir la misma recomendación.
  /// Se eligen de manera determinista por turno; no son contenido generado.
  static const Map<String, Map<String, String>> alternateResponses = {
    'food_desayuno': {
      'rapida': 'Otra variante rápida: pan integral con frijoles '
          'y fruta entera, según tus preferencias y disponibilidad.',
      'economica': 'Otra opción económica puede ser huevo bien cocido '
          'con tortilla y jitomate, si consumes huevo.',
      'sin lacteos': 'También puedes preparar una tortilla con '
          'frijoles y verduras, sin añadir leche ni queso.',
    },
    'food_cena': {
      'economica': 'Una segunda idea económica es arroz con '
          'frijoles cocidos y verduras disponibles.',
      'vegetariana': 'Otra alternativa vegetariana: verduras '
          'salteadas con tofu o lentejas bien cocidas.',
    },
    'food_almuerzo': {
      'para llevar': 'Otra opción para llevar son lentejas '
          'con arroz, bien refrigeradas hasta consumirlas.',
      'en casa': 'Prueba verduras de temporada con '
          'garbanzos y tortilla, según tu apetito.',
    },
    'food_plato': {
      'desayuno': 'Otra idea de desayuno: tostada con '
          'frijoles y verduras más una fruta de temporada.',
      'comida': 'Una segunda combinación es arroz, '
          'garbanzos cocidos y ensalada de verduras.',
      'cena': 'Una alternativa es sopa de verduras '
          'con lentejas y un acompañamiento sencillo.',
    },
    'ex_principiante': {
      'en casa': 'También puedes hacer movilidad suave '
          'de hombros y caminar en el sitio durante unos minutos.',
      'caminar': 'Otra posibilidad es dividir una caminata '
          'cómoda en dos recorridos cortos durante el día.',
    },
    'ex_fuerza': {
      'con equipo': 'Otra idea es practicar primero el '
          'movimiento sin carga y añadir una carga ligera '
          'cuando lo controles bien.',
      'sin equipo': 'Puedes alternar empujes contra pared '
          'con levantarte de una silla estable, sin dolor.',
    },
    'ex_cardio': {
      'caminar': 'También puedes caminar acompañado o '
          'cambiar de ruta para mantener el interés.',
      'bicicleta': 'En bicicleta, prueba un trayecto '
          'seguro y tranquilo antes de aumentar intensidad.',
      'baile': 'Prueba una sesión breve de baile '
          'a ritmo cómodo y descansa cuando lo necesites.',
    },
    'ex_sin_equipo': {
      'piernas': 'Puedes añadir pasos laterales suaves '
          'cerca de un apoyo firme.',
      'brazos': 'Otra variante es empujar suavemente '
          'contra una pared a ritmo controlado.',
      'movilidad': 'También puedes hacer círculos suaves '
          'de hombros y pausas frecuentes.',
    },
    'random_historia': {
      'misterio': 'El robot halló una segunda nota: '
          '«La clave está en la constelación apagada». '
          'Una sombra cruzó el invernadero.',
      'aventura': 'Desde el cohete divisaron una ciudad '
          'sobre las nubes. Una señal invitaba a aterrizar.',
    },
    'random_aburrido': {
      'adivinanza': 'Otra adivinanza: tengo agujas, '
          'pero no coso. ¿Qué soy?',
      'historia': 'Otra historia: un pequeño planeta '
          'cambió de color cuando llegó su primera lluvia.',
      'reto creativo': 'Otro reto: diseña una mascota '
          'para un planeta acuático y dale un nombre.',
    },
    'app_tienda': {
      'tema': 'Para cambiar de aspecto, revisa primero '
          'qué temas aparecen como adquiridos y cuáles siguen '
          'disponibles en Tienda.',
      'inventario': 'Abre tu Armario y revisa qué objetos '
          'puedes equipar sin volver a comprarlos.',
    },
    'app_cosmos': {
      'comprar': 'Otra forma de localizarlo es buscar '
          'la categoría Temas en la Tienda. La compra '
          'requiere saldo y confirmación.',
      'volver al anterior': 'Puedes quitar Cosmos sin '
          'borrar la compra y equiparlo de nuevo más adelante.',
    },
  };

  static const Map<String, List<String>> synonyms = {
    'rapida': ['rapida', 'rapido', 'facil', 'sencilla', 'sencillo'],
    'economica': ['economica', 'economico', 'economicas',
      'economicos', 'barata', 'barato', 'baratas', 'baratos',
      'poco dinero', 'bajo presupuesto'],
    'sin lacteos': ['sin lacteos', 'sin leche'],
    'vegetariana': ['vegetariana', 'vegetariano',
      'vegetarianas', 'vegetarianos', 'sin carne'],
    'para llevar': ['para llevar', 'llevar al trabajo'],
    'en casa': ['en casa', 'de casa', 'desde casa', 'casera'],
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
    'habitos': ['habitos', 'actividades'],
    'progreso': ['progreso', 'estadisticas'],
    'tienda': ['tienda'],
    'agregar': ['agregar', 'anadir', 'nuevo habito'],
    'registrar': ['registrar', 'guardar un registro'],
    'contador': ['contador', 'contar'],
    'temporizador': ['temporizador', 'cronometro'],
    'fotografias': ['fotografias', 'fotos', 'foto'],
    'alimentos': ['alimentos', 'alimentacion'],
    'ejercicio': ['ejercicio', 'actividad fisica'],
    'diarias': ['diarias', 'diaria'],
    'temporada': ['temporada', 'estacionales'],
    'desayuno': ['desayuno'],
    'comida': ['comida', 'almuerzo'],
    'cena': ['cena'],
    'sin refrigeracion': ['sin refrigeracion', 'sin refri', 'para llevar'],
    'integrales': ['integrales', 'integral'],
    'refinados': ['refinados', 'refinado'],
    'sopa': ['sopa'],
    'bicicleta': ['bicicleta', 'bici'],
    'baile': ['baile', 'bailar'],
    'piernas': ['piernas'],
    'brazos': ['brazos'],
    'movilidad': ['movilidad'],
    'rodillas': ['rodillas'],
    'pared': ['pared'],
    'antes': ['antes'],
    'despues': ['despues'],
    'marte': ['marte'],
    'luna': ['luna'],
    'fases': ['fases'],
    'exploraciones': ['exploraciones', 'exploracion'],
  };

  static int _offeredPosition(String priorReply, String choice) {
    // Consider only the last proposal, not incidental words in the
    // explanation that preceded it. This preserves ordinal order.
    final proposal = priorReply.trim().split(RegExp(r'\n\s*\n')).last;
    final reply = _normalize(proposal);
    final candidates = synonyms[choice] ?? [choice];
    var position = -1;
    for (final candidate in candidates) {
      final index = (' $reply ').indexOf(' ${_normalize(candidate)} ');
      if (index >= 0 && (position < 0 || index < position)) {
        position = index;
      }
    }
    return position;
  }

  static bool _offered(String priorReply, List<String> available) {
    if (priorReply.trim().isEmpty) return false;
    // At least two alternatives must be present in the latest proposal.
    // A lone incidental word (for example "comida") is not a menu.
    return available.where((choice) =>
        _offeredPosition(priorReply, choice) >= 0).length >= 2;
  }

  static bool isOrdinalSelection(String text) =>
      _ordinal(_normalize(text)) != null;

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
    int turnIndex = 0,
  }) {
    final options = choices[topicId];
    if (options == null || previousAssistantText.trim().isEmpty) return null;
    final q = _normalize(input);
    if (q.isEmpty || _sensitive.hasMatch(q)) return null;

    final eligible = _offered(previousAssistantText, options);
    if (!eligible) return null;

    String? option;
    final ordinal = _ordinal(q);
    if (ordinal != null) {
      // An ordinal is valid only if the previous reply enumerated options
      // in the same order; do not invent an implicit list.
      final positions = options.map((choice) =>
          _offeredPosition(previousAssistantText, choice)).toList();
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
    final primary = responses[topicId]?[option];
    if (primary == null) return null;
    final alternative = alternateResponses[topicId]?[option];
    final text = turnIndex.isOdd && alternative != null
        ? alternative : primary;
    final closing = turnIndex % 3 == 2
        ? '¿Te gustaría probar una alternativa diferente? '
            'Opciones: ${options.join(', ')}.'
        : turnIndex % 3 == 1
            ? 'Si quieres, seguimos con ${options.join(', ')}. '
                '¿Cuál te interesa?'
            : 'Puedes elegir otra opción: '
                '${options.join(', ')}. ¿Cuál prefieres?';
    return HealthyAssistantReply(
      '$text\n\n$closing',
      card: 'topic', actionArgument: topicId, knowledgeId: topicId,
    );
  }
}
