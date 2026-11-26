import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/páginas/tienda/season_pass_preview_screen.dart';

void main() {
  testWidgets('el pase ficticio muestra recompensas sin cobrar',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
      home: SeasonPassPreviewScreen(),
    ));
    expect(find.text('Cultiva tu leyenda'), findsOneWidget);
    expect(find.textContaining('precio ficticio'), findsOneWidget);

    final premiumButton = find.byKey(
      const ValueKey('season-demo-premium'));
    await tester.scrollUntilVisible(
      premiumButton, 150, scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(premiumButton);
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('al cambiar de carril se visualizan premios exclusivos',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SeasonPassPreviewScreen(),
    ));
    expect(find.text('Ruta gratuita'), findsWidgets);
    await tester.tap(find.text('Ruta premium').first);
    await tester.pumpAndSettle();
    expect(find.text('Aura exclusiva'), findsOneWidget);
    expect(find.byKey(const ValueKey('season-reward-1-premium')),
      findsOneWidget);
  });
}
