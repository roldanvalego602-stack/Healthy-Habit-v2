/// Catálogo inicial de Healthy Habit.
/// Los datos se mantienen localmente en Dart; no requieren Firestore.
library;

const List<String> habitCategories = [
  'Alimentación',
  'Hidratación',
  'Energía',
  'Bienestar',
];

const List<String> habitDifficulties = ['Sencillo', 'Moderado', 'Difícil'];

const Map<String, int> _xpByDifficulty = {
  'Sencillo': 10,
  'Moderado': 15,
  'Difícil': 20,
};

const Map<String, int> _graceByDifficulty = {
  'Sencillo': 1,
  'Moderado': 1,
  'Difícil': 0,
};

const Map<String, int> _levelByDifficulty = {
  'Sencillo': 1,
  'Moderado': 2,
  'Difícil': 4,
};

Map<String, dynamic> _habit({
  required String id,
  required String title,
  required String category,
  required String difficulty,
  required String subtitle,
  required String frequencyType,
  required int registrationsPerPeriod,
  required int durationPeriods,
  bool repeatable = true,
  int cooldownDays = 0,
}) {
  final target = registrationsPerPeriod * durationPeriods;

  return {
    'id': id,
    'title': title,
    'category': category,
    'difficulty': difficulty,
    'subtitle': subtitle,
    'xp': _xpByDifficulty[difficulty]!,
    'target': target,
    'unlockType': difficulty == 'Sencillo' ? 'free' : 'level',
    'requiredLevel': _levelByDifficulty[difficulty]!,
    'requiredHabitId': null,
    'coinCost': 0,
    'repeatable': repeatable,
    'cooldownDays': cooldownDays,
    'frequencyType': frequencyType,
    'registrationsPerPeriod': registrationsPerPeriod,
    'durationPeriods': durationPeriods,
    'gracePeriods': _graceByDifficulty[difficulty]!,
    'streakEnabled': true,
  };
}

