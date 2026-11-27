import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'guide_character_pose.dart';

/// Personaje de presentación. Animamos el sprite existente como una pieza
/// completa: no fingimos disponer de huesos o manos articuladas.
class AssistantGuideCharacter extends StatelessWidget {
  const AssistantGuideCharacter({
    super.key,
    required this.pose,
    required this.motion,
    required this.phase,
    required this.stepIndex,
    this.accent = const Color(0xFF63E6BE),
  });

  final GuideCharacterPose pose;
  final bool motion;
  final Animation<double> phase;
  final int stepIndex;
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
          label: 'Mr. Healthy señala el elemento de este paso',
          image: true,
          child: RepaintBoundary(
            child: TweenAnimationBuilder<double>(
              key: ValueKey('healthy-guide-pose-$stepIndex'),
              tween: Tween<double>(begin: motion ? .75 : 1, end: 1),
              duration: motion
                  ? const Duration(milliseconds: 290) : Duration.zero,
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
                final t = motion ? phase.value : 0.0;
                final hover = motion ? -3.5 * math.sin(t * math.pi * 2) : 0.0;
                final lean = motion
                    ? pose.leanRadians +
                        .025 * math.sin(t * math.pi * 2) : 0.0;
                final scale = motion
                    ? 1 + .018 * math.sin(t * math.pi * 2) : 1.0;
                return Transform.translate(
                  offset: Offset(0, hover),
                  child: Transform.rotate(
                    angle: lean,
                    alignment: Alignment.bottomCenter,
                    child: Transform.scale(
                      scale: scale,
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
                  Positioned.fill(
                    bottom: 7,
                    child: Image.asset(
                      'assets/mascot/healthy.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.spa_rounded,
                            size: 58, color: accent),
                    ),
                  ),
                  Positioned(
                    top: 3,
                    right: pose.facesLeft ? null : -3,
                    left: pose.facesLeft ? -3 : null,
                    child: Icon(
                      pose.pointsUp
                          ? (pose.facesLeft
                              ? Icons.north_west_rounded
                              : Icons.north_east_rounded)
                          : (pose.facesLeft
                              ? Icons.south_west_rounded
                              : Icons.south_east_rounded),
                      size: 21,
                      color: accent,
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
