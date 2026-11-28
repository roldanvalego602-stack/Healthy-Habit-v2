import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'healthy_chat_display_mode.dart';
import 'healthy_web_search_service.dart';
import 'mr_healthy_reply_style.dart';
import '../../tema/healthy_magic_guide.dart';
import 'healthy_typing_indicator.dart';
import 'mr_healthy_chat_avatar.dart';
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
import 'mr_healthy_topic_service.dart';
import 'mr_healthy_preference_memory.dart';
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
  HealthyChatDisplayMode _displayMode = HealthyChatDisplayMode.balanced;
  MrHealthyReplyStyle _replyStyle = MrHealthyReplyStyle.natural;

  Future<void> _loadDisplayMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _displayMode = HealthyChatDisplayModeCodec.parse(
        prefs.getString(HealthyChatDisplayModeCodec.preferenceKey));
      _replyStyle = MrHealthyReplyStyler.parse(
        prefs.getString(MrHealthyReplyStyler.preferenceKey));
    });
  }

  Future<void> _selectReplyStyle(MrHealthyReplyStyle style) async {
    if (style == _replyStyle) return;
    setState(() => _replyStyle = style);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(MrHealthyReplyStyler.preferenceKey, style.name);
  }

  Future<void> _selectDisplayMode(HealthyChatDisplayMode mode) async {
    if (_displayMode == mode) return;
    setState(() => _displayMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(HealthyChatDisplayModeCodec.preferenceKey, mode.name);
  }


  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool _nearLatestMessage = true;
  bool _showJumpToLatest = false;

  void _trackMessageScroll() {
    if (!scrollController.hasClients) return;
    final distance = scrollController.position.extentAfter;
    final nearLatest = distance < 140;
    final showJump = distance > 220;
    if (nearLatest != _nearLatestMessage || showJump != _showJumpToLatest) {
      setState(() {
        _nearLatestMessage = nearLatest;
        _showJumpToLatest = showJump;
      });
    }
  }

  Future<void> _copyChatMessage(ChatMessage message) async {
    await Clipboard.setData(ClipboardData(text: message.text));
    if (mounted) _chatNotice('Mensaje copiado al portapapeles.');
  }

  void _showMessageDetails(ChatMessage message) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message.isUser ? 'Tu mensaje' : 'Mensaje de Mr. Healthy',
                style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Hora: ${message.time}',
                style: Theme.of(sheetContext).textTheme.bodySmall),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight:
                  MediaQuery.sizeOf(sheetContext).height * .45),
                child: SingleChildScrollView(
                  child: SelectableText(message.text),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _copyChatMessage(message);
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copiar mensaje'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final FocusNode _inputFocus = FocusNode();
  final NutriCalculatorService _calculatorService = NutriCalculatorService();
  final HealthyWebSearchService _webSearch = const HealthyWebSearchService();
  final ClimaServicio _climaServicio = ClimaServicio();

  final NutriRespuestasService _respuestas = NutriRespuestasService();
  final HealthyHybridKnowledge _hybridKnowledge = HealthyHybridKnowledge();
  final MrHealthyTopicService _topicService = MrHealthyTopicService();
  final MrHealthyPreferenceMemory _preferenceMemory = MrHealthyPreferenceMemory();
  String _lastEditorialTopic = '';
  int _editorialFollowUps = 0;
  int _editorialTurnIndex = 0;
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
    _loadDisplayMode();
    _inputFocus.addListener(_onFocusChange);
    scrollController.addListener(_trackMessageScroll);
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
        _lastEditorialTopic = '';
        _editorialFollowUps = 0;
        _editorialTurnIndex = 0;
        _preferenceMemory.reset();
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
            if (record.card == 'topic' &&
                record.actionArgument.startsWith(RegExp(
                    r'^(app|food|ex|risk|random)_'))) {
              _lastEditorialTopic = record.actionArgument;
              _editorialFollowUps = 0;
            }
            break;
          }
        }
      });
      await _refreshAssistantData();
      if (mounted) setState(() {});
      _scrollToBottom(force: true);
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
      _lastEditorialTopic = '';
      _editorialFollowUps = 0;
      _editorialTurnIndex = 0;
      _preferenceMemory.reset();
      _lastHabitTitle = '';
      _lastShopItemId = '';
      _hasSentMessage = false;
      _nearLatestMessage = true;
      _showJumpToLatest = false;
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
    final priorAssistantMessages = messages
        .where((message) => !message.isUser)
        .map((message) => message.text)
        .toList();
    final previousAssistantText =
        priorAssistantMessages.isEmpty ? '' : priorAssistantMessages.last;
    final userMessage = ChatMessage(
      text: text, isUser: true, time: _timeNow());

    messageController.clear();
    if (_listening) {
      await _speech.stop();
      _listening = false;
    }
    setState(() {
      _hasSentMessage = true;
      messages.add(userMessage);
      isTyping = true;
      _replyPending = true;
    });
    _scrollToBottom(force: true);

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
      } else if (NutriRespuestasService.contiene(normalized, const [
        'no puedo respirar', 'me estoy asfixiando',
        'me atragante', 'hinchazon de garganta',
        'me intoxique', 'tengo intoxicacion',
        'tome veneno', 'me desmaye', 'dolor fuerte en el pecho',
      ])) {
        _lastEditorialTopic = '';
        _editorialFollowUps = 0;
        _editorialTurnIndex = 0;
        _preferenceMemory.reset();
        response = 'Esto puede ser una urgencia médica. Busca atención '
            'presencial inmediata o llama al servicio de emergencias de '
            'tu zona. No intentes provocarte el vómito ni retrases la '
            'atención esperando una respuesta del chat. '
            '¿Hay alguien contigo que pueda ayudarte?';
      } else if (NutriRespuestasService.ataqueDiscriminatorio(text) || NutriRespuestasService.tieneGroserias(text)) {
        response = _respuestas.moderar(text, _primerNombre);
      } else if (HealthyWebSearchService.extractQuery(text) != null) {
        // Búsqueda explícita, limitada a Wikipedia en español. El backend
        // valida la consulta y nunca recibe perfil, hábitos ni historial.
        final query = HealthyWebSearchService.extractQuery(text)!;
        try {
          final results = await _webSearch.search(query);
          response = HealthyWebSearchService.formatResults(results);
          if (results.isNotEmpty) {
            intent = HealthyAssistantReply(
              response, card: 'external_source',
              action: 'source', actionArgument: results.first.url,
            );
          }
        } on FirebaseFunctionsException catch (error) {
          response = error.code == 'unauthenticated'
              ? 'Inicia sesión para consultar Wikipedia desde Mr. Healthy.'
              : error.code == 'failed-precondition'
                  ? 'No puedo enviar esa consulta a Wikipedia. '
                    'Puedo ayudarte con información local o '
                    'puedes reformularla como pregunta general.'
                  : 'La consulta enciclopédica no está disponible '
                    'en este momento. Verifica que la función '
                    'searchMrHealthyEncyclopedia esté desplegada.';
        } catch (_) {
          response = 'No pude consultar Wikipedia. Comprueba tu conexión '
              'o inténtalo más tarde. No voy a inventar resultados.';
        }
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
          // Las explicaciones generales deben funcionar sin consultar
          // Firestore. Las consultas personales siguen usando datos reales.
          final normalizedQuestion = MrHealthyResponseBank.normalize(text);
          final generalQuestion = RegExp(
            r'^(que es|que son|como funciona|para que sirve|'
            r'habla(me)? de|explicame|dime sobre|quiero saber de|'
            r'que sabes de|como se usa|me interesa|informacion sobre)\b',
          ).hasMatch(normalizedQuestion);
          final requiresProfile = HealthyIntentRouter.asksForCoinBalance(text) ||
              (!generalQuestion && (
                NutriRespuestasService.contiene(normalized, [
                  'mi perfil','mis datos','mis estadisticas','mi progreso',
                  'mi nivel','mi xp','mis xp','habit coins','monedas','racha',
                  'mis habitos','habitos activos','que habitos tengo',
                  'mis actividades','camino de xp',
                  'subir de nivel','mi posicion','cuanto he avanzado',
                  'cuantos xp','tienda','armario','canjear',
                ]) || _lastTopic == 'profile'
              ));
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
              _lastEditorialTopic = '';
              _editorialFollowUps = 0;
              _editorialTurnIndex = 0;
              _preferenceMemory.reset();
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
                _lastEditorialTopic = '';
                _editorialFollowUps = 0;
                _editorialTurnIndex = 0;
                _preferenceMemory.reset();
              } else {
                // Capas seguras: acciones > banco revisable de 10k+
                // formulaciones > fichas educativas > conversación.
                // El motor de temas nunca ejecuta compras o registros.
                final correction = _preferenceMemory.correct(
                  text, _lastEditorialTopic,
                  previousAssistantText: previousAssistantText);
                final contextualQuestion = correction == null
                    ? _preferenceMemory.compose(text, _lastEditorialTopic)
                    : text;
                final editorial = correction ?? await _topicService.answer(
                  contextualQuestion,
                  previousTopicId: _lastEditorialTopic,
                  followUpDepth: _editorialFollowUps,
                  previousAssistantText: previousAssistantText,
                  turnIndex: _editorialTurnIndex,
                );
                if (editorial != null) {
                  final isFollowUp = MrHealthyResponseBank.normalize(text);
                  final continues = _lastEditorialTopic == editorial.knowledgeId &&
                      MrHealthyResponseBank.isFollowUpPhrase(isFollowUp);
                  _editorialFollowUps = continues ? _editorialFollowUps + 1 : 0;
                  final isSameTopic =
                      _lastEditorialTopic == editorial.knowledgeId;
                  _editorialTurnIndex = isSameTopic
                      ? (_editorialTurnIndex + 1) % 100 : 0;
                  _lastEditorialTopic = editorial.knowledgeId;
                  if (correction == null) {
                    _preferenceMemory.record(text, editorial.knowledgeId);
                  }
                  intent = editorial;
                  response = editorial.text;
                  _chatContext.reset();
                } else {
                  _lastEditorialTopic = '';
                  _editorialFollowUps = 0;
                  _editorialTurnIndex = 0;
                  _preferenceMemory.reset();
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
                    final conversational = _conversation.reply(
                      text,
                      name: _primerNombre,
                      previousUserMessage: lastUserPrompt,
                      previousAssistantText: previousAssistantText,
                    );
                    response = conversational == null
                        ? _respuestas.responder(
                            text, nombre: _primerNombre, perfil: _perfil)
                        : MrHealthyReplyStyler.format(
                            conversational, _replyStyle);
                  }
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
              } else if (intent.card != 'knowledge' && intent.card != 'topic') {
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

    // Simula un tiempo breve de reflexión cuando el motor local responde
    // instantáneamente. No añade demora si la búsqueda real tardó más.
    // Límite bajo para no perjudicar la experiencia del chat.
    final elapsed = DateTime.now().difference(startedAt);
    final thinkingMs = (1000 + response.runes.length * 9).clamp(1100, 2400).toInt();
    final minimum = Duration(milliseconds: thinkingMs);
    if (elapsed < minimum) {
      await Future<void>.delayed(minimum - elapsed);
    }
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

  void _scrollToBottom({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;
      // No interrumpir a quien está leyendo mensajes antiguos.
      if (!force && !_nearLatestMessage) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: HealthyVisualEffects.duration(
          context, const Duration(milliseconds: 240)),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _speech.cancel();
    _inputFocus.removeListener(_onFocusChange);
    messageController.removeListener(_onDraftChanged);
    _inputFocus.dispose();
    messageController.dispose();
    scrollController.removeListener(_trackMessageScroll);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      floatingActionButton: const HealthyMagicGuideButton(section: 'chatbot'),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      backgroundColor: _background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
          children: [
            if (_historyLoading)
              const LinearProgressIndicator(minHeight: 2),
            AnimatedSize(
              duration: HealthyVisualEffects.duration(
                context, const Duration(milliseconds: 220)),
              curve: Curves.easeOutCubic,
              child: (_replyPending || (_hasDraft && _displayMode != HealthyChatDisplayMode.compact))
                  ? Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            key: const ValueKey('mr-healthy-draft-avatar'),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: HealthyAdaptive.mint,
                              borderRadius: BorderRadius.circular(48),
                              boxShadow: const [BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 15, offset: Offset(0, 4),
                              )],
                            ),
                            child: MrHealthyChatAvatar(
                              size: _displayMode == HealthyChatDisplayMode.reading ? 46 : 34,
                              isTyping: _replyPending),
                          ),
                          const SizedBox(width: 7),
                          Flexible(child: AnimatedSwitcher(
                            duration: HealthyVisualEffects.duration(
                              context, const Duration(milliseconds: 220)),
                            child: Text(
                              _replyPending
                                  ? 'Mr. Healthy está preparando una respuesta…'
                                  : 'Mr. Healthy sigue tu mensaje 👀',
                              key: ValueKey(_replyPending),
                              style: TextStyle(
                                color: HealthyAdaptive.muted,
                                fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          )),
                        ],
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
                // Reserve the first message's space; while scrolling, content
                // remains visible behind the floating header.
                padding: EdgeInsets.fromLTRB(
                  _displayMode == HealthyChatDisplayMode.compact ? 8 : 12,
                  76,
                  _displayMode == HealthyChatDisplayMode.compact ? 8 : 12,
                  12),
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
            Positioned(
              top: 8,
              left: 10,
              right: 10,
              child: _buildFloatingChatHeader(),
            ),
            if (_showJumpToLatest)
              Positioned(
                bottom: 100,
                right: 14,
                child: FloatingActionButton.small(
                  heroTag: 'healthy-chat-jump-latest',
                  tooltip: 'Ir al mensaje más reciente',
                  onPressed: () => _scrollToBottom(force: true),
                  backgroundColor: HealthyAdaptive.surface,
                  foregroundColor: _navy,
                  child: const Icon(Icons.keyboard_double_arrow_down_rounded),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Controles flotantes dibujados sobre el chat, sin AppBar opaco.
  Widget _buildFloatingChatHeader() {
    return Row(
      children: [
        _chatHeaderAction(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Regresar',
          onPressed: () => Navigator.maybePop(context),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: PopupMenuButton<Object>(
            key: const Key('healthy-chat-display-mode'),
            tooltip: 'Cambiar presentación y estilo del chat',
            onSelected: (selected) {
              if (selected is HealthyChatDisplayMode) {
                _selectDisplayMode(selected);
              } else if (selected is MrHealthyReplyStyle) {
                _selectReplyStyle(selected);
              }
            },
            position: PopupMenuPosition.under,
            itemBuilder: (_) => [
              const PopupMenuItem<Object>(
                enabled: false,
                height: 30,
                child: Text('PRESENTACIÓN',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
              ),
              for (final mode in HealthyChatDisplayMode.values)
                PopupMenuItem<Object>(
                  value: mode,
                  child: Row(
                    children: [
                      Icon(mode.icon, size: 19,
                        color: mode == _displayMode ? _green : _muted),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(mode.label, style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                          Text(mode.description, style: TextStyle(
                            fontSize: 10, color: _muted)),
                        ],
                      )),
                      if (mode == _displayMode)
                        const Icon(Icons.check_rounded, color: _green, size: 18),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem<Object>(
                enabled: false,
                height: 30,
                child: Text('FORMA DE RESPONDER',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
              ),
              for (final style in MrHealthyReplyStyle.values)
                PopupMenuItem<Object>(
                  value: style,
                  child: Row(
                    children: [
                      Icon(style.icon, size: 19,
                        color: style == _replyStyle ? _green : _muted),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(style.label, style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                          Text(style.description, style: TextStyle(
                            fontSize: 10, color: _muted)),
                        ],
                      )),
                      if (style == _replyStyle)
                        const Icon(Icons.check_rounded, color: _green, size: 18),
                    ],
                  ),
                ),
            ],
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: HealthyAdaptive.surface.withValues(alpha: .93),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: HealthyAdaptive.border),
              ),
              child: Row(
                children: [
                  Icon(_displayMode.icon, size: 16, color: _green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mr. Healthy', maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _navy, fontSize: 13,
                            fontWeight: FontWeight.w800)),
                        Text(_displayMode.label, maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _muted, fontSize: 9)),
                      ],
                    ),
                  ),
                  const Icon(Icons.expand_more_rounded, size: 15),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _chatHeaderAction(
          key: const Key('healthy-chat-audio-toggle'),
          icon: _readAloud
              ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          tooltip: _readAloud
              ? 'Silenciar voz retro de Mr. Healthy'
              : 'Activar voz retro de Mr. Healthy',
          onPressed: _toggleReadAloud,
        ),
        const SizedBox(width: 5),
        _chatHeaderAction(
          key: const Key('healthy-chat-history-button'),
          icon: Icons.history_rounded,
          tooltip: 'Historial de conversaciones',
          onPressed: isTyping || _historyLoading
              ? null : _showChatHistory,
        ),
        const SizedBox(width: 5),
        _chatHeaderAction(
          key: const Key('healthy-chat-new-button'),
          icon: Icons.add_comment_outlined,
          tooltip: 'Nueva conversación',
          onPressed: isTyping ? null : _newConversation,
        ),
      ],
    );
  }

  /// Controles independientes: sin una barra visual continua.
  Widget _chatHeaderAction({
    Key? key,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 36,
      height: 40,
      decoration: BoxDecoration(
        color: HealthyAdaptive.surface.withValues(alpha: .93),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HealthyAdaptive.border),
      ),
      child: IconButton(
        key: key,
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 36, height: 40),
        icon: Icon(icon, size: 19, color: onPressed == null
            ? _muted : _navy),
      ),
    );
  }

  Widget _buildWelcome() => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      children: [
        MrHealthyChatAvatar(size: 52, isTyping: _replyPending),
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
    padding: EdgeInsets.fromLTRB(10, 6, 10, keyboardVisible ? 6 :
      (_displayMode == HealthyChatDisplayMode.compact ? 5 : 8)),
    decoration: BoxDecoration(
      color: _background,
      border: Border(top: BorderSide(color: HealthyAdaptive.border)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 13, right: 4),
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
                    contentPadding: EdgeInsets.symmetric(vertical: 11),
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
          SizedBox(height: _displayMode == HealthyChatDisplayMode.compact ? 3 : 8),
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

  /// Separa párrafos y viñetas sin alterar el texto original del mensaje.
  /// La selección de texto permanece disponible en los tres modos.
  Widget _buildReadableMessageText(ChatMessage message) {
    final color = message.isUser ? Colors.white : HealthyAdaptive.text;
    final style = TextStyle(
      color: color,
      fontSize: _displayMode.messageFontSize,
      height: _displayMode.messageLineHeight,
    );
    final lines = message.text.split('\n');
    if (lines.length <= 1) {
      return SelectableText(message.text, style: style);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < lines.length; index++) ...[
          if (lines[index].trim().isNotEmpty)
            SelectableText(
              lines[index],
              style: style.copyWith(
                fontWeight: RegExp(r'^#{1,3} ').hasMatch(lines[index])
                    ? FontWeight.w700 : null,
              ),
            ),
          if (index < lines.length - 1)
            SizedBox(height: lines[index].trim().isEmpty ? 8 : 3),
        ],
      ],
    );
  }

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
        child: AnimatedContainer(
        duration: HealthyVisualEffects.duration(
          context, const Duration(milliseconds: 200)),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.only(bottom: _displayMode.messageGap),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * _displayMode.messageWidth,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: _displayMode.messageHorizontalPadding,
          vertical: _displayMode.messageVerticalPadding),
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
            _buildReadableMessageText(message),
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
            if (!isUser && message.card == 'external_source') ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.public_rounded, size: 17,
                  color: HealthyAdaptive.accent),
                const SizedBox(width: 7),
                Expanded(child: Text(
                  'Fuente externa · Wikipedia · consulta solicitada',
                  style: TextStyle(fontSize: 11,
                    color: HealthyAdaptive.muted),
                )),
              ]),
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
            SizedBox(height: _displayMode == HealthyChatDisplayMode.compact ? 2 : 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(
                  '${isUser ? 'Tú' : 'Mr. Healthy'} · ${message.time}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isUser ? Colors.white70 : HealthyAdaptive.muted,
                    fontSize: 10,
                  ),
                )),
                const SizedBox(width: 7),
                InkWell(
                  key: ValueKey('healthy-chat-copy-${messages.indexOf(message)}'),
                  onTap: () => _copyChatMessage(message),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(Icons.copy_rounded, size: 15,
                      color: isUser ? Colors.white70 : HealthyAdaptive.muted),
                  ),
                ),
                InkWell(
                  key: ValueKey('healthy-chat-details-${messages.indexOf(message)}'),
                  onTap: () => _showMessageDetails(message),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(Icons.more_horiz_rounded, size: 17,
                      color: isUser ? Colors.white70 : HealthyAdaptive.muted),
                  ),
                ),
              ],
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
