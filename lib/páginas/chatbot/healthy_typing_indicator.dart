import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Indicador accesible para la espera de una respuesta de Mr. Healthy.
class HealthyTypingIndicator extends StatefulWidget {
  const HealthyTypingIndicator({super.key});

  @override
  State<HealthyTypingIndicator> createState() => _HealthyTypingIndicatorState();
}

class _HealthyTypingIndicatorState extends State<HealthyTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: 'Mr. Healthy está escribiendo',
      liveRegion: true,
      child: Container(
        key: const ValueKey('mr-healthy-typing-indicator'),
        margin: const EdgeInsets.only(left: 6, bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('Mr. Healthy está escribiendo',
            style: TextStyle(color: color, fontSize: 12,
              fontWeight: FontWeight.w600)),
          const SizedBox(width: 9),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final phase = (_controller.value - index * .19) * 2 * math.pi;
                final strength = (.5 + .5 * math.sin(phase)).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Transform.translate(
                    offset: Offset(0, -3 * strength),
                    child: Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: .35 + .65 * strength),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ]),
      ),
    );
  }
}
