import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/healthy_chat_progress_cards.dart';
import 'package:healthy_habit/páginas/chatbot/healthy_chat_store_card.dart';
import 'package:healthy_habit/páginas/tienda/shop_service.dart';
import 'package:healthy_habit/tema/healthy_visual_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('barra animada termina en progreso real sin cambiarlo',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SizedBox(width: 290,
        child: HealthyChatProgressTile(
          title: 'Misión de prueba',
          progress: .6,
          description: '3 de 5',
        ))),
    ));
    await tester.pump(const Duration(milliseconds: 650));
    final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator));
    expect(bar.value, closeTo(.6, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lite muestra progreso final inmediatamente',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.lite);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: HealthyChatProgressTile(
        title: 'Misión Lite',
        progress: .4,
        description: '2 de 5',
      )),
    ));
    await tester.pumpAndSettle();
    expect(tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator)).value, .4);
    expect(tester.takeException(), isNull);
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
  });

  testWidgets('comprar requiere confirmación y cancelar no cobra',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
    var operations = 0;
    var committed = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SizedBox(width: 320,
        child: HealthyChatStoreCard(
          initialItemId: 'crown',
          stateStream: Stream.value(const ShopState(
            coins: 220,
            owned: <String>{},
            equipped: <String, String>{},
          )),
          purchaseAction: (_) async { operations++; },
          onCommitted: (_) { committed++; },
        ))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Corona de bronce'), findsOneWidget);
    expect(operations, 0);
    await tester.tap(find.byKey(const Key('chat-shop-purchase')));
    await tester.pumpAndSettle();
    expect(operations, 0);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(operations, 0);
    await tester.tap(find.byKey(const Key('chat-shop-purchase')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-store-confirm')));
    await tester.pumpAndSettle();
    expect(operations, 1);
    expect(committed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lite permite equipar propiedad real con confirmación',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.lite);
    var equipCalls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SizedBox(width: 320,
        child: HealthyChatStoreCard(
          initialItemId: 'crown',
          stateStream: Stream.value(const ShopState(
            coins: 15,
            owned: <String>{'crown'},
            equipped: <String, String>{},
          )),
          equipAction: (_, {required bool remove}) async {
            expect(remove, false);
            equipCalls++;
          },
          onCommitted: (_) {},
        ))),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-shop-equip')));
    await tester.pumpAndSettle();
    expect(equipCalls, 0);
    await tester.tap(find.byKey(const Key('chat-store-confirm')));
    await tester.pumpAndSettle();
    expect(equipCalls, 1);
    expect(tester.takeException(), isNull);
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
  });
}
