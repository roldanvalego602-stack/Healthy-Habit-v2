/// Reglas locales de participación. Las reglas de Firestore deben repetir
/// estas restricciones: una validación en el cliente no es seguridad.
class PoliticaHabitosPareja {
  const PoliticaHabitosPareja._();

  static bool puedeActivar({
    required Map<String, dynamic> invitacion,
    required String uid,
    required String habitId,
  }) {
    if (uid.isEmpty || habitId.isEmpty) return false;
    return invitacion['status'] == 'aceptada' &&
        invitacion['habitId'] == habitId &&
        (invitacion['senderUid'] == uid ||
            invitacion['recipientUid'] == uid);
  }

  static bool puedeTerminar({
    required Map<String, dynamic> invitacion,
    required String uid,
  }) => uid.isNotEmpty &&
      invitacion['status'] == 'aceptada' &&
      (invitacion['senderUid'] == uid ||
          invitacion['recipientUid'] == uid);

  static String? otroParticipante({
    required Map<String, dynamic> invitacion,
    required String uid,
  }) {
    final sender = invitacion['senderUid'];
    final recipient = invitacion['recipientUid'];
    if (sender is! String || recipient is! String ||
        sender.isEmpty || recipient.isEmpty || sender == recipient) {
      return null;
    }
    if (sender == uid) return recipient;
    if (recipient == uid) return sender;
    return null;
  }
}
