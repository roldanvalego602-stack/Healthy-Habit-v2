import 'dart:async';
import 'package:flutter/material.dart';
import '../../tema/healthy_theme.dart';

/// Ayudas breves compartidas por las herramientas de hábitos.
class HabitToolGuide {
  static String titleFor(String type, String unit) {
    if (type == 'timer') return 'Temporizador';
    if (type == 'stopwatch') return 'Cronómetro';
    return unit.trim().toLowerCase() == 'ml'
        ? 'Contador de hidratación'
        : 'Contador de actividad';
  }

  static String instructionsFor(String type, String unit) {
    if (type == 'timer') {
      return 'Pulsa Iniciar para comenzar la cuenta regresiva. '
          'Puedes pausar y reanudar. Al llegar a cero, continúa con el siguiente paso.';
    }
    if (type == 'stopwatch') {
      return 'Pulsa Iniciar para medir el tiempo transcurrido. '
          'Pausa o reanuda hasta alcanzar la duración objetivo.';
    }
    if (unit.trim().toLowerCase() == 'ml') {
      return 'Registra cada cantidad de agua con +100, +250 o +500 ml. '
          'Usa Corregir −100 ml para ajustar el registro.';
    }
    return 'Pulsa Registrar cada vez que completes una unidad. '
        'Utiliza el botón menos si necesitas corregir el contador.';
  }
}

class HabitInteractionCard extends StatefulWidget {
  const HabitInteractionCard({super.key, required this.type, required this.target,
    required this.unit, required this.onChanged, this.enabled = true,
    this.initialValue = 0});
  final String type, unit;
  final int target;
  final int initialValue;
  final bool enabled;
  final void Function(bool completed, int value) onChanged;
  @override
  State<HabitInteractionCard> createState() => _HabitInteractionCardState();
}

class _HabitInteractionCardState extends State<HabitInteractionCard> {
  final Stopwatch _watch = Stopwatch();
  Timer? _ticker;
  int _count = 0, _seconds = 0;
  int _baseSeconds = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue.clamp(0, widget.target);
    _count = initial;
    _seconds = initial;
    _baseSeconds = initial;
  }
  bool get _timed => widget.type == 'timer' || widget.type == 'stopwatch';
  bool get _water => !_timed && widget.unit.trim().toLowerCase() == 'ml';
  int get _target => widget.target.clamp(1, 86400);
  int get _value => _timed ? _seconds : _count;
  bool get _done => _value >= _target;

  void _notify() => widget.onChanged(_done, _value);
  void _tick(Timer timer) {
    if (!mounted) return;
    final value = _baseSeconds + _watch.elapsed.inSeconds;
    if (value == _seconds) return;
    setState(() => _seconds = value);
    if (_done) { _watch.stop(); _ticker?.cancel(); }
    _notify();
  }
  void _toggle() {
    if (!widget.enabled || _done) return;
    if (_watch.isRunning) { _watch.stop(); _ticker?.cancel(); }
    else { _watch.start(); _ticker = Timer.periodic(const Duration(milliseconds: 200), _tick); }
    setState(() {});
  }
  void _add(int delta) {
    if (!widget.enabled) return;
    setState(() => _count = (_count + delta).clamp(0, _target));
    _notify();
  }
  @override
  void dispose() { _ticker?.cancel(); _watch.stop(); super.dispose(); }
  String _clock(int v) => '${(v ~/ 60).toString().padLeft(2, '0')}:${(v % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final green = HealthyAdaptive.accent, ink = HealthyAdaptive.text;
    final display = widget.type == 'timer' ? (_target - _seconds).clamp(0, _target) : _seconds;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: HealthyAdaptive.mint, borderRadius: BorderRadius.circular(26)),
      child: Column(children: [
        Row(children: [Icon(_timed ? Icons.timer_outlined : Icons.water_drop_outlined, color: green),
          const SizedBox(width: 8), Text(_timed ? 'Tiempo de actividad' : 'Contador de actividad',
            style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w900))]),
        const SizedBox(height: 20),
        Stack(alignment: Alignment.center, children: [
          SizedBox(width: 176, height: 176, child: CircularProgressIndicator(
            value: (_value / _target).clamp(0.0, 1.0), strokeWidth: 12,
            backgroundColor: HealthyAdaptive.surface, color: green)),
          Column(children: [
            Text(_timed ? _clock(display) : '$_count / $_target',
              style: TextStyle(color: ink, fontSize: 34, fontWeight: FontWeight.w900)),
            Text(_timed ? 'Meta ${_clock(_target)}' : widget.unit,
              style: TextStyle(color: HealthyAdaptive.muted)),
          ]),
        ]),
        const SizedBox(height: 20),
        if (_timed) SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: widget.enabled && !_done ? _toggle : null,
          icon: Icon(_watch.isRunning ? Icons.pause : Icons.play_arrow),
          label: Text(_done ? 'Objetivo alcanzado' : _watch.isRunning ? 'Pausar' : _seconds == 0 ? 'Iniciar' : 'Reanudar'),
          style: FilledButton.styleFrom(backgroundColor: green))),
        if (!_timed && !_water) Row(children: [
          IconButton.filledTonal(onPressed: widget.enabled && _count > 0 ? () => _add(-1) : null,
            icon: const Icon(Icons.remove)),
          const SizedBox(width: 12),
          Expanded(child: FilledButton.icon(
            onPressed: widget.enabled && !_done ? () => _add(1) : null,
            icon: const Icon(Icons.add),
            label: Text(_done ? 'Objetivo alcanzado' : 'Registrar ${widget.unit}'),
            style: FilledButton.styleFrom(backgroundColor: green))),
        ]),
        if (_water) Column(children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final amount in const [100, 250, 500])
                FilledButton.tonal(
                  onPressed: widget.enabled && !_done
                      ? () => _add(amount)
                      : null,
                  child: Text('+$amount ml'),
                ),
            ],
          ),
          TextButton.icon(
            onPressed: widget.enabled && _count > 0
                ? () => _add(-100)
                : null,
            icon: const Icon(Icons.undo_rounded),
            label: const Text('Corregir −100 ml'),
          ),
        ]),
        const SizedBox(height: 12),
        ExpansionTile(
          key: const ValueKey('habit-tool-instructions'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Icon(Icons.help_outline_rounded, color: green),
          title: Text(
            'Cómo usar esta herramienta',
            style: TextStyle(color: ink, fontWeight: FontWeight.w700),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                HabitToolGuide.instructionsFor(widget.type, widget.unit),
                style: TextStyle(color: ink, height: 1.45),
              ),
            ),
          ],
        ),
        Text(_done ? '¡Actividad lista! Guarda tu registro.' : 'Completa la actividad para guardar.',
          textAlign: TextAlign.center, style: TextStyle(color: ink)),
      ]),
    );
  }
}
