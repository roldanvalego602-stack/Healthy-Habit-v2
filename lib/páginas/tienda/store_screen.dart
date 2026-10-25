import 'package:flutter/material.dart';
import 'wardrobe_screen.dart';

/// Pantalla de tienda de Healthy Habit.
///
/// La compra y el saldo se gestionan en el estado local de esta pantalla.
/// Para conservar compras entre sesiones o sincronizarlas entre dispositivos,
/// conecta estos métodos con el servicio/repositorio de la aplicación.
class StoreScreen extends StatefulWidget {
  const StoreScreen({
    super.key,
    this.initialCoins = 120,
    this.onNavigate,
    this.onOpenWardrobe,
  });

  final int initialCoins;

  /// Índices sugeridos: 0 Inicio, 1 Hábitos, 2 Tienda, 3 Desafíos, 4 Perfil.
  final ValueChanged<int>? onNavigate;

  /// Abre la pantalla del armario/vestidor de la mascota.
  final VoidCallback? onOpenWardrobe;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

enum _StoreCategory { personalizacion, avatares, insignias, extras }

class _StoreItem {
  const _StoreItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.icon,
    required this.color,
    this.special = false,
  });

  final String id;
  final String name;
  final _StoreCategory category;
  final String description;
  final int price;
  final IconData icon;
  final Color color;
  final bool special;
}

class _StoreScreenState extends State<StoreScreen> {
  static const Color _green = Color(0xFF08BD87);
  static const Color _navy = Color(0xFF1A2B40);
  static const Color _muted = Color(0xFF71839A);
  static const Color _page = Color(0xFFF6F8FB);

  late int _coins;
  _StoreCategory? _filter;
  final Set<String> _owned = <String>{};

