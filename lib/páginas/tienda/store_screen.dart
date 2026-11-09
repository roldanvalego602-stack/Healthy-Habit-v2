import 'package:flutter/material.dart';
import 'shop_service.dart';
import 'wardrobe_screen.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({
    super.key,
    this.initialCoins = 120,
    this.onNavigate,
    this.onOpenWardrobe,
  });
  // Compatibilidad con llamadas existentes. El saldo real siempre viene de Firestore.
  final int initialCoins;
  final ValueChanged<int>? onNavigate;
  final VoidCallback? onOpenWardrobe;
  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  static const green = Color(0xFF08BD87),
      navy = Color(0xFF1A2B40),
      muted = Color(0xFF71839A);
  String _filter = 'Todos';
  String? _busy;
  final _categories = const [
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
      _message(
        error is ShopException
            ? error.message
            : 'No se pudo completar la compra. Revisa tu conexión y permisos.',
      );
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _openWardrobe() {
    if (widget.onOpenWardrobe != null) {
      widget.onOpenWardrobe!();
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WardrobeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: StreamBuilder<ShopState>(
          stream: ShopService.instance.watch(),
          builder: (context, snapshot) {
            final state = snapshot.data;
            final items =
                shopCatalog
                    .where((i) => _filter == 'Todos' || i.category == _filter)
                    .toList();
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.pop(context);
                              } else {
                                widget.onNavigate?.call(0);
                              }
                            },
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Expanded(
                            child: Text(
                              'Tienda',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: navy,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _openWardrobe,
                            icon: const Icon(Icons.checkroom_rounded),
                            label: const Text('Armario'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Convierte tus Habit Coins en recompensas.',
                        style: TextStyle(color: muted),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/monedas/h coin.png',
                              width: 50,
                              height: 50,
                              errorBuilder:
                                  (_, __, ___) => const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.amber,
                                    size: 45,
                                  ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Saldo disponible',
                                  style: TextStyle(color: muted),
                                ),
                                Text(
                                  state == null
                                      ? 'Cargando...'
                                      : '${state.coins} H. Coins',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: navy,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (snapshot.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'No se pudo cargar el saldo. Comprueba tu sesión y permisos de Firestore.',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children:
                            _categories
                                .map(
                                  (c) => ChoiceChip(
                                    label: Text(c),
                                    selected: _filter == c,
                                    onSelected:
                                        (_) => setState(() => _filter = c),
                                    selectedColor: const Color(0xFFD9F7E9),
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${items.length} recompensas',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: navy,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (items.isEmpty)
                        const Text('No hay artículos en esta categoría.'),
                      ...items.map((item) => _card(item, state)),
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

  Widget _card(ShopItem item, ShopState? state) {
    final owned = state?.owns(item.id) ?? false;
    final affordable = state != null && state.coins >= item.price;
    final waiting = _busy == item.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F8EE),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(item.emoji, style: const TextStyle(fontSize: 27)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category.toUpperCase(),
                      style: const TextStyle(
                        color: muted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      item.description,
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.image_not_supported_outlined,
                color: Color(0xFFB58A26),
                size: 20,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  item.price == 0 ? 'Gratis' : '${item.price} H. Coins',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed:
                    state == null || owned || !affordable || _busy != null
                        ? null
                        : () => _buy(item),
                icon: Icon(
                  owned
                      ? Icons.check_circle_outline
                      : Icons.shopping_bag_outlined,
                  size: 17,
                ),
                label: Text(
                  waiting
                      ? 'Comprando...'
                      : owned
                      ? 'Adquirido'
                      : affordable
                      ? 'Canjear'
                      : 'Sin saldo',
                ),
                style: FilledButton.styleFrom(backgroundColor: green),
              ),
            ],
          ),
          if (state != null && !owned && !affordable)
            Text(
              'Te faltan ${item.price - state.coins} H. Coins',
              style: const TextStyle(color: muted, fontSize: 11),
            ),
        ],
      ),
    );
  }
}
