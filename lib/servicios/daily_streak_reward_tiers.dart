/// Vista previa del premio diario para un día de racha verificado.
/// La acreditación real siempre la calcula y valida Cloud Functions.
class DailyStreakRewardTiers {
  DailyStreakRewardTiers._();

  static int preview(int day) {
    if (day < 1) return 0;
    if (day >= 180) return 200;
    if (day >= 120) return 175;
    if (day >= 90) return 150;
    if (day >= 60) return 125;
    if (day >= 45) return 100;
    if (day >= 30) return 80;
    if (day >= 21) return 60;
    if (day >= 14) return 45;
    if (day >= 7) return 30;
    if (day >= 4) return 20;
    if (day >= 2) return 15;
    return 10;
  }
}
