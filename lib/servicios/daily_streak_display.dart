/// Presentación de la racha global sin alterar ni conceder recompensas.
/// Los contadores server* sólo son autoridad cuando existen en Firestore.
class DailyStreakDisplay {
  DailyStreakDisplay._();

  static int _count(dynamic value) =>
      value is num && value >= 0 ? value.toInt() : 0;

  static String lastDay(Map<String, dynamic> profile) =>
      (profile['serverLastStreakDay'] ??
          profile['lastStreakDate'] ?? '').toString();

  static int current(Map<String, dynamic> profile, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final day = DateTime.tryParse(lastDay(profile));
    if (day == null) return 0;
    final midnightToday = DateTime(today.year, today.month, today.day);
    final midnightLast = DateTime(day.year, day.month, day.day);
    final gap = midnightToday.difference(midnightLast).inDays;
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
