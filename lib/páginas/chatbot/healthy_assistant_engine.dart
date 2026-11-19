import '../habitos/catalogo.dart';
import '../niveles/levels_system.dart';
import 'nutri_respuestas_service.dart';

/// Respuesta estructurada: la interfaz decide cómo mostrar las tarjetas.
class HealthyAssistantReply {
  const HealthyAssistantReply(this.text, {
    this.action = '',
    this.actionArgument = '',
    this.card = '',
  });
  final String text;
  final String action;
  final String actionArgument;
  final String card;
}

class HealthyKnowledgeEntry {
  const HealthyKnowledgeEntry(this.id, this.terms, this.answer, this.source);
  final String id;
  final List<String> terms;
  final String answer;
  final String source;
}

/// Contenido educativo breve, revisable y sin recomendaciones clínicas.
class HealthyKnowledgeBase {
  static const entries = <HealthyKnowledgeEntry>[
    HealthyKnowledgeEntry('avena', ['avena', 'hojuelas de avena'],
        'La avena es un cereal que aporta carbohidratos y fibra. Puedes combinarla con fruta y otras fuentes de proteína según tus preferencias. Los valores exactos dependen de la porción y preparación.',
        'USDA FoodData Central · https://fdc.nal.usda.gov/'),
    HealthyKnowledgeEntry('lentejas', ['lentejas', 'lenteja'],
        'Las lentejas son legumbres que aportan proteína vegetal y fibra. Su contenido nutricional cambia según la preparación y la cantidad. No hay un alimento único que sustituya una alimentación variada.',
        'USDA FoodData Central · https://fdc.nal.usda.gov/'),
    HealthyKnowledgeEntry('huevo', ['huevo', 'huevos'],
        'El huevo aporta proteínas y otros nutrientes. La composición de un platillo con huevo depende de sus ingredientes y su preparación.',
        'USDA FoodData Central · https://fdc.nal.usda.gov/'),
    HealthyKnowledgeEntry('fruta', ['fruta', 'frutas', 'verduras', 'vegetales'],
        'Consumir frutas y verduras variadas forma parte de una alimentación saludable. Puedes empezar incorporándolas a comidas que ya haces; no necesitas perseguir una dieta perfecta.',
        'OMS, Alimentación saludable · https://www.who.int/es/news-room/fact-sheets/detail/healthy-diet'),
    HealthyKnowledgeEntry('azucar', ['azucar añadida', 'refresco', 'bebidas azucaradas', 'azucares libres'],
        'Reducir el consumo habitual de bebidas con azúcares libres puede ayudar a mejorar el patrón de alimentación. Una opción sencilla es elegir agua como bebida de uso frecuente.',
        'OMS, Alimentación saludable · https://www.who.int/es/news-room/fact-sheets/detail/healthy-diet'),
    HealthyKnowledgeEntry('ejercicio', ['actividad fisica', 'sedentarismo', 'ejercicio moderado', 'actividad aeróbica'],
        'La actividad física habitual aporta beneficios para la salud. Puedes empezar por movimientos que te resulten accesibles y aumentar progresivamente según tus capacidades.',
        'OMS, Actividad física · https://www.who.int/es/news-room/fact-sheets/detail/physical-activity'),
  ];

  static HealthyKnowledgeEntry? search(String question) {
    final normalized = NutriRespuestasService.normalizar(question);
    for (final entry in entries) {
      if (NutriRespuestasService.contiene(normalized, entry.terms)) return entry;
    }
    return null;
  }
}

/// Intenciones de alta confianza. No ejecuta cambios por cuenta del usuario.
class HealthyAssistantEngine {
  const HealthyAssistantEngine();

  static int _number(Object? raw) =>
      raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;

