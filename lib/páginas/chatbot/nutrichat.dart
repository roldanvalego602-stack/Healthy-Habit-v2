import 'package:flutter/material.dart';
import 'healthy_typing_indicator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import '../../tema/healthy_theme.dart';
import '../../tema/healthy_coin.dart';
import '../../servicios/healthy_retro_sound_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'nutri_calculator_service.dart';
import '../../servicios/clima_servicio.dart';
import 'nutri_respuestas_service.dart';
import 'healthy_conversation_service.dart';
import 'healthy_assistant_engine.dart';
import 'healthy_hybrid_knowledge.dart';
import 'healthy_intent_router.dart';
import 'healthy_chat_context.dart';
import 'healthy_chat_history.dart';
import 'healthy_chat_history_sheet.dart';
import 'healthy_chat_habit_card.dart';
import 'healthy_chat_store_card.dart';
import 'healthy_chat_progress_cards.dart';
import 'healthy_chat_profile_editor.dart';
import 'healthy_chat_catalog_card.dart';
import '../catalogo/catalogo_screen.dart';
import '../catalogo/detalles/catalogo_detalle_screen.dart';
import '../catalogo/modelos/catalogo_item.dart';
import 'healthy_chat_habit_picker.dart';
import '../habitos/modelo/habit.dart';
import '../../tema/healthy_visual_mode.dart';
import '../../tema/healthy_celebration.dart';
import '../habitos/habit_action_service.dart';
import '../habitos/habits_screen.dart';
import '../estadisticas/progreso_screen.dart';
import '../perfil/profesionales_screen.dart';
import '../perfil/profile_screen.dart';
import '../niveles/camino_niveles_screen.dart';
import '../niveles/levels_system.dart';
import '../ranking_screen.dart';
import '../tienda/store_screen.dart';
import '../desafios/desafios_screen.dart';
import '../logros/logros_screen.dart';
import '../perfil/editar_perfil_screen.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String time;
  final String action;
  final String argument;
  final String card;

  ChatMessage({required this.text, required this.isUser, required this.time,
    this.action = '', this.argument = '', this.card = ''});

  factory ChatMessage.fromRecord(HealthyChatRecord record) => ChatMessage(
    text: record.text, isUser: record.isUser,
    time: '${record.createdAt.hour.toString().padLeft(2, '0')}:${record.createdAt.minute.toString().padLeft(2, '0')}',
    action: record.action, argument: record.actionArgument, card: record.card,
  );
}

class NutriChatPage extends StatefulWidget {
  const NutriChatPage({super.key});

  @override
  State<NutriChatPage> createState() => _NutriChatPageState();
}

class _NutriChatPageState extends State<NutriChatPage> {
  Color get _background => HealthyAdaptive.background;
  Color get _navy => HealthyAdaptive.text;
  Color get _muted => HealthyAdaptive.muted;
  static const _green = Color(0xFF198568);

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  final NutriCalculatorService _calculatorService = NutriCalculatorService();
  final ClimaServicio _climaServicio = ClimaServicio();

