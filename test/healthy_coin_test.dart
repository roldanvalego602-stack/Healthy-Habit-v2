import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/tema/healthy_coin.dart';

void main() {
  testWidgets('Habit Coins use the official asset, never a currency emoji',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          HealthyCoinIcon(size: 28),
          HealthyCoinAmount(amount: '125', suffix: ' Habit Coins'),
          HealthyCoinIcon(premium: true, size: 28),
        ]),
      ),
    ));
    final normal = tester.widget<Image>(
      find.byKey(const ValueKey('healthy-habit-coin')).first);
    final premium = tester.widget<Image>(
      find.byKey(const ValueKey('healthy-premium-coin')));
    expect((normal.image as AssetImage).assetName,
      HealthyCoinIcon.asset);
    expect((premium.image as AssetImage).assetName,
      HealthyCoinIcon.premiumAsset);
    expect(find.text('125 Habit Coins'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('coin label remains readable on narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(12),
          child: HealthyCoinAmount(
            amount: '1200',
            suffix: ' Habit Coins',
            size: 19,
          ),
        ),
      ),
    ));
    expect(find.text('1200 Habit Coins'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
