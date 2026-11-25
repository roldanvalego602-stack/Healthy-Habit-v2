import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/servicios/streak_notice_policy.dart';

void main() {
  final now = DateTime.parse('2026-11-24T16:00:00Z');

  test('sin historial no afirma que se perdió una racha', () {
    expect(StreakNoticePolicy.status({}, now: now),
        StreakNoticeStatus.inactive);
  });

  test('el registro del día cancela mensajes de riesgo', () {
    expect(StreakNoticePolicy.status({
      'serverLastStreakDay': '2026-11-24',
      'serverStreakTimeZone': 'America/Monterrey',
    }, now: now), StreakNoticeStatus.completedToday);
  });

  test('el registro de ayer deja pendiente el día actual', () {
    expect(StreakNoticePolicy.status({
      'serverLastStreakDay': '2026-11-23',
      'serverStreakTimeZone': 'America/Monterrey',
    }, now: now), StreakNoticeStatus.pendingToday);
  });

  test('después de dos días de ausencia indica interrupción', () {
    expect(StreakNoticePolicy.status({
      'lastStreakDate': '2026-11-22',
    }, now: now), StreakNoticeStatus.lost);
  });

  test('el calendario UTC no se sustituye por la zona del teléfono', () {
    final instant = DateTime.parse('2026-11-25T01:00:00Z');
    expect(StreakNoticePolicy.status({
      'serverLastStreakDay': '2026-11-24',
      'serverStreakTimeZone': 'UTC',
    }, now: instant), StreakNoticeStatus.pendingToday);
    expect(StreakNoticePolicy.status({
      'serverLastStreakDay': '2026-11-24',
      'serverStreakTimeZone': 'America/Monterrey',
    }, now: instant), StreakNoticeStatus.completedToday);
  });

  test('sin zona reconocida no se inventan alertas', () {
    expect(StreakNoticePolicy.status({
      'serverLastStreakDay': '2026-11-24',
      'serverStreakTimeZone': 'Mars/Unknown',
    }, now: now), StreakNoticeStatus.unknown);
  });

  test('alerta UTC tres horas antes del fin de su propio día', () {
    final instant = DateTime.parse('2026-11-24T16:00:00Z');
    expect(StreakNoticePolicy.warningInstant({
      'serverLastStreakDay': '2026-11-23',
      'serverStreakTimeZone': 'UTC',
    }, now: instant)?.toUtc().toIso8601String(), '2026-11-24T21:00:00.000Z');
  });

  test('alerta en Monterrey respeta la zona de la cuenta', () {
    final instant = DateTime.parse('2026-11-24T16:00:00Z');
    expect(StreakNoticePolicy.warningInstant({
      'serverLastStreakDay': '2026-11-23',
      'serverStreakTimeZone': 'America/Monterrey',
    }, now: instant)?.toUtc().toIso8601String(), '2026-11-25T03:00:00.000Z');
    expect(StreakNoticePolicy.warningInstant({
      'serverLastStreakDay': '2026-11-24',
      'serverStreakTimeZone': 'America/Monterrey',
    }, now: instant, daysAhead: 1)?.toUtc().toIso8601String(),
        '2026-11-26T03:00:00.000Z');
  });

  test('fechas futuras, imposibles y formatos incorrectos no son pérdida', () {
    for (final last in ['2026-11-25', '2026-11-31', '23/11/2026']) {
      expect(StreakNoticePolicy.status({'lastStreakDate': last}, now: now),
          StreakNoticeStatus.unknown);
    }
  });
}
