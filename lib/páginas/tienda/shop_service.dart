import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'shop_purchase_gateway.dart';
import 'beta_shop_purchase_gateway.dart';
import '../../servicios/beta_habit_gateway.dart';

class ShopItem {
  const ShopItem(
    this.id,
    this.name,
    this.category,
    this.description,
    this.price, {
    this.emoji = '🎁',
    this.slot,
  });
  final String id, name, category, description, emoji;
  final int price;
  final String? slot;
}

const shopCatalog = <ShopItem>[
  ShopItem(
    'avatar_frame',
    'Marco de avatar',
    'Avatares',
    'Borde esmeralda para tu perfil.',
    120,
    emoji: '🖼️',
    slot: 'perfil_marco',
  ),
  ShopItem(
    'banner',
    'Banner',
    'Personalización',
    'Un banner especial para tu perfil.',
    120,
    emoji: '🎨',
    slot: 'perfil_banner',
  ),
  ShopItem(
    'streak_guard',
    'Protector de racha',
    'Extras',
    'Protección consumible para una ausencia; requiere integración con el registro de rachas.',
    300,
    emoji: '🛡️',
  ),
  ShopItem(
    'achievement_display',
    'Expositor de logros',
    'Personalización',
    'Personalización del perfil.',
    200,
    emoji: '🏆',
    slot: 'perfil_expositor',
  ),
  ShopItem(
    'elite_avatar',
    'Avatar Élite',
    'Avatares',
    'Identidad exclusiva para tu perfil.',
    140,
    emoji: '🌟',
    slot: 'perfil_avatar',
  ),
  ShopItem(
    'mint_scarf',
    'Pañuelo Menta',
    'Ropa',
    'Accesorio para Mr. Healthy.',
    180,
    emoji: '🧣',
    slot: 'cuello',
  ),
  ShopItem(
    'sunglasses',
    'Lentes sol',
    'Accesorios',
    'Un clásico para Mr. Healthy.',
    0,
    emoji: '🕶️',
    slot: 'ojos',
  ),
  ShopItem(
    'bandana',
    'Bufanda',
    'Ropa',
    'Un toque aventurero.',
    0,
    emoji: '🧣',
    slot: 'cuello',
  ),
  ShopItem(
    'cap',
    'Gorra urbana',
    'Cabeza',
    'Estilo relajado.',
    100,
    emoji: '🧢',
    slot: 'cabeza',
  ),
  ShopItem(
    'crown',
    'Corona de bronce',
    'Cabeza',
    'Para una racha legendaria.',
    180,
    emoji: '👑',
    slot: 'cabeza',
  ),
  ShopItem(
    'mint_aura',
    'Aura menta',
    'Especiales',
    'Brillo suave alrededor de la mascota.',
    120,
    emoji: '✨',
    slot: 'aura',
  ),
  ShopItem('leaf_aura', 'Aura de hojas', 'Especiales',
      'Hojas flotantes, luz verde y halo vegetal alrededor de Mr. Healthy.',
      180, emoji: '🍃', slot: 'aura'),
  ShopItem('stellar_aura', 'Aura estelar', 'Especiales',
      'Órbita luminosa, estrellas en movimiento y brillo azul violeta.',
      280, emoji: '🌌', slot: 'aura'),
  ShopItem('golden_aura', 'Aura dorada', 'Especiales',
      'Halo dorado, resplandor radiante y laureles de celebración.',
      400, emoji: '🌟', slot: 'aura'),
  ShopItem(
    'cape',
    'Capa de héroe',
    'Ropa',
    'Listo para completar misiones.',
    200,
    emoji: '🦸',
    slot: 'espalda',
  ),
  ShopItem(
    'pixel_glasses',
    'Lentes pixel',
    'Accesorios',
    'Modo gamer activado.',
    80,
    emoji: '🤓',
    slot: 'ojos',
  ),
  ShopItem(
    'cat_ears',
    'Orejas felinas',
    'Cabeza',
    'Una apariencia juguetona.',
    150,
    emoji: '🐱',
    slot: 'cabeza',
  ),
  ShopItem('sports_headband', 'Banda deportiva', 'Cabeza',
      'Banda verde de hojas para Mr. Healthy.', 70,
      emoji: '🌿', slot: 'cabeza'),
  ShopItem('leaf_headphones', 'Audífonos naturaleza', 'Cabeza',
      'Audífonos verde menta con motivos naturales.', 140,
      emoji: '🎧', slot: 'cabeza'),
  ShopItem('leaf_hoodie', 'Sudadera ecológica', 'Ropa',
      'Sudadera verde de Mr. Healthy.', 200,
      emoji: '👕', slot: 'torso'),
  ShopItem('wellness_medal', 'Medalla saludable', 'Accesorios',
      'Medalla de oro por tu constancia.', 100,
      emoji: '🏅', slot: 'cuello'),
  ShopItem('water_bottle', 'Termo turquesa', 'Accesorios',
      'Botella de hidratación reutilizable.', 90,
      emoji: '💧', slot: 'mano'),
  ShopItem('leaf_backpack', 'Mochila ecológica', 'Accesorios',
      'Mochila verde de exploración.', 170,
      emoji: '🎒', slot: 'espalda'),
  ShopItem('cat_headphones_pink', 'Audífonos felinos', 'Cabeza',
      'Audífonos rosas con orejas de gato', 190, emoji: '🎧', slot: 'cabeza'),
  ShopItem('chef_hat_green', 'Gorro de chef', 'Cabeza',
      'Sombrero de chef verde con laureles', 170, emoji: '👨‍🍳', slot: 'cabeza'),
  ShopItem('paper_sailor_hat', 'Sombrero de papel', 'Cabeza',
      'Sombrero de papel con cinta negra', 120, emoji: '⛵', slot: 'cabeza'),
  ShopItem('green_gloves', 'Guantes de hojas', 'Accesorios',
      'Guantes verdes para Mr. Healthy', 140, emoji: '🧤', slot: 'brazos'),
  ShopItem('superhero_cape_red', 'Capa roja de héroe', 'Ropa',
      'Capa roja con medallón dorado', 230, emoji: '🦸', slot: 'espalda'),
  ShopItem('star_backpack_blue', 'Mochila estelar', 'Accesorios',
      'Mochila azul con estrella', 170, emoji: '🎒', slot: 'espalda'),
  ShopItem('rock_face_mask', 'Máscara de piedra', 'Accesorios',
      'Máscara con el rostro de la piedra', 230, emoji: '🎭', slot: 'ojos'),
  ShopItem('space_helmet', 'Casco espacial', 'Cabeza',
      'Casco de exploración espacial', 280, emoji: '🧑‍🚀', slot: 'cabeza'),
  ShopItem('hero_mask_blue', 'Antifaz de héroe', 'Accesorios',
      'Máscara azul de superhéroe', 160, emoji: '🎭', slot: 'ojos'),
  ShopItem('frame_arcane', 'Marco Arcano', 'Marcos',
      'Marco violeta mágico para tu avatar', 300, emoji: '🔮', slot: 'perfil_marco'),
  ShopItem('frame_emerald', 'Marco Esmeralda', 'Marcos',
      'Marco circular verde de hojas', 160, emoji: '🍃', slot: 'perfil_marco'),
  ShopItem('frame_cyber', 'Marco Galáctico', 'Marcos',
      'Marco futurista cian', 350, emoji: '🪐', slot: 'perfil_marco'),
  ShopItem('frame_nature', 'Marco Naturaleza', 'Marcos',
      'Marco verde con gemas doradas', 210, emoji: '🌿', slot: 'perfil_marco'),
  ShopItem('banner_space', 'Horizonte Galáctico', 'Banners',
      'Banner de paisaje espacial', 260, emoji: '🌌', slot: 'perfil_banner'),
  ShopItem('banner_sunset', 'Atardecer Dorado', 'Banners',
      'Banner de atardecer', 130, emoji: '🌅', slot: 'perfil_banner'),
  ShopItem('banner_floral', 'Jardín Floral', 'Banners',
      'Banner de flores y naturaleza', 150, emoji: '🌸', slot: 'perfil_banner'),
  ShopItem('banner_ice', 'Invierno Glacial', 'Banners',
      'Banner de paisaje nevado', 190, emoji: '❄️', slot: 'perfil_banner'),
  ShopItem('avatar_snowman', 'Muñeco de nieve animado', 'Avatares',
      'Avatar navideño animado', 300, emoji: '⛄', slot: 'perfil_avatar'),
  ShopItem('avatar_christmas', 'Avatar navideño', 'Avatares',
      'Avatar de Navidad', 210, emoji: '🎅', slot: 'perfil_avatar'),
  ShopItem('avatar_gingerbread', 'Galleta de jengibre', 'Avatares',
      'Avatar navideño de galleta', 210, emoji: '🍪', slot: 'perfil_avatar'),
  ShopItem('avatar_gift', 'Regalo navideño', 'Avatares',
      'Avatar de regalo de Navidad', 210, emoji: '🎁', slot: 'perfil_avatar'),
  ShopItem('reaction_compas', 'Vamos juntos', 'Reacciones',
      'Sticker para animar a tus amigos', 90, emoji: '🤝'),
  ShopItem('reaction_celebrate', '¡Felicidades!', 'Reacciones',
      'Sticker de celebración', 90, emoji: '🎉'),
  ShopItem('reaction_love', 'Con cariño', 'Reacciones',
      'Sticker de apoyo y cariño', 90, emoji: '❤️'),
  ShopItem('reaction_goal', '¡Meta conseguida!', 'Reacciones',
      'Sticker de progreso', 90, emoji: '⭐'),
  ShopItem('reaction_support', '¡Ánimo!', 'Reacciones',
      'Sticker de motivación', 90, emoji: '👏'),
  ShopItem('reaction_like', '¡Buen trabajo!', 'Reacciones',
      'Sticker de aprobación', 90, emoji: '👍'),
  ShopItem('aviator_goggles_gold', 'Gafas de aviador', 'Cabeza',
      'Gafas de cuero con lentes dorados', 175, emoji: '🥽', slot: 'cabeza'),
  ShopItem('leaf_glow_hat', 'Hoja luminosa', 'Cabeza',
      'Hoja verde con destellos dorados', 145, emoji: '🍃', slot: 'cabeza'),
  ShopItem('leaf_crown', 'Corona de hojas', 'Cabeza',
      'Corona vegetal para Mr. Healthy', 180, emoji: '👑', slot: 'cabeza'),
  ShopItem('skin_christmas_cartoon', 'Skin festiva', 'Skins',
      'Aspecto completo de Mr. Healthy', 420, emoji: '🎄', slot: 'skin'),
  ShopItem('banner_gradient_yellow_pink', 'Degradado amanecer', 'Banners',
      'Amarillo y rosa', 95, emoji: '🌅', slot: 'perfil_banner'),
  ShopItem('banner_gradient_blue_pink', 'Degradado aurora', 'Banners',
      'Azul y rosa', 95, emoji: '🎨', slot: 'perfil_banner'),
  ShopItem('banner_gradient_teal_yellow', 'Degradado vitalidad', 'Banners',
      'Azul verdoso y amarillo', 95, emoji: '✨', slot: 'perfil_banner'),
  ShopItem('banner_gradient_gold_black', 'Degradado nocturno', 'Banners',
      'Dorado y negro', 110, emoji: '🌙', slot: 'perfil_banner'),
  ShopItem('banner_gradient_purple_teal', 'Degradado místico', 'Banners',
      'Morado y azul verdoso', 95, emoji: '🔮', slot: 'perfil_banner'),
  ShopItem('banner_gradient_pink_violet', 'Degradado floral', 'Banners',
      'Rosa y violeta', 95, emoji: '🌸', slot: 'perfil_banner'),
  ShopItem('banner_gradient_turquoise_blue', 'Degradado océano', 'Banners',
      'Turquesa y azul', 95, emoji: '🌊', slot: 'perfil_banner'),
  ShopItem('banner_gradient_black_blue', 'Degradado profundo', 'Banners',
      'Negro y azul', 110, emoji: '🌌', slot: 'perfil_banner'),
];

