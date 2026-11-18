import 'dart:math';

/// Respuestas locales y transparentes: no consulta Internet ni inventa datos.
class NutriRespuestasService {
  final Random _random = Random();
  int _ultimoConsejo = -1;
  int _ultimoFallback = -1;

  static String normalizar(String text) =>
      text
          .toLowerCase()
          .replaceAll('á', 'a')
          .replaceAll('é', 'e')
          .replaceAll('í', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ú', 'u')
          .replaceAll('ü', 'u')
          .replaceAll('ñ', 'n')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  static bool contiene(String input, List<String> terms) {
    final text = normalizar(input);
    return terms.any((term) {
      final key = normalizar(term);
      return RegExp(
        r'(^|[^a-z0-9])' + RegExp.escape(key) + r'($|[^a-z0-9])',
      ).hasMatch(text);
    });
  }

  /// Coincidencia de palabras completas: evita bloquear palabras inocentes.
  static bool tieneGroserias(String input) => contiene(input, const [
    'puta',
    'puto',
    'putas',
    'putos',
    'pendejo',
    'pendeja',
    'pendejos',
    'pendejas',
    'cabron',
    'cabrona',
    'cabrones',
    'chingada',
    'chingado',
    'chingar',
    'chingas',
    'chingate',
    'verga',
    'mierda',
    'culero',
    'culera',
    'idiota',
    'imbecil',
    'estupido',
    'estupida',
    'joder',
    'fuck',
    'shit',
    'bitch',
    'motherfucker',
  ]);

  String moderar(String input, String nombre) {
    final personal = nombre.isEmpty ? '' : ', $nombre';
    if (contiene(input, [
      'suicidio',
      'suicidarme',
      'matarme',
      'hacerme dano',
      'autolesion',
    ])) {
      return 'Me preocupa que puedas estar pasando por algo difícil$personal. '
          'Si estás en peligro inmediato, llama a emergencias de tu zona o '
          'busca a una persona de confianza que pueda acompañarte ahora. '
          '¿Estás a salvo en este momento?';
    }
    return 'Oye$personal, podemos hablar de lo que te molesta sin groserías 🙂. '
        'No te voy a regañar, pero prefiero que nos tratemos con respeto. '
        'Cuéntame qué pasó o qué necesitas y lo resolvemos juntos.';
  }

  String _elegir(List<String> respuestas, {bool fallback = false}) {
    if (respuestas.length == 1) return respuestas.first;
    int i = _random.nextInt(respuestas.length);
    final previous = fallback ? _ultimoFallback : _ultimoConsejo;
    if (i == previous) i = (i + 1) % respuestas.length;
    if (fallback) {
      _ultimoFallback = i;
    } else {
      _ultimoConsejo = i;
    }
    return respuestas[i];
  }

  String responder(
    String input, {
    required String nombre,
    required Map<String, dynamic> perfil,
  }) {
    final text = normalizar(input);
    final saludo = nombre.isEmpty ? '' : ', $nombre';
    final now = DateTime.now();
    final hora =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final momento =
        now.hour < 12
            ? 'mañana'
            : now.hour < 19
            ? 'tarde'
            : 'noche';

    if (contiene(text, [
      'hola',
      'buenas',
      'buenos dias',
      'buenas tardes',
      'buenas noches',
      'hey',
      'holi',
    ])) {
      return _elegir([
        '¡Hola$saludo! 🌱 ¿Hoy vamos por una victoria pequeña o por una gran misión?',
        '¡Qué gusto verte$saludo! Mi superpoder es ayudarte a empezar con algo sencillo. ¿Hábitos, perfil o curiosidades?',
        '¡Buenas! Mr. Healthy reportándose 🫡. ¿Cómo va tu $momento?',
      ]);
    }
    if (contiene(text, [
      'que hora es',
      'dime la hora',
      'hora actual',
      'que horas son',
      'hora del dia',
    ])) {
      return 'En la hora local de este dispositivo son las $hora. '
          'Es $momento: ${now.hour < 12
              ? 'un buen momento para organizar tu primer hábito.'
              : now.hour < 19
              ? 'todavía puedes registrar un pequeño avance.'
              : 'si ya terminaste tus pendientes, prepara una rutina tranquila para mañana.'} '
          'No estoy consultando un reloj de otra ciudad.';
    }
    if (contiene(text, [
      'que dia es',
      'fecha de hoy',
      'que fecha es',
      'hoy que dia',
    ])) {
      const dias = [
        'lunes',
        'martes',
        'miércoles',
        'jueves',
        'viernes',
        'sábado',
        'domingo',
      ];
      const meses = [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre',
      ];
      return 'Hoy es ${dias[now.weekday - 1]} ${now.day} de ${meses[now.month - 1]} de ${now.year}, según tu dispositivo. 📅 ¿Quieres que planeemos un hábito para hoy?';
    }
    if (contiene(text, [
      'clima',
      'temperatura',
      'va a llover',
      'lluvia',
      'pronostico',
      'tiempo afuera',
    ])) {
      return 'Me encantaría decirte si necesitas paraguas ☂️, pero no tengo acceso a datos meteorológicos en vivo ni a tu ubicación. '
          'Consulta el pronóstico de tu ciudad en una app del clima. Si hace calor, recuerda beber agua; si llueve, podemos elegir un hábito para interiores.';
    }
    if (contiene(text, [
      'quien eres',
      'que eres',
      'eres una ia',
      'como te llamas',
      'eres real',
    ])) {
      return 'Soy Mr. Healthy, el asistente de Healthy Habit 🌿. No soy una persona ni un profesional médico. '
          'Puedo conversar con respuestas programadas, ayudarte a explorar tus datos de perfil y hacer cálculos orientativos de IMC y GET. '
          'No tengo acceso libre a Internet ni conozco todo lo que pasa en el mundo.';
    }
    if (contiene(text, [
      'quien es',
      'quien fue',
      'hablame de',
      'conoces a',
      'sobre personas',
      'sobre una persona',
    ])) {
      return '¡Modo detective curioso activado! 🔎 Puedo hablar de personajes históricos o figuras públicas con información general, '
          'pero no tengo una enciclopedia actualizada ni acceso a información privada de personas. '
          'Dime el nombre y qué te interesa (trayectoria, logros o contexto); si no tengo datos fiables, te lo diré en vez de inventarlos.';
    }
    if (contiene(text, [
      'mi perfil',
      'mis datos',
      'mis estadisticas',
      'cuantas monedas',
      'habit coins',
      'mi nivel',
      'cuanta xp',
      'mi xp',
      'mi racha',
      'mi nombre',
      'mi usuario',
    ])) {
      final datos = <String>[];
      final n = perfil['name'];
      final username = perfil['username'];
      final level = perfil['level'];
      final xp = perfil['xp'];
      final coins = perfil['habitCoins'];
      final streak = perfil['currentStreak'];
      if (n is String && n.trim().isNotEmpty) datos.add('Nombre: ${n.trim()}');
      if (username is String && username.trim().isNotEmpty) {
        datos.add(
          'Usuario: @${username.trim().replaceFirst(RegExp(r'^@+'), '')}',
        );
      }
      if (level is num) datos.add('Nivel: ${level.toInt()}');
      if (xp is num) datos.add('XP: ${xp.toInt()}');
      if (coins is num) datos.add('Habit Coins: ${coins.toInt()}');
      if (streak is num) datos.add('Racha registrada: ${streak.toInt()} días');
      if (datos.isEmpty) {
        return 'No pude consultar tus estadísticas de perfil ahora mismo. Comprueba tu conexión y vuelve a intentarlo. No quiero inventarte monedas ni XP.';
      }
      return '¡Aquí va tu tarjeta de progreso$saludo! 📊\n\n${datos.join('\n')}\n\nEstos son los valores guardados en tu perfil, no una estimación. ¿Quieres una idea para seguir avanzando?';
    }
    if (contiene(text, ['mision', 'desafio', 'reto de hoy', 'misiones'])) {
      return 'Las misiones y desafíos pueden cambiar según tus registros. No tengo aquí una consulta fiable del desafío activo, '
          'así que no te inventaré uno. Abre Hábitos o Desafíos para ver el progreso actualizado. '
          'Si me dices qué misión elegiste, puedo ayudarte a dividirla en pasos.';
    }
    if (contiene(text, ['racha', 'constancia', 'no perder mi racha'])) {
      final streak = perfil['currentStreak'];
      final intro =
          streak is num
              ? 'Tu racha registrada es de ${streak.toInt()} días. '
              : '';
      return '${intro}Mi truco favorito: elige un hábito mínimo que puedas cumplir incluso en un día complicado. '
          'Por ejemplo, dejar preparada tu botella de agua o caminar cinco minutos. '
          'Registra el hábito en la app; lo que cuenta es construir continuidad, no perfección. 🌱';
    }
    if (contiene(text, [
      'sugerir habitos',
      'sugiere habitos',
      'recomienda habitos',
      'que habito',
      'nuevo habito',
      'consejo',
      'ideas de habitos',
      'habitos',
    ])) {
      final ideas = [
        '💧 Hidratación: deja un vaso o botella a la vista y bebe agua al comenzar tu mañana.',
        '🥗 Alimentación: añade una fruta o verdura a una comida que ya haces todos los días.',
        '🚶 Energía: haz una caminata breve o levántate a estirarte entre actividades.',
        '🧘 Bienestar: reserva cinco minutos para respirar, descansar de pantallas o escribir cómo te sientes.',
        '🌙 Descanso: prepara una rutina corta sin pantallas antes de dormir.',
        '📓 Organización: anota una sola prioridad para mañana antes de terminar el día.',
      ];
      final pick = _elegir(ideas);
      return 'Te propongo un experimento de 3 días$saludo:\n\n$pick\n\nEmpieza fácil, registra tu avance y después aumenta la dificultad si te funciona. ¿Prefieres Alimentación, Hidratación, Energía o Bienestar?';
    }
    if (contiene(text, ['hidratacion', 'agua', 'sed'])) {
      return '💧 Truco práctico: vincula beber agua con algo que ya haces, como desayunar o tomar un descanso. '
          'La cantidad adecuada depende de tu contexto y salud; no existe una cifra universal para todas las personas. '
          '¿Te cuesta recordarlo o mantener la constancia?';
    }
    if (contiene(text, [
      'alimentacion',
      'comida',
      'nutricion',
      'desayuno',
      'cenar',
    ])) {
      return '🥑 Para empezar sin complicarte, piensa en variedad y regularidad, no en dietas extremas. '
          'Puedes probar añadir un alimento fresco a una comida habitual. '
          'Si necesitas un plan individual por salud, consulta a un profesional de nutrición.';
    }
    if (contiene(text, [
      'ejercicio',
      'caminar',
      'energia',
      'actividad fisica',
    ])) {
      return '⚡ No necesitas empezar con una rutina gigante. Prueba una actividad cómoda y progresiva: '
          'unos minutos de caminata, movilidad o estiramientos. Ajusta el esfuerzo a tus capacidades y evita forzarte si sientes dolor.';
    }
    if (contiene(text, ['dormir', 'sueno', 'descanso', 'insomnio'])) {
      return '🌙 Una rutina de descanso puede comenzar con una hora de acostarte relativamente estable, menos pantallas al final del día y un ambiente tranquilo. '
          'Si el problema de sueño persiste, merece una valoración profesional.';
    }
    if (contiene(text, [
      'estres',
      'ansiedad',
      'triste',
      'mal dia',
      'desanimado',
      'motivacion',
    ])) {
      return 'Siento que hoy puede estar pesado$saludo. 💚 No tienes que convertir cada día en una hazaña. '
          'Elige algo pequeño y alcanzable, como respirar lentamente un momento o salir a tomar aire. '
          'Si el malestar es intenso o persistente, hablar con alguien de confianza o un profesional puede ayudar. ¿Quieres contarme qué te preocupa?';
    }
    if (contiene(text, [
      'profesional',
      'nutriologo',
      'nutriologa',
      'medico',
      'psicologo',
    ])) {
      return 'En Orientación profesional de Healthy Habit puedes encontrar los canales de contacto disponibles. '
          'Revisa que los datos estén actualizados antes de llamar o escribir. Yo puedo dar información general, pero no sustituir una consulta.';
    }
    if (contiene(text, [
      'tienda',
      'armario',
      'comprar',
      'canjear',
      'recompensas',
    ])) {
      return '🛍️ Las Habit Coins sirven para canjear recompensas en la Tienda. '
          'En Armario puedes equipar los accesorios que ya adquiriste. '
          'Las compras se guardan en tu cuenta; si no ves una, revisa la conexión antes de volver a comprar.';
    }
    if (contiene(text, ['gracias', 'muchas gracias', 'te agradezco'])) {
      return _elegir([
        '¡Para eso estoy$saludo! 🌿 Un hábito a la vez.',
        '¡Con gusto! Hoy sumamos un granito de progreso. ✨',
        '¡De nada! Si necesitas otra idea, aquí sigo con mis hojas bien puestas. 🍃',
      ]);
    }
    if (contiene(text, ['chiste', 'algo divertido', 'hazme reir', 'broma'])) {
      return _elegir([
        '¿Por qué la botella de agua era tan popular? ¡Porque siempre estaba en su elemento! 💧😄',
        'Intenté correr una maratón… pero soy una hoja y el viento me llevó primero. 🍃',
        'Mi entrenador me dijo que diera pequeños pasos. Como soy planta, empecé por echar raíces. 🌱',
      ]);
    }
    if (contiene(text, ['puedes', 'sabes', 'ayuda', 'que haces', 'opciones'])) {
      return 'Puedo ayudarte con tu perfil, XP, Habit Coins y racha; sugerirte hábitos; explicar la Tienda; '
          'conversar sobre bienestar y calcular IMC o GET. También sé la fecha y hora del dispositivo. '
          'Para clima en vivo o noticias necesitaría una fuente externa. ¿Qué te interesa hoy?';
    }
    return _elegir([
      'Buena pregunta$saludo. No tengo una respuesta verificada para ese tema y prefiero no inventarla. '
          'Si me das un poco de contexto, puedo ayudarte a razonarla o relacionarla con tus objetivos.',
      'Me dejaste pensando 🤔. Mi conocimiento aquí es limitado: no consulto Internet en tiempo real. '
          '¿Buscas una explicación, un consejo práctico o un dato específico?',
      'Eso se sale un poquito de mi jardín de conocimientos 🌿. Cuéntame qué parte te interesa y trataré de ayudarte sin darte información inventada.',
      'Podemos desmenuzarlo juntos. Dime si te interesa el «qué», el «cómo» o el «por qué», y lo abordamos paso a paso.',
    ], fallback: true);
  }
}
