import 'dart:async';
import 'package:flutter/material.dart';
import 'guide_controller.dart';
import 'guide_spotlight_painter.dart';
import 'guide_step.dart';
import 'guide_character_pose.dart';
import 'assistant_guide_character.dart';
import 'guide_pointer.dart';
import '../tema/healthy_visual_mode.dart';

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
    if (!HealthyVisualEffects.enabled(context)) {
      pulse.stop();
      pulse.value = 0;
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
    // Garantiza una medición incluso si el usuario reduce animaciones
    // y no hay un ticker que produzca fotogramas automáticamente.
    WidgetsBinding.instance.scheduleFrame();
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
    final reduceMotion = !HealthyVisualEffects.enabled(context);
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
    final cardBounds = Rect.fromLTWH(
      (screen.width - cardWidth) / 2, clampedTop,
      cardWidth, cardHeight,
    );
    final pose = GuideCharacterPose.resolve(
      viewport: screen,
      safeArea: EdgeInsets.fromLTRB(0, safeTop, 0, safeBottom),
      target: targetRect,
      explanation: cardBounds,
      characterSize: screen.width < 350
          ? const Size(72, 86) : const Size(90, 104),
    );

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
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: pulse,
              builder: (_, __) => CustomPaint(
                painter: GuidePointerPainter(
                  pose: pose,
                  target: targetRect,
                  progress: reduceMotion ? 0 : pulse.value,
                  accent: accent,
                ),
              ),
            ),
          ),
        ),
        AssistantGuideCharacter(
          pose: pose,
          motion: !reduceMotion,
          phase: pulse,
          stepIndex: controller.index,
          accent: accent,
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
                  CircleAvatar(
                    backgroundColor: accent.withValues(alpha: .14),
                    child: Icon(step.icon, color: theme.colorScheme.primary),
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
