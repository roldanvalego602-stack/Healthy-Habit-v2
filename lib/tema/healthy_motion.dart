import 'package:flutter/material.dart';
import 'healthy_visual_mode.dart';
import 'cosmos_theme.dart';
import 'healthy_theme.dart';

/// Entrada breve sin animación infinita ni cambios de tamaño de layout.
class HealthyMotionCard extends StatefulWidget {
  const HealthyMotionCard({
    super.key,
    required this.child,
    this.enableEntrance = true,
    this.enablePress = true,
    this.duration = const Duration(milliseconds: 300),
  });

  final Widget child;
  final bool enableEntrance;
  final bool enablePress;
  final Duration duration;

  @override
  State<HealthyMotionCard> createState() => _HealthyMotionCardState();
}

class _HealthyMotionCardState extends State<HealthyMotionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = HealthyVisualEffects.enabled(context);
    final entrance = enabled && widget.enableEntrance;
    final press = enabled && widget.enablePress;

    final card = Listener(
      onPointerDown: press ? (_) => setState(() => _pressed = true) : null,
      onPointerUp: press ? (_) => setState(() => _pressed = false) : null,
      onPointerCancel: press ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: press && _pressed ? 0.985 : 1,
        duration: enabled ? const Duration(milliseconds: 110) : Duration.zero,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );

    if (!entrance) return CosmosCardShell(child: card);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 12),
          child: child,
        ),
      ),
      child: CosmosCardShell(child: card),
    );
  }
}

/// Pequeño énfasis cuando cambia el número de días; estático en Lite.
class HealthyStreakNumber extends StatelessWidget {
  const HealthyStreakNumber({
    super.key,
    required this.days,
    required this.style,
    this.suffix = ' días',
    this.maxLines,
  });

  final int days;
  final TextStyle style;
  final String suffix;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      '$days$suffix',
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: style,
    );
    if (!HealthyVisualEffects.enabled(context)) return text;
    return TweenAnimationBuilder<double>(
      key: ValueKey('streak-number-$days'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutBack,
      builder: (context, progress, child) => Transform.scale(
        alignment: Alignment.centerLeft,
        scale: 0.93 + 0.07 * progress,
        child: child,
      ),
      child: text,
    );
  }
}

/// Cuenta visualmente hacia un valor ya confirmado. No modifica la cifra real.
class HealthyCountUp extends StatelessWidget {
  const HealthyCountUp({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 750),
  });

  final int value;
  final String prefix;
  final String suffix;
  final TextStyle style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    Text text(int number) => Text(
      '$prefix$number$suffix',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
    if (!HealthyVisualEffects.enabled(context)) return text(value);
    final initial = value - (value > 200 ? 200 : value);
    return TweenAnimationBuilder<double>(
      key: ValueKey('count-up-$prefix-$value-$suffix'),
      tween: Tween<double>(begin: initial.toDouble(), end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => text(progress.round()),
    );
  }
}


/// Consistent lightweight transitions between major tabs.
class HealthyPageSwitch extends StatelessWidget {
  const HealthyPageSwitch({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!HealthyVisualEffects.enabled(context)) return child;
    final cosmos = HealthyAdaptive.isCosmos;
    return AnimatedSwitcher(
      duration: Duration(milliseconds: cosmos ? 360 : 240),
      reverseDuration: Duration(milliseconds: cosmos ? 210 : 130),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (page, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: cosmos ? const Offset(0.055, -0.014)
                : const Offset(0.025, 0.015),
            end: Offset.zero,
          ).animate(animation),
          child: cosmos
              ? ScaleTransition(
                  scale: Tween<double>(begin: .975, end: 1)
                      .animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic)),
                  child: page)
              : page,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey<int>(index),
        child: child,
      ),
    );
  }
}

/// Fade and slide for ordinary push routes, respecting reduced motion.
class HealthyRouteTransitions extends PageTransitionsBuilder {
  const HealthyRouteTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!HealthyVisualEffects.enabled(context)) return child;
    final cosmos = HealthyAdaptive.isCosmos;
    final reveal = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: cosmos ? const Offset(.07, -.025)
              : const Offset(0.035, 0.015),
          end: Offset.zero,
        ).animate(reveal),
        child: cosmos
            ? ScaleTransition(
                scale: Tween<double>(begin: .96, end: 1).animate(reveal),
                child: child)
            : child,
      ),
    );
  }
}
