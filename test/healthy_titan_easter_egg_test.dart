import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/tienda/shop_service.dart';
import 'package:healthy_habit/páginas/tienda/shop_item_artwork.dart';
import 'package:healthy_habit/páginas/tienda/healthy_titan_skin.dart';
import 'package:healthy_habit/páginas/tienda/wardrobe_screen.dart';

void main() {
  test('Titán no se regala por tener precio cero', () {
    final empty = ShopState.fromMap(const {
      'habitCoins': 250,
      'shopInventory': <String>[],
      'shopEquipped': <String, String>{},
    });
    expect(empty.owns('skin_titan_secret'), isFalse);
    expect(empty.owns('sunglasses'), isTrue);
    expect(availableShopItems(empty).any(
      (item) => item.id == 'skin_titan_secret'), isFalse);
  });

  test('desbloqueada, Titán está disponible en el Armario', () {
    final state = ShopState.fromMap(const {
      'shopInventory': <String>['skin_titan_secret'],
      'shopEquipped': <String, String>{
        'skin': 'skin_titan_secret',
      },
    });
    expect(state.owns('skin_titan_secret'), isTrue);
    expect(state.equippedItem('skin_titan_secret'), isTrue);
    expect(wardrobeItemsForSlot('skin').any(
      (item) => item.id == 'skin_titan_secret'), isTrue);
    expect(shopItemById('skin_titan_secret')?.slot, 'skin');
  });

  testWidgets('el arte de Titán se muestra sin archivos de imagen externos',
      (tester) async {
    final item = shopItemById('skin_titan_secret')!;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(
        child: ShopItemArtwork(item: item, size: 100),
      )),
    ));
    expect(find.byType(HealthyTitanSkin), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la ilustración escala en tamaños pequeños y grandes',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Column(children: [
        HealthyTitanSkin(size: 60),
        HealthyTitanSkin(size: 180),
      ])),
    ));
    expect(find.byType(HealthyTitanSkin), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
