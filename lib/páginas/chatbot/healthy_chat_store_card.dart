import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../tema/healthy_theme.dart';
import '../../tema/healthy_coin.dart';
import '../../tema/healthy_visual_mode.dart';
import '../tienda/shop_service.dart';

/// Tienda dentro de la conversación. Todo canje/equipamiento pasa por ShopService.
class HealthyChatStoreCard extends StatefulWidget {
  const HealthyChatStoreCard({
    super.key,
    this.initialItemId = '',
    required this.onCommitted,
    this.stateStream,
    this.purchaseAction,
    this.equipAction,
  });

  final String initialItemId;
  final ValueChanged<String> onCommitted;
  // Inyección opcional para probar autorización sin llamar a Firebase.
  final Stream<ShopState>? stateStream;
  final Future<void> Function(ShopItem item)? purchaseAction;
  final Future<void> Function(ShopItem item, {required bool remove})?
      equipAction;

  @override
  State<HealthyChatStoreCard> createState() => _HealthyChatStoreCardState();
}

class _HealthyChatStoreCardState extends State<HealthyChatStoreCard> {
  String? _itemId;
  bool _working = false;
  late Stream<ShopState> _stateStream;

  Stream<ShopState> _shopStream() {
    if (widget.stateStream != null) return widget.stateStream!;
    if (FirebaseAuth.instance.currentUser == null) {
      return Stream<ShopState>.error(
        const ShopException('Inicia sesión para consultar tu tienda.'));
    }
    return ShopService.instance.watch();
  }

  @override
  void initState() {
    super.initState();
    _itemId = isShopItemVisible(widget.initialItemId)
        ? shopItemById(widget.initialItemId)?.id : null;
    _stateStream = _shopStream();
  }

