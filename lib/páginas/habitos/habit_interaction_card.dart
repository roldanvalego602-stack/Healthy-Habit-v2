import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class HabitInteractionCard extends StatefulWidget {
  const HabitInteractionCard({super.key, required this.type, required this.target,
    required this.unit, required this.onChanged, this.enabled = true});
  final String type, unit;
  final int target;
  final bool enabled;
  final void Function(bool completed, int value) onChanged;
  @override
  State<HabitInteractionCard> createState() => _HabitInteractionCardState();
}

class _HabitInteractionCardState extends State<HabitInteractionCard> {
  final Stopwatch _watch = Stopwatch();
  Timer? _ticker;
  StreamSubscription<StepCount>? _stepsSubscription;
  int _count = 0, _seconds = 0;
  int? _stepBaseline;
  int _stepsBeforeResume = 0;
  bool _stepsStarted = false;
  String? _sensorError;

  bool get _timed => ['timer', 'stopwatch', 'breathing', 'pomodoro'].contains(widget.type);
  int get _target => widget.target.clamp(1, 86400);
  int get _value => _timed ? _seconds : _count;
  bool get _done => _value >= _target;
  void _notify() => widget.onChanged(_done, _value);

  void _tick(Timer timer) {
    if (!mounted || !widget.enabled) return;
    final value = _watch.elapsed.inSeconds.clamp(0, _target);
    if (value == _seconds) return;
    setState(() => _seconds = value);
    if (_done) {
      _watch.stop();
      _ticker?.cancel();
    }
    _notify();
  }