  final NutriRespuestasService _respuestas = NutriRespuestasService();
  final HealthyHybridKnowledge _hybridKnowledge = HealthyHybridKnowledge();
  final HealthyConversationService _conversation =
      const HealthyConversationService();
  final HealthyAssistantEngine _engine = const HealthyAssistantEngine();
  final HealthyChatHistory _history = const HealthyChatHistory();
  String? _sessionId;
  String _lastTopic = '';
  final HealthyChatContext _chatContext = HealthyChatContext();
  String _lastHabitTitle = '';
  String _lastShopItemId = '';
  bool _historyLoading = false;
  bool _manuallyStartedNew = false;
  List<Map<String, dynamic>> _habitosPerfil = [];
  bool _allowHistoryAnalysis = false;
  Map<String, dynamic> _perfil = <String, dynamic>{};
  String _primerNombre = '';
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _voiceReady = false;
  bool _listening = false;
  bool _readAloud = true; // Bips originales; no voz hablada.
  String? _voiceError;
  bool isTyping = false;
  bool _replyPending = false;
  bool _hasDraft = false;
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
    '¿Quién eres?',
    'Cuéntame una historia',
    '¿Qué es la inteligencia artificial?',
    '¿Cómo va mi perfil?',
    'Mis desafíos',
    '¿Qué logros tengo?',
    'Quiero comprar corona',
    'Editar mi perfil',
    'Agregar un hábito',
    'Ver mis estadísticas',
    'Hablar con un profesional',
    '¿Qué nutrientes tienen las lentejas?',
    'Muéstrame los beneficios de la avena',
    'Quiero calcular mi GET',
    '¿Cómo mejorar mi racha?',
    '¿Qué misión tengo hoy?',
    'Quiero mejorar mi hidratación',
    'Sugiere hábitos para mí',
    '¿Cómo está el clima hoy?',
  ];

  static String _timeNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _inputFocus.addListener(_onFocusChange);
    messageController.addListener(_onDraftChanged);
    _cargarSaludoPersonalizado();
    _loadRecentChat();
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    try {
      _voiceReady = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            setState(() => _listening = false);
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _listening = false;
            _voiceError = 'No se pudo reconocer la voz. Revisa el micrófono.';
          });
        },
      );
      if (!_voiceReady) {
        if (mounted) setState(() => _voiceError = 'El reconocimiento de voz no está disponible en este dispositivo.');
        return;
      }
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: 'es_MX',
          listenFor: const Duration(seconds: 25),
          pauseFor: const Duration(seconds: 3),
        ),
        onResult: (result) {
          if (!mounted) return;
          messageController.value = TextEditingValue(
            text: result.recognizedWords,
            selection: TextSelection.collapsed(offset: result.recognizedWords.length),
          );
          if (result.finalResult) setState(() => _listening = false);
        },
      );
      if (mounted) {
        setState(() {
          _listening = true;
          _voiceError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _listening = false;
          _voiceError = 'No fue posible iniciar el micrófono.';
        });
      }
    }
  }

  void _toggleReadAloud() {
    if (mounted) setState(() => _readAloud = !_readAloud);
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

  Future<void> _loadRecentChat() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      final sessions = await _history.watchSessions().first;
      if (!mounted || _hasSentMessage || _manuallyStartedNew || sessions.isEmpty) return;
      await _openSession(sessions.first.id);
    } catch (_) {
      // El chat sigue disponible si Firestore no permite consultar el historial.
    }
  }

  Future<void> _openSession(String id) async {
    if (isTyping) return;
    _calculatorService.reset();
    setState(() => _historyLoading = true);
    try {
      final records = await _history.loadMessages(id);
      if (!mounted) return;
      setState(() {
        _manuallyStartedNew = false;
        _sessionId = id;
        messages
          ..clear()
          ..addAll(records.map(ChatMessage.fromRecord));
        if (messages.isEmpty) {
          messages.add(ChatMessage(
            text: '¡Hola! Soy Mr. Healthy. ¿En qué te ayudo?',
            isUser: false, time: _timeNow()));
        }
        _hasSentMessage = records.isNotEmpty;
        _lastTopic = '';
        _chatContext.reset();
        _lastHabitTitle = '';
        _lastShopItemId = '';
        for (final record in records.reversed) {
          if (record.card == 'shop_item' &&
              record.actionArgument.isNotEmpty) {
            _lastShopItemId = record.actionArgument;
            break;
          }
        }
        for (final record in records.reversed) {
          if (record.action == 'habits' &&
              record.actionArgument.isNotEmpty) {
            _lastHabitTitle = record.actionArgument;
            break;
          }
        }
        for (final record in records.reversed) {
          if (!record.isUser) {
            _lastTopic = const [
              'habit_add','habit_remove','profile','shop_item',
            ].contains(record.card) ? record.card : '';
            break;
          }
        }
      });
      await _refreshAssistantData();
      if (mounted) setState(() {});
      _scrollToBottom();
    } catch (_) {
      _chatNotice('No se pudo abrir el historial de ese chat.');
    } finally {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  void _newConversation() {
    if (isTyping) return;
    _calculatorService.reset();
    setState(() {
      _manuallyStartedNew = true;
      _sessionId = null;
      _lastTopic = '';
      _chatContext.reset();
      _lastHabitTitle = '';
      _lastShopItemId = '';
      _hasSentMessage = false;
      messages
        ..clear()
        ..add(ChatMessage(
          text: '¡Hola! Soy Mr. Healthy. ¿En qué te ayudo?',
          isUser: false,
          time: _timeNow(),
        ));
    });
  }

  void _chatNotice(String notice) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(notice)));
  }

  Future<void> _persist(ChatMessage message, {bool first = false}) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      _sessionId ??= await _history.createSession();
      await _history.saveMessage(_sessionId!, text: message.text,
        isUser: message.isUser, action: message.action,
        actionArgument: message.argument, card: message.card,
        isFirstUserMessage: first && message.isUser);
    } catch (_) {
      _chatNotice('No se pudo sincronizar este mensaje con el historial.');
    }
  }

  Future<bool> _refreshAssistantData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _perfil = {};
      _habitosPerfil = [];
      _allowHistoryAnalysis = false;
      return false;
    }
    final userRef = FirebaseFirestore.instanceFor(
      app: Firebase.app(), databaseId: 'default',
    ).collection('users').doc(user.uid);
    try {
      final result = await userRef.get();
      if (!result.exists) return false;
      _perfil = result.data() ?? {};
      final rawSettings = _perfil['settings'];
      _allowHistoryAnalysis =
          rawSettings is Map && rawSettings['analizarHistorialIA'] == true;
      if (!_allowHistoryAnalysis) {
        _habitosPerfil = [];
        return true;
      }
    } catch (_) {
      _perfil = {};
      _habitosPerfil = [];
      _allowHistoryAnalysis = false;
      return false;
    }
    try {
      final result = await userRef.collection('user_habits').limit(100).get();
      _habitosPerfil = result.docs.map((d) => d.data()).toList();
    } catch (_) {
      _habitosPerfil = [];
    }
    return true;
  }

  Future<void> _openOfficialSource(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' ||
        !const {'fdc.nal.usda.gov', 'www.who.int', 'www.fda.gov'}.contains(uri.host)) {
      _chatNotice('Fuente externa no disponible o no verificada.');
      return;
    }
    try {
      final opened = await launchUrl(
        uri, mode: LaunchMode.externalApplication);
      if (!opened) _chatNotice('No fue posible abrir la fuente.');
    } catch (_) {
      _chatNotice('No fue posible abrir la fuente.');
    }
  }

  Future<void> _chooseHabitForChat(bool remove) async {
    if (isTyping || _historyLoading) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: HealthyAdaptive.surface,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => HealthyChatHabitPicker(
        remove: remove,
        onSelected: (habit) => _onHabitPicked(habit, remove),
      ),
    );
  }

  Future<void> _onHabitPicked(Habit habit, bool remove) async {
    if (!mounted || isTyping) return;
    final first = _sessionId == null;
    final cardType = remove ? 'habit_remove' : 'habit_add';
    final user = ChatMessage(
      text: '${remove ? 'Abandonar' : 'Agregar'}: ${habit.title}',
      isUser: true, time: _timeNow());
    final bot = ChatMessage(
      text: remove
          ? 'Elegiste «${habit.title}». Verificaré el intento activo '
              'y su posible penalización antes de pedirte confirmación.'
          : 'Elegiste «${habit.title}». Revisaré tus cupos, '
              'monedas y requisitos antes de solicitar confirmación.',
      isUser: false, time: _timeNow(),
      action: 'habits', argument: habit.title, card: cardType,
    );
    setState(() {
      messages.addAll([user, bot]);
      _hasSentMessage = true;
      _lastTopic = cardType;
      _lastHabitTitle = habit.title;
      isTyping = true;
    });
    _scrollToBottom();
    await _persist(user, first: first);
    await _persist(bot);
    if (mounted) setState(() => isTyping = false);
  }

  void _openCatalogItem(CatalogoItem item) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CatalogoDetalleScreen(item: item),
    ));
  }

  Future<void> _onShopCommitted(String detail) async {
    await _refreshAssistantData();
    if (!mounted) return;
    final reply = ChatMessage(
      text: detail,
      isUser: false,
      time: _timeNow(),
      card: 'shop_result',
      action: 'shop',
    );
    setState(() => messages.add(reply));
    HealthyCelebration.show(
      context,
      title: '¡Apariencia actualizada!',
      subtitle: detail,
      icon: Icons.auto_awesome_rounded,
    );
    _scrollToBottom();
    await _persist(reply);
  }

  Future<void> _onHabitActionCompleted(HabitActionResult result) async {
    await _refreshAssistantData();
    if (!mounted) return;
    final text = result.removed
        ? 'Confirmado: «${result.habit.title}» fue abandonado. '
          'Se descontaron ${result.chargedCoins} Habit Coins y tu historial permanece disponible.'
        : 'Confirmado: «${result.habit.title}» se agregó a tus hábitos activos. '
          'Puedes registrar tu progreso desde Hábitos.';
    final message = ChatMessage(
      text: text, isUser: false, time: _timeNow(),
      action: 'habits', argument: result.habit.title,
      card: 'habit_result',
    );
    setState(() {
      messages.add(message);
    });
    HealthyCelebration.show(context,
      title: result.removed ? 'Hábito actualizado' : '¡Nuevo hábito!',
      subtitle: result.removed
          ? 'Tu historial se conservó.'
          : 'Puedes comenzar a registrar tus avances.',
      icon: result.removed
          ? Icons.task_alt_rounded
          : Icons.emoji_events_rounded,
    );
    _scrollToBottom();
    await _persist(message);
  }

  void _navigateFromChat(ChatMessage message) {
    if (message.action == 'source') {
      _openOfficialSource(message.argument);
      return;
    }
    Widget? target;
    switch (message.action) {
      case 'habits':
        target = HabitsScreen(initialSearch: message.argument);
        break;
      case 'progress':
        target = const ProgresoScreen();
        break;
      case 'professionals':
        target = const ProfesionalesScreen();
        break;
      case 'profile':
        target = const ProfileScreen();
        break;
      case 'levels':
        final raw = _perfil['xp'] ?? _perfil['currentXp'];
        target = CaminoNivelesScreen(
          xp: raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0);
        break;
      case 'ranking':
        target = const RankingScreen();
        break;
      case 'shop':
        target = const StoreScreen();
        break;
      case 'catalog':
        target = const CatalogoScreen();
        break;
      case 'catalog_item':
        final item = HealthyChatCatalogCard.findById(message.argument);
        if (item != null) target = CatalogoDetalleScreen(item: item);
        break;
      case 'challenges':
        target = const DesafiosScreen();
        break;
      case 'achievements':
        target = const LogrosScreen();
        break;
      case 'edit_profile':
        target = const EditarPerfilScreen();
        break;
    }
    if (target != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => target!))
          .then((_) async {
        await _refreshAssistantData();
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _showChatHistory() async {
    if (FirebaseAuth.instance.currentUser == null) {
      _chatNotice('Inicia sesión para guardar conversaciones.');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: HealthyAdaptive.surface,
      builder: (_) => HealthyChatHistorySheet(
        history: _history,
        activeId: _sessionId,
        onSelected: _openSession,
        onNew: _newConversation,
      ),
    );
  }

  void _onDraftChanged() {
    final value = messageController.text.trim().isNotEmpty;
    if (mounted && value != _hasDraft) setState(() => _hasDraft = value);
  }

  void _onFocusChange() {
    if (_inputFocus.hasFocus) {
      // Espera al ajuste de tamaño causado por el teclado.
      Future<void>.delayed(const Duration(milliseconds: 250), _scrollToBottom);
    }
  }

  Future<void> sendMessage([String? predefinedText]) async {
    if (!mounted || isTyping || _historyLoading) return;
    final text = (predefinedText ?? messageController.text).trim();
    final startedAt = DateTime.now();
    if (text.isEmpty) return;
    final first = _sessionId == null;
    final previousUserMessage = messages
        .where((message) => message.isUser)
        .map((message) => message.text)
        .toList();
    final lastUserPrompt = previousUserMessage.isEmpty
        ? '' : previousUserMessage.last;
    final userMessage = ChatMessage(
      text: text, isUser: true, time: _timeNow());

    messageController.clear();
    if (_listening) {
      await _speech.stop();
      _listening = false;
    }
    await _tts.stop();
    setState(() {
      _hasSentMessage = true;
      messages.add(userMessage);
      isTyping = true;
      _replyPending = true;
    });
    _scrollToBottom();

    String response = '';
    HealthyAssistantReply intent = const HealthyAssistantReply('');
    try {
      // Los mensajes se guardan en orden cronológico por conversación.
      final normalized = NutriRespuestasService.normalizar(text);
      final danger = NutriRespuestasService.contiene(text, [
        'suicidio', 'suicidarme', 'matarme', 'hacerme daño', 'autolesion',
      ]);
      if (danger) {
        response = _respuestas.moderar(text, _primerNombre);
      } else if (NutriRespuestasService.ataqueDiscriminatorio(text) || NutriRespuestasService.tieneGroserias(text)) {
        response = _respuestas.moderar(text, _primerNombre);
      } else if (NutriRespuestasService.contiene(normalized, [
        'cancelar', 'salir del calculo', 'detener calculo',
      ]) && (_calculatorService.pasoIMC > 0 ||
            _calculatorService.pasoGET > 0)) {
        _calculatorService.reset();
        response = 'Cálculo cancelado. ¿Te ayudo con otra cosa? 🌿';
      } else {
        final activeCalculator = _calculatorService.pasoIMC > 0 ||
            _calculatorService.pasoGET > 0;
        final calculatorIntent = NutriRespuestasService.contiene(normalized, [
          'imc','indice de masa corporal','get','gasto energetico',
          'calorias diarias','calcular mi get',
        ]);
        final calc = activeCalculator || calculatorIntent
            ? _calculatorService.procesarMensaje(text) : '';
        if (calc.isNotEmpty) {
          response = calc;
        } else if (NutriRespuestasService.contiene(normalized, const [
          'clima', 'pronostico', 'va a llover', 'esta lloviendo',
          'temperatura de hoy', 'tiempo meteorologico',
        ])) {
          // Mijo: clima real por solicitud explícita, sin ubicación por IP.
          try {
            final weather = await _climaServicio.obtenerClimaActual();
            response = weather.mensaje;
            intent = HealthyAssistantReply(
              response, card: 'weather');
          } on ClimaException catch (error) {
            response = error.message;
          }
        } else {
          final requiresProfile = HealthyIntentRouter.asksForCoinBalance(text) ||
              NutriRespuestasService.contiene(normalized, [
            'mi perfil','mis datos','mis estadisticas','mi progreso',
            'mi nivel','mi xp','mis xp','habit coins','monedas','racha',
            'mis habitos','habitos activos','que habitos tengo',
            'mis actividades','camino de xp',
            'subir de nivel','mi posicion','cuanto he avanzado','cuantos xp',
            'tienda','armario','canjear',
          ]) || _lastTopic == 'profile';
          final available = !requiresProfile ||
              await _refreshAssistantData();
          if (!available) {
            response = 'No pude consultar tus datos actualizados. '
                'Revisa tu conexión e inténtalo de nuevo; no inventaré XP ni monedas.';
          } else if (!_allowHistoryAnalysis &&
              NutriRespuestasService.contiene(normalized, const [
                'mis habitos', 'habitos activos', 'que habitos tengo',
                'mis actividades',
              ])) {
            response = 'Para consultar tus hábitos desde el asistente, activa '
                '«Permitir análisis del historial» en Configuración. '
                'Puedes seguir viendo tus hábitos desde su sección normal.';
          } else {
            if (HealthyChatContext.needsActionClarification(text)) {
              response = '¿Qué quieres modificar exactamente? '
                  'Indica qué hábito o cuenta y qué deseas hacer. '
                  'No realizaré cambios sin confirmación.';
              _chatContext.reset();
              _lastTopic = '';
              _lastHabitTitle = '';
              _lastShopItemId = '';
            } else {
              intent = _engine.resolve(text, profile: _perfil,
                  habits: _habitosPerfil, lastTopic: _lastTopic,
                  lastHabitTitle: _lastHabitTitle,
                  lastShopItemId: _lastShopItemId);
              // Los modos de personalidad no se ofrecen hasta que exista
              // un cambio de comportamiento verificable en el asistente.
              // Prioridad: acciones → conocimiento → conversación.
              if (intent.text.isNotEmpty || intent.action.isNotEmpty) {
                response = intent.text;
              } else {
                final previousKnowledge = _chatContext.referenceFor(text);
                final educational = await _hybridKnowledge.answer(
                  text, operational: intent,
                  lastKnowledgeId: previousKnowledge,
                );
                if (educational != null) {
                  intent = educational;
                  response = educational.text;
                  _chatContext.recordEducationalReply(
                    input: text,
                    knowledgeId: educational.knowledgeId,
                    previousReference: previousKnowledge,
                  );
                } else {
                  _chatContext.reset();
                  response = _conversation.reply(
                        text,
                        name: _primerNombre,
                        previousUserMessage: lastUserPrompt,
                      ) ??
                      _respuestas.responder(
                        text, nombre: _primerNombre, perfil: _perfil);
                }
              }
              if (intent.card == 'catalog_item' &&
                  intent.actionArgument == 'huevo') {
                // El catálogo también puede introducir un tema educativo.
                // La siguiente pregunta podrá referirse al huevo sin repetirlo.
                _chatContext.recordEducationalReply(
                  input: text,
                  knowledgeId: 'huevo',
                  previousReference: '',
                );
              } else if (intent.card != 'knowledge') {
                _chatContext.reset();
              }
              _lastTopic = _engine.topicFor(intent);
              if (intent.action == 'habits' &&
                  intent.actionArgument.isNotEmpty) {
                _lastHabitTitle = intent.actionArgument;
              }
              if (intent.card == 'shop_item' &&
                  intent.actionArgument.isNotEmpty) {
                _lastShopItemId = intent.actionArgument;
              }
            } // Respuesta ordinaria (no orden elíptica).
          }
        }
      }
    } catch (_) {
      response = 'Ocurrió un problema al preparar tu respuesta. '
          'Puedes intentar de nuevo.';
    }

    // Mantener visible la animación de escritura antes de la respuesta,
    // incluso si el motor local respondió de inmediato.
    final elapsed = DateTime.now().difference(startedAt);
    const minimum = Duration(milliseconds: 620);
    if (elapsed < minimum) await Future<void>.delayed(minimum - elapsed);
    if (!mounted) return;
    final botMessage = ChatMessage(
      text: response, isUser: false, time: _timeNow(),
      action: intent.action, argument: intent.actionArgument,
      card: intent.card,
    );
    setState(() {
      _replyPending = false;
      messages.add(botMessage);
    });
    _scrollToBottom();
    // La respuesta aparece de inmediato; la escritura se serializa después.
    await _persist(userMessage, first: first);
    await _persist(botMessage);
    if (mounted) setState(() => isTyping = false);
    if (_readAloud && mounted) {
      await HealthyRetroSoundService.play('talk');
    }
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
    _speech.cancel();
    _tts.stop();
    _inputFocus.removeListener(_onFocusChange);
    messageController.removeListener(_onDraftChanged);
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
          icon: Icon(Icons.arrow_back, color: _navy),
          onPressed: () => Navigator.maybePop(context),
        ),
        titleSpacing: 0,
        title: Column(
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
          IconButton(
            key: const Key('healthy-chat-audio-toggle'),
            tooltip: _readAloud ? 'Silenciar voz retro de Mr. Healthy' :
                'Activar voz retro de Mr. Healthy',
            icon: Icon(_readAloud ? Icons.volume_up_rounded :
                Icons.volume_off_rounded, color: _navy),
            onPressed: _toggleReadAloud,
          ),
          IconButton(
            key: const Key('healthy-chat-history-button'),
            onPressed: isTyping || _historyLoading ? null : _showChatHistory,
            tooltip: 'Historial de conversaciones',
            icon: Icon(Icons.history_rounded, color: _navy),
          ),
          IconButton(
            key: const Key('healthy-chat-new-button'),
            onPressed: isTyping ? null : _newConversation,
            tooltip: 'Nueva conversación',
            icon: Icon(Icons.add_comment_outlined, color: _navy),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_historyLoading)
              const LinearProgressIndicator(minHeight: 2),
            AnimatedSize(
              duration: HealthyVisualEffects.duration(
                context, const Duration(milliseconds: 220)),
              curve: Curves.easeOutCubic,
              child: _hasDraft && !isTyping
                  ? Center(
                      child: Container(
                        key: const ValueKey('mr-healthy-draft-avatar'),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: HealthyAdaptive.mint,
                          borderRadius: BorderRadius.circular(48),
                          boxShadow: const [BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 15, offset: Offset(0, 4),
                          )],
                        ),
                        child: ClipOval(
                          child: SizedBox(
                            width: 78, height: 78,
                            child: Image.asset(
                              'assets/mascot/healthy.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
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
                    (_replyPending ? 1 : 0) +
                    (!_hasSentMessage && !keyboardVisible ? 1 : 0) +
                    (_hasSentMessage && !keyboardVisible &&
                            _calculatorService.opcionesRapidas.isNotEmpty
                        ? 1 : 0),
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
                  if (_replyPending && messageIndex == messages.length) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: HealthyTypingIndicator(),
                    );
                  }
                  return _hasSentMessage
                      ? _buildCalculatorOptions()
                      : _buildQuickOptions();
                },
              ),
            ),
            if (_voiceError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(_voiceError!, style: const TextStyle(color: Colors.deepOrange, fontSize: 12)),
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
        Expanded(
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

  Widget _buildCalculatorOptions() => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Opciones del cálculo',
            style: TextStyle(color: _muted,
                fontWeight: FontWeight.w800, fontSize: 12)),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final option in _calculatorService.opcionesRapidas)
              ActionChip(
                label: Text(option),
                onPressed: isTyping ? null : () => sendMessage(option),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _buildQuickOptions() => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preguntas frecuentes',
          style: TextStyle(
            color: _muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (_calculatorService.opcionesRapidas.isNotEmpty) ...[
          Text('Opciones del cálculo',
            style: TextStyle(color: _muted,
              fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8, runSpacing: 5,
            children: [
              for (final option in _calculatorService.opcionesRapidas)
                ActionChip(
                  label: Text(option),
                  onPressed: isTyping ? null : () => sendMessage(option),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        ...quickOptions.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Material(
              color: HealthyAdaptive.surface,
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
                    border: Border.all(color: HealthyAdaptive.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
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
    decoration: BoxDecoration(
      color: _background,
      border: Border(top: BorderSide(color: HealthyAdaptive.border)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 16, right: 5),
          decoration: BoxDecoration(
            color: HealthyAdaptive.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: HealthyAdaptive.border),
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
              IconButton(
                tooltip: _listening ? 'Detener dictado' : 'Dictar mensaje',
                onPressed: isTyping ? null : _toggleListening,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    key: ValueKey(_listening),
                    color: _listening ? Colors.deepOrange : _green,
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
                  disabledBackgroundColor: HealthyAdaptive.border,
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
      child: TweenAnimationBuilder<double>(
        key: ValueKey('mr-healthy-message-${messages.indexOf(message)}'),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: HealthyVisualEffects.duration(
          context, const Duration(milliseconds: 220)),
        curve: Curves.easeOutBack,
        builder: (context, value, child) => Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: Transform.scale(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              scale: 0.82 + value * 0.18,
              child: child,
            ),
          ),
        ),
        child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? (HealthyAdaptive.isDark ? const Color(0xFF284B56) : const Color(0xFF174F48))
              : HealthyAdaptive.mint,
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
                color: isUser ? Colors.white : HealthyAdaptive.text,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (!isUser &&
                (message.card == 'habit_add' ||
                 message.card == 'habit_remove') &&
                message.argument.trim().isEmpty) ...[
              const SizedBox(height: 9),
              FilledButton.icon(
                key: const Key('mr-healthy-pick-habit'),
                onPressed: isTyping ? null : () =>
                    _chooseHabitForChat(message.card == 'habit_remove'),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Seleccionar hábito'),
              ),
            ],
            if (!isUser &&
                (message.card == 'habit_add' ||
                 message.card == 'habit_remove') &&
                message.argument.trim().isNotEmpty) ...[
              HealthyChatHabitCard(
                habitTitle: message.argument,
                remove: message.card == 'habit_remove',
                onCompleted: (result) => _onHabitActionCompleted(result),
              ),
            ],
            if (!isUser &&
                (message.card == 'shop_item' ||
                 message.card == 'shop_picker')) ...[
              HealthyChatStoreCard(
                initialItemId: message.argument,
                onCommitted: _onShopCommitted,
              ),
            ],
            if (!isUser && message.card == 'challenges') ...[
              HealthyChatChallengesCard(
                onOpen: () => _navigateFromChat(message),
              ),
            ],
            if (!isUser && message.card == 'achievements') ...[
              HealthyChatAchievementsCard(
                onOpen: () => _navigateFromChat(message),
              ),
            ],
            if (!isUser && message.card == 'edit_profile') ...[
              HealthyChatProfileEditor(
                onEdit: () => _navigateFromChat(message),
              ),
            ],
            if (!isUser && message.card == 'weather') ...[
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.cloud_outlined, size: 18,
                  color: HealthyAdaptive.accent),
                const SizedBox(width: 7),
                Expanded(child: Text(
                  'Clima actual · Open-Meteo · ubicación aproximada',
                  style: TextStyle(fontSize: 11,
                    color: HealthyAdaptive.muted),
                )),
              ]),
            ],
            if (!isUser && message.card == 'catalog_item' &&
                message.argument.isNotEmpty) ...[
              HealthyChatCatalogCard(
                itemId: message.argument,
                onOpen: _openCatalogItem,
              ),
            ],
            if (!isUser && message.card == 'knowledge') ...[
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.menu_book_rounded, size: 17,
                  color: HealthyAdaptive.accent),
                const SizedBox(width: 7),
                Expanded(child: Text('Información educativa con fuente',
                  style: TextStyle(fontSize: 11,
                    color: HealthyAdaptive.muted))),
              ]),
            ],
            if (!isUser && message.card == 'profile') ...[
              const SizedBox(height: 12),
              _profileCard(),
            ],
            if (!isUser && message.action.isNotEmpty &&
                !const {
                  'habit_add', 'habit_remove', 'shop_item', 'shop_picker',
                  'challenges', 'achievements', 'edit_profile',
                  'catalog_item',
                }.contains(message.card)) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: ValueKey('healthy-chat-action-${message.action}'),
                onPressed: () => _navigateFromChat(message),
                icon: Icon(_actionIcon(message.action), size: 18),
                label: Text(_actionLabel(message)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: HealthyAdaptive.text,
                  side: BorderSide(color: HealthyAdaptive.border),
                  backgroundColor: HealthyAdaptive.surface,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              '${isUser ? 'Tú' : 'Mr. Healthy'} · ${message.time}',
              style: TextStyle(
                color: isUser ? Colors.white70 : HealthyAdaptive.muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
  String _actionLabel(ChatMessage message) {
    switch (message.action) {
      case 'habits':
        return message.argument.isEmpty
            ? 'Abrir Hábitos'
            : 'Buscar en Hábitos';
      case 'progress': return 'Ver estadísticas y gráficas';
      case 'professionals': return 'Ver directorio de profesionales';
      case 'profile': return 'Abrir mi perfil';
      case 'levels': return 'Abrir mi camino de XP';
      case 'ranking': return 'Ver clasificación';
      case 'shop': return 'Abrir Tienda';
      case 'catalog': return 'Ver catálogo educativo';
      case 'catalog_item': return 'Ver ficha completa';
      case 'challenges': return 'Ver desafíos';
      case 'achievements': return 'Ver logros';
      case 'edit_profile': return 'Editar mi perfil';
      case 'source': return 'Consultar fuente oficial';
      default: return 'Abrir';
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'habits': return Icons.checklist_rtl_rounded;
      case 'progress': return Icons.bar_chart_rounded;
      case 'professionals': return Icons.medical_services_outlined;
      case 'profile': return Icons.person_outline_rounded;
      case 'levels': return Icons.route_outlined;
      case 'ranking': return Icons.leaderboard_outlined;
      case 'shop': return Icons.storefront_outlined;
      case 'catalog': return Icons.menu_book_outlined;
      case 'catalog_item': return Icons.book_outlined;
      case 'challenges': return Icons.flag_outlined;
      case 'achievements': return Icons.workspace_premium_outlined;
      case 'edit_profile': return Icons.manage_accounts_outlined;
      case 'source': return Icons.open_in_new_rounded;
      default: return Icons.open_in_new_rounded;
    }
  }

  Widget _profileCard() {
    // Tarjeta de datos actuales, obtenidos del perfil y no de la conversación.
    if (_perfil.isEmpty) {
      return Text('Consulta tu perfil para ver datos actualizados.',
          style: TextStyle(color: HealthyAdaptive.muted, fontSize: 12));
    }
    int number(Object? raw) =>
        raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
    final xp = number(_perfil['xp'] ?? _perfil['currentXp']);
    final level = LevelSystem.fromXp(xp);
    final streak = number(_perfil['currentStreak'] ?? _perfil['streakDays']);
    final coins = number(_perfil['habitCoins']);
    return Container(
      key: const Key('healthy-chat-profile-card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HealthyAdaptive.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HealthyAdaptive.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tu progreso actual',
            style: TextStyle(color: HealthyAdaptive.text,
              fontWeight: FontWeight.w900, fontSize: 13)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _metric(Icons.rocket_launch_outlined,
                'Nivel', '${level.number}')),
            Expanded(child: _metric(Icons.bolt_rounded, 'XP', '$xp')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _metric(Icons.local_fire_department_outlined,
                'Racha', '$streak días')),
            Expanded(child: _coinMetric('$coins')),
          ]),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: LevelSystem.progress(xp),
              minHeight: 7,
              backgroundColor: HealthyAdaptive.border,
              color: HealthyAdaptive.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _coinMetric(String value) => Row(children: [
    const HealthyCoinIcon(size: 19),
    const SizedBox(width: 5),
    Expanded(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Monedas', style: TextStyle(color: HealthyAdaptive.muted,
          fontSize: 10)),
        Text(value, overflow: TextOverflow.ellipsis,
          style: TextStyle(color: HealthyAdaptive.text,
            fontWeight: FontWeight.w800, fontSize: 13)),
      ],
    )),
  ]);

  Widget _metric(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 18, color: HealthyAdaptive.accent),
      const SizedBox(width: 5),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: HealthyAdaptive.muted,
            fontSize: 10)),
          Text(value, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: HealthyAdaptive.text,
              fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      )),
    ]);
  }

}
