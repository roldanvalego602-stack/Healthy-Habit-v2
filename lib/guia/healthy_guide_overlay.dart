import 'dart:async';
import 'package:flutter/material.dart';
import 'guide_controller.dart';
import 'guide_spotlight_painter.dart';
import 'guide_step.dart';

/// Capa interactiva modal. No permite pulsar controles del fondo.
/// La guía antigua permanece disponible para pantallas no migradas.
class HealthyGuideOverlay {
  const HealthyGuideOverlay._();

  static bool _visible = false;

  static Future<void> show(
    BuildContext context, {
    required List<HealthySpotlightStep> steps,
    String sectionTitle = 'Hábitos',
  }) async {
    if (steps.isEmpty || _visible) return;
    _visible = true;
    final completed = Completer<void>();
    final overlay = Overlay.of(context, rootOverlay: true);
    var closed = false;
    late OverlayEntry entry;
    void close() {
      if (closed) return;
      closed = true;
      entry.remove();
      entry.dispose();
      _visible = false;
      completed.complete();
    }

    entry = OverlayEntry(
      builder: (_) => _HealthyGuideScene(
        steps: steps,
        sectionTitle: sectionTitle,
        onClose: close,
      ),
    );
    overlay.insert(entry);
    await completed.future;
  }
}

class _HealthyGuideScene extends StatefulWidget {
  const _HealthyGuideScene({
    required this.steps,
    required this.sectionTitle,
    required this.onClose,
  });

  final List<HealthySpotlightStep> steps;
  final String sectionTitle;
  final VoidCallback onClose;

  @override
  State<_HealthyGuideScene> createState() => _HealthyGuideSceneState();
}

