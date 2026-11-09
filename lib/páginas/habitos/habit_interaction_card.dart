import 'dart:async';
import 'package:flutter/material.dart';

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
  int _count = 0, _seconds = 0;
  bool get _timed => widget.type == 'timer' || widget.type == 'stopwatch';
  int get _target => widget.target.clamp(1, 86400);
  int get _value => _timed ? _seconds : _count;
  bool get _done => _value >= _target;

  void _notify() => widget.onChanged(_done, _value);
  void _tick(Timer timer) {
    if (!mounted) return;
    final value = _watch.elapsed.inSeconds;
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
    const green = Color(0xFF08B889), ink = Color(0xFF193344);
    final display = widget.type == 'timer' ? (_target - _seconds).clamp(0, _target) : _seconds;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFE2F7ED), borderRadius: BorderRadius.circular(26)),
      child: Column(children: [
        Row(children: [Icon(_timed ? Icons.timer_outlined : Icons.water_drop_outlined, color: green),
          const SizedBox(width: 8), Text(_timed ? 'Tiempo de actividad' : 'Contador de actividad',
            style: const TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w900))]),
        const SizedBox(height: 20),
        Stack(alignment: Alignment.center, children: [
          SizedBox(width: 176, height: 176, child: CircularProgressIndicator(
            value: (_value / _target).clamp(0.0, 1.0), strokeWidth: 12,
            backgroundColor: Colors.white, color: green)),
          Column(children: [
            Text(_timed ? _clock(display) : '$_count / $_target',
              style: const TextStyle(color: ink, fontSize: 34, fontWeight: FontWeight.w900)),
            Text(_timed ? 'Meta ${_clock(_target)}' : widget.unit,
              style: const TextStyle(color: Color(0xFF71879A))),
          ]),
        ]),
        const SizedBox(height: 20),
        if (_timed) SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: widget.enabled && !_done ? _toggle : null,
          icon: Icon(_watch.isRunning ? Icons.pause : Icons.play_arrow),
          label: Text(_done ? 'Objetivo alcanzado' : _watch.isRunning ? 'Pausar' : _seconds == 0 ? 'Iniciar' : 'Reanudar'),
          style: FilledButton.styleFrom(backgroundColor: green))),
        if (!_timed) Row(children: [
          IconButton.filledTonal(onPressed: widget.enabled && _count > 0 ? () => _add(-1) : null,
            icon: const Icon(Icons.remove)),
          const SizedBox(width: 12),
          Expanded(child: FilledButton.icon(
            onPressed: widget.enabled && !_done ? () => _add(1) : null,
            icon: const Icon(Icons.add),
            label: Text(_done ? 'Objetivo alcanzado' : 'Registrar ${widget.unit}'),
            style: FilledButton.styleFrom(backgroundColor: green))),
        ]),
        const SizedBox(height: 12),
        Text(_done ? '¡Actividad lista! Guarda tu registro.' : 'Completa la actividad para guardar.',
          textAlign: TextAlign.center, style: const TextStyle(color: ink)),
      ]),
    );
  }
}
