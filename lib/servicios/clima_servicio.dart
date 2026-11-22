import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class ClimaActual {
  final String ciudad;
  final double temperatura;
  final double sensacion;
  final int humedad;
  final double viento;
  final double lluviaMm;
  final int codigo;
  final bool esDeDia;
  final bool ubicacionAproximada;

  const ClimaActual({
    required this.ciudad,
    required this.temperatura,
    required this.sensacion,
    required this.humedad,
    required this.viento,
    required this.lluviaMm,
    required this.codigo,
    required this.esDeDia,
    required this.ubicacionAproximada,
  });

  /// Descripción en español del código de clima de Open-Meteo (WMO).
  String get descripcion {
    if (codigo == 0) return esDeDia ? 'Despejado' : 'Cielo despejado';
    if (codigo == 1) return 'Mayormente despejado';
    if (codigo == 2) return 'Parcialmente nublado';
    if (codigo == 3) return 'Nublado';
    if (codigo == 45 || codigo == 48) return 'Niebla';
    if (codigo >= 51 && codigo <= 57) return 'Llovizna';
    if (codigo >= 61 && codigo <= 67) return 'Lluvia';
    if (codigo >= 71 && codigo <= 77) return 'Nieve';
    if (codigo >= 80 && codigo <= 82) return 'Chubascos';
    if (codigo == 85 || codigo == 86) return 'Chubascos de nieve';
    if (codigo >= 95) return 'Tormenta eléctrica';
    return 'Clima variable';
  }

  String get emoji {
    if (codigo == 0 || codigo == 1) return esDeDia ? '☀️' : '🌙';
    if (codigo == 2) return '⛅';
    if (codigo == 3) return '☁️';
    if (codigo == 45 || codigo == 48) return '🌫️';
    if (codigo >= 51 && codigo <= 67) return '🌧️';
    if (codigo >= 71 && codigo <= 77) return '❄️';
    if (codigo >= 80 && codigo <= 86) return '🌦️';
    if (codigo >= 95) return '⛈️';
    return '🌤️';
  }

  bool get estaLloviendo =>
      lluviaMm > 0 || (codigo >= 51 && codigo <= 67) || codigo >= 80;

  /// Consejo de hábitos según el clima actual.
  String get consejo {
    if (codigo >= 95) {
      return 'Hay tormenta: mejor haz tu actividad en casa y mantente hidratado.';
    }
    if (estaLloviendo) {
      return 'Está lloviendo: es buen momento para ejercicio en casa, como '
          'estiramientos o una rutina corta.';
    }
    if (sensacion >= 32) {
      return 'Hace mucho calor: toma agua con frecuencia y evita ejercitarte '
          'al aire libre en las horas más calurosas.';
    }
    if (sensacion <= 10) {
      return 'Hace frío: abrígate bien y haz un buen calentamiento antes de '
          'ejercitarte.';
    }
    return 'Buen clima para una caminata. Recuerda tomar agua durante el día.';
  }

  String get mensaje {
    final lugar =
        ubicacionAproximada ? '$ciudad (ubicación aproximada)' : ciudad;
    return '$emoji Clima en $lugar\n\n'
        '$descripcion, ${temperatura.round()} °C '
        '(sensación térmica ${sensacion.round()} °C)\n'
        '• Humedad: $humedad %\n'
        '• Viento: ${viento.round()} km/h\n'
        '${lluviaMm > 0 ? '• Lluvia: ${lluviaMm.toStringAsFixed(1)} mm\n' : ''}'
        '\n$consejo';
  }
}

class ClimaException implements Exception {
  final String message;
  const ClimaException(this.message);

  @override
  String toString() => message;
}

class ClimaServicio {
  static const _timeout = Duration(seconds: 10);

  /// Ubicación únicamente bajo petición explícita del usuario.
  /// No consulta servicios de geolocalización por IP si rechaza permisos.
  Future<ClimaActual> obtenerClimaActual() async {
    final posicion = await _posicionDelDispositivo();
    if (posicion == null) {
      throw const ClimaException(
        'Para mostrar el clima necesito permiso de ubicación. '
        'Puedes habilitarlo en los ajustes del dispositivo. '
        'No consultaré tu ubicación mediante la IP.',
      );
    }
    // Precisión aproximada (~1 km) suficiente para el tiempo meteorológico.
    // No se guarda ni se incluye la coordenada en el historial del chat.
    final latitud = double.parse(posicion.latitude.toStringAsFixed(2));
    final longitud = double.parse(posicion.longitude.toStringAsFixed(2));
    const ciudad = 'tu zona';

    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$latitud',
      'longitude': '$longitud',
      'current':
          'temperature_2m,apparent_temperature,relative_humidity_2m,'
          'precipitation,weather_code,wind_speed_10m,is_day',
      'timezone': 'auto',
    });

    final respuesta = await _get(uri);
    final actual = respuesta['current'] as Map<String, dynamic>?;
    if (actual == null) {
      throw const ClimaException('No pude leer los datos del clima.');
    }

    return ClimaActual(
      ciudad: ciudad,
      temperatura: (actual['temperature_2m'] as num).toDouble(),
      sensacion: (actual['apparent_temperature'] as num).toDouble(),
      humedad: (actual['relative_humidity_2m'] as num).round(),
      viento: (actual['wind_speed_10m'] as num).toDouble(),
      lluviaMm: (actual['precipitation'] as num).toDouble(),
      codigo: (actual['weather_code'] as num).toInt(),
      esDeDia: (actual['is_day'] as num?) != 0,
      ubicacionAproximada: true,
    );
  }

  /// Posición del dispositivo, o null si no hay permiso o servicio de ubicación.
  Future<Position?> _posicionDelDispositivo() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    try {
      final respuesta = await http.get(uri).timeout(_timeout);
      if (respuesta.statusCode != 200) {
        throw ClimaException(
          'Error ${respuesta.statusCode} al consultar el clima.',
        );
      }
      return jsonDecode(respuesta.body) as Map<String, dynamic>;
    } on ClimaException {
      rethrow;
    } on TimeoutException {
      throw const ClimaException(
        'La consulta del clima tardó demasiado. Inténtalo de nuevo.',
      );
    } catch (_) {
      throw const ClimaException(
        'No pude consultar el clima. Revisa tu conexión a internet.',
      );
    }
  }
}
