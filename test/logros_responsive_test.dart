import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/logros/logros_screen.dart';
import 'package:healthy_habit/páginas/logros/logros_service.dart';

void main() {
  final items = <LogroVista>[
    const LogroVista(
      definicion: LogroDefinicion(
        id: 'done', nombre: 'Primer paso', descripcion: 'Registra tu primer hábito',
        meta: 1, tipo: 'primer', icono: Icons.flag_rounded,
      ),
      progreso: 1,
    ),
    const LogroVista(
      definicion: LogroDefinicion(
        id: 'pending',
        nombre: 'Un nombre de logro bastante largo que debe ocupar varias líneas',
        descripcion: 'Una descripción extensa para comprobar que los textos crecen '
          'dentro de la tarjeta y no quedan cortados en pantallas pequeñas.',
        meta: 30, tipo: 'racha', icono: Icons.local_fire_department_rounded,
      ),
      progreso: 4,
    ),
  ];

  Future<void> show(WidgetTester tester, Size size, double scale) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
          child: LogrosColeccion(items: items),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('320 px con texto 1.4: sin overflow y con dos logros',
      (tester) async {
    await show(tester, const Size(320, 640), 1.4);
    expect(find.byKey(const Key('logros-resumen')), findsOneWidget);
    expect(find.byKey(const ValueKey('logro-done')), findsOneWidget);
    expect(find.byKey(const ValueKey('logro-pending')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filtros cambian entre conseguidos y pendientes',
      (tester) async {
    await show(tester, const Size(360, 720), 1.0);
    await tester.tap(find.text('Conseguidos'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('logro-done')), findsOneWidget);
    expect(find.byKey(const ValueKey('logro-pending')), findsNothing);
    await tester.tap(find.text('Pendientes'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('logro-done')), findsNothing);
    expect(find.byKey(const ValueKey('logro-pending')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('colección vacía no divide por cero',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: LogrosColeccion(items: [])),
    ));
    await tester.pumpAndSettle();
    expect(find.text('0 / 0'), findsOneWidget);
    expect(find.text('Todavía no hay logros en esta sección.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
