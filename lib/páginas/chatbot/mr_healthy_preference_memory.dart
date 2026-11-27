import 'healthy_hybrid_knowledge.dart';

/// Contexto efímero de restricciones expresadas por el usuario.
/// No se persiste, no analiza historiales ajenos ni representa datos médicos.
class MrHealthyPreferenceMemory {
  String _topicId = '';
  final Set<String> _conditions = <String>{};

  String get topicId => _topicId;
  Set<String> get conditions => Set<String>.unmodifiable(_conditions);

  static const Map<String, Map<String, List<String>>> _recognized = {
    'food_desayuno': {
      'sin lacteos': ['sin lacteos', 'sin leche', 'sin productos lacteos'],
      'economica': ['economica', 'economico', 'barato', 'barata',
        'baratos', 'baratas', 'poco presupuesto', 'poco dinero',
        'mas barato', 'mas barata'],
      'rapida': ['rapida', 'rapido', 'sin tiempo', 'tengo prisa'],
    },
    'food_cena': {
      'vegetariana': ['vegetariana', 'vegetariano', 'sin carne'],
      'economica': ['economica', 'economico', 'barata', 'barato',
        'mas barato', 'poco dinero'],
    },
    'food_almuerzo': {
      'para llevar': ['para llevar', 'llevar al trabajo'],
      'economica': ['economica', 'economico', 'barata', 'barato',
        'mas barato', 'poco dinero'],
    },
    'food_fibra': {
      'para llevar': ['para llevar'],
      'economica': ['economica', 'economico', 'barata', 'barato'],
    },
    'food_colacion': {
      'sin refrigeracion': ['sin refrigeracion', 'sin refri'],
      'economica': ['economica', 'economico', 'barata', 'barato'],
    },
    'ex_principiante': {
      'en casa': ['en casa', 'desde casa', 'hacerlo en casa'],
      'sin equipo': ['sin equipo', 'sin aparatos', 'sin pesas'],
      'caminar': ['caminar', 'caminata'],
    },
    'ex_fuerza': {
      'en casa': ['en casa', 'desde casa'],
      'sin equipo': ['sin equipo', 'sin aparatos', 'sin pesas'],
    },
    'ex_cardio': {
      'caminar': ['caminar', 'caminata'],
      'tiempo': ['poco tiempo', 'sin tiempo', 'tengo prisa'],
    },
    'ex_motivacion': {
      'cansancio': ['cansado', 'cansada', 'cansancio'],
      'tiempo': ['poco tiempo', 'sin tiempo', 'tengo prisa'],
    },
  };

  static final RegExp _clear = RegExp(
    r'^(cambiar de tema|cambiando de tema|olvida eso|'
    r'borra mis preferencias|ignora mis preferencias|'
    r'empecemos de cero|reinicia mis preferencias)$',
  );
  static final RegExp _clinical = RegExp(
    r'\b(alergia\w*|anafilaxia|embaraz\w*|lactancia|'
    r'diabetes|medicamento\w*|dosis|tratamiento|'
    r'intoxic\w*|asfixia|desmay\w*|'
    r'cuantas calorias|cuanto debo|mi saldo|mi contrasena)\b',
  );
  static final RegExp _operational = RegExp(
    r'^(comprar|compra|activar|activa|agregar|agrega|'
    r'borra|borrar|elimina|eliminar|desactiva|desactivar)\b',
  );
  static final RegExp _negation = RegExp(
    r'\b(no quiero|no prefiero|descarta|evita|ya no quiero|'
    r'quita esa|sin restriccion)\b',
  );

  static String _normalize(String input) =>
      HealthyKnowledgeIndex.normalize(input);

  static bool _has(String normalized, String phrase) =>
      (' $normalized ').contains(' ${_normalize(phrase)} ');

  static Set<String> _extract(String input, String topicId) {
    final supported = _recognized[topicId];
    if (supported == null) return <String>{};
    final normalized = _normalize(input);
    return {
      for (final entry in supported.entries)
        if (entry.value.any((phrase) => _has(normalized, phrase))) entry.key,
    };
  }

  static bool _needsReset(String input) =>
      _clear.hasMatch(_normalize(input));

  void reset() {
    _topicId = '';
    _conditions.clear();
  }

  /// No altera la memoria. El candidato se usa solamente para una respuesta
  /// verificada del mismo tema, nunca para ejecutar operaciones.
  String compose(String input, String previousTopicId) {
    final q = _normalize(input);
    if (_topicId != previousTopicId ||
        _conditions.isEmpty || _needsReset(input) ||
        _clinical.hasMatch(q) || _operational.hasMatch(q) ||
        _negation.hasMatch(q)) {
      return input;
    }
    final current = _extract(input, previousTopicId);
    if (current.isEmpty) return input;
    final combined = {..._conditions, ...current};
    // Nunca inventar una combinación de tres condiciones no revisada.
    if (combined.length != 2 || combined.length == current.length) {
      return input;
    }
    return '$input ${_conditions.difference(current).join(' ')}';
  }

  /// Solo registrar información de entradas que obtuvieron una respuesta
  /// editorial aprobada, y mantenerla como máximo en el tema actual.
  void record(String input, String resolvedTopicId) {
    if (resolvedTopicId.isEmpty || _needsReset(input)) {
      reset();
      return;
    }
    if (_topicId != resolvedTopicId) {
      _conditions.clear();
      _topicId = resolvedTopicId;
    }
    final q = _normalize(input);
    if (_clinical.hasMatch(q) || _operational.hasMatch(q)) return;
    if (_negation.hasMatch(q)) {
      final mentioned = _extract(input, resolvedTopicId);
      _conditions.removeAll(mentioned);
      return;
    }
    final recognized = _extract(input, resolvedTopicId);
    if (recognized.isEmpty) return;
    final next = {..._conditions, ...recognized};
    if (next.length > 2) {
      // Conservar las restricciones más recientes y evitar inferir
      // cómo resolver preferencias contrapuestas.
      _conditions
        ..clear()
        ..addAll(recognized.take(2));
    } else {
      _conditions.addAll(recognized);
    }
  }
}
