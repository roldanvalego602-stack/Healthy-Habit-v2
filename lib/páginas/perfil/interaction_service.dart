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
    await _interactionsRef.doc(interactionId).update({
      'leido': true,
    });
  }

  /// Registrar cuando el usuario responde a una interacción
  Future<void> responderInteraccion(String interactionId, String nuevoEstado) async {
    await _interactionsRef.doc(interactionId).update({
      'estado': nuevoEstado,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }
}