import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/healthy_chat_habit_card.dart';
import 'package:healthy_habit/páginas/habitos/habit_action_service.dart';
import 'package:healthy_habit/tema/healthy_visual_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final habit = HabitActionService.findCatalogHabit('alim_001')!;

  HabitActionPreview preview({bool remove = false}) => HabitActionPreview(
    userId: 'test-user',
    habit: habit,
    remove: remove,
    attemptId: remove ? 'attempt-1' : null,
    activeCount: remove ? 1 : 0,
    activeIds: remove ? {'alim_001'} : <String>{},
    slots: 3,
    xp: 100,
    coins: 90,
    mutationVersion: 0,
    estimatedCost: 0,
  );

  testWidgets('No ejecuta ninguna operación hasta confirmar',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
    var executed = 0;
    var completed = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: HealthyChatHabitCard(
        habitTitle: habit.title,
        remove: false,
        previewResolver: (_, _) async => preview(),
        executor: (_) async {
          executed++;
          return HabitActionResult(
            habit: habit, removed: false, chargedCoins: 0);
        },
        onCompleted: (_) => completed++,
      )),
    ));
    await tester.pumpAndSettle();
    expect(executed, 0);
    expect(find.byKey(const Key('mr-healthy-habit-ready')), findsOneWidget);
    await tester.tap(find.byKey(const Key('mr-healthy-habit-review')));
    await tester.pumpAndSettle();
    expect(executed, 0);
    expect(find.text('¿Agregar hábito?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(executed, 0);
    expect(completed, 0);
    await tester.tap(find.byKey(const Key('mr-healthy-habit-review')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mr-healthy-confirm-habit')));
    await tester.pumpAndSettle();
    expect(executed, 1);
    expect(completed, 1);
    expect(find.byKey(const ValueKey('mr-healthy-habit-success')),
      findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lite presenta confirmación y resultado sin animaciones',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.lite);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: HealthyChatHabitCard(
        habitTitle: habit.title,
        remove: true,
        previewResolver: (_, _) async => preview(remove: true),
        executor: (_) async => HabitActionResult(
          habit: habit, removed: true, chargedCoins: 0),
        onCompleted: (_) {},
      )),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mr-healthy-habit-review')));
    await tester.pumpAndSettle();
    expect(find.textContaining('historial'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mr-healthy-confirm-habit')));
    await tester.pumpAndSettle();
    expect(find.text('Hábito abandonado'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
  });
}
