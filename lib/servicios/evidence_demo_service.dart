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
