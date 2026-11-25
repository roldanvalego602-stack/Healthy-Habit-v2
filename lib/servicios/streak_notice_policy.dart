import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

/// El aviso de racha se basa en el último día registrado, no en el número
/// visible de días. Nunca otorga premios ni modifica el perfil.
enum StreakNoticeStatus { inactive, completedToday, pendingToday, lost, unknown }

class StreakNoticePolicy {
  StreakNoticePolicy._();

  static bool _ready = false;

  static String _key(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String? todayKey(Map<String, dynamic> profile, {DateTime? now}) {
    final instant = now ?? DateTime.now();
    if (profile['serverLastStreakDay'] is! String) {
      return _key(instant.toLocal());
    }
    final zone = (profile['serverStreakTimeZone'] ??
        profile['calendarTimeZone'] ?? 'UTC').toString();
    if (zone == 'UTC') return _key(instant.toUtc());
    try {
      if (!_ready) {
        timezone_data.initializeTimeZones();
        _ready = true;
      }
      return _key(tz.TZDateTime.from(instant, tz.getLocation(zone)));
    } catch (_) {
      // Un calendario desconocido no debe generar avisos de vencimiento.
      return null;
    }
  }

  static int? daysSinceLast(Map<String, dynamic> profile, {DateTime? now}) {
    final raw = profile['serverLastStreakDay'] ??
        profile['lastStreakDate'];
    if (raw is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
      return null;
    }
    final today = todayKey(profile, now: now);
    final lastDate = DateTime.tryParse(raw);
    final todayDate = today == null ? null : DateTime.tryParse(today);
    if (lastDate == null || todayDate == null) return null;
    if (_key(lastDate) != raw || _key(todayDate) != today) return null;
    return DateTime.utc(todayDate.year, todayDate.month, todayDate.day)
        .difference(DateTime.utc(
          lastDate.year, lastDate.month, lastDate.day,
        )).inDays;
  }

  static StreakNoticeStatus status(Map<String, dynamic> profile,
      {DateTime? now}) {
    final last = profile['serverLastStreakDay'] ??
        profile['lastStreakDate'];
    if (last == null || last == '') return StreakNoticeStatus.inactive;
    final gap = daysSinceLast(profile, now: now);
    if (gap == null || gap < 0) return StreakNoticeStatus.unknown;
    if (gap == 0) return StreakNoticeStatus.completedToday;
    if (gap == 1) return StreakNoticeStatus.pendingToday;
    return StreakNoticeStatus.lost;
  }

  static String title(StreakNoticeStatus status) => switch (status) {
        StreakNoticeStatus.inactive => 'Enciende tu primera racha',
        StreakNoticeStatus.completedToday => '¡Tu racha sigue viva!',
        StreakNoticeStatus.pendingToday => '¡Mantén tu racha encendida!',
        StreakNoticeStatus.lost => 'Tu racha se interrumpió',
        StreakNoticeStatus.unknown => 'Consulta tu racha',
      };

  static String message(StreakNoticeStatus status) => switch (status) {
        StreakNoticeStatus.inactive =>
          'Registra una actividad válida para comenzar.',
        StreakNoticeStatus.completedToday =>
          'Tu actividad de hoy ya quedó registrada. ¡Buen trabajo!',
        StreakNoticeStatus.pendingToday =>
          'Todavía falta una actividad válida de hoy para continuar.',
        StreakNoticeStatus.lost =>
          'Puedes comenzar una nueva racha con tu próxima actividad.',
        StreakNoticeStatus.unknown =>
          'No podemos confirmar el estado sin actualizar tus datos.',
      };
}
