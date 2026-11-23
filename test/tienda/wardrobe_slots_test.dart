import 'package:flutter_test/flutter_test.dart';
import '../../lib/páginas/tienda/wardrobe_screen.dart';
import '../../lib/páginas/tienda/shop_service.dart';

void main() {
  test('el editor separa ranuras de mascota y de perfil', () {
    final mascota = mascotWardrobeSlots.map((slot) => slot.id).toSet();
    final perfil = profileWardrobeSlots.map((slot) => slot.id).toSet();

    expect(mascota.contains('cabeza'), isTrue);
    expect(mascota.contains('torso'), isTrue);
    expect(mascota.contains('pies'), isTrue);
    expect(mascota.contains('skin'), isTrue);
    expect(perfil, containsAll(['perfil_avatar', 'perfil_marco',
      'perfil_banner', 'perfil_expositor']));
    expect(mascota.intersection(perfil), isEmpty);
    expect(mascota.length, mascotWardrobeSlots.length);
    expect(perfil.length, profileWardrobeSlots.length);
  });

  test('la selección por icono muestra solo piezas de esa ranura', () {
    for (final slot in [...mascotWardrobeSlots, ...profileWardrobeSlots]) {
      for (final item in wardrobeItemsForSlot(slot.id)) {
        expect(item.slot, slot.id);
      }
    }
    expect(wardrobeItemsForSlot('cabeza')
        .any((item) => item.id == 'leaf_crown'), isTrue);
    expect(wardrobeItemsForSlot('perfil_banner')
        .any((item) => item.id == 'banner_gradient_black_blue'), isTrue);
    expect(wardrobeItemsForSlot('piel-inexistente'), isEmpty);
    expect(wardrobeItemsForSlot('pies'), isEmpty);
  });

  test('los artículos sin ranura no se presentan como vestimenta', () {
    final visible = <String>{
      for (final slot in [...mascotWardrobeSlots, ...profileWardrobeSlots])
        ...wardrobeItemsForSlot(slot.id).map((item) => item.id),
    };
    expect(visible.contains('reaction_like'), isFalse);
    expect(visible.contains('streak_guard'), isFalse);
    expect(visible.contains('leaf_crown'), isTrue);
    expect(shopItemById('reaction_like'), isNotNull);
  });

  test('artículo adquirido se puede equipar sin modificar el inventario', () {
    final state = ShopState(
      coins: 50,
      owned: {'leaf_crown'},
      equipped: {'cabeza': 'leaf_crown'},
    );
    expect(state.owns('leaf_crown'), isTrue);
    expect(state.equipped['cabeza'], 'leaf_crown');
    expect(state.owns('space_helmet'), isFalse);
  });
}
