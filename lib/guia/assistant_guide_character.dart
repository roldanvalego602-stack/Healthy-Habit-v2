import 'package:flutter/material.dart';
import 'guide_character_pose.dart';
import 'guide_gesture.dart';
import 'guide_animated_limbs.dart';

/// Presentador con gestos diferenciados sobre el recurso gráfico existente.
/// La imagen original no tiene articulaciones independientes: movimiento de
/// cuerpo completo + símbolo expresivo superpuesto, no un rig esquelético.
class AssistantGuideCharacter extends StatelessWidget {
  const AssistantGuideCharacter({
    super.key,
    required this.pose,
    required this.motion,
    required this.phase,
    required this.stepIndex,
    this.gesture = HealthyGuideGesture.point,
    this.accent = const Color(0xFF63E6BE),
  });

  final GuideCharacterPose pose;
  final bool motion;
  final Animation<double> phase;
  final int stepIndex;
  final HealthyGuideGesture gesture;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      key: const ValueKey('healthy-guide-character-position'),
      duration: motion ? const Duration(milliseconds: 590) : Duration.zero,
      curve: Curves.easeInOutCubic,
      left: pose.position.dx,
      top: pose.position.dy,
      width: pose.size.width,
      height: pose.size.height,
      child: IgnorePointer(
        child: Semantics(
          label: 'Mr. Healthy ${gesture.semanticAction}',
          image: true,
          child: RepaintBoundary(
            child: TweenAnimationBuilder<double>(
              key: ValueKey('healthy-guide-pose-$stepIndex'),
              tween: Tween<double>(begin: motion ? .78 : 1, end: 1),
              duration: motion
                  ? const Duration(milliseconds: 330) : Duration.zero,
              curve: Curves.easeOutBack,
              builder: (context, arrival, child) => Opacity(
                opacity: arrival.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: arrival,
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
              ),
              child: AnimatedBuilder(
                animation: phase,
                builder: (context, child) {
                  final poseMotion = HealthyGuideMotion.at(
                    gesture,
                    phase.value,
                    1,
                    enabled: motion,
                    direction: pose.facesLeft ? -1 : 1,
                  );
                  return Transform.translate(
                    offset: Offset(0, poseMotion.lift),
                    child: Transform.rotate(
                      angle: poseMotion.rotation,
                      alignment: Alignment.bottomCenter,
                      child: Transform.scale(
                        scale: poseMotion.scale,
                        alignment: Alignment.bottomCenter,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      bottom: 0, left: 7, right: 7, height: 16,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(80),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: .29),
                              blurRadius: 18, spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Brazos independientes por debajo del cuerpo para
                    // ocultar de forma natural sus uniones al sprite.
                    Positioned.fill(
                      bottom: 7,
                      child: GuideAnimatedLimbs(
                        gesture: gesture,
                        phase: phase,
                        motion: motion,
                        facesLeft: pose.facesLeft,
                        accent: accent,
                      ),
                    ),
                    Positioned.fill(
                      bottom: 7,
                      child: Image.asset(
                        'assets/mascot/healthy.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.spa_rounded, size: 58, color: accent),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: pose.facesLeft ? null : -7,
                      left: pose.facesLeft ? -7 : null,
                      child: AnimatedBuilder(
                        animation: phase,
                        builder: (context, _) {
                          final signal = HealthyGuideMotion.at(
                            gesture, phase.value, 1,
                            enabled: motion,
                            direction: pose.facesLeft ? -1 : 1,
                          ).signal;
                          return Transform.scale(
                            scale: signal,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: accent.withValues(alpha: .8),
                                  width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: .22),
                                    blurRadius: 9),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Icon(gesture.symbol, size: 19,
                                  color: accent),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
