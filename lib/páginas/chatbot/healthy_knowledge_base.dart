/// Standalone text normalization so this module does not depend on older files.
String _normalizarTexto(String value) => value
    .toLowerCase()
    .replaceAll(RegExp('[àáâãä]'), 'a')
    .replaceAll(RegExp('[èéêë]'), 'e')
    .replaceAll(RegExp('[ìíîï]'), 'i')
    .replaceAll(RegExp('[òóôõö]'), 'o')
    .replaceAll(RegExp('[ùúûü]'), 'u')
    .replaceAll('ñ', 'n')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

bool _contieneTermino(String input, String term) {
  final key = _normalizarTexto(term);
  if (key.isEmpty) return false;
  final suffix = key.length > 3 ? r'(?:s|es)?' : '';
  return RegExp(
    r'(^|[^a-z0-9])' + RegExp.escape(key) + suffix + r'($|[^a-z0-9])',
  ).hasMatch(input);
}


/// Knowledge base curated for brief, general wellness education.
/// This does not perform diagnoses, food composition estimates or medical plans.
class HealthyWellnessKnowledgeBase {
  const HealthyWellnessKnowledgeBase();

  static const entries = <KnowledgeEntry>[
    KnowledgeEntry(['proteina', 'proteinas', 'musculo', 'ganar masa muscular'],
      'Las proteínas ayudan a reparar y mantener tejidos. Puedes obtenerlas de frijoles, lentejas, huevo, lácteos, pescado, pollo, tofu o semillas. Distribuir fuentes variadas entre tus comidas suele ser práctico. Para necesidades individuales, consulta a nutrición.'),
    KnowledgeEntry(['carbohidrato', 'carbohidratos', 'arroz', 'avena', 'pan integral'],
      'Los carbohidratos aportan energía. Prefiere con frecuencia cereales integrales, frutas, leguminosas y verduras; no es necesario eliminarlos para comer equilibradamente.'),
    KnowledgeEntry(['grasa saludable', 'grasas', 'aguacate', 'aceite de oliva', 'nueces'],
      'Las grasas participan en funciones esenciales. Aguacate, nueces, semillas y aceites vegetales pueden formar parte de una alimentación variada. Modera las grasas trans y considera las porciones sin obsesionarte con ellas.'),
    KnowledgeEntry(['fibra', 'estrenimiento', 'digestión', 'digestion'],
      'La fibra se encuentra en frutas, verduras, leguminosas y cereales integrales. Auméntala gradualmente y acompáñala con líquidos adecuados. Si hay síntomas persistentes, busca valoración médica.'),
    KnowledgeEntry(['vitamina', 'vitaminas', 'mineral', 'minerales', 'micronutrientes'],
      'Las vitaminas y minerales cumplen distintas funciones. Comer alimentos variados ayuda a cubrir necesidades; los suplementos no sustituyen una dieta completa y no siempre son necesarios.'),
    KnowledgeEntry(['hierro', 'anemia'],
      'El hierro se encuentra en carnes y también en lentejas, frijoles y algunas semillas. Combinar fuentes vegetales con vitamina C puede mejorar su aprovechamiento. La anemia necesita evaluación clínica; no te automediques hierro.'),
    KnowledgeEntry(['calcio', 'huesos', 'vitamina d'],
      'El calcio y la vitamina D son importantes para la salud ósea. Considera lácteos o bebidas vegetales fortificadas y otras fuentes de calcio. La necesidad de suplementación requiere evaluación.'),
    KnowledgeEntry(['azucar', 'refresco', 'bebidas azucaradas'],
      'Reducir bebidas azucaradas de consumo habitual puede ser un primer cambio útil. El agua simple es una alternativa frecuente; no tienes que prohibirte alimentos para progresar.'),
    KnowledgeEntry(['sal', 'sodio', 'hipertension'],
      'Gran parte del sodio puede venir de alimentos muy procesados. Revisa etiquetas y prueba sazonar con hierbas o especias. Si tienes hipertensión, sigue las indicaciones de tu equipo de salud.'),
    KnowledgeEntry(['etiqueta nutricional', 'etiquetas', 'sellos', 'porciones'],
      'En una etiqueta observa tamaño de porción, ingredientes y nutrimentos. Compara productos con la misma porción y considera el patrón general de alimentación, no un número aislado.'),
    KnowledgeEntry(['plato saludable', 'plato equilibrado', 'comida equilibrada', 'balancear mi plato'],
      'Una guía visual sencilla es incluir verduras, alguna fuente de proteína y cereales o tubérculos, variando alimentos durante el día. Las cantidades dependen de tus necesidades.'),
    KnowledgeEntry(['fruta', 'frutas', 'verdura', 'verduras'],
      'Variar colores y tipos de frutas y verduras ayuda a ampliar el aporte de fibra y micronutrientes. Pueden ser frescas, congeladas o en conserva sin exceso de azúcar o sal.'),
    KnowledgeEntry(['legumbre', 'leguminosas', 'frijol', 'lenteja', 'garbanzo'],
      'Los frijoles, lentejas y garbanzos aportan fibra y proteína vegetal, suelen ser accesibles y combinan bien con cereales y verduras.'),
    KnowledgeEntry(['desayunar', 'desayuno saludable', 'ideas para desayunar'],
      'Tres ideas flexibles: avena con fruta y yogur; huevo con tortilla y verduras; o frijoles con pan integral. Elige según hambre, disponibilidad y preferencias.'),
    KnowledgeEntry(['cena saludable', 'que cenar', 'ideas para cenar'],
      'Para una cena práctica puedes combinar verduras con huevo, frijoles, pescado o tofu, y una porción de cereal o tortilla según tu apetito.'),
    KnowledgeEntry(['colacion', 'snack saludable', 'entre comidas'],
      'Si tienes hambre entre comidas, prueba fruta con yogur, una porción de nueces o verduras con hummus. No tienes obligación de comer colaciones si no las necesitas.'),
    KnowledgeEntry(['comer barato', 'economico', 'presupuesto comida', 'alimentacion economica'],
      'Para comer variado con presupuesto ajustado, planifica con frijoles, lentejas, avena, huevo, verduras de temporada y alimentos locales. Reutilizar preparaciones reduce desperdicio.'),
    KnowledgeEntry(['vegetariano', 'vegetariana', 'vegano', 'vegana'],
      'Una alimentación vegetal puede ser variada si se planifica bien: leguminosas, cereales, verduras, frutas, semillas y fuentes adecuadas de nutrientes críticos. En dietas veganas la vitamina B12 requiere atención particular.'),
    KnowledgeEntry(['alergia alimentaria', 'alergias', 'intolerancia', 'gluten', 'lactosa'],
      'Una alergia alimentaria no es lo mismo que una intolerancia. No elimines grupos completos por sospecha sin una evaluación adecuada. Dificultad para respirar o hinchazón intensa tras comer requiere atención urgente.'),
    KnowledgeEntry(['diabetes', 'glucosa', 'azucar en sangre'],
      'La alimentación puede apoyar el control de glucosa, pero debe individualizarse según medicamentos y situación clínica. Evita modificar tratamiento por consejos del chat.'),
    KnowledgeEntry(['bajar de peso', 'adelgazar', 'perder grasa'],
      'Los cambios sostenibles suelen centrarse en alimentación variada, actividad física, descanso y seguimiento realista. Evita dietas extremas y metas precipitadas; el peso no resume toda tu salud.'),
    KnowledgeEntry(['subir de peso', 'aumentar peso', 'ganar peso'],
      'Para aumentar peso de forma saludable, ayuda comer con regularidad, incluir alimentos densos en nutrientes y entrenar fuerza si es apropiado. Si hay pérdida involuntaria de peso, consulta a un profesional.'),
    KnowledgeEntry(['ayuno', 'ayuno intermitente'],
      'El ayuno no es indispensable para mejorar hábitos y puede no ser adecuado para algunas personas, por ejemplo durante embarazo, crecimiento o con antecedentes de trastornos alimentarios.'),
    KnowledgeEntry(['creatina', 'proteina en polvo', 'suplemento', 'suplementos'],
      'Los suplementos no reemplazan sueño, entrenamiento ni alimentación. Sus beneficios y riesgos dependen de la sustancia, edad, salud y calidad del producto; consulta antes de usarlos si tienes condiciones médicas.'),
    KnowledgeEntry(['cardio', 'ejercicio aerobico', 'resistencia cardiovascular', 'correr'],
      'El ejercicio aeróbico incluye caminar a paso ligero, bicicleta o nadar. Aumenta la duración gradualmente. Como referencia general para adultos, la OMS recomienda 150–300 minutos semanales de actividad moderada o 75–150 vigorosa.'),
    KnowledgeEntry(['fuerza', 'pesas', 'entrenamiento de fuerza', 'hipertrofia', 'mancuernas'],
      'Entrenar fuerza trabaja músculos y huesos. Como punto de partida, practica movimientos sencillos con técnica controlada y deja tiempo para recuperarte. Para adultos, la OMS recomienda fortalecer grupos musculares principales al menos 2 días por semana.'),
    KnowledgeEntry(['sentadilla', 'sentadillas'],
      'La sentadilla trabaja principalmente piernas y cadera. Mantén movimiento controlado, apoya los pies y usa un rango cómodo. Si hay dolor, detente y revisa la técnica.'),
    KnowledgeEntry(['flexion', 'flexiones', 'lagartijas'],
      'Las flexiones trabajan pecho, hombros y tríceps. Puedes comenzar contra una pared o superficie elevada y progresar según tu fuerza. Evita forzar muñecas u hombros doloridos.'),
    KnowledgeEntry(['plancha abdominal', 'planchas', 'core', 'abdominales'],
      'La plancha es una opción de estabilidad del tronco. Mantén postura cómoda y respiración continua; empieza con intervalos cortos y evita aguantar la respiración.'),
    KnowledgeEntry(['calentar', 'calentamiento', 'antes de entrenar'],
      'Antes de entrenar, realiza varios minutos de movilidad y actividad suave relacionada con la sesión. Comienza progresivamente, especialmente si llevas tiempo sin moverte.'),
    KnowledgeEntry(['estirar', 'estiramientos', 'movilidad'],
      'La movilidad suave y los estiramientos pueden ayudar a mantener rango de movimiento. No rebotes ni fuerces posiciones dolorosas; adapta la práctica a tus necesidades.'),
    KnowledgeEntry(['descansar despues de entrenar', 'recuperacion muscular', 'agujetas'],
      'La recuperación incluye descanso, suficiente alimentación y progresión gradual de cargas. Dolor agudo, hinchazón intensa o pérdida de función no son molestias normales de entrenamiento.'),
    KnowledgeEntry(['entrenar en casa', 'rutina en casa', 'ejercicios en casa'],
      'Puedes empezar con sentarte y levantarte de una silla, caminar, flexiones contra pared y movilidad. Haz sesiones breves y adapta el esfuerzo a tu capacidad.'),
    KnowledgeEntry(['sedentarismo', 'sentado mucho tiempo', 'pausas activas'],
      'Interrumpir periodos prolongados sentado con pausas de movimiento es útil. Un paseo corto o levantarte regularmente cuenta como progreso.'),
    KnowledgeEntry(['dormir mejor', 'higiene del sueno', 'insomnio'],
      'Prueba horarios regulares, menos cafeína tarde, luz natural por la mañana y una rutina tranquila antes de acostarte. Si el insomnio persiste, busca ayuda profesional.'),
    KnowledgeEntry(['motivacion para entrenar', 'no tengo motivacion', 'disciplina'],
      'Reduce la barrera de inicio: prepara tu ropa, elige una actividad de 5 minutos y marca tu avance. Una acción pequeña repetida suele ser más sostenible que esperar motivación perfecta.'),
  ];

  String? answer(String query) {
    final normalized = _normalizarTexto(query);
    if (normalized.isEmpty) return null;
    KnowledgeEntry? best;
    var maxScore = 0;
    for (final entry in entries) {
      var score = 0;
      for (final key in entry.keywords) {
        if (_contieneTermino(normalized, key)) {
          score += key.contains(' ') ? 4 : 2;
        }
      }
      if (score > maxScore) {
        maxScore = score;
        best = entry;
      }
    }
    return maxScore > 0 ? best?.answer : null;
  }
}

class KnowledgeEntry {
  final List<String> keywords;
  final String answer;
  const KnowledgeEntry(this.keywords, this.answer);
}
