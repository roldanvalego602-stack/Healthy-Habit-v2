import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'healthy_local_image_recognition.dart';

class HealthyFoodModelStatus {
  const HealthyFoodModelStatus({required this.installed,
    required this.title});

  final bool installed;
  final String title;
}

class HealthyFoodModelAnalysis {
  const HealthyFoodModelAnalysis({required this.labels,
    required this.model});

  final List<HealthyDetectedLabel> labels;
  final String model;
}

/// Modelo de 65 clases ejecutado mediante ONNX Runtime en Android.
/// Descarga solamente los pesos (opt-in); NUNCA envía fotografías.
class HealthyFoodModelService {
  const HealthyFoodModelService();

  static const _channel = MethodChannel('healthy_habit/food_model');

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<HealthyFoodModelStatus> status() async {
    if (!supported) {
      return const HealthyFoodModelStatus(installed: false,
        title: 'Modelo disponible solo en Android');
    }
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
          'status');
      return HealthyFoodModelStatus(
        installed: result?['installed'] == true,
        title: result?['title']?.toString() ??
            'SekoKuva Mobile 423K',
      );
    } on PlatformException {
      return const HealthyFoodModelStatus(
        installed: false, title: 'Motor no instalado');
    } on MissingPluginException {
      return const HealthyFoodModelStatus(
        installed: false, title: 'Motor no disponible');
    }
  }

  Future<HealthyFoodModelStatus> install() async {
    if (!supported) {
      throw UnsupportedError('El modelo solo funciona en Android.');
    }
    final result = await _channel.invokeMapMethod<String, dynamic>(
        'install');
    if (result?['installed'] != true) {
      throw StateError('La instalación no quedó confirmada.');
    }
    return HealthyFoodModelStatus(
      installed: true,
      title: result?['title']?.toString() ?? 'SekoKuva Mobile 423K',
    );
  }

  Future<HealthyFoodModelAnalysis> analyze(Uint8List jpeg) async {
    if (!supported || jpeg.isEmpty || jpeg.lengthInBytes > 250 * 1024) {
      throw ArgumentError('Fotografía JPEG no válida para el motor local.');
    }
    final data = await _channel.invokeMapMethod<String, dynamic>(
        'classify', <String, dynamic>{'jpeg': jpeg});
    if (data?['installed'] != true || data?['labels'] is! List) {
      throw const FormatException('El modelo no devolvió etiquetas válidas.');
    }
    final labels = <HealthyDetectedLabel>[];
    for (final raw in data!['labels'] as List) {
      if (raw is! Map) continue;
      final label = raw['name'];
      final score = raw['score'];
      if (label is! String || score is! num ||
          !score.isFinite || score < 0 || score > 1) continue;
      labels.add(HealthyDetectedLabel(label, score.toDouble()));
    }
    return HealthyFoodModelAnalysis(
      labels: List.unmodifiable(labels),
      model: data['model']?.toString() ?? 'SekoKuva Mobile 423K',
    );
  }
}
