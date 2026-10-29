import 'dart:math';
import 'package:flutter/material.dart';
import 'nutri_calculator_service.dart';

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
  bool isTyping = false;

  final List<ChatMessage> messages = [
    ChatMessage(
      text:
          '¡Hola, Diego! Puedo resolver dudas sobre la app, tus misiones y tus hábitos, aunque algo limitado aún. ¿Por dónde empezamos?',
      isUser: false,
      time: '9:40',
    ),
  ];

  final List<String> quickOptions = [
    '¿Cómo mejorar mi racha?',
    '¿Qué misión tengo hoy?',
    'Quiero mejorar mi hidratación',
    'Hablar con un profesional',
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

    final normalizedText = _normalizeText(text);
    final isActiveCalculatorFlow =
        _calculatorService.pasoIMC > 0 || _calculatorService.pasoGET > 0;
    final isQuickOption = quickOptions.any(
      (option) => _normalizeText(option) == normalizedText,
    );
    final isImcIntent = _containsAny(normalizedText, [
      'imc',
      'indice de masa corporal',
    ]);
    final respuesta =
        (isActiveCalculatorFlow || isImcIntent || isQuickOption)
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

    if (_containsAny(text, ['racha', 'como mejorar mi racha'])) {
      return 'Para mantener tu racha activa, asegúrate de completar y registrar al menos un hábito o misión principal al día antes de que termine la jornada.';
    }

    if (_containsAny(text, ['mision', 'misión', 'que mision tengo hoy'])) {
      return 'Tu misión destacada de hoy es Hidratación (4 de 6 vasos de agua tomados). ¡Solo te faltan 2 vasos para completarla!';
    }

    if (_containsAny(text, [
      'hidratacion',
      'hidratación',
      'quiero mejorar mi hidratacion',
    ])) {
      return 'Puedes asociar tu hábito a un momento cotidiano y configurar un recordatorio en Hábitos → Hidratación.\n\nEs una idea general, no una indicación médica. Si necesitas orientación individual, consulta a un profesional.';
    }

    if (_containsAny(text, ['profesional', 'hablar con un profesional'])) {
      return 'Puedes consultar la pestaña de Orientación Profesional en el menú principal para contactar con nutriólogos y psicólogos capacitados.';
    }

    const List<String> consejosHabitos = [
      '1. Bebe un vaso de agua al despertar y mantén una botella a la mano durante el día.',
      '2. Añade una porción de verdura o fruta a cada comida.',
      '3. Camina al menos 20-30 minutos al día.',
      '4. Duerme entre 7 y 9 horas a la misma hora.',
    ];

    if (_containsAny(text, ['habito', 'habitos', 'consejo'])) {
      final consejo = consejosHabitos[Random().nextInt(consejosHabitos.length)];
      return 'Aquí tienes una sugerencia práctica:\n\n$consejo';
    }

    return 'Puedo ayudarte con información sobre hábitos, misiones diarias, hidratación o cálculo de tu IMC/GET. ¿Sobre cuál te gustaría profundizar?';
  }

  bool _containsAny(String text, List<String> keywords) {
    final normalized = _normalizeText(text);
    return keywords.any((keyword) {
      final key = _normalizeText(keyword);
      if (key.isEmpty) return false;
      final pattern = RegExp(
        r'(^|[^a-z0-9])' + RegExp.escape(key) + r'($|[^a-z0-9])',
      );
      return pattern.hasMatch(normalized);
    });
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

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
                    const Text(
                      'Sugerencias rápidas',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7A869A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children:
                          quickOptions.map((option) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap:
                                    isTyping ? null : () => sendMessage(option),
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
                          }).toList(),
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
