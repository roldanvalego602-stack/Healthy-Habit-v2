import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'interaction_model.dart';

class InteractionService {
  final CollectionReference _interactionsRef =
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default')
          .collection('interactions');

  /// Enviar una nueva reacción a un usuario con los campos exactos de Firestore
  Future<void> enviarReaccion({
    required String fromUid,
    required String toUid,
    required String emoji,
    String challengeId = '',
    String estado = 'enviado',
    String tipo = 'reaccion',
  }) async {
    // El cliente nunca debe enviar reacciones atribuidas a otra cuenta.
    // La misma comprobación debe aplicarse en las reglas de Firestore.
    final loggedInUid = FirebaseAuth.instance.currentUser?.uid;
    if (loggedInUid == null || loggedInUid != fromUid) {
      throw StateError('Inicia sesión con tu cuenta para enviar reacciones.');
    }
    if (toUid.trim().isEmpty || toUid == fromUid) {
      throw ArgumentError('Selecciona a otro usuario válido.');
    }
    if (!const ['🔥', '❤️', '👏', '💪', '🎉', '⭐'].contains(emoji)) {
      throw ArgumentError('La reacción seleccionada no es válida.');
    }
    final friendship = await FirebaseFirestore.instanceFor(
      app: Firebase.app(), databaseId: 'default',
    ).collection('users').doc(fromUid)
        .collection('friends').doc(toUid).get();
    if (!friendship.exists) {
      throw StateError('Solo puedes reaccionar al progreso de tus amigos.');
    }
    final publicProfile = await FirebaseFirestore.instanceFor(
      app: Firebase.app(), databaseId: 'default',
    ).collection('public_profiles').doc(toUid).get();
    final rawSettings = publicProfile.data()?['settings'];
    if (rawSettings is Map && rawSettings['permitirReacciones'] == false) {
      throw StateError('Esta persona no acepta reacciones.');
    }
    final nuevaInteraccion = InteractionModel(
      challengeId: challengeId,
      createdAt: DateTime.now(),
      emoji: emoji,
      estado: estado,
      fromUid: fromUid,
      leido: false,
      respondedAt: null,
      tipo: tipo,
      toUid: toUid,
    );

    // Timeout de 10 segundos para evitar que se quede colgado indefinidamente
    await _interactionsRef.add(nuevaInteraccion.toMap()).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception(
          'Tiempo de espera agotado. Revisa tu conexión o las reglas de Firestore.',
        );
      },
    );
  }

  /// Escuchar en tiempo real las reacciones recibidas por el usuario actual
  Stream<List<InteractionModel>> escucharReaccionesRecibidas(String currentUid) {
    return _interactionsRef
        .where('toUid', isEqualTo: currentUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InteractionModel.fromFirestore(doc))
            .toList());
  }

  /// Marcar una reacción como leída
  Future<void> marcarComoLeida(String interactionId) async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) throw StateError('Inicia sesión.');
    final ref = _interactionsRef.doc(interactionId);
    await FirebaseFirestore.instanceFor(
      app: Firebase.app(), databaseId: 'default',
    ).runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists || (doc.data() as Map<String, dynamic>?)?['toUid'] != me) {
        throw StateError('Solo el destinatario puede leer esta reacción.');
      }
      tx.update(ref, {'leido': true});
    });
  }

  /// Solo el destinatario puede responder y la respuesta es definitiva.
  /// Firestore Rules debe validar la misma autorización en el servidor.
  Future<void> responderInteraccion(String interactionId, String nuevoEstado) async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) throw StateError('Inicia sesión.');
    if (interactionId.trim().isEmpty) {
      throw ArgumentError('La interacción no es válida.');
    }
    if (nuevoEstado != 'aceptado' && nuevoEstado != 'rechazado') {
      throw ArgumentError('La respuesta no es válida.');
    }

    await FirebaseFirestore.instanceFor(
      app: Firebase.app(), databaseId: 'default',
    ).runTransaction((tx) async {
      final ref = _interactionsRef.doc(interactionId);
      final snapshot = await tx.get(ref);
      if (!snapshot.exists) {
        throw StateError('Esta interacción ya no existe.');
      }
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data?['toUid'] != me) {
        throw StateError('Solo el destinatario puede responder.');
      }
      if (data?['tipo'] != 'reaccion' ||
          data?['estado'] != 'enviado' ||
          data?['respondedAt'] != null) {
        throw StateError('Esta interacción ya fue respondida o no es válida.');
      }
      tx.update(ref, {
        'estado': nuevoEstado,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}