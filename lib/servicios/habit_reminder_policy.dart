/// Determina si un intento necesita un recordatorio de actividad diaria.
/// La información procede de documentos de servidor; no concede recompensas.
class HabitReminderPolicy {
  const HabitReminderPolicy._();

  static bool pendingDaily({
    required String status,
    required String frequency,
    required int progress,
    required int target,
    required int requiredToday,
    required int registeredToday,
  }) {
    return status == 'inProgress' &&
        frequency == 'daily' &&
        target > 0 &&
        progress < target &&
        requiredToday > 0 &&
        registeredToday < requiredToday;
  }
}
