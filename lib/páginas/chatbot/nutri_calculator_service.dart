import 'texto_chatbot.dart';

class NutriCalculatorService {
  // Palabras clave que inician cada cálculo (las usa también el chat).
  static const List<String> imcKeywords = [
    'imc',
    'indice de masa corporal',
    'masa corporal',
  ];
  static const List<String> getKeywords = [
    'get',
    'gasto energetico',
    'gasto calorico',
    'calorias diarias',
    'calorias necesito',
    'calorias al dia',
    'metabolismo basal',
    'tmb',
  ];

  static const List<String> _afirmativos = [
    'si',
    'claro',
    'ok',
    'dale',
    'yes',
    'va',
    'vale',
    'quiero',
    'adelante',
    'por favor',
    'aja',
  ];
  static const List<String> _negativos = [
    'no',
    'nope',
    'nel',
    'luego',
    'despues',
    'mejor no',
    'ahora no',
    'cancelar',
  ];

  static const String _preguntaSexo =
      'Primero elige tu sexo en las opciones de abajo.';

  static const List<String> _opcionesSexo = [
    'Hombre',
    'Mujer',
    'Prefiero no decirlo',
  ];

  /// Opciones que el chat muestra como botones según el paso actual.
  List<String> get opcionesRapidas {
    if (_confirmandoSalida) return ['Sí, seguir', 'No, salir'];
    switch (pasoGET) {
      case 1:
      case 8:
        return ['Sí', 'No'];
      case 11:
        return _opcionesSexo;
      case 10:
      case 12:
        return ['Sí, es correcto', 'No, corregir'];
      case 5:
        return ['Muy sedentaria', 'Sedentaria', 'Moderada', 'Activa'];
      case 9:
        return [
          'Balanceada',
          'Estándar',
          'Baja en carbohidratos',
          'Alta en proteínas',
        ];
    }
    switch (pasoIMC) {
      case 1:
        return ['Sí', 'No'];
      case 4:
        return ['Sí, es correcto', 'No, corregir'];
    }
    return const [];
  }

  // Estados para IMC
  int pasoIMC = 0;
  double? pesoUsuario;
  bool pesoIMCEnLibras = false;
  double? alturaIMC;

  // Aviso cuando se interpretó una altura dudosa (se muestra al validar).
  String? _notaAltura;

