import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/tema/cosmos_theme.dart';
import 'package:healthy_habit/tema/healthy_theme.dart';
import 'package:healthy_habit/páginas/tienda/shop_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    HealthyThemeController.instance.syncCosmos(
      owned: false, equipped: false);
  });

  test('Cosmos solo se activa si fue comprado y equipado', () {
    final controller = HealthyThemeController.instance;

    controller.syncCosmos(owned: false, equipped: true);
    expect(controller.cosmosActive, isFalse);

    controller.syncCosmos(owned: true, equipped: false);
    expect(controller.cosmosActive, isFalse);

    controller.syncCosmos(owned: true, equipped: true);
    expect(controller.cosmosActive, isTrue);
    expect(HealthyAdaptive.isCosmos, isTrue);
    expect(HealthyAdaptive.accent, CosmosPalette.primary);

    controller.syncCosmos(owned: false, equipped: false);
    expect(controller.cosmosActive, isFalse);
  });

  test('producto Cosmos tiene precio y ranura de tema', () {
    final item = shopItemById(cosmosShopId)!;
    expect(item.price, 1800);
    expect(item.slot, cosmosSlot);
    expect(item.category, 'Temas');
  });

  test('el estado de tienda utiliza propiedad real', () {
    final empty = ShopState.fromMap(const {});
    expect(empty.owns(cosmosShopId), isFalse);

    final owned = ShopState.fromMap(const {
      'shopInventory': ['theme_cosmos'],
      'shopEquipped': {'app_theme': 'theme_cosmos'},
    });
    expect(owned.owns(cosmosShopId), isTrue);
    expect(owned.equipped[cosmosSlot], cosmosShopId);
  });

  testWidgets('la barra Cosmos muestra el porcentaje real y respeta límites',
      (tester) async {
    HealthyThemeController.instance.syncCosmos(
      owned: true, equipped: true);
    await tester.pumpWidget(MaterialApp(
      theme: HealthyThemes.dark(),
      home: const Scaffold(
        body: Center(child: SizedBox(
          width: 240,
          child: CosmosEnergyBar(value: .42, height: 11),
        )),
      ),
    ));
    expect(find.byType(CosmosEnergyBar), findsOneWidget);
    expect(find.bySemanticsLabel('Progreso'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cosmos reduce animaciones cuando el sistema las desactiva',
      (tester) async {
    HealthyThemeController.instance.syncCosmos(
      owned: true, equipped: true);
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(
        theme: HealthyThemes.dark(),
        home: const Scaffold(body: Center(
          child: SizedBox(width: 240, height: 160,
            child: CosmosCardShell(child: Text('Cosmos Lite'))),
        )),
      ),
    ));
    expect(find.text('Cosmos Lite'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('los adornos solo se activan con Cosmos', (tester) async {
    final controller = HealthyThemeController.instance;
    controller.syncCosmos(owned: true, equipped: true);
    await tester.pumpWidget(MaterialApp(
      theme: HealthyThemes.light(),
      home: const Scaffold(
        body: CosmosCardShell(child: Text('Prueba Cosmos')),
      ),
    ));
    expect(find.text('Prueba Cosmos'), findsOneWidget);
    expect(tester.takeException(), isNull);
    controller.syncCosmos(owned: false, equipped: false);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
