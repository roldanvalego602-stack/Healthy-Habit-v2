import 'nutri_respuestas_service.dart';

/// Conversación local de propósito general y de bajo riesgo.
///
/// Intenciones verificables (compras, hábitos, métricas, profesionales) se
/// resuelven antes mediante HealthyAssistantEngine. Aquí no se inventan
/// cifras, personas, vivencias ni acceso a datos ajenos.
class HealthyConversationService {
  const HealthyConversationService();

  /// Continúa solo elecciones explícitamente ofrecidas en el turno anterior.
  /// No intenta resolver órdenes, diagnósticos ni información de cuenta.
  static String? _continueLastChoice(String input, String assistant) {
    final clean = input.trim();
    if (clean.length > 65 || assistant.isEmpty) return null;
    final q = clean.replaceAll(RegExp(r'[¿?!¡.,;:]'), '').trim();

    final storyOffered = assistant.contains('misterio o aventura');
    if (storyOffered && (q == 'misterio' || q == 'aventura' ||
        q == 'la primera' || q == 'la segunda')) {
      if (q == 'misterio' || q == 'la primera') {
        return 'La semilla abrió el libro y encontró una página en blanco. '
            'Al tocarla, apareció un mapa con una huella que se movía sola. '
            'El rastro terminaba detrás de una puerta que nadie recordaba haber construido. '
            '¿Quieres que investiguemos la puerta?';
      }
      return 'La semilla siguió un sendero de luciérnagas hasta un puente '
          'sobre el río de las nubes. Allí encontró una brújula que '
          'señalaba los lugares donde aún quedaban historias por contar. '
          '¿Continuamos el viaje?';
    }

    final offeredActivities = assistant.contains('un acertijo') &&
        assistant.contains('historia') && assistant.contains('juego de palabras');
    if (offeredActivities && (q == 'acertijo' || q == 'historia' ||
        q == 'juego de palabras')) {
      if (q == 'acertijo') {
        return 'Aquí tienes uno: cuanto más me quitas, más grande me hago. '
            '¿Qué soy? (Pista: puedes encontrarme en el suelo).';
      }
      if (q == 'historia') {
        return 'Un día, una pequeña semilla encontró una llave bajo la lluvia. '
            'La probó en una puerta diminuta entre las raíces y descubrió '
            'una biblioteca de árboles. ¿Misterio o aventura?';
      }
      return 'Juguemos a encadenar palabras: yo digo «semilla». '
          'Responde con una palabra que empiece por la última letra: «a».';
    }

    final offeredRiddle = assistant.contains('cuanto mas me quitas') &&
        assistant.contains('pista');
    if (offeredRiddle && const {
      'me rindo', 'dame la respuesta', 'cual es la respuesta', 'no se',
      'no lo se', 'un agujero', 'agujero',
    }.contains(q)) {
      if (q == 'agujero' || q == 'un agujero') {
        return '¡Correcto! Es un agujero. ¿Quieres intentar otro acertijo?';
      }
      return 'La respuesta es un agujero: cuanto más tierra sacas, '
          'más grande se vuelve. ¿Quieres otro acertijo?';
    }

    final investigating = assistant.contains('investiguemos la puerta') ||
        assistant.contains('investigamos la puerta');
    if (investigating && const {
      'si', 'claro', 'investiguemos', 'abramos la puerta', 'continuar',
    }.contains(q)) {
      return 'Detrás de la puerta había un reloj sin agujas. '
          'Cada vez que la semilla pronunciaba una palabra, '
          'una nueva habitación aparecía entre las raíces. '
          'En el suelo encontró dos pistas: una llave y una carta. '
          '¿Cuál investigamos?';
    }
    if (assistant.contains('continuamos el viaje') &&
        const {'si', 'claro', 'continuemos', 'vamos', 'seguir'}.contains(q)) {
      return 'La brújula los guió hasta un jardín suspendido. '
          'En el centro había una escalera hecha de hojas. '
          'La semilla podía subir hacia el cielo o explorar '
          'las cuevas bajo el jardín. ¿Qué ruta prefieres?';
    }

    final offeredEmotion = assistant.contains('que ocurrio') &&
        assistant.contains('distraerte un rato');
    if (offeredEmotion && (q == 'distraerme' || q == 'distraerme un rato')) {
      return 'Podemos cambiar de ritmo. ¿Prefieres un acertijo, '
          'una historia breve o un juego de palabras?';
    }
    return null;
  }