  HealthyAssistantReply resolve(
    String input, {
    required Map<String, dynamic> profile,
    required List<Map<String, dynamic>> habits,
    String lastTopic = '',
    String lastHabitTitle = '',
  }) {
    final normalized = NutriRespuestasService.normalizar(input);
    bool has(List<String> terms) =>
        NutriRespuestasService.contiene(normalized, terms);
    final xp = _number(profile['xp'] ?? profile['currentXp']);
    final current = LevelSystem.fromXp(xp);
    final next = LevelSystem.nextLevel(xp);
    final coins = _number(profile['habitCoins']);
    final streak = _number(profile['currentStreak'] ?? profile['streakDays']);
    final firstName = (profile['name'] ?? '').toString().trim().split(' ').first;
    final personal = firstName.isEmpty ? '' : ', $firstName';
    final active = habits.where((habit) =>
        (habit['latestStatus'] ?? habit['lastStatus']) == 'inProgress').toList();
    final finished = habits.where((habit) =>
        (habit['latestStatus'] ?? habit['lastStatus']) == 'completed').length;

    if (has(['suicidio','suicidarme','matarme','hacerme dano','autolesion'])) {
      return const HealthyAssistantReply(
        'Si estás en peligro inmediato, busca ayuda presencial o llama a emergencias. '
        'También puedes contactar a alguien de confianza para que esté contigo. '
        '¿Estás en un lugar seguro ahora?');
    }

    // Acciones de hábitos: solo recomendar y abrir la UI que valida cupos,
    // penalizaciones y confirmación explícita. Nunca escribir directamente.
    if (has(['agrega','agregar','anade','anadir','activar','iniciar un habito',
             'quiero empezar un habito','ponme un habito',
             'elimina','eliminar','borrar','quitar','abandonar','cancelar habito',
             'eliminalo','quitalo','agregalo','anadelo','activarlo'])) {
      final removing = has(['elimina','eliminar','borrar','quitar','abandonar','cancelar',
        'eliminalo','quitalo']);
      Map<String, dynamic>? target;
      for (final h in habitCatalog) {
        final name = NutriRespuestasService.normalizar(h['title'].toString());
        if (normalized.contains(name)) {
          target = h;
          break;
        }
      }
      // Seguimiento: el usuario puede dar el título en el segundo mensaje.
      if (target == null && (lastTopic == 'habit_add' || lastTopic == 'habit_remove')) {
        for (final h in habitCatalog) {
          final name = NutriRespuestasService.normalizar(h['title'].toString());
          if (normalized.contains(name)) {
            target = h;
            break;
          }
        }
      }
      final referential = has(['eliminalo','quitamelo','quitalo','borrarlo',
          'agregalo','anadelo','activarlo','ese habito','el mismo']);
      final title = target?['title']?.toString() ??
          (referential ? lastHabitTitle : '');
      return HealthyAssistantReply(
        title.isEmpty
            ? removing
                ? 'Puedo ayudarte a abandonar un hábito. Abre tus hábitos activos, elige el que quieras quitar y confirma la operación. Los hábitos difíciles pueden tener una penalización.'
                : 'Puedo ayudarte a comenzar un hábito. Abre el catálogo, selecciona una actividad y confirma sus requisitos y cupos.'
            : removing
                ? 'Encontré «$title». Abre Hábitos, selecciona el intento activo correspondiente y confirma si deseas abandonarlo. No borraré tu historial ni aplicaré penalizaciones sin tu confirmación.'
                : 'Encontré «$title». Te llevaré a su búsqueda en Hábitos para que revises requisitos, cupos y confirmes si deseas iniciarlo.',
        action: 'habits',
        actionArgument: title,
        card: removing ? 'habit_remove' : 'habit_add',
      );
    }

    // Continuación textual del hábito sin exigir que repita el verbo.
    if ((lastTopic == 'habit_add' || lastTopic == 'habit_remove') &&
        normalized.length < 80) {
      for (final h in habitCatalog) {
        final name = NutriRespuestasService.normalizar(h['title'].toString());
        if (normalized.contains(name)) {
          return HealthyAssistantReply(
            'Encontré «${h['title']}». Puedes revisarlo en la pantalla de Hábitos y decidir allí si deseas ${lastTopic == 'habit_add' ? 'activarlo' : 'abandonarlo'}.',
            action: 'habits',
            actionArgument: h['title'].toString(),
            card: lastTopic,
          );
        }
      }
    }

    if (has(['profesional', 'nutriologo', 'nutriologa', 'consulta nutricional',
             'contacto de nutricion', 'especialista', 'orientacion profesional'])) {
      return const HealthyAssistantReply(
        'Puedo abrir el directorio de orientación profesional. Por ahora contiene contactos de demostración: no se deben utilizar para reservar ni llamar hasta que estén verificados.',
        action: 'professionals', card: 'professional');
    }
    if (has(['mis estadisticas','mi progreso','ver progreso','grafica',
             'graficas','mi historial de registros','cuanto he avanzado'])) {
      return HealthyAssistantReply(
        'Este es tu progreso registrado$personal: tienes $xp XP, nivel ${current.number}, '
        '$streak días de racha y $finished hábitos con último intento completado. '
        'Abre Estadísticas para ver gráficas e historial detallado.',
        action: 'progress', card: 'profile');
    }
    if (has(['mi perfil','mi nivel','mis datos','mis monedas','habit coins',
             'mi xp','cuantos xp','cuantas monedas','mi racha','mi posicion',
             'cuanto me falta para nivel','mi siguiente nivel']) ||
        (lastTopic == 'profile' &&
         has(['y mis monedas','y mi racha','y mi nivel','y mis xp','y ahora']))) {
      final required = next == null
          ? 'Alcanzaste el nivel máximo disponible.'
          : 'Faltan ${LevelSystem.remainingXp(xp)} XP para el nivel ${next.number}.';
      return HealthyAssistantReply(
        'Tu resumen$personal:\n'
        '• Nivel: ${current.number} · ${current.name}\n'
        '• Experiencia: $xp XP\n'
        '• Habit Coins: $coins\n'
        '• Racha actual: $streak días\n'
        '• Hábitos activos identificados: ${active.length}\n'
        '$required',
        action: 'profile', card: 'profile');
    }
    if (has(['camino de xp','camino de niveles','ver mis niveles','subir de nivel'])) {
      return HealthyAssistantReply(
        'Actualmente estás en el nivel ${current.number} y tienes $xp XP. '
        'Puedes visualizar tu camino y las próximas recompensas.',
        action: 'levels', card: 'level');
    }
    if (has(['ranking','clasificacion','tabla de posiciones'])) {
      return const HealthyAssistantReply(
        'Abre Ranking para ver tu posición real y la clasificación actualizada. No puedo determinar tu puesto sin consultar la lista completa.',
        action: 'ranking', card: 'ranking');
    }
    if (has(['mis habitos','habitos activos','que habitos tengo',
             'mis actividades','mis misiones'])) {
      if (active.isEmpty) {
        return const HealthyAssistantReply(
          'No encontré hábitos marcados como activos en tus registros consultados. Puedes abrir Hábitos para iniciar uno.',
          action: 'habits', card: 'habit_add');
      }
      final names = active.take(5).map((h) =>
          '• ${h['title'] ?? h['name'] ?? 'Hábito'}').join('\n');
      return HealthyAssistantReply(
        'Encontré ${active.length} hábitos activos:\n$names\n'
        'Puedes abrir Hábitos para registrar avances o administrarlos.',
        action: 'habits', card: 'habits');
    }
    if (has(['tienda','comprar','canjear','armario','recompensa de la tienda'])) {
      return HealthyAssistantReply(
        'Actualmente tienes $coins Habit Coins. Puedes revisar el catálogo '
        'y confirmar cualquier canje en Tienda.',
        action: 'shop', card: 'shop');
    }

    final factQuestion = has(['nutrientes','proteinas','calorias de','que contiene',
        'beneficios de','alimento','alimentacion','comer','tiene fibra',
        'es saludable','que puedo desayunar','actividad fisica']);
    if (factQuestion) {
      final entry = HealthyKnowledgeBase.search(input);
      if (entry != null) {
        return HealthyAssistantReply(
          '${entry.answer}\n\nFuente de referencia: ${entry.source}',
          card: 'knowledge',
          action: 'source',
          actionArgument: entry.source.split('·').last.trim());
      }
      return const HealthyAssistantReply(
        'No tengo una ficha verificada que responda con precisión esa pregunta. '
        'Puedo ayudarte con las fichas disponibles sobre avena, lentejas, huevo, '
        'frutas, azúcares libres y actividad física; no inventaré valores nutricionales.');
    }

    return const HealthyAssistantReply('');
  }

  String topicFor(HealthyAssistantReply reply) {
    switch (reply.card) {
      case 'habit_add': return 'habit_add';
      case 'habit_remove': return 'habit_remove';
      case 'profile': return 'profile';
      case 'knowledge': return 'knowledge';
      default: return '';
    }
  }
}
