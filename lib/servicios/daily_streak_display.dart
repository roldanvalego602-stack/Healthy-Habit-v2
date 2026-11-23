import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

/// Presentación de la racha global sin alterar ni conceder recompensas.
/// El día civil verificado se compara en la zona fijada por el backend.
class DailyStreakDisplay {
  DailyStreakDisplay._();

  static bool _initialized = false;

  static int _count(dynamic value) =>
      value is num && value >= 0 ? value.toInt() : 0;

  static String lastDay(Map<String, dynamic> profile) =>
      (profile['serverLastStreakDay'] ??
          profile['lastStreakDate'] ?? '').toString();

  static String _todayInZone(Map<String, dynamic> profile, DateTime now) {
    final zone = profile['serverLastStreakDay'] is String
        ? (profile['calendarTimeZone'] ?? 'UTC').toString()
        : '';
    if (zone.isEmpty) return _dayKey(now.toLocal());

    if (zone == 'UTC') return _dayKey(now.toUtc());
    try {
      if (!_initialized) {
        timezone_data.initializeTimeZones();
        _initialized = true;
      }
      return _dayKey(tz.TZDateTime.from(now, tz.getLocation(zone)));
    } catch (_) {
      // No inventar un calendario cuando el servidor usa otra zona.
      return '';
    }
  }

  static String _dayKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static int current(Map<String, dynamic> profile, {DateTime? now}) {
    final last = lastDay(profile);
    final today = _todayInZone(profile, now ?? DateTime.now());
    final parsedLast = DateTime.tryParse(last);
    final parsedToday = DateTime.tryParse(today);
    if (parsedLast == null || parsedToday == null) return 0;

    // Fechas civiles: usar UTC para la resta evita errores por horario de verano.
    final lastCivil = DateTime.utc(
      parsedLast.year, parsedLast.month, parsedLast.day,
    );
    final todayCivil = DateTime.utc(
      parsedToday.year, parsedToday.month, parsedToday.day,
    );
    final gap = todayCivil.difference(lastCivil).inDays;
    if (gap != 0 && gap != 1) return 0;

    return _count(profile['serverStreakDays'] ??
        profile['currentStreak'] ?? profile['streakDays']);
  }

  static int longest(Map<String, dynamic> profile) => _count(
        profile['serverLongestStreak'] ?? profile['longestStreak'],
      );

  static bool verified(Map<String, dynamic> profile) =>
      profile['serverLastStreakDay'] is String;
}
