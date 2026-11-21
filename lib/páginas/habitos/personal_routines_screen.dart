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
      MaterialPageRoute(builder: (_) => const _RoutineEditor()),
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
        builder: (_) => _RoutineEditor(
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
        builder: (_) => const _RoutineEditor(singleGoal: true),
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
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('personal-routine-create'),
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Crear rutina'),
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
                OutlinedButton.icon(
                  key: const ValueKey('personal-goal-create'),
                  onPressed: _createGoal,
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Crear meta personal'),
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

class _RoutineEditor extends StatefulWidget {
  const _RoutineEditor({this.existing, this.singleGoal = false});

  final PersonalRoutine? existing;
  final bool singleGoal;

  @override
  State<_RoutineEditor> createState() => _RoutineEditorState();
}

class _RoutineEditorState extends State<_RoutineEditor> {
  final _title = TextEditingController();
  final _stepName = TextEditingController();
  final _goal = TextEditingController(text: '10');
  final _unit = TextEditingController(text: 'repeticiones');
  final List<PersonalRoutineStep> _steps = [];
  String _type = 'counter';

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

  void _addStep() {
    final name = _stepName.text.trim();
    final target = int.tryParse(_goal.text.trim());
    if (widget.singleGoal && _steps.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Una meta personal tiene una sola actividad.')),
      );
      return;
    }
    if (name.isEmpty || target == null || target < 1 || target > 86400) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un paso y una meta válida (1 a 86400).')),
      );
      return;
    }
    setState(() {
      _steps.add(PersonalRoutineStep(
        title: name,
        type: _type,
        target: target,
        unit: _type == 'counter' ? _unit.text.trim() : 'segundos',
      ));
      _stepName.clear();
    });
  }

  void _save() {
    if (_title.text.trim().isEmpty || _steps.isEmpty ||
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
          const SizedBox(height: 16),
          Text(widget.singleGoal ? 'Configura tu meta' : 'Añadir actividad'),
          const SizedBox(height: 10),
          TextField(
            controller: _stepName,
            maxLength: 70,
            decoration: const InputDecoration(
              labelText: 'Actividad',
              hintText: 'Ej. Sentadillas o descanso',
              border: OutlineInputBorder(),
            ),
          ),
          DropdownButtonFormField<String>(
            value: _type,
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
            onPressed: widget.singleGoal && _steps.isNotEmpty ? null : _addStep,
            icon: const Icon(Icons.add),
            label: Text(widget.singleGoal ? 'Establecer meta' : 'Añadir paso'),
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < _steps.length; index++)
            ListTile(
              title: Text(_steps[index].title),
              subtitle: Text(
                '${_steps[index].target} ${_steps[index].unit}',
              ),
              leading: CircleAvatar(child: Text('${index + 1}')),
              trailing: IconButton(
                tooltip: 'Quitar paso',
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _steps.removeAt(index)),
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
