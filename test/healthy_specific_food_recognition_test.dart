import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/servicios/healthy_local_image_recognition.dart';
import 'package:healthy_habit/servicios/healthy_specific_food_recognition.dart';

void main() {
  test('una sandía etiquetada explícitamente se reconoce como sandía', () {
    final result = HealthySpecificFoodRecognition.identify(const [
      HealthyDetectedLabel('Fruit', .96),
      HealthyDetectedLabel('Watermelon', .89),
      HealthyDetectedLabel('Food', .88),
    ]);
    expect(result.isSpecific, isTrue);
    expect(result.name, 'sandía');
    expect(result.sourceLabel, 'Watermelon');
    expect(result.confidence, .89);
  });

  test('una imagen de sandía sin etiqueta concreta no se inventa', () {
    final result = HealthySpecificFoodRecognition.identify(const [
      HealthyDetectedLabel('Food', .74),
      HealthyDetectedLabel('Fruit', .63),
      HealthyDetectedLabel('Vegetable', .35),
      HealthyDetectedLabel('Flesh', .56),
      HealthyDetectedLabel('Toy', .55),
    ]);
    expect(result.isSpecific, isFalse);
    expect(result.name, isNull);
    expect(result.confidence, 0);
  });

  test('etiquetas específicas débiles no se anuncian como identificadas', () {
    final result = HealthySpecificFoodRecognition.identify(const [
      HealthyDetectedLabel('Watermelon', .53),
      HealthyDetectedLabel('Apple', .61),
    ]);
    expect(result.isSpecific, isFalse);
    expect(result.name, isNull);
  });

  test('la etiqueta de objeto no se deduce desde nombre de archivo', () {
    final result = HealthySpecificFoodRecognition.identify(const [
      HealthyDetectedLabel('Food', .99),
    ]);
    expect(result.isSpecific, isFalse);
  });

  test('elige el candidato específico de mayor confianza', () {
    final result = HealthySpecificFoodRecognition.identify(const [
      HealthyDetectedLabel('Watermelon', .74),
      HealthyDetectedLabel('Apple', .83),
      HealthyDetectedLabel('Banana', .72),
    ]);
    expect(result.name, 'manzana');
    expect(result.confidence, .83);
  });

  test('rechaza porcentajes fuera de rango', () {
    final result = HealthySpecificFoodRecognition.identify(const [
      HealthyDetectedLabel('Apple', 1.4),
      HealthyDetectedLabel('Orange', -.3),
    ]);
    expect(result.isSpecific, isFalse);
  });

  test('el vocabulario es explícito y no afirma verificar un hábito', () {
    expect(HealthySpecificFoodRecognition.foodNames['watermelon'], 'sandía');
    expect(HealthySpecificFoodRecognition.foodNames['carrot'], 'zanahoria');
    expect(HealthySpecificFoodRecognition.genericLabels.contains('fruit'),
      isTrue);
    expect(HealthySpecificFoodRecognition.foodNames.containsKey('fruit'),
      isFalse);
  });
}
