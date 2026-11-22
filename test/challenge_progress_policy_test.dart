import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/desafios/challenge_progress_policy.dart';

void main() {
  test('los ejemplos completados no conceden recompensas', () {
    final legacyDemo = <String, dynamic>{
      'title': 'Racha de 7 días',
      'status': 'completed',
      'currentProgress': 7,
      'totalProgress': 7,
      'xpReward': 80,
      'hcReward': 25,
    };
    expect(ChallengeProgressPolicy.verified(legacyDemo), isFalse);
    expect(ChallengeProgressPolicy.visibleProgress(legacyDemo), 0);
    expect(ChallengeProgressPolicy.claimable(legacyDemo), isFalse);
  });

  test('la marca demo no es una prueba de progreso', () {
    final sample = <String, dynamic>{
      'status': 'completed',
      'currentProgress': 7,
      'totalProgress': 7,
      'demoSeed': true,
      'progressVerified': true,
      'progressSource': 'habit_records',
    };
    expect(ChallengeProgressPolicy.verified(sample), isFalse);
    expect(ChallengeProgressPolicy.claimable(sample), isFalse);
  });

  test('solo registros comprobados y objetivos completos son reclamables', () {
    final verified = <String, dynamic>{
      'status': 'completed',
      'currentProgress': 5,
      'totalProgress': 5,
      'demoSeed': false,
      'progressVerified': true,
      'progressSource': 'habit_records',
    };
    expect(ChallengeProgressPolicy.verified(verified), isTrue);
    expect(ChallengeProgressPolicy.visibleProgress(verified), 5);
    expect(ChallengeProgressPolicy.claimable(verified), isTrue);
    verified['currentProgress'] = 3;
    expect(ChallengeProgressPolicy.claimable(verified), isFalse);
    verified['currentProgress'] = 5;
    verified['status'] = 'claimed';
    expect(ChallengeProgressPolicy.claimable(verified), isFalse);
  });
}
