import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/tienda/shop_service.dart';
import 'package:healthy_habit/páginas/tienda/store_featured_carousel.dart';
import 'package:healthy_habit/tema/healthy_theme.dart';
import 'package:healthy_habit/tema/healthy_visual_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const featured = <ShopItem>[
    ShopItem('crown', 'Corona de bronce', 'Cabeza',
        'Para una racha legendaria.', 180, emoji: '👑'),
    ShopItem('mint_aura', 'Aura menta', 'Especiales',
        'Brillo suave alrededor de la mascota.', 120, emoji: '✨'),
    ShopItem('elite_avatar', 'Avatar Élite', 'Avatares',
        'Identidad exclusiva para tu perfil.', 140, emoji: '🌟'),
  ];

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpFeatured(WidgetTester tester, {
    required ThemeMode themeMode,
    required HealthyVisualMode visualMode,
    Size size = const Size(320, 700),
    ValueChanged<ShopItem>? onSelected,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await HealthyVisualController.instance.select(visualMode);
    await tester.pumpWidget(MaterialApp(
      theme: HealthyThemes.light(),
      darkTheme: HealthyThemes.dark(),
      themeMode: themeMode,
      home: Scaffold(
        body: ListView(
          children: [
            StoreFeaturedCarousel(
              items: featured,
              shopState: const ShopState(
                coins: 150,
                owned: <String>{},
                equipped: <String, String>{},
              ),
              onSelected: onSelected ?? (_) {},
            ),
          ],
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 900));
  }

  testWidgets('carrusel en móvil estrecho abre el producto real',
      (tester) async {
    ShopItem? selection;
    await pumpFeatured(tester,
      themeMode: ThemeMode.dark,
      visualMode: HealthyVisualMode.normal,
      onSelected: (item) => selection = item,
    );
    expect(find.text('Artículos destacados'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('destacado-crown')));
    expect(selection?.id, 'crown');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lite permite navegar sin animación de página',
      (tester) async {
    await pumpFeatured(tester,
      themeMode: ThemeMode.light,
      visualMode: HealthyVisualMode.lite,
    );
    await tester.tap(find.byTooltip('Artículo siguiente'));
    await tester.pump();
    expect(find.text('Aura menta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('los artículos destacados existen en el catálogo oficial',
      (tester) async {
    for (final id in featuredShopItemIds) {
      expect(shopItemById(id), isNotNull);
    }
  });

  testWidgets('no se produce overflow a 360dp en tema oscuro',
      (tester) async {
    await pumpFeatured(tester,
      themeMode: ThemeMode.dark,
      visualMode: HealthyVisualMode.normal,
      size: const Size(360, 740),
    );
    await tester.drag(
      find.byKey(const Key('tienda-carrusel-destacados')),
      const Offset(-260, 0),
    );
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });
}
