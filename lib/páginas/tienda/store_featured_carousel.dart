import 'package:flutter/material.dart';
import '../../tema/healthy_theme.dart';
import '../../tema/healthy_coin.dart';
import '../../tema/healthy_visual_mode.dart';
import '../../tema/healthy_float.dart';
import 'shop_service.dart';
import 'shop_item_artwork.dart';

/// Destacados del catálogo real. La lista se puede ampliar sin tocar el carrusel.
const featuredShopItemIds = <String>[
  'leaf_crown',
  'avatar_snowman',
  'frame_emerald',
  'skin_christmas_cartoon',
];

/// Un carrusel manual: no se desplaza solo, conserva el catálogo tradicional
/// y no ejecuta compras. La selección abre una vista previa.
class StoreFeaturedCarousel extends StatefulWidget {
  const StoreFeaturedCarousel({
    super.key,
    required this.items,
    required this.onSelected,
    this.shopState,
  });

  final List<ShopItem> items;
  final ShopState? shopState;
  final ValueChanged<ShopItem> onSelected;

  @override
  State<StoreFeaturedCarousel> createState() => _StoreFeaturedCarouselState();
}

class _StoreFeaturedCarouselState extends State<StoreFeaturedCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.89);
  }

  @override
  void didUpdateWidget(covariant StoreFeaturedCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.items.length && widget.items.isNotEmpty) {
      _index = widget.items.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(_index);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.items.length || !_controller.hasClients) {
      return;
    }
    if (HealthyVisualEffects.enabled(context)) {
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _controller.jumpToPage(index);
    }
  }

  List<Color> _gradient(String category, bool dark) {
    if (dark) {
      switch (category) {
        case 'Cabeza':
          return const [Color(0xFF4A3A60), Color(0xFF242F48)];
        case 'Especiales':
          return const [Color(0xFF285E50), Color(0xFF203747)];
        case 'Avatares':
          return const [Color(0xFF285276), Color(0xFF26364C)];
        default:
          return const [Color(0xFF3A4D67), Color(0xFF253B46)];
      }
    }
    switch (category) {
      case 'Cabeza':
        return const [Color(0xFFF3E4FC), Color(0xFFE6D8F7)];
      case 'Especiales':
        return const [Color(0xFFCEF4E3), Color(0xFFB4E3DB)];
      case 'Avatares':
        return const [Color(0xFFD8F0FF), Color(0xFFBBDDED)];
      default:
        return const [Color(0xFFE4F4EA), Color(0xFFCEEADE)];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? const Color(0xFFF5F7FA) : const Color(0xFF183344);
    final muted = dark ? const Color(0xFFD1DDE3) : const Color(0xFF4D6470);
    final motion = HealthyVisualEffects.enabled(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 9, 18, 12),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: HealthyAdaptive.accent),
              const SizedBox(width: 9),
              Expanded(
                child: Text('Artículos destacados',
                  style: TextStyle(color: HealthyAdaptive.text,
                    fontSize: 19, fontWeight: FontWeight.w900)),
              ),
              Text('Desliza', style: TextStyle(
                color: HealthyAdaptive.muted, fontSize: 12)),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          child: PageView.builder(
            key: const Key('tienda-carrusel-destacados'),
            controller: _controller,
            itemCount: widget.items.length,
            padEnds: true,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final owned = widget.shopState?.owns(item.id) ?? false;
              final colors = _gradient(item.category, dark);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                child: AnimatedScale(
                  duration: motion
                      ? const Duration(milliseconds: 260)
                      : Duration.zero,
                  curve: Curves.easeOutCubic,
                  scale: motion && index != _index ? 0.965 : 1,
                  child: Material(
                    elevation: motion && index == _index ? 4 : 0,
                    shadowColor: Colors.black.withValues(alpha: 0.17),
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(23),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey('destacado-${item.id}'),
                      onTap: () => widget.onSelected(item),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: colors,
                          ),
                          borderRadius: BorderRadius.circular(23),
                          border: Border.all(
                            color: dark
                                ? const Color(0xFF657887)
                                : const Color(0xFFBBCDCB),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(17, 14, 17, 13),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: dark
                                        ? Colors.white.withValues(alpha: 0.13)
                                        : Colors.white.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 5),
                                  child: Text(
                                    owned ? 'EN TU COLECCIÓN' : 'DESTACADO',
                                    style: TextStyle(color: fg, fontSize: 10,
                                      fontWeight: FontWeight.w900),
                                  ),
                                ),
                                const Spacer(),
                                HealthyGlowIcon(
                                  icon: Icons.stars_rounded,
                                  color: dark
                                      ? const Color(0xFFFFDB91)
                                      : const Color(0xFF987227),
                                  size: 22,
                                  float: index == _index,
                                ),
                              ]),
                              const SizedBox(height: 9),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: fg,
                                              fontSize: 21,
                                              fontWeight: FontWeight.w900,
                                              height: 1.1)),
                                          const SizedBox(height: 7),
                                          Text(item.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: muted,
                                              fontSize: 11.5, height: 1.25)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: HealthyFloat(
                                        enabled: index == _index,
                                        distance: 6,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: ShopItemArtwork(item: item, size: 105),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(children: [
                                const HealthyCoinIcon(size: 20),
                                const SizedBox(width: 5),
                                Expanded(child: Text(
                                  item.price == 0 ? 'Gratis'
                                      : '${item.price} Habit Coins',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: fg, fontSize: 14,
                                    fontWeight: FontWeight.w900),
                                )),
                                const SizedBox(width: 7),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: dark ? const Color(0xFF364D53)
                                        : Colors.white.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Ver', style: TextStyle(color: fg,
                                        fontSize: 12, fontWeight: FontWeight.w800)),
                                      const SizedBox(width: 3),
                                      Icon(Icons.arrow_forward_rounded,
                                        color: fg, size: 14),
                                    ],
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 9),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Artículo anterior',
              onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
              icon: const Icon(Icons.chevron_left_rounded),
              color: HealthyAdaptive.text,
              iconSize: 21,
              visualDensity: VisualDensity.compact,
            ),
            ...List.generate(widget.items.length, (index) => Semantics(
              label: 'Ir a destacado ${index + 1} de ${widget.items.length}',
              button: true,
              child: InkWell(
                key: ValueKey('indicador-destacado-$index'),
                onTap: () => _goTo(index),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: motion
                      ? const Duration(milliseconds: 240)
                      : Duration.zero,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _index ? 21 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _index
                        ? HealthyAdaptive.accent
                        : HealthyAdaptive.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )),
            IconButton(
              tooltip: 'Artículo siguiente',
              onPressed: _index < widget.items.length - 1
                  ? () => _goTo(_index + 1) : null,
              icon: const Icon(Icons.chevron_right_rounded),
              color: HealthyAdaptive.text,
              iconSize: 21,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
