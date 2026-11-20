import 'package:flutter/material.dart';
import '../../tema/healthy_theme.dart';
import '../../tema/healthy_coin.dart';
import 'shop_service.dart';
import 'shop_item_artwork.dart';
import '../../servicios/healthy_feedback_service.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});
  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  Color get navy => HealthyAdaptive.text;
  Color get green => HealthyAdaptive.accent;
  Color get muted => HealthyAdaptive.muted;
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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.description),
                  const SizedBox(height: 12),
                  const Text('Costo:'),
                  HealthyCoinAmount(amount: '${item.price}',
                    size: 22, suffix: ' Habit Coins',
                    style: TextStyle(color: navy,
                      fontWeight: FontWeight.w800)),
                ],
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
      if (!state.owns(item.id)) {
        await ShopService.instance.buy(item);
        await HealthyFeedbackService.onReward();
      }
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
    backgroundColor: HealthyAdaptive.background,
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
                    Expanded(
                      child: Text(
                        'Armario',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: navy,
                        ),
                      ),
                    ),
                    const HealthyCoinIcon(size: 24),
                    const SizedBox(width: 5),
                    Text(
                      state == null ? '...' : '${state.coins}',
                      style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Tan único como tú',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),
                Text(
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

  /// Composición anclada a un lienzo fijo de 280×275. La mascota base
  /// permanece centrada y las prendas se distribuyen según su función.
  /// Ajustar estos valores si cambia la ilustración de la mascota.
  Widget _preview(ShopState? state) {
    final equipped = state?.equipped ?? <String, String>{};
    final names = equipped.entries
        .where((entry) => !entry.key.startsWith('perfil_'))
        .map((entry) => shopItemById(entry.value)?.name)
        .whereType<String>()
        .join(' + ');

    Widget accessory(String id, {
      required double left, required double top, required double size,
    }) {
      final item = shopItemById(id);
      if (item == null) return const SizedBox.shrink();
      return Positioned(
        left: left,
        top: top,
        width: size,
        height: size,
        child: IgnorePointer(
          child: ShopItemArtwork(item: item, size: size),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: HealthyAdaptive.isDark
              ? const [Color(0xFF223E39), Color(0xFF1A3138)]
              : const [Color(0xFFE8F7EF), Color(0xFFDDEFE6)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text('Vista previa de Mr. Healthy',
            style: TextStyle(color: navy, fontWeight: FontWeight.w800))),
          IconButton(
            onPressed: state == null ? null : _reset,
            icon: const Icon(Icons.refresh),
            tooltip: 'Quitar accesorios',
          ),
        ]),
        // FittedBox mantiene alineadas todas las capas en dispositivos
        // estrechos y no modifica las posiciones lógicas de los objetos.
        SizedBox(
          width: double.infinity,
          height: 275,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 280,
              height: 275,
              child: Stack(clipBehavior: Clip.none, children: [
                if (equipped['aura'] == 'mint_aura')
                  Positioned(
                    left: 30, top: 17,
                    child: Container(
                      width: 220, height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                          color: green.withValues(alpha: .5),
                          blurRadius: 44, spreadRadius: 8,
                        )],
                      ),
                    ),
                  ),
                // Objetos detrás del cuerpo.
                if (equipped['espalda'] == 'cape')
                  Positioned(
                    left: 47, top: 148,
                    child: Container(
                      width: 185, height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB94B58),
                        borderRadius: BorderRadius.circular(42),
                      ),
                    ),
                  ),
                if (equipped['espalda'] == 'leaf_backpack')
                  accessory('leaf_backpack', left: 165, top: 115, size: 85),

                Positioned(
                  left: 30, top: 7,
                  width: 220, height: 260,
                  child: Image.asset(
                    'assets/mascot/healthy.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.sentiment_satisfied,
                          size: 170, color: green),
                  ),
                ),

                // Vestimenta y objetos de frente. Los ojos de la mascota
                // están por encima del centro de la cara (no en la boca).
                if (equipped['torso'] == 'leaf_hoodie')
                  accessory('leaf_hoodie', left: 76, top: 151, size: 128),

                if (equipped['cabeza'] == 'cap')
                  accessory('cap', left: 77, top: 30, size: 125),
                if (equipped['cabeza'] == 'sports_headband')
                  accessory('sports_headband',
                    left: 78, top: 62, size: 122),
                if (equipped['cabeza'] == 'leaf_headphones')
                  accessory('leaf_headphones',
                    left: 61, top: 60, size: 154),
                if (equipped['cabeza'] == 'crown')
                  accessory('crown', left: 94, top: 35, size: 92),
                if (equipped['cabeza'] == 'cat_ears')
                  accessory('cat_ears', left: 85, top: 40, size: 110),

                if (equipped['ojos'] == 'sunglasses')
                  accessory('sunglasses', left: 91, top: 107, size: 100),
                if (equipped['ojos'] == 'pixel_glasses')
                  accessory('pixel_glasses',
                    left: 85, top: 107, size: 110),

                if (equipped['cuello'] == 'wellness_medal')
                  accessory('wellness_medal',
                    left: 111, top: 177, size: 58),
                if (equipped['cuello'] == 'mint_scarf' ||
                    equipped['cuello'] == 'bandana')
                  Positioned(
                    left: 82, top: 192,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 4),
                      decoration: BoxDecoration(
                        color: equipped['cuello'] == 'mint_scarf'
                            ? green : const Color(0xFF1D7666),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('✦  ✦  ✦',
                        style: TextStyle(color: Colors.white)),
                    ),
                  ),
                if (equipped['mano'] == 'water_bottle')
                  accessory('water_bottle',
                    left: 202, top: 163, size: 61),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          names.isEmpty ? 'Sin accesorios equipados' : names,
          textAlign: TextAlign.center,
          style: TextStyle(color: navy, fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }

  Widget _itemCard(ShopItem item, ShopState state) {
    final owned = state.owns(item.id);
    final equipped = state.equippedItem(item.id);
    final affordable = state.coins >= item.price;
    return Material(
      color: HealthyAdaptive.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _busy != null ? null : () => _onTap(item, state),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: equipped ? green : HealthyAdaptive.border,
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
                    color: HealthyAdaptive.isDark
                        ? const Color(0xFF304941)
                        : const Color(0xFFE5F7EF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ShopItemArtwork(item: item, size: 74),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              !owned && affordable && _busy != item.id
                  ? HealthyCoinAmount(amount: '${item.price}',
                      size: 17, suffix: ' H. Coins',
                      style: TextStyle(
                        color: muted, fontWeight: FontWeight.w700,
                        fontSize: 11))
                  : Text(
                      _busy == item.id
                          ? 'Guardando...'
                          : equipped
                              ? 'Equipado · Toca para quitar'
                              : owned
                                  ? (item.slot == null
                                      ? 'Adquirido' : 'Toca para equipar')
                                  : 'Saldo insuficiente',
                      maxLines: 2,
                      style: TextStyle(
                        color: equipped ? green : muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
              const SizedBox(height: 6),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
