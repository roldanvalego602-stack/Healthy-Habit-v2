import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nutri_calculator_service.dart';
import 'texto_chatbot.dart';

/// Mensaje del chat con Mr. Healthy.
class ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  ChatMessage({required this.text, required this.isUser, required this.time});

  Map<String, dynamic> toMap() => {'text': text, 'u': isUser, 'time': time};

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        text: (m['text'] ?? '') as String,
        isUser: m['u'] == true,
        time: (m['time'] ?? '') as String,
      );
}

/// Tema corto de cada conversación. Usa las mismas palabras clave que
/// Mr. Healthy, en el mismo orden, para que historial y chatbot coincidan.
class ChatTopics {
  ChatTopics._();

  static final List<(String, List<String>)> _temas = [
    ('Calcular IMC', NutriCalculatorService.imcKeywords),
    ('Calcular calorías (GET)', NutriCalculatorService.getKeywords),
    ('Clima de hoy', [
      'clima', 'temperatura', 'pronostico', 'llover', 'lluvia', 'llueve',
      'hace calor', 'hace frio', 'que tiempo hace',
    ]),
    ('Fecha y hora', [
      'que dia es', 'que fecha es', 'fecha de hoy', 'fecha actual',
      'que hora es', 'hora actual', 'dime la hora', 'dime la fecha',
      'en que dia estamos', 'a cuanto estamos', 'que dia de la semana',
    ]),
    ('Desafíos', ['desafio', 'desafios', 'evidencia', 'foto', 'fotografia']),
    ('Ejercicio', ['entren*']),
    ('Qué es un hábito', [
      'que es un habito', 'que es habito', 'explica un habito',
      'explicar un habito', 'como funciona un habito',
      'como se forma un habito', 'que significa un habito',
    ]),
    ('Registrar hábitos', [
      'registrar un habito', 'registrar mis habitos',
      'como registro mis habitos', 'como registro un habito',
      'donde registro un habito',
    ]),
    ('Si no cumplo un hábito', [
      'si no cumplo', 'que pasa si fallo un dia',
    ]),
    ('Cambiar mis datos', [
      'cambiar correo', 'cambiar el correo', 'cambiar mi correo',
      'cambiar email', 'cambiar mi email', 'cambiar mis datos',
      'editar mis datos', 'datos personales', 'correo electronico',
    ]),
    ('Retroalimentación', ['retroalimentacion', 'feedback']),
    ('Grasas saludables', [
      'grasas saludables', 'grasa saludable', 'grasas buenas', 'grasa buena',
      'grasas sanas', 'grasa sana', 'aceite saludable', 'aceites saludables',
    ]),
    ('Cocinar sin aceite', [
      'sin aceite', 'cocina sin aceite', 'cocinar sin aceite',
      'recetas sin aceite',
    ]),
    ('Mejorar mi racha', ['racha', 'dias seguidos']),
    ('Misión de hoy', ['mision', 'reto del dia']),
    ('Hidratación', ['hidrat*', 'agua', 'vasos de agua', 'tengo sed']),
    ('Hablar con profesional', [
      'profesional', 'nutriologo', 'nutricionista', 'psicologo', 'terapeuta',
      'doctor', 'medico',
    ]),
    ('Recordatorios', [
      'recordatorio', 'recordar*', 'notificacion', 'alarma', 'aviso',
    ]),
    ('Logros e insignias', ['logro', 'insignia', 'medalla', 'trofeo']),
    ('Puntos y nivel', [
      'punto', 'xp', 'experiencia', 'nivel', 'subir de nivel',
    ]),
    ('Contraseña y cuenta', [
      'contrasena', 'password', 'clave', 'perfil', 'cuenta',
    ]),
    ('Bajar de peso', [
      'bajar de peso', 'adelgaz*', 'perder peso', 'bajar kilos',
      'perder kilos', 'quemar grasa',
    ]),
    ('Peso y calorías', ['peso', 'caloria', 'calorias']),
    ('Sueño', ['dorm*', 'sueno', 'descans*', 'insomnio', 'desvel*']),
    ('Ejercicio', [
      'ejercicio', 'ejercit*', 'entren*', 'actividad fisica', 'gimnasio',
      'gym', 'deporte', 'correr', 'camin*',
    ]),
    ('Desayuno', ['desayun*']),
    ('Proteínas', ['proteina']),
    ('Snacks', [
      'snack', 'colacion', 'entre comidas', 'botana', 'antojo', 'antojito',
      'merienda',
    ]),
    ('Frutas y verduras', [
      'fruta', 'verdura', 'vegetal', 'frutas y verduras',
    ]),
    ('Alimentación', [
      'dieta', 'comida', 'comer', 'alimentacion', 'alimento', 'nutricion',
      'almuerzo', 'cena', 'cenar',
    ]),
    ('Estrés', [
      'estres', 'estresad*', 'ansied*', 'ansios*', 'nervios*', 'angustia',
      'agobiad*',
    ]),
    ('Motivación', [
      'motiv*', 'animo', 'desanimad*', 'sin ganas', 'flojera', 'pereza',
    ]),
    ('Rutina y hábitos', [
      'rutina', 'habito', 'consejo', 'recomendacion', 'tip', 'sugerencia',
    ]),
  ];

