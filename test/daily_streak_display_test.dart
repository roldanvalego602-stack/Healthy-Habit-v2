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
  test('UTC evening does not erase a verified streak', () {
    // 19:30 in Durango is already 01:30 UTC the next day.
    final utcEvening = DateTime.parse('2026-11-23T01:30:00Z');
    expect(DailyStreakDisplay.current({
      'serverLastStreakDay': '2026-11-23',
      'serverStreakDays': 1,
      'calendarTimeZone': 'UTC',
    }, now: utcEvening), 1);
  });

  test('server time zone America/Monterrey uses local civil day', () {
    final utcEvening = DateTime.parse('2026-11-23T01:30:00Z');
    expect(DailyStreakDisplay.current({
      'serverLastStreakDay': '2026-11-22',
      'serverStreakDays': 2,
      'calendarTimeZone': 'America/Monterrey',
    }, now: utcEvening), 2);
  });

  test('unknown time zone does not invent streak status', () {
    expect(DailyStreakDisplay.current({
      'serverLastStreakDay': '2026-11-22',
      'serverStreakDays': 4,
      'calendarTimeZone': 'Mars/Olympus',
    }, now: DateTime.parse('2026-11-22T22:00:00Z')), 0);
  });


  test('zona estable del contador prevalece sobre la zona de hábitos', () {
    // En Durango todavía es el 22; en UTC ya es el 23.
    final instant = DateTime.parse('2026-11-23T01:30:00Z');
    expect(DailyStreakDisplay.current({
      'serverLastStreakDay': '2026-11-22',
      'serverStreakDays': 3,
      'serverStreakTimeZone': 'America/Monterrey',
      'calendarTimeZone': 'UTC',
    }, now: instant), 3);
  });

}
