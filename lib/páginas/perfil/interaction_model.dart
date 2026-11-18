import 'package:cloud_firestore/cloud_firestore.dart';

class InteractionModel {
  final String? id;
  final String challengeId;
  final DateTime createdAt;
  final String emoji;
  final String estado;
  final String fromUid;
  final bool leido;
  final DateTime? respondedAt;
  final String tipo;
  final String toUid;

  InteractionModel({
    this.id,
    required this.challengeId,
    required this.createdAt,
    required this.emoji,
    required this.estado,
    required this.fromUid,
    required this.leido,
    required this.respondedAt,
    required this.tipo,
    required this.toUid,
  });

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'createdAt': Timestamp.fromDate(createdAt),
      'emoji': emoji,
      'estado': estado,
      'fromUid': fromUid,
      'leido': leido,
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'tipo': tipo,
      'toUid': toUid,
    };
  }

  factory InteractionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InteractionModel(
      id: doc.id,
      challengeId: data['challengeId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      emoji: data['emoji'] ?? '',
      estado: data['estado'] ?? 'enviado',
      fromUid: data['fromUid'] ?? '',
      leido: data['leido'] ?? false,
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
      tipo: data['tipo'] ?? 'reaccion',
      toUid: data['toUid'] ?? '',
    );
  }
}