  /// Interpreta correcciones explícitas únicamente sobre actividades
  /// ofrecidas en la conversación general. Nunca reutiliza este contexto
  /// para compras, operaciones, tratamientos ni datos del perfil.
  static String? _correctRecentChoice(
    String input, String previousUser, String assistant,
  ) {
    if (input.length > 75 || assistant.isEmpty) return null;
    // Una corrección mezclada con instrucciones operativas o clínicas
    // debe pasar a los módulos especializados, nunca a una historia.
    if (RegExp(
      r'\b(borra|borrar|elimina|eliminar|compra|comprar|'
      r'cuenta|perfil|saldo|monedas|habito|habitos|'
      r'dosis|medicamento|diagnostico|tratamiento)\b',
    ).hasMatch(input)) return null;
    final q = input.replaceAll(RegExp(r'[¿?!¡.,;:]'), '').trim();
    final correction = RegExp(
      r'^(no|mejor|perdon|perdon me referia a|no queria|'
      r'no me referia a|queria decir)\b',
    ).hasMatch(q);
    if (!correction) return null;

    final wantsAdventure = RegExp(r'\baventura\b').hasMatch(q);
    final wantsMystery = RegExp(r'\bmisterio\b').hasMatch(q);
    final mysteryScene = assistant.contains('huella que se movia sola');
    final adventureScene = assistant.contains('rio de las nubes');

    if (wantsAdventure && !wantsMystery && mysteryScene &&
        (previousUser == 'misterio' || previousUser == 'la primera')) {
      return 'De acuerdo, cambiamos a aventura. '
          'La semilla siguió un sendero de luciérnagas hasta un puente '
          'sobre el río de las nubes. Allí encontró una brújula que '
          'señalaba lugares por descubrir. ¿Continuamos el viaje?';
    }
    if (wantsMystery && !wantsAdventure && adventureScene &&
        (previousUser == 'aventura' || previousUser == 'la segunda')) {
      return 'De acuerdo, cambiamos a misterio. '
          'La semilla abrió el libro y encontró una página en blanco. '
          'Al tocarla apareció una huella que se movía sola hacia '
          'una puerta olvidada. ¿Investigamos la puerta?';
    }

    if (const {
      'no', 'no era eso', 'no me referia a eso', 'me entendiste mal',
      'eso no era lo que queria', 'no queria eso',
    }.contains(q)) {
      return 'Entiendo que interpreté mal tu mensaje. '
          '¿Qué quisiste decir o qué parte debo cambiar? '
          'No haré suposiciones.';
    }
    return null;
  }

  static bool _has(String input, List<String> phrases) =>
      NutriRespuestasService.contiene(input, phrases);

