import 'package:flutter/material.dart';

class NutriCalculatorService {
  // Estados para IMC
  int pasoIMC = 0;
  double? pesoUsuario;
  bool pesoIMCEnLibras = false;

  // Estados para GET
  int pasoGET = 0;
  String? sexoGET;
  double? pesoGET;
  double? alturaGET;
  int? edadGET;
  double? factorActividadGET;
  double? porcentajeTAGET;
  double? tmbGET;
  double? gebGET;
  double? etaGET;
  double? taGET;
  double? getTotalGET;

  void resetGET() {
    pasoGET = 0;
    sexoGET = null;
    pesoGET = null;
    alturaGET = null;
    edadGET = null;
    factorActividadGET = null;
    porcentajeTAGET = null;
    tmbGET = null;
    gebGET = null;
    etaGET = null;
    taGET = null;
    getTotalGET = null;
  }

  void resetIMC() {
    pasoIMC = 0;
    pesoUsuario = null;
    pesoIMCEnLibras = false;
  }

  String procesarMensaje(String input) {
    final text = input.toLowerCase();

    // ==========================================
    // 1. FLUJO DE GASTO ENERGÉTICO TOTAL (GET)
    // ==========================================
    if (pasoGET == 1) {
      if (_containsAny(text, [
        'hombre',
        'masculino',
        'Hombre',
        'HOMBRE',
        'Masculino',
        'MASCULINO',
      ])) {
        sexoGET = 'hombre';
        pasoGET = 2;
        return 'Perfecto. ¿Cuál es tu peso? Puedes escribirlo en kilogramos '
            '(por ejemplo: 70 kg) o en libras (por ejemplo: 150 lb).';
      }
      if (_containsAny(text, [
        'mujer',
        'femenino',
        'Mujer',
        'MUJER',
        'Femenino',
        'FEMENINO',
      ])) {
        sexoGET = 'mujer';
        pasoGET = 2;
        return 'Perfecto. ¿Cuál es tu peso? Puedes escribirlo en kilogramos '
            '(por ejemplo: 60 kg) o en libras (por ejemplo: 130 lb).';
      }
      if (_containsAny(text, [
        'si',
        'sí',
        'claro',
        'ok',
        'dale',
        'Si',
        'Sí',
        'SÍ',
        'Claro',
        'CLARO',
        'Ok',
        'OK',
        'Dale',
        'DALE',
      ])) {
        return 'Perfecto. Primero dime tu sexo: escribe "hombre" o "mujer".';
      }
      if (_containsAny(text, [
        'no',
        'nope',
        'no gracias',
        'nel',
        'luego',
        'despues',
        'después',
        'mejor no',
        'No',
        'NO',
        'Nope',
        'NOPE',
        'No gracias',
        'NO GRACIAS',
        'Nel',
        'NEL',
        'Luego',
        'LUEGO',
        'Después',
        'DESPUÉS',
        'Mejor no',
        'MEJOR NO',
      ])) {
        resetGET();
        return 'Está bien. Si en otro momento quieres calcularlo, aquí estaré.';
      }
      return 'Por favor dime tu sexo: escribe "hombre" o "mujer".';
    }

    if (pasoGET == 2) {
      final peso = _parseWeightInKilograms(text);
      if (peso == null) {
        return 'No entendí tu peso. Escríbelo en kg (por ejemplo: 70 kg) o '
            'en libras (por ejemplo: 150 lb).';
      }
      pesoGET = peso;
      pasoGET = 3;
      return 'Gracias. Ahora dime tu altura en metros, centímetros o pies '
          '(por ejemplo: 1.70 m, 170 cm o 5 pies 10 pulgadas).';
    }

    if (pasoGET == 3) {
      final altura = _parseHeightInMeters(text);
      if (altura == null) {
        return 'No entendí tu altura. Escríbela como 1.70 m, 170 cm o '
            '5 pies 10 pulgadas.';
      }
      alturaGET = altura;
      pasoGET = 4;
      return 'Gracias. Ahora dime tu edad en años, por ejemplo: 25 años';
    }

    if (pasoGET == 4) {
      final edadMatch = RegExp(r'^\s*(\d+)\s*(?:años?)?\s*$').firstMatch(text);
      final edad = edadMatch == null ? null : int.tryParse(edadMatch.group(1)!);
      if (edad == null || edad <= 0 || edad > 120) {
        return 'No entendí tu edad. Escríbela en años, por ejemplo: 25 años';
      }
      edadGET = edad;
      pasoGET = 5;
      return 'Ahora dime tu nivel de actividad física:\n\n'
          '1. Muy sedentaria (poco o nada de ejercicio) → TA 30%\n'
          '2. Sedentaria (ejercicio ligero) → TA 50%\n'
          '3. Moderada (3-5 días por semana) → TA 75%\n'
          '4. Activa (6-7 días por semana) → TA 100%\n\n'
          'Responde con el número o la palabra.';
    }

    if (pasoGET == 5) {
      double? factor;
      double? porcentajeTA;
      if (_containsAny(text, [
        '1',
        'muy sedentario',
        'muy sedentaria',
        'Muy sedentario',
        'Muy sedentaria',
        'MUY SEDENTARIO',
        'MUY SEDENTARIA',
      ])) {
        factor = 1.25;
        porcentajeTA = 0.30;
      } else if (_containsAny(text, [
        '2',
        'sedentario',
        'sedentaria',
        'Sedentario',
        'Sedentaria',
        'SEDENTARIO',
        'SEDENTARIA',
      ])) {
        factor = 1.5;
        porcentajeTA = 0.50;
      } else if (_containsAny(text, [
        '3',
        'moderado',
        'moderada',
        'Moderado',
        'Moderada',
        'MODERADO',
        'MODERADA',
      ])) {
        factor = 1.75;
        porcentajeTA = 0.75;
      } else if (_containsAny(text, [
        '4',
        'activo',
        'activa',
        'atleta',
        'Activo',
        'Activa',
        'Atleta',
        'ACTIVO',
        'ACTIVA',
        'ATLETA',
      ])) {
        factor = 2.2;
        porcentajeTA = 1.00;
      }

      if (factor == null || porcentajeTA == null) {
        return 'No entendí tu nivel de actividad. Elige un número del 1 al 4.';
      }

      factorActividadGET = factor;
      porcentajeTAGET = porcentajeTA;
      final peso = pesoGET ?? 0;
      final alturaCm = (alturaGET ?? 0) * 100;
      final edad = edadGET ?? 0;
      final sexo = sexoGET ?? 'hombre';
      final tmb =
          sexo == 'hombre'
              ? (10 * peso) + (6.25 * alturaCm) - (5 * edad) + 5
              : (10 * peso) + (6.25 * alturaCm) - (5 * edad) - 161;

      gebGET = tmb;
      etaGET = tmb * 0.10;
      taGET = tmb * (porcentajeTAGET ?? 0.30);

      final geb = gebGET ?? 0;
      final eta = etaGET ?? 0;
      final ta = taGET ?? 0;
      final getTotal = geb + eta + ta;
      getTotalGET = getTotal;
      pasoGET = 8;

      return 'Tu Gasto Energético Total (GET) es ${getTotal.toStringAsFixed(0)} kcal/día.\n\n¿Quieres ver la distribución de macronutrientes? (Responde "sí" o "no")';
    }

    if (pasoGET == 8) {
      if (_containsAny(text, [
        'si',
        'sí',
        'claro',
        'ok',
        'dale',
        'yes',
        'Si',
        'Sí',
        'SÍ',
        'Claro',
        'CLARO',
        'Ok',
        'OK',
        'Dale',
        'DALE',
        'Yes',
        'YES',
      ])) {
        pasoGET = 9;
        return '¿Qué tipo de distribución prefieres?\n1. Balanceada (50% HC / 30% Lípidos / 20% Proteínas)\n2. Estándar (60% HC / 25% Lípidos / 15% Proteínas)\n3. Baja en carbohidratos (40% / 35% / 25%)\n4. Alta en proteínas (45% / 25% / 30%)\nResponde con el número.';
      }
      resetGET();
      return '¡Entendido!';
    }

    if (pasoGET == 9) {
      double? pHC, pLipidos, pProt;
      String tipo = '';

      if (_containsAny(text, ['1', 'balanceada', 'Balanceada', 'BALANCEADA'])) {
        pHC = 0.50;
        pLipidos = 0.30;
        pProt = 0.20;
        tipo = 'Balanceada';
      } else if (_containsAny(text, [
        '2',
        'estandar',
        'estándar',
        'Estándar',
        'ESTÁNDAR',
        'Estandar',
        'ESTANDAR',
      ])) {
        pHC = 0.60;
        pLipidos = 0.25;
        pProt = 0.15;
        tipo = 'Estándar';
      } else if (_containsAny(text, [
        '3',
        'baja en carbohidratos',
        'Baja en carbohidratos',
        'BAJA EN CARBOHIDRATOS',
        'low carb',
        'Low carb',
        'LOW CARB',
      ])) {
        pHC = 0.40;
        pLipidos = 0.35;
        pProt = 0.25;
        tipo = 'Baja en carbohidratos';
      } else if (_containsAny(text, [
        '4',
        'alta en proteinas',
        'alta en proteínas',
        'Alta en proteínas',
        'ALTA EN PROTEÍNAS',
        'Alta en proteinas',
        'ALTA EN PROTEINAS',
      ])) {
        pHC = 0.45;
        pLipidos = 0.25;
        pProt = 0.30;
        tipo = 'Alta en proteínas';
      } else {
        return 'No entendí tu elección. Responde un número del 1 al 4.';
      }

      final get = getTotalGET ?? 0;
      final gHC = (get * pHC) / 4;
      final gLip = (get * pLipidos) / 9;
      final gProt = (get * pProt) / 4;

      resetGET();
      return 'Distribución ($tipo) para ${get.toStringAsFixed(0)} kcal:\n• Hidratos de carbono: ${gHC.toStringAsFixed(1)} g\n• Lípidos: ${gLip.toStringAsFixed(1)} g\n• Proteínas: ${gProt.toStringAsFixed(1)} g';
    }

    // ==========================================
    // 2. FLUJO DE ÍNDICE DE MASA CORPORAL (IMC)
    // ==========================================
    if (pasoIMC == 1) {
      if (_containsAny(text, [
        'si',
        'sí',
        'claro',
        'ok',
        'dale',
        'yes',
        'Si',
        'Sí',
        'SÍ',
        'Claro',
        'CLARO',
        'Ok',
        'OK',
        'Dale',
        'DALE',
        'Yes',
        'YES',
      ])) {
        pasoIMC = 2;
        return '¿Cuál es tu peso? Puedes escribirlo en kilogramos '
            '(por ejemplo: 65 kg) o en libras (por ejemplo: 150 lb).';
      }
      resetIMC();
      return 'Está bien.';
    }

    if (pasoIMC == 2) {
      final peso = _parseWeightInKilograms(text);
      if (peso == null) {
        return 'No entendí tu peso. Escríbelo en kg (por ejemplo: 65 kg) o '
            'en libras (por ejemplo: 150 lb).';
      }
      pesoUsuario = peso;
      pesoIMCEnLibras = _weightWasEnteredInPounds(text);
      pasoIMC = 3;
      return 'Gracias. Ahora dime tu altura en metros, centímetros o pies '
          '(por ejemplo: 1.70 m, 170 cm o 5 pies 10 pulgadas).';
    }

    if (pasoIMC == 3) {
      final altura = _parseHeightInMeters(text);
      if (altura == null) {
        return 'No entendí tu altura. Escríbela como 1.70 m, 170 cm o '
            '5 pies 10 pulgadas.';
      }
      final pesoCalculado = pesoUsuario ?? 0;
      final imc = pesoCalculado / (altura * altura);
      final pesoIngresadoEnLibras = pesoIMCEnLibras;
      resetIMC();

      String clasificacion =
          imc < 18.5
              ? 'Bajo peso'
              : imc < 25
              ? 'Peso normal'
              : imc < 30
              ? 'Sobrepeso'
              : 'Obesidad';

      final pesoConvertido =
          pesoIngresadoEnLibras
              ? 'El peso convertido es ${pesoCalculado.toStringAsFixed(1)} kg. '
              : '';
      return '${pesoConvertido}Tu IMC es ${imc.toStringAsFixed(1)} kg/m², '
          'lo que corresponde a: $clasificacion.';
    }

    if (_containsAny(text, [
      'get',
      'gasto energetico',
      'gasto energético',
      'calorias diarias',
    ])) {
      pasoGET = 1;
      return 'El Gasto Energético Total (GET) calcula tus calorías diarias. ¿Quieres calcular el tuyo? Responde "sí".';
    }

    if (_containsAny(text, [
      'imc',
      'indice de masa corporal',
      'índice de masa corporal',
    ])) {
      pasoIMC = 1;
      return 'El IMC evalúa tu peso en relación con tu altura. ¿Quieres calcular tu IMC? Responde "sí".';
    }

    return '';
  }

