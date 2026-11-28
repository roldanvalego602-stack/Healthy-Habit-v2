import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/servicios/healthy_food_model_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('healthy_habit/food_model');
  final messenger = TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('consulta estado sin enviar imágenes ni activar la descarga', () async {
    final names = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      names.add(call.method);
      expect(call.arguments, isNull);
      return {'installed': false, 'title': 'Modelo optativo'};
    });
    final status = await const HealthyFoodModelService().status();
    expect(status.installed, isFalse);
    expect(names, ['status']);
  });

  test('solo el usuario puede iniciar instalación del modelo', () async {
    final names = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      names.add(call.method);
      expect(call.arguments, isNull);
      return {'installed': true, 'title': 'SekoKuva Mobile 423K'};
    });
    final status = await const HealthyFoodModelService().install();
    expect(status.installed, isTrue);
    expect(names, ['install']);
  });

  test('clasificación entrega etiquetas originales del modelo y nada más',
      () async {
    final photo = Uint8List.fromList(
      [0xff, 0xd8, 0xff, ...List.filled(20, 0), 0xff, 0xd9]);
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'classify');
      final arguments = Map<String, dynamic>.from(call.arguments as Map);
      expect(arguments.keys, ['jpeg']);
      expect(arguments['jpeg'], photo);
      return {
        'installed': true, 'model': 'SekoKuva Mobile 423K',
        'labels': [
          {'name': 'watermelon', 'score': .81},
          {'name': 'carrot', 'score': .06},
          {'name': 'banana', 'score': -4}, // ignorar salida inválida
        ],
      };
    });
    final result = await const HealthyFoodModelService().analyze(photo);
    expect(result.labels.length, 2);
    expect(result.labels.first.name, 'watermelon');
    expect(result.labels.first.confidence, .81);
  });

  test('el motor rechaza imágenes vacías antes de llamar Android', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      return null;
    });
    await expectLater(const HealthyFoodModelService()
        .analyze(Uint8List(0)), throwsArgumentError);
    expect(calls, 0);
  });
}
