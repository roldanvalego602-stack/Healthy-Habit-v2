import 'dart:async';
import 'package:flutter/material.dart';
import '../../tema/healthy_theme.dart';
import '../../guia/guide_target.dart';
import '../../tema/cosmos_theme.dart';
import '../../tema/healthy_motion.dart';
import '../../tema/healthy_float.dart';
import '../../tema/healthy_celebration.dart';
import '../../tema/cosmos_interaction_fx.dart';
import '../../tema/healthy_visual_mode.dart';
import '../../tema/healthy_coin.dart';

import '../../servicios/healthy_feedback_service.dart';
import 'shop_service.dart';
import 'shop_daily_rotation.dart';
import 'shop_rarity.dart';
import 'shop_purchase_gateway.dart';
import 'beta_shop_purchase_gateway.dart';
import '../../servicios/beta_habit_gateway.dart';
import 'shop_item_artwork.dart';
import 'store_featured_carousel.dart';
import 'wardrobe_screen.dart';
import 'healthy_titan_cave_screen.dart';
import 'season_pass_preview_screen.dart';

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
  Color get _green => HealthyAdaptive.accent;
  Color get _ink => HealthyAdaptive.text;
  Color get _muted => HealthyAdaptive.muted;
  Color get _background => HealthyAdaptive.background;

  static const _categories = <String>[
    'Todos',
    'Personalización',
    'Avatares',
    'Marcos',
    'Banners',
    'Reacciones',
    'Skins',
    'Insignias',
    'Extras',
    'Ropa',
    'Cabeza',
    'Accesorios',
    'Especiales',
    'Temas',
    'OVNI',
  ];

  String _filter = 'Todos';
  late String _shopDay;
  Timer? _dayWatcher;

  bool get _offerIsAuthoritative =>
      BetaHabitGateway.enabled || DemoShopPurchaseGateway.requested;
  ShopDailyRotation get _rotation =>
      ShopDailyRotation.forDay(_shopDay);
  int _currentPrice(ShopItem item) =>
      _rotation.priceFor(item, authoritative: _offerIsAuthoritative);
  String? _busy;
  bool _recoveryBusy = false;
  List<String> _pendingBetaPurchases = [];

  @override
  void initState() {
    super.initState();
    _shopDay = ShopDailyRotation.today().dayKey;
    _dayWatcher = Timer.periodic(const Duration(minutes: 1), (_) {
      final day = ShopDailyRotation.today().dayKey;
      if (mounted && day != _shopDay) setState(() => _shopDay = day);
    });
    if (BetaHabitGateway.enabled) {
      _loadBetaPurchases();
    }
  }

  @override
  void dispose() {
    _dayWatcher?.cancel();
    super.dispose();
  }

  Future<void> _loadBetaPurchases() async {
    if (!BetaHabitGateway.enabled) return;
    try {
      final items = await const BetaShopPurchaseGateway().listarPendientes();
      if (mounted) {
        setState(() => _pendingBetaPurchases = items);
      }
    } catch (_) {
      _message('No se pudo revisar el diario de compras pendientes.');
    }
  }

  Future<void> _recoverBetaPurchase(String itemId) async {
    if (_busy != null || _recoveryBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recuperar compra'),
        content: Text(
          'Se consultará la compra pendiente de $itemId '
          'con el identificador original. El servidor podría haber '
          'procesado el pago. No se generará una compra nueva.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Recuperar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _recoveryBusy = true);
    try {
      await const BetaShopPurchaseGateway().comprar(
        itemId, soloRecuperar: true,
      );
      if (mounted) {
        _message('Compra confirmada por el servidor.');
      }
      await _loadBetaPurchases();
    } catch (_) {
      _message('No se pudo recuperar la compra. Se conservó su identificador.');
    } finally {
      if (mounted) setState(() => _recoveryBusy = false);
    }
  }

  Widget _pendingBetaBanner() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Compras pendientes de confirmar',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('La respuesta pudo perderse. '
                'Recupera la compra original, no repitas el pago.'),
            for (final itemId in _pendingBetaPurchases)
              ListTile(
                dense: true,
                title: Text(shopItemById(itemId)?.name ?? itemId),
                trailing: TextButton(
                  onPressed: _recoveryBusy || _busy != null
                      ? null : () => _recoverBetaPurchase(itemId),
                  child: const Text('Recuperar'),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  int _secretTaps = 0;
  DateTime? _lastSecretTap;

  void _trySecretEntry() {
    final now = DateTime.now();
    if (_lastSecretTap == null ||
        now.difference(_lastSecretTap!) > const Duration(seconds: 5)) {
      _secretTaps = 0;
    }
    _lastSecretTap = now;
    setState(() => _secretTaps++);
    if (_secretTaps >= 7) {
      setState(() => _secretTaps = 0);
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => const HealthyTitanCaveScreen(),
      ));
    }
  }


  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _buy(ShopItem item) async {
    if (_busy != null) return;
    final quotedDay = _shopDay;
    final quotedPrice = _currentPrice(item);
    if (!_rotation.contains(item.id)) {
      _message('Este artículo no está disponible hoy.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar canje'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vas a adquirir ${item.name} para tu colección.'),
            const SizedBox(height: 10),
            Semantics(
              label: 'Costo: $quotedPrice Habit Coins',
              child: Row(children: [
                const HealthyCoinIcon(size: 25),
                const SizedBox(width: 7),
                Text('$quotedPrice Habit Coins',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              ]),
            ),
            const SizedBox(height: 8),
            Text('La compra no se puede deshacer ni reembolsar.',
              style: TextStyle(color: HealthyAdaptive.muted, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('tienda-confirmar-canje'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar canje'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (quotedDay != ShopDailyRotation.today().dayKey) {
      setState(() => _shopDay = ShopDailyRotation.today().dayKey);
      _message('La selección cambió de día. Revisa el nuevo precio.');
      return;
    }
    setState(() => _busy = item.id);
    try {
      await ShopService.instance.buy(item, shopDay: _shopDay);
      await _loadBetaPurchases();
      // La compra ya fue confirmada por Firestore. Los efectos son opcionales.
      final celebrate = await HealthyFeedbackService.onReward();
      if (!mounted) return;
      if (celebrate) {
        HealthyCelebration.show(
          context,
          title: '¡Recompensa adquirida!',
          subtitle: '${item.name} ya está en tu colección.',
          icon: Icons.card_giftcard_rounded,
          effect: CosmosEffect.purchase,
        );
      } else {
        _message('${item.name} se agregó a tu colección.');
      }
    } catch (error) {
      await _loadBetaPurchases();
      _message(error is ShopException
          ? error.message
          : 'No se pudo completar la compra. Revisa tu conexión y permisos.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _showFeaturedPreview(ShopItem item, ShopState? state) {
    final owned = state?.owns(item.id) ?? false;
    final price = _currentPrice(item);
    final available = _rotation.contains(item.id);
    final affordable = state != null && state.coins >= price;
    final canBuy = state != null && !owned && available && affordable && _busy == null;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: HealthyAdaptive.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            22, 12, 22, 22 + MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: ShopItemArtwork(item: item, size: 125)),
              const SizedBox(height: 12),
              Text(item.category.toUpperCase(),
                style: TextStyle(color: HealthyAdaptive.accent,
                  fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              ShopRarityChip(item: item),
              const SizedBox(height: 6),
              ShopRarityChip(item: item),
              const SizedBox(height: 6),
              Text(item.name,
                style: TextStyle(color: HealthyAdaptive.text,
                  fontSize: 25, fontWeight: FontWeight.w900)),
              const SizedBox(height: 9),
              Text(item.description,
                style: TextStyle(color: HealthyAdaptive.muted,
                  fontSize: 14, height: 1.4)),
              const SizedBox(height: 17),
              Row(children: [
                _coinIcon(size: 24),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  item.price == 0 ? 'Gratis'
                      : '$price Habit Coins',
                  style: TextStyle(color: HealthyAdaptive.text,
                    fontSize: 17, fontWeight: FontWeight.w800))),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canBuy ? () {
                    Navigator.of(sheetContext).pop();
                    _buy(item);
                  } : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: HealthyAdaptive.accent,
                    foregroundColor: const Color(0xFF10392F),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(owned ? 'Ya adquirido'
                      : state == null ? 'Cargando saldo'
                      : !available ? 'Fuera de rotación'
                       : affordable ? 'Canjear recompensa'
                      : 'Saldo insuficiente'),
                ),
              ),
              if (state != null && !owned && !affordable) ...[
                const SizedBox(height: 8),
                Center(child: Text(
                  'Te faltan ${price - state.coins} Habit Coins',
                  style: TextStyle(color: HealthyAdaptive.muted,
                    fontSize: 12))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleCosmos(ShopState state) async {
    final item = shopItemById(cosmosShopId);
    if (item == null || _busy != null) return;
    if (!state.owns(item.id)) {
      await _buy(item);
      return;
    }
    final active = state.equipped[cosmosSlot] == cosmosShopId;
    setState(() => _busy = item.id);
    try {
      await ShopService.instance.equip(item, remove: active);
      if (!mounted) return;
      _message(active ? 'Volviste a tu estilo anterior.' :
          'Cosmos equipado. ¡Explora tu nueva galaxia!');
    } catch (_) {
      _message('No fue posible cambiar el tema. Comprueba tu conexión.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Widget _cosmosThemePanel(ShopState? state) {
    final item = shopItemById(cosmosShopId)!;
    final owned = state?.owns(cosmosShopId) ?? false;
    final equipped = state?.equipped[cosmosSlot] == cosmosShopId;
    final busy = _busy != null || state == null;
    final canBuy = state != null && state.coins >= item.price;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: Container(
        key: const ValueKey('cosmos-premium-theme-card'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF202957), Color(0xFF43235E), Color(0xFF0F1A3D)],
          ),
          border: Border.all(color: CosmosPalette.cyan.withValues(alpha: .8)),
          boxShadow: const [BoxShadow(color: Color(0x38245BAA), blurRadius: 18)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.public_rounded,
                color: CosmosPalette.cyan, size: 34),
              const SizedBox(width: 12),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('COSMOS · TEMA ANIMADO',
                    style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w900, fontSize: 17)),
                  SizedBox(height: 3),
                  Text('Nebulosas · Estrellas · Sonidos exclusivos',
                    style: TextStyle(color: Color(0xFFD9DFFF), fontSize: 11)),
                ],
              )),
            ]),
            const SizedBox(height: 12),
            const Text('Una galaxia completa para tus hábitos: '
              'colores espaciales, fondos vivos y tarjetas luminosas.',
              style: TextStyle(color: Color(0xFFEEF0FF), fontSize: 12)),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('cosmos-buy-equip'),
                onPressed: busy || (!owned && !canBuy)
                    ? null : () => _toggleCosmos(state),
                icon: Icon(equipped ? Icons.check_circle_outline :
                    owned ? Icons.auto_awesome_rounded :
                    Icons.toll_rounded),
                label: Text(equipped ? 'Equipado · Quitar tema' :
                    owned ? 'Equipar Cosmos' :
                    state == null ? 'Consultando inventario' :
                    canBuy ? 'Desbloquear · 1800 Habit Coins' :
                    'Necesitas 1800 Habit Coins'),
              ),
            ),
          ]),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: StreamBuilder<ShopState>(
          stream: ShopService.instance.watch(),
          builder: (context, snapshot) {
            final state = snapshot.data;
            // Un artículo adquirido sale de la tienda, pero permanece
            // disponible en el armario/inventario para equiparlo.
            final rotation = _rotation;
            final items = availableShopItems(state, category: _filter)
                .where((item) => rotation.contains(item.id))
                .toList(growable: false);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: KeyedSubtree(
                  key: HealthyGuideTargets.shopHeader,
                  child: _header(state))),
                if (rotation.contains(cosmosShopId) ||
                    (state?.owns(cosmosShopId) ?? false))
                  SliverToBoxAdapter(child: KeyedSubtree(
                    key: HealthyGuideTargets.shopFeatured,
                    child: _cosmosThemePanel(state))),
                if (BetaHabitGateway.enabled &&
                    _pendingBetaPurchases.isNotEmpty)
                  SliverToBoxAdapter(child: _pendingBetaBanner()),
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
                SliverToBoxAdapter(child: _dailyPanel(state)),
                SliverToBoxAdapter(
                  child: StoreFeaturedCarousel(
                    items: [
                      ...rotation.itemIds.skip(ShopDailyRotation.fixedSlots),
                      ...rotation.itemIds.take(ShopDailyRotation.fixedSlots),
                    ].map(shopItemById)
                        .whereType<ShopItem>()
                        .where((item) => state == null || !state.owns(item.id))
                        .take(5).toList(),
                    shopState: state,
                    displayPriceFor: _currentPrice,
                    onSelected: (item) => _showFeaturedPreview(item, state),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                    child: Material(
                      color: const Color(0xFF173F36),
                      borderRadius: BorderRadius.circular(19),
                      child: InkWell(
                        key: const ValueKey('store-season-pass-entry'),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SeasonPassPreviewScreen())),
                        borderRadius: BorderRadius.circular(19),
                        child: const Padding(
                          padding: EdgeInsets.all(15),
                          child: Row(children: [
                            Icon(Icons.workspace_premium_rounded,
                              color: Color(0xFFFFD57A), size: 31),
                            SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PASE DE TEMPORADA',
                                  style: TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.w900)),
                                SizedBox(height: 4),
                                Text('Recompensas exclusivas y paquetes de '
                                  'monedas · simulación sin pagos',
                                  style: TextStyle(color: Colors.white70,
                                    fontSize: 11)),
                              ],
                            )),
                            Icon(Icons.chevron_right_rounded,
                              color: Colors.white),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: RepaintBoundary(
                  key: HealthyGuideTargets.shopCategories,
                  child: _categoryFilters())),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      KeyedSubtree(
                        key: HealthyGuideTargets.shopRewards,
                        child: Row(
                        children: [
                          HealthyGlowIcon(
                            icon: Icons.auto_awesome_rounded,
                            color: _green,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
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
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                      ),
                      const SizedBox(height: 14),
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(
                            child: Text('Ya adquiriste todos los artículos de esta categoría o no hay disponibles.'),
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

  void _showCollection(ShopState? state) {
    final today = _rotation;
    final items = shopCatalog.where((item) =>
        isShopItemVisible(item.id)).toList(growable: false);
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true,
      backgroundColor: HealthyAdaptive.surface,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(sheet).height * .78,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Colección completa',
                  style: TextStyle(color: _ink, fontSize: 21,
                    fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text('Los artículos fuera de rotación pueden consultarse, '
                  'pero no comprarse hoy. Lo adquirido permanece en tu inventario.',
                  style: TextStyle(color: _muted, fontSize: 12)),
              ]),
            ),
            Expanded(child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, index) {
                final item = items[index];
                final owned = state?.owns(item.id) ?? false;
                final available = today.contains(item.id);
                return ListTile(
                  key: ValueKey('coleccion-${item.id}'),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    _showFeaturedPreview(item, state);
                  },
                  leading: SizedBox(width: 54, height: 54,
                    child: FittedBox(fit: BoxFit.contain,
                      child: ShopItemArtwork(item: item, size: 54))),
                  title: Text(item.name, maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                  subtitle: Text(owned ? 'En tu colección' :
                    available ? '${_currentPrice(item)} Habit Coins · Disponible hoy' :
                    'Fuera de rotación · Solo vista previa'),
                  trailing: ShopRarityChip(item: item, compact: true),
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  Widget _dailyPanel(ShopState? state) {
    final daily = _rotation;
    final offer = daily.offerId == null ? null : shopItemById(daily.offerId!);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 7, 18, 12),
      child: Semantics(
        label: 'Selección diaria: ${daily.itemIds.length} artículos, '
          '9 fijos, 7 rotativos y 4 especiales. Fecha ${daily.dayKey}.',
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: HealthyAdaptive.surface,
            border: Border.all(color: HealthyAdaptive.border),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.autorenew_rounded, color: _green, size: 23),
                const SizedBox(width: 9),
                Expanded(child: Text('Selección del día',
                  style: TextStyle(color: _ink, fontWeight: FontWeight.w900,
                    fontSize: 17))),
                Text(daily.dayKey, style: TextStyle(color: _muted,
                  fontSize: 11)),
              ]),
              const SizedBox(height: 6),
              Text('9 fijos · 7 rotativos · 4 especiales. '
                'Se renueva a medianoche (UTC−06:00).',
                style: TextStyle(color: _muted, fontSize: 12)),
              if (offer != null && _offerIsAuthoritative) ...[
                const SizedBox(height: 9),
                Row(children: [
                  const Icon(Icons.local_offer_rounded,
                    size: 18, color: Color(0xFFAC7730)),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Oferta del día: ${offer.name} · '
                      '−${ShopDailyRotation.discountPercent} %',
                    maxLines: 2, style: TextStyle(color: _ink,
                      fontWeight: FontWeight.w800, fontSize: 12))),
                ]),
              ],
              const SizedBox(height: 9),
              Align(alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  key: const Key('tienda-coleccion-completa'),
                  onPressed: () => _showCollection(state),
                  icon: const Icon(Icons.collections_bookmark_outlined,
                    size: 18),
                  label: const Text('Ver colección completa'),
                ),
              ),
            ],
          ),
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
              Expanded(
                child: Text(
                  'Tienda',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              GestureDetector(
                key: const Key('tienda-acceso-secreto'),
                behavior: HitTestBehavior.opaque,
                onTap: _trySecretEntry,
                child: Container(
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
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Pista del santuario secreto',
            child: InkWell(
              key: const Key('tienda-pista-titan'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('La inscripción de los siete latidos'),
                  content: const Text('Se dice que una criatura duerme '
                    'detrás de un muro de hierro. Su entrada está '
                    'oculta donde las monedas se cuentan, '
                    'pero el secreto no se compra. '
                    'Escucha siete latidos antes de que pasen cinco segundos.'),
                  actions: [TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Entendido'),
                  )],
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.auto_awesome_rounded,
                  size: 14, color: _muted),
                const SizedBox(width: 6),
                Flexible(child: Text(
                  _secretTaps > 0
                      ? 'El muro responde: $_secretTaps / 7 latidos'
                      : '¿Escuchaste la leyenda de los siete latidos?',
                  style: TextStyle(color: _muted,
                    fontSize: 11, fontStyle: FontStyle.italic),
                )),
                const SizedBox(width: 4),
                Icon(Icons.help_outline_rounded, size: 14, color: _muted),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Convierte tus Habit Coins en recompensas.',
                  style: TextStyle(color: _muted, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: HealthyGuideTargets.shopWardrobe,
                onPressed: _openWardrobe,
                icon: const Icon(Icons.checkroom_rounded, size: 18),
                label: const Text('Armario'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  backgroundColor: HealthyAdaptive.surface,
                  side: BorderSide(color: HealthyAdaptive.border),
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
            backgroundColor: HealthyAdaptive.surface,
            side: BorderSide(
              color: selected ? _green : HealthyAdaptive.border,
            ),
            labelStyle: TextStyle(
              color: selected
                  ? (HealthyAdaptive.isCosmos
                      ? CosmosPalette.background : Colors.white)
                  : _ink,
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
    final price = _currentPrice(item);
    final discount = _offerIsAuthoritative && _rotation.isOffer(item.id);
    final affordable = state != null && state.coins >= price;
    final waiting = _busy == item.id;
    final canBuy = state != null && !owned && affordable && _busy == null;
    final palette = _palette(item.category);

    return HealthyMotionCard(
      key: ValueKey('store-card-${item.id}'),
      child: Container(
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
        boxShadow: HealthyVisualEffects.allowDecorativeShadows
            ? const [BoxShadow(color: Color(0x180F4039), blurRadius: 12, offset: Offset(0, 6))]
            : null,
      ),
      child: Column(
        children: [
          SizedBox(
            // Altura adaptable para rarezas y tamaños de texto accesibles.
            height: (212 * MediaQuery.textScalerOf(context).scale(1))
                .clamp(212.0, 380.0).toDouble(),
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
                                color: HealthyAdaptive.isDark
                                    ? const Color(0xFF273745)
                                    : Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                item.category.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Align(alignment: Alignment.centerLeft,
                              child: ShopRarityChip(item: item, compact: true)),
                            const SizedBox(height: 5),
                            Text(
                              item.name,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
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
                              style: TextStyle(
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
                            child: ShopItemArtwork(item: item, size: 126),
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
            color: HealthyAdaptive.surface.withValues(alpha: 0.93),
            child: Row(
              children: [
                _coinIcon(size: 25),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (discount)
                        Text('${item.price} Habit Coins · −20 %',
                          style: TextStyle(fontSize: 10, color: _muted,
                            decoration: TextDecoration.lineThrough)),
                      Text(
                        item.price == 0 ? 'Gratis' : '$price H. Coins',
                        style: TextStyle(fontSize: 17,
                          fontWeight: FontWeight.w900, color: _ink),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: canBuy ? () => _buy(item) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: HealthyAdaptive.isDark
                        ? const Color(0xFF334652)
                        : const Color(0xFFB6C6C0),
                    disabledForegroundColor: HealthyAdaptive.isDark
                        ? const Color(0xFFCED7DC)
                        : _ink,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: HealthyVisualEffects.duration(
                      context, const Duration(milliseconds: 180)),
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
                      key: ValueKey('$waiting-$owned-$affordable'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (state != null && !owned && !affordable)
            Container(
              width: double.infinity,
              color: HealthyAdaptive.surface,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 9),
              child: Text(
                'Te faltan ${price - state.coins} H. Coins',
                style: TextStyle(fontSize: 11, color: _muted),
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _coinIcon({double size = 24}) =>
      HealthyCoinIcon(size: size);

  // Colores de las recompensas: el modo oscuro utiliza pigmentos profundos,
  // no pasteles luminosos con texto casi blanco.
  List<Color> _palette(String category) {
    if (HealthyAdaptive.isCosmos) {
      return switch (category) {
        'Temas' => const [Color(0xFF352A70), Color(0xFF121B44)],
        'Ropa' || 'Cabeza' => const [
          Color(0xFF392F70), Color(0xFF1C2149)],
        'Especiales' => const [Color(0xFF16465F), Color(0xFF19234D)],
        'OVNI' => const [Color(0xFF2B3874), Color(0xFF182443)],
        'Marcos' || 'Banners' => const [
          Color(0xFF4B285B), Color(0xFF1E2351)],
        _ => const [Color(0xFF233B68), Color(0xFF171F44)],
      };
    }
    if (HealthyAdaptive.isDark) {
      switch (category) {
        case 'Ropa':
        case 'Personalización':
          return const [Color(0xFF403159), Color(0xFF2C253E)];
        case 'Cabeza':
        case 'Avatares':
          return const [Color(0xFF214963), Color(0xFF192F47)];
        case 'Insignias':
          return const [Color(0xFF59472D), Color(0xFF352E28)];
        case 'Accesorios':
          return const [Color(0xFF59354A), Color(0xFF382A3B)];
        case 'OVNI':
          return const [Color(0xFF283C64), Color(0xFF1E2849)];
        case 'Especiales':
          return const [Color(0xFF28503C), Color(0xFF1D3D39)];
        default:
          return const [Color(0xFF285046), Color(0xFF1C383B)];
      }
    }
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
      case 'OVNI':
        return const [Color(0xFFD9E3FF), Color(0xFFA7B9EB)];
      case 'Especiales':
        return const [Color(0xFFC5F3CC), Color(0xFF8ADCB1)];
      default:
        return const [Color(0xFFC7F1E2), Color(0xFF91DCC5)];
    }
  }
}