  double? _parseHeightInMeters(String input) {
    final feetAndInchesMatch = RegExp(
      r'''^\s*(\d+)\s*(?:ft|feet|pies?|')\s*(\d+(?:[.,]\d+)?)\s*(?:in|inches|pulgadas?|")\s*$''',
    ).firstMatch(input.toLowerCase());
    if (feetAndInchesMatch != null) {
      final feet = double.parse(feetAndInchesMatch.group(1)!);
      final inches = double.parse(
        feetAndInchesMatch.group(2)!.replaceAll(',', '.'),
      );
      if (feet <= 0 || inches >= 12) return null;
      final heightInMeters = (feet * 12 + inches) * 0.0254;
      return heightInMeters <= 3 ? heightInMeters : null;
    }

    final feetMatch = RegExp(
      r"^\s*(\d+(?:[.,]\d+)?)\s*(?:ft|feet|pies?|')\s*$",
    ).firstMatch(input.toLowerCase());
    if (feetMatch != null) {
      final feet = double.tryParse(feetMatch.group(1)!.replaceAll(',', '.'));
      if (feet == null || feet <= 0) return null;
      final heightInMeters = feet * 0.3048;
      return heightInMeters <= 3 ? heightInMeters : null;
    }

    final match = RegExp(
      r'^\s*(\d+(?:[.,]\d+)?)\s*(cm|m)?\s*$',
    ).firstMatch(input.toLowerCase());
    if (match == null) return null;

    final value = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (value == null || value <= 0) return null;

    final unit = match.group(2);
    final heightInMeters =
        unit == 'cm' || (unit == null && value > 3) ? value / 100 : value;
    if (heightInMeters > 3) return null;

    return heightInMeters;
  }

