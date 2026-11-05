import 'package:cloud_firestore/cloud_firestore.dart';
import 'interaction_model.dart';

class InteractionService {
  final CollectionReference _interactionsRef =
      FirebaseFirestore.instance.collection('interactions');

  /// Enviar una nueva reacción a un usuario con los campos exactos de Firestore
  Future<void> enviarReaccion({
    required String fromUid,
    required String toUid,
    required String emoji,
    String challengeId = '',
    String estado = 'enviado',
    String tipo = 'reaccion',
  }) async {
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