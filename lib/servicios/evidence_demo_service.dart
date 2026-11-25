import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';

/// Transporte intercambiable para probar el cliente sin una conexión de red.
typedef EvidenceDemoCall = Future<Map<String, dynamic>> Function(
  String functionName,
  Map<String, dynamic> data,
);

class DemoChallenge {
  const DemoChallenge({
    required this.id,
    required this.objectId,
    required this.code,
    required this.expiresAt,
  });

  final String id;
  final String objectId;
  final String code;
  final DateTime expiresAt;

  factory DemoChallenge.fromMap(Map<String, dynamic> value) {
    final id = value['challengeId'];
    final objectId = value['objectId'];
    final code = value['code'];
    final expiresAt = value['expiresAt'];
    if (id is! String || id.isEmpty ||
        objectId is! String || objectId.isEmpty ||
        code is! String || !RegExp(r'^\d{6}$').hasMatch(code) ||
        expiresAt is! String) {
      throw const FormatException('El desafío recibido es inválido.');
    }
    final expiry = DateTime.tryParse(expiresAt);
    if (expiry == null) {
      throw const FormatException('La caducidad del desafío es inválida.');
    }
    return DemoChallenge(
      id: id,
      objectId: objectId,
      code: code,
      expiresAt: expiry,
    );
  }
}

class DemoChallengeCheck {
  const DemoChallengeCheck({
    required this.codeMatched,
    required this.imageVerified,
    required this.xpAwarded,
  });

  final bool codeMatched;
  final bool imageVerified;
  final int xpAwarded;

  factory DemoChallengeCheck.fromMap(Map<String, dynamic> value) {
    if (value['codeMatched'] is! bool ||
        value['imageVerified'] is! bool ||
        value['xpAwarded'] is! int) {
      throw const FormatException('La comprobación es inválida.');
    }
    return DemoChallengeCheck(
      codeMatched: value['codeMatched'] as bool,
      imageVerified: value['imageVerified'] as bool,
      xpAwarded: value['xpAwarded'] as int,
    );
  }
}

class EvidenceDemoService {
  EvidenceDemoService({required EvidenceDemoCall call}) : _call = call;

  factory EvidenceDemoService.firebase(FirebaseFunctions functions) {
    return EvidenceDemoService(
      call: (functionName, data) async {
        final response = await functions
            .httpsCallable(
              functionName,
              options: HttpsCallableOptions(
                timeout: const Duration(seconds: 15),
              ),
            )
            .call(data);
        if (response.data is! Map) {
          throw const FormatException('El servidor no devolvió un objeto.');
        }
        return Map<String, dynamic>.from(response.data as Map);
      },
    );
  }

  final EvidenceDemoCall _call;

  Future<void> prepareDemoHabit() async {
    final data = await _call('prepareEvidenceDemo', <String, dynamic>{});
    if (data['habitId'] != 'demo-water' ||
        data['attemptId'] != 'demo-attempt' ||
        data['xpAwarded'] != 0) {
      throw const FormatException('La preparación de prueba es inválida.');
    }
  }

  Future<DemoChallenge> startChallenge(String objectId) async {
    const choices = ['spoon', 'pen', 'paper', 'cup', 'napkin'];
    if (!choices.contains(objectId)) {
      throw ArgumentError.value(objectId, 'objectId', 'Objeto desconocido');
    }
    final data = await _call('startEvidenceChallenge', {
      'habitId': 'demo-water',
      'attemptId': 'demo-attempt',
      'objectId': objectId,
    });
    return DemoChallenge.fromMap(data);
  }

  /// Análisis visual de laboratorio. No registra el hábito ni entrega XP.
  Future<DemoVisualPreview> previewPhoto(
    Uint8List imageBytes, String profileId,
  ) async {
    if (imageBytes.isEmpty || imageBytes.lengthInBytes > 250 * 1024) {
      throw const FormatException('La fotografía debe ocupar como máximo 250 KB.');
    }
    if (!const ['hydration', 'fruit_vegetable', 'meal'].contains(profileId)) {
      throw ArgumentError.value(profileId, 'profileId', 'Categoría inválida');
    }
    final data = await _call('analyzeEvidencePreview', {
      'profileId': profileId,
      'imageBase64': base64Encode(imageBytes),
    });
    return DemoVisualPreview.fromMap(data);
  }

  /// Prueba aislada del código escrito, NO verifica una fotografía.
  Future<DemoChallengeCheck> checkTypedCode(DemoChallenge challenge) async {
    final data = await _call('checkEvidenceChallengeCode', {
      'habitId': 'demo-water',
      'attemptId': 'demo-attempt',
      'challengeId': challenge.id,
      'code': challenge.code,
    });
    return DemoChallengeCheck.fromMap(data);
  }
}

class DemoVisualLabel {
  const DemoVisualLabel(this.name, this.confidence);
  final String name;
  final double confidence;
}

/// Cuota informativa del piloto real. El servidor sigue siendo la autoridad.
class VisionPreviewQuota {
  const VisionPreviewQuota({
    required this.remaining,
    required this.dailyLimit,
    required this.nextAllowedAt,
    required this.resetAt,
  });
  final int remaining;
  final int dailyLimit;
  final DateTime nextAllowedAt;
  final DateTime resetAt;

  factory VisionPreviewQuota.fromMap(Map<dynamic, dynamic> data) {
    final remaining = data['remaining'];
    final dailyLimit = data['dailyLimit'];
    final next = data['nextAllowedAtMillis'];
    final reset = data['resetAtMillis'];
    if (remaining is! int || dailyLimit is! int ||
        next is! int || reset is! int || dailyLimit <= 0 ||
        remaining < 0 || remaining >= dailyLimit ||
        next <= 0 || reset <= 0) {
      throw const FormatException('Información de cuota inválida.');
    }
    return VisionPreviewQuota(
      remaining: remaining,
      dailyLimit: dailyLimit,
      nextAllowedAt: DateTime.fromMillisecondsSinceEpoch(next, isUtc: true),
      resetAt: DateTime.fromMillisecondsSinceEpoch(reset, isUtc: true),
    );
  }
}

class DemoVisualPreview {
  const DemoVisualPreview({
    required this.status,
    required this.message,
    required this.labels,
    this.quota,
  });
  final VisionPreviewQuota? quota;
  final String status;
  final String message;
  final List<DemoVisualLabel> labels;

  factory DemoVisualPreview.fromMap(Map<String, dynamic> data) {
    final raw = data['labels'];
    if (!const ['visual_match_only', 'inconclusive'].contains(data['status']) ||
        data['imageVerified'] != false ||
        data['xpAwarded'] != 0 ||
        data['coinsAwarded'] != 0 ||
        data['message'] is! String ||
        raw is! List) {
      throw const FormatException('Respuesta visual insegura o inválida.');
    }
    final labels = <DemoVisualLabel>[];
    for (final item in raw) {
      if (item is! Map ||
          item['name'] is! String ||
          item['score'] is! num ||
          (item['score'] as num) < 0 ||
          (item['score'] as num) > 1) {
        throw const FormatException('Etiqueta visual inválida.');
      }
      labels.add(DemoVisualLabel(
        item['name'] as String,
        (item['score'] as num).toDouble(),
      ));
    }
    return DemoVisualPreview(
      status: data['status'] as String,
      message: data['message'] as String,
      labels: labels,
      quota: data['quota'] == null
          ? null
          : data['quota'] is Map
              ? VisionPreviewQuota.fromMap(data['quota'] as Map)
              : throw const FormatException('Cuota inválida.'),
    );
  }
}