  /// Tema de un solo mensaje, o null si no reconoce ninguno
  /// (por ejemplo "sí", "ok", "gracias", "otro").
  static String? detectar(String texto) {
    final t = normalizeText(texto);
    if (t.isEmpty) return null;
    for (final (titulo, claves) in _temas) {
      if (containsAnyKeyword(t, claves)) return titulo;
    }
    return null;
  }

  /// Primer tema que aparece en los mensajes del usuario.
  static String? temaDe(List<ChatMessage> mensajes) {
    for (final m in mensajes) {
      if (!m.isUser) continue;
      final tema = detectar(m.text);
      if (tema != null) return tema;
    }
    return null;
  }
}

/// Una conversación del historial (un tema).
class ChatSession {
  final String id;
  final String? uid;
  final DateTime startedAt;
  final List<ChatMessage> messages = [];

  /// Se marca cuando el usuario la borra del historial.
  bool deleted = false;

  ChatSession({required this.id, required this.uid, required this.startedAt});

  bool get hasUserMessages => messages.any((m) => m.isUser);

  int get userMessageCount => messages.where((m) => m.isUser).length;

  /// Título corto con el tema; si no hay tema, las primeras palabras.
  String get title {
    final tema = ChatTopics.temaDe(messages);
    if (tema != null) return tema;

    final delUsuario = messages.where((m) => m.isUser).toList();
    if (delUsuario.isEmpty) return 'Conversación';
    final palabras = delUsuario.first.text.trim().split(RegExp(r'\s+'));
    var corto = palabras.take(4).join(' ');
    if (corto.isEmpty) return 'Conversación';
    if (corto.length > 28) corto = '${corto.substring(0, 28)}…';
    return corto[0].toUpperCase() + corto.substring(1);
  }

  String get preview {
    if (messages.isEmpty) return '';
    final text = messages.last.text.trim().replaceAll('\n', ' ');
    return text.length > 90 ? '${text.substring(0, 90)}…' : text;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'uid': uid,
        'startedAt': startedAt.toIso8601String(),
        'messages': messages.map((m) => m.toMap()).toList(),
      };

  factory ChatSession.fromMap(Map<String, dynamic> m) {
    final session = ChatSession(
      id: m['id'] as String,
      uid: m['uid'] as String?,
      startedAt: DateTime.parse(m['startedAt'] as String),
    );
    for (final e in (m['messages'] as List)) {
      session.messages.add(
        ChatMessage.fromMap(Map<String, dynamic>.from(e as Map)),
      );
    }
    return session;
  }
}

/// Historial guardado en el dispositivo (SharedPreferences), separado por
/// usuario. Sigue ahí al cerrar y volver a abrir la aplicación.
class ChatHistoryStore {
  ChatHistoryStore._();

  static final ChatHistoryStore instance = ChatHistoryStore._();
  static const int _maxSessions = 5;
  static const String _key = 'mr_healthy_historial_v2';

