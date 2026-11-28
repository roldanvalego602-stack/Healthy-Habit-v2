import 'healthy_local_image_recognition.dart';

/// Identificación ESPECÍFICA de objetos alimentarios a partir de etiquetas
/// observadas. El motor general de ML Kit no identifica necesariamente
/// especies: la categoría "Fruit" nunca se transforma en "sandía".
///
/// Esta capa no utiliza colores, nombres del archivo, elecciones del usuario
/// ni inferencias a partir de etiquetas generales. Un modelo especializado
/// futuro podrá entregar sus propias etiquetas mediante este mismo contrato.
class HealthySpecificFoodResult {
  const HealthySpecificFoodResult({
    required this.name,
    required this.confidence,
    required this.sourceLabel,
    required this.isSpecific,
  });

  final String? name;
  final double confidence;
  final String? sourceLabel;
  final bool isSpecific;
}

/// Vocabulario concreto y cerrado; evita nombres inexistentes o
/// traducciones inesperadas en los resultados visibles al usuario.
class HealthySpecificFoodRecognition {
  const HealthySpecificFoodRecognition._();

  static const minimumConfidence = 0.70;

  static const foodNames = <String, String>{
    'watermelon': 'sandía',
    'apple': 'manzana',
    'banana': 'plátano',
    'orange': 'naranja',
    'pear': 'pera',
    'grape': 'uva',
    'grapes': 'uvas',
    'strawberry': 'fresa',
    'pineapple': 'piña',
    'mango': 'mango',
    'peach': 'durazno',
    'cherry': 'cereza',
    'kiwi': 'kiwi',
    'papaya': 'papaya',
    'melon': 'melón',
    'avocado': 'aguacate',
    'carrot': 'zanahoria',
    'broccoli': 'brócoli',
    'cucumber': 'pepino',
    'tomato': 'tomate',
    'potato': 'papa',
    'lettuce': 'lechuga',
    'spinach': 'espinaca',
    'onion': 'cebolla',
    'corn': 'maíz',
    'egg': 'huevo',
    'eggs': 'huevos',
    'rice': 'arroz',
    'bread': 'pan',
    'pasta': 'pasta',
    'pizza': 'pizza',
    'sandwich': 'sándwich',
    'hamburger': 'hamburguesa',
    'soup': 'sopa',
    'cheese': 'queso',
    'yogurt': 'yogur',
  };

  static const genericLabels = <String>{
    'fruit', 'fruits', 'vegetable', 'vegetables', 'food', 'meal',
    'dish', 'cuisine', 'produce', 'plant', 'salad', 'breakfast',
    'lunch', 'dinner', 'flesh', 'toy', 'cake', 'drinkware', 'glass',
  };

  static HealthySpecificFoodResult identify(
      List<HealthyDetectedLabel> labels) {
    HealthyDetectedLabel? best;
    String? name;

    for (final item in labels) {
      final normalized = item.name.trim().toLowerCase();
      final candidate = foodNames[normalized];
      if (candidate == null || item.confidence < minimumConfidence ||
          !item.confidence.isFinite || item.confidence > 1) {
        continue;
      }
      if (best == null || item.confidence > best.confidence) {
        best = item;
        name = candidate;
      }
    }
    if (best == null) {
      return const HealthySpecificFoodResult(
        name: null, confidence: 0, sourceLabel: null, isSpecific: false,
      );
    }
    return HealthySpecificFoodResult(
      name: name,
      confidence: best.confidence,
      sourceLabel: best.name,
      isSpecific: true,
    );
  }
}
