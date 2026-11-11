import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'nutri_calculator_service.dart';
import 'texto_chatbot.dart';
import 'package:healthy_habit/servicios/clima_servicio.dart';
import 'package:healthy_habit/servicios/firebase_servicios.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  ChatMessage({required this.text, required this.isUser, required this.time});
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
    messages = [
      ChatMessage(
        text:
            '¡Hola, $initialName! Puedo resolver dudas sobre la app, tus misiones y tus hábitos, aunque algo limitado aún. ¿Por dónde empezamos?',
        isUser: false,
        time: _getFormattedTime(),
      ),
    ];
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
      _responderClima();
      return;
    }

    final respuesta =
        (isActiveCalculatorFlow || isImcIntent || isGetIntent || isQuickOption)
            ? _calculatorService.procesarMensaje(text)
            : '';
    final response = respuesta.isNotEmpty ? respuesta : getNutriResponse(text);

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

    const List<String> consejosHabitos = [
      '1. Bebe un vaso de agua al despertar y mantén una botella a la mano durante el día.',
      '2. Añade una porción de verdura o fruta a cada comida.',
      '3. Camina al menos 20-30 minutos al día.',
      '4. Duerme entre 7 y 9 horas a la misma hora.',
    ];

    if (_containsAny(text, [
      'habito',
      'consejo',
      'recomendacion',
      'tip',
      'sugerencia',
    ])) {
      final consejo = consejosHabitos[Random().nextInt(consejosHabitos.length)];
      return 'Aquí tienes una sugerencia práctica:\n\n$consejo';
    }

    return 'Puedo ayudarte con hábitos, misiones, hidratación, sueño, ejercicio, alimentación, recordatorios, logros o con el cálculo de tu IMC y tus calorías (GET). ¿Sobre cuál te gustaría profundizar?';
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
