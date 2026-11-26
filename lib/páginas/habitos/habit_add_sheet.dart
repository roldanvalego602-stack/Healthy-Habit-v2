import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../tema/healthy_theme.dart';
import '../../tema/healthy_visual_mode.dart';
import 'modelo/habit.dart';

/// Ficha de activación: una única confirmación. No escribe en Firebase.
/// El llamador debe validar el preview y ejecutar HabitActionService.
class HabitAddSheet extends StatefulWidget {
  const HabitAddSheet({super.key, required this.habit, required this.cost});

  final Habit habit;
  final int cost;

  static Future<Map<String, dynamic>?> open(
      BuildContext context, Habit habit, int cost) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: HealthyAdaptive.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => HabitAddSheet(habit: habit, cost: cost),
    );
  }

  @override
  State<HabitAddSheet> createState() => _HabitAddSheetState();
}

class _HabitAddSheetState extends State<HabitAddSheet> {
  static const _noticeKey = 'hh_habit_rewards_explanation_hidden_v1';
  final _target = TextEditingController(text: '1');
  String _type = 'manual';
  String _unit = 'vasos';
  bool _showNotice = false;
  bool _hideNextTime = false;
  bool _expandedDetails = false;

  @override
  void initState() {
    super.initState();
    _loadNotice();
  }

