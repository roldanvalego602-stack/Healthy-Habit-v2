import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/habitos/habitos_pareja_servicio.dart';
import 'package:healthy_habit/páginas/habitos/habit_action_service.dart';
import 'package:healthy_habit/páginas/habitos/catalogo.dart';

void main() {
  test('las invitaciones por pareja y hábito tienen IDs estables', () {
    final a = HabitosParejaServicio.idPara('alice', 'bob', 'agua');
    final b = HabitosParejaServicio.idPara('alice', 'bob', 'agua');
    final reversed = HabitosParejaServicio.idPara('bob', 'alice', 'agua');
    final other = HabitosParejaServicio.idPara('alice', 'bob', 'caminar');
    expect(a, b);
    expect(reversed, isNot(a));
    expect(other, isNot(a));
  });

  test('el catálogo oficial permite recuperar el hábito antes de invitar', () {
    final first = habitCatalog.first;
    final id = first['id'] as String;
    final habit = HabitActionService.findCatalogHabit(id);
    expect(habit, isNotNull);
    expect(habit!.id, id);
    expect(habit.title, first['title']);
    expect(HabitActionService.findCatalogHabit('habit_invalid_123'), isNull);
  });
}