final List<Map<String, dynamic>> habitCatalog = [
  // --------------------------------------------------
  // ALIMENTACIÓN - SENCILLO
  // --------------------------------------------------
  _habit(
    id: 'alim_001',
    title: 'Incluir una fruta',
    category: 'Alimentación',
    difficulty: 'Sencillo',
    subtitle: 'Come al menos una fruta durante el día.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 7,
  ),
  _habit(
    id: 'alim_002',
    title: 'Desayuno equilibrado',
    category: 'Alimentación',
    difficulty: 'Sencillo',
    subtitle: 'Prepara un desayuno que incluya alimentos nutritivos.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 7,
  ),
  _habit(
    id: 'alim_003',
    title: 'Agregar verduras',
    category: 'Alimentación',
    difficulty: 'Sencillo',
    subtitle: 'Incluye verduras en una de tus comidas.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 7,
  ),

  // --------------------------------------------------
  // ALIMENTACIÓN - MODERADO
  // --------------------------------------------------
  _habit(
    id: 'alim_004',
    title: 'Planificar mis comidas',
    category: 'Alimentación',
    difficulty: 'Moderado',
    subtitle: 'Organiza tus comidas con anticipación.',
    frequencyType: 'weekly',
    registrationsPerPeriod: 3,
    durationPeriods: 4,
  ),
  _habit(
    id: 'alim_005',
    title: 'Cocinar en casa',
    category: 'Alimentación',
    difficulty: 'Moderado',
    subtitle: 'Prepara una comida completa en casa.',
    frequencyType: 'weekly',
    registrationsPerPeriod: 4,
    durationPeriods: 4,
  ),
  _habit(
    id: 'alim_006',
    title: 'Evitar bebidas azucaradas',
    category: 'Alimentación',
    difficulty: 'Moderado',
    subtitle: 'Elige una alternativa sin azúcar añadida.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 14,
  ),

  // --------------------------------------------------
  // ALIMENTACIÓN - DIFÍCIL
  // --------------------------------------------------
  _habit(
    id: 'alim_007',
    title: 'Menú semanal saludable',
    category: 'Alimentación',
    difficulty: 'Difícil',
    subtitle: 'Organiza y sigue un menú equilibrado durante la semana.',
    frequencyType: 'weekly',
    registrationsPerPeriod: 5,
    durationPeriods: 6,
  ),
  _habit(
    id: 'alim_008',
    title: 'Preparar alimentos con anticipación',
    category: 'Alimentación',
    difficulty: 'Difícil',
    subtitle: 'Deja preparadas varias comidas para tus días.',
    frequencyType: 'weekly',
    registrationsPerPeriod: 4,
    durationPeriods: 6,
  ),
  _habit(
    id: 'alim_009',
    title: 'Mantener una alimentación equilibrada',
    category: 'Alimentación',
    difficulty: 'Difícil',
    subtitle: 'Completa tus comidas con variedad de grupos alimenticios.',
    frequencyType: 'daily',
    registrationsPerPeriod: 2,
    durationPeriods: 21,
  ),

  // --------------------------------------------------
  // HIDRATACIÓN - SENCILLO
  // --------------------------------------------------
  _habit(
    id: 'hidr_001',
    title: 'Beber agua al despertar',
    category: 'Hidratación',
    difficulty: 'Sencillo',
    subtitle: 'Comienza tu día tomando un vaso de agua.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 7,
  ),
  _habit(
    id: 'hidr_002',
    title: 'Acompañar mis comidas con agua',
    category: 'Hidratación',
    difficulty: 'Sencillo',
    subtitle: 'Toma agua durante una de tus comidas principales.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 7,
  ),
  _habit(
    id: 'hidr_003',
    title: 'Llevar mi botella de agua',
    category: 'Hidratación',
    difficulty: 'Sencillo',
    subtitle: 'Ten agua disponible durante tus actividades.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 7,
  ),

  // --------------------------------------------------
  // HIDRATACIÓN - MODERADO
  // --------------------------------------------------
  _habit(
    id: 'hidr_004',
    title: 'Cumplir mi meta de agua',
    category: 'Hidratación',
    difficulty: 'Moderado',
    subtitle: 'Completa tu objetivo personal de consumo de agua.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 14,
  ),
  _habit(
    id: 'hidr_005',
    title: 'Hidratarme durante el ejercicio',
    category: 'Hidratación',
    difficulty: 'Moderado',
    subtitle: 'Mantén una hidratación adecuada durante tu actividad física.',
    frequencyType: 'weekly',
    registrationsPerPeriod: 3,
    durationPeriods: 4,
  ),
  _habit(
    id: 'hidr_006',
    title: 'Registrar mi consumo de agua',
    category: 'Hidratación',
    difficulty: 'Moderado',
    subtitle: 'Lleva un control de tu consumo diario.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 14,
  ),

  // --------------------------------------------------
  // HIDRATACIÓN - DIFÍCIL
  // --------------------------------------------------
  _habit(
    id: 'hidr_007',
    title: 'Mantener mi rutina de hidratación',
    category: 'Hidratación',
    difficulty: 'Difícil',
    subtitle: 'Cumple tu meta personal de hidratación de forma constante.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 21,
  ),
  _habit(
    id: 'hidr_008',
    title: 'Planificar mi hidratación semanal',
    category: 'Hidratación',
    difficulty: 'Difícil',
    subtitle: 'Organiza y evalúa tu rutina de hidratación cada semana.',
    frequencyType: 'weekly',
    registrationsPerPeriod: 5,
    durationPeriods: 6,
  ),
  _habit(
    id: 'hidr_009',
    title: 'Hidratación consciente',
    category: 'Hidratación',
    difficulty: 'Difícil',
    subtitle: 'Mantén un seguimiento constante de tus necesidades de agua.',
    frequencyType: 'daily',
    registrationsPerPeriod: 2,
    durationPeriods: 21,
  ),

  // --------------------------------------------------
  // ENERGÍA - SENCILLO
  // --------------------------------------------------
  _habit(
    id: 'ener_001',
    title: 'Caminar 10 minutos',
    category: 'Energía',
    difficulty: 'Sencillo',
    subtitle: 'Realiza una caminata breve durante el día.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 7,
  ),
  _habit(
    id: 'ener_002',
    title: 'Estirarme por la mañana',
    category: 'Energía',
    difficulty: 'Sencillo',
    subtitle: 'Dedica unos minutos a estirar tu cuerpo.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 7,
  ),
  _habit(
    id: 'ener_003',
    title: 'Tomar una pausa activa',
    category: 'Energía',
    difficulty: 'Sencillo',
    subtitle: 'Levántate y mueve tu cuerpo durante una pausa.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 7,
  ),

  // --------------------------------------------------
  // ENERGÍA - MODERADO
  // --------------------------------------------------
  _habit(
    id: 'ener_004',
    title: 'Entrenar tres veces',
    category: 'Energía',
    difficulty: 'Moderado',
    subtitle: 'Completa tres sesiones de actividad física por semana.',
    frequencyType: 'weekly',
    registrationsPerPeriod: 3,
    durationPeriods: 4,
  ),
  _habit(
    id: 'ener_005',
    title: 'Caminar 30 minutos',
    category: 'Energía',
    difficulty: 'Moderado',
    subtitle: 'Realiza una caminata de 30 minutos.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 14,
  ),
  _habit(
    id: 'ener_006',
    title: 'Rutina de movilidad',
    category: 'Energía',
    difficulty: 'Moderado',
    subtitle: 'Completa una sesión de movilidad y estiramientos.',
    frequencyType: 'weekly',
    registrationsPerPeriod: 4,
    durationPeriods: 4,
  ),

  // --------------------------------------------------
  // ENERGÍA - DIFÍCIL
  // --------------------------------------------------
  _habit(
    id: 'ener_007',
    title: 'Entrenamiento constante',
    category: 'Energía',
    difficulty: 'Difícil',
    subtitle: 'Completa cinco sesiones de actividad física por semana.',
    frequencyType: 'weekly',
    registrationsPerPeriod: 5,
    durationPeriods: 6,
  ),
  _habit(
    id: 'ener_008',
    title: 'Rutina física integral',
    category: 'Energía',
    difficulty: 'Difícil',
    subtitle:
        'Combina sesiones de fuerza, movilidad y actividad cardiovascular.',
    frequencyType: 'weekly',
    registrationsPerPeriod: 5,
    durationPeriods: 6,
  ),
  _habit(
    id: 'ener_009',
    title: 'Actividad física diaria',
    category: 'Energía',
    difficulty: 'Difícil',
    subtitle: 'Completa una sesión de movimiento cada día.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 21,
  ),

  // --------------------------------------------------
  // BIENESTAR - SENCILLO
  // --------------------------------------------------
  _habit(
    id: 'bien_001',
    title: 'Respirar conscientemente',
    category: 'Bienestar',
    difficulty: 'Sencillo',
    subtitle: 'Dedica unos minutos a respirar con calma.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 7,
  ),
  _habit(
    id: 'bien_002',
    title: 'Tomar un descanso',
    category: 'Bienestar',
    difficulty: 'Sencillo',
    subtitle: 'Haz una pausa para desconectarte de tus actividades.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 7,
  ),
  _habit(
    id: 'bien_003',
    title: 'Escribir algo positivo',
    category: 'Bienestar',
    difficulty: 'Sencillo',
    subtitle: 'Anota algo positivo que haya ocurrido durante tu día.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 7,
  ),

  // --------------------------------------------------
  // BIENESTAR - MODERADO
  // --------------------------------------------------
  _habit(
    id: 'bien_004',
    title: 'Meditar 10 minutos',
    category: 'Bienestar',
    difficulty: 'Moderado',
    subtitle: 'Realiza una sesión de meditación de diez minutos.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 14,
  ),
  _habit(
    id: 'bien_005',
    title: 'Desconectarme de las pantallas',
    category: 'Bienestar',
    difficulty: 'Moderado',
    subtitle: 'Reserva un espacio del día sin dispositivos electrónicos.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 14,
  ),
  _habit(
    id: 'bien_006',
    title: 'Cuidar mi descanso',
    category: 'Bienestar',
    difficulty: 'Moderado',
    subtitle: 'Mantén una rutina personal de preparación para dormir.',
    frequencyType: 'daily',
    registrationsPerPeriod: 1,
    durationPeriods: 14,
  ),

  // --------------------------------------------------
  // BIENESTAR - DIFÍCIL
  // --------------------------------------------------
  _habit(
    id: 'bien_007',
    title: 'Rutina diaria de bienestar',
    category: 'Bienestar',
    difficulty: 'Difícil',
    subtitle: 'Combina actividades de relajación, reflexión y autocuidado.',
    frequencyType: 'daily',
    registrationsPerPeriod: 2,
    durationPeriods: 21,
  ),
  _habit(
    id: 'bien_008',
    title: 'Diario de reflexión semanal',
    category: 'Bienestar',
    difficulty: 'Difícil',
    subtitle: 'Dedica tiempo a reflexionar y registrar tus avances personales.',
    frequencyType: 'weekly',
    registrationsPerPeriod: 5,
    durationPeriods: 6,
  ),
  _habit(
    id: 'bien_009',
    title: 'Equilibrio entre actividad y descanso',
    category: 'Bienestar',
    difficulty: 'Difícil',
    subtitle:
        'Organiza tu semana para equilibrar responsabilidades y recuperación.',
    frequencyType: 'weekly',
    registrationsPerPeriod: 5,
    durationPeriods: 6,
  ),
];

/// Busca un hábito por su identificador.
Map<String, dynamic>? findHabitById(String id) {
  for (final habit in habitCatalog) {
    if (habit['id'] == id) return habit;
  }
  return null;
}

/// Filtra por categoría y dificultad.
/// Usa null para no aplicar un filtro.
List<Map<String, dynamic>> filterHabitCatalog({
  String? category,
  String? difficulty,
}) {
  return habitCatalog.where((habit) {
    final matchesCategory = category == null || habit['category'] == category;
    final matchesDifficulty =
        difficulty == null || habit['difficulty'] == difficulty;

    return matchesCategory && matchesDifficulty;
  }).toList();
}
