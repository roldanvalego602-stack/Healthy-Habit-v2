import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/servicios/healthy_local_image_recognition.dart';
import 'package:healthy_habit/servicios/healthy_visual_match.dart';

void main() {
  test('reconoce una manzana como evidencia visual compatible con fruta', () {
    final result = HealthyVisualMatch.evaluate(
      labels: const [
        HealthyDetectedLabel('Apple', .94),
        HealthyDetectedLabel('Food', .88),
      ],
      profile: 'fruit_vegetable',
    );
    expect(result.isMatch, isTrue);
    expect(result.matchedLabel, 'Apple');
    expect(result.confidence, .94);
    expect(result.message, contains('manzana'));
  });

  test('descarta ruido como Toy, Insect y Flesh en una sandía', () {
    final labels = const [
      HealthyDetectedLabel('Food', .70),
      HealthyDetectedLabel('Fruit', .62),
      HealthyDetectedLabel('Flesh', .58),
      HealthyDetectedLabel('Cake', .50),
      HealthyDetectedLabel('Toy', .45),
      HealthyDetectedLabel('Insect', .40),
    ];
    final relevant = HealthyVisualMatch.relevantLabels(
      labels: labels, profile: 'fruit_vegetable');
    expect(relevant.map((label) => label.name), ['Fruit']);
    expect(HealthyVisualMatch.evaluate(
      labels: labels, profile: 'fruit_vegetable').isMatch, isTrue);
    expect(HealthyVisualMatch.evaluate(
      labels: labels, profile: 'hydration').isMatch, isFalse);
  });

  test('la comparación visual no inventa agua para un vaso sin etiqueta', () {
    final labels = const [
      HealthyDetectedLabel('Glass', .98),
      HealthyDetectedLabel('Drinkware', .85),
    ];
    expect(HealthyVisualMatch.relevantLabels(
      labels: labels, profile: 'hydration'), isEmpty);
    expect(HealthyVisualMatch.evaluate(
      labels: labels, profile: 'hydration').isMatch, isFalse);
  });

  test('una etiqueta genérica Food no basta para verificar fruta', () {
    final result = HealthyVisualMatch.evaluate(
      labels: const [HealthyDetectedLabel('Food', .99)],
      profile: 'fruit_vegetable',
    );
    expect(result.isMatch, isFalse);
  });

  test('una coincidencia débil no se presenta como positiva', () {
    final result = HealthyVisualMatch.evaluate(
      labels: const [HealthyDetectedLabel('Banana', .41)],
      profile: 'fruit_vegetable',
    );
    expect(result.isMatch, isFalse);
  });

  test('no identifica cualquier bebida como agua', () {
    final result = HealthyVisualMatch.evaluate(
      labels: const [HealthyDetectedLabel('Soft drink', .95)],
      profile: 'hydration',
    );
    expect(result.isMatch, isFalse);
  });

  test('una botella sin agua visible no acredita hidratación', () {
    final result = HealthyVisualMatch.evaluate(
      labels: const [HealthyDetectedLabel('Bottle', .98)],
      profile: 'hydration',
    );
    expect(result.isMatch, isFalse);
  });

  test('evidencia de agua compatible con hidratación', () {
    final result = HealthyVisualMatch.evaluate(
      labels: const [HealthyDetectedLabel('Water', .85)],
      profile: 'hydration',
    );
    expect(result.isMatch, isTrue);
  });

  test('habito ajeno a las categorias no obtiene coincidencia', () {
    final result = HealthyVisualMatch.evaluate(
      labels: const [HealthyDetectedLabel('Food', .99)],
      profile: HealthyVisualMatch.suggestedProfile(
        'Dormir ocho horas', 'Salud',
      ),
    );
    expect(result.isMatch, isFalse);
  });

  test('resultados sin etiquetas no crean coincidencias falsas', () {
    final result = HealthyVisualMatch.evaluate(
      labels: const [],
      profile: 'meal',
    );
    expect(result.isMatch, isFalse);
    expect(result.message, contains('No se detectaron'));
  });
}
