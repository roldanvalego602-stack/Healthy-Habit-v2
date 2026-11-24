import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/servicios/habit_vision_profile.dart';

void main() {
  test('detecta hidratación desde el título del hábito', () {
    expect(HabitVisionProfile.suggest(
      title: 'Tomar 6 vasos de agua', category: 'Hábitos saludables',
    ), 'hydration');
    expect(HabitVisionProfile.suggest(
      title: 'Hidratarse', category: 'Autocuidado',
    ), 'hydration');
  });

  test('frutas y verduras prevalecen sobre alimentación general', () {
    expect(HabitVisionProfile.suggest(
      title: 'Comer una fruta al día', category: 'Alimentación',
    ), 'fruit_vegetable');
    expect(HabitVisionProfile.suggest(
      title: 'Incluir verduras en la cena', category: 'Nutrición',
    ), 'fruit_vegetable');
  });

  test('identifica comidas y desayunos', () {
    expect(HabitVisionProfile.suggest(
      title: 'Preparar desayuno saludable', category: 'Hábitos',
    ), 'meal');
    expect(HabitVisionProfile.suggest(
      title: 'Almuerzo equilibrado', category: 'Nutrición',
    ), 'meal');
  });

  test('no inventa perfil para hábitos ajenos a estas imágenes', () {
    expect(HabitVisionProfile.suggest(
      title: 'Caminar treinta minutos', category: 'Ejercicio',
    ), isNull);
    expect(HabitVisionProfile.suggest(
      title: 'Dormir ocho horas', category: 'Alimentación',
    ), isNull);
    expect(HabitVisionProfile.suggest(
      title: 'Leer un libro', category: 'Crecimiento personal',
    ), isNull);
  });

  test('no asigna comida por defecto a categorías desconocidas', () {
    expect(HabitVisionProfile.suggest(
      title: 'Mantener mi rutina', category: 'Bienestar',
    ), isNull);
  });

  test('sugiere la categoría específica si el título es ambiguo', () {
    expect(HabitVisionProfile.suggest(
      title: 'Meta de hoy', category: 'Hidratación',
    ), 'hydration');
    expect(HabitVisionProfile.suggest(
      title: 'Meta de hoy', category: 'Frutas y verduras',
    ), 'fruit_vegetable');
  });
}
