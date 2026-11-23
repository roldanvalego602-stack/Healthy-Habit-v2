import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/estadisticas/daily_streak_reward_dialog.dart';

void main() {
  Future<void> openDialog(
    WidgetTester tester, {
    required Future<Map<String, dynamic>> Function() claim,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) => ElevatedButton(
          onPressed: () => showDialog<StreakRewardAction>(
            context: context,
            builder: (_) => DailyStreakRewardDialog(
              streak: 3,
              coins: 3,
              xp: 10,
              onClaim: claim,
            ),
          ),
          child: const Text('Registrar sesión'),
        )),
      ),
    ));
    await tester.tap(find.text('Registrar sesión'));
    await tester.pumpAndSettle();
  }

  testWidgets('primera sesión permite cobrar desde la ventana',
      (tester) async {
    var requests = 0;
    await openDialog(tester, claim: () async {
      requests++;
      return {'alreadyClaimed': false, 'coinsAwarded': 3};
    });
    expect(find.text('¡Día 3 de racha!'), findsOneWidget);
    expect(find.text('+3 Habit Coins'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('streak-collect-now')));
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.text('¡Día 3 de racha!'), findsNothing);
  });

  testWidgets('más tarde conserva el premio sin reclamación',
      (tester) async {
    var requests = 0;
    await openDialog(tester, claim: () async {
      requests++;
      return {'coinsAwarded': 3};
    });
    await tester.tap(find.text('Más tarde'));
    await tester.pumpAndSettle();
    expect(requests, 0);
    expect(find.text('¡Día 3 de racha!'), findsNothing);
  });

  testWidgets('fallo de conexión mantiene abierto el diálogo',
      (tester) async {
    await openDialog(tester, claim: () async {
      throw StateError('network error');
    });
    await tester.tap(find.byKey(const ValueKey('streak-collect-now')));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo confirmar el reclamo'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('streak-collect-now')), findsOneWidget);
  });

  testWidgets('cobro ya realizado permite cerrar sin pagar dos veces',
      (tester) async {
    await openDialog(tester, claim: () async =>
        {'alreadyClaimed': true, 'coinsAwarded': 0});
    await tester.tap(find.byKey(const ValueKey('streak-collect-now')));
    await tester.pumpAndSettle();
    expect(find.text('¡Día 3 de racha!'), findsNothing);
  });
}