  @override
  void didUpdateWidget(covariant HealthyChatStoreCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stateStream != widget.stateStream) {
      _stateStream = _shopStream();
    }
    if (oldWidget.initialItemId != widget.initialItemId) {
      _itemId = isShopItemVisible(widget.initialItemId)
          ? shopItemById(widget.initialItemId)?.id : null;
    }
  }

  Future<void> _chooseItem() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: HealthyAdaptive.surface,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .65,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Catálogo de recompensas',
                style: TextStyle(fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: HealthyAdaptive.text)),
            ),
            Expanded(child: ListView.builder(
              itemCount: availableShopItems(null).length,
              itemBuilder: (_, index) {
                final item = availableShopItems(null)[index];
                return ListTile(
                  key: ValueKey('chat-shop-option-${item.id}'),
                  leading: Text(item.emoji, style: const TextStyle(fontSize: 27)),
                  title: Text(item.name),
                  subtitle: Text(item.category),
                  trailing: HealthyCoinAmount(
                    amount: '${item.price}', size: 18,
                    style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700),
                  ),
                  onTap: () => Navigator.pop(sheetContext, item.id),
                );
              },
            )),
          ]),
        ),
      ),
    );
    if (mounted && selected != null) {
      setState(() => _itemId = selected);
    }
  }

  Future<void> _commit(ShopItem item, ShopState state, {
    required bool purchase,
    bool remove = false,
  }) async {
    if (_working) return;
    final title = purchase ? '¿Canjear ${item.name}?'
        : remove ? '¿Quitar ${item.name}?' : '¿Equipar ${item.name}?';
    final details = purchase
        ? 'El artículo cuesta ${item.price} Habit Coins. '
          'Tu saldo actual es ${state.coins}. '
          'La compra solo se hará si confirmas.'
        : remove ? 'Se quitará de tu apariencia, pero seguirá en tu colección.'
        : 'Se equipará en el espacio ${item.slot ?? 'indefinido'}, '
          'reemplazando el artículo anterior en ese espacio.';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(details),
            if (purchase) ...[
              const SizedBox(height: 10),
              const Text('Costo del artículo:'),
              HealthyCoinAmount(amount: '${item.price}', size: 22,
                suffix: ' Habit Coins'),
              const SizedBox(height: 5),
              const Text('Saldo actual:'),
              HealthyCoinAmount(amount: '${state.coins}', size: 22,
                suffix: ' Habit Coins'),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar')),
          FilledButton(
            key: const Key('chat-store-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(purchase ? 'Confirmar canje' :
                remove ? 'Quitar artículo' : 'Equipar'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => _working = true);
    try {
      if (purchase) {
        await (widget.purchaseAction?.call(item) ??
            ShopService.instance.buy(item));
      } else {
        await (widget.equipAction?.call(item, remove: remove) ??
            ShopService.instance.equip(item, remove: remove));
      }
      if (!mounted) return;
      widget.onCommitted(purchase
          ? 'Canje confirmado: ${item.name} se agregó a tu colección.'
          : remove
              ? 'Quitaste ${item.name} de tu apariencia; sigue en tu colección.'
              : 'Equipaste ${item.name} en tu apariencia.');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error is ShopException ? error.message
            : 'No fue posible completar la operación. Revisa tu conexión.'),
      ));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _itemId == null ? null : shopItemById(_itemId!);
    final motion = HealthyVisualEffects.enabled(context);
    return Container(
      key: const Key('mr-healthy-shop-card'),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: HealthyAdaptive.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: HealthyAdaptive.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AnimatedSize(
          duration: HealthyVisualEffects.enabled(context)
              ? const Duration(milliseconds: 240)
              : const Duration(milliseconds: 1),
          curve: Curves.easeOutCubic,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Icon(Icons.storefront_rounded, color: HealthyAdaptive.accent),
                const SizedBox(width: 8),
                Expanded(child: Text('Tienda de Mr. Healthy',
                  style: TextStyle(color: HealthyAdaptive.text,
                    fontSize: 14, fontWeight: FontWeight.w900))),
              ]),
              const SizedBox(height: 8),
              StreamBuilder<ShopState>(
                stream: _stateStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      snapshot.error is ShopException
                          ? snapshot.error.toString()
                          : 'No pude consultar tu saldo e inventario.',
                      style: TextStyle(
                        color: HealthyAdaptive.muted, fontSize: 12),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final state = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Text('Saldo: ', style: TextStyle(
                          color: HealthyAdaptive.muted, fontSize: 12)),
                        HealthyCoinAmount(amount: '${state.coins}', size: 19,
                          suffix: ' HC',
                          style: TextStyle(color: HealthyAdaptive.text,
                            fontWeight: FontWeight.w800, fontSize: 12)),
                      ]),
                      const SizedBox(height: 10),
                      if (item != null) ...[
                        Row(children: [
                          Text(item.emoji, style: const TextStyle(fontSize: 36)),
                          const SizedBox(width: 8),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: TextStyle(
                                color: HealthyAdaptive.text,
                                fontSize: 14, fontWeight: FontWeight.w800)),
                              Text(item.category,
                                style: TextStyle(color: HealthyAdaptive.muted,
                                  fontSize: 11)),
                              HealthyCoinAmount(amount: '${item.price}',
                                size: 16, suffix: ' HC',
                                style: TextStyle(
                                  color: HealthyAdaptive.text, fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                            ],
                          )),
                        ]),
                        const SizedBox(height: 6),
                        Text(item.description, style: TextStyle(
                          color: HealthyAdaptive.muted, fontSize: 11)),
                        const SizedBox(height: 11),
                        AnimatedSwitcher(
                          duration: HealthyVisualEffects.duration(
                            context, const Duration(milliseconds: 280)),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: _working
                            ? const Center(
                                key: ValueKey('shop-action-working'),
                                child: CircularProgressIndicator())
                            : !state.owns(item.id)
                                ? FilledButton.icon(
                                    key: const Key('chat-shop-purchase'),
                                    onPressed: state.coins >= item.price
                                        ? () => _commit(
                                            item, state, purchase: true)
                                        : null,
                                    icon: const Icon(
                                      Icons.shopping_bag_outlined),
                                    label: Text(state.coins >= item.price
                                        ? 'Canjear por ${item.price} HC'
                                        : 'Saldo insuficiente'),
                                  )
                                : item.slot != null
                                    ? FilledButton.icon(
                                        key: const Key('chat-shop-equip'),
                                        onPressed: () => _commit(
                                          item, state, purchase: false,
                                          remove: state.equippedItem(item.id)),
                                        icon: Icon(state.equippedItem(item.id)
                                            ? Icons.check_circle_outline
                                            : Icons.checkroom_outlined),
                                        label: Text(
                                          state.equippedItem(item.id)
                                            ? 'Quitar de mi apariencia'
                                            : 'Equipar'),
                                      )
                                    : Text('✓ Ya está en tu colección',
                                        key: const ValueKey(
                                          'shop-action-owned'),
                                        style: TextStyle(
                                          color: HealthyAdaptive.accent,
                                          fontWeight: FontWeight.w800)),
                        ),
                      ],
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        key: const Key('chat-shop-select'),
                        onPressed: _working ? null : _chooseItem,
                        icon: const Icon(Icons.grid_view_rounded),
                        label: Text(item == null
                            ? 'Elegir un artículo' : 'Ver otros artículos'),
                      ),
                    ],
                  );
                },
              ),
              if (motion) const SizedBox(height: 1),
            ],
          ),
        ),
      ),
    );
  }
}