  void _toggle() {
    if (!widget.enabled || _done) return;
    if (_watch.isRunning) {
      _watch.stop();
      _ticker?.cancel();
    } else {
      _watch.start();
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(milliseconds: 200), _tick);
    }
    setState(() {});
  }

  void _add(int delta) {
    if (!widget.enabled) return;
    setState(() => _count = (_count + delta).clamp(0, _target));
    _notify();
  }

  Future<void> _startSteps() async {
    if (!widget.enabled || _stepsStarted || _done) return;
    setState(() => _sensorError = null);
    try {
      final permission = await Permission.activityRecognition.request();
      if (!mounted) return;
      if (!permission.isGranted) {
        setState(() => _sensorError = 'Permiso de actividad física denegado. Habilítalo en ajustes.');
        return;
      }
      _stepBaseline = null;
      _stepsBeforeResume = _count;
      await _stepsSubscription?.cancel();
      _stepsSubscription = Pedometer.stepCountStream.listen((event) {
        if (!mounted || !widget.enabled) return;
        _stepBaseline ??= event.steps;
        final steps = (_stepsBeforeResume + event.steps - _stepBaseline!).clamp(0, _target);
        if (steps != _count) {
          setState(() => _count = steps);
          _notify();
        }
        if (_done) {
          _stepsSubscription?.cancel();
          setState(() => _stepsStarted = false);
        }
      }, onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _stepsStarted = false;
          _sensorError = 'No se pudo leer el podómetro de este dispositivo.';
        });
      });
      if (mounted) setState(() => _stepsStarted = true);
    } catch (_) {
      if (mounted) setState(() => _sensorError = 'El podómetro no está disponible.');
    }
  }

  void _stopSteps() {
    _stepsSubscription?.cancel();
    setState(() => _stepsStarted = false);
  }

  @override
  void didUpdateWidget(covariant HabitInteractionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type || oldWidget.target != widget.target) {
      _ticker?.cancel();
      _watch.stop();
      _watch.reset();
      _stepsSubscription?.cancel();
      _seconds = 0;
      _count = 0;
      _stepBaseline = null;
      _stepsBeforeResume = 0;
      _stepsStarted = false;
      _sensorError = null;
    }
    if (!widget.enabled && oldWidget.enabled) {
      _watch.stop();
      _ticker?.cancel();
      _stepsSubscription?.cancel();
      _stepsStarted = false;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _watch.stop();
    _stepsSubscription?.cancel();
    super.dispose();
  }

  String _clock(int v) => '${(v ~/ 60).toString().padLeft(2, '0')}:${(v % 60).toString().padLeft(2, '0')}';

  String get _heading {
    switch (widget.type) {
      case 'steps': return 'Podómetro automático';
      case 'breathing': return 'Respiración guiada';
      case 'pomodoro': return 'Modo concentración';
      case 'hydration': return 'Medidor de hidratación';
      case 'timer': return 'Temporizador';
      case 'stopwatch': return 'Cronómetro';
      default: return 'Contador de actividad';
    }
  }

  String get _breathingPhase {
    final position = _seconds % 12;
    if (position < 4) return 'Inhala · 4 segundos';
    if (position < 6) return 'Mantén · 2 segundos';
    return 'Exhala · 6 segundos';
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF08B889), ink = Color(0xFF193344);
    final remaining = (_target - _seconds).clamp(0, _target);
    final display = widget.type == 'timer' || widget.type == 'pomodoro' ? remaining : _seconds;
    final icon = widget.type == 'steps' ? Icons.directions_walk_rounded :
      widget.type == 'hydration' ? Icons.water_drop_rounded :
      widget.type == 'breathing' ? Icons.air_rounded :
      widget.type == 'pomodoro' ? Icons.self_improvement_rounded :
      _timed ? Icons.timer_outlined : Icons.add_circle_outline_rounded;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFE2F7ED), borderRadius: BorderRadius.circular(26)),
      child: Column(children: [
        Row(children: [Icon(icon, color: green), const SizedBox(width: 8),
          Expanded(child: Text(_heading, style: const TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w900)))]),
        const SizedBox(height: 20),
        Stack(alignment: Alignment.center, children: [
          SizedBox(width: 176, height: 176, child: CircularProgressIndicator(
            value: (_value / _target).clamp(0.0, 1.0), strokeWidth: 12,
            backgroundColor: Colors.white, color: green)),
          Column(children: [
            Text(_timed ? _clock(display) : '$_count / $_target',
              style: const TextStyle(color: ink, fontSize: 30, fontWeight: FontWeight.w900)),
            Text(_timed ? 'Meta ${_clock(_target)}' : widget.unit,
              style: const TextStyle(color: Color(0xFF71879A))),
          ]),
        ]),
        const SizedBox(height: 16),
        if (widget.type == 'breathing' && !_done)
          Text(_breathingPhase, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
        if (widget.type == 'steps') ...[
          const Text('Cuenta los pasos nuevos desde que inicias la medición. No representa el total diario.',
            textAlign: TextAlign.center),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: widget.enabled && !_done ? (_stepsStarted ? _stopSteps : _startSteps) : null,
            icon: Icon(_stepsStarted ? Icons.stop : Icons.directions_walk),
            label: Text(_done ? 'Objetivo alcanzado' : _stepsStarted ? 'Detener medición' : 'Iniciar medición'),
            style: FilledButton.styleFrom(backgroundColor: green))),
          if (_sensorError != null) Padding(padding: const EdgeInsets.only(top: 8),
            child: Text(_sensorError!, style: const TextStyle(color: Colors.red))),
        ] else if (_timed) ...[
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: widget.enabled && !_done ? _toggle : null,
            icon: Icon(_watch.isRunning ? Icons.pause : Icons.play_arrow),
            label: Text(_done ? 'Objetivo alcanzado' : _watch.isRunning ? 'Pausar' : _seconds == 0 ? 'Iniciar' : 'Reanudar'),
            style: FilledButton.styleFrom(backgroundColor: green))),
          if (widget.type == 'pomodoro' && _done)
            const Padding(padding: EdgeInsets.only(top: 8),
              child: Text('Bloque de concentración terminado. Puedes descansar 5 minutos después de guardar.')),
        ] else if (widget.type == 'hydration') ...[
          Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
            for (final ml in [100, 250, 500]) OutlinedButton(
              onPressed: widget.enabled && !_done ? () => _add(ml) : null,
              child: Text('+$ml ml')),
            IconButton.outlined(onPressed: widget.enabled && _count > 0 ? () => _add(-100) : null,
              icon: const Icon(Icons.undo), tooltip: 'Restar 100 ml'),
          ]),
        ] else ...[
          Row(children: [
            IconButton.filledTonal(onPressed: widget.enabled && _count > 0 ? () => _add(-1) : null,
              icon: const Icon(Icons.remove)),
            const SizedBox(width: 12),
            Expanded(child: FilledButton.icon(
              onPressed: widget.enabled && !_done ? () => _add(1) : null,
              icon: const Icon(Icons.add),
              label: Text(_done ? 'Objetivo alcanzado' : 'Registrar ${widget.unit}'),
              style: FilledButton.styleFrom(backgroundColor: green))),
          ]),
        ],
        const SizedBox(height: 12),
        Text(_done ? '¡Actividad lista! Guarda tu registro.' : 'Completa la actividad para guardar.',
          textAlign: TextAlign.center, style: const TextStyle(color: ink)),
      ]),
    );
  }
}
