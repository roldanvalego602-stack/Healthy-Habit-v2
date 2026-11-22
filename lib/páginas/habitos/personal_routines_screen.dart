import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../tema/healthy_theme.dart';
import 'habit_interaction_card.dart';

/// Rutinas privadas del dispositivo. No forman parte de las transacciones
/// de hábitos oficiales y no conceden XP ni Habit Coins.
class PersonalRoutine {
  const PersonalRoutine({
    required this.id,
    required this.title,
    required this.steps,
    this.completedSessions = 0,
    this.dailyGoal = false,
    this.completedDays = const [],
  });

  final String id;
  final String title;
  final List<PersonalRoutineStep> steps;
  final int completedSessions;
  final bool dailyGoal;
  final List<String> completedDays;

  bool completedOn(DateTime date) => completedDays.contains(dateKey(date));

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  PersonalRoutine copyWith({
    String? title,
    List<PersonalRoutineStep>? steps,
    int? completedSessions,
    bool? dailyGoal,
    List<String>? completedDays,
  }) => PersonalRoutine(
        id: id,
        title: title ?? this.title,
        steps: steps ?? this.steps,
        completedSessions: completedSessions ?? this.completedSessions,
        dailyGoal: dailyGoal ?? this.dailyGoal,
        completedDays: completedDays ?? this.completedDays,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'steps': steps.map((step) => step.toJson()).toList(),
        'completedSessions': completedSessions,
        'dailyGoal': dailyGoal,
        'completedDays': completedDays,
      };

  factory PersonalRoutine.fromJson(Map<String, dynamic> data) {
    final rawSteps = data['steps'];
    return PersonalRoutine(
      id: data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      steps: rawSteps is List
          ? rawSteps
              .whereType<Map>()
              .map((step) => PersonalRoutineStep.fromJson(
                  Map<String, dynamic>.from(step)))
              .toList()
          : <PersonalRoutineStep>[],
      completedSessions:
          ((data['completedSessions'] as num?)?.toInt() ?? 0).clamp(0, 1000000).toInt(),
      dailyGoal: data['dailyGoal'] == true,
      completedDays: data['completedDays'] is List
          ? (data['completedDays'] as List)
              .whereType<String>()
              .where((day) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day))
              .toSet()
              .toList()
          : <String>[],
    );
  }
}

class PersonalRoutineStep {
  const PersonalRoutineStep({
    required this.title,
    required this.type,
    required this.target,
    required this.unit,
  });

  final String title;
  final String type;
  final int target;
  final String unit;

  PersonalRoutineStep copyWith({
    String? title,
    String? type,
    int? target,
    String? unit,
  }) => PersonalRoutineStep(
        title: title ?? this.title,
        type: type ?? this.type,
        target: target ?? this.target,
        unit: unit ?? this.unit,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'type': type,
        'target': target,
        'unit': unit,
      };

  factory PersonalRoutineStep.fromJson(Map<String, dynamic> data) {
    final kind = data['type']?.toString() ?? 'counter';
    return PersonalRoutineStep(
      title: data['title']?.toString() ?? '',
      type: {'counter', 'timer', 'stopwatch'}.contains(kind) ? kind : 'counter',
      target: ((data['target'] as num?)?.toInt() ?? 1).clamp(1, 86400).toInt(),
      unit: data['unit']?.toString() ?? 'repeticiones',
    );
  }
}

/// Estado de la sesión en curso, aislado del registro oficial.
class PersonalRoutineDraft {
  const PersonalRoutineDraft({
    required this.date,
    this.stepIndex = 0,
    this.stepValue = 0,
  });

  final String date;
  final int stepIndex;
  final int stepValue;

  Map<String, dynamic> toJson() => {
        'date': date,
        'stepIndex': stepIndex,
        'stepValue': stepValue,
      };

  factory PersonalRoutineDraft.fromJson(Map<String, dynamic> data) =>
      PersonalRoutineDraft(
        date: data['date']?.toString() ?? '',
        stepIndex: ((data['stepIndex'] as num?)?.toInt() ?? 0)
            .clamp(0, 1000).toInt(),
        stepValue: ((data['stepValue'] as num?)?.toInt() ?? 0)
            .clamp(0, 86400).toInt(),
      );
}

class PersonalRoutinesStore {
  const PersonalRoutinesStore();

