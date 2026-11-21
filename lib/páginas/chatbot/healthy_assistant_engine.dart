import 'healthy_assistant_reply.dart';
export 'healthy_assistant_reply.dart';
import '../habitos/catalogo.dart';
import '../catalogo/datos/catalogo_datos.dart';
import '../catalogo/modelos/catalogo_item.dart';
import '../tienda/shop_service.dart';
import '../niveles/levels_system.dart';
import 'nutri_respuestas_service.dart';
import 'healthy_intent_router.dart';

/// Intenciones de alta confianza. No ejecuta cambios por cuenta del usuario.
class HealthyAssistantEngine {
  const HealthyAssistantEngine();

  static CatalogoItem? _catalogMatch(String normalized) {
    final entries = <CatalogoItem>[
      ...alimentosCatalogo,
      ...ejerciciosCatalogo,
      ...consejosCatalogo,
    ];
    for (final item in entries) {
      final title = NutriRespuestasService.normalizar(item.titulo);
      if (NutriRespuestasService.contiene(normalized, [title])) {
        return item;
      }
    }
    // Variantes habituales; todas resuelven a una ficha existente.
    const aliases = <String, String>{
      'sentadilla': 'sentadillas',
      'plancha': 'plancha',
      'lenteja': 'lentejas',
      'huevos': 'huevo',
      'caminar en casa': 'caminar',
      'caminata en casa': 'caminar',
      'dormir mejor': 'dormir_mejor',
      'prevenir caidas': 'prevenir_caidas',
      'pausas activas': 'pausas_activas',
      'pausa activa': 'pausas_activas',
    };
    for (final entry in aliases.entries) {
      if (NutriRespuestasService.contiene(normalized, [entry.key])) {
        for (final item in entries) {
          if (item.id == entry.value) return item;
        }
      }
    }
    return null;
  }

  static int _number(Object? raw) =>
      raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;

