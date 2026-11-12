import 'package:flutter/material.dart';

import 'shop_service.dart';
import 'wardrobe_screen.dart';

/// Tienda con tarjetas horizontales grandes. Conserva el catálogo y las compras.
class StoreScreen extends StatefulWidget {
  const StoreScreen({
    super.key,
    this.initialCoins = 120,
    this.onNavigate,
    this.onOpenWardrobe,
  });

  // Se mantiene por compatibilidad; el saldo real procede de ShopService.
  final int initialCoins;
  final ValueChanged<int>? onNavigate;
  final VoidCallback? onOpenWardrobe;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  static const _green = Color(0xFF07865F);
  static const _ink = Color(0xFF113B36);
  static const _muted = Color(0xFF607A76);
  static const _background = Color(0xFFF4FAF7);

  static const _categories = <String>[
    'Todos',
    'Personalización',
    'Avatares',
    'Insignias',
    'Extras',
    'Ropa',
    'Cabeza',
    'Accesorios',
    'Especiales',
  ];

  String _filter = 'Todos';
  String? _busy;

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _buy(ShopItem item) async {
    if (_busy != null) return;
    setState(() => _busy = item.id);
    try {
      await ShopService.instance.buy(item);
      _message('¡Canjeaste ${item.name}! Ya está en tu colección.');
    } catch (error) {
      _message(error is ShopException
          ? error.message
          : 'No se pudo completar la compra. Revisa tu conexión y permisos.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _openWardrobe() {
    if (widget.onOpenWardrobe != null) {
      widget.onOpenWardrobe!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WardrobeScreen()),
      );
    }
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      widget.onNavigate?.call(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: StreamBuilder<ShopState>(
          stream: ShopService.instance.watch(),
          builder: (context, snapshot) {
            final state = snapshot.data;
            final items = shopCatalog
                .where((item) => _filter == 'Todos' || item.category == _filter)
                .toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _header(state)),
                if (snapshot.hasError)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      child: Text(
                        'No se pudo cargar el saldo. Comprueba tu sesión y los permisos de Firestore.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: _categoryFilters()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: _green),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Recompensas disponibles',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _ink,
                              ),
                            ),
                          ),
                          Text(
                            '${items.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(
                            child: Text('No hay artículos en esta categoría.'),
                          ),
                        ),
                      ...items.map((item) => _offerCard(item, state)),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(ShopState? state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _ink,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tienda',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22004E37), offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _coinIcon(size: 23),
                    const SizedBox(width: 7),
                    Text(
                      state == null ? '...' : '${state.coins}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
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
              const Expanded(
                child: Text(
                  'Convierte tus Habit Coins en recompensas.',
                  style: TextStyle(color: _muted, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _openWardrobe,
                icon: const Icon(Icons.checkroom_rounded, size: 18),
                label: const Text('Armario'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFB8DCD0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryFilters() {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = _filter == category;
          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) => setState(() => _filter = category),
            showCheckmark: false,
            selectedColor: _green,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected ? _green : const Color(0xFFB8DCD0),
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : _ink,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          );
        },
      ),
    );
  }

  Widget _offerCard(ShopItem item, ShopState? state) {
    final owned = state?.owns(item.id) ?? false;
    final affordable = state != null && state.coins >= item.price;
    final waiting = _busy == item.id;
    final canBuy = state != null && !owned && affordable && _busy == null;
    final palette = _palette(item.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ink, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180F4039),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 174,
            child: Stack(
              children: [
                Positioned(
                  right: -28,
                  top: -36,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.17),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 30,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                item.category.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: _ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              item.name,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 21,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              item.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.emoji,
                              style: const TextStyle(fontSize: 92),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
            color: Colors.white.withValues(alpha: 0.88),
            child: Row(
              children: [
                _coinIcon(size: 25),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    item.price == 0 ? 'Gratis' : '${item.price} H. Coins',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: canBuy ? () => _buy(item) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFB6C6C0),
                    disabledForegroundColor: _ink,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    waiting
                        ? 'Comprando...'
                        : owned
                            ? 'Adquirido'
                            : state == null
                                ? 'Cargando...'
                                : affordable
                                    ? 'Canjear'
                                    : 'Sin saldo',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          if (state != null && !owned && !affordable)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 9),
              child: Text(
                'Te faltan ${item.price - state.coins} H. Coins',
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _coinIcon({double size = 24}) {
    return Image.asset(
      'assets/monedas/h coin.png',
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => Icon(
        Icons.monetization_on_rounded,
        size: size,
        color: const Color(0xFFFFC845),
      ),
    );
  }

  List<Color> _palette(String category) {
    switch (category) {
      case 'Ropa':
      case 'Personalización':
        return const [Color(0xFFD6B5FF), Color(0xFFB987F0)];
      case 'Cabeza':
      case 'Avatares':
        return const [Color(0xFFB3E8FF), Color(0xFF70C7F5)];
      case 'Insignias':
        return const [Color(0xFFFFE6A0), Color(0xFFFFC766)];
      case 'Accesorios':
        return const [Color(0xFFFFC4DF), Color(0xFFF59AC3)];
      case 'Especiales':
        return const [Color(0xFFC5F3CC), Color(0xFF8ADCB1)];
      default:
        return const [Color(0xFFC7F1E2), Color(0xFF91DCC5)];
    }
  }
}
