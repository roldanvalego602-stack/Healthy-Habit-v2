/// Estado de confianza del progreso de desafíos.
///
/// Los datos iniciales del catálogo son demostraciones; ni 7/7 ni el estado
/// `completed` bastan para entregar XP o Habit Coins.
///
/// Las propiedades de verificación solo deben ser escritas por un backend
/// autorizado. Esta comprobación cliente NO sustituye reglas de Firestore.
class ChallengeProgressPolicy {
  const ChallengeProgressPolicy._();

  static int number(Object? value, [int fallback = 0]) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  static bool verified(Map<String, dynamic> data) =>
      data['progressVerified'] == true &&
      data['progressSource'] == 'habit_records' &&
      data['demoSeed'] != true;

  static int visibleProgress(Map<String, dynamic> data) =>
      verified(data) ? number(data['currentProgress']) : 0;

  static bool claimable(Map<String, dynamic> data) =>
      verified(data) &&
      data['status'] == 'completed' &&
      number(data['totalProgress']) > 0 &&
      number(data['currentProgress']) >= number(data['totalProgress']);
}
