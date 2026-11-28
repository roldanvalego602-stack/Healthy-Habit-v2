import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/tienda/healthy_titan_cave_screen.dart';

void main() {
  testWidgets('las inscripciones revelan pistas en orden sin regalar skin',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HealthyTitanCaveScreen(testRequest: (data) async =>
        <String, dynamic>{'status':'ready','remaining':5}),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('ALGO RESPIRA'), findsOneWidget);
    expect(find.textContaining('No nazco de un solo esfuerzo'),
      findsNothing);
    await tester.tap(find.text('Descifrar primera pista'));
    await tester.pump();
    expect(find.textContaining('No nazco de un solo esfuerzo'),
      findsOneWidget);
    expect(find.text('LIBERADO'), findsNothing);
    expect(find.textContaining('Intentos disponibles hoy: 5'),
      findsOneWidget);
  });

  testWidgets('la celda se abre solo con aprobación del servidor',
      (tester) async {
    var tries = 0;
    await tester.pumpWidget(MaterialApp(
      home: HealthyTitanCaveScreen(testRequest: (data) async {
        if (data['action'] == 'status') {
          return <String,dynamic>{'status':'ready','remaining':5};
        }
        tries++;
        return tries == 1
          ? <String,dynamic>{'status':'incorrect','remaining':4,
              'awarded':false}
          : <String,dynamic>{'status':'unlocked','remaining':3,
              'awarded':true,'skinId':'skin_titan_secret'};
      }),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.ensureVisible(find.byKey(const Key('titan-respuesta')));
    await tester.enterText(find.byKey(const Key('titan-respuesta')), 'incorrecta');
    await tester.ensureVisible(find.byKey(const Key('titan-validar')));
    await tester.tap(find.byKey(const Key('titan-validar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('LIBERADO'), findsNothing);
    expect(find.textContaining('Intentos disponibles hoy: 4'),
      findsOneWidget);

    await tester.enterText(find.byKey(const Key('titan-respuesta')), 'respuesta');
    await tester.ensureVisible(find.byKey(const Key('titan-validar')));
    await tester.tap(find.byKey(const Key('titan-validar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));

    expect(find.text('LIBERADO'), findsOneWidget);
    expect(find.textContaining('se añadió a tu armario'), findsOneWidget);
    expect(find.byKey(const Key('titan-validar')), findsNothing);
    expect(tries, 2);
  });
}
