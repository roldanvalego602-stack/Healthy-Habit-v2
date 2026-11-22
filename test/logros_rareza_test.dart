import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/logros/logro_insignia.dart';
import 'package:healthy_habit/páginas/logros/logros_service.dart';

void main() {
  test('12 logros existentes tienen rarezas válidas y están repartidos', () {
    expect(LogrosService.catalogo.length, 12);
    final rarezas = LogrosService.catalogo.map((x) => x.rareza).toSet();
    expect(rarezas, RarezaLogro.values.toSet());
    expect(
      LogrosService.catalogo.firstWhere((x) => x.id == 'racha_30').rareza,
      RarezaLogro.legendario,
    );
    expect(
      LogrosService.catalogo.firstWhere((x) => x.id == 'primer_paso').rareza,
      RarezaLogro.frecuente,
    );
  });

  testWidgets('dibuja cada rareza sin overflow a 320 px, texto grande',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TickerMode(enabled: false, child: ListView(
          children: [
            for (final tier in RarezaLogro.values)
              Row(children: [
                LogroInsignia(
                  key: ValueKey(tier),
                  rareza: tier,
                  icono: Icons.emoji_events,
                  desbloqueado: true,
                ),
                Expanded(child: Text(tier.etiqueta)),
              ]),
          ],
        )),
      ),
    ));
    await tester.pump();
    for (final tier in RarezaLogro.values) {
      expect(find.byKey(ValueKey(tier)), findsOneWidget);
      expect(find.text(tier.etiqueta), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('se detiene la animación al bloquear un logro',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: LogroInsignia(
        rareza: RarezaLogro.legendario,
        icono: Icons.military_tech,
        desbloqueado: true,
      )),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: LogroInsignia(
        rareza: RarezaLogro.legendario,
        icono: Icons.military_tech,
        desbloqueado: false,
      )),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
