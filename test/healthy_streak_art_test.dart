import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/tema/healthy_streak_art.dart';

void main() {
  final now = DateTime(2026, 11, 22, 12);

  test('todas las variantes tienen una ruta PNG independiente', () {
    expect(HealthyStreakArt.paths.length, HealthyStreakArtState.values.length);
    expect(HealthyStreakArt.paths.values.toSet().length,
        HealthyStreakArtState.values.length);
    for (final path in HealthyStreakArt.paths.values) {
      expect(path, startsWith('assets/gamificacion/protectores_racha/'));
      expect(path, endsWith('.png'));
    }
  });

  test('sin historial muestra mascota inactiva', () {
    expect(HealthyStreakArt.fromProfile({}, now: now),
        HealthyStreakArtState.inactive);
  });

  test('racha vigente muestra mascota encendida', () {
    expect(HealthyStreakArt.fromProfile({
      'lastStreakDate': '2026-11-22',
      'currentStreak': 5,
    }, now: now), HealthyStreakArtState.active);
  });

  test('racha extensa muestra variante legendaria', () {
    expect(HealthyStreakArt.fromProfile({
      'lastStreakDate': '2026-11-22',
      'currentStreak': 32,
    }, now: now), HealthyStreakArtState.legendary);
  });

  test('racha vencida con historial muestra variante de interrupción', () {
    expect(HealthyStreakArt.fromProfile({
      'lastStreakDate': '2026-11-19',
      'currentStreak': 5,
      'longestStreak': 10,
    }, now: now), HealthyStreakArtState.lost);
  });

  test('no supone protección ni peligro sin dato de backend', () {
    final state = HealthyStreakArt.fromProfile({
      'lastStreakDate': '2026-11-21',
      'currentStreak': 4,
    }, now: now);
    expect(state, HealthyStreakArtState.active);
    expect(state, isNot(HealthyStreakArtState.protected));
    expect(state, isNot(HealthyStreakArtState.atRisk));
  });
}
