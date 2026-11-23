import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Matemática pura que mantiene sincronizados la vista previa y el JPEG
/// exportado. Trabaja con el mismo BoxFit.cover centrado del editor.
class ProfilePhotoCropGeometry {
  const ProfilePhotoCropGeometry._();

  static Size baseSize({
    required int imageWidth,
    required int imageHeight,
    required double viewport,
  }) {
    assert(imageWidth > 0 && imageHeight > 0 && viewport > 0);
    final aspect = imageWidth / imageHeight;
    return aspect >= 1
        ? Size(viewport * aspect, viewport)
        : Size(viewport, viewport / aspect);
  }

  static Offset clampOffset({
    required Offset offset,
    required Size base,
    required double zoom,
    required double viewport,
  }) {
    final maxX = math.max(0.0, (base.width * zoom - viewport) / 2);
    final maxY = math.max(0.0, (base.height * zoom - viewport) / 2);
    return Offset(
      offset.dx.clamp(-maxX, maxX).toDouble(),
      offset.dy.clamp(-maxY, maxY).toDouble(),
    );
  }

  static Rect sourceRect({
    required int imageWidth,
    required int imageHeight,
    required double viewport,
    required double zoom,
    required Offset offset,
  }) {
    if (imageWidth <= 0 || imageHeight <= 0 ||
        viewport <= 0 || zoom < 1 || !zoom.isFinite) {
      throw ArgumentError('Dimensiones o escala inválidas.');
    }
    final base = baseSize(
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      viewport: viewport,
    );
    final center = clampOffset(
      offset: offset,
      base: base,
      zoom: zoom,
      viewport: viewport,
    );
    final displayWidth = base.width * zoom;
    final displayHeight = base.height * zoom;
    final side = (viewport * imageWidth / displayWidth)
        .round().clamp(1, math.min(imageWidth, imageHeight));
    final left = (((displayWidth - viewport) / 2 - center.dx) *
            imageWidth / displayWidth)
        .round().clamp(0, imageWidth - side);
    final top = (((displayHeight - viewport) / 2 - center.dy) *
            imageHeight / displayHeight)
        .round().clamp(0, imageHeight - side);
    return Rect.fromLTWH(
      left.toDouble(), top.toDouble(), side.toDouble(), side.toDouble(),
    );
  }
}
