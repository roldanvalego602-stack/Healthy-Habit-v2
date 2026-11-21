/// Contrato entre motor de acciones, recuperación educativa y vista del chat.
///
/// Una respuesta con action/card puede abrir una interfaz existente; ninguna
/// de estas propiedades ejecuta escrituras de Firestore por sí misma.
class HealthyAssistantReply {
  const HealthyAssistantReply(this.text, {
    this.action = '',
    this.actionArgument = '',
    this.card = '',
    this.knowledgeId = '',
  });

  final String text;
  final String action;
  final String actionArgument;
  final String card;
  /// Identificador educativo para seguimiento contextual, nunca una acción.
  final String knowledgeId;
}
