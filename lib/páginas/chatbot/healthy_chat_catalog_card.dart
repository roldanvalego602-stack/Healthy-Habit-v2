import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../tema/healthy_theme.dart';
import '../../tema/healthy_visual_mode.dart';
import '../catalogo/datos/catalogo_datos.dart';
import '../catalogo/modelos/catalogo_item.dart';

/// Vista compacta de una ficha existente del catálogo.
/// No concede XP ni altera hábitos ni interpreta datos educativos como consejos clínicos.
class HealthyChatCatalogCard extends StatelessWidget {
  const HealthyChatCatalogCard({
    super.key,
    required this.itemId,
    required this.onOpen,
  });

  final String itemId;
  final ValueChanged<CatalogoItem> onOpen;

  static CatalogoItem? findById(String id) {
    for (final item in [
      ...alimentosCatalogo,
      ...ejerciciosCatalogo,
      ...consejosCatalogo,
    ]) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final item = findById(itemId);
    if (item == null) {
      return const Text('Esta ficha ya no está disponible en el catálogo.');
    }
    final animate = HealthyVisualEffects.enabled(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey('catalog-card-${item.id}'),
      tween: Tween(begin: animate ? 0.0 : 1.0, end: 1.0),
      duration: HealthyVisualEffects.duration(
        context, const Duration(milliseconds: 350)),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - progress) * 9),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: HealthyAdaptive.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: HealthyAdaptive.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 124,
                child: item.imagen.toLowerCase().endsWith('.svg')
                    ? SvgPicture.asset(
                        item.imagen,
                        semanticsLabel: 'Ilustración de ${item.titulo}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            _fallback(context),
                      )
                    : Image.asset(
                        item.imagen,
                        key: ValueKey('catalog-photo-${item.id}'),
                        semanticLabel: 'Fotografía de ${item.titulo}',
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (context, error, stack) =>
                            _fallback(context),
                      ),
              ),
            ),
            const SizedBox(height: 9),
            Text(item.titulo,
              style: TextStyle(
                color: HealthyAdaptive.text,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              )),
            const SizedBox(height: 3),
            Text('${item.categoria} · ${item.dificultad}',
              style: TextStyle(
                color: HealthyAdaptive.muted,
                fontSize: 11,
              )),
            if (item.beneficios.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(item.beneficios.first,
                maxLines: 3, overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: HealthyAdaptive.text,
                  fontSize: 12,
                )),
            ],
            const SizedBox(height: 6),
            Text('Fuente: ${item.fuente}',
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: HealthyAdaptive.muted,
                fontSize: 10,
              )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: ValueKey('catalog-open-${item.id}'),
              onPressed: () => onOpen(item),
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text('Ver ficha completa'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) => ColoredBox(
    color: HealthyAdaptive.mint,
    child: Center(
      child: Icon(Icons.menu_book_outlined,
        size: 40, color: HealthyAdaptive.accent),
    ),
  );
}