ShopItem? shopItemById(String id) {
  for (final item in shopCatalog) {
    if (item.id == id) return item;
  }
  return null;
}

class ShopState {
  const ShopState({
    required this.coins,
    required this.owned,
    required this.equipped,
  });
  final int coins;
  final Set<String> owned;
  final Map<String, String> equipped;
  bool owns(String id) => owned.contains(id) || (shopItemById(id)?.price == 0);
  bool equippedItem(String id) => equipped.values.contains(id);

  factory ShopState.fromMap(Map<String, dynamic> data) {
    final rawOwned = data['shopInventory'];
    final rawEquipped = data['shopEquipped'];
    return ShopState(
      coins: (data['habitCoins'] as num?)?.toInt() ?? 0,
      owned:
          rawOwned is List ? rawOwned.whereType<String>().toSet() : <String>{},
      equipped:
          rawEquipped is Map
              ? rawEquipped.map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              )
              : <String, String>{},
    );
  }
}

/// Artículos pendientes de adquirir. El inventario comprado se conserva
/// en ShopState y se administra desde el armario, no desde esta lista.
/// Artículos antiguos de demostración que no deben seguir vendiéndose.
/// Permanecen en el catálogo técnico para conservar inventarios y precios
/// históricos de cuentas existentes; no se conceden ni eliminan compras.
const retiredShopItemIds = <String>{
  'crown', 'mint_aura', 'elite_avatar', 'banner', 'avatar_frame',
  'streak_guard', 'mint_scarf', 'bandana', 'cape', 'pixel_glasses', 'cat_ears',
};

