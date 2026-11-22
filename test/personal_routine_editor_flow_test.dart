import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/habitos/personal_routines_screen.dart';

class _EditorLauncher extends StatefulWidget {
  const _EditorLauncher();
  @override
  State<_EditorLauncher> createState() => _EditorLauncherState();
}

class _EditorLauncherState extends State<_EditorLauncher> {
  PersonalRoutine? saved;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(children: [
      FilledButton(
        onPressed: () async {
          final routine = await Navigator.push<PersonalRoutine>(
            context,
            MaterialPageRoute(
              builder: (_) => const PersonalRoutineEditor(),
            ),
          );
          if (mounted) setState(() => saved = routine);
        },
        child: const Text('Abrir editor'),
      ),
      if (saved != null)
        Text('Guardado: ${saved!.title} / ${saved!.steps.length} pasos'),
    ]),
  );
}

Future<void> _ensure(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 160,
    scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('permite agregar varios ejercicios antes de guardar',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _EditorLauncher()));
    await tester.tap(find.text('Abrir editor'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('personal-routine-name')),
      'Entrenamiento completo',
    );

    await _ensure(tester, find.byKey(
      const ValueKey('routine-new-exercise')));
    await tester.enterText(
      find.byKey(const ValueKey('routine-new-exercise')), 'Sentadillas');
    await _ensure(tester, find.text('Añadir ejercicio a la rutina'));
    await tester.tap(find.text('Añadir ejercicio a la rutina'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-step-added-feedback')),
      findsOneWidget);
    // La confirmación es texto dentro del formulario: no tapa Guardar.
    expect(find.byType(SnackBar), findsNothing);

    await _ensure(tester, find.byKey(
      const ValueKey('routine-new-exercise')));
    await tester.enterText(
      find.byKey(const ValueKey('routine-new-exercise')), 'Flexiones');
    await _ensure(tester, find.text('Añadir ejercicio a la rutina'));
    await tester.tap(find.text('Añadir ejercicio a la rutina'));
    await tester.pumpAndSettle();

    await _ensure(tester,
      find.byKey(const ValueKey('personal-routine-save')));
    await tester.tap(find.byKey(const ValueKey('personal-routine-save')));
    await tester.pumpAndSettle();

    final state = tester.state<_EditorLauncherState>(
      find.byType(_EditorLauncher));
    expect(state.saved?.steps.map((e) => e.title).toList(),
      ['Sentadillas', 'Flexiones']);
    expect(find.text('Guardado: Entrenamiento completo / 2 pasos'),
      findsOneWidget);
  });

  testWidgets('guardar incluye un ejercicio que quedó escrito',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _EditorLauncher()));
    await tester.tap(find.text('Abrir editor'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('personal-routine-name')), 'Rutina rápida');
    await _ensure(tester,
      find.byKey(const ValueKey('routine-new-exercise')));
    await tester.enterText(
      find.byKey(const ValueKey('routine-new-exercise')), 'Caminata');

    await _ensure(tester,
      find.byKey(const ValueKey('personal-routine-save')));
    await tester.tap(find.byKey(const ValueKey('personal-routine-save')));
    await tester.pumpAndSettle();

    final state = tester.state<_EditorLauncherState>(
      find.byType(_EditorLauncher));
    expect(state.saved?.steps.length, 1);
    expect(state.saved?.steps.first.title, 'Caminata');
  });
}