  Future<void> _loadNotice() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _showNotice = !(prefs.getBool(_noticeKey) ?? false));
  }

  Future<void> _dismissNotice() async {
    if (_hideNextTime) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_noticeKey, true);
    }
    if (mounted) setState(() => _showNotice = false);
  }

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  bool get _timed => const ['stopwatch', 'timer', 'breathing', 'pomodoro']
      .contains(_type);

  bool get _valid {
    final target = int.tryParse(_target.text.trim());
    return _type == 'manual' ||
        (target != null && target >= 1 && target <= (_timed ? 1440 : 86400));
  }

  void _confirm() {
    if (!_valid) return;
    final target = _type == 'manual' ? 1 : int.parse(_target.text.trim());
    Navigator.of(context).pop(<String, dynamic>{
      'type': _type,
      'target': _timed ? target * 60 : target,
      'unit': _timed ? 'segundos'
          : _type == 'hydration' ? 'ml'
          : _type == 'steps' ? 'pasos'
          : _type == 'counter' ? _unit : 'vez',
    });
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final reduceMotion = !HealthyVisualEffects.enabled(context);
    final difficult = const ['difícil', 'dificil']
        .contains(habit.difficulty.trim().toLowerCase());
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .86,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: HealthyAdaptive.mint,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(Icons.spa_rounded,
                            color: HealthyAdaptive.accent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(habit.title,
                            style: TextStyle(fontSize: 21,
                              color: HealthyAdaptive.text,
                              fontWeight: FontWeight.w800)),
                          Text('${habit.category} · ${habit.difficulty}',
                            style: TextStyle(fontSize: 12,
                              color: HealthyAdaptive.muted)),
                        ],
                      )),
                      IconButton(
                        tooltip: 'Información de recompensas',
                        onPressed: () => setState(() => _showNotice = true),
                        icon: const Icon(Icons.info_outline_rounded),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _fact(Icons.flag_outlined, '${habit.target} sesiones'),
                      _fact(Icons.event_repeat_outlined,
                          habit.frequencyType == 'daily' ? 'Diario' : 'Semanal'),
                      _fact(Icons.calendar_month_outlined,
                          '${habit.durationPeriods} periodos'),
                    ]),
                    if (widget.cost > 0) ...[
                      const SizedBox(height: 14),
                      _noticeLine(Icons.paid_outlined,
                          'Costo de activación: ${widget.cost} Habit Coins'),
                    ],
                    if (difficult) ...[
                      const SizedBox(height: 8),
                      _noticeLine(Icons.warning_amber_rounded,
                          'Abandonarlo puede costar hasta 25 Habit Coins.'),
                    ],
                    const SizedBox(height: 14),
                    AnimatedSize(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 360),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: !_showNotice
                          ? const SizedBox(width: double.infinity)
                          : Container(
                              key: const ValueKey('habit-rewards-envelope'),
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: HealthyAdaptive.mint,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Icon(Icons.mark_email_read_outlined,
                                        color: HealthyAdaptive.accent),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text('Antes de comenzar…',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: HealthyAdaptive.text))),
                                  ]),
                                  const SizedBox(height: 7),
                                  Text(
                                    'Cada registro aporta al progreso, pero '
                                    'no garantiza completar el hábito ni '
                                    'recibir su recompensa final. '
                                    'Las recompensas dependen de las reglas '
                                    'del hábito y de la evidencia.',
                                    style: TextStyle(fontSize: 12,
                                      color: HealthyAdaptive.text),
                                  ),
                                  Material(
                                    color: HealthyAdaptive.mint,
                                    child: CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      controlAffinity: ListTileControlAffinity.leading,
                                      title: const Text('No volver a mostrar '
                                          'esta explicación',
                                          style: TextStyle(fontSize: 12)),
                                      value: _hideNextTime,
                                      onChanged: (value) => setState(
                                          () => _hideNextTime = value ?? false),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _dismissNotice,
                                      child: const Text('Entendido'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text('¿Cómo registrarás tu avance?',
                        style: TextStyle(color: HealthyAdaptive.text,
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      key: const ValueKey('habit-add-tool'),
                      value: _type,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Herramienta de registro',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'manual',
                            child: Text('Registro tradicional')),
                        DropdownMenuItem(value: 'counter',
                            child: Text('Contador manual')),
                        DropdownMenuItem(value: 'stopwatch',
                            child: Text('Cronómetro')),
                        DropdownMenuItem(value: 'timer',
                            child: Text('Temporizador')),
                        DropdownMenuItem(value: 'steps',
                            child: Text('Podómetro automático')),
                        DropdownMenuItem(value: 'breathing',
                            child: Text('Respiración guiada')),
                        DropdownMenuItem(value: 'pomodoro',
                            child: Text('Concentración (Pomodoro)')),
                        DropdownMenuItem(value: 'hydration',
                            child: Text('Medidor de hidratación')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _type = value;
                          _target.text = value == 'manual' ? '1'
                              : value == 'counter' ? '6'
                              : value == 'steps' ? '1000'
                              : value == 'hydration' ? '2000'
                              : value == 'pomodoro' ? '25' : '10';
                          _unit = 'vasos';
                        });
                      },
                    ),
                    if (_type != 'manual') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _target,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _timed
                            ? 'Minutos por sesión'
                            : _type == 'hydration' ? 'Mililitros'
                            : _type == 'steps' ? 'Pasos'
                            : 'Cantidad por sesión',
                          border: const OutlineInputBorder(),
                          helperText: _timed
                              ? 'Entre 1 y 1440 minutos'
                              : 'Entre 1 y 86400 unidades',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    if (_type == 'counter') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _unit,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Unidad',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'vasos', child: Text('Vasos')),
                          DropdownMenuItem(value: 'pasos',
                              child: Text('Pasos manuales')),
                          DropdownMenuItem(value: 'repeticiones',
                              child: Text('Repeticiones')),
                          DropdownMenuItem(value: 'unidades',
                              child: Text('Unidades')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _unit = v);
                        },
                      ),
                    ],
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () => setState(
                          () => _expandedDetails = !_expandedDetails),
                      icon: Icon(_expandedDetails
                          ? Icons.expand_less : Icons.expand_more),
                      label: Text(_expandedDetails
                          ? 'Ocultar detalles' : 'Ver detalles del hábito'),
                    ),
                    AnimatedSize(
                      duration: reduceMotion ? Duration.zero
                          : const Duration(milliseconds: 220),
                      child: !_expandedDetails
                          ? const SizedBox(width: double.infinity)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(habit.subtitle,
                                    style: TextStyle(
                                        color: HealthyAdaptive.muted)),
                                const SizedBox(height: 8),
                                Text('Recompensa indicada en catálogo: '
                                    '${habit.xp} XP',
                                    style: TextStyle(
                                        color: HealthyAdaptive.muted)),
                                const SizedBox(height: 6),
                                Text('La meta de la herramienta equivale '
                                    'a una sesión, no a completar el hábito.',
                                    style: TextStyle(fontSize: 12,
                                        color: HealthyAdaptive.muted)),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Row(children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton.icon(
                    key: const ValueKey('confirm-official-habit'),
                    onPressed: _valid ? _confirm : null,
                    icon: const Icon(Icons.add_task_rounded, size: 18),
                    label: const Text('Agregar hábito'),
                  )),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fact(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: HealthyAdaptive.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: HealthyAdaptive.accent),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(
            color: HealthyAdaptive.text, fontSize: 12)),
      ]),
    );
  }

  Widget _noticeLine(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 18, color: HealthyAdaptive.accent),
      const SizedBox(width: 8),
      Expanded(child: Text(text,
          style: TextStyle(color: HealthyAdaptive.text,
              fontWeight: FontWeight.w600, fontSize: 12))),
    ]);
  }
}
