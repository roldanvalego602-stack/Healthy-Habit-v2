import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/tienda/healthy_leaf_aura.dart';
import 'package:healthy_habit/páginas/tienda/healthy_mascot_outfit.dart';
import 'package:healthy_habit/páginas/tienda/shop_item_artwork.dart';
import 'package:healthy_habit/páginas/tienda/shop_service.dart';
import 'package:healthy_habit/tema/healthy_visual_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('el aura vegetal tiene precio y ranura propios', () {
    final item = shopItemById('leaf_aura');
    expect(item, isNotNull);
    expect(item!.slot, 'aura');
    expect(item.price, 180);
    expect(item.category, 'Especiales');
    expect(isShopItemVisible(item.id), isTrue);
    expect(availableShopItems(null)
        .any((candidate) => candidate.id == item.id), isTrue);
    expect(shopItemById('mint_aura'), isNotNull);
    expect(isShopItemVisible('mint_aura'), isFalse);
  });

  testWidgets('el aura rodea a la mascota y deja su composición intacta',
      (tester) async {
    await HealthyVisualController.instance.select(HealthyVisualMode.lite);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: HealthyMascotOutfit(
          equipped: {'aura': 'leaf_aura', 'cabeza': 'leaf_crown'},
        )),
      ),
    ));
    expect(find.byType(HealthyLeafAura), findsOneWidget);
    expect(find.byKey(const Key('healthy-aura-hojas')), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await HealthyVisualController.instance.select(HealthyVisualMode.normal);
  });

  testWidgets('sin equipar el aura no se dibuja el efecto',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: HealthyMascotOutfit(equipped: {})),
    ));
    expect(find.byType(HealthyLeafAura), findsNothing);
    expect(find.byKey(const Key('healthy-aura-hojas')), findsNothing);
  });

  testWidgets('la miniatura se pinta con Flutter sin archivos externos',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ShopItemArtwork(
        item: shopItemById('leaf_aura')!,
      )),
    ));
    expect(find.byType(HealthyLeafAuraThumbnail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
