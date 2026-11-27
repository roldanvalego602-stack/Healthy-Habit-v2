import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Fotograma inerte de un widget real; no contiene controles interactivos.
/// Solo se muestra mientras el recorrido está activo.
class GuideExtraction extends StatelessWidget {
  const GuideExtraction({
    super.key,
    required this.png,
    required this.source,
    required this.destination,
    required this.expanded,
    required this.motion,
    this.accent = const Color(0xFF63E6BE),
  });

  final Uint8List png;
  final Rect source;
  final Rect destination;
  final bool expanded;
  final bool motion;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final bounds = expanded ? destination : source;
    return AnimatedPositioned(
      key: const ValueKey('guide-extraction-position'),
      duration: motion ? const Duration(milliseconds: 530) : Duration.zero,
      curve: Curves.easeInOutCubic,
      top: bounds.top,
      left: bounds.left,
      width: bounds.width,
      height: bounds.height,
      child: IgnorePointer(
        child: Semantics(
          label: 'Vista ampliada, solo lectura, del elemento señalado',
          image: true,
          child: AnimatedScale(
            scale: expanded ? 1 : .98,
            duration: motion
                ? const Duration(milliseconds: 530) : Duration.zero,
            curve: Curves.easeInOutCubic,
            child: RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: accent.withValues(alpha: .8),
                    width: 2),
                  boxShadow: [
                    BoxShadow(color: accent.withValues(alpha: .24),
                      blurRadius: expanded ? 28 : 5, spreadRadius: 2),
                    if (expanded) const BoxShadow(
                      color: Color(0x88000000), blurRadius: 24,
                      offset: Offset(0, 12)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(
                    png,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Calcula una zona para ampliar, sin tapar la tarjeta explicativa.
Rect? guideExtractionDestination({
  required Size viewport,
  required EdgeInsets safeArea,
  required Rect explanation,
}) {
  final topStart = safeArea.top + 75;
  final topSpace = explanation.top - topStart - 12;
  final bottomStart = explanation.bottom + 12;
  final bottomSpace = viewport.height - safeArea.bottom - bottomStart - 12;
  final useTop = topSpace >= bottomSpace;
  final available = useTop ? topSpace : bottomSpace;
  if (available < 118 || viewport.width < 200) return null;

  final width = (viewport.width - 40).clamp(160.0, 420.0).toDouble();
  final height = available.clamp(118.0, 300.0).toDouble();
  final left = (viewport.width - width) / 2;
  final top = useTop
      ? topStart + (available - height) / 2
      : bottomStart + (available - height) / 2;
  return Rect.fromLTWH(left, top, width, height);
}
