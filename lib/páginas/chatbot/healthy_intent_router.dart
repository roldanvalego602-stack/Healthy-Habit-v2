import 'healthy_hybrid_knowledge.dart';

/// Clasificación local de intenciones críticas. No lee ni escribe Firestore.
/// Los datos del perfil se consultan posteriormente por el flujo autorizado.
class HealthyIntentRouter {
  const HealthyIntentRouter._();

  static const _currencyTerms = <String>{
    'moneda', 'monedas', 'coin', 'coins', 'saldo', 'dinero',
    'habitcoin', 'habitcoins', 'puntos canjeables',
  };
  static const _accountTerms = <String>{
    'cuenta', 'perfil', 'usuario', 'account',
  };
  static const _deletionTerms = <String>{
    'borrar', 'eliminar', 'cerrar', 'suprimir', 'dar de baja',
    'desactivar', 'cancelar', 'quitar', 'deshacerme',
  };
  static final _ownership = RegExp(
    r'\b(mi|mis|tengo|tienes|tendra|me quedan|me queda|me restan|'
    r'he ganado|he acumulado|acumule|he conseguido|poseo|dispongo|'
    r'disponibles|actuales|me dieron|mi saldo|saldo actual|'
    r'cuantas|cuantos|cuanto|cuanta)\b',
  );

  static String normalize(String text) =>
      HealthyKnowledgeIndex.normalize(text).replaceAll(
        RegExp(r'\bhabit\s+coins?\b'), 'habitcoins');

  static bool _containsAny(String query, Iterable<String> terms) =>
      terms.any((term) => (' $query ').contains(' $term '));

  static bool asksForAccountDeletion(String text) {
    final q = normalize(text);
    return _containsAny(q, _accountTerms) &&
        _containsAny(q, _deletionTerms) &&
        (RegExp(r'\b(mi|mis|cuenta|perfil|usuario)\b').hasMatch(q));
  }

  static bool asksForCoinBalance(String text) {
    final q = normalize(text);
    final currency = _containsAny(q, _currencyTerms);
    if (!currency) return false;
    // "¿Cuánto cuesta comprar monedas?" no es una consulta de saldo.
    if (_containsAny(q, const ['comprar', 'compra', 'canjear',
      'precio', 'cuesta', 'adquirir', 'vender'])) {
      return false;
    }
    return _ownership.hasMatch(q) ||
        _containsAny(q, const ['saldo', 'cantidad de monedas',
          'cuenta de monedas']);
  }

  static bool asksForHabitAction(String text) {
    final q = normalize(text);
    if (asksForAccountDeletion(text)) return false;
    final modifies = _containsAny(q, const [
      'agrega', 'agregar', 'anade', 'anadir', 'activar',
      'elimina', 'eliminar', 'borrar', 'quitar', 'abandonar',
      'cancelar', 'iniciar', 'registrar', 'quita',
    ]);
    final target = _containsAny(q, const [
      'habito', 'habitos', 'actividad', 'actividades',
    ]);
    return modifies && target;
  }
}
