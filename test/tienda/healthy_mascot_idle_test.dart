import 'package:flutter_test/flutter_test.dart';

import '../../lib/páginas/tienda/healthy_mascot_idle.dart';

void main() {
  test('el ciclo comienza y termina en la misma postura', () {
    final start = HealthyIdlePose.at(0);
    final end = HealthyIdlePose.at(1);
    expect(start.angle, closeTo(0, 1e-10));
    expect(end.angle, closeTo(0, 1e-10));
    expect(start.lift, closeTo(0, 1e-10));
    expect(end.lift, closeTo(0, 1e-10));
    expect(start.scaleY, closeTo(1, 1e-10));
    expect(end.scaleY, closeTo(1, 1e-10));
  });

  test('el balanceo lateral es pequeño y simétrico', () {
    final left = HealthyIdlePose.at(.25);
    final right = HealthyIdlePose.at(.75);
    expect(left.angle, closeTo(-right.angle, 1e-10));
    expect(left.angle.abs(), lessThan(.025));
    expect(right.angle.abs(), lessThan(.025));
  });

  test('la respiración no deforma el ancho ni desplaza bruscamente', () {
    for (var i = 0; i <= 100; i++) {
      final pose = HealthyIdlePose.at(i / 100);
      expect(pose.lift, inInclusiveRange(-2.01, 0.01));
      expect(pose.scaleY, inInclusiveRange(1, 1.0061));
      expect(pose.angle.abs(), lessThan(.024));
    }
    expect(HealthyIdlePose.at(.5).lift, closeTo(-2, 1e-10));
  });
}
