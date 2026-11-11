import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'nutri_calculator_service.dart';
import 'texto_chatbot.dart';
import 'chat_historial.dart';
import 'package:healthy_habit/servicios/clima_servicio.dart';
import 'package:healthy_habit/servicios/firebase_servicios.dart';

export 'chat_historial.dart' show ChatMessage;

class _Offer {
  final String action;
  final String question;

  const _Offer(this.action, this.question);
}

class NutriChatPage extends StatefulWidget {
  const NutriChatPage({super.key});

  @override
  State<NutriChatPage> createState() => _NutriChatPageState();
}

class _NutriChatPageState extends State<NutriChatPage> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final NutriCalculatorService _calculatorService = NutriCalculatorService();
  final ClimaServicio _climaServicio = ClimaServicio();
  final List<String> offensiveWords = [
    //IA
    'puta',
    'puta',
    'puto',
    'culo',
    'mierda',
    'imbecil',
    'idiota',
    'cabron',
    'cabrona',
    'estupido',
    'gilipollas',
    'pendejo',
    'pendeja',
    'hijo de puta',
    'maldito',
    'zorra',
    'pedo',
    //IA
    //Mijo
    'perro malnacido',
    'perra malnacida',
    'buey',
    'vete a la verga',
    'vrg',
    'verga',
    'estupida',
    'estupido',
    'perra',
    'perra madre',
    'chingada madre',
    'vete a la chingada',
    'chingada',
    'perro infeliz',
    'perro',
    'hijo de la chingada',
    'tonto',
    'tonta',
    'tu puta madre',
    'tonto chatbot',
    'vete a la vrg',
  ];
  bool isTyping = false;

  late final ChatSession _session;
  List<ChatMessage> messages = [];

  String _getCurrentUserNameSync() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }

    final email = user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first.trim();
    }

    return 'Usuario';
  }

  @override
  void initState() {
    super.initState();
    final initialName = _getCurrentUserNameSync();
    _session = ChatHistoryStore.instance.startSession(
      FirebaseAuth.instance.currentUser?.uid,
    );
    // La lista de la sesión es la misma que muestra el chat.
    messages = _session.messages;
    messages.add(
      ChatMessage(
        text:
            '¡Hola, $initialName! Puedo resolver dudas sobre la app, tus misiones y tus hábitos, aunque algo limitado aún. ¿Por dónde empezamos?',
        isUser: false,
        time: _getFormattedTime(),
      ),
    );
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await _getCurrentUserName();
    if (!mounted) return;

    setState(() {
      if (messages.isNotEmpty) {
        messages[0] = ChatMessage(
          text:
              '¡Hola, $name! Puedo resolver dudas sobre la app, tus misiones y tus hábitos, aunque algo limitado aún. ¿Por dónde empezamos?',
          isUser: false,
          time: messages[0].time,
        );
      }
    });
  }

  Future<String> _getCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Usuario';

    try {
      await user.reload();
    } catch (_) {}

    final refreshedUser = FirebaseAuth.instance.currentUser;
    if (refreshedUser == null) return 'Usuario';

    try {
      final snapshot =
          await appFirestore.collection('users').doc(refreshedUser.uid).get();
      final firestoreName = snapshot.data()?['name'];
      if (firestoreName is String && firestoreName.trim().isNotEmpty) {
        return firestoreName.trim();
      }
    } catch (_) {}

    final displayName = refreshedUser.displayName;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }

    final email = refreshedUser.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first.trim();
    }

    return 'Usuario';
  }

  final List<String> quickOptions = [
    '¿Cómo mejorar mi racha?',
    '¿Qué misión tengo hoy?',
    'Quiero mejorar mi hidratación',
    'Hablar con un profesional',
    '¿Cómo está el clima hoy?',
  ];

  String _getFormattedTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void sendMessage([String? predefinedText]) {
    final text = (predefinedText ?? messageController.text).trim();

    if (text.isEmpty || isTyping) return;

    messageController.clear();

    final currentTime = _getFormattedTime();

    setState(() {
      messages.add(ChatMessage(text: text, isUser: true, time: currentTime));
      isTyping = true;
    });

    scrollToBottom();

    if (_containsProfanity(text)) {
      final response =
          'No acepto mensajes con groserías ni lenguaje ofensivo. Si necesitas ayuda con hábitos, hidratación o tus metas, estoy aquí para ayudarte.';

      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;

        setState(() {
          messages.add(
            ChatMessage(
              text: response,
              isUser: false,
              time: _getFormattedTime(),
            ),
          );
          isTyping = false;
        });

        scrollToBottom();
      });
      return;
    }

    final normalizedText = _normalizeText(text);
    final isActiveCalculatorFlow =
        _calculatorService.pasoIMC > 0 || _calculatorService.pasoGET > 0;
    final isQuickOption = quickOptions.any(
      (option) => _normalizeText(option) == normalizedText,
    );
    final isImcIntent = _containsAny(
      normalizedText,
      NutriCalculatorService.imcKeywords,
    );
    final isGetIntent = _containsAny(
      normalizedText,
      NutriCalculatorService.getKeywords,
    );
    if (!isActiveCalculatorFlow &&
        !isImcIntent &&
        !isGetIntent &&
        _containsAny(normalizedText, _climaKeywords)) {
      _lastTopic = null;
      _pendingOffer = null;
      _responderClima();
      return;
    }

    final respuesta =
        (isActiveCalculatorFlow || isImcIntent || isGetIntent || isQuickOption)
            ? _calculatorService.procesarMensaje(text)
            : '';
    final String response;
    if (respuesta.isNotEmpty) {
      // La calculadora lleva su propio flujo: se limpia el contexto.
      _lastTopic = null;
      _pendingOffer = null;
      response = respuesta;
    } else {
      response = _buildContextualResponse(text, normalizedText);
    }

    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;

      setState(() {
        messages.add(
          ChatMessage(text: response, isUser: false, time: _getFormattedTime()),
        );
        isTyping = false;
      });

      scrollToBottom();
    });
  }

  static const List<String> _climaKeywords = [
    'clima',
    'temperatura',
    'pronostico',
    'llover',
    'lluvia',
    'llueve',
    'hace calor',
    'hace frio',
    'que tiempo hace',
  ];

  Future<void> _responderClima() async {
    String response;
    try {
      response = (await _climaServicio.obtenerClimaActual()).mensaje;
    } on ClimaException catch (e) {
      response = e.message;
    } catch (_) {
      response = 'No pude consultar el clima en este momento.';
    }

    if (!mounted) return;

    setState(() {
      messages.add(
        ChatMessage(text: response, isUser: false, time: _getFormattedTime()),
      );
      isTyping = false;
    });

    scrollToBottom();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String getNutriResponse(String input) {
    final text = _normalizeText(input);

    if (_containsProfanity(text)) {
      return 'No acepto mensajes con groserías ni lenguaje ofensivo. Si necesitas ayuda con hábitos, hidratación o tus metas, estoy aquí para ayudarte.';
    }

    final extra = _consultasPrioritarias(text);
    if (extra != null) return extra;

    if (_containsAny(text, [
      'racha',
      'como mejorar mi racha',
      'dias seguidos',
    ])) {
      return 'Para mantener tu racha activa, asegúrate de completar y registrar al menos un hábito o misión principal al día antes de que termine la jornada.';
    }

    if (_containsAny(text, [
      'mision',
      'que mision tengo hoy',
      'reto del dia',
    ])) {
      return 'Tu misión destacada de hoy es Hidratación (4 de 6 vasos de agua tomados). ¡Solo te faltan 2 vasos para completarla!';
    }

    if (_containsAny(text, ['hidrat*', 'agua', 'vasos de agua', 'tengo sed'])) {
      return 'Puedes asociar tu hábito a un momento cotidiano y configurar un recordatorio en Hábitos → Hidratación.\n\nEs una idea general, no una indicación médica. Si necesitas orientación individual, consulta a un profesional.';
    }

    if (_containsAny(text, [
      'profesional',
      'nutriologo',
      'nutricionista',
      'psicologo',
      'terapeuta',
      'doctor',
      'medico',
    ])) {
      return 'Puedes consultar la pestaña de Orientación Profesional en el menú principal para contactar con nutriólogos y psicólogos capacitados.';
    }

    // Temas de la app
    if (_containsAny(text, [
      'recordatorio',
      'recordar*',
      'notificacion',
      'alarma',
      'aviso',
    ])) {
      return 'Puedes activar o desactivar tus recordatorios en Perfil → Configuración → Recordatorios. Ahí elijes si quieres avisos por hábito, de racha o de desafíos.';
    }

    if (_containsAny(text, ['logro', 'insignia', 'medalla', 'trofeo'])) {
      return 'Tus logros e insignias aparecen en Perfil → Mis logros. Se desbloquean al mantener tus hábitos y completar misiones. Si quieres, en Configuración → Privacidad eliges si tus amigos pueden verlos.';
    }

    if (_containsAny(text, ['punto', 'xp', 'experiencia'])) {
      return 'Ganas puntos (XP) al completar hábitos y misiones. Cada hábito suma según su dificultad.';
    }

    if (_containsAny(text, ['nivel', 'subir de nivel'])) {
      return 'Subes de nivel cuando acumulas suficiente XP. En Inicio ves cuánto te falta para el siguiente.';
    }

    if (_containsAny(text, ['contrasena', 'password', 'clave'])) {
      return 'Para cambiar tu contraseña ve a Perfil → Configuración → Cambiar contraseña. Si no puedes entrar a tu cuenta, usa la opción "Olvidé mi contraseña" en la pantalla de inicio de sesión.';
    }

    if (_containsAny(text, ['perfil', 'cuenta'])) {
      return 'En la pestaña Perfil puedes ver tu progreso y logros, usar "Editar perfil" para cambiar tus datos y entrar a Configuración para ajustar recordatorios y privacidad.';
    }

    // Temas de salud
    if (_containsAny(text, [
      'bajar de peso',
      'adelgaz*',
      'perder peso',
      'bajar kilos',
      'perder kilos',
      'quemar grasa',
    ])) {
      return 'Lo más sostenible suele ser hacer cambios pequeños: más verduras, porciones moderadas, moverte a diario y dormir bien. Evita dietas extremas.\n\nSi quieres una referencia, escribe "IMC" para calcular el tuyo. Para un plan individual, consulta a un nutriólogo en Orientación Profesional.';
    }

    if (_containsAny(text, ['peso'])) {
      return 'Tu peso es solo un dato más. Puedo calcular tu IMC (escribe "IMC") o tus calorías diarias (escribe "GET"). Para una valoración completa, consulta a un profesional.';
    }

    if (_containsAny(text, ['caloria', 'calorias'])) {
      return 'Puedo calcular tus calorías diarias con el Gasto Energético Total. Escribe "GET" para empezar.';
    }

    if (_containsAny(text, [
      'dorm*',
      'sueno',
      'descans*',
      'insomnio',
      'desvel*',
    ])) {
      return 'Intenta dormir entre 7 y 9 horas y acostarte a la misma hora. Evita pantallas y comidas pesadas 1 hora antes de dormir.\n\nSi tienes problemas de sueño constantes, consulta a un profesional de la salud.';
    }

    if (_containsAny(text, [
      'ejercicio',
      'ejercit*',
      'entren*',
      'actividad fisica',
      'gimnasio',
      'gym',
      'deporte',
      'correr',
      'camin*',
    ])) {
      return 'Empieza con algo simple: caminar 20-30 minutos al día. Después puedes sumar fuerza o cardio poco a poco. Lo importante es la constancia, no la intensidad.';
    }

    if (_containsAny(text, ['desayun*'])) {
      return _pickVaried('desayuno', [
        'Un buen desayuno combina proteína (huevo, yogur, queso), un carbohidrato integral (avena, pan integral) y una fruta. Así te da energía por más tiempo.',
        'Prueba avena cocida con plátano o manzana y un puñado de nueces. Es rápida, saciante y te da energía estable.',
        'Unos huevos revueltos con verduras (espinaca, jitomate, champiñones) y una tortilla o pan integral son un desayuno completo.',
        'Yogur natural con fruta picada, semillas (chía o linaza) y un poco de granola sin azúcar añadida es fácil y ligero.',
        'Aguacate machacado sobre pan integral con un huevo o queso fresco te mantiene satisfecho hasta la comida.',
        'Un licuado de fruta con leche o yogur y una cucharada de avena sirve si no tienes mucho tiempo en la mañana.',
        'Si desayunas poco, empieza por algo simple: una fruta y un puñado de almendras. Lo importante es crear el hábito.',
      ]);
    }

    if (_containsAny(text, ['proteina'])) {
      return _pickVaried('proteina', [
        'Buenas fuentes de proteína: huevo, pollo, pescado, legumbres (frijol, lentejas), lácteos y tofu. Trata de incluir una en cada comida.\n\nLas necesidades varían por persona; un nutriólogo puede orientarte mejor.',
        'Si prefieres opciones vegetales, las lentejas, garbanzos, frijoles, tofu y quinoa aportan buena proteína y fibra.',
        'El pescado y el pollo sin piel son opciones magras de proteína. Prepáralos al horno, a la plancha o cocidos para que sean más ligeros.',
        'Para un snack con proteína: yogur griego, un huevo cocido, queso cottage o un puñado de almendras o cacahuates.',
        'Combinar cereales con legumbres (arroz con frijoles, tortilla con lentejas) te da una proteína más completa.',
        'Reparte la proteína en el día (desayuno, comida y cena) en lugar de concentrarla en una sola comida.',
        'Los lácteos (leche, yogur, queso fresco) y los huevos son opciones accesibles y fáciles de incluir cada día.\n\nLas necesidades cambian según la persona; un nutriólogo puede orientarte mejor.',
      ]);
    }

    final alimentos = _consultasAlimentos(text);
    if (alimentos != null) return alimentos;

    if (_containsAny(text, [
      'dieta',
      'comida',
      'comer',
      'alimentacion',
      'alimento',
      'nutricion',
      'almuerzo',
      'cena',
      'cenar',
      'merienda',
      'snack',
    ])) {
      return 'Una alimentación equilibrada incluye verduras, frutas, proteínas, cereales integrales y agua. Un plato variado y porciones moderadas funcionan mejor que prohibirte alimentos.\n\nEs una guía general, no un plan médico.';
    }

    if (_containsAny(text, [
      'estres',
      'estresad*',
      'ansied*',
      'ansios*',
      'nervios*',
      'angustia',
      'agobiad*',
    ])) {
      return 'Prueba respirar profundo 1-2 minutos, caminar un rato o escribir lo que sientes. Dormir bien y moverte también ayudan.\n\nSi se vuelve constante o te supera, habla con un psicólogo en Orientación Profesional. No estás solo/a.';
    }

    if (_containsAny(text, [
      'motiv*',
      'animo',
      'desanimad*',
      'sin ganas',
      'flojera',
      'pereza',
    ])) {
      return '¡Vas bien! Elige un hábito pequeño, hazlo hoy y celebra cada avance. Un día perdido no borra tu progreso: lo importante es volver a empezar.';
    }

    if (_containsAny(text, ['rutina'])) {
      return 'Para crear una rutina, ata el hábito a algo que ya haces (por ejemplo, un vaso de agua al levantarte) y empieza con algo de 5 minutos. Puedes programar recordatorios en Hábitos.';
    }

    // Saludos y cortesía
    if (_containsAny(text, ['gracias', 'te agradezco'])) {
      return '¡De nada! Aquí estoy para lo que necesites. 💚';
    }

    if (_containsAny(text, [
      'adios',
      'hasta luego',
      'nos vemos',
      'bye',
      'chao',
    ])) {
      return '¡Hasta pronto! Recuerda: un pequeño paso cada día. 🌱';
    }

    if (_containsAny(text, ['ayuda', 'ayudame', 'help', 'que puedes hacer'])) {
      return 'Claro, te ayudo. Puedes preguntarme sobre tu racha, misiones, hidratación, sueño, ejercicio, alimentación, recordatorios, logros o pedirme calcular tu IMC (escribe "IMC") o tus calorías (escribe "GET"). ¿Qué necesitas?';
    }

    if (_containsAny(text, [
      'ok',
      'vale',
      'listo',
      'entendido',
      'perfecto',
      'genial',
    ])) {
      return '¡Perfecto! Si tienes otra duda sobre tus hábitos, aquí estoy.';
    }

    if (_containsAny(text, [
      'hola',
      'buenos dias',
      'buenas tardes',
      'buenas noches',
      'buen dia',
      'que tal',
      'hey',
      'saludos',
      'buenas',
    ])) {
      return '¡Hola! 👋 Soy Mr. Healthy. Puedo ayudarte con tus hábitos, misiones, hidratación, sueño, ejercicio y más. ¿Qué te gustaría saber?';
    }

    if (_containsAny(text, [
      'habito',
      'consejo',
      'recomendacion',
      'tip',
      'sugerencia',
    ])) {
      _branchTopic = 'consejo_habito';
      final consejo = _pickVaried('consejo_habito', _consejosHabitos);
      return 'Aquí tienes una sugerencia práctica:\n\n$consejo\n\nSi quieres otro consejo, escribe "otro".';
    }

    return _fallbackResponse;
  }

  // ====== CONSULTAS ADICIONALES (tomadas del asistente anterior) ======
  // Tema fijado por una rama concreta de getNutriResponse.
  String? _branchTopic;

  static const List<String> _consejosHabitos = [
    'Bebe un vaso de agua al despertar y mantén una botella a la mano durante el día.',
    'Añade una porción de verdura o fruta a cada comida.',
    'Camina al menos 20-30 minutos al día; empieza con 10 si te cuesta.',
    'Duerme entre 7 y 9 horas y trata de acostarte a la misma hora.',
    'Come despacio y sin pantallas para notar cuándo ya estás satisfecho.',
    'Planea tus comidas de la semana y haz tu lista de compras con tiempo.',
    'Cambia un refresco o jugo azucarado al día por agua o agua con limón.',
    'Ten a la vista snacks saludables: fruta, nueces o yogur natural.',
    'Reduce poco a poco la sal y los ultraprocesados; lee las etiquetas.',
    'Cambia un solo hábito a la vez y repítelo durante varias semanas hasta que se vuelva automático.',
  ];

  /// Consultas específicas que deben evaluarse antes que las generales.
  String? _consultasPrioritarias(String text) {
    // ---------- Entrenamiento ----------
    if (_containsAny(text, [
      'comer antes de entrenar',
      'comida pesada antes de hacer ejercicio',
      'que no comer antes de entrenar',
      'alimentos a evitar antes del gym',
      'comida grasosa antes de ejercicio',
      'comer mucho antes de entrenar',
      'evitar fritos antes de entrenar',
      'comer antes de correr',
      'que no debo comer antes del ejercicio',
      'comida antes del gimnasio',
      'evitar comer antes de entrenar',
      'no debo comer antes de entrenar',
    ])) {
      return 'Evita comidas pesadas, grasosas, fritas o muy abundantes 2 a 3 horas antes de entrenar. Pueden causar pesadez, náuseas y calambres. Mejor una comida ligera con carbohidratos y algo de proteína.';
    }

    if (_containsAny(text, [
      'alcohol antes de entrenar',
      'beber antes de hacer ejercicio',
      'cerveza antes del gym',
      'tomar alcohol y entrenar',
      'resaca y ejercicio',
      'entrenar con resaca',
      'alcohol y rendimiento',
      'evitar alcohol antes de ejercicio',
      'bebidas alcoholicas y deporte',
      'puedo entrenar despues de tomar',
      'tomar antes del ejercicio',
      'tomar antes de hacer ejercicio',
      'tomar antes del entrenamiento',
      'tomar antes de entrenar',
      'beber antes del ejercicio',
      'beber antes de entrenar',
      'beber antes del entrenamiento',
    ])) {
      return 'Evita el alcohol antes de entrenar (y la noche anterior). Deshidrata, reduce la coordinación, la fuerza y los reflejos, y aumenta el riesgo de lesiones.';
    }

    if (_containsAny(text, [
      'cafe antes de entrenar',
      'cafeina antes del ejercicio',
      'bebidas energeticas antes de entrenar',
      'exceso de cafeina gym',
      'pre entreno demasiado',
      'preworkout riesgos',
      'energizantes y ejercicio',
      'cuanta cafeina antes de entrenar',
      'taquicardia por pre entreno',
      'redbull antes de entrenar',
      'exceso de preentreno',
      'demasiado preentreno',
      'cafe antes de hacer ejercicio',
      'demasiada cafeina antes de entrenar',
      'mucha cafeina antes de entrenar',
    ])) {
      return 'Evita el exceso de cafeína y las bebidas energéticas. Demasiada puede causar taquicardia, temblores, ansiedad y malestar estomacal. Si la usas, que sea en dosis moderadas.';
    }

    if (_containsAny(text, [
      'agua antes de entrenar',
      'deshidratacion y ejercicio',
      'no beber agua antes del gym',
      'hidratarse antes de hacer ejercicio',
      'cuanta agua tomar antes de entrenar',
      'entrenar sin tomar agua',
      'sed durante el ejercicio',
      'calambres por falta de agua',
      'beber mucha agua antes de correr',
      'hidratacion antes del entrenamiento',
      'hago ejercicio sin tomar agua',
      'hacer ejercicio sin tomar agua',
      'hago ejercicio sin beber agua',
      'hacer ejercicio sin beber agua',
      'entreno sin tomar agua',
      'sin haber tomado agua',
      'sin tomar agua',
      'sin beber agua',
      'sin haber bebido agua',
    ])) {
      return 'No llegues deshidratado ni tampoco tomes grandes cantidades de golpe. Bebe agua de forma gradual durante el día y un poco (250-500 ml) antes de entrenar.';
    }

    if (_containsAny(text, [
      'entrenar sin calentar',
      'no calentar antes de ejercicio',
      'calentamiento antes del gym',
      'es necesario calentar',
      'lesiones por no calentar',
      'calentamiento previo',
      'empezar directo con pesas',
      'saltarse el calentamiento',
      'como calentar antes de entrenar',
      'evitar lesiones al empezar',
      'salto el calentamiento antes de',
      'no hago el calentamiento antes de',
      'no hago calentamiento previo',
      'hago ejercicio sin calentar',
      'entreno sin calentar',
    ])) {
      return 'No te saltes el calentamiento. De 5 a 10 minutos de movilidad y cardio suave preparan músculos y articulaciones y reducen el riesgo de lesiones.';
    }

    if (_containsAny(text, [
      'estirar antes de entrenar',
      'estiramientos antes del ejercicio',
      'estiramiento estatico antes de pesas',
      'estirar en frio',
      'estiramientos largos antes de correr',
      'estirar antes o despues',
      'estiramiento dinamico',
      'estirar antes del gym',
      'perder fuerza por estirar',
      'estiramientos previos al entrenamiento',
    ])) {
      return 'Evita los estiramientos estáticos largos (más de 30-60 s) antes de entrenar: pueden reducir temporalmente la fuerza y la potencia. Prefiere estiramientos dinámicos y deja los estáticos para el final.';
    }

    if (_containsAny(text, [
      'entrenar sin dormir',
      'poco sueno y ejercicio',
      'dormir antes de entrenar',
      'cansancio y gym',
      'falta de descanso entrenamiento',
      'entrenar con sueno',
      'desvelado y ejercicio',
      'dormir mal rendimiento',
      'insomnio y entrenar',
      'horas de sueno para entrenar',
      'ejercicio sin dormir bien',
      'entreno sin dormir bien',
      'voy al gym sin dormir bien',
      'ejercicio sin haber dormido bien',
      'entreno sin haber dormido bien',
      'voy al gym sin haber dormido bien',
    ])) {
      return 'Evita entrenar intenso con muy poco sueño. Baja el rendimiento, aumenta el riesgo de lesión y afecta la recuperación. Si dormiste mal, baja la intensidad o descansa.';
    }

    if (_containsAny(text, [
      'ibuprofeno antes de entrenar',
      'pastillas para el dolor y ejercicio',
      'antiinflamatorios antes del gym',
      'tomar analgesicos antes de correr',
      'paracetamol antes de entrenar',
      'medicamentos antes de hacer ejercicio',
      'tomar pastilla para no sentir dolor',
      'aines y deporte',
      'naproxeno y ejercicio',
      'analgesico preventivo deporte',
    ])) {
      return 'Evita tomar analgésicos o antiinflamatorios "preventivamente" antes de entrenar. Pueden enmascarar el dolor, afectar estómago y riñones, y hacerte ignorar una lesión. Consulta a un médico si los necesitas.';
    }

    if (_containsAny(text, [
      'entrenar con fiebre',
      'hacer ejercicio enfermo',
      'entrenar con dolor',
      'entrenar lesionado',
      'ejercicio con gripe',
      'entrenar con mareo',
      'hacer ejercicio con resfriado',
      'dolor de pecho al entrenar',
      'cuando no debo entrenar',
      'entrenar con malestar',
    ])) {
      return 'Evita entrenar con fiebre, mareos, dolor de pecho, vómito o dolor articular agudo. Descansa y consulta a un médico si los síntomas persisten.';
    }

    if (_containsAny(text, [
      'ropa para entrenar',
      'zapatos para hacer ejercicio',
      'calzado inadecuado gym',
      'que no usar para entrenar',
      'ropa incomoda ejercicio',
      'tenis para correr',
      'ropa de algodon sudor',
      'evitar ampollas al entrenar',
      'ropa y lesiones deportivas',
      'que ponerme para entrenar',
      'pongo para entrenar',
      'debo usar para entrenar',
      'debo ponerme para entrenar',
    ])) {
      return 'Evita ropa muy ajustada, que no transpire o calzado gastado o inadecuado. Pueden causar rozaduras, ampollas, sobrecalentamiento y lesiones en rodillas y tobillos.';
    }

    if (text.contains('entren') &&
        _containsAny(text, ['antes', 'despues'])) {
      return 'Depende de la duración e intensidad del ejercicio y de cómo te sientas. Si vas a comer una comida completa antes de entrenar, intenta hacerlo entre 1 y 3 horas antes; si falta poco, elige algo ligero que te siente bien. Después de entrenar, procura incluir proteína y carbohidratos en tu siguiente comida; no es necesario comer inmediatamente. Mantente bien hidratado.';
    }

    // ---------- Desafíos difícil / rendirse ----------
    final mencionaDesafio = _containsAny(text, ['desafio', 'reto']);
    if (_containsAny(text, [
          'no puedo con el desafio',
          'no puedo con el reto',
          'no puedo terminar el desafio',
          'no logro completar el reto',
          'me resulta dificil el desafio',
          'el desafio es muy dificil',
          'quiero abandonar el reto',
          'no puedo seguir con este desafio',
          'me siento abrumado por el desafio',
          'quiero rendirme',
          'me quiero rendir',
        ]) ||
        (mencionaDesafio &&
            _containsAny(text, [
              'no lo logro',
              'no puedo hacerlo',
              'es demasiado para mi',
              'me cuesta mucho',
              'me cuesta demasiado',
              'es muy pesado',
              'es muy complicado',
              'muy complicado',
              'muy exigente',
              'muy dificil',
            ]))) {
      return 'Te sugiero ir a ajustes para cambiar la dificultad de tus desafíos. También puedes retirarte o cancelar el desafío.\n\nRecuerda que un día difícil no borra tu progreso: puedes retomarlo cuando estés listo.';
    }

    // ---------- Funciones de la app ----------
    if (_containsAny(text, [
      'que pasa si no cumplo un habito',
      'que pasa si no cumplo mis habitos',
      'que pasa si no completo los habitos',
      'que pasa si no realizo un habito',
      'si no cumplo un habito',
      'si no cumplo los habitos',
      'que ocurre si no cumplo',
      'que pasa si fallo un dia',
      'pierdo mi progreso si no hago',
      'que sucede si no completo',
      'si hoy no hago mis habitos',
      'afecta si un dia no cumplo',
      'que pasa si dejo de hacer un habito',
    ])) {
      return 'No pasa nada grave: puedes continuar con tu siguiente objetivo diario. Solo pierdes el XP que acumularías con el hábito (o los hábitos) que no cumpliste.';
    }

    if (_containsAny(text, [
      'registrar un habito',
      'registrar mis habitos',
      'como registro mis habitos',
      'donde registro un habito',
      'como registro un habito',
      'como se registra un habito',
      'donde se registra un habito',
      'en que parte registro',
      'donde marco que cumpli',
      'como puedo completar mi habito',
      'donde agrego un nuevo habito',
      'como registro el cumplimiento',
    ])) {
      return 'Puedes registrar tus hábitos en "Tu misión de hoy" o en la sección de Hábitos.';
    }

    if (_containsAny(text, [
      'cambiar correo',
      'cambiar el correo',
      'cambiar mi correo',
      'cambiar email',
      'cambiar el email',
      'cambiar mi email',
      'cambiar mis datos',
      'editar mis datos',
      'datos personales',
      'donde cambio el correo',
      'donde cambiar el correo',
      'donde se cambia el correo',
      'como se cambia el correo',
      'actualizar mi correo',
      'modificar el correo',
      'correo electronico',
    ])) {
      return 'Entra a Perfil (en la parte inferior derecha) y luego a Configuración. Ahí puedes editar tus datos personales, como tu correo o tu contraseña.';
    }

    if (_containsAny(text, [
      'que son los desafios',
      'que es un desafio',
      'que significa un desafio',
      'para que sirven los desafios',
      'como funcionan los desafios',
      'objetivo de los desafios',
      'que gano al completar un desafio',
      'desafios',
      'desafio',
    ])) {
      return 'Los desafíos son metas temporales que la aplicación te propone. Al completarlos obtienes experiencia (XP) y HabitCoins. Puedes aceptarlos, ver tu progreso y reclamar tu recompensa en la pestaña Desafíos.';
    }

    if (_containsAny(text, [
      'evidencia',
      'foto',
      'fotografia',
      'como subo una evidencia',
      'para que sirven las evidencias',
      'como envio evidencia',
      'las fotos de los desafios son obligatorias',
      'como se comprueba que complete',
      'donde agrego una foto',
    ])) {
      return 'Las evidencias fotográficas son opcionales y se piden en los desafíos de dificultad media a alta. Sirven para verificar que cumples el desafío y para que puedas ver tu progreso. Solo tú puedes verlas, y la aplicación rechaza las fotos que no tengan relación con tus hábitos.';
    }

    if (_containsAny(text, [
      'retroalimentacion',
      'feedback',
      'comentarios sobre mi progreso',
      'recomendaciones de habitos',
      'sugerencias segun mis resultados',
      'seguimiento de mi progreso',
      'comentarios sobre mis avances',
    ])) {
      return 'La retroalimentación analiza tu progreso registrado y te da sugerencias de hábitos acordes con tus objetivos.';
    }

    // ---------- Fecha y hora ----------
    if (_containsAny(text, [
      'que dia es',
      'que fecha es',
      'fecha de hoy',
      'fecha actual',
      'que hora es',
      'hora actual',
      'dime la hora',
      'dime la fecha',
      'en que dia estamos',
      'a cuanto estamos',
      'que dia de la semana',
      'a que estamos',
    ])) {
      final now = DateTime.now();
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
      final hora = now.hour.toString().padLeft(2, '0');
      final minuto = now.minute.toString().padLeft(2, '0');

      return 'Hoy es ${dias[now.weekday - 1]} ${now.day} de ${meses[now.month - 1]} de ${now.year}, y son las $hora:$minuto.';
    }

    // ---------- Agua, grasas y cocina ----------
    if (_containsAny(text, [
      'cuanta agua',
      'cuantos litros de agua',
      'cantidad de agua',
      'agua debo',
      'agua necesito',
      'agua tengo que',
      'agua hay que',
      'litros de agua',
      'mantenerme hidratado',
    ])) {
      return 'Una referencia general es multiplicar tu peso en kilogramos por 35 mililitros. Por ejemplo, si pesas 70 kg, serían unos 2.45 litros al día.\n\nEs una estimación: cambia con el clima y tu actividad. Si tienes alguna condición médica, consulta a un profesional.';
    }

    if (_containsAny(text, [
      'grasas saludables',
      'grasa saludable',
      'grasas buenas',
      'grasa buena',
      'fuentes de grasa',
      'alimentos con grasa saludable',
      'que grasas puedo comer',
      'grasas sanas',
      'grasa sana',
      'aceite saludable',
      'aceites saludables',
      'aceites buenos',
      'aceites sanos',
      'aceite sano',
      'aceite bueno',
    ])) {
      return 'Algunas fuentes de grasas saludables son:\n\n'
          '• Aguacate\n'
          '• Aceite de oliva extra virgen\n'
          '• Nueces, almendras, cacahuates y pistaches\n'
          '• Semillas de chía, linaza y calabaza\n'
          '• Pescados grasos: salmón, sardina, atún y caballa\n'
          '• Aceitunas\n'
          '• Huevo\n\n'
          'Consúmelas con moderación: aunque son saludables, aportan muchas calorías. Una porción pequeña al día es suficiente.';
    }

    if (_containsAny(text, [
      'cocina sin aceite',
      'recetas sin aceite',
      'cocinar sin aceite',
      'alternativas al aceite',
      'reemplazar el aceite',
      'remplazar el aceite',
      'sin aceite',
      'evitar aceite',
      'evitar el aceite',
      'alimentos sin aceite',
      'comidas sin aceite',
    ])) {
      return 'Las técnicas de cocina sin aceite permiten preparar alimentos de forma más saludable, reduciendo las grasas añadidas sin perder sabor. Puedes cocinar al vapor (ideal para verduras y pescado), hornear (papas o pollo), usar una freidora de aire (papas o alitas con poco o nada de aceite) o cocinar a la plancha antiadherente (huevos, carnes y verduras sin añadir grasa).';
    }

    // ---------- Explicación de hábito ----------
    if (_containsAny(text, _explicaHabitoKeywords)) {
      return 'Un hábito es una conducta que se repite casi sin pensarlo y que se vuelve automática con el tiempo. Por ejemplo, caminar 20 minutos al día o beber agua al despertar. Los hábitos saludables se fortalecen cuando los repites de forma constante, con una rutina clara y poco a poco.';
    }

    return null;
  }

  static const List<String> _explicaHabitoKeywords = [
    'que es un habito',
    'que es habito',
    'explica un habito',
    'explicar un habito',
    'explicar habito',
    'explica habito',
    'explica el habito',
    'explicar el habito',
    'como funciona un habito',
    'como se forma un habito',
    'que significa un habito',
    'que significa tener un habito',
    'que quiere decir habito',
    'por que es importante crear habitos',
    'como puedo entender mejor los habitos',
  ];

  /// Consultas de alimentos que van antes de la respuesta general.
  String? _consultasAlimentos(String text) {
    if (_containsAny(text, _snacksKeywords)) {
      return 'Ideas de snacks saludables: fruta fresca, yogur natural, un puñado de nueces o almendras, zanahoria o apio con hummus, palomitas caseras, huevo duro o un sándwich pequeño de pan integral. Lo importante es que combinen fibra y proteína para que te llenen.';
    }

    if (_containsAny(text, _frutasVerdurasKeywords)) {
      return 'Se recomienda comer al menos 5 porciones de frutas y verduras al día. Varía los colores (verde, rojo, naranja y morado) y agrégalas al desayuno, como snack, en la comida o en la cena. Prueba nuevas preparaciones para que no se vuelvan aburridas.';
    }

    return null;
  }

  static const List<String> _snacksKeywords = [
    'snack',
    'colacion',
    'entre comidas',
    'botana',
    'antojo',
    'antojito',
    'algo saludable para picar',
    'merienda saludable',
    'merienda',
  ];

  static const List<String> _frutasVerdurasKeywords = [
    'fruta',
    'verdura',
    'vegetal',
    'porciones de fruta',
    'frutas y verduras',
  ];

  // ====== SEGUIMIENTO DE LA CONVERSACIÓN ======
  // Recuerda el último tema y una posible pregunta pendiente para poder
  // continuar ("sí", "dame otro", "cuéntame más") sin perder el contexto.
  String? _lastTopic;
  String? _pendingOffer;
  final Map<String, int> _detailIndex = {};

  static const String _fallbackResponse =
      'Puedo ayudarte con hábitos, misiones, hidratación, sueño, ejercicio, alimentación, recordatorios, logros o con el cálculo de tu IMC y tus calorías (GET). ¿Sobre cuál te gustaría profundizar?';

  // Mismo orden que las ramas de getNutriResponse.
  static const Map<String, List<String>> _topicKeywords = {
    'que_es_habito': _explicaHabitoKeywords,
    'racha': ['racha', 'como mejorar mi racha', 'dias seguidos'],
    'mision': ['mision', 'que mision tengo hoy', 'reto del dia'],
    'hidratacion': ['hidrat*', 'agua', 'vasos de agua', 'tengo sed'],
    'profesional': [
      'profesional',
      'nutriologo',
      'nutricionista',
      'psicologo',
      'terapeuta',
      'doctor',
      'medico',
    ],
    'recordatorio': [
      'recordatorio',
      'recordar*',
      'notificacion',
      'alarma',
      'aviso',
    ],
    'logros': ['logro', 'insignia', 'medalla', 'trofeo'],
    'xp': ['punto', 'xp', 'experiencia'],
    'nivel': ['nivel', 'subir de nivel'],
    'bajar_peso': [
      'bajar de peso',
      'adelgaz*',
      'perder peso',
      'bajar kilos',
      'perder kilos',
      'quemar grasa',
    ],
    'peso': ['peso'],
    'calorias': ['caloria', 'calorias'],
    'sueno': ['dorm*', 'sueno', 'descans*', 'insomnio', 'desvel*'],
    'ejercicio': [
      'ejercicio',
      'ejercit*',
      'entren*',
      'actividad fisica',
      'gimnasio',
      'gym',
      'deporte',
      'correr',
      'camin*',
    ],
    'desayuno': ['desayun*'],
    'proteina': ['proteina'],
    'snacks': _snacksKeywords,
    'frutas_verduras': _frutasVerdurasKeywords,
    'alimentacion': [
      'dieta',
      'comida',
      'comer',
      'alimentacion',
      'alimento',
      'nutricion',
      'almuerzo',
      'cena',
      'cenar',
      'merienda',
      'snack',
    ],
    'estres': [
      'estres',
      'estresad*',
      'ansied*',
      'ansios*',
      'nervios*',
      'angustia',
      'agobiad*',
    ],
    'motivacion': [
      'motiv*',
      'animo',
      'desanimad*',
      'sin ganas',
      'flojera',
      'pereza',
    ],
    'rutina': ['rutina'],
  };

  // Preguntas que el asistente deja abiertas después de responder.
  static const Map<String, _Offer> _offers = {
    'bajar_peso': _Offer('imc', '¿Quieres que calculemos tu IMC ahora?'),
    'peso': _Offer('imc', '¿Quieres que calculemos tu IMC ahora?'),
    'calorias': _Offer('get', '¿Quieres que calculemos tus calorías ahora?'),
    'racha': _Offer('mision', '¿Quieres que te diga cuál es tu misión de hoy?'),
    'hidratacion': _Offer(
      'recordatorio',
      '¿Te explico cómo activar un recordatorio para este hábito?',
    ),
    'estres': _Offer(
      'profesional',
      '¿Quieres que te indique dónde contactar a un profesional?',
    ),
  };

  static const List<String> _pesoDetalles = [
    'Dormir bien y moverte a diario suele ayudar más que las dietas estrictas. Los cambios pequeños y constantes son los que se mantienen.',
    'Registrar lo que comes durante unos días te ayuda a notar patrones sin obsesionarte con los números.',
    'Tu peso puede variar de un día a otro por líquidos, sueño o comidas. Fíjate más en la tendencia de varias semanas.',
  ];

  // Información adicional para cuando el usuario pide "más".
  static const Map<String, List<String>> _topicDetails = {
    'que_es_habito': [
      'Los hábitos saludables de alimentación y actividad física son fundamentales para mantener una buena salud y prevenir enfermedades. Una alimentación equilibrada incluye frutas, verduras, cereales, proteínas y suficiente agua, evitando el exceso de azúcar, grasas y comida chatarra. Además, moverte con regularidad (caminar, correr, bailar o practicar un deporte) fortalece los músculos, mejora tu condición física y ayuda a reducir el estrés.',
    ],
    'snacks': [
      'Si se te antoja algo dulce: fruta con yogur natural o un plátano con un poco de crema de cacahuate natural.',
      'Para algo salado: palomitas caseras con poca sal, garbanzos tostados o pepino con limón.',
    ],
    'frutas_verduras': [
      'Una forma fácil: fruta en el desayuno, verdura en la comida y fruta o verdura como snack.',
      'Las frutas y verduras de temporada suelen ser más económicas y sabrosas.',
      'Si no te gustan crudas, prueba al vapor, al horno, en licuados o en sopas.',
    ],
    'racha': [
      'Elige un hábito "mínimo" que puedas cumplir incluso en un día complicado, como un vaso de agua. Así tu racha no depende de tener tiempo o energía.',
      'Registra tu hábito a la misma hora todos los días y asócialo a algo que ya haces (después de desayunar o antes de dormir).',
      'Si un día fallas, no pasa nada: retoma al día siguiente. La constancia a largo plazo importa más que un día perdido.',
    ],
    'mision': [
      'Puedes ver el avance de tus misiones en la pestaña Desafíos. Al completarlas puedes reclamar XP y HabitCoins.',
      'Empieza por las misiones a las que les falta menos progreso para completarlas más rápido.',
    ],
    'hidratacion': [
      'Deja una botella visible en tu escritorio o mochila; verla te recuerda tomar agua.',
      'Toma un vaso al despertar, otro con cada comida y uno antes de dormir. Así repartes el agua en el día sin pensarlo.',
      'Si el agua sola te aburre, prueba agregarle rodajas de limón, pepino o menta.',
    ],
    'profesional': [
      'En Orientación Profesional puedes contactar a nutriólogos y psicólogos, que pueden darte un plan individual, algo que yo no puedo hacer.',
    ],
    'recordatorio': [
      'Elige una hora en la que normalmente tengas el teléfono a la mano, así es más fácil que atiendas el aviso.',
    ],
    'logros': [
      'Revisa en Perfil qué logros te faltan y elige uno como siguiente meta; te ayuda a mantener la motivación.',
    ],
    'xp': [
      'Los hábitos más difíciles suman más XP, y completar misiones y desafíos te da XP extra.',
      'También ganas XP al registrar tus evidencias fotográficas cuando un desafío las pide.',
    ],
    'nivel': [
      'Mantener tus hábitos todos los días es la forma más constante de subir de nivel. Los desafíos también aportan XP.',
      'Para pasar al siguiente nivel necesitas completar el nivel actual al 100 %; así desbloqueas el siguiente.',
    ],
    'bajar_peso': _pesoDetalles,
    'peso': _pesoDetalles,
    'calorias': [
      'El GET es una estimación: cambia según tu edad, peso, estatura y nivel de actividad. Escribe "GET" y te guío paso a paso.',
      'En lugar de contar cada caloría, enfócate en comer variado: verduras, frutas, proteínas, granos integrales y grasas saludables.',
    ],
    'sueno': [
      'Procura que tu cuarto esté oscuro, fresco y silencioso, y deja el teléfono lejos de la cama.',
      'Evita la cafeína por la tarde-noche y trata de despertarte a la misma hora también los fines de semana.',
    ],
    'ejercicio': [
      'Si caminar ya te resulta fácil, prueba intervalos: 2 minutos a paso rápido y 2 a paso normal, repetidos varias veces.',
      'Cuando te sientas listo, suma 2 o 3 días por semana de fuerza con tu propio peso (sentadillas o flexiones apoyadas).',
      'Escucha a tu cuerpo: si sientes dolor o mareo, detente y consulta a un profesional de la salud.',
    ],
    'alimentacion': [
      'Una guía sencilla: la mitad del plato con verduras o frutas, un cuarto con proteína y un cuarto con cereales integrales.',
      'Planear tus comidas de la semana reduce las decisiones de último momento.',
      'Come despacio: masticar con calma te ayuda a notar cuándo ya estás satisfecho.',
    ],
    'estres': [
      'Prueba la respiración 4-4-6: inhala 4 segundos, sostén 4 y exhala 6, durante 1 o 2 minutos.',
      'Levántate a estirarte cada hora si pasas mucho tiempo sentado.',
      'Hablar con alguien de confianza ayuda. Si el estrés persiste, busca a un psicólogo en Orientación Profesional.',
    ],
    'motivacion': [
      'Divide tu meta en pasos pequeños y marca cada uno; ver el progreso motiva.',
      'Recompénsate al completar tu semana con algo que no sea comida, como un paseo o una película.',
      'Revisa tus logros y tu racha en Perfil para recordar todo lo que ya llevas.',
    ],
    'rutina': [
      'Empieza con un solo hábito durante una o dos semanas antes de agregar otro.',
      'Prepara tu entorno la noche anterior (ropa, botella, desayuno) para que sea más fácil empezar.',
    ],
  };

  String _cleanForMatch(String normalized) {
    return normalized
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? _detectTopic(String normalizedText) {
    for (final entry in _topicKeywords.entries) {
      if (_containsAny(normalizedText, entry.value)) return entry.key;
    }
    return null;
  }

  bool _isAffirmative(String t) {
    const yes = {
      'si',
      'sii',
      'siii',
      'sip',
      'claro',
      'claro que si',
      'si claro',
      'si quiero',
      'si por favor',
      'por favor',
      'por supuesto',
      'dale',
      'va',
      'vale',
      'ok',
      'okay',
      'sale',
      'quiero',
      'hazlo',
      'adelante',
    };
    return yes.contains(t);
  }

  bool _isNegative(String t) {
    const no = {
      'no',
      'nel',
      'no gracias',
      'ahora no',
      'no quiero',
      'no por ahora',
      'luego',
      'despues',
      'paso',
    };
    return no.contains(t);
  }

  bool _wantsMore(String t) {
    if (t.isEmpty || t.split(' ').length > 6) return false;

    const exact = {
      'mas',
      'otro',
      'otra',
      'como',
      'por que',
      'porque',
      'y eso',
      'explica',
      'explicame',
      'continua',
      'sigue',
      'algo mas',
      'que mas',
      'ejemplos',
      'mas detalles',
      'mas informacion',
    };
    const phrases = [
      'dame mas',
      'dime mas',
      'cuentame mas',
      'explicame mas',
      'mas ideas',
      'mas consejos',
      'otro consejo',
      'otra opcion',
      'otra idea',
      'otra sugerencia',
      'dame otro',
      'dame otra',
      'dame ejemplos',
      'como lo hago',
      'como le hago',
      'y como',
      'profundiza',
    ];
    return exact.contains(t) || phrases.any(t.contains);
  }

  /// Devuelve una respuesta si el mensaje continúa la conversación anterior;
  /// si no, devuelve null para tratarlo como una consulta nueva.
  String? _resolveFollowUp(String cleanText) {
    final offer = _pendingOffer;

    if (offer != null) {
      if (_isAffirmative(cleanText)) {
        _pendingOffer = null;
        return _acceptOffer(offer);
      }
      if (_isNegative(cleanText)) {
        _pendingOffer = null;
        return 'Sin problema. Si necesitas algo más, aquí estoy.';
      }
    }

    final topic = _lastTopic;
    if (topic != null && _wantsMore(cleanText)) {
      // Si el mensaje ya trae un tema propio, es una consulta nueva.
      if (_detectTopic(cleanText) != null) return null;
      _pendingOffer = null;
      return _moreAbout(topic);
    }

    return null;
  }

  String _acceptOffer(String offer) {
    switch (offer) {
      case 'imc':
        _lastTopic = null;
        // El usuario ya aceptó: se salta la confirmación de la calculadora.
        final inicio = _calculatorService.procesarMensaje('IMC');
        if (inicio.isEmpty) return 'Escribe "IMC" para comenzar.';
        final calc = _calculatorService.procesarMensaje('si');
        return calc.isNotEmpty ? calc : inicio;
      case 'get':
        _lastTopic = null;
        // El usuario ya aceptó: se salta la confirmación de la calculadora.
        final inicioGet = _calculatorService.procesarMensaje('GET');
        if (inicioGet.isEmpty) return 'Escribe "GET" para comenzar.';
        final calcGet = _calculatorService.procesarMensaje('si');
        return calcGet.isNotEmpty ? calcGet : inicioGet;
      case 'mision':
        _lastTopic = 'mision';
        return getNutriResponse('mision');
      case 'recordatorio':
        _lastTopic = 'recordatorio';
        return getNutriResponse('recordatorio');
      case 'profesional':
        _lastTopic = 'profesional';
        return getNutriResponse('profesional');
    }
    return 'Claro. ¿Sobre qué te gustaría profundizar?';
  }

  String _moreAbout(String topic) {
    // Estos temas ya tienen varias respuestas distintas.
    if (topic == 'desayuno' || topic == 'proteina') {
      return getNutriResponse(topic);
    }
    if (topic == 'consejo_habito') {
      return getNutriResponse('dame un consejo');
    }

    final details = _topicDetails[topic] ?? const <String>[];
    final index = _detailIndex[topic] ?? 0;

    if (index >= details.length) {
      _lastTopic = null;
      return 'Ya te compartí lo principal sobre este tema. Si quieres, pregúntame otra cosa: hábitos, sueño, ejercicio, alimentación, tu IMC o tus calorías (GET).';
    }

    _detailIndex[topic] = index + 1;
    return details[index];
  }

  String _buildContextualResponse(String text, String normalizedText) {
    final clean = _cleanForMatch(normalizedText);

    final followUp = _resolveFollowUp(clean);
    if (followUp != null) return followUp;

    _branchTopic = null;
    final response = getNutriResponse(text);
    final topic = _branchTopic ?? _detectTopic(normalizedText);
    _pendingOffer = null;

    if (topic != null) {
      _lastTopic = topic;
      _detailIndex[topic] = 0;

      final offer = _offers[topic];
      if (offer != null) {
        _pendingOffer = offer.action;
        return '$response\n\n${offer.question}';
      }
    } else if (response != _fallbackResponse) {
      // Respondió algo que no es un tema seguible (saludo, contraseña...).
      _lastTopic = null;
    }

    return response;
  }

  final Map<String, int> _lastVariant = {};

  /// Elige una respuesta al azar sin repetir la anterior del mismo tema.
  String _pickVaried(String topic, List<String> options) {
    var index = Random().nextInt(options.length);
    if (options.length > 1 && index == _lastVariant[topic]) {
      index =
          (index + 1 + Random().nextInt(options.length - 1)) % options.length;
    }
    _lastVariant[topic] = index;
    return options[index];
  }

  bool _containsProfanity(String text) {
    final normalized = _normalizeText(text);
    if (normalized.isEmpty) return false;

    // Palabras completas (con plural), para no bloquear "cálculo" o "músculo".
    return offensiveWords.any((word) {
      final key = _normalizeText(word);
      if (key.isEmpty) return false;
      return RegExp(
        r'(^|[^a-z0-9])' + RegExp.escape(key) + r'(s|es)?($|[^a-z0-9])',
      ).hasMatch(normalized);
    });
  }

  bool _containsAny(String text, List<String> keywords) =>
      containsAnyKeyword(text, keywords);

  String _normalizeText(String value) => normalizeText(value);

  @override
  void dispose() {
    ChatHistoryStore.instance.discardIfEmpty(_session);
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9F8),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF172B36)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mr. Healthy',
              style: TextStyle(
                color: Color(0xFF172B36),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Asistente de Healthy Habit',
              style: TextStyle(
                color: Color(0xFF7A869A),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Historial',
            icon: const Icon(Icons.history_rounded, color: Color(0xFF172B36)),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ChatHistoryPage(activeSessionId: _session.id),
                  ),
                ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Hero Banner de Mr. Healthy
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 120,
                            height: 6,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFF172B36),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/mascot/healthy.png',
                                width: 56,
                                height: 56,
                                errorBuilder:
                                    (context, error, stackTrace) => const Icon(
                                      Icons.eco_rounded,
                                      color: Color(0xFF00C88C),
                                      size: 48,
                                    ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2F7ED),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'A TU RITMO',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF198568),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Un pequeño paso, juntos.',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF172B36),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Lista de Mensajes
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: messages.length + (isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= messages.length) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Mr. Healthy está escribiendo...',
                              style: TextStyle(
                                color: Color(0xFF198568),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        }
                        return _buildMessageBubble(messages[index]);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Sugerencias rápidas verticales
                    Text(
                      _calculatorService.opcionesRapidas.isNotEmpty
                          ? 'Elige una opción'
                          : 'Sugerencias rápidas',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7A869A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children:
                          (_calculatorService.opcionesRapidas.isNotEmpty
                                  ? _calculatorService.opcionesRapidas
                                  : quickOptions)
                              .map((option) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap:
                                        isTyping
                                            ? null
                                            : () => sendMessage(option),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFFE5EEE9),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              option,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF172B36),
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.north_east_rounded,
                                            size: 18,
                                            color: Color(0xFF198568),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Input inferior con caja blanca redondeada y nota médica
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              color: const Color(0xFFF7F9F8),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFFE5EEE9),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 18),
                        Expanded(
                          child: TextField(
                            controller: messageController,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 1,
                            maxLines: 3,
                            onSubmitted: (_) => sendMessage(),
                            decoration: const InputDecoration(
                              hintText: 'Escribe a Mr. Healthy...',
                              hintStyle: TextStyle(
                                color: Color(0xFF8A8F98),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: InkWell(
                            onTap: isTyping ? null : () => sendMessage(),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFF8DE0C0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                color: Color(0xFF172B36),
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Healthy Habit no realiza diagnósticos ni sustituye atención médica profesional.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8A8F98),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF172B36) : const Color(0xFFE2F7ED),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(isUser ? 22 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 22),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFF172B36),
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isUser ? 'Tú · ${message.time}' : 'Mr. Healthy · ${message.time}',
              style: TextStyle(
                color: isUser ? Colors.white60 : const Color(0xFF198568),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
