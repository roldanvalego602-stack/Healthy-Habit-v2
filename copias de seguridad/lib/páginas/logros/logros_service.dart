import 'package:flutter/material.dart';

class LogroDefinicion {
  const LogroDefinicion({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.meta,
    required this.tipo,
    required this.icono,
  });
  final String id, nombre, descripcion, tipo;
  final int meta;
  final IconData icono;
}

class LogrosService {
  static const String primerPasoId = 'primer_paso';
  static const int primerPasoXp = 25;
  static const int primerPasoCoins = 10;

  // Los logros nuevos son medallas de progreso. No conceden monedas ni XP:
  // las recompensas deben acreditarse exclusivamente mediante una operación
  // segura del backend, para evitar cobros repetidos o manipulaciones.
  static const List<LogroDefinicion> catalogo = [
    LogroDefinicion(
      id: 'primer_paso',
      nombre: 'Primer paso',
      descripcion: 'Registra tu primer hábito',
      meta: 1,
      tipo: 'primer',
      icono: Icons.flag_rounded,
    ),
    LogroDefinicion(
      id: 'explorador',
      nombre: 'Explorador saludable',
      descripcion: 'Agrega 3 hábitos a tu colección',
      meta: 3,
      tipo: 'habitos',
      icono: Icons.explore_rounded,
    ),
    LogroDefinicion(
      id: 'coleccionista',
      nombre: 'Coleccionista de hábitos',
      descripcion: 'Agrega 6 hábitos',
      meta: 6,
      tipo: 'habitos',
      icono: Icons.collections_bookmark_rounded,
    ),
    LogroDefinicion(
      id: 'primera_meta',
      nombre: 'Meta cumplida',
      descripcion: 'Completa un hábito',
      meta: 1,
      tipo: 'completados',
      icono: Icons.check_circle_rounded,
    ),
    LogroDefinicion(
      id: 'triple_victoria',
      nombre: 'Triple victoria',
      descripcion: 'Completa 3 hábitos',
      meta: 3,
      tipo: 'completados',
      icono: Icons.emoji_events_rounded,
    ),
    LogroDefinicion(
      id: 'cinco_logros',
      nombre: 'Cinco objetivos',
      descripcion: 'Completa 5 hábitos',
      meta: 5,
      tipo: 'completados',
      icono: Icons.stars_rounded,
    ),
    LogroDefinicion(
      id: 'racha_3',
      nombre: 'Tres días de constancia',
      descripcion: 'Alcanza una racha de 3 días',
      meta: 3,
      tipo: 'racha',
      icono: Icons.local_fire_department_rounded,
    ),
    LogroDefinicion(
      id: 'racha_7',
      nombre: 'Semana imparable',
      descripcion: 'Alcanza una racha de 7 días',
      meta: 7,
      tipo: 'racha',
      icono: Icons.whatshot_rounded,
    ),
    LogroDefinicion(
      id: 'racha_30',
      nombre: 'Constancia legendaria',
      descripcion: 'Alcanza una racha de 30 días',
      meta: 30,
      tipo: 'racha',
      icono: Icons.military_tech_rounded,
    ),
    LogroDefinicion(
      id: 'nivel_3',
      nombre: 'En crecimiento',
      descripcion: 'Alcanza el nivel 3',
      meta: 3,
      tipo: 'nivel',
      icono: Icons.trending_up_rounded,
    ),
    LogroDefinicion(
      id: 'nivel_5',
      nombre: 'Cultivador experto',
      descripcion: 'Alcanza el nivel 5',
      meta: 5,
      tipo: 'nivel',
      icono: Icons.workspace_premium_rounded,
    ),
    LogroDefinicion(
      id: 'xp_1000',
      nombre: 'Mil razones para seguir',
      descripcion: 'Acumula 1000 XP',
      meta: 1000,
      tipo: 'xp',
      icono: Icons.bolt_rounded,
    ),
  ];

  static int entero(dynamic v, [int defecto = 0]) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? defecto;

  static int progreso(
    LogroDefinicion logro,
    Map<String, dynamic> perfil,
    int habitos,
    int completados,
    Set<String> desbloqueados,
  ) {
    switch (logro.tipo) {
      case 'primer':
        return desbloqueados.contains(primerPasoId) ? 1 : 0;
      case 'habitos':
        return habitos;
      case 'completados':
        return completados;
      case 'racha':
        return entero(
          perfil['longestStreak'],
          entero(perfil['currentStreak'], entero(perfil['streakDays'])),
        );
      case 'nivel':
        return entero(perfil['level'], 1);
      case 'xp':
        return entero(perfil['xp'], entero(perfil['currentXp']));
      default:
        return 0;
    }
  }

  static bool obtenido(LogroDefinicion logro, int progreso) =>
      progreso >= logro.meta;

  static LogroDefinicion? siguiente(
    Map<String, dynamic> perfil,
    int habitos,
    int completados,
    Set<String> desbloqueados,
  ) {
    for (final logro in catalogo) {
      if (!obtenido(
        logro,
        progreso(logro, perfil, habitos, completados, desbloqueados),
      ))
        return logro;
    }
    return null;
  }
}