  // Estados para GET
  int pasoGET = 0;
  String? sexoGET; // 'hombre', 'mujer' u 'otro' (prefiero no decirlo)
  String? sexoEtiquetaGET;
  double? pesoGET;
  bool pesoGETEnLibras = false;
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
    sexoEtiquetaGET = null;
    pesoGET = null;
    pesoGETEnLibras = false;
    alturaGET = null;
    _notaAltura = null;
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
    alturaIMC = null;
    _notaAltura = null;
  }

  static const String _preguntaActividad =
      'Ahora dime tu nivel de actividad física:\n\n'
      '1. Muy sedentaria (poco o nada de ejercicio) → TA 30%\n'
      '2. Sedentaria (ejercicio ligero) → TA 50%\n'
      '3. Moderada (3-5 días por semana) → TA 75%\n'
      '4. Activa (6-7 días por semana) → TA 100%\n\n'
      'Responde con el número o la palabra.';

  static const String _preguntaDistribucion =
      '¿Qué tipo de distribución prefieres?\n'
      '1. Balanceada (50% HC / 30% Lípidos / 20% Proteínas)\n'
      '2. Estándar (60% HC / 25% Lípidos / 15% Proteínas)\n'
      '3. Baja en carbohidratos (40% / 35% / 25%)\n'
      '4. Alta en proteínas (45% / 25% / 30%)\n'
      'Responde con el número.';

  static const List<String> _palabrasSalir = [
    'salir',
    'cancelar',
    'terminar',
    'detener',
  ];

  // Verdadero mientras se espera que el usuario confirme si quiere salir.
  bool _confirmandoSalida = false;

  bool get _enCalculo => pasoGET > 0 || pasoIMC > 0;

  /// Procesa el mensaje del usuario. Si en medio de un cálculo escribe algo
  /// fuera de tema, pregunta si quiere salir en lugar de insistir con el dato.
  String procesarMensaje(String input) {
    if (_confirmandoSalida) return _resolverSalida(input);

    final texto = normalizeText(input);
    if (_enCalculo && _containsAny(texto, _palabrasSalir)) {
      return _salirDelCalculo();
    }

    final pasoGETAntes = pasoGET;
    final pasoIMCAntes = pasoIMC;
    final respuesta = _procesarFlujo(input);

    if (_enCalculo && _noEntendido(respuesta) && _pareceFueraDeTema(texto)) {
      // Se conserva el paso en el que estaba para poder retomarlo.
      pasoGET = pasoGETAntes;
      pasoIMC = pasoIMCAntes;
      _confirmandoSalida = true;
      final calculo = pasoGET > 0 ? 'el GET' : 'el IMC';
      return 'Eso no corresponde al cálculo de $calculo. '
          '¿Quieres seguir con la conversación del cálculo?\n\n'
          'Elige "sí" para continuar o "no" para salir.';
    }
    return respuesta;
  }

  bool _noEntendido(String respuesta) =>
      respuesta.startsWith('No entendí') ||
      respuesta.startsWith('No identifiqué') ||
      respuesta.startsWith('Responde');

  /// Una pregunta, o un texto sin números, no es un dato del cálculo.
  bool _pareceFueraDeTema(String texto) =>
      texto.contains('?') || !RegExp(r'\d').hasMatch(texto);

  String _resolverSalida(String input) {
    final texto = normalizeText(input);
    if (_containsAny(texto, _negativos) ||
        _containsAny(texto, _palabrasSalir)) {
      return _salirDelCalculo();
    }
    if (_containsAny(texto, _afirmativos) ||
        _containsAny(texto, ['continuar', 'seguir'])) {
      _confirmandoSalida = false;
      return 'Perfecto, continuemos.\n\n${_preguntaActual()}';
    }
    return 'Responde "sí" para seguir con el cálculo o "no" para salir.';
  }

  String _salirDelCalculo() {
    _confirmandoSalida = false;
    resetGET();
    resetIMC();
    return 'Listo, salí del cálculo. Cuando quieras retomarlo, pídeme calcular '
        'tu GET o tu IMC. ¿En qué más puedo ayudarte?';
  }

  /// Repite la pregunta del paso actual al retomar el cálculo.
  String _preguntaActual() {
    switch (pasoGET) {
      case 1:
        return '¿Quieres calcular tu Gasto Energético Total (GET)? '
            'Responde "sí".';
      case 11:
        return _preguntaSexo;
      case 2:
        return '¿Cuál es tu peso? Puedes escribirlo en kg (por ejemplo: 70 kg) '
            'o en libras (por ejemplo: 150 lb).';
      case 3:
        return 'Dime tu altura en metros, centímetros o pies '
            '(por ejemplo: 1.70 m, 170 cm o 5 pies 10 pulgadas).';
      case 4:
        return 'Dime tu edad en años, por ejemplo: 25 años';
      case 10:
      case 12:
        return '¿Es correcto lo que entendí? Responde "sí" para continuar o '
            '"no" para volver a ingresar tus datos.';
      case 5:
        return _preguntaActividad;
      case 8:
        return '¿Quieres ver la distribución de macronutrientes? '
            '(Responde "sí" o "no")';
      case 9:
        return _preguntaDistribucion;
    }
    switch (pasoIMC) {
      case 1:
        return '¿Quieres calcular tu IMC? Responde "sí".';
      case 2:
        return '¿Cuál es tu peso? Puedes escribirlo en kg (por ejemplo: 65 kg) '
            'o en libras (por ejemplo: 150 lb).';
      case 3:
        return 'Dime tu altura en metros, centímetros o pies '
            '(por ejemplo: 1.70 m, 170 cm o 5 pies 10 pulgadas).';
      case 4:
        return '¿Es correcto lo que entendí? Responde "sí" para calcular tu '
            'IMC o "no" para volver a ingresar tus datos.';
    }
    return '';
  }

  String _procesarFlujo(String input) {
    final text = input.toLowerCase();

    // ==========================================
    // 1. FLUJO DE GASTO ENERGÉTICO TOTAL (GET)
    // ==========================================
    if (pasoGET == 1 || pasoGET == 11) {
      final sexo = _detectarSexo(text);
      if (sexo != null) {
        sexoGET = sexo.clave;
        sexoEtiquetaGET = sexo.etiqueta;
        pasoGET = 2;
        final aviso =
            sexo.clave == 'otro'
                ? 'Gracias. Para tu cálculo usaré un valor específico que '
                    'promedia las fórmulas masculina y femenina, así que el '
                    'resultado es aproximado.\n\n'
                : 'Perfecto. ';
        return '$aviso¿Cuál es tu peso? Puedes escribirlo en kilogramos '
            '(por ejemplo: 65 kg) o en libras (por ejemplo: 150 lb).';
      }
      if (_containsAny(text, _afirmativos)) {
        pasoGET = 11;
        return _preguntaSexo;
      }
      if (pasoGET == 1 && _containsAny(text, _negativos)) {
        resetGET();
        return 'Está bien. Si en otro momento quieres calcularlo, aquí estaré.';
      }
      pasoGET = 11;
      return 'No identifiqué tu opción.\n\n$_preguntaSexo';
    }

    if (pasoGET == 2) {
      final peso = _parseWeightInKilograms(text);
      if (peso == null) {
        return 'No entendí tu peso. Escríbelo en kg (por ejemplo: 70 kg) o '
            'en libras (por ejemplo: 150 lb).';
      }
      pesoGET = peso;
      pesoGETEnLibras = _weightWasEnteredInPounds(text);

      final alturaEnFrase = _findHeightInPhrase(normalizeText(text));
      if (alturaEnFrase != null) return _continuarTrasAlturaGET(alturaEnFrase);

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
      return _continuarTrasAlturaGET(altura);
    }

    // Confirmación de una altura que se interpretó con duda (ej. "174 f").
    if (pasoGET == 12) {
      if (_containsAny(text, _negativos)) {
        pasoGET = 2;
        alturaGET = null;
        _notaAltura = null;
        return 'Sin problema, volvamos a ingresar tus datos. ¿Cuál es tu peso? '
            'Puedes escribirlo en kg (por ejemplo: 70 kg) o en libras '
            '(por ejemplo: 150 lb), y también tu altura si quieres.';
      }
      if (_containsAny(text, _afirmativos)) {
        pasoGET = 4;
        _notaAltura = null;
        return 'Gracias. Ahora dime tu edad en años, por ejemplo: 25 años';
      }
      return 'Responde "sí" si los datos son correctos o "no" para '
          'ingresarlos de nuevo.';
    }

    if (pasoGET == 4) {
      final edad = _parseAge(text);
      if (edad == null || edad <= 0 || edad > 120) {
        return 'No entendí tu edad. Escríbela en años, por ejemplo: 25 años';
      }
      edadGET = edad;
      pasoGET = 10;
      return 'Esto es lo que entendí:\n'
          '• Sexo: ${sexoEtiquetaGET ?? sexoGET}\n'
          '• Peso: ${_describirPeso(pesoGET ?? 0, pesoGETEnLibras)}\n'
          '• Altura: ${_describirAltura(alturaGET ?? 0)}\n'
          '• Edad: $edad años\n'
          '${_notaAltura == null ? '' : '\n⚠️ $_notaAltura\n'}'
          '\n¿Es correcto? Responde "sí" para continuar o "no" para '
          'volver a ingresar tus datos.';
    }

    if (pasoGET == 10) {
      if (_containsAny(text, _negativos)) {
        pasoGET = 2;
        _notaAltura = null;
        return 'Sin problema, volvamos a ingresar tus datos. ¿Cuál es tu peso? '
            'Puedes escribirlo en kg (por ejemplo: 70 kg) o en libras '
            '(por ejemplo: 150 lb), y también tu altura si quieres.';
      }
      if (_containsAny(text, _afirmativos)) {
        pasoGET = 5;
        return _preguntaActividad;
      }
      return 'Responde "sí" si los datos son correctos o "no" para '
          'ingresarlos de nuevo.';
    }

    if (pasoGET == 5) {
      double? factor;
      double? porcentajeTA;
      if (_containsAny(text, [
        '1',
        'muy sedentari*',
        'nada',
        'ningun*',
        'poco ejercicio',
      ])) {
        factor = 1.25;
        porcentajeTA = 0.30;
      } else if (_containsAny(text, ['2', 'sedentari*', 'ligero', 'ligera'])) {
        factor = 1.5;
        porcentajeTA = 0.50;
      } else if (_containsAny(text, ['3', 'moderad*', 'regular', 'medio'])) {
        factor = 1.75;
        porcentajeTA = 0.75;
      } else if (_containsAny(text, [
        '4',
        'activo',
        'activa',
        'atleta',
        'deportista',
        'intenso',
        'intensa',
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
      // Mifflin-St Jeor: +5 hombre, -161 mujer y -78 (promedio) para "prefiero no decirlo".
      final constanteSexo = switch (sexoGET) {
        'hombre' => 5,
        'mujer' => -161,
        _ => -78,
      };
      final tmb = (10 * peso) + (6.25 * alturaCm) - (5 * edad) + constanteSexo;

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
      if (_containsAny(text, _afirmativos)) {
        pasoGET = 9;
        return _preguntaDistribucion;
      }
      resetGET();
      return '¡Entendido!';
    }

    if (pasoGET == 9) {
      double? pHC, pLipidos, pProt;
      String tipo = '';

      if (_containsAny(text, ['1', 'balanceada', 'balanceado'])) {
        pHC = 0.50;
        pLipidos = 0.30;
        pProt = 0.20;
        tipo = 'Balanceada';
      } else if (_containsAny(text, ['2', 'estandar'])) {
        pHC = 0.60;
        pLipidos = 0.25;
        pProt = 0.15;
        tipo = 'Estándar';
      } else if (_containsAny(text, [
        '3',
        'baja en carbohidratos',
        'bajo en carbohidratos',
        'low carb',
      ])) {
        pHC = 0.40;
        pLipidos = 0.35;
        pProt = 0.25;
        tipo = 'Baja en carbohidratos';
      } else if (_containsAny(text, [
        '4',
        'alta en proteinas',
        'alto en proteinas',
        'mas proteinas',
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
      if (_containsAny(text, _afirmativos)) {
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

      final alturaEnFrase = _findHeightInPhrase(normalizeText(text));
      if (alturaEnFrase != null) return _validarIMC(alturaEnFrase);

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
      return _validarIMC(altura);
    }

    if (pasoIMC == 4) {
      if (_containsAny(text, _negativos)) {
        pasoIMC = 2;
        alturaIMC = null;
        _notaAltura = null;
        return 'Sin problema, volvamos a ingresar tus datos. ¿Cuál es tu peso? '
            'Puedes escribirlo en kg (por ejemplo: 65 kg) o en libras '
            '(por ejemplo: 150 lb), y también tu altura si quieres.';
      }
      if (_containsAny(text, _afirmativos)) {
        return _calcularIMC(alturaIMC ?? 0);
      }
      return 'Responde "sí" si los datos son correctos o "no" para '
          'ingresarlos de nuevo.';
    }

    if (_containsAny(text, getKeywords)) {
      pasoGET = 1;
      return 'El Gasto Energético Total (GET) calcula tus calorías diarias. ¿Quieres calcular el tuyo? Responde "sí".';
    }

    if (_containsAny(text, imcKeywords)) {
      pasoIMC = 1;
      return 'El IMC evalúa tu peso en relación con tu altura. ¿Quieres calcular tu IMC? Responde "sí".';
    }

    return '';
  }

  /// Pasa a la edad; si la altura se interpretó con duda, pide confirmarla antes.
  String _continuarTrasAlturaGET(double altura) {
    alturaGET = altura;
    if (_notaAltura == null) {
      pasoGET = 4;
      return 'Gracias. Ahora dime tu edad en años, por ejemplo: 25 años';
    }
    pasoGET = 12;
    return 'Esto es lo que entendí:\n'
        '• Peso: ${_describirPeso(pesoGET ?? 0, pesoGETEnLibras)}\n'
        '• Altura: ${_describirAltura(altura)}\n'
        '\n⚠️ $_notaAltura\n'
        '\n¿Es correcto? Responde "sí" para continuar o "no" para '
        'volver a ingresar tus datos.';
  }

  /// Muestra la conversión de unidades y pide confirmar antes de calcular.
  String _validarIMC(double altura) {
    alturaIMC = altura;
    pasoIMC = 4;
    return 'Esto es lo que entendí:\n'
        '• Peso: ${_describirPeso(pesoUsuario ?? 0, pesoIMCEnLibras)}\n'
        '• Altura: ${_describirAltura(altura)}\n'
        '${_notaAltura == null ? '' : '\n⚠️ $_notaAltura\n'}'
        '\n¿Es correcto? Responde "sí" para calcular tu IMC o "no" para '
        'volver a ingresar tus datos.';
  }

  String _calcularIMC(double altura) {
    final pesoCalculado = pesoUsuario ?? 0;
    final imc = pesoCalculado / (altura * altura);
    resetIMC();

    String clasificacion =
        imc < 18.5
            ? 'Bajo peso'
            : imc < 25
            ? 'Peso normal'
            : imc < 30
            ? 'Sobrepeso'
            : 'Obesidad';

    return 'Tu IMC es ${imc.toStringAsFixed(1)} kg/m², '
        'lo que corresponde a: $clasificacion.';
  }

  ({String clave, String etiqueta})? _detectarSexo(String text) {
    // Primero "prefiero no decirlo", que contiene la palabra "no".
    if (_containsAny(text, [
      '3',
      'prefiero no*',
      'no decir*',
      'no quiero decir*',
      'privado',
    ])) {
      return (clave: 'otro', etiqueta: 'Prefiero no decirlo');
    }
    if (_containsAny(text, ['2', 'mujer', 'femenino', 'chica', 'female'])) {
      return (clave: 'mujer', etiqueta: 'Mujer');
    }
    if (_containsAny(text, [
      '1',
      'hombre',
      'masculino',
      'varon',
      'chico',
      'male',
    ])) {
      return (clave: 'hombre', etiqueta: 'Hombre');
    }
    return null;
  }

  String _formatear(double value) =>
      value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');

  String _describirPeso(double kg, bool enLibras) {
    if (!enLibras) return '${_formatear(kg)} kg';
    return '${_formatear(kg / 0.45359237)} lb = ${_formatear(kg)} kg';
  }

  String _describirAltura(double metros) =>
      '${(metros * 100).round()} cm (${metros.toStringAsFixed(2)} m)';

  static const _num = r'(\d+(?:[.,]\d+)?)';

  /// Devuelve el único número que contiene el texto, o null si hay 0 o varios.
  String? _loneNumber(String text) {
    final numbers = RegExp(_num).allMatches(text).toList();
    return numbers.length == 1 ? numbers.first.group(1) : null;
  }

  /// Altura escrita de forma exacta ("1.70", "170 cm", "5 pies 10 pulgadas").
  double? _parseHeightStrict(String input) {
    final feetAndInchesMatch = RegExp(
      r'''^\s*(\d+)\s*(?:ft|feet|pies?|f|')\s*(\d+(?:[.,]\d+)?)\s*(?:in|inches|pulgadas?|")\s*$''',
    ).firstMatch(input);
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
      r"^\s*(\d+(?:[.,]\d+)?)\s*(?:ft|feet|pies?|f|')\s*$",
    ).firstMatch(input);
    if (feetMatch != null) {
      final feet = double.tryParse(feetMatch.group(1)!.replaceAll(',', '.'));
      if (feet == null || feet <= 0) return null;
      final heightInMeters = feet * 0.3048;
      return heightInMeters <= 3 ? heightInMeters : null;
    }

    final match = RegExp(
      r'^\s*(\d+(?:[.,]\d+)?)\s*(cms?|m)?\s*$',
    ).firstMatch(input);
    if (match == null) return null;

    final value = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (value == null || value <= 0) return null;

    final unit = match.group(2);
    final heightInMeters =
        (unit != null && unit.startsWith('c')) || (unit == null && value > 3)
            ? value / 100
            : value;
    if (heightInMeters > 3) return null;

    return heightInMeters;
  }

  /// Busca una altura dentro de una frase, solo si trae unidad o una palabra
  /// como "mido" o "altura" ("peso 70 y mido 1.70").
  double? _findHeightInPhrase(String text) {
    _notaAltura = null;
    final feetAndInches = RegExp(
      r'''\d+\s*(?:ft|feet|pies?|f|')\s*\d+(?:[.,]\d+)?\s*(?:in|inches|pulgadas?|")''',
    ).firstMatch(text);
    if (feetAndInches != null) {
      return _parseHeightStrict(feetAndInches.group(0)!);
    }

    final feet = RegExp('$_num\\s*(?:ft|feet|pies?|f)\\b').firstMatch(text);
    if (feet != null) {
      final n = feet.group(1)!;
      final enPies = _parseHeightStrict('$n ft');
      if (enPies != null) return enPies;

      // Una altura así no es posible en pies: se toma como centímetros y se
      // le pide al usuario que lo confirme.
      final enCentimetros = _parseHeightStrict('$n cm');
      if (enCentimetros != null) {
        _notaAltura =
            '"$n pies" no es una altura posible, así que lo tomé como $n cm.';
        return enCentimetros;
      }
    }

    final metric = RegExp(
      '$_num\\s*(cms?|centimetros?|metros?|mts?|m)\\b',
    ).firstMatch(text);
    if (metric != null) {
      final unitText = metric.group(2)!;
      final unit = unitText.startsWith('c') ? 'cm' : 'm';
      return _parseHeightStrict('${metric.group(1)} $unit');
    }

    final marked = RegExp(
      '(?:mido|altura|estatura|talla)\\s*(?:de|es|:)?\\s*$_num',
    ).firstMatch(text);
    if (marked != null) return _parseHeightStrict(marked.group(1)!);

    return null;
  }

  double? _parseHeightInMeters(String input) {
    _notaAltura = null;
    final text = normalizeText(input);
    final strict = _parseHeightStrict(text);
    if (strict != null) return strict;

    final inPhrase = _findHeightInPhrase(text);
    if (inPhrase != null) return inPhrase;

    final lone = _loneNumber(text);
    return lone == null ? null : _parseHeightStrict(lone);
  }

  /// Peso exacto ("70", "70 kg", "150 lb").
  double? _parseWeightStrict(String input) {
    final match = RegExp(
      r'^\s*(\d+(?:[.,]\d+)?)\s*(kgs|kg|kilogramos?|kilos?|k|lbs|lb|libras?|l)?\s*$',
    ).firstMatch(input);
    if (match == null) return null;

    final value = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (value == null || value <= 0) return null;

    final unit = match.group(2);
    final weightInKilograms =
        unit == 'lb' ||
                unit == 'lbs' ||
                unit == 'l' ||
                unit == 'libra' ||
                unit == 'libras'
            ? value * 0.45359237
            : value;
    if (weightInKilograms > 500) return null;

    return weightInKilograms;
  }

  double? _parseWeightInKilograms(String input) {
    final text = normalizeText(input);
    final strict = _parseWeightStrict(text);
    if (strict != null) return strict;

    final withUnit = RegExp(
      '$_num\\s*(kgs|kg|kilogramos?|kilos?|k|lbs|lb|libras?|l)\\b',
    ).firstMatch(text);
    if (withUnit != null) {
      return _parseWeightStrict('${withUnit.group(1)} ${withUnit.group(2)}');
    }

    final marked = RegExp(
      '(?:peso|pesando|peses|pesas)\\s*(?:de|es|:)?\\s*$_num',
    ).firstMatch(text);
    if (marked != null) return _parseWeightStrict(marked.group(1)!);

    final lone = _loneNumber(text);
    return lone == null ? null : _parseWeightStrict(lone);
  }

  bool _weightWasEnteredInPounds(String input) {
    return RegExp(
      r'\d\s*(?:lbs|lb|libras?|l)\b',
    ).hasMatch(normalizeText(input));
  }

  /// Edad en años ("25", "25 años", "tengo 25 años y mido 1.70").
  int? _parseAge(String input) {
    final text = normalizeText(input);
    final match =
        RegExp(r'^\s*(\d+)\s*(?:anos?)?\s*$').firstMatch(text) ??
        RegExp(r'(\d{1,3})\s*anos?\b').firstMatch(text) ??
        RegExp(r'tengo\s*(\d{1,3})\b').firstMatch(text);
    final edad = match == null ? null : int.tryParse(match.group(1)!);
    if (edad != null) return edad;

    final lone = _loneNumber(text);
    return lone == null ? null : int.tryParse(lone);
  }

  bool _containsAny(String text, List<String> keywords) =>
      containsAnyKeyword(text, keywords);
}
