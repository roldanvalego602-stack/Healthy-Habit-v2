import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/nutri_calculator_service.dart';

void main() {
  group('Calculadora integrada del chatbot', () {
    test('IMC solicita confirmación de medidas antes del resultado', () {
      final calc = NutriCalculatorService();
      expect(calc.procesarMensaje('Quiero calcular mi IMC'), contains('IMC'));
      expect(calc.pasoIMC, 1);
      expect(calc.opcionesRapidas, contains('Sí'));

      calc.procesarMensaje('Sí');
      expect(calc.pasoIMC, 2);
      calc.procesarMensaje('70 kg');
      expect(calc.pasoIMC, 3);

      final confirmation = calc.procesarMensaje('1.70 m');
      expect(confirmation, contains('¿Es correcto?'));
      expect(calc.pasoIMC, 4);
      expect(calc.opcionesRapidas, contains('Sí, es correcto'));

      final result = calc.procesarMensaje('Sí, es correcto');
      expect(result, contains('24.2'));
      expect(calc.pasoIMC, 0);
    });

    test('GET permite elegir sexo privado, validar datos y seleccionar actividad', () {
      final calc = NutriCalculatorService();
      calc.procesarMensaje('calcular GET');
      calc.procesarMensaje('Sí');
      expect(calc.opcionesRapidas, contains('Prefiero no decirlo'));
      calc.procesarMensaje('Prefiero no decirlo');
      expect(calc.pasoGET, 2);

      calc.procesarMensaje('70 kg');
      calc.procesarMensaje('1.70 m');
      final confirmation = calc.procesarMensaje('25 años');
      expect(confirmation, contains('¿Es correcto?'));
      calc.procesarMensaje('Sí, es correcto');

      expect(calc.opcionesRapidas, contains('Moderada'));
      final result = calc.procesarMensaje('Moderada');
      expect(result, contains('Gasto Energético Total'));
      expect(calc.opcionesRapidas, contains('Sí'));
    });

    test('consulta fuera de tema permite cancelar sin consumir datos previos', () {
      final calc = NutriCalculatorService();
      calc.procesarMensaje('imc');
      calc.procesarMensaje('Sí');
      calc.procesarMensaje('70 kg');
      expect(calc.pasoIMC, 3);

      final response = calc.procesarMensaje('¿Qué clima hay?');
      expect(response, contains('¿Deseas continuar o salir?'));
      expect(calc.pasoIMC, 3);
      expect(calc.opcionesRapidas, contains('Salir del cálculo'));
      calc.procesarMensaje('Salir del cálculo');
      expect(calc.pasoIMC, 0);
    });

    test('reiniciar conversación borra pasos y confirmaciones pendientes', () {
      final calc = NutriCalculatorService();
      calc.procesarMensaje('imc');
      calc.procesarMensaje('Sí');
      calc.procesarMensaje('70 kg');
      calc.procesarMensaje('¿Qué clima hay?');
      calc.reset();

      expect(calc.pasoIMC, 0);
      expect(calc.pasoGET, 0);
      expect(calc.opcionesRapidas, isEmpty);
      expect(calc.procesarMensaje('Hola'), isEmpty);
    });
  });
}