  final List<_StoreItem> _items = const [
    _StoreItem(
      id: 'avatar_frame',
      name: 'Marco de avatar',
      category: _StoreCategory.avatares,
      description: 'Un borde esmeralda para tu identidad.',
      price: 120,
      icon: Icons.center_focus_weak_rounded,
      color: Color(0xFFCFF9E8),
    ),
    _StoreItem(
      id: 'banner',
      name: 'Banner',
      category: _StoreCategory.personalizacion,
      description: 'Dale a tu perfil un estilo propio.',
      price: 120,
      icon: Icons.palette_outlined,
      color: Color(0xFFDFF3FF),
    ),
    _StoreItem(
      id: 'streak_guard',
      name: 'Protector de racha',
      category: _StoreCategory.extras,
      description: 'Conserva tu racha si fallas un día.',
      price: 300,
      icon: Icons.verified_user_outlined,
      color: Color(0xFFCFF9E8),
    ),
    _StoreItem(
      id: 'achievement_display',
      name: 'Expositor de logros',
      category: _StoreCategory.personalizacion,
      description: 'Un destello al completar tus hábitos.',
      price: 200,
      icon: Icons.palette_outlined,
      color: Color(0xFFDFF3FF),
    ),
    _StoreItem(
      id: 'elite_avatar',
      name: 'Avatar Élite',
      category: _StoreCategory.avatares,
      description: 'Una identidad exclusiva para tu perfil.',
      price: 140,
      icon: Icons.workspace_premium_outlined,
      color: Color(0xFFFFF1C2),
    ),
    _StoreItem(
      id: 'mint_scarf',
      name: 'Pañuelo Menta',
      category: _StoreCategory.personalizacion,
      description: 'Accesorio para Mr. Healthy',
      price: 180,
      icon: Icons.checkroom_outlined,
      color: Color(0xFFDDF7EA),
      special: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _coins = widget.initialCoins;
  }

  List<_StoreItem> get _visibleItems =>
      _filter == null
          ? _items
          : _items.where((item) => item.category == _filter).toList();

  String _categoryName(_StoreCategory category) {
    switch (category) {
      case _StoreCategory.personalizacion:
        return 'PERSONALIZACIÓN';
      case _StoreCategory.avatares:
        return 'AVATARES';
      case _StoreCategory.insignias:
        return 'INSIGNIAS';
      case _StoreCategory.extras:
        return 'EXTRAS';
    }
  }

  void _buy(_StoreItem item) {
    if (_owned.contains(item.id)) {
      _showMessage('Ya tienes ${item.name}.');
      return;
    }
    if (_coins < item.price) {
      _showMessage('Te faltan ${item.price - _coins} H. Coins para canjearlo.');
      return;
    }

    setState(() {
      _coins -= item.price;
      _owned.add(item.id);
    });
    _showMessage('¡Canjeaste ${item.name}!');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;
    final regularItems = visibleItems.where((item) => !item.special).toList();
    final specialItems = visibleItems.where((item) => item.special).toList();

    return Scaffold(
      backgroundColor: _page,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            widget.onNavigate?.call(0);
                          }
                        },
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: _navy,
                        ),
                        tooltip: 'Volver',
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tienda',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _openWardrobe,
                        icon: const Icon(Icons.checkroom_rounded, size: 18),
                        label: const Text('Armario'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _green,
                          side: const BorderSide(color: Color(0xFFBDEBD8)),
                          backgroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Convierte tus Habit coins en recompensas.',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  _balanceCard(),
                  const SizedBox(height: 16),
                  _categoryGrid(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Elige tu recompensa',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${visibleItems.length} disponibles',
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (visibleItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No hay recompensas en esta categoría todavía.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted),
                      ),
                    ),
                  ...regularItems.map(_productCard),
                  ...specialItems.map(_specialCard),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openWardrobe() {
    if (widget.onOpenWardrobe != null) {
      widget.onOpenWardrobe!();
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const WardrobeScreen()));
  }

  Widget _balanceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD8E9E3)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5D1),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD8C95E), width: 1.5),
            ),
            child: Center(
              child: Image.asset(
                'assets/monedas/h coin.png',
                width: 40,
                height: 40,
                errorBuilder:
                    (_, __, ___) => const Icon(
                      Icons.monetization_on_rounded,
                      color: Color(0xFFB58A26),
                      size: 34,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Habit coins',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_coins H. Coins',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Disponibles para intercambiar',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _categoryButton(
                'Personalización',
                Icons.tune_rounded,
                _StoreCategory.personalizacion,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _categoryButton(
                'Avatares',
                Icons.person_outline_rounded,
                _StoreCategory.avatares,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _categoryButton(
                'Insignias',
                Icons.workspace_premium_outlined,
                _StoreCategory.insignias,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _categoryButton(
                'Extras',
                Icons.auto_awesome_outlined,
                _StoreCategory.extras,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _categoryButton(String label, IconData icon, _StoreCategory category) {
    final selected = _filter == category;
    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: () => setState(() => _filter = selected ? null : category),
        icon: Icon(icon, size: 16, color: _green),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? const Color(0xFFE0F8EE) : Colors.white,
          foregroundColor: _navy,
          side: BorderSide(color: selected ? _green : const Color(0xFFDCE5EF)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }

  Widget _productCard(_StoreItem item) {
    final owned = _owned.contains(item.id);
    final canAfford = _coins >= item.price;
    final shortage = item.price - _coins;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B15283B),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  item.icon,
                  color:
                      item.category == _StoreCategory.avatares
                          ? _green
                          : const Color(0xFF009FE3),
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categoryName(item.category),
                      style: TextStyle(
                        color:
                            item.name == 'Avatar Élite'
                                ? const Color(0xFFB75B00)
                                : _muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Image.asset(
                'assets/monedas/h coin.png',
                width: 19,
                height: 19,
                errorBuilder:
                    (_, __, ___) => const Icon(
                      Icons.monetization_on,
                      size: 18,
                      color: Color(0xFFB58A26),
                    ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${item.price} H. Coins',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: owned || !canAfford ? null : () => _buy(item),
                  icon: Icon(
                    owned
                        ? Icons.check_circle_outline
                        : Icons.shopping_bag_outlined,
                    size: 17,
                  ),
                  label: Text(owned ? 'Adquirido' : 'Canjear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    disabledBackgroundColor: const Color(0xFFE1E7EF),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: _muted,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!owned && !canAfford) ...[
            const SizedBox(height: 5),
            Text(
              'Te faltan $shortage H. Coins',
              style: const TextStyle(color: _muted, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _specialCard(_StoreItem item) {
    final owned = _owned.contains(item.id);
    final canAfford = _coins >= item.price;
    final shortage = item.price - _coins;

    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF91DFC1)),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F8EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Especial',
              style: TextStyle(
                color: _green,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 126,
            decoration: BoxDecoration(
              color: const Color(0xFFE4F7EF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Image.asset(
                'assets/mascot/healthy.png',
                height: 112,
                fit: BoxFit.contain,
                errorBuilder:
                    (_, __, ___) => const Icon(
                      Icons.checkroom_rounded,
                      size: 70,
                      color: _green,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.name,
            style: const TextStyle(
              color: _navy,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Image.asset(
                'assets/monedas/h coin.png',
                width: 19,
                height: 19,
                errorBuilder:
                    (_, __, ___) => const Icon(
                      Icons.monetization_on,
                      size: 18,
                      color: Color(0xFFB58A26),
                    ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${item.price} H. Coins',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                owned ? 'Adquirido' : 'Disponible',
                style: const TextStyle(color: _green, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: owned || !canAfford ? null : () => _buy(item),
              icon: Icon(
                owned
                    ? Icons.check_circle_outline
                    : Icons.shopping_bag_outlined,
                size: 18,
              ),
              label: Text(owned ? 'Adquirido' : 'Canjear'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                disabledBackgroundColor: const Color(0xFFE1E7EF),
                foregroundColor: Colors.white,
                disabledForegroundColor: _muted,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          if (!owned && !canAfford) ...[
            const SizedBox(height: 10),
            Text(
              'Te faltan $shortage H. Coins',
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bottomNav() {
    const entries = [
      (Icons.home_outlined, 'Inicio'),
      (Icons.track_changes_outlined, 'Hábitos'),
      (Icons.storefront_outlined, 'Tienda'),
      (Icons.emoji_events_outlined, 'Desafíos'),
      (Icons.person_outline_rounded, 'Perfil'),
    ];
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8EDF2))),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(entries.length, (index) {
            final entry = entries[index];
            final selected = index == 2;
            return InkWell(
              onTap: () => widget.onNavigate?.call(index),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(entry.$1, size: 21, color: selected ? _green : _muted),
                    const SizedBox(height: 3),
                    Text(
                      entry.$2,
                      style: TextStyle(
                        color: selected ? _green : _muted,
                        fontSize: 10,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
