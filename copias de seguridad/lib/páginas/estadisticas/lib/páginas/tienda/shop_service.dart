import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

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
    if (user == null)
      throw const ShopException('Inicia sesión para acceder a la tienda.');
    return user;
  }

  DocumentReference<Map<String, dynamic>> get _userRef =>
      _db.collection('users').doc(_user.uid);
  Stream<ShopState> watch() =>
      _userRef.snapshots().map((doc) => ShopState.fromMap(doc.data() ?? {}));

  Future<void> buy(ShopItem item) async {
    if (shopItemById(item.id) == null)
      throw const ShopException('Objeto desconocido.');
    final ref = _userRef;
    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(ref);
      if (!doc.exists) throw const ShopException('No se encontró tu perfil.');
      final state = ShopState.fromMap(doc.data() ?? {});
      if (state.owns(item.id))
        throw const ShopException('Ya tienes este objeto.');
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
    if (item.slot == null)
      throw const ShopException('Este artículo no se puede equipar.');
    final ref = _userRef;
    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(ref);
      if (!doc.exists) throw const ShopException('No se encontró tu perfil.');
      final state = ShopState.fromMap(doc.data() ?? {});
      if (!state.owns(item.id))
        throw const ShopException('Primero debes comprar el objeto.');
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
