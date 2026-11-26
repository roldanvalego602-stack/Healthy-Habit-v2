import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/healthy_typing_indicator.dart';

void main() {
  testWidgets('El indicador muestra texto y exactamente tres puntos',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: HealthyTypingIndicator()),
    ));
    expect(find.text('Mr. Healthy está escribiendo'), findsOneWidget);
    expect(find.byKey(const ValueKey('mr-healthy-typing-indicator')),
        findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
