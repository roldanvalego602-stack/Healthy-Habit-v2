import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Geometría pura para situar a Mr. Healthy sin tapar el objetivo ni la tarjeta.
@immutable
class GuideCharacterPose {
  const GuideCharacterPose({
    required this.position,
    required this.size,
    required this.leanRadians,
    required this.facesLeft,
    required this.pointsUp,
  });

  final Offset position;
  final Size size;
  final double leanRadians;
  final bool facesLeft;
  final bool pointsUp;

  Rect get bounds => position & size;

  static GuideCharacterPose resolve({
    required Size viewport,
    required EdgeInsets safeArea,
    required Rect? target,
    required Rect explanation,
    Size characterSize = const Size(94, 106),
  }) {
    final width = viewport.width;
    final height = viewport.height;
    final safe = Rect.fromLTRB(
      8, safeArea.top + 50, width - 8,
      height - safeArea.bottom - 8,
    );
    final maxX = math.max(safe.left, safe.right - characterSize.width);
    final maxY = math.max(safe.top, safe.bottom - characterSize.height);
    final reference = target ?? Rect.fromCenter(
      center: Offset(width / 2, height * .36),
      width: 2, height: 2,
    );
    final margin = 16.0;
    final candidates = <Offset>[
      Offset(reference.right + margin,
          reference.center.dy - characterSize.height / 2),
      Offset(reference.left - characterSize.width - margin,
          reference.center.dy - characterSize.height / 2),
      Offset(reference.center.dx - characterSize.width / 2,
          reference.bottom + margin),
      Offset(reference.center.dx - characterSize.width / 2,
          reference.top - characterSize.height - margin),
      Offset(width - characterSize.width - 16,
          explanation.top - characterSize.height - margin),
      Offset(16, explanation.top - characterSize.height - margin),
      Offset(width - characterSize.width - 16,
          explanation.bottom + margin),
      Offset(16, explanation.bottom + margin),
    ];
    double score(Offset p) {
      final rect = p & characterSize;
      final targetOverlap = target == null
          ? 0.0 : rect.intersect(target.inflate(9)).size;
      final cardOverlap = rect.intersect(explanation.inflate(6)).size;
      final overlapA = targetOverlap is Size
          ? math.max(0, targetOverlap.width) *
              math.max(0, targetOverlap.height)
          : 0.0;
      final overlapB = math.max(0, cardOverlap.width) *
          math.max(0, cardOverlap.height);
      return overlapA * 7 + overlapB * 9 +
          (rect.center - reference.center).distance * .12;
    }
    Offset? best;
    var bestScore = double.infinity;
    for (final origin in candidates) {
      final candidate = Offset(
        origin.dx.clamp(safe.left, maxX).toDouble(),
        origin.dy.clamp(safe.top, maxY).toDouble(),
      );
      final cost = score(candidate);
      if (cost < bestScore) {
        best = candidate;
        bestScore = cost;
      }
    }
    final position = best ?? Offset(safe.left, safe.top);
    final center = position + Offset(
      characterSize.width / 2, characterSize.height / 2);
    final left = reference.center.dx < center.dx;
    final up = reference.center.dy < center.dy;
    return GuideCharacterPose(
      position: position,
      size: characterSize,
      leanRadians: target == null ? 0 : (left ? -.10 : .10),
      facesLeft: left,
      pointsUp: up,
    );
  }
}