  final List<ChatSession> _sessions = [];
  Future<void>? _carga;

  /// Carga lo guardado (una sola vez).
  Future<void> ensureLoaded() => _carga ??= _cargar();

  Future<void> _cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final enMemoria = _sessions.map((s) => s.id).toSet();
      for (final e in jsonDecode(raw) as List) {
        final s = ChatSession.fromMap(Map<String, dynamic>.from(e as Map));
        if (!enMemoria.contains(s.id) && s.hasUserMessages) _sessions.add(s);
      }
      _sessions.sort((a, b) => a.startedAt.compareTo(b.startedAt));
      _recortar();
    } catch (_) {
      // Datos dañados: se empieza con el historial vacío.
    }
  }

    /// Deja solo las 5 conversaciones más recientes de cada usuario.
  /// Las conversaciones vacías no cuentan.
  void _recortar() {
    final porUsuario = <String?, List<ChatSession>>{};
    for (final s in _sessions.where((s) => s.hasUserMessages)) {
      porUsuario.putIfAbsent(s.uid, () => []).add(s);
    }
    for (final lista in porUsuario.values) {
      lista.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      for (final s in lista.skip(_maxSessions)) {
        s.deleted = true;
        _sessions.remove(s);
      }
    }
  }

  /// Guarda el historial en el dispositivo.
  void persist() => unawaited(_escribir());

  Future<void> _escribir() async {
    await ensureLoaded();
     _recortar();
    try {
      final prefs = await SharedPreferences.getInstance();
      final lista =
          _sessions
              .where((s) => s.hasUserMessages)
              .map((s) => s.toMap())
              .toList();
      await prefs.setString(_key, jsonEncode(lista));
    } catch (_) {}
  }

  ChatSession startSession(String? uid) {
    final now = DateTime.now();
    final session = ChatSession(
      id: now.microsecondsSinceEpoch.toString(),
      uid: uid,
      startedAt: now,
    );

    _sessions.removeWhere((s) => !s.hasUserMessages);
    _sessions.add(session);
    _recortar();
    return session;
  }

  /// Conversaciones del usuario, de la más reciente a la más antigua.
  List<ChatSession> sessionsFor(String? uid) {
    final lista =
        _sessions
            .where((s) => s.uid == uid && s.hasUserMessages && !s.deleted)
            .toList();
     lista.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return lista.take(_maxSessions).toList();
  }

  void discardIfEmpty(ChatSession session) {
    if (!session.hasUserMessages) _sessions.remove(session);
  }

  /// Borra una conversación al instante.
  void delete(String id) {
    for (final s in _sessions.where((s) => s.id == id)) {
      s.deleted = true;
    }
    _sessions.removeWhere((s) => s.id == id);
    persist();
  }

  /// Borra todas las conversaciones del usuario al instante.
  void clearFor(String? uid) {
    for (final s in _sessions.where((s) => s.uid == uid)) {
      s.deleted = true;
    }
    _sessions.removeWhere((s) => s.uid == uid);
    persist();
  }
}

String _formatearFecha(DateTime d) {
  final now = DateTime.now();
  final hoy = DateTime(now.year, now.month, now.day);
  final dia = DateTime(d.year, d.month, d.day);
  final diff = hoy.difference(dia).inDays;
  final hora =
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  if (diff == 0) return 'Hoy · $hora';
  if (diff == 1) return 'Ayer · $hora';

  const meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  return '${d.day} ${meses[d.month - 1]} · $hora';
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.grey.shade200),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.025),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

// ======================= PÁGINA DE HISTORIAL =======================

class ChatHistoryPage extends StatefulWidget {
  /// Conversación que está abierta en el chat (se marca como "ACTUAL").
  final String? activeSessionId;

