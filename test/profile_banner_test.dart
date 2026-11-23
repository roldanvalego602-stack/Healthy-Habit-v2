import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/perfil/profile_banner.dart';

void main() {
  testWidgets('el banner conserva una proporción 8:3 en ambos tamaños',
      (tester) async {
    for (final width in <double>[280, 360, 440]) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: const ProfileBanner(
                bannerStyle: 'Atardecer',
                label: 'PERFIL PÚBLICO',
                fallbackColors: [Colors.green, Colors.teal],
              ),
            ),
          ),
        ),
      ));
      final size = tester.getSize(
        find.byKey(const ValueKey('healthy-profile-banner')),
      );
      expect(size.width, closeTo(width, 0.01));
      expect(size.height,
          closeTo(width / ProfileBanner.aspectRatio, 0.01));
      expect(find.text('PERFIL PÚBLICO'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('el banner propio utiliza el mismo componente',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: ProfileBanner(
            bannerStyle: 'Atardecer',
            label: 'ATARDECER',
            fallbackColors: [Colors.orange, Colors.pink],
          ),
        ),
      ),
    ));
    expect(find.text('ATARDECER'), findsOneWidget);
    expect(tester.getSize(
      find.byKey(const ValueKey('healthy-profile-banner')),
    ).height, closeTo(120, 0.01));
  });
}