bool isShopItemVisible(String id) => !retiredShopItemIds.contains(id);

List<ShopItem> availableShopItems(ShopState? state,
    {String category = 'Todos'}) {
  return shopCatalog.where((item) =>
    isShopItemVisible(item.id) &&
    (category == 'Todos' || item.category == category) &&
    (state == null || !state.owns(item.id))
  ).toList(growable: false);
}

class ShopException implements Exception {
  const ShopException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ShopService {
  ShopService._();
  static final instance = ShopService._();
  FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');
  User get _user {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const ShopException('Inicia sesión para acceder a la tienda.');
    }
    return user;
  }

  DocumentReference<Map<String, dynamic>> get _userRef =>
      _db.collection('users').doc(_user.uid);
  Stream<ShopState> watch() =>
      _userRef.snapshots().map((doc) => ShopState.fromMap(doc.data() ?? {}));

  Future<void> buy(ShopItem item) async {
    if (shopItemById(item.id) == null) {
      throw const ShopException('Objeto desconocido.');
    }
    // En beta cerrada: comprar únicamente con transacción autoritativa.
    // Ante cualquier error conservar el ID y jamás volver a escribir
    // Habit Coins directamente desde Flutter.
    if (BetaHabitGateway.enabled) {
      await const BetaShopPurchaseGateway().comprar(item.id);
      return;
    }
    // Compilaciones normales conservan el flujo actual. La ruta demo
    // NUNCA vuelve a escribir directamente si el callable falla.
    if (DemoShopPurchaseGateway.requested) {
      await DemoShopPurchaseGateway.purchase(item.id);
      return;
    }
    final ref = _userRef;
    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(ref);
      if (!doc.exists) throw const ShopException('No se encontró tu perfil.');
      final state = ShopState.fromMap(doc.data() ?? {});
      if (state.owns(item.id)) {
        throw const ShopException('Ya tienes este objeto.');
      }
      if (state.coins < item.price) {
        throw ShopException(
          'Te faltan ${item.price - state.coins} Habit Coins.',
        );
      }
      transaction.update(ref, {
        'habitCoins': state.coins - item.price,
        'shopInventory': FieldValue.arrayUnion([item.id]),
      });
    });
  }

  Future<void> equip(ShopItem item, {bool remove = false}) async {
    if (item.slot == null) {
      throw const ShopException('Este artículo no se puede equipar.');
    }
    if (BetaHabitGateway.enabled) {
      final uid = _user.uid;
      await FirebaseFunctions.instanceFor(
        app: Firebase.app(), region: 'us-central1',
      ).httpsCallable('changeShopAppearanceBeta').call({
        'action': remove ? 'unequip' : 'equip',
        'itemId': item.id,
      });
      if (FirebaseAuth.instance.currentUser?.uid != uid) {
        throw StateError('Cambió la sesión durante el equipamiento.');
      }
      return;
    }
    final ref = _userRef;
    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(ref);
      if (!doc.exists) throw const ShopException('No se encontró tu perfil.');
      final state = ShopState.fromMap(doc.data() ?? {});
      if (!state.owns(item.id)) {
        throw const ShopException('Primero debes comprar el objeto.');
      }
      final equipped = Map<String, String>.from(state.equipped);
      if (remove || equipped[item.slot] == item.id) {
        equipped.remove(item.slot);
      } else {
        equipped[item.slot!] = item.id;
      }
      transaction.update(ref, {'shopEquipped': equipped});
    });
  }

  Future<void> resetLook() async {
    if (BetaHabitGateway.enabled) {
      final uid = _user.uid;
      await FirebaseFunctions.instanceFor(
        app: Firebase.app(), region: 'us-central1',
      ).httpsCallable('changeShopAppearanceBeta').call({
        'action': 'reset',
      });
      if (FirebaseAuth.instance.currentUser?.uid != uid) {
        throw StateError('Cambió la sesión durante la restauración.');
      }
      return;
    }
    final ref = _userRef;
    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(ref);
      if (!doc.exists) throw const ShopException('No se encontró tu perfil.');
      final equipped = ShopState.fromMap(doc.data() ?? {}).equipped;
      equipped.removeWhere((slot, _) => !slot.startsWith('perfil_'));
      transaction.update(ref, {'shopEquipped': equipped});
    });
  }
}
