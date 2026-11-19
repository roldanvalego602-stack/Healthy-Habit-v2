import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Recordatorios locales, sin datos personales en la notificación.
/// Android: programación aproximada que puede demorarse por ahorro de batería.
class HealthyRemindersService {
  HealthyRemindersService._();
  static final instance = HealthyRemindersService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _revision = 0;

  static const int _firstId = 8100;
  static const List<String> _titles = [
    'Un paso para tus hábitos',
    'Cuida tu constancia',
    'Revisa tus desafíos',
  ];
  static const List<String> _bodies = [
    '¿Qué pequeña acción saludable quieres registrar hoy?',
    'Si puedes, dedica un momento a tu rutina de hoy.',
    'Tus desafíos te esperan cuando tengas un momento.',
  ];

  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (!supported || _initialized) return;
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    // Nunca suponer la zona horaria del usuario por ubicación o IP.
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher'),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> _cancelManaged() async {
    for (var kind = 0; kind < 3; kind++) {
      for (var day = 0; day < 8; day++) {
        await _plugin.cancel(_firstId + kind * 10 + day);
      }
    }
  }

  /// Reconstruye la agenda desde la configuración de la cuenta activa.
  /// Devuelve false si Android denegó notificaciones.
  Future<bool> synchronize(
    Map<String, dynamic> settings, {
    bool askPermission = false,
  }) async {
    if (!supported) return false;
    await initialize();
    final revision = ++_revision;
    await _cancelManaged();
    if (revision != _revision) return false;
    if (settings['permitirRecordatorios'] != true) return true;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (askPermission) {
      final granted = await android?.requestNotificationsPermission();
      if (granted == false) return false;
    }
    final enabled = await android?.areNotificationsEnabled();
    if (enabled == false) return false;

    final time = (settings['horarioRecordatorio'] ?? '09:00').toString();
    final parts = time.split(':');
    final hour = int.tryParse(parts.first) ?? 9;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw const FormatException('Horario de recordatorios no válido');
    }
    final restSunday = settings['descansoSemanal'] == true;
    final flags = [
      settings['recordatorioHabito'] != false,
      settings['recordatorioRacha'] != false,
      settings['recordatorioDesafios'] == true,
    ];
    final playSound = settings['sonidosApp'] != false;
    final vibrate = settings['vibracionHaptica'] != false;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'healthy_reminders_s' + (playSound ? '1' : '0') +
            '_v' + (vibrate ? '1' : '0'),
        'Recordatorios de Healthy Habit',
        channelDescription: 'Avisos voluntarios para hábitos, rachas y desafíos',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: playSound,
        enableVibration: vibrate,
      ),
    );
    for (var kind = 0; kind < flags.length; kind++) {
      if (!flags[kind]) continue;
      // Cada tipo se separa 20 minutos. Evitar avisos pasada la medianoche.
      final minutes = (hour * 60 + minute + kind * 20).clamp(0, 1439).toInt();
      final h = minutes ~/ 60;
      final m = minutes % 60;
      final now = tz.TZDateTime.now(tz.local);
      if (restSunday) {
        for (var weekday = 1; weekday <= 6; weekday++) {
          var next = tz.TZDateTime(
            tz.local, now.year, now.month, now.day, h, m,
          );
          final days = (weekday - next.weekday + 7) % 7;
          next = tz.TZDateTime(
            tz.local, now.year, now.month, now.day + days, h, m,
          );
          if (!next.isAfter(now)) {
            next = tz.TZDateTime(
              tz.local, next.year, next.month, next.day + 7, h, m,
            );
          }
          if (revision != _revision) return false;
          await _plugin.zonedSchedule(
            _firstId + kind * 10 + weekday,
            _titles[kind],
            _bodies[kind],
            next,
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      } else {
        var next = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, h, m,
        );
        if (!next.isAfter(now)) {
          next = tz.TZDateTime(
            tz.local, now.year, now.month, now.day + 1, h, m,
          );
        }
        if (revision != _revision) return false;
        await _plugin.zonedSchedule(
          _firstId + kind * 10,
          _titles[kind],
          _bodies[kind],
          next,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
    return true;
  }

  Future<void> cancel() async {
    if (!supported) return;
    await initialize();
    ++_revision;
    await _cancelManaged();
  }

  /// Solo se invoca cuando el usuario pulsa explícitamente Probar aviso.
  Future<bool> sendTest() async {
    if (!supported) return false;
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    if (granted == false) return false;
    final enabled = await android?.areNotificationsEnabled();
    if (enabled == false) return false;
    await _plugin.show(
      8199,
      'Prueba de Healthy Habit',
      'Las notificaciones de esta aplicación están activas.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'healthy_habit_daily_v1',
          'Recordatorios de Healthy Habit',
          channelDescription: 'Avisos voluntarios para hábitos, rachas y desafíos',
        ),
      ),
    );
    return true;
  }
}
