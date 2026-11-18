import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/perfil/social_action_button.dart';

void main() {
  testWidgets('seguir responde al toque y no dispara cuando hay carga', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SocialActionButton(
            label: 'Seguir',
            icon: Icons.person_add,
            onPressed: () => taps++,
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Seguir'));
    await tester.pumpAndSettle();
    expect(taps, 1);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SocialActionButton(
            label: 'Seguir',
            busy: true,
            onPressed: () => taps++,
          ),
        ),
      ),
    ));
    // El CircularProgressIndicator es infinito: pumpAndSettle no terminaría.
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const ValueKey('busy')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('busy')));
    await tester.pump();
    expect(taps, 1);
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('estado cambia cuando actualiza el servidor', (tester) async {
    String label = 'Seguir';
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(builder: (context, setState) {
          update = setState;
          return Center(
            child: SocialActionButton(
              label: label,
              outlined: label == 'Siguiendo',
              onPressed: () {},
            ),
          );
        }),
      ),
    ));
    expect(find.text('Seguir'), findsOneWidget);
    update(() => label = 'Siguiendo');
    await tester.pumpAndSettle();
    expect(find.text('Siguiendo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('botón cabe en una pantalla de 320 px con texto ampliado',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.5),
          ),
          child: Center(
            child: SizedBox(
              width: 120,
              child: SocialActionButton(
                label: 'Agregar amigo',
                compact: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
