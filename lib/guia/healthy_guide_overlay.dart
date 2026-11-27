import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'guide_controller.dart';
import 'guide_spotlight_painter.dart';
import 'guide_step.dart';
import 'guide_character_pose.dart';
import 'assistant_guide_character.dart';
import 'guide_pointer.dart';
import 'guide_extraction.dart';
import 'guide_fx_theme.dart';
import 'guide_choreography.dart';
import '../tema/healthy_visual_mode.dart';

/// Capturador inyectable para tests; la app usa toImage() por defecto.
typedef HealthyGuideCapture = Future<Uint8List?> Function(
    RenderRepaintBoundary boundary);

/// Capa interactiva modal. No permite pulsar controles del fondo.
/// La guía antigua permanece disponible para pantallas no migradas.
class HealthyGuideOverlay {
  const HealthyGuideOverlay._();

  static bool _visible = false;

  static Future<void> show(
    BuildContext context, {
    required List<HealthySpotlightStep> steps,
    String sectionTitle = 'Hábitos',
    HealthyGuideCapture? capture,
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
        capture: capture,
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
    required this.capture,
    required this.onClose,
  });

  final List<HealthySpotlightStep> steps;
  final String sectionTitle;
  final HealthyGuideCapture? capture;
  final VoidCallback onClose;

  @override
  State<_HealthyGuideScene> createState() => _HealthyGuideSceneState();
}

class _HealthyGuideSceneState extends State<_HealthyGuideScene>
    with TickerProviderStateMixin {
  late final HealthyGuideController controller;
  late final AnimationController pulse;
  late final AnimationController _arrival;
  Rect? targetRect;
  bool resolving = false;
  bool _navigating = false;
  Uint8List? _previewPng;
  Rect? _previewSource;
  bool _previewExpanded = false;

  @override
  void initState() {
    super.initState();
    controller = HealthyGuideController(widget.steps.length)
      ..addListener(_onStepChanged);
    pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1700),
    );
    _arrival = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 540),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveTarget());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!HealthyVisualEffects.enabled(context)) {
      pulse.stop();
      pulse.value = 0;
      _arrival.stop();
      _arrival.value = 1;
    } else {
      if (!pulse.isAnimating) pulse.repeat();
      if (_arrival.value == 0 && !_arrival.isAnimating) {
        _arrival.forward();
      }
    }
  }

  @override
  void dispose() {
    pulse.dispose();
    _arrival.dispose();
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
      _previewPng = null;
      _previewSource = null;
      _previewExpanded = false;
    });
    if (HealthyVisualEffects.enabled(context)) {
      _arrival.forward(from: 0);
    } else {
      _arrival.value = 1;
    }
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
    final measured = topLeft & targetRender.size;
    setState(() {
      targetRect = measured;
      resolving = false;
    });
    if (widget.steps[index].extract && targetRender is RenderRepaintBoundary) {
      await _capture(targetRender, measured, index);
    }
  }

  Future<void> _capture(
      RenderRepaintBoundary boundary, Rect origin, int index) async {
    if (!mounted || index != controller.index) return;
    ui.Image? image;
    try {
      Uint8List? png;
      if (widget.capture != null) {
        png = await widget.capture!(boundary);
      } else {
        final area = math.max(1.0,
            boundary.size.width * boundary.size.height);
        final pixelRatio = math.min(1.5, math.sqrt(1100000 / area));
        image = await boundary.toImage(pixelRatio: pixelRatio);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes != null) {
          png = bytes.buffer.asUint8List(
            bytes.offsetInBytes, bytes.lengthInBytes);
        }
      }
      if (png == null || !mounted || index != controller.index) return;
      setState(() {
        _previewPng = png;
        _previewSource = origin;
        _previewExpanded = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && index == controller.index && _previewPng != null) {
          setState(() => _previewExpanded = true);
        }
      });
    } catch (_) {
      // Fallback: spotlight y explicación sin fotografía ni fallo del tour.
    } finally {
      image?.dispose();
    }
  }

  Future<void> _navigate({required bool forward}) async {
    if (_navigating || !mounted) return;
    _navigating = true;
    if (_previewPng != null && _previewExpanded) {
      setState(() => _previewExpanded = false);
      if (HealthyVisualEffects.enabled(context)) {
        await Future<void>.delayed(const Duration(milliseconds: 280));
      }
    }
    if (mounted) {
      if (forward) {
        controller.next();
      } else {
        controller.previous();
      }
    }
    _navigating = false;
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
    final fx = GuideFxTheme.current();
    final accent = fx.accent;
    final cardWidth = screen.width > 480 ? 420.0 : screen.width - 32;
    final cardHeight = 260.0;
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
    final extractedDestination = guideExtractionDestination(
      viewport: screen,
      safeArea: EdgeInsets.fromLTRB(0, safeTop, 0, safeBottom),
      explanation: cardBounds,
    );
    final highlightedRect = _previewExpanded &&
            _previewPng != null && extractedDestination != null
        ? extractedDestination : targetRect;
    final pose = GuideCharacterPose.resolve(
      viewport: screen,
      safeArea: EdgeInsets.fromLTRB(0, safeTop, 0, safeBottom),
      target: highlightedRect,
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
                target: highlightedRect,
                phase: reduceMotion ? 0 : pulse.value,
                accent: accent,
              ),
            ),
          )),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([pulse, _arrival]),
                builder: (_, __) => CustomPaint(
                  painter: GuideChoreographyPainter(
                    target: highlightedRect,
                    phase: reduceMotion ? 0 : pulse.value,
                    intro: reduceMotion ? 1 : _arrival.value,
                    fx: fx,
                    motion: !reduceMotion,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: safeTop + 12, left: 16, right: 16,
          child: Row(children: [
            Icon(Icons.auto_awesome_rounded, color: accent, size: 19),
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
            child: TweenAnimationBuilder<Offset>(
              tween: Tween<Offset>(end: pose.position),
              duration: reduceMotion
                  ? Duration.zero : const Duration(milliseconds: 590),
              curve: Curves.easeInOutCubic,
              builder: (_, pointerPosition, __) => AnimatedBuilder(
                animation: pulse,
                builder: (_, __) => CustomPaint(
                  painter: GuidePointerPainter(
                    pose: GuideCharacterPose(
                      position: pointerPosition,
                      size: pose.size,
                      leanRadians: pose.leanRadians,
                      facesLeft: pose.facesLeft,
                      pointsUp: pose.pointsUp,
                    ),
                    target: highlightedRect,
                    progress: reduceMotion ? 0 : pulse.value,
                    accent: accent,
                  ),
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
        if (_previewPng != null && _previewSource != null &&
            extractedDestination != null)
          GuideExtraction(
            png: _previewPng!,
            source: _previewSource!,
            destination: extractedDestination,
            expanded: _previewExpanded,
            motion: !reduceMotion,
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
              color: fx.background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accent.withValues(alpha: .68), width: 1.2),
              boxShadow: [
                const BoxShadow(
                  color: Color(0x60000000), blurRadius: 30,
                  offset: Offset(0, 14)),
                if (fx.cosmos && !reduceMotion)
                  BoxShadow(
                    color: fx.secondary.withValues(alpha: .18),
                    blurRadius: 28, spreadRadius: 1),
              ],
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
                AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero : const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, .09),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    step.description,
                    key: ValueKey('guide-explanation-${controller.index}'),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ),
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
                        ? null : () => _navigate(forward: false),
                    child: const Text('Anterior')),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => _navigate(forward: true),
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
