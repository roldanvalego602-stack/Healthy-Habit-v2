import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/servicios/evidence_demo_service.dart';

void main() {
  test('solicitud de desafío usa el hábito ficticio y el objeto elegido', () async {
    String? functionName;
    Map<String, dynamic>? payload;
    final service = EvidenceDemoService(call: (name, data) async {
      functionName = name;
      payload = data;
      return {
        'challengeId': 'abc',
        'objectId': 'spoon',
        'code': '001235',
        'expiresAt': '2026-11-17T12:00:00Z',
      };
    });
    final challenge = await service.startChallenge('spoon');
    expect(functionName, 'startEvidenceChallenge');
    expect(payload?['habitId'], 'demo-water');
    expect(payload?['attemptId'], 'demo-attempt');
    expect(payload?['objectId'], 'spoon');
    expect(challenge.code, '001235');
  });

  test('no admite objetos desconocidos', () async {
    final service = EvidenceDemoService(call: (_, __) async => {});
    await expectLater(service.startChallenge('passport'), throwsArgumentError);
  });

  test('un código válido no equivale a una imagen validada', () async {
    final service = EvidenceDemoService(call: (name, data) async {
      if (name == 'checkEvidenceChallengeCode') {
        expect(data['challengeId'], 'abc');
        return {
          'codeMatched': true,
          'imageVerified': false,
          'xpAwarded': 0,
        };
      }
      throw StateError('Función inesperada');
    });
    final result = await service.checkTypedCode(DemoChallenge(
      id: 'abc',
      objectId: 'spoon',
      code: '123456',
      expiresAt: DateTime.utc(2026, 11, 17),
    ));
    expect(result.codeMatched, isTrue);
    expect(result.imageVerified, isFalse);
    expect(result.xpAwarded, 0);
  });

  test('descarta respuestas de desafíos con código incorrecto', () {
    expect(
      () => DemoChallenge.fromMap({
        'challengeId': 'abc',
        'objectId': 'spoon',
        'code': '123',
        'expiresAt': '2026-11-17T12:00:00Z',
      }),
      throwsFormatException,
    );
  });
}