  String? reply(
    String input, {
    String name = '',
    String previousUserMessage = '',
    String previousAssistantText = '',
  }) {
    final t = NutriRespuestasService.normalizar(input)
        .replaceAll(RegExp(r'[¿?!¡.,;:]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final previous = NutriRespuestasService.normalizar(previousUserMessage);
    final assistant = NutriRespuestasService.normalizar(previousAssistantText)
        .replaceAll(RegExp(r'[¿?!¡.,;:]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (t.isEmpty) return null;
    final greeting = name.trim().isEmpty ? '' : ', ${name.trim()}';
    // Continuaciones inequívocas: exige una invitación concreta en la
    // respuesta anterior, no infiere temas de conversaciones remotas.
    final correction = _correctRecentChoice(t, previous, assistant);
    if (correction != null) return correction;
    final continuation = _continueLastChoice(t, assistant);
    if (continuation != null) return continuation;


    // Pista narrativa opcional. Nunca abre recompensas, ni revela
    // la contraseña del santuario, ni invoca Cloud Functions.
    if (RegExp(
      r'\b(santuario|prisionero|titan|cueva secreta|siete latidos|'
      r'leyenda del titan)\b',
    ).hasMatch(t)) {
      return 'Hay una leyenda en Healthy Habit: un guardián muy fuerte '
          'duerme detrás de barrotes antiguos. Dicen que la entrada '
          'está cerca del lugar donde cuentas tus monedas, '
          'pero que ningún tesoro puede comprar la llave. '
          'El corazón de la puerta escucha siete latidos '
          'antes de cerrar los ojos. ¿Te atreves a investigar?';
    }

    // Identidad, fantasía y preguntas juguetonas: responder sin adjudicar
    // identidades personales que la app no puede conocer.
    if (_has(t, ['soy una princesa', 'soy princesa', 'soy un principe',
        'soy principe', 'soy una reina', 'soy un rey'])) {
      return 'Si lo dices en plan de juego: ¡por supuesto que podemos '
          'hablar como en un cuento! 👑 Si preguntas literalmente, no tengo '
          'cómo comprobar títulos reales. ¿Quieres que te invente una '
          'aventura de reinos o prefieres una conversación normal?';
    }
    if (_has(t, ['hablame sobre ti','cuentame sobre ti','dime sobre ti',
        'presentate','quien eres en realidad','que personalidad tienes',
        'como eres','que te gusta hacer'])) {
      return 'Soy Mr. Healthy 🌱, el asistente de Healthy Habit. '
          'Me gusta conversar, explicar conceptos, contar historias breves '
          'y ayudarte a revisar tus hábitos, retos y estadísticas. '
          'Soy un programa, no una persona: no tengo una vida fuera de '
          'esta aplicación ni recuerdos independientes de tus chats. '
          '¿Quieres conocer lo que puedo hacer o prefieres charlar?';
    }
    if (_has(t, ['eres humano','eres un robot','eres un bot',
        'tienes sentimientos','tienes emociones','tienes conciencia',
        'estas vivo','eres inteligente','quien te creo'])) {
      return 'Soy un asistente de software de Healthy Habit. '
          'Puedo interpretar varias preguntas y usar funciones de la app, '
          'pero no soy humano ni tengo experiencias personales. '
          'Podemos conversar sin fingir que tengo una vida propia. 🌿';
    }
    if (_has(t, ['como estas','como te sientes','como va tu dia',
        'estas bien','que tal estas'])) {
      return '¡Listo para ayudarte$greeting! No tengo días buenos o malos '
          'como una persona, pero me alegra poder acompañar la conversación. '
          '¿Cómo te ha ido a ti?';
    }
    if (_has(t, ['me gustas','te quiero','te amo','quieres ser mi amigo',
        'somos amigos','eres mi amigo','quieres ser mi novia',
        'quieres ser mi novio'])) {
      return 'Aprecio el tono de cariño 🌱. Puedo acompañarte a conversar '
          'y apoyarte con ideas, aunque soy un asistente y no puedo '
          'tener una relación humana. ¿De qué te gustaría platicar?';
    }
    if (_has(t, ['estoy feliz','estoy contento','estoy contenta',
        'estoy emocionado','estoy emocionada','me fue bien',
        'lo logre','estoy orgulloso','estoy orgullosa'])) {
      return '¡Qué buena noticia! 🌿 ¿Qué pasó? '
          'Me interesa saber qué parte te hizo sentir así.';
    }
    if (_has(t, ['estoy triste','estoy solo','estoy sola','me siento solo',
        'me siento sola','no me siento bien','tuve un mal dia',
        'estoy frustrado','estoy frustrada'])) {
      return 'Lamento que estés pasando por un momento pesado. '
          'Podemos hablar sin convertirlo todo en una tarea o un hábito. '
          '¿Te gustaría contarme qué ocurrió o prefieres distraerte un rato?';
    }
    if (_has(t, ['estoy aburrido','estoy aburrida','me aburro',
        'estoy aburrida','quiero distraerme','que hacemos'])) {
      return 'Podemos hacer algo diferente: un acertijo, una historia '
          'de tres decisiones, preguntas curiosas o un juego de palabras. '
          '¿Qué te apetece?';
    }
    if (_has(t, ['cuentame un cuento','cuentame una historia',
        'inventame una historia','una historia corta','haz una historia'])) {
      return 'Un día, una pequeña semilla encontró una llave bajo la lluvia. '
          'La probó en una puerta diminuta entre las raíces y descubrió '
          'una biblioteca de árboles que guardaban recuerdos del viento. '
          'Solo faltaba abrir el libro con su nombre… '
          '¿Quieres que el siguiente capítulo sea misterio o aventura?';
    }
    if (_has(t, ['dime un acertijo','hazme un acertijo','adivinanza',
        'ponme un acertijo'])) {
      return 'Aquí tienes uno: cuanto más me quitas, más grande me hago. '
          '¿Qué soy? (Pista: puedes encontrarme en el suelo).';
    }
    if (_has(t, ['que soy','dame la respuesta','cual es la respuesta',
        'me rindo'])) {
      if (_has(previous, ['acertijo','adivinanza']) ||
          _has(previous, ['cuanto mas me quitas'])) {
        return '¡Era un agujero! 🕳️ ¿Quieres otro acertijo?';
      }
    }
    if (_has(t, ['otro chiste','otro mas','uno mas','otro cuento','otro acertijo'])) {
      if (_has(previous, ['chiste','broma'])) {
        return '¿Por qué el tomate siempre llegaba tarde? '
            '¡Porque se quedaba hecho puré con el tráfico! 🍅';
      }
      if (_has(previous, ['cuento','historia'])) {
        return 'En una ciudad sin relojes, una luciérnaga empezó a '
            'encenderse cada noche a la misma hora. Alguien descubrió '
            'que estaba esperando una carta perdida. ¿Quién la escribió?';
      }
      return '¿Prefieres otro chiste, una historia o un acertijo?';
    }
    if (_has(t, ['que piensas de mi','como me ves','que opinas de mi',
        'como soy yo','me conoces'])) {
      return 'Solo conozco lo que has compartido aquí y los datos que '
          'la aplicación me permite consultar. No puedo describir tu '
          'personalidad con certeza, pero puedo ayudarte a reflexionar. '
          '¿Qué aspecto de ti quieres explorar?';
    }
    if (_has(t, ['cual es tu color favorito','tu comida favorita',
        'que musica te gusta','tienes un favorito','cual es tu favorito'])) {
      return 'No tengo gustos propios, pero si estuviera eligiendo un '
          'color para mi personaje, sería verde esmeralda 🌿. '
          '¿Qué elegirías tú?';
    }
    if (_has(t, ['dime algo curioso','dato curioso','sorprendeme',
        'algo interesante','sabias que'])) {
      return 'Dato curioso: algunas semillas pueden permanecer inactivas '
          'durante largos periodos antes de germinar cuando encuentran '
          'condiciones adecuadas. La biología tiene historias increíbles. '
          '¿Quieres otra curiosidad o un acertijo?';
    }
    if (_has(t, ['hablame de tus limites','que no puedes hacer',
        'puedes hablar de cualquier cosa','sabes de todo'])) {
      return 'Puedo charlar sobre muchos temas frecuentes y ayudarte '
          'con funciones de Healthy Habit. Sin embargo, mis respuestas '
          'son programadas: no razono libremente sobre cualquier tema '
          'como un modelo de lenguaje conectado, ni tengo Internet '
          'general. Para preguntas sin datos fiables, lo indicaré.';
    }
    if (_has(t, ['hola de nuevo','aqui estoy de nuevo','regrese','volvi'])) {
      return '¡Bienvenido de nuevo$greeting! ¿Seguimos con lo anterior '
          'o quieres hablar de otra cosa?';
    }
    if (_has(t, ['me equivoque','era broma','solo bromeaba',
        'lo decia de broma'])) {
      return 'Entendido 😄. Podemos seguir la broma o cambiar de tema. '
          '¿Qué prefieres?';
    }
    if (_has(t, ['no se','no lo se','no tengo idea','no estoy seguro',
        'no estoy segura'])) {
      return 'Está bien no tener una respuesta todavía. '
          'Podemos explorar dos o tres posibilidades y comparar. '
          '¿Qué decisión o pregunta tienes en mente?';
    }
    if (_has(t, ['por que existes','para que sirves','cual es tu proposito',
        'cual es tu objetivo'])) {
      return 'Mi función es ayudarte a construir hábitos sostenibles '
          'y acompañar el uso de Healthy Habit. También puedo charlar '
          'un poco para que la experiencia sea más natural, sin '
          'presentarme como un profesional ni inventar datos.';
    }
    if (_has(t, ['me ayudas a decidir','necesito decidir',
        'no se que elegir','que hago con mi vida'])) {
      return 'Podemos ordenarlo. Dime las opciones que estás considerando '
          'y qué te importa más: tiempo, dinero, tranquilidad o resultados. '
          'No voy a decidir por ti, pero sí a comparar los pros y contras.';
    }
    if (_has(t, ['que opinas','que piensas','tu opinion',
        'que harias tu'])) {
      return 'Puedo ayudarte a comparar argumentos, aunque no tenga '
          'opiniones vividas. ¿Sobre qué tema o decisión quieres '
          'que razonemos?';
    }

    // Conocimientos generales intemporales, sin inventar datos actuales.
    // Se responde solo a conceptos presentes en este pequeño glosario.
    if (_has(t, ['que es', 'que significa', 'explicame', 'hablame de',
        'como funciona', 'para que sirve', 'definicion de'])) {
      const concepts = <String, String>{
        'fotosintesis': 'La fotosíntesis es el proceso mediante el cual '
          'plantas, algas y algunos microorganismos convierten la energía '
          'de la luz en energía química. Usan agua y dióxido de carbono, '
          'y muchas de estas rutas liberan oxígeno.',
        'algoritmo': 'Un algoritmo es una secuencia finita de instrucciones '
          'para resolver un problema o realizar una tarea. '
          'Puede describirse con pasos, diagramas o código.',
        'programacion': 'Programar consiste en diseñar instrucciones '
          'para que una computadora realice tareas. '
          'Implica comprender un problema, escribir código, '
          'probarlo y corregir errores.',
        'inteligencia artificial': 'La inteligencia artificial es un '
          'campo de la informática que desarrolla sistemas capaces '
          'de realizar tareas como reconocer patrones, generar texto '
          'y apoyar decisiones. Sus resultados pueden equivocarse.',
        'flutter': 'Flutter es un framework de Google para construir '
          'interfaces y aplicaciones a partir de una base de código '
          'principalmente escrita en Dart. Healthy Habit utiliza Flutter.',
        'firebase': 'Firebase es una plataforma de desarrollo de '
          'aplicaciones que ofrece servicios como autenticación, '
          'almacenamiento, bases de datos y funciones en la nube. '
          'Healthy Habit utiliza varios de esos servicios.',
        'base de datos': 'Una base de datos organiza información para '
          'consultarla y actualizarla. Firestore es una base de datos '
          'de documentos utilizada en Healthy Habit.',
        'sistema solar': 'El Sistema Solar incluye al Sol y los cuerpos '
          'que orbitan a su alrededor: planetas, lunas, asteroides '
          'y cometas, entre otros.',
        'galaxia': 'Una galaxia es un conjunto gravitacional de '
          'estrellas, gas, polvo y otros componentes. '
          'La Vía Láctea es la galaxia donde se encuentra el Sol.',
        'marte': 'Marte es el cuarto planeta desde el Sol. '
          'Es rocoso y tiene una atmósfera muy delgada, '
          'compuesta principalmente por dióxido de carbono.',
        'adn': 'El ADN es una molécula que almacena información '
          'genética en muchos organismos. Su secuencia participa '
          'en la transmisión de características biológicas.',
        'proteina': 'Las proteínas son moléculas formadas por '
          'aminoácidos que cumplen funciones estructurales, '
          'enzimáticas y de regulación en los seres vivos.',
        'habito': 'Un hábito es un comportamiento que se vuelve '
          'más automático mediante repetición y señales del '
          'entorno. Para construir uno conviene empezar con '
          'acciones pequeñas y fáciles de repetir.',
        'estres': 'El estrés es una respuesta del organismo ante '
          'demandas o amenazas percibidas. Puede ser temporal; '
          'si es intenso o persistente, buscar apoyo profesional '
          'puede ser útil.',
      };
      for (final entry in concepts.entries) {
        if (_has(t, [entry.key])) {
          return '${entry.value} ¿Quieres un ejemplo sencillo '
              'o prefieres profundizar en alguna parte?';
        }
      }
    }

    return null;
  }
}
