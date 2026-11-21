import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/habitos/habit_interaction_card.dart';

/// Reproduce el montaje/desmontaje del componente usado en el registro
/// guiado, sin necesitar autenticación ni escribir datos de producción.
class _StepHarness extends StatefulWidget {
  const _StepHarness({this.type = 'counter', this.unit = 'repeticiones',
    this.target = 3});
  final String type;
  final String unit;
  final int target;

  @override
  State<_StepHarness> createState() => _StepHarnessState();
}

class _StepHarnessState extends State<_StepHarness> {
  int step = 0;
  int value = 0;
  bool complete = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(child: Column(
      children: [
        if (step == 0)
          HabitInteractionCard(
            type: widget.type,
            target: widget.target,
            unit: widget.unit,
            initialValue: value,
            onChanged: (done, next) => setState(() {
              value = next;
              complete = done;
            }),
          )
        else
          Text('Paso de nota · acumulado: $value'),
        FilledButton(
          onPressed: () => setState(() => step = step == 0 ? 1 : 0),
          child: Text(step == 0 ? 'Continuar' : 'Volver'),
        ),
        Text('Progreso persistente: $value · completo: $complete'),
      ],
    )),
  );
}

void main() {
  testWidgets('el contador no pierde unidades al avanzar y regresar',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _StepHarness()));
    expect(find.text('0 / 3'), findsOneWidget);

    await tester.tap(find.text('Registrar repeticiones'));
    await tester.pump();
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Paso de nota · acumulado: 1'), findsOneWidget);

    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.tap(find.text('Registrar repeticiones'));
    await tester.pump();
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('un valor completo se restaura como completado',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _StepHarness(
      type: 'counter', unit: 'ml', target: 250,
    )));
    await tester.tap(find.text('+250 ml'));
    await tester.pump();
    expect(find.text('250 / 250'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();

    expect(find.text('250 / 250'), findsOneWidget);
    expect(find.text('Objetivo alcanzado'), findsNothing);
    expect(find.text('¡Actividad lista! Guarda tu registro.'),
      findsOneWidget);
  });

  testWidgets('un temporizador recupera los segundos ya acumulados',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _StepHarness(
      type: 'timer', unit: 'segundos', target: 60,
    )));
    // La reconstrucción del widget recibe el valor acumulado.
    // Se simula un avance previo estable sin depender de reloj real.
    final state = tester.state<_StepHarnessState>(
        find.byType(_StepHarness));
    state.setState(() => state.value = 15);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('00:45'), findsOneWidget);
  });
}
