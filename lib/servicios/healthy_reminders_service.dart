import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'streak_notice_policy.dart';
import 'habit_reminder_policy.dart';
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
  Future<void>? _initializing;
  int _revision = 0;

  static const int _firstId = 8100;
  static const int _diagnosticId = 8198;
  static const int _habitTodayId = 8129;
  static const int _streakReminderId = 8130;
  static const int _streakWarningId = 8131;
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

  Future<void> initialize() {
    if (!supported || _initialized) return Future<void>.value();
    return _initializing ??= _initializeInternal().whenComplete(() {
      _initializing = null;
    });
  }

  Future<void> _initializeInternal() async {
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    // Nunca suponer la zona horaria del usuario por ubicación o IP.
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_healthy_notification'),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> _cancelManaged() async {
    await _plugin.cancel(_habitTodayId);
    await _plugin.cancel(_streakReminderId);
    await _plugin.cancel(_streakWarningId);
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
    Map<String, dynamic>? profile,
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
      false, // Los avisos de hábitos se calculan por día y sin recurrencia.
      false, // La racha se agenda por fecha, nunca de forma recurrente.
      settings['recordatorioDesafios'] == true,
    ];
    final playSound = settings['sonidosApp'] != false;
    final vibrate = settings['vibracionHaptica'] != false;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'healthy_reminders_s${playSound ? '1' : '0'}_v${vibrate ? '1' : '0'}',
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
    if (settings['recordatorioHabito'] != false) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final count = await _pendingDailyHabits(user.uid);
          if (revision != _revision ||
              FirebaseAuth.instance.currentUser?.uid != user.uid) {
            return false;
          }
          final now = tz.TZDateTime.now(tz.local);
          final next = tz.TZDateTime(
            tz.local, now.year, now.month, now.day, hour, minute,
          );
          if (count > 0 && next.isAfter(now) &&
              (!restSunday || now.weekday != DateTime.sunday)) {
            await _plugin.zonedSchedule(
              _habitTodayId,
              count == 1 ? 'Tienes un hábito pendiente' :
                  'Tienes $count hábitos pendientes',
              'Consulta tus actividades pendientes de hoy en Healthy Habit.',
              next, details,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
          }
        } catch (error) {
          debugPrint('No se pudo verificar pendientes: $error');
        }
      }
    }
    // Las alarmas de racha son de una sola ocasión y se cancelan al
    // registrar una actividad; un aviso recurrente podría mentir al usuario.
    if (settings['recordatorioRacha'] != false) {
      var latest = profile;
      if (latest == null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            final doc = await FirebaseFirestore.instanceFor(
              app: Firebase.app(), databaseId: 'default',
            ).collection('users').doc(user.uid).get();
            if (FirebaseAuth.instance.currentUser?.uid == user.uid) {
              latest = doc.data();
            }
          } catch (error) {
            debugPrint('No se pudo verificar la racha para avisar: $error');
          }
        }
      }
      if (revision != _revision) return false;
      if (latest != null) {
        final state = StreakNoticePolicy.status(latest);
        final now = tz.TZDateTime.now(tz.local);
        // Únicamente se agenda hoy si falta registrar, o mañana si
        // ya se registró hoy. Con estados inciertos no se programa.
        final offset = state == StreakNoticeStatus.completedToday
            ? 1
            : state == StreakNoticeStatus.pendingToday ||
                    state == StreakNoticeStatus.inactive
                ? 0 : null;
        if (offset != null) {
          final day = tz.TZDateTime(
            tz.local, now.year, now.month, now.day + offset,
          );
          if (!restSunday || day.weekday != DateTime.sunday) {
            final first = tz.TZDateTime(
              tz.local, day.year, day.month, day.day,
              (hour * 60 + minute + 20).clamp(0, 1439).toInt() ~/ 60,
              (hour * 60 + minute + 20).clamp(0, 1439).toInt() % 60,
            );
            final warningInstant = StreakNoticePolicy.warningInstant(
              latest, daysAhead: offset,
            );
            final warning = warningInstant == null ? null
                : tz.TZDateTime.from(warningInstant, tz.local);
            final isNew = state == StreakNoticeStatus.inactive;
            var reminder = first;
            if (isNew && !reminder.isAfter(now)) {
              // El primer recordatorio de activación puede esperar al
              // próximo día permitido; no se envían alertas nocturnas.
              reminder = tz.TZDateTime(
                tz.local, day.year, day.month, day.day + 1,
                first.hour, first.minute,
              );
            }
            if (isNew || warning != null &&
                reminder.isAfter(now) && reminder.isBefore(warning)) {
              if (revision != _revision) return false;
              if (reminder.isAfter(now) &&
                  (!restSunday || reminder.weekday != DateTime.sunday)) {
              await _plugin.zonedSchedule(
                _streakReminderId,
                isNew ? '¡Enciende tu primera racha!' : '¡Mantén tu racha encendida!',
                isNew
                    ? 'Registra una actividad válida para comenzar tu constancia.'
                    : 'Si aún no registraste actividad hoy, puedes hacerlo '
                        'para mantener tu constancia.',
                reminder, details,
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              );
              }
            }
            if (!isNew && warning != null && warning.isAfter(now)) {
              if (revision != _revision) return false;
              await _plugin.zonedSchedule(
                _streakWarningId,
                'Revisa tu racha antes de terminar el día',
                'Si todavía no registraste una actividad válida, '
                    'tu racha podría interrumpirse.',
                warning, details,
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              );
            }
          }
        }
      }
    }
    return true;
  }

  /// Nunca confía en datos del caché para anunciar actividades pendientes.
  Future<int> _pendingDailyHabits(String uid) async {
    final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(), databaseId: 'default',
    );
    final habits = await db.collection('users').doc(uid)
        .collection('user_habits')
        .get(const GetOptions(source: Source.server));
    final now = DateTime.now().toLocal();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day + 1);
    var count = 0;
    for (final habit in habits.docs) {
      if (FirebaseAuth.instance.currentUser?.uid != uid) {
        throw StateError('Cambio de sesión');
      }
      final attempts = await habit.reference.collection('attempts')
          .where('status', isEqualTo: 'inProgress')
          .get(const GetOptions(source: Source.server));
      for (final attempt in attempts.docs) {
        final data = attempt.data();
        final progress = (data['progress'] as num?)?.toInt() ?? 0;
        final target = (data['target'] as num?)?.toInt() ?? 0;
        if ((data['frequencyType'] ?? 'daily') != 'daily' ||
            target < 1 || progress >= target) {
          continue;
        }
        final required = (data['registrationsPerPeriod'] as num?)
                ?.toInt() ?? 1;
        if (required < 1) {
          continue;
        }
        final logs = await attempt.reference.collection('logs')
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('createdAt', isLessThan: Timestamp.fromDate(end))
            .get(const GetOptions(source: Source.server));
        if (HabitReminderPolicy.pendingDaily(
          status: (data['status'] ?? '').toString(),
          frequency: (data['frequencyType'] ?? 'daily').toString(),
          progress: progress,
          target: target,
          requiredToday: required,
          registeredToday: logs.docs.length,
        )) {
          count++;
        }
      }
    }
    return count;
  }

  /// Recarga la agenda después de confirmar un registro en Firestore.
  /// Los avisos antiguos se cancelan antes de reconstruir los próximos.
  Future<void> refreshForCurrentUser() async {
    if (!supported) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instanceFor(
        app: Firebase.app(), databaseId: 'default',
      ).collection('users').doc(user.uid).get();
      if (FirebaseAuth.instance.currentUser?.uid != user.uid) return;
      final data = doc.data() ?? <String, dynamic>{};
      final raw = data['settings'];
      await synchronize(raw is Map
          ? Map<String, dynamic>.from(raw) : <String, dynamic>{},
          profile: data);
    } catch (error) {
      debugPrint('No se pudo actualizar la agenda de rachas: $error');
    }
  }

  /// Cantidad de recordatorios de Healthy Habit pendientes en Android.
  /// No incluye notificaciones de otras aplicaciones.
  Future<int?> pendingCount() async {
    if (!supported) return null;
    await initialize();
    final requests = await _plugin.pendingNotificationRequests();
    return requests.where((request) =>
      request.id >= _firstId &&
      request.id < _firstId + 3 * 10 + 8).length;
  }

  /// Consulta el estado del permiso sin solicitarlo.
  Future<bool?> notificationsEnabled() async {
    if (!supported) return null;
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return android?.areNotificationsEnabled();
  }

  /// Programa una notificación de diagnóstico dentro de dos minutos.
  /// Puede llegar más tarde por las restricciones energéticas de Android.
  /// No cambia preferencias ni elimina los recordatorios cotidianos.
  Future<bool> scheduleDiagnosticTest() async {
    if (!supported) return false;
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    if (granted == false || await android?.areNotificationsEnabled() == false) {
      return false;
    }
    // La prueba se puede repetir sin acumular avisos de diagnóstico.
    await _plugin.cancel(_diagnosticId);
    final scheduledAt =
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: 2));
    await _plugin.zonedSchedule(
      _diagnosticId,
      'Prueba programada de Healthy Habit',
      'Android ejecutó el aviso de diagnóstico de esta aplicación.',
      scheduledAt,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'healthy_habit_diagnostic_v1',
          'Pruebas de recordatorios',
          channelDescription: 'Prueba voluntaria de programación de avisos',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    return true;
  }

  /// Comprueba si la prueba de dos minutos figura entre las pendientes.
  Future<bool?> diagnosticPending() async {
    if (!supported) return null;
    await initialize();
    final requests = await _plugin.pendingNotificationRequests();
    return requests.any((request) => request.id == _diagnosticId);
  }

  Future<void> cancel() async {
    if (!supported) return;
    await initialize();
    ++_revision;
    await _cancelManaged();
    // Al cerrar sesión tampoco debe quedar un diagnóstico anterior.
    await _plugin.cancel(_diagnosticId);
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