class _HealthyGuideSceneState extends State<_HealthyGuideScene>
    with SingleTickerProviderStateMixin {
  late final HealthyGuideController controller;
  late final AnimationController pulse;
  Rect? targetRect;
  bool resolving = false;

  @override
  void initState() {
    super.initState();
    controller = HealthyGuideController(widget.steps.length)
      ..addListener(_onStepChanged);
    pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1700),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveTarget());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      pulse.stop();
    } else if (!pulse.isAnimating) {
      pulse.repeat();
    }
  }

  @override
  void dispose() {
    pulse.dispose();
    controller
      ..removeListener(_onStepChanged)
      ..dispose();
    super.dispose();
  }

  void _onStepChanged() {
    if (!mounted) return;
    if (!controller.active) {
      widget.onClose();
      return;
    }
    setState(() {
      targetRect = null;
      resolving = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveTarget());
  }

  Future<void> _resolveTarget() async {
    if (!mounted) return;
    final index = controller.index;
    final target = widget.steps[index].targetKey?.currentContext;
    if (target == null) {
      setState(() {
        targetRect = null;
        resolving = false;
      });
      return;
    }
    try {
      await Scrollable.ensureVisible(
        target, duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic, alignment: .28,
      );
    } catch (_) {
      // Elemento desmontado mientras cambia la pantalla.
    }
    if (!mounted || index != controller.index) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || index != controller.index) return;
    final overlayRender = context.findRenderObject();
    final targetRender = widget.steps[index].targetKey?.currentContext
        ?.findRenderObject();
    if (overlayRender is! RenderBox || targetRender is! RenderBox ||
        !overlayRender.hasSize || !targetRender.hasSize ||
        !targetRender.attached) {
      setState(() {
        targetRect = null;
        resolving = false;
      });
      return;
    }
    // Las pantallas están bajo Navigator, no bajo el render de esta escena.
    // Convertimos ambas posiciones globales al espacio local del overlay.
    final topLeft = targetRender.localToGlobal(Offset.zero) -
        overlayRender.localToGlobal(Offset.zero);
    setState(() {
      targetRect = topLeft & targetRender.size;
      resolving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[controller.index];
    final media = MediaQuery.of(context);
    final screen = media.size;
    final safeTop = media.padding.top;
    final safeBottom = media.padding.bottom;
    final theme = Theme.of(context);
    final reduceMotion = media.disableAnimations;
    const accent = Color(0xFF63E6BE);
    final cardWidth = screen.width > 480 ? 420.0 : screen.width - 32;
    final cardHeight = 230.0;
    final belowTarget = targetRect == null ||
        targetRect!.center.dy < screen.height * .47;
    final top = belowTarget
        ? (screen.height - safeBottom - cardHeight - 20)
        : (safeTop + 24);
    final clampedTop = top.clamp(
      safeTop + 8, (screen.height - safeBottom - cardHeight - 8)
          .clamp(safeTop + 8, double.infinity),
    ).toDouble();

    return Material(
      color: Colors.transparent,
      child: Stack(children: [
        const Positioned.fill(
          child: ModalBarrier(dismissible: false, color: Colors.transparent),
        ),
        Positioned.fill(
          child: IgnorePointer(child: AnimatedBuilder(
            animation: pulse,
            builder: (_, __) => CustomPaint(
              painter: HealthyGuideSpotlightPainter(
                target: targetRect,
                phase: reduceMotion ? 0 : pulse.value,
                accent: accent,
              ),
            ),
          )),
        ),
        Positioned(
          top: safeTop + 12, left: 16, right: 16,
          child: Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: accent, size: 19),
            const SizedBox(width: 9),
            Expanded(child: Text('MR. HEALTHY · ${widget.sectionTitle.toUpperCase()}',
              style: const TextStyle(color: Colors.white,
                fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w800))),
            IconButton(
              tooltip: 'Cerrar guía',
              onPressed: widget.onClose,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ]),
        ),
        if (targetRect != null)
          Positioned(
            left: (targetRect!.center.dx - 13)
                .clamp(16.0, screen.width - 42).toDouble(),
            top: belowTarget
                ? (targetRect!.bottom + 14)
                    .clamp(safeTop + 64, clampedTop - 38).toDouble()
                : (targetRect!.top - 44)
                    .clamp(safeTop + 58, screen.height - safeBottom - 48)
                    .toDouble(),
            child: IgnorePointer(child: Icon(
              belowTarget ? Icons.north_rounded : Icons.south_rounded,
              color: accent, size: 28)),
          ),
        AnimatedPositioned(
          duration: reduceMotion
              ? Duration.zero : const Duration(milliseconds: 420),
          curve: Curves.easeInOutCubic,
          top: clampedTop,
          left: (screen.width - cardWidth) / 2,
          width: cardWidth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accent.withValues(alpha: .55), width: 1.2),
              boxShadow: const [BoxShadow(
                color: Color(0x60000000), blurRadius: 30,
                offset: Offset(0, 14))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  AnimatedBuilder(
                    animation: pulse,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, reduceMotion ? 0 : -2 * pulse.value),
                      child: child,
                    ),
                    child: Semantics(
                      label: 'Mr. Healthy, asistente de la guía',
                      child: Image.asset('assets/mascot/healthy.png',
                        width: 48, height: 48, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(step.icon,
                          color: theme.colorScheme.primary, size: 32)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(step.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800))),
                  Text('${controller.index + 1}/${controller.count}',
                    style: theme.textTheme.labelMedium),
                ]),
                const SizedBox(height: 12),
                Text(step.description,
                  maxLines: 4, overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
                if (targetRect == null || resolving) ...[
                  const SizedBox(height: 7),
                  Text('Puedes seguir el recorrido aunque el elemento '
                    'no esté visible.',
                    style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 15),
                LinearProgressIndicator(
                  value: (controller.index + 1) / controller.count,
                  borderRadius: BorderRadius.circular(8), minHeight: 4),
                const SizedBox(height: 10),
                Row(children: [
                  TextButton(
                    onPressed: controller.index == 0
                        ? null : controller.previous,
                    child: const Text('Anterior')),
                  const Spacer(),
                  FilledButton(
                    onPressed: controller.next,
                    child: Text(controller.isLast ? 'Finalizar' : 'Siguiente')),
                ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
