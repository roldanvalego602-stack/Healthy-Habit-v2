import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_habit/páginas/chatbot/healthy_assistant_engine.dart';

void main() {
  const engine = HealthyAssistantEngine();
  const profile = <String, dynamic>{
    'name': 'Usuario de prueba',
    'xp': 470,
    'habitCoins': 65,
    'currentStreak': 4,
  };
  const habits = <Map<String, dynamic>>[
    {'title': 'Incluir una fruta', 'latestStatus': 'inProgress'},
    {'title': 'Caminar 10 minutos', 'latestStatus': 'completed'},
  ];

  test('perfil usa exclusivamente los datos facilitados', () {
    final result = engine.resolve('¿Cómo va mi perfil?',
      profile: profile, habits: habits);
    expect(result.text, contains('470 XP'));
    expect(result.text, contains('65'));
    expect(result.text, contains('4 días'));
    expect(result.action, 'profile');
    expect(result.card, 'profile');
  });

  test('solicitar un hábito abre interfaz sin modificar recompensas', () {
    final result = engine.resolve('Agregar Incluir una fruta',
      profile: profile, habits: habits);
    expect(result.action, 'habits');
    expect(result.actionArgument, 'Incluir una fruta');
    expect(result.card, 'habit_add');
    expect(result.text, contains('confirmes'));
  });

  test('abandonar hábito exige confirmación en Hábitos', () {
    final result = engine.resolve('Eliminar Incluir una fruta',
      profile: profile, habits: habits);
    expect(result.action, 'habits');
    expect(result.card, 'habit_remove');
    expect(result.text, contains('confirma'));
  });

  test('recordar intención permite continuar con el nombre', () {
    final result = engine.resolve('Incluir una fruta',
      profile: profile, habits: habits, lastTopic: 'habit_add');
    expect(result.actionArgument, 'Incluir una fruta');
    expect(result.action, 'habits');
  });

  test('un seguimiento pronominal reutiliza el último hábito citado', () {
    final result = engine.resolve('Elimínalo',
      profile: profile, habits: habits,
      lastTopic: 'habit_add',
      lastHabitTitle: 'Incluir una fruta');
    expect(result.action, 'habits');
    expect(result.actionArgument, 'Incluir una fruta');
    expect(result.card, 'habit_remove');
  });

  test('pregunta nutricional responde solo ficha con fuente', () {
    final result = engine.resolve('¿Qué nutrientes tienen las lentejas?',
      profile: profile, habits: habits);
    expect(result.card, 'knowledge');
    expect(result.action, 'source');
    expect(result.actionArgument, 'https://fdc.nal.usda.gov/');
    expect(result.text, contains('USDA'));
    expect(result.text, contains('lentejas'));
  });

  test('sin ficha no inventa valores nutricionales', () {
    final result = engine.resolve('¿Cuántas calorías de dragón azul hay?',
      profile: profile, habits: habits);
    expect(result.text, contains('no inventaré'));
  });

  test('contactos de profesionales no se presentan como verificados', () {
    final result = engine.resolve('Quiero un nutriólogo',
      profile: profile, habits: habits);
    expect(result.action, 'professionals');
    expect(result.text, contains('demostración'));
  });

  test('muestra desafíos sin inventar recompensas', () {
    final result = engine.resolve('Muéstrame los desafíos',
      profile: profile, habits: habits);
    expect(result.action, 'challenges');
    expect(result.card, 'challenges');
    expect(result.text, contains('consultar'));
    expect(result.text, isNot(contains('80 XP')));
  });

  test('consulta misiones como desafíos y no como hábitos', () {
    final result = engine.resolve('Mis misiones',
      profile: profile, habits: habits);
    expect(result.action, 'challenges');
  });

  test('consulta logros mediante un componente de progreso', () {
    final result = engine.resolve('¿Qué logros tengo?',
      profile: profile, habits: habits);
    expect(result.card, 'achievements');
    expect(result.action, 'achievements');
  });

  test('edición de perfil nunca cambia datos desde el motor', () {
    final result = engine.resolve('Cambiar mi nombre',
      profile: profile, habits: habits);
    expect(result.card, 'edit_profile');
    expect(result.action, 'edit_profile');
  });

  test('encuentra artículo único del catálogo por nombre parcial', () {
    final result = engine.resolve('Quiero comprar corona',
      profile: profile, habits: habits);
    expect(result.action, 'shop');
    expect(result.actionArgument, 'crown');
    expect(result.card, 'shop_item');
  });

  test('una solicitud genérica abre selector de artículos reales', () {
    final result = engine.resolve('Qué puedo comprar',
      profile: profile, habits: habits);
    expect(result.card, 'shop_picker');
  });

  test('el motor conserva un fallback para intenciones no verificadas', () {
    final result = engine.resolve('Explícame física cuántica',
      profile: profile, habits: habits);
    expect(result.text, isEmpty);
    expect(result.action, isEmpty);
  });
}
