import 'package:flutter/material.dart';
import 'shop_service.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});
  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  static const navy = Color(0xFF193342),
      green = Color(0xFF42C99A),
      muted = Color(0xFF82919A);
  String _filter = 'Todos';
  String? _busy;
  final categories = const [
    'Todos',
    'Cabeza',
    'Ropa',
    'Accesorios',
    'Especiales',
    'Personalización',
    'Avatares',
    'Extras',
  ];

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onTap(ShopItem item, ShopState state) async {
    if (_busy != null) return;
    if (!state.owns(item.id)) {
      final accepted = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text('¿Comprar ${item.name}?'),
              content: Text(
                '${item.description}\n\nCosto: ${item.price} Habit Coins.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Comprar'),
                ),
              ],
            ),
      );
      if (accepted != true || !mounted) return;
    }
    setState(() => _busy = item.id);
    try {
      if (!state.owns(item.id)) await ShopService.instance.buy(item);
      if (item.slot != null) {
        await ShopService.instance.equip(
          item,
          remove: state.equippedItem(item.id),
        );
        _message(
          state.owns(item.id)
              ? (state.equippedItem(item.id)
                  ? 'Objeto retirado.'
                  : 'Objeto equipado.')
              : 'Comprado y equipado.',
        );
      } else {
        _message(
          'Objeto adquirido. Su efecto se activa desde la sección correspondiente.',
        );
      }
    } catch (error) {
      _message(
        error is ShopException
            ? error.message
            : 'No se pudo guardar el cambio. Revisa tu conexión.',
      );
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _reset() async {
    try {
      await ShopService.instance.resetLook();
      _message('Aspecto restablecido. Conservas todas tus compras.');
    } catch (_) {
      _message('No se pudo restablecer el aspecto.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F8F6),
    body: SafeArea(
      child: StreamBuilder<ShopState>(
        stream: ShopService.instance.watch(),
        builder: (context, snapshot) {
          final state = snapshot.data;
          final visible =
              shopCatalog
                  .where((i) => _filter == 'Todos' || i.category == _filter)
                  .toList();
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Armario',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: navy,
                        ),
                      ),
                    ),
                    Image.asset(
                      'assets/monedas/h coin.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (_, __, ___) => const Icon(
                            Icons.image_not_supported_outlined,
                            color: Color(0xFFB58A26),
                            size: 22,
                          ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      state == null ? '...' : '${state.coins}',
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Tan único como tú',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),
                const Text(
                  'Personaliza a Mr. Healthy con tus objetos.',
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 20),
                _preview(state),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        categories
                            .map(
                              (category) => Padding(
                                padding: const EdgeInsets.only(right: 7),
                                child: ChoiceChip(
                                  label: Text(category),
                                  selected: _filter == category,
                                  onSelected:
                                      (_) => setState(() => _filter = category),
                                  selectedColor: green,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                if (snapshot.hasError)
                  const Text(
                    'Error al cargar inventario. Revisa tu sesión y permisos.',
                    style: TextStyle(color: Colors.red),
                  ),
                if (state == null && !snapshot.hasError)
                  const Center(child: CircularProgressIndicator()),
                if (state != null)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visible.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: .76,
                        ),
                    itemBuilder: (_, index) => _itemCard(visible[index], state),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.storefront),
                    label: const Text('Volver a la tienda'),
                    style: FilledButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: navy,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );

  Widget _preview(ShopState? state) {
    final eq = state?.equipped ?? <String, String>{};
    final head = shopItemById(eq['cabeza'] ?? '');
    final eye = eq['ojos'];
    final neck = eq['cuello'];
    final cape = eq['espalda'] == 'cape';
    final aura = eq['aura'] == 'mint_aura';
    final names = eq.entries
        .where((e) => !e.key.startsWith('perfil_'))
        .map((e) => shopItemById(e.value)?.name)
        .whereType<String>()
        .join(' + ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F7EF), Color(0xFFDDEFE6)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Vista previa de Mr. Healthy',
                  style: TextStyle(color: navy, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: state == null ? null : _reset,
                icon: const Icon(Icons.refresh),
                tooltip: 'Quitar accesorios',
              ),
            ],
          ),
          SizedBox(
            height: 275,
            width: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (aura)
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: green.withValues(alpha: .6),
                          blurRadius: 48,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                if (cape)
                  Positioned(
                    top: 145,
                    child: Container(
                      width: 180,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB94B58),
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                Image.asset(
                  'assets/mascot/healthy.png',
                  height: 260,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (_, __, ___) => const Icon(
                        Icons.sentiment_satisfied,
                        size: 170,
                        color: green,
                      ),
                ),
                if (head != null)
                  Positioned(
                    top: 5,
                    child: Text(
                      head.emoji,
                      style: const TextStyle(fontSize: 49),
                    ),
                  ),
                if (eye != null)
                  Positioned(
                    top: 160,
                    child: Text(
                      eye == 'sunglasses' ? '🕶️' : '🤓',
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                if (neck == 'bandana' || neck == 'mint_scarf')
                  Positioned(
                    top: 202,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            neck == 'mint_scarf'
                                ? green
                                : const Color(0xFF1D7666),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '✦  ✦  ✦',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            names.isEmpty ? 'Sin accesorios equipados' : names,
            textAlign: TextAlign.center,
            style: const TextStyle(color: navy, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(ShopItem item, ShopState state) {
    final owned = state.owns(item.id);
    final equipped = state.equippedItem(item.id);
    final affordable = state.coins >= item.price;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _busy != null ? null : () => _onTap(item, state),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: equipped ? green : const Color(0xFFE2EAE5),
              width: equipped ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F7EF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(item.emoji, style: const TextStyle(fontSize: 45)),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _busy == item.id
                    ? 'Guardando...'
                    : equipped
                    ? 'Equipado · Toca para quitar'
                    : owned
                    ? (item.slot == null ? 'Adquirido' : 'Toca para equipar')
                    : affordable
                    ? '${item.price} H. Coins'
                    : 'Saldo insuficiente',
                maxLines: 2,
                style: TextStyle(
                  color: equipped ? const Color(0xFF16866B) : muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