  HealthyAssistantReply resolve(
    String input, {
    required Map<String, dynamic> profile,
    required List<Map<String, dynamic>> habits,
    String lastTopic = '',
    String lastHabitTitle = '',
    String lastShopItemId = '',
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

    // Intenciones de cuenta y saldo primero; «borrar mi cuenta» nunca
    // se interpreta como abandono de hábito, ni se ejecuta un borrado.
    if (HealthyIntentRouter.asksForAccountDeletion(input)) {
      return const HealthyAssistantReply(
        'Si quieres eliminar tu cuenta de Healthy Habit, la opción está '
        'en Configuración, pero actualmente está deshabilitada: '
        'todavía falta implementar la eliminación segura de los datos '
        'de Authentication, Firestore y evidencias. '
        'No he eliminado tu cuenta ni tus hábitos.',
      );
    }
    if (HealthyIntentRouter.asksForCoinBalance(input)) {
      return HealthyAssistantReply(
        'Tu saldo actual es de $coins Habit Coins. '
        'Puedes usarlas en Tienda para canjear accesorios, '
        'después de revisar el precio y confirmar la compra.',
        action: 'profile',
        card: 'profile',
      );
    }

    // Acciones de hábitos: solo recomendar y abrir la UI que valida cupos,
    // penalizaciones y confirmación explícita. Nunca escribir directamente.
    if (HealthyIntentRouter.asksForHabitAction(input) ||
        has(['iniciar un habito','quiero empezar un habito',
             'ponme un habito','cancelar habito',
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
                ? 'Encontré «$title». Revisa aquí la penalización y confirma si deseas abandonarlo. No borraré tu historial ni aplicaré cargos sin tu confirmación.'
                : 'Encontré «$title». Revisa aquí sus requisitos, cupos y costo para que confirmes si deseas iniciarlo.',
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
            'Encontré «${h['title']}». Puedes revisar los requisitos y confirmar aquí mismo si deseas ${lastTopic == 'habit_add' ? 'activarlo' : 'abandonarlo'}.',
            action: 'habits',
            actionArgument: h['title'].toString(),
            card: lastTopic,
          );
        }
      }
    }

    // Fichas educativas del catálogo real, con imagen y fuentes propias.
    // Nunca se deducen cifras nutricionales ni se ejecutan acciones.
    final catalogItem = _catalogMatch(normalized);
    final catalogQuestion = has([
      'informacion','informame','hablame','muestrame',
      'que sabes','beneficios','precauciones','nutrientes',
      'como preparar','como hacer','como realizar','como se hace',
      'como prevenir',
      'cuantas proteinas','proteinas de','calorias de',
      'calorias tiene','cuantas calorias','valor nutricional',
      'datos de','explicame','ver ficha','ver catalogo',
      'quiero saber','que contiene','para que sirve',
      'recomiendame','dime sobre',
    ]);
    if (catalogQuestion && catalogItem != null) {
      final summary = catalogItem.descripcion;
      final benefits = catalogItem.beneficios.isEmpty
          ? ''
          : '\nBeneficio: ${catalogItem.beneficios.first}';
      final warning = catalogItem.precauciones.isEmpty
          ? ''
          : '\nPrecaución: ${catalogItem.precauciones.first}';
      final wantsCalories = has(['calorias', 'kcal', 'energia calorica']);
      final numericDetails = catalogItem.categoria == 'Alimentos'
          ? catalogItem.detalles.entries
              .where((entry) => const {
                'Proteína', 'Grasas', 'Carbohidratos', 'Fibra',
              }.contains(entry.key))
              .map((entry) => '${entry.key}: ${entry.value}')
              .join(' · ')
          : '';
      final nutrition = wantsCalories &&
              !catalogItem.detalles.keys.any(
                (label) => label.toLowerCase().contains('calor'))
          ? '\nEsta ficha aún no contiene un valor calórico revisado. '
              'No voy a estimarlo.'
          : numericDetails.isNotEmpty
              ? '\nComposición aproximada (${catalogItem.detalles['Referencia'] ?? 'porción indicada en la ficha'}): '
                  '$numericDetails.'
              : '';
      return HealthyAssistantReply(
        '${catalogItem.titulo}: $summary$benefits$warning$nutrition\n'
        'Puedes revisar la ficha completa y su fuente en el catálogo. '
        'Los datos del catálogo son educativos y requieren revisión '
        'antes de usarse como referencia clínica.',
        action: 'catalog_item', actionArgument: catalogItem.id,
        card: 'catalog_item',
      );
    }

    if (has(['abre el catalogo','abrir catalogo','ir al catalogo',
             'muestra el catalogo','ver el catalogo'])) {
      return const HealthyAssistantReply(
        'Te llevo al catálogo educativo de Healthy Habit, '
        'con fichas de alimentos, ejercicios y consejos.',
        action: 'catalog', card: 'catalog');
    }

    // Interacciones de otros módulos, ordenadas antes de perfiles/FAQ.
    if (has(['editar mi perfil','editar perfil','cambiar mi nombre',
        'modificar mi perfil','cambiar mi usuario','cambiar mi biografia',
        'editar mi biografia'])) {
      return const HealthyAssistantReply(
        'Puedes actualizar tu nombre, usuario y biografía desde el formulario '
        'de edición. No cambiaré tus datos sin que los revises y guardes.',
        action: 'edit_profile', card: 'edit_profile');
    }

    if (has(['mis desafios','mis retos','desafios activos','desafios disponibles',
        'mis misiones','misiones disponibles','ver desafios','ver mis desafios',
        'muestrame los desafios','aceptar desafio',
        'reclamar desafio','reclamar recompensa de desafio',
        'que desafios tengo'])) {
      return const HealthyAssistantReply(
        'Voy a consultar tus desafíos reales para mostrar el avance, '
        'los pendientes y las recompensas. Para aceptar o reclamar '
        'utilizaremos la pantalla de Desafíos, que valida esas operaciones.',
        action: 'challenges', card: 'challenges');
    }

    if (has(['mis logros','que logros tengo','mis insignias','medallas',
        'logros desbloqueados','proximo logro','siguiente logro',
        'ver logros','mis trofeos'])) {
      return const HealthyAssistantReply(
        'Revisaré tus logros y cuánto te falta para el siguiente. '
        'No se concederán XP ni monedas al mostrar la información.',
        action: 'achievements', card: 'achievements');
    }

    for (final item in shopCatalog) {
      final itemName = NutriRespuestasService.normalizar(item.name);
      final uniqueWords = itemName.split(' ')
          .where((word) => word.length >= 5 && !const {
            'avatar', 'lentes', 'recompensa', 'articulo',
          }.contains(word));
      final exact = normalized.contains(itemName);
      final uniqueWord = uniqueWords.any((word) =>
          NutriRespuestasService.contiene(normalized, [word]) &&
          shopCatalog.where((other) =>
            NutriRespuestasService.normalizar(other.name)
                .split(' ').contains(word)).length == 1);
      final followUp = lastTopic == 'shop_item' &&
          item.id == lastShopItemId &&
          has(['compralo','comprala','equipalo','equipala',
              'cuanto cuesta','precio','quitamelo','quitalo']);
      if (((exact || uniqueWord) &&
           has(['comprar','compra','canjear','quiero','equipar',
               'ponerme','usar','quitarme','quitame','desequipar',
               'cuanto cuesta','precio','tengo'])) || followUp) {
        return HealthyAssistantReply(
          'Encontré «${item.name}» en la tienda. '
          'Consultaré tu saldo y la colección antes de ofrecer '
          'una compra o cambio de apariencia.',
          action: 'shop', actionArgument: item.id, card: 'shop_item');
      }
    }
    if (has(['que puedo comprar','recomiendame algo de la tienda',
        'ver productos','catalogo de tienda','articulos de tienda',
        'comprar recompensa','comprar un accesorio','canjear monedas'])) {
      return const HealthyAssistantReply(
        'Puedes consultar artículos reales de la tienda, revisar '
        'precios, adquirirlos con confirmación o equipar los que ya tienes.',
        action: 'shop', card: 'shop_picker');
    }

    if (has(['profesional', 'nutriologo', 'nutriologa', 'consulta nutricional',
             'contacto de nutricion', 'especialista', 'orientacion profesional'])) {
      return const HealthyAssistantReply(
        'Puedo abrir orientación profesional con enlaces externos al directorio de nutriólogos y a la consulta de cédulas. Healthy Habit no ofrece citas ni profesionales afiliados.',
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
             'mis actividades'])) {
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

    // La recuperación de conocimiento se ejecuta después de las acciones
    // mediante HealthyHybridKnowledge. Este motor solo decide flujos de app.

    return const HealthyAssistantReply('');
  }

  String topicFor(HealthyAssistantReply reply) {
    switch (reply.card) {
      case 'habit_add': return 'habit_add';
      case 'habit_remove': return 'habit_remove';
      case 'profile': return 'profile';
      case 'shop_item': return 'shop_item';
      case 'knowledge': return 'knowledge';
      default: return '';
    }
  }
}
