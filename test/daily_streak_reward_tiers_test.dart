import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/servicios/daily_streak_reward_tiers.dart';

void main() {
  test('la escala de premios nuevos está entre 10 y 200', () {
    const days = [1, 2, 3, 4, 6, 7, 13, 14, 20, 21, 29,
      30, 44, 45, 59, 60, 89, 90, 119, 120, 179, 180, 1000];
    const expected = [10, 15, 15, 20, 20, 30, 30, 45, 45,
      60, 60, 80, 80, 100, 100, 125, 125, 150, 150,
      175, 175, 200, 200];
    for (var i = 0; i < days.length; i++) {
      expect(DailyStreakRewardTiers.preview(days[i]), expected[i],
          reason: 'día ${days[i]}');
    }
    for (var day = 1; day <= 1000; day++) {
      final amount = DailyStreakRewardTiers.preview(day);
      expect(amount, inInclusiveRange(10, 200));
    }
    expect(DailyStreakRewardTiers.preview(0), 0);
  });
}
