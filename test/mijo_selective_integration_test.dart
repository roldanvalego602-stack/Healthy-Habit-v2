import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/nutri_calculator_service.dart';
import 'package:healthy_habit/servicios/clima_servicio.dart';

void main() {
  group('Mejoras selectivas importadas de la rama Mijo', () {
    test('el clima se representa con datos reales sin coordenadas', () {
      const weather = ClimaActual(
        ciudad: 'tu zona',
        temperatura: 33.7,
        sensacion: 35.2,
        humedad: 48,
        viento: 9,
        lluviaMm: 0,
        codigo: 1,
        esDeDia: true,
        ubicacionAproximada: true,
      );
      expect(weather.consejo, contains('calor'));
      expect(weather.mensaje, contains('ubicación aproximada'));
      expect(weather.mensaje, contains('34 °C'));
      expect(weather.mensaje, isNot(contains('latitud')));
    });

    test('durante tormenta recomienda actividad bajo techo', () {
      const weather = ClimaActual(
        ciudad: 'tu zona', temperatura: 22, sensacion: 22,
        humedad: 90, viento: 28, lluviaMm: 12,
        codigo: 95, esDeDia: false, ubicacionAproximada: true,
      );
      expect(weather.estaLloviendo, isTrue);
      expect(weather.consejo, contains('tormenta'));
    });

    test('el cálculo de IMC permite seguir sin perder el paso', () {
      final calculator = NutriCalculatorService();
      calculator.procesarMensaje('IMC');
      expect(calculator.pasoIMC, 1);
      calculator.procesarMensaje('sí');
      expect(calculator.pasoIMC, 2);
      final response = calculator.procesarMensaje(
        '¿Qué clima hace hoy?');
      expect(response, contains('¿Deseas continuar o salir?'));
      expect(calculator.pasoIMC, 2);
      expect(calculator.opcionesRapidas, contains('Continuar cálculo'));
      expect(calculator.procesarMensaje('Continuar cálculo'),
        contains('peso'));
      expect(calculator.pasoIMC, 2);
      calculator.procesarMensaje('70 kg');
      expect(calculator.pasoIMC, 3);
    });

    test('salir del cálculo elimina el estado sin consultar otros datos', () {
      final calculator = NutriCalculatorService();
      calculator.procesarMensaje('GET');
      expect(calculator.pasoGET, 1);
      calculator.procesarMensaje('clima');
      expect(calculator.opcionesRapidas, hasLength(2));
      expect(calculator.procesarMensaje('Salir del cálculo'),
        contains('cancelado'));
      expect(calculator.pasoGET, 0);
      expect(calculator.opcionesRapidas, isEmpty);
    });

    test('cancelación original también elimina pregunta pendiente', () {
      final calculator = NutriCalculatorService();
      calculator.procesarMensaje('IMC');
      calculator.procesarMensaje('clima');
      calculator.resetIMC();
      expect(calculator.opcionesRapidas, isEmpty);
    });
  });
}