  double? _parseWeightInKilograms(String input) {
    final match = RegExp(
      r'^\s*(\d+(?:[.,]\d+)?)\s*(kg|kgs|kilogramos?|kilos?|lb|lbs|libras?)?\s*$',
    ).firstMatch(input.toLowerCase());
    if (match == null) return null;

    final value = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (value == null || value <= 0) return null;

    final unit = match.group(2);
    final weightInKilograms =
        unit == 'lb' || unit == 'lbs' || unit == 'libra' || unit == 'libras'
            ? value * 0.45359237
            : value;
    if (weightInKilograms > 500) return null;

    return weightInKilograms;
  }

  bool _weightWasEnteredInPounds(String input) {
    return RegExp(r'(?:lb|lbs|libras?)\s*$').hasMatch(input.toLowerCase());
  }

  bool _containsAny(String text, List<String> keywords) {
    final normalizedText = _normalizeText(text);
    return keywords.any((word) {
      final normalizedWord = _normalizeText(word);
      if (normalizedWord.isEmpty) return false;
      final pattern = RegExp(
        r'(^|[^a-z0-9])' + RegExp.escape(normalizedWord) + r'($|[^a-z0-9])',
      );
      return pattern.hasMatch(normalizedText);
    });
  }

  String _normalizeText(String value) {
    final normalized = value.toLowerCase();
    final withoutAccents =
        normalized
            .replaceAll('á', 'a')
            .replaceAll('à', 'a')
            .replaceAll('ä', 'a')
            .replaceAll('â', 'a')
            .replaceAll('ã', 'a')
            .replaceAll('é', 'e')
            .replaceAll('è', 'e')
            .replaceAll('ë', 'e')
            .replaceAll('ê', 'e')
            .replaceAll('í', 'i')
            .replaceAll('ì', 'i')
            .replaceAll('ï', 'i')
            .replaceAll('î', 'i')
            .replaceAll('ó', 'o')
            .replaceAll('ò', 'o')
            .replaceAll('ö', 'o')
            .replaceAll('ô', 'o')
            .replaceAll('õ', 'o')
            .replaceAll('ú', 'u')
            .replaceAll('ù', 'u')
            .replaceAll('ü', 'u')
            .replaceAll('û', 'u')
            .replaceAll('ñ', 'n')
            .replaceAll('ç', 'c')
            .replaceAll(RegExp(r"[\u2018\u2019]"), "'")
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
    return withoutAccents;
  }
}
