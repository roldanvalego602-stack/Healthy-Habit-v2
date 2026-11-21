/// Contrato de datos de hábitos compartidos.
////
/// Cada participante registra su propio progreso. Las invitaciones requieren
/// aceptación y nunca otorgan XP adicional por duplicar un registro.
enum EstadoInvitacionHabito {
  pendiente,
  aceptada,
  rechazada,
  cancelada,
  finalizada,
}

class InvitacionHabitoCompartido {
  const InvitacionHabitoCompartido({
    required this.id,
    required this.habitId,
    required this.habitTitle,
    required this.senderUid,
    required this.recipientUid,
    required this.estado,
    required this.createdAt,
  });

  final String id;
  final String habitId;
  final String habitTitle;
  final String senderUid;
  final String recipientUid;
  final EstadoInvitacionHabito estado;
  final DateTime createdAt;

  bool get pendiente => estado == EstadoInvitacionHabito.pendiente;
  bool puedeAceptar(String uid) =>
      pendiente && recipientUid == uid && senderUid != uid;
  bool puedeCancelar(String uid) => pendiente && senderUid == uid;

  /// Valida una invitación sin permitir autoinvitaciones o datos vacíos.
  static void validar({
    required String habitId,
    required String habitTitle,
    required String senderUid,
    required String recipientUid,
  }) {
    if (habitId.trim().isEmpty || habitTitle.trim().isEmpty ||
        senderUid.trim().isEmpty || recipientUid.trim().isEmpty) {
      throw ArgumentError('Los identificadores y el título son obligatorios.');
    }
    if (senderUid == recipientUid) {
      throw ArgumentError('No puedes compartir un hábito contigo mismo.');
    }
    if (habitTitle.length > 120) {
      throw ArgumentError('El título del hábito es demasiado largo.');
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'habitId': habitId,
    'habitTitle': habitTitle,
    'senderUid': senderUid,
    'recipientUid': recipientUid,
    'status': estado.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory InvitacionHabitoCompartido.fromJson(Map<String, dynamic> json) {
    final name = (json['status'] ?? 'pendiente').toString();
    return InvitacionHabitoCompartido(
      id: (json['id'] ?? '').toString(),
      habitId: (json['habitId'] ?? '').toString(),
      habitTitle: (json['habitTitle'] ?? '').toString(),
      senderUid: (json['senderUid'] ?? '').toString(),
      recipientUid: (json['recipientUid'] ?? '').toString(),
      estado: EstadoInvitacionHabito.values.firstWhere(
        (item) => item.name == name,
        orElse: () => EstadoInvitacionHabito.pendiente,
      ),
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? '').toString(),
      )?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

/// Un mismo hábito puede asociar a usuarios sin compartir sus diarios,
/// fotografías, notas ni evidencia. El progreso se atribuye por UID.
class ProgresoHabitoCompartido {
  const ProgresoHabitoCompartido({
    required this.participantUid,
    required this.completedSessions,
    required this.targetSessions,
  });

  final String participantUid;
  final int completedSessions;
  final int targetSessions;

  double get fraction {
    if (targetSessions <= 0) return 0;
    return (completedSessions / targetSessions).clamp(0.0, 1.0).toDouble();
  }
}
