import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthy_habit/páginas/habitos/habit_add_sheet.dart';
import 'package:healthy_habit/páginas/habitos/catalogo.dart';
import 'package:healthy_habit/páginas/habitos/modelo/habit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Habit firstHabit() {
    final raw = Map<String, dynamic>.from(habitCatalog.first);
    return Habit.fromMap(raw, raw['id'] as String);
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('un único paso de activación devuelve una herramienta válida',
      (tester) async {
    Map<String, dynamic>? chosen;
    final habit = firstHabit();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: Builder(
        builder: (context) => FilledButton(
          onPressed: () async {
            chosen = await HabitAddSheet.open(context, habit, 0);
          },
          child: const Text('Abrir ficha'),
        ),
      ))),
    ));
    await tester.tap(find.text('Abrir ficha'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('habit-add-tool')), findsOneWidget);
    expect(find.byKey(const ValueKey('confirm-official-habit')), findsOneWidget);
    expect(chosen, isNull);
    await tester.tap(find.byKey(const ValueKey('confirm-official-habit')));
    await tester.pumpAndSettle();
    expect(chosen, {'type': 'manual', 'target': 1, 'unit': 'vez'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('explicación puede ocultarse sin confirmar un hábito',
      (tester) async {
    final habit = firstHabit();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Builder(
        builder: (context) => FilledButton(
          onPressed: () => HabitAddSheet.open(context, habit, 0),
          child: const Text('Abrir ficha'),
        ),
      )),
    ));
    await tester.tap(find.text('Abrir ficha'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('habit-rewards-envelope')), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('habit-rewards-envelope')), findsNothing);
    expect(find.byKey(const ValueKey('confirm-official-habit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
