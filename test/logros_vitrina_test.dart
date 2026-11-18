import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/logros/logros_vitrina.dart';
import 'package:healthy_habit/páginas/logros/logros_service.dart';

void main() {
  testWidgets('vitrina contiene cinco categorías y no desborda a 320px',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: TickerMode(
          enabled: false,
          child: VitrinaRarezas(),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byKey(const Key('vitrina-rarezas')), findsOneWidget);
    // Scroll para comprobar también las categorías fuera de pantalla.
    for (final tier in RarezaLogro.values) {
      await tester.scrollUntilVisible(find.text(tier.etiqueta), 180,
        scrollable: find.byType(Scrollable).first);
      expect(find.text(tier.etiqueta), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
