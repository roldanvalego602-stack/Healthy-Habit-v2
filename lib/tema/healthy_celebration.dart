import 'package:flutter/material.dart';
import 'healthy_visual_mode.dart';
import 'healthy_theme.dart';
import 'cosmos_theme.dart';
import 'cosmos_interaction_fx.dart';

/// Feedback exclusivamente visual: jamás concede XP, monedas ni desbloqueos.
class HealthyCelebration {
  HealthyCelebration._();

  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
    IconData icon = Icons.auto_awesome_rounded,
    Color? color,
    CosmosEffect effect = CosmosEffect.reward,
  }) {
    if (effect == CosmosEffect.level) CosmosLevelOverlay.show(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 2600),
      backgroundColor: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: color ?? Theme.of(context).colorScheme.primary),
      ),
      content: HealthyCelebrationBanner(
        effect: effect,
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
      ),
    ));
  }
}

class HealthyCelebrationBanner extends StatelessWidget {
  const HealthyCelebrationBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.color,
    this.effect = CosmosEffect.reward,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color? color;
  final CosmosEffect effect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;
    final body = Row(
      children: [
        HealthyAdaptive.isCosmos
            ? CosmosOrbitingIcon(icon: icon, size: 32)
            : Icon(icon, color: accent, size: 32),
        const SizedBox(width: 12),
        Expanded(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: scheme.onSurface,
              fontWeight: FontWeight.w800, fontSize: 15)),
            Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant,
              fontSize: 12)),
          ],
        )),
      ],
    );

    final decorated = HealthyAdaptive.isCosmos
        ? SizedBox(
            height: 75,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CosmosParticleBurst(effect: effect),
                Align(alignment: Alignment.centerLeft, child: body),
              ],
            ),
          )
        : body;
    if (!HealthyVisualEffects.enabled(context)) return decorated;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.scale(
          alignment: Alignment.centerLeft,
          scale: 0.88 + 0.12 * value,
          child: child,
        ),
      ),
      child: decorated,
    );
  }
}
