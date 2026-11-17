import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/servicios/mr_healthy_intent_service.dart';

void main() {
  test('convierte una respuesta válida a una intención tipada', () async {
    String? sent;
    final service = MrHealthyIntentService(
      transport: (message) async {
        sent = message;
        return <String, dynamic>{
          'intent': 'SHOW_PROGRESS',
          'method': 'rules_v1',
          'requiresConfirmation': false,
        };
      },
    );

    final result = await service.interpret('  ¿Cómo voy esta semana?  ');
    expect(sent, '¿Cómo voy esta semana?');
    expect(result.intent, MrHealthyIntent.showProgress);
    expect(result.method, 'rules_v1');
    expect(result.requiresConfirmation, isFalse);
  });

  test('registrar hábitos siempre requiere confirmación', () async {
    final service = MrHealthyIntentService(
      transport: (_) async => <String, dynamic>{
        'intent': 'REGISTER_HABIT',
        'method': 'rules_v1',
        'requiresConfirmation': false,
      },
    );

    final result = await service.interpret('Ya bebí agua');
    expect(result.intent, MrHealthyIntent.registerHabit);
    expect(result.requiresConfirmation, isTrue);
  });

  test('intenciones nuevas se manejan sin ejecutar acciones', () async {
    final service = MrHealthyIntentService(
      transport: (_) async => <String, dynamic>{
        'intent': 'UNRECOGNIZED_INTENT',
        'method': 'rules_v1',
        'requiresConfirmation': false,
      },
    );

    final result = await service.interpret('Algo nuevo');
    expect(result.intent, MrHealthyIntent.unknown);
  });

  test('rechaza mensajes vacíos antes de contactar el servidor', () async {
    var calls = 0;
    final service = MrHealthyIntentService(
      transport: (_) async {
        calls++;
        return <String, dynamic>{};
      },
    );
    await expectLater(service.interpret('   '), throwsArgumentError);
    await expectLater(service.interpret('a' * 501), throwsArgumentError);
    expect(calls, 0);
  });

  test('rechaza respuestas mal formadas', () async {
    final service = MrHealthyIntentService(
      transport: (_) async => <String, dynamic>{
        'intent': 42,
        'method': 'rules_v1',
        'requiresConfirmation': false,
      },
    );
    await expectLater(service.interpret('Mi progreso'), throwsFormatException);
  });

  test('propaga errores de transporte para que la interfaz use fallback', () async {
    final service = MrHealthyIntentService(
      transport: (_) async => throw StateError('sin conexión'),
    );
    await expectLater(service.interpret('Mi progreso'), throwsStateError);
  });
}
