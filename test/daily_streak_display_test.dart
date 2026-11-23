import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/servicios/daily_streak_display.dart';

void main() {
  final now = DateTime(2026, 11, 22, 12);

  test('la primera sesión del día mantiene un día de racha', () {
    expect(DailyStreakDisplay.current({
      'lastStreakDate': '2026-11-22',
      'currentStreak': 1,
    }, now: now), 1);
  });

  test('se conserva la racha de ayer hasta finalizar hoy', () {
    expect(DailyStreakDisplay.current({
      'lastStreakDate': '2026-11-21',
      'currentStreak': 4,
    }, now: now), 4);
  });

  test('la racha caduca visualmente tras un día perdido', () {
    expect(DailyStreakDisplay.current({
      'lastStreakDate': '2026-11-20',
      'currentStreak': 4,
      'longestStreak': 7,
    }, now: now), 0);
    expect(DailyStreakDisplay.longest({
      'longestStreak': 7,
    }), 7);
  });

  test('los contadores del servidor prevalecen sobre Flutter', () {
    final profile = {
      'serverLastStreakDay': '2026-11-22',
      'serverStreakDays': 2,
      'serverLongestStreak': 5,
      'lastStreakDate': '2026-11-22',
      'currentStreak': 99,
      'longestStreak': 99,
    };
    expect(DailyStreakDisplay.current(profile, now: now), 2);
    expect(DailyStreakDisplay.longest(profile), 5);
    expect(DailyStreakDisplay.verified(profile), true);
  });
}
