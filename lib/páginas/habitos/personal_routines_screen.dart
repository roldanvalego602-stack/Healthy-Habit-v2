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

class PersonalRoutinesStore {
  const PersonalRoutinesStore();

  static const key = 'healthy_personal_routines_v1';

  String get _storageKey {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? '${key}_guest' : '${key}_$uid';
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
        builder: (_) => _RoutineEditor(existing: routine),
      ),
    );
    if (edited == null || !mounted) return;
    try {
      final current = await _store.load();
      await _store.save([
        for (final item in current)
          if (item.id == routine.id) edited else item,
      ]);
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
      await _reload();
    } catch (error) {
      if (mounted) _message('$error');
    }
  }

  Future<void> _run(PersonalRoutine routine) async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _RoutineRunner(routine: routine)),
    );
    if (completed != true || !mounted) return;
    try {
      final current = await _store.load();
      await _store.save([
        for (final item in current)
          item.id == routine.id
              ? item.copyWith(completedSessions: item.completedSessions + 1)
              : item,
      ]);
      await _reload();
      if (mounted) _message('Sesión personal completada. Sin recompensas oficiales.');
    } catch (error) {
      if (mounted) _message('$error');
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
                for (final routine in _routines)
                  Card(
                    key: ValueKey('personal-routine-${routine.id}'),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            routine.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: HealthyAdaptive.text,
                            ),
                          ),
                          Text(
                            '${routine.steps.length} pasos · ${routine.completedSessions} sesiones completadas',
                            style: TextStyle(color: HealthyAdaptive.muted),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _run(routine),
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Comenzar'),
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
  const _RoutineRunner({required this.routine});
  final PersonalRoutine routine;

  @override
  State<_RoutineRunner> createState() => _RoutineRunnerState();
}

class _RoutineRunnerState extends State<_RoutineRunner> {
  int _step = 0;
  bool _complete = false;

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
            onChanged: (complete, _) {
              if (mounted && complete != _complete) {
                setState(() => _complete = complete);
              }
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: const ValueKey('personal-routine-next'),
            onPressed: _complete
                ? () {
                    if (_step + 1 == widget.routine.steps.length) {
                      Navigator.pop(context, true);
                    } else {
                      setState(() {
                        _step++;
                        _complete = false;
                      });
                    }
                  }
                : null,
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