  static const key = 'healthy_personal_routines_v1';

  String get _storageKey {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? '${key}_guest' : '${key}_$uid';
  }

  String _draftKey(String routineId) => '${_storageKey}_draft_$routineId';

  Future<PersonalRoutineDraft?> loadDraft(String routineId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey(routineId));
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return null;
      final draft = PersonalRoutineDraft.fromJson(
        Map<String, dynamic>.from(data),
      );
      return draft.date == PersonalRoutine.dateKey(DateTime.now())
          ? draft
          : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> saveDraft(
    String routineId,
    PersonalRoutineDraft draft,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      _draftKey(routineId),
      jsonEncode(draft.toJson()),
    )) {
      throw StateError('No se pudo guardar el progreso de la sesión.');
    }
  }

  Future<void> clearDraft(String routineId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey(routineId));
  }

  Future<List<PersonalRoutine>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final data = jsonDecode(raw);
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((entry) => PersonalRoutine.fromJson(
              Map<String, dynamic>.from(entry)))
          .where((entry) => entry.id.isNotEmpty && entry.title.isNotEmpty)
          .toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> save(List<PersonalRoutine> routines) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(routines.map((routine) => routine.toJson()).toList());
    if (!await prefs.setString(_storageKey, data)) {
      throw StateError('No se pudieron guardar tus rutinas.');
    }
  }
}

class PersonalRoutinesScreen extends StatefulWidget {
  const PersonalRoutinesScreen({super.key});

  @override
  State<PersonalRoutinesScreen> createState() => _PersonalRoutinesScreenState();
}

