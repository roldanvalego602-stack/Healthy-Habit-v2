import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Mensajes de un chat individual, aislados bajo el UID autenticado.
class HealthyChatRecord {
  const HealthyChatRecord({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.action = '',
    this.actionArgument = '',
    this.card = '',
  });
  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;
  final String action;
  final String actionArgument;
  final String card;

  factory HealthyChatRecord.fromDocument(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final raw = data['createdAt'];
    return HealthyChatRecord(
      id: doc.id,
      text: (data['text'] ?? '').toString(),
      isUser: data['isUser'] == true,
      createdAt: raw is Timestamp ? raw.toDate() : DateTime.now(),
      action: (data['action'] ?? '').toString(),
      actionArgument: (data['actionArgument'] ?? '').toString(),
      card: (data['card'] ?? '').toString(),
    );
  }
}

class HealthyChatSession {
  const HealthyChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
  });
  final String id;
  final String title;
  final DateTime updatedAt;

  factory HealthyChatSession.fromDocument(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data();
    final raw = map['updatedAt'];
    return HealthyChatSession(
      id: doc.id,
      title: (map['title'] ?? 'Conversación').toString(),
      updatedAt: raw is Timestamp ? raw.toDate() : DateTime.now(),
    );
  }
}

/// Almacenamiento por usuario: users/{uid}/healthy_chats/{chatId}/messages.
/// No hay claves de API ni datos compartidos entre cuentas.
class HealthyChatHistory {
  const HealthyChatHistory();

  DocumentReference<Map<String, dynamic>> get _profile {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Inicia sesión para guardar conversaciones.');
    return FirebaseFirestore.instanceFor(
      app: Firebase.app(), databaseId: 'default',
    ).collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _profile.collection('healthy_chats');

  Stream<List<HealthyChatSession>> watchSessions() =>
      _sessions.orderBy('updatedAt', descending: true).limit(35).snapshots()
          .map((snapshot) => snapshot.docs
              .map(HealthyChatSession.fromDocument).toList());

  Future<String> createSession() async {
    final doc = _sessions.doc();
    await doc.set({
      'title': 'Nueva conversación',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<List<HealthyChatRecord>> loadMessages(String chatId) async {
    final snap = await _sessions.doc(chatId).collection('messages')
        .orderBy('createdAt', descending: true).limit(80).get();
    return snap.docs.map(HealthyChatRecord.fromDocument).toList().reversed.toList();
  }

  Future<void> saveMessage(
    String chatId, {
    required String text,
    required bool isUser,
    String action = '',
    String actionArgument = '',
    String card = '',
    bool isFirstUserMessage = false,
  }) async {
    final parent = _sessions.doc(chatId);
    final message = parent.collection('messages').doc();
    final title = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final batch = _profile.firestore.batch();
    batch.set(message, {
      'text': text,
      'isUser': isUser,
      'createdAt': Timestamp.now(),
      'action': action,
      'actionArgument': actionArgument,
      'card': card,
    });
    batch.set(parent, {
      'updatedAt': FieldValue.serverTimestamp(),
      if (isFirstUserMessage) 'title':
          title.length > 48 ? '${title.substring(0, 48)}…' : title,
    }, SetOptions(merge: true));
    await batch.commit();
  }

  /// Borrar mensajes antes de borrar su sesión evita dejar datos huérfanos.
  /// Ejecuta en páginas de 100 para respetar límites de escritura.
  Future<void> deleteSession(String chatId) async {
    final parent = _sessions.doc(chatId);
    while (true) {
      final page = await parent.collection('messages').limit(100).get();
      if (page.docs.isEmpty) break;
      final batch = _profile.firestore.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await parent.delete();
  }
}
