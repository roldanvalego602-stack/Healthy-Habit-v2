import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/perfil/profile_habit_insights.dart';

void main() {
  test('identifica hábito y categoría más practicados', () {
    final summary = ProfileHabitInsights.fromDocuments([
      {'title': 'Tomar agua', 'category': 'Hidratación', 'latestProgress': 8},
      {'title': 'Llevar botella', 'category': 'Hidratación', 'latestProgress': 5},
      {'title': 'Fruta', 'category': 'Alimentación', 'latestProgress': 10},
    ]);
    expect(summary.favoriteTitle, 'Fruta');
    expect(summary.topCategory, 'Hidratación');
    expect(summary.registeredCount, 23);
  });

  test('no atribuye favoritos si falta progreso registrado', () {
    final summary = ProfileHabitInsights.fromDocuments([
      {'title': 'Agua', 'category': 'Hidratación', 'latestProgress': 0},
      {'title': 'Fruta', 'category': 'Alimentación'},
    ]);
    expect(summary.favoriteTitle, isNull);
    expect(summary.topCategory, isNull);
    expect(summary.registeredCount, 0);
  });

  test('ignora progreso negativo y decide empates de modo consistente', () {
    final summary = ProfileHabitInsights.fromDocuments([
      {'title': 'Zeta', 'category': 'Bienestar', 'latestProgress': 5},
      {'title': 'Alfa', 'category': 'Alimentación', 'latestProgress': 5},
      {'title': 'Otra', 'category': 'Hidratación', 'latestProgress': -2},
    ]);
    expect(summary.favoriteTitle, 'Alfa');
    expect(summary.topCategory, 'Alimentación');
    expect(summary.registeredCount, 10);
  });
}