class _PersonalRoutinesScreenState extends State<PersonalRoutinesScreen> {
  final PersonalRoutinesStore _store = const PersonalRoutinesStore();
  List<PersonalRoutine> _routines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final items = await _store.load();
      if (mounted) {
        setState(() {
          _routines = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _create() async {
    final routine = await Navigator.push<PersonalRoutine>(
      context,
      MaterialPageRoute(builder: (_) => const PersonalRoutineEditor()),
    );
    if (routine == null || !mounted) return;
    try {
      await _store.save([..._routines, routine]);
      await _reload();
    } catch (error) {
      if (mounted) _message('$error');
    }
  }

  Future<void> _edit(PersonalRoutine routine) async {
    final edited = await Navigator.push<PersonalRoutine>(
      context,
      MaterialPageRoute(
        builder: (_) => PersonalRoutineEditor(
          existing: routine,
          singleGoal: routine.dailyGoal,
        ),
      ),
    );
    if (edited == null || !mounted) return;
    try {
      final current = await _store.load();
      await _store.save([
        for (final item in current)
          if (item.id == routine.id) edited else item,
      ]);
      await _store.clearDraft(routine.id);
      await _reload();
    } catch (error) {
      if (mounted) _message('$error');
    }
  }

  Future<void> _createGoal() async {
    final goal = await Navigator.push<PersonalRoutine>(
      context,
      MaterialPageRoute(
        builder: (_) => const PersonalRoutineEditor(singleGoal: true),
      ),
    );
    if (goal == null || !mounted) return;
    try {
      await _store.save([...await _store.load(), goal]);
      await _reload();
    } catch (error) {
      if (mounted) _message('$error');
    }
  }

  Future<void> _remove(PersonalRoutine routine) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar rutina personal'),
        content: Text('¿Eliminar "${routine.title}" y su historial local?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    try {
      await _store.save(_routines.where((item) => item.id != routine.id).toList());
      await _store.clearDraft(routine.id);
      await _reload();
    } catch (error) {
      if (mounted) _message('$error');
    }
  }

  Future<void> _run(PersonalRoutine routine) async {
    if (routine.dailyGoal && routine.completedOn(DateTime.now())) {
      _message('Ya completaste esta meta hoy. Podrás repetirla mañana.');
      return;
    }
    try {
      final draft = await _store.loadDraft(routine.id);
      if (!mounted) return;
      final completed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => _RoutineRunner(routine: routine, draft: draft),
        ),
      );
      if (completed != true || !mounted) return;
      final current = await _store.load();
      final today = PersonalRoutine.dateKey(DateTime.now());
      await _store.save([
        for (final item in current)
          if (item.id != routine.id)
            item
          else if (item.dailyGoal && item.completedDays.contains(today))
            item
          else
            item.copyWith(
              completedSessions: item.completedSessions + 1,
              completedDays: item.dailyGoal
                  ? [...item.completedDays, today]
                  : item.completedDays,
            ),
      ]);
      await _store.clearDraft(routine.id);
      await _reload();
      if (mounted) _message('Sesión personal completada. Sin recompensas oficiales.');
    } catch (error) {
      if (mounted) _message('No se pudo guardar el progreso: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealthyAdaptive.background,
      appBar: AppBar(
        title: const Text('Mis rutinas personales'),
        backgroundColor: HealthyAdaptive.background,
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                Text(
                  'Tu espacio, tus objetivos',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: HealthyAdaptive.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Organiza ejercicios, descansos y metas con contadores y '
                  'temporizadores. Las rutinas se guardan solo en este '
                  'dispositivo y no otorgan XP ni Habit Coins.',
                  style: TextStyle(color: HealthyAdaptive.muted),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('personal-routine-primary'),
                    onPressed: _create,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Crear y guardar mi rutina'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Agrega tantos ejercicios y descansos como necesites; '
                  'guarda la rutina después de organizar sus pasos.',
                  style: TextStyle(color: HealthyAdaptive.muted, fontSize: 12),
                ),
                const SizedBox(height: 18),
                Text('Otras opciones',
                  style: TextStyle(
                    color: HealthyAdaptive.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  key: const ValueKey('personal-goal-create'),
                  onPressed: _createGoal,
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Crear meta individual (una actividad)'),
                ),
                const SizedBox(height: 24),
                if (_routines.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.fitness_center_outlined, size: 42),
                          const SizedBox(height: 10),
                          const Text('Aún no tienes rutinas personales'),
                          const SizedBox(height: 8),
                          Text(
                            'Crea una para entrenar, descansar o cumplir '
                            'cualquier meta que puedas medir.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: HealthyAdaptive.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_routines.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Tus metas y rutinas',
                      style: TextStyle(
                        color: HealthyAdaptive.text,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                for (final routine in [
                  ..._routines.where((item) => item.dailyGoal),
                  ..._routines.where((item) => !item.dailyGoal),
                ])
                  Card(
                    key: ValueKey('personal-routine-${routine.id}'),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                routine.dailyGoal
                                    ? Icons.water_drop_outlined
                                    : Icons.fitness_center_outlined,
                                color: HealthyAdaptive.accent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  routine.dailyGoal
                                      ? 'META PERSONAL'
                                      : 'RUTINA PERSONAL',
                                  style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w800,
                                    color: HealthyAdaptive.accent,
                                  ),
                                ),
                              ),
                              if (routine.dailyGoal &&
                                  routine.completedOn(DateTime.now()))
                                Icon(Icons.check_circle_rounded,
                                    color: HealthyAdaptive.accent),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            routine.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: HealthyAdaptive.text,
                            ),
                          ),
                          Text(
                            routine.dailyGoal
                                ? 'Meta diaria · ${routine.completedDays.length} días completados'
                                : '${routine.steps.length} pasos · ${routine.completedSessions} sesiones completadas',
                            style: TextStyle(color: HealthyAdaptive.muted),
                          ),
                          if (routine.dailyGoal && routine.completedOn(DateTime.now()))
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text('Meta de hoy completada ✓'),
                            ),
                          if (routine.dailyGoal) ...[
                            const SizedBox(height: 14),
                            Text(
                              'Últimos 7 días',
                              style: TextStyle(
                                color: HealthyAdaptive.muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _PersonalWeekCalendar(routine: routine),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: routine.dailyGoal && routine.completedOn(DateTime.now())
                                      ? null
                                      : () => _run(routine),
                                  icon: const Icon(Icons.play_arrow),
                                  label: Text(routine.dailyGoal ? 'Registrar hoy' : 'Iniciar o continuar'),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Editar rutina',
                                onPressed: () => _edit(routine),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Eliminar rutina',
                                onPressed: () => _remove(routine),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Resumen visual de siete días; usa las fechas locales registradas.
class _PersonalWeekCalendar extends StatelessWidget {
  const _PersonalWeekCalendar({required this.routine});

  final PersonalRoutine routine;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const weekdays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Row(
      key: const ValueKey('personal-goal-week-calendar'),
      children: [
        for (var i = 6; i >= 0; i--)
          Expanded(
            child: Builder(
              builder: (context) {
                final date = DateTime(now.year, now.month, now.day)
                    .subtract(Duration(days: i));
                final completed = routine.completedOn(date);
                final isToday = i == 0;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(weekdays[date.weekday - 1],
                        style: TextStyle(
                          fontSize: 11,
                          color: HealthyAdaptive.muted,
                        )),
                    const SizedBox(height: 6),
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completed
                            ? HealthyAdaptive.accent
                            : HealthyAdaptive.surface,
                        border: Border.all(
                          color: isToday
                              ? HealthyAdaptive.accent
                              : HealthyAdaptive.border,
                          width: isToday ? 2 : 1,
                        ),
                      ),
                      child: completed
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : Text(
                              '${date.day}',
                              style: TextStyle(
                                color: HealthyAdaptive.text,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Plantillas locales: no conceden recompensas y siempre son editables.
class PersonalRoutineTemplates {
  static const strength = [
    PersonalRoutineStep(
      title: 'Sentadillas', type: 'counter', target: 12, unit: 'repeticiones'),
    PersonalRoutineStep(
      title: 'Descanso', type: 'timer', target: 45, unit: 'segundos'),
    PersonalRoutineStep(
      title: 'Desplantes', type: 'counter', target: 10, unit: 'repeticiones'),
  ];

  static const focus = [
    PersonalRoutineStep(
      title: 'Concentración', type: 'timer', target: 1500, unit: 'segundos'),
    PersonalRoutineStep(
      title: 'Pausa', type: 'timer', target: 300, unit: 'segundos'),
  ];

  static const mobility = [
    PersonalRoutineStep(
      title: 'Movilidad suave', type: 'timer', target: 120, unit: 'segundos'),
    PersonalRoutineStep(
      title: 'Descanso', type: 'timer', target: 30, unit: 'segundos'),
    PersonalRoutineStep(
      title: 'Estiramiento', type: 'timer', target: 120, unit: 'segundos'),
  ];
}

class PersonalRoutineEditor extends StatefulWidget {
  const PersonalRoutineEditor({super.key, this.existing, this.singleGoal = false});

  final PersonalRoutine? existing;
  final bool singleGoal;

  @override
  State<PersonalRoutineEditor> createState() => _PersonalRoutineEditorState();
}

class _PersonalRoutineEditorState extends State<PersonalRoutineEditor> {
  final _title = TextEditingController();
  final _stepName = TextEditingController();
  final _goal = TextEditingController(text: '10');
  final _unit = TextEditingController(text: 'repeticiones');
  final List<PersonalRoutineStep> _steps = [];
  String _type = 'counter';
  String? _ultimoEjercicioAnadido;

  void _applyTemplate(String title, List<PersonalRoutineStep> steps) {
    if (widget.singleGoal || widget.existing != null || _steps.isNotEmpty) {
      return;
    }
    setState(() {
      _title.text = title;
      _steps.addAll(steps);
    });
  }

  void _moveStep(int index, int offset) {
    final next = index + offset;
    if (widget.singleGoal || next < 0 || next >= _steps.length) return;
    setState(() {
      final step = _steps.removeAt(index);
      _steps.insert(next, step);
    });
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _title.text = existing.title;
      _steps.addAll(existing.steps);
    }
    if (widget.singleGoal) {
      _goal.text = '2000';
      _unit.text = 'ml';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _stepName.dispose();
    _goal.dispose();
    _unit.dispose();
    super.dispose();
  }

  bool _addStep({bool showConfirmation = true}) {
    final name = _stepName.text.trim();
    final target = int.tryParse(_goal.text.trim());
    if (widget.singleGoal && _steps.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
          'Una meta individual admite una sola actividad. '
          'Elige «Crear rutina» para combinar varios ejercicios.',
        )),
      );
      return false;
    }
    if (name.isEmpty || target == null || target < 1 || target > 86400 ||
        (_type == 'counter' && _unit.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
          'Escribe una actividad, su cantidad válida y una unidad '
          'antes de añadirla.',
        )),
      );
      return false;
    }
    setState(() {
      _steps.add(PersonalRoutineStep(
        title: name,
        type: _type,
        target: target,
        unit: _type == 'counter' ? _unit.text.trim() : 'segundos',
      ));
      _stepName.clear();
      // Confirmación dentro del formulario: no tapa el botón Guardar.
      _ultimoEjercicioAnadido = showConfirmation ? name : null;
    });
    return true;
  }

  Future<void> _editStep(int index) async {
    final original = _steps[index];
    final edited = await showDialog<PersonalRoutineStep>(
      context: context,
      builder: (dialogContext) =>
          _PersonalRoutineStepDialog(initial: original),
    );
    if (!mounted || edited == null) return;
    setState(() => _steps[index] = edited);
  }

  void _save() {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un nombre a tu rutina.')),
      );
      return;
    }
    // Si quedó una actividad escrita, inclúyela antes de guardar.
    // Así no se pierde al pulsar Guardar sin tocar Añadir ejercicio.
    if (_stepName.text.trim().isNotEmpty &&
        !_addStep(showConfirmation: false)) {
      return;
    }
    if (_steps.isEmpty ||
        _steps.any((step) => step.title.isEmpty || step.unit.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un nombre y añade al menos un paso.')),
      );
      return;
    }
    Navigator.pop(context, PersonalRoutine(
      id: widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: _title.text.trim(),
      steps: List.unmodifiable(_steps),
      completedSessions: widget.existing?.completedSessions ?? 0,
      dailyGoal: widget.existing?.dailyGoal ?? widget.singleGoal,
      completedDays: widget.existing?.completedDays ?? const [],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null
            ? 'Editar rutina'
            : widget.singleGoal ? 'Nueva meta personal' : 'Diseñar rutina'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            key: const ValueKey('personal-routine-name'),
            controller: _title,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Nombre de tu rutina',
              hintText: 'Ej. Entrenamiento de pierna',
              border: OutlineInputBorder(),
            ),
          ),
          if (!widget.singleGoal && widget.existing == null && _steps.isEmpty) ...[
            Text('Comienza desde una plantilla',
                style: TextStyle(
                  color: HealthyAdaptive.text,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.fitness_center_outlined, size: 18),
                  label: const Text('Fuerza'),
                  onPressed: () => _applyTemplate(
                    'Entrenamiento de fuerza', PersonalRoutineTemplates.strength),
                ),
                ActionChip(
                  avatar: const Icon(Icons.psychology_outlined, size: 18),
                  label: const Text('Concentración'),
                  onPressed: () => _applyTemplate(
                    'Sesión de concentración', PersonalRoutineTemplates.focus),
                ),
                ActionChip(
                  avatar: const Icon(Icons.accessibility_new_rounded, size: 18),
                  label: const Text('Movilidad'),
                  onPressed: () => _applyTemplate(
                    'Movilidad y estiramiento', PersonalRoutineTemplates.mobility),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          const SizedBox(height: 16),
          if (!widget.singleGoal)
            Card(
              color: HealthyAdaptive.surface,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Una rutina admite varios ejercicios',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: HealthyAdaptive.text,
                      )),
                    const SizedBox(height: 5),
                    Text('Añade una actividad, su cantidad o tiempo y pulsa '
                      '«Añadir ejercicio». Repite para incluir todas las '
                      'actividades de la rutina. Después puedes cambiar '
                      'su orden y guardar.',
                      style: TextStyle(color: HealthyAdaptive.muted,
                          fontSize: 12)),
                    const SizedBox(height: 6),
                    Text('${_steps.length} actividades añadidas',
                      key: const ValueKey('routine-steps-count'),
                      style: TextStyle(color: HealthyAdaptive.accent,
                          fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          Text(widget.singleGoal ? 'Configura tu meta' : 'Añadir ejercicio'),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('routine-new-exercise'),
            controller: _stepName,
            maxLength: 70,
            decoration: const InputDecoration(
              labelText: 'Actividad',
              hintText: 'Ej. Sentadillas o descanso',
              border: OutlineInputBorder(),
            ),
          ),
          Text('Selecciona una herramienta',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: HealthyAdaptive.text,
              )),
          const SizedBox(height: 8),
          Row(
            children: [
              _toolChoice('counter', 'Contador', Icons.add_circle_outline),
              const SizedBox(width: 7),
              _toolChoice('timer', 'Temporizador', Icons.hourglass_bottom_rounded),
              const SizedBox(width: 7),
              _toolChoice('stopwatch', 'Cronómetro', Icons.timer_outlined),
            ],
          ),
          const SizedBox(height: 12),
          if (_type == 'counter')
            TextField(
              controller: _unit,
              maxLength: 24,
              decoration: const InputDecoration(
                labelText: 'Unidad de medida',
                hintText: 'ml, vasos, repeticiones, páginas...',
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _goal,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _type == 'counter'
                  ? 'Cantidad objetivo'
                  : 'Duración en segundos',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: widget.singleGoal && _steps.isNotEmpty
                ? null : () => _addStep(),
            icon: const Icon(Icons.add),
            label: Text(widget.singleGoal ? 'Establecer meta' : 'Añadir ejercicio a la rutina'),
          ),
          if (_ultimoEjercicioAnadido != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                '✓ «$_ultimoEjercicioAnadido» añadido. '
                'Puedes agregar otro ejercicio o guardar la rutina.',
                key: const ValueKey('routine-step-added-feedback'),
                style: TextStyle(
                  color: HealthyAdaptive.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          for (var index = 0; index < _steps.length; index++)
            ListTile(
              key: ValueKey('personal-edit-step-$index'),
              onTap: () => _editStep(index),
              title: Text(_steps[index].title),
              subtitle: Text(
                '${_steps[index].target} ${_steps[index].unit}',
              ),
              leading: CircleAvatar(child: Text('${index + 1}')),
              trailing: PopupMenuButton<String>(
                tooltip: 'Opciones de actividad',
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (action) {
                  switch (action) {
                    case 'edit':
                      _editStep(index);
                      break;
                    case 'up':
                      _moveStep(index, -1);
                      break;
                    case 'down':
                      _moveStep(index, 1);
                      break;
                    case 'remove':
                      setState(() => _steps.removeAt(index));
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Editar actividad'),
                  ),
                  if (!widget.singleGoal && index > 0)
                    const PopupMenuItem(
                      value: 'up',
                      child: Text('Subir paso'),
                    ),
                  if (!widget.singleGoal && index < _steps.length - 1)
                    const PopupMenuItem(
                      value: 'down',
                      child: Text('Bajar paso'),
                    ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text('Eliminar actividad'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const ValueKey('personal-routine-save'),
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(widget.existing != null
                ? 'Guardar cambios'
                : widget.singleGoal
                    ? 'Guardar meta personal'
                    : 'Guardar rutina personal'),
          ),
        ],
      ),
    );
  }

  Widget _toolChoice(String value, String label, IconData icon) {
    final selected = _type == value;
    return Expanded(
      child: InkWell(
        key: ValueKey('routine-tool-$value'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _type = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 90),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? HealthyAdaptive.mint : HealthyAdaptive.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? HealthyAdaptive.accent : HealthyAdaptive.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected
                  ? HealthyAdaptive.accent : HealthyAdaptive.muted),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: HealthyAdaptive.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _PersonalRoutineStepDialog extends StatefulWidget {
  const _PersonalRoutineStepDialog({required this.initial});

  final PersonalRoutineStep initial;

  @override
  State<_PersonalRoutineStepDialog> createState() =>
      _PersonalRoutineStepDialogState();
}

class _PersonalRoutineStepDialogState extends State<_PersonalRoutineStepDialog> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _unit;
  late String _type;

  @override
  void initState() {
    super.initState();
    final step = widget.initial;
    _name = TextEditingController(text: step.title);
    _target = TextEditingController(text: step.target.toString());
    _unit = TextEditingController(text: step.unit);
    _type = step.type;
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _unit.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = int.tryParse(_target.text.trim());
    final name = _name.text.trim();
    final unit = _type == 'counter' ? _unit.text.trim() : 'segundos';
    if (name.isEmpty || unit.isEmpty ||
        amount == null || amount < 1 || amount > 86400) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica un nombre, unidad y meta válida (1–86400).')),
      );
      return;
    }
    Navigator.pop(context, widget.initial.copyWith(
      title: name, target: amount, type: _type, unit: unit,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar actividad'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('edit-step-title'),
              controller: _name,
              maxLength: 70,
              decoration: const InputDecoration(labelText: 'Actividad'),
            ),
            DropdownButtonFormField<String>(
              value: _type,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Herramienta'),
              items: const [
                DropdownMenuItem(value: 'counter', child: Text('Contador')),
                DropdownMenuItem(value: 'timer', child: Text('Temporizador')),
                DropdownMenuItem(value: 'stopwatch', child: Text('Cronómetro')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            TextField(
              key: const ValueKey('edit-step-target'),
              controller: _target,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _type == 'counter' ? 'Cantidad' : 'Segundos',
              ),
            ),
            if (_type == 'counter')
              TextField(
                key: const ValueKey('edit-step-unit'),
                controller: _unit,
                maxLength: 24,
                decoration: const InputDecoration(labelText: 'Unidad'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('edit-step-confirm'),
          onPressed: _submit,
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

class _RoutineRunner extends StatefulWidget {
  const _RoutineRunner({required this.routine, this.draft});
  final PersonalRoutine routine;
  final PersonalRoutineDraft? draft;

  @override
  State<_RoutineRunner> createState() => _RoutineRunnerState();
}

class _RoutineRunnerState extends State<_RoutineRunner> {
  final PersonalRoutinesStore _store = const PersonalRoutinesStore();
  int _step = 0;
  int _stepValue = 0;
  bool _complete = false;
  bool _advancing = false;
  Future<void> _pendingWrite = Future<void>.value();

  @override
  void initState() {
    super.initState();
    final saved = widget.draft;
    if (saved == null || widget.routine.steps.isEmpty) return;
    _step = saved.stepIndex.clamp(0, widget.routine.steps.length - 1).toInt();
    _stepValue = saved.stepValue
        .clamp(0, widget.routine.steps[_step].target).toInt();
    _complete = _stepValue >= widget.routine.steps[_step].target;
  }

  void _progressChanged(bool complete, int value) {
    if (!mounted || _advancing) return;
    if (_complete != complete || _stepValue != value) {
      setState(() {
        _complete = complete;
        _stepValue = value;
      });
    }
    final saved = PersonalRoutineDraft(
      date: PersonalRoutine.dateKey(DateTime.now()),
      stepIndex: _step,
      stepValue: value,
    );
    _pendingWrite = _pendingWrite
        .then((_) => _store.saveDraft(widget.routine.id, saved))
        .catchError((Object error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se guardó el avance: $error')),
        );
      }
    });
  }

  Future<void> _nextStep() async {
    if (!_complete || _advancing) return;
    setState(() => _advancing = true);
    try {
      await _pendingWrite;
      if (!mounted) return;
      if (_step + 1 == widget.routine.steps.length) {
        Navigator.pop(context, true);
        return;
      }
      final nextIndex = _step + 1;
      await _store.saveDraft(
        widget.routine.id,
        PersonalRoutineDraft(
          date: PersonalRoutine.dateKey(DateTime.now()),
          stepIndex: nextIndex,
        ),
      );
      if (!mounted) return;
      setState(() {
        _step = nextIndex;
        _stepValue = 0;
        _complete = false;
        _advancing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _advancing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo avanzar: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.routine.steps[_step];
    return Scaffold(
      appBar: AppBar(title: Text(widget.routine.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Paso ${_step + 1} de ${widget.routine.steps.length}',
            style: TextStyle(
              color: HealthyAdaptive.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            key: const ValueKey('personal-routine-overall-progress'),
            value: (_step + (_stepValue / step.target))
                .clamp(0.0, widget.routine.steps.length.toDouble())
                .toDouble() / widget.routine.steps.length,
            minHeight: 8,
          ),
          const SizedBox(height: 18),
          Text(
            step.title,
            style: TextStyle(
              color: HealthyAdaptive.text,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          HabitInteractionCard(
            key: ValueKey('personal-step-$_step'),
            type: step.type,
            target: step.target,
            unit: step.unit,
            initialValue: _stepValue,
            onChanged: _progressChanged,
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: const ValueKey('personal-routine-next'),
            onPressed: _complete && !_advancing ? _nextStep : null,
            child: Text(
              _step + 1 == widget.routine.steps.length
                  ? 'Finalizar sesión'
                  : 'Siguiente paso',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Progreso privado: esta sesión no concede recompensas oficiales.',
            textAlign: TextAlign.center,
            style: TextStyle(color: HealthyAdaptive.muted),
          ),
        ],
      ),
    );
  }
}
