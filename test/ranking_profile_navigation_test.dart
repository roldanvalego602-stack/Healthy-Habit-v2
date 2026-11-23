import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/ranking_screen.dart';
import 'package:healthy_habit/páginas/perfil/profile_avatar.dart';

void main() {
  testWidgets('un puesto del podio permite abrir el perfil seleccionado',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RankingPodiumCard(
          rank: 1,
          name: 'Participante',
          xp: 700,
          compact: true,
          avatarPreset: 'avatar_snowman',
          onTap: (_) => tapped = true,
        ),
      ),
    ));
    expect(find.byType(HealthyProfileAvatar), findsOneWidget);
    expect(find.byKey(const ValueKey('ranking-podio-abrir-perfil-1')),
        findsOneWidget);
    await tester.tap(find.byKey(
      const ValueKey('ranking-podio-abrir-perfil-1')));
    expect(tapped, isTrue);
  });

  testWidgets('un podio sin interacción sigue mostrando sus datos',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: RankingPodiumCard(
          rank: 2, name: 'Participante', xp: 100,
        ),
      ),
    ));
    expect(find.text('Participante'), findsOneWidget);
    expect(find.text('100 XP'), findsOneWidget);
  });
}