  const ChatHistoryPage({super.key, this.activeSessionId});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  bool _cargando = true;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    ChatHistoryStore.instance.ensureLoaded().then((_) {
      if (mounted) setState(() => _cargando = false);
    });
  }

  // Borrado instantáneo, sin confirmación.
  void _borrarUna(ChatSession session) {
    setState(() => ChatHistoryStore.instance.delete(session.id));
  }

  void _borrarTodo() {
    setState(() => ChatHistoryStore.instance.clearFor(_uid));
  }

  @override
  Widget build(BuildContext context) {
    final sessions =
        _cargando
            ? const <ChatSession>[]
            : ChatHistoryStore.instance.sessionsFor(_uid);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0E1A30)),
        title: const Text(
          'Historial',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0E1A30),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Borrar todo',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: sessions.isEmpty ? null : _borrarTodo,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body:
          _cargando
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00C88C)),
              )
              : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F6FC),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Color(0xFF2B7FD1),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tus conversaciones se guardan solo en este '
                            'dispositivo, no en tu cuenta. Cada tema queda '
                            'en su propia conversación.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: Color(0xFF0E1A30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (sessions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: Color(0xFF7A869A),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Aún no hay conversaciones',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0E1A30),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Cuando hables con Mr. Healthy, aparecerán aquí.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7A869A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  for (final session in sessions) ...[
                    _SessionCard(
                      session: session,
                      isActive: session.id == widget.activeSessionId,
                                            onTap: () async {
                        final resultado = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ChatHistoryDetailPage(session: session),
                          ),
                        );
                        // 'nuevo' o 'chat': se vuelve al chatbot.
                        if (resultado != null && mounted) {
                          Navigator.pop(context, resultado);
                        }
                      },
                      onDelete: () => _borrarUna(session),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ChatSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6FC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFF2B7FD1),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title, // tema corto
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0E1A30),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Color(0xFF7A869A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _formatearFecha(session.startedAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7A869A),
                        ),
                      ),
                      Text(
                        '${session.userMessageCount} '
                        '${session.userMessageCount == 1 ? 'pregunta' : 'preguntas'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7A869A),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2F7ED),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'ACTUAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00A875),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Borrar',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: Color(0xFF7A869A),
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= DETALLE (SOLO LECTURA) =======================

class ChatHistoryDetailPage extends StatefulWidget {
  final ChatSession session;

  const ChatHistoryDetailPage({super.key, required this.session});

  @override
  State<ChatHistoryDetailPage> createState() => _ChatHistoryDetailPageState();
}

class _ChatHistoryDetailPageState extends State<ChatHistoryDetailPage> {
  late ChatSession _session = widget.session;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Widget _buildMenu() {
    final conversaciones = ChatHistoryStore.instance.sessionsFor(_uid);

    return Drawer(
      backgroundColor: const Color(0xFFF7F9F8),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'Historial',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0E1A30),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // cierra el menú
                    Navigator.pop(context, 'nuevo'); // vuelve al chatbot
                  },
                  icon: const Icon(Icons.add_comment_outlined, size: 20),
                  label: const Text(
                    'Nuevo chat',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C88C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Últimas conversaciones',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7A869A),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final s in conversaciones)
                    ListTile(
                      selected: s.id == _session.id,
                      selectedTileColor: const Color(0xFFE2F7ED),
                      leading: const Icon(Icons.chat_bubble_outline_rounded),
                      title: Text(
                        s.title, // tema corto
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(_formatearFecha(s.startedAt)),
                      onTap: () {
                        setState(() => _session = s);
                        Navigator.pop(context); // cierra el menú
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      drawer: _buildMenu(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF172B36)),
        automaticallyImplyLeading: false,
        // El menú reemplaza a la flecha de regreso.
        leading: Builder(
          builder:
              (ctx) => IconButton(
                tooltip: 'Menú',
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _session.title,
              style: const TextStyle(
                color: Color(0xFF172B36),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              _formatearFecha(_session.startedAt),
              style: const TextStyle(
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
              child: ListView.builder(
                key: ValueKey(_session.id),
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                itemCount: _session.messages.length,
                itemBuilder:
                    (context, index) =>
                        _HistoryBubble(message: _session.messages[index]),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Solo lectura. Para seguir hablando, abre el menú y elige '
                '"Nuevo chat".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Color(0xFF8A8F98)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _HistoryBubble extends StatelessWidget {
  final ChatMessage message;

  const _HistoryBubble({required this.message});

  @override
  Widget build(BuildContext context) {
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