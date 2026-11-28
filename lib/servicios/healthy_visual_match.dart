import 'healthy_local_image_recognition.dart';
import 'habit_vision_profile.dart';
import 'healthy_specific_food_recognition.dart';

/// Comparación orientativa: no equivale a verificar consumo o actividad.
class HealthyVisualMatch {
  const HealthyVisualMatch({
    required this.profile,
    required this.isMatch,
    required this.confidence,
    required this.message,
    required this.matchedLabel,
  });

  final String? profile;
  final bool isMatch;
  final double confidence;
  final String message;
  final String? matchedLabel;

  static const _positive = <String, List<String>>{
    'hydration': [
      'water', 'drinking water', 'bottled water', 'water bottle',
    ],
    'fruit_vegetable': [
      'fruit', 'vegetable', 'apple', 'banana', 'orange', 'pear',
      'grape', 'strawberry', 'pineapple', 'watermelon', 'mango',
      'carrot', 'broccoli', 'lettuce', 'salad', 'tomato',
      'cucumber', 'potato', 'citrus',
    ],
    'meal': [
      'food', 'dish', 'meal', 'breakfast', 'lunch', 'dinner',
      'cuisine', 'sandwich', 'soup', 'pasta', 'rice',
      'salad', 'bread', 'vegetable', 'fruit', 'pizza',
      'hamburger',
    ],
  };

  static const _spanish = <String, String>{
    'water': 'agua', 'drinking water': 'agua para beber',
    'bottled water': 'agua embotellada',
    'water bottle': 'botella de agua',
    'bottle': 'botella', 'drinkware': 'recipiente para beber',
    'drinking glass': 'vaso', 'glass': 'vaso', 'cup': 'taza o vaso',
    'fruit': 'fruta', 'vegetable': 'verdura', 'apple': 'manzana',
    'banana': 'plátano', 'orange': 'naranja', 'pear': 'pera',
    'grape': 'uva', 'strawberry': 'fresa', 'pineapple': 'piña',
    'watermelon': 'sandía', 'mango': 'mango', 'carrot': 'zanahoria',
    'broccoli': 'brócoli', 'lettuce': 'lechuga', 'salad': 'ensalada',
    'tomato': 'tomate', 'cucumber': 'pepino', 'potato': 'papa',
    'citrus': 'cítrico', 'food': 'alimento', 'dish': 'platillo',
    'meal': 'comida', 'breakfast': 'desayuno', 'lunch': 'almuerzo',
    'dinner': 'cena', 'cuisine': 'comida preparada',
    'sandwich': 'sándwich', 'soup': 'sopa', 'pasta': 'pasta',
    'rice': 'arroz', 'bread': 'pan', 'pizza': 'pizza',
    'hamburger': 'hamburguesa', 'plate': 'plato',
  };

  /// Reduce ruido visual: los resultados genéricos del etiquetador no
  /// son diagnósticos de una fotografía ni pruebas del hábito.
  /// Conservamos la lista íntegra solo en «Ver etiquetas técnicas».
  static List<HealthyDetectedLabel> relevantLabels({
    required List<HealthyDetectedLabel> labels,
    required String? profile,
  }) {
    final expected = _positive[profile] ?? const <String>[];
    return labels.where((label) =>
      expected.contains(label.name.toLowerCase().trim()) &&
      label.confidence >= 0.3,
    ).toList(growable: false);
  }

  static String displayName(String label) =>
      _spanish[label.toLowerCase().trim()] ?? label;

  static HealthyVisualMatch evaluate({
    required List<HealthyDetectedLabel> labels,
    required String? profile,
  }) {
    if (profile == null || !_positive.containsKey(profile)) {
      return const HealthyVisualMatch(
        profile: null,
        isMatch: false,
        confidence: 0,
        matchedLabel: null,
        message: 'Este hábito no permite comparar automáticamente '
            'su cumplimiento mediante una fotografía.',
      );
    }
    final expected = _positive[profile]!;
    HealthyDetectedLabel? best;
    for (final label in labels) {
      final term = label.name.toLowerCase().trim();
      if (expected.contains(term) && label.confidence >= 0.55 &&
          (best == null || label.confidence > best.confidence)) {
        best = label;
      }
    }
    if (best == null) {
      return HealthyVisualMatch(
        profile: profile,
        isMatch: false,
        confidence: 0,
        matchedLabel: null,
        message: labels.isEmpty
            ? 'No se detectaron elementos claros en esta fotografía.'
            : 'No se encontró una coincidencia visual suficiente con '
              'el tipo de evidencia esperado.',
      );
    }
    return HealthyVisualMatch(
      profile: profile,
      isMatch: true,
      confidence: best.confidence,
      matchedLabel: best.name,
      message: 'Coincidencia visual: se identificó '
          '${displayName(best.name)} en la fotografía.',
    );
  }

  /// Combina indicios del etiquetador general y de un modelo específico.
  /// No crea premios, no verifica ingestión ni convierte fotos en
  /// certificados. Cada motor conserva su origen en el mensaje.
  static HealthyVisualMatch evaluateCombined({
    required List<HealthyDetectedLabel> labels,
    required String? profile,
    List<HealthyDetectedLabel>? specializedLabels,
  }) {
    final generic = evaluate(labels: labels, profile: profile);
    if (specializedLabels == null || profile == null) return generic;

    final specific = HealthySpecificFoodRecognition
        .identifyFromSpecializedModel(specializedLabels);
    if (!specific.isSpecific || specific.sourceLabel == null) {
      return generic;
    }
    final term = specific.sourceLabel!.toLowerCase();
    const fruitsAndVegetables = <String>{
      'watermelon', 'apple_fruit', 'banana', 'orange_fruit',
      'pear', 'grape', 'strawberry', 'pineapple', 'mango',
      'peach', 'lemon', 'coconut', 'carrot', 'broccoli',
      'cabbage', 'tomato', 'potato', 'mushroom',
    };
    const preparedFoods = <String>{
      'bread', 'chicken', 'cookie',
    };
    final compatible = (profile == 'fruit_vegetable' &&
            fruitsAndVegetables.contains(term)) ||
        (profile == 'meal' &&
            (fruitsAndVegetables.contains(term) ||
             preparedFoods.contains(term)));
    if (!compatible || generic.isMatch) return generic;

    return HealthyVisualMatch(
      profile: profile,
      isMatch: true,
      confidence: specific.confidence,
      matchedLabel: specific.sourceLabel,
      message: 'El modelo especializado encontró una posible '
          '${specific.name} relacionada con esta categoría. '
          'No demuestra consumo ni cumplimiento.',
    );
  }

  static String? suggestedProfile(String title, String category) =>
      HabitVisionProfile.suggest(title: title, category: category);

  static String titleOf(String? profile) =>
      HabitVisionProfile.label(profile);
}
