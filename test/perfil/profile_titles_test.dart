import 'package:flutter_test/flutter_test.dart';
import '../../lib/páginas/perfil/profile_titles.dart';

void main() {
  test('títulos de nivel se desbloquean por umbrales', () {
    final novice = HealthyProfileTitles.byName('Semilla saludable')!;
    final level3 = HealthyProfileTitles.byName('Cultivador de constancia')!;
    final level5 = HealthyProfileTitles.byName('Explorador del bienestar')!;
    expect(novice.available(1, {}), isTrue);
    expect(level3.available(2, {}), isFalse);
    expect(level3.available(3, {}), isTrue);
    expect(level5.available(4, {}), isFalse);
    expect(level5.available(5, {}), isTrue);
  });

  test('logros oficiales y festivales nunca se regalan sin insignia', () {
    final first = HealthyProfileTitles.byName('Primer paso cumplido')!;
    final festival = HealthyProfileTitles.byName('Espíritu del festival')!;
    expect(first.available(100, {}), isFalse);
    expect(first.available(1, {'primera_meta'}), isTrue);
    expect(festival.available(100, {}), isFalse);
    expect(festival.available(1, {'festival_participant_2026'}), isTrue);
  });

  test('perfil no muestra títulos que todavía estén bloqueados', () {
    expect(HealthyProfileTitles.visibleTitle(
        'Leyenda saludable', 2, {}), 'Semilla saludable');
    expect(HealthyProfileTitles.visibleTitle(
        'Leyenda saludable', 10, {}), 'Leyenda saludable');
    expect(HealthyProfileTitles.visibleTitle(
        'Espíritu del festival', 50, {}), 'Semilla saludable');
  });
}
