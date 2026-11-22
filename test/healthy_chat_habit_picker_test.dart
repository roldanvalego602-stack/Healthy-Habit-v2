import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/healthy_chat_habit_picker.dart';
import 'package:healthy_habit/páginas/habitos/modelo/habit.dart';
import 'package:healthy_habit/tema/healthy_visual_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('seleccionar un hábito no ejecuta ninguna transacción',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.lite);
    Habit? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Builder(builder: (context) =>
        TextButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => HealthyChatHabitPicker(
              remove: false,
              onSelected: (habit) => selected = habit,
            ),
          ),
          child: const Text('Elegir'),
        ),
      )),
    ));
    await tester.tap(find.text('Elegir'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mr-healthy-picker-alim_001')),
      findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mr-healthy-picker-alim_001')));
    await tester.pumpAndSettle();
    expect(selected?.id, 'alim_001');
    expect(tester.takeException(), isNull);
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
  });
}
