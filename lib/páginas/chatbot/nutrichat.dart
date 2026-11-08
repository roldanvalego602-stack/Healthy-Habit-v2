import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'nutri_calculator_service.dart';
import 'nutri_respuestas_service.dart';

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
  static const _background = Color(0xFFF7F9F8);
  static const _navy = Color(0xFF172B36);
  static const _muted = Color(0xFF7A869A);
  static const _green = Color(0xFF198568);

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  final NutriCalculatorService _calculatorService = NutriCalculatorService();

  final NutriRespuestasService _respuestas = NutriRespuestasService();
  Map<String, dynamic> _perfil = <String, dynamic>{};
  String _primerNombre = '';
  bool isTyping = false;
  bool _hasSentMessage = false;

  final List<ChatMessage> messages = [
    ChatMessage(
      text:
          '¡Hola! Soy Mr. Healthy. Puedo ayudarte con dudas sobre la app, tus misiones y tus hábitos. ¿Por dónde empezamos?',
      isUser: false,
      time: _timeNow(),
    ),
  ];

  final List<String> quickOptions = const [
    '¿Cómo mejorar mi racha?',
    '¿Qué misión tengo hoy?',
    'Quiero mejorar mi hidratación',
    'Hablar con un profesional',
    'Sugiere hábitos para mí',
    '¿Cómo va mi perfil?',
    'Quiero calcular mi GET',
  ];

  static String _timeNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _inputFocus.addListener(_onFocusChange);
    _cargarSaludoPersonalizado();
  }

  Future<void> _cargarSaludoPersonalizado() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // El nombre guardado en el perfil tiene prioridad sobre el de Auth.
    String nombre = (user.displayName ?? '').trim();
    try {
      final db = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );
      final snapshot = await db.collection('users').doc(user.uid).get();
      final data = snapshot.data() ?? <String, dynamic>{};
      if (!mounted) return;
      _perfil = data;
      final storedName = data['name'];
      if (storedName is String && storedName.trim().isNotEmpty) {
        nombre = storedName.trim();
      }
    } catch (_) {
      // Sin conexión o sin permisos: usar el nombre de Auth si existe.
    }

    if (!mounted) return;
    _primerNombre = nombre.isEmpty ? '' : nombre.split(RegExp(r'\s+')).first;
    if (_hasSentMessage || nombre.isEmpty) return;
    final primerNombre = _primerNombre;
    setState(() {
      messages[0] = ChatMessage(
        text:
            '¡Hola, $primerNombre! Soy Mr. Healthy. Puedo ayudarte con dudas sobre la app, tus misiones y tus hábitos. ¿Por dónde empezamos?',
        isUser: false,
        time: messages[0].time,
      );
    });
  }

  void _onFocusChange() {
    if (_inputFocus.hasFocus) {
      // Espera al ajuste de tamaño causado por el teclado.
      Future<void>.delayed(const Duration(milliseconds: 250), _scrollToBottom);
    }
  }

  Future<void> sendMessage([String? predefinedText]) async {
    if (!mounted || isTyping) return;
    final text = (predefinedText ?? messageController.text).trim();
    if (text.isEmpty) return;

    messageController.clear();
    setState(() {
      _hasSentMessage = true;
      messages.add(ChatMessage(text: text, isUser: true, time: _timeNow()));
      isTyping = true;
    });
    _scrollToBottom();

    String response;
    try {
      final normalized = NutriRespuestasService.normalizar(text);
      // Moderación antes de los flujos: el lenguaje ofensivo no se procesa
      // como un dato numérico de IMC/GET. No se bloquea el resto del chat.
      if (NutriRespuestasService.tieneGroserias(text) ||
          NutriRespuestasService.contiene(text, [
            'suicidio',
            'suicidarme',
            'matarme',
            'hacerme daño',
            'autolesion',
          ])) {
        response = _respuestas.moderar(text, _primerNombre);
      } else if (NutriRespuestasService.contiene(normalized, [
            'cancelar',
            'salir del calculo',
            'detener calculo',
          ]) &&
          (_calculatorService.pasoIMC > 0 || _calculatorService.pasoGET > 0)) {
        _calculatorService.resetIMC();
        _calculatorService.resetGET();
        response = 'Cálculo cancelado. ¿Te ayudo con otra cosa? 🌿';
      } else {
        // Actualizar estadísticas solo cuando se preguntan; no inventar datos.
        if (NutriRespuestasService.contiene(normalized, [
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
          'como va mi perfil',
        ])) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            try {
              final snapshot =
                  await FirebaseFirestore.instanceFor(
                    app: Firebase.app(),
                    databaseId: 'default',
                  ).collection('users').doc(user.uid).get();
              _perfil = snapshot.data() ?? <String, dynamic>{};
            } catch (_) {
              _perfil = <String, dynamic>{};
            }
          } else {
            _perfil = <String, dynamic>{};
          }
        }
        final activeCalculator =
            _calculatorService.pasoIMC > 0 || _calculatorService.pasoGET > 0;
        final calculatorIntent = NutriRespuestasService.contiene(normalized, [
          'imc',
          'indice de masa corporal',
          'get',
          'gasto energetico',
          'calorias diarias',
          'calcular mi get',
        ]);
        final calcResponse =
            (activeCalculator || calculatorIntent)
                ? _calculatorService.procesarMensaje(text)
                : '';
        response =
            calcResponse.isNotEmpty
                ? calcResponse
                : _respuestas.responder(
                  text,
                  nombre: _primerNombre,
                  perfil: _perfil,
                );
      }
    } catch (_) {
      response =
          'Tuve un problema al preparar la respuesta. Intenta de nuevo en un momento. 🌿';
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      messages.add(
        ChatMessage(text: response, isUser: false, time: _timeNow()),
      );
      isTyping = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _inputFocus.removeListener(_onFocusChange);
    _inputFocus.dispose();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: _background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _navy),
          onPressed: () => Navigator.maybePop(context),
        ),
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mr. Healthy',
              style: TextStyle(
                color: _navy,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Asistente de Healthy Habit',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/mascot/healthy.png',
              width: 38,
              height: 38,
              fit: BoxFit.contain,
              errorBuilder:
                  (_, __, ___) => const Icon(Icons.eco, color: _green),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                itemCount:
                    1 +
                    messages.length +
                    (isTyping ? 1 : 0) +
                    (!_hasSentMessage && !keyboardVisible ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _hasSentMessage || keyboardVisible
                        ? const SizedBox.shrink()
                        : _buildWelcome();
                  }
                  final messageIndex = index - 1;
                  if (messageIndex < messages.length) {
                    return _buildMessageBubble(messages[messageIndex]);
                  }
                  if (isTyping && messageIndex == messages.length) {
                    return const Padding(
                      padding: EdgeInsets.only(left: 6, bottom: 14),
                      child: Text(
                        'Mr. Healthy está escribiendo…',
                        style: TextStyle(
                          color: _green,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  }
                  return _buildQuickOptions();
                },
              ),
            ),
            _buildComposer(keyboardVisible),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      children: [
        Image.asset(
          'assets/mascot/healthy.png',
          width: 52,
          height: 52,
          errorBuilder:
              (_, __, ___) => const Icon(Icons.eco, size: 45, color: _green),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A TU RITMO',
                style: TextStyle(
                  fontSize: 10,
                  color: _green,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Un pequeño paso, juntos.',
                maxLines: 2,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: _navy,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildQuickOptions() => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preguntas frecuentes',
          style: TextStyle(
            color: _muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...quickOptions.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: isTyping ? null : () => sendMessage(option),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5EEE9)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _navy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: _green,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildComposer(bool keyboardVisible) => Container(
    padding: EdgeInsets.fromLTRB(14, 8, 14, keyboardVisible ? 8 : 12),
    decoration: const BoxDecoration(
      color: _background,
      border: Border(top: BorderSide(color: Color(0xFFE5EEE9))),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 16, right: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFDDE8E2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  focusNode: _inputFocus,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 3,
                  onSubmitted: (_) => sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Escribe a Mr. Healthy…',
                    hintStyle: TextStyle(
                      color: Color(0xFF8A8F98),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              IconButton.filled(
                onPressed: isTyping ? null : () => sendMessage(),
                icon: const Icon(Icons.arrow_upward_rounded, size: 21),
                tooltip: 'Enviar mensaje',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF8DE0C0),
                  foregroundColor: _navy,
                  disabledBackgroundColor: const Color(0xFFE5EEE9),
                ),
              ),
            ],
          ),
        ),
        if (!keyboardVisible) ...[
          const SizedBox(height: 8),
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
      ],
    ),
  );

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? _navy : const Color(0xFFE2F7ED),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : _navy,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${isUser ? 'Tú' : 'Mr. Healthy'} · ${message.time}',
              style: TextStyle(
                color: isUser ? Colors.white70 : _green,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
