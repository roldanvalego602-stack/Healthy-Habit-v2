import 'healthy_hybrid_knowledge.dart';

/// Contexto efímero de Mr. Healthy: no es un clasificador ML ni un permiso.
/// Solo conserva la referencia educativa de la sesión actual.
class HealthyChatContext {
  String _knowledgeId = '';
  int _followUpCount = 0;

  String get knowledgeId => _knowledgeId;

  void reset() {
    _knowledgeId = '';
    _followUpCount = 0;
  }

  /// La sesión no hereda temas tras cambiar a perfil, tienda o acciones.
  static bool isExplicitTopicSwitch(String input) {
    final q = HealthyKnowledgeIndex.normalize(input);
    return RegExp(
      r'\b(monedas|coins|saldo|habitcoins|xp|experiencia|nivel|'
      r'cuenta|perfil|usuario|tienda|desafios|misiones|'
      r'agregar|anadir|eliminar|borrar|quitar|cancelar|'
      r'habito|habitos|armario)\b',
    ).hasMatch(q);
  }

  static bool isEducationalFollowUp(String input) {
    final q = HealthyKnowledgeIndex.normalize(input);
    return RegExp(
      r'\b(y si|y con|si le|si lo|lo preparo|lo cocino|'
      r'prepararlo|cocinarlo|comerlo|con jamon|'
      r'le agrego|le pongo|que mas|dime mas|'
      r'hace dano|es peligroso)\b',
    ).hasMatch(q);
  }

  /// Máximo dos referencias consecutivas sin volver a nombrar el tema.
  String referenceFor(String input) {
    if (_knowledgeId.isEmpty || _followUpCount >= 2 ||
        isExplicitTopicSwitch(input) || !isEducationalFollowUp(input)) {
      return '';
    }
    return _knowledgeId;
  }

  void recordEducationalReply({
    required String input,
    required String knowledgeId,
    required String previousReference,
  }) {
    if (knowledgeId.isEmpty) {
      reset();
      return;
    }
    _followUpCount = previousReference.isNotEmpty ? _followUpCount + 1 : 0;
    _knowledgeId = knowledgeId;
  }

  /// Un verbo sin objeto explícito debe solicitar aclaración; nunca generar
  /// navegación a hábitos o eliminación de cuenta por sí solo.
  static bool needsActionClarification(String input) {
    final q = HealthyKnowledgeIndex.normalize(input);
    const shortCommands = <String>{
      'eliminalo', 'eliminala', 'quitalo', 'quitala',
      'borralo', 'borrala', 'agregalo', 'agregala',
      'anadelo', 'anadela', 'activarlo', 'desactivalo',
      'hazlo ya', 'hazlo', 'borrame',
    };
    return shortCommands.contains(q);
  }
}
