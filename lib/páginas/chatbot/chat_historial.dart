import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Mensaje del chat con Mr. Healthy.
class ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  ChatMessage({required this.text, required this.isUser, required this.time});
}

/// Una conversación completa (desde que se abre el chat hasta que se cierra).
class ChatSession {
  final String id;
  final String? uid;
  final DateTime startedAt;
  final List<ChatMessage> messages = [];

  ChatSession({required this.id, required this.uid, required this.startedAt});

  bool get hasUserMessages => messages.any((m) => m.isUser);

  int get userMessageCount => messages.where((m) => m.isUser).length;

  String get title {
    final first = messages.where((m) => m.isUser).toList();
    if (first.isEmpty) return 'Conversación';
    final text = first.first.text.trim().replaceAll('\n', ' ');
    return text.length > 48 ? '${text.substring(0, 48)}…' : text;
  }

  String get preview {
    if (messages.isEmpty) return '';
    final text = messages.last.text.trim().replaceAll('\n', ' ');
    return text.length > 90 ? '${text.substring(0, 90)}…' : text;
  }
}

/// Historial EN MEMORIA: no se guarda en la base de datos ni en el
/// dispositivo. Se borra al cerrar la aplicación y se separa por usuario.
class ChatHistoryStore {
  ChatHistoryStore._();

  static final ChatHistoryStore instance = ChatHistoryStore._();
  static const int _maxSessions = 30;

  final List<ChatSession> _sessions = [];

  ChatSession startSession(String? uid) {
    final now = DateTime.now();
    final session = ChatSession(
      id: now.microsecondsSinceEpoch.toString(),
      uid: uid,
      startedAt: now,
    );

    _sessions.removeWhere((s) => !s.hasUserMessages);
    _sessions.add(session);
    while (_sessions.length > _maxSessions) {
      _sessions.removeAt(0);
    }
    return session;
  }

  /// Conversaciones del usuario, de la más reciente a la más antigua.
  List<ChatSession> sessionsFor(String? uid) {
    return _sessions
        .where((s) => s.uid == uid && s.hasUserMessages)
        .toList()
        .reversed
        .toList();
  }

  void discardIfEmpty(ChatSession session) {
    if (!session.hasUserMessages) _sessions.remove(session);
  }

  void delete(String id) => _sessions.removeWhere((s) => s.id == id);

  void clearFor(String? uid, {String? exceptId}) {
    _sessions.removeWhere((s) => s.uid == uid && s.id != exceptId);
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
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
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
        color: Colors.black.withOpacity(0.025),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

// ======================= PÁGINA DE HISTORIAL =======================

class ChatHistoryPage extends StatefulWidget {
  /// Conversación que está abierta en el chat (no se puede borrar).
  final String? activeSessionId;

  const ChatHistoryPage({super.key, this.activeSessionId});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _borrarUna(ChatSession session) async {
    final confirmar = await _confirmar(
      titulo: 'Borrar conversación',
      mensaje: 'Esta conversación se eliminará del historial.',
    );
    if (confirmar != true) return;

    setState(() => ChatHistoryStore.instance.delete(session.id));
  }

  Future<void> _borrarTodo() async {
    final confirmar = await _confirmar(
      titulo: 'Borrar historial',
      mensaje:
          'Se eliminarán todas tus conversaciones anteriores. La conversación '
          'actual no se borra.',
    );
    if (confirmar != true) return;

    setState(() {
      ChatHistoryStore.instance.clearFor(
        _uid,
        exceptId: widget.activeSessionId,
      );
    });
  }

  Future<bool?> _confirmar({required String titulo, required String mensaje}) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(titulo),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Borrar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ChatHistoryStore.instance.sessionsFor(_uid);
    final hayBorrables = sessions.any((s) => s.id != widget.activeSessionId);

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
            tooltip: 'Borrar historial',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: hayBorrables ? _borrarTodo : null,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    'Tu historial solo se conserva mientras la aplicación '
                    'está abierta. Al cerrarla, se borra. No se guarda en '
                    'tu cuenta.',
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
                    style: TextStyle(fontSize: 12, color: Color(0xFF7A869A)),
                  ),
                ],
              ),
            ),
          for (final session in sessions) ...[
            _SessionCard(
              session: session,
              isActive: session.id == widget.activeSessionId,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatHistoryDetailPage(session: session),
                    ),
                  ),
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
                    session.title,
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
            if (!isActive)
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

class ChatHistoryDetailPage extends StatelessWidget {
  final ChatSession session;

  const ChatHistoryDetailPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF172B36)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conversación',
              style: TextStyle(
                color: Color(0xFF172B36),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              _formatearFecha(session.startedAt),
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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                itemCount: session.messages.length,
                itemBuilder:
                    (context, index) =>
                        _HistoryBubble(message: session.messages[index]),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Solo lectura. Para seguir hablando, abre una conversación '
                'nueva con Mr. Healthy.',
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
