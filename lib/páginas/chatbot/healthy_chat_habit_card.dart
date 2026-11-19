import 'package:flutter/material.dart';

import '../../tema/healthy_theme.dart';
import '../../tema/healthy_visual_mode.dart';
import '../habitos/habit_action_service.dart';

/// Tarjeta de operación real dentro del chat; nunca ejecuta sin confirmación.
class HealthyChatHabitCard extends StatefulWidget {
  const HealthyChatHabitCard({
    super.key,
    required this.habitTitle,
    required this.remove,
    required this.onCompleted,
  });

  final String habitTitle;
  final bool remove;
  final ValueChanged<HabitActionResult> onCompleted;

  @override
  State<HealthyChatHabitCard> createState() => _HealthyChatHabitCardState();
}

class _HealthyChatHabitCardState extends State<HealthyChatHabitCard> {
  final HabitActionService _service = const HabitActionService();
  late Future<HabitActionPreview> _preview;
  bool _working = false;
  HabitActionResult? _done;

  @override
  void initState() {
    super.initState();
    _preview = _service.preview(widget.habitTitle, remove: widget.remove);
  }

  @override
  void didUpdateWidget(covariant HealthyChatHabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.habitTitle != widget.habitTitle ||
        oldWidget.remove != widget.remove) {
      _done = null;
      _preview = _service.preview(widget.habitTitle, remove: widget.remove);
    }
  }

  void _retry() {
    setState(() {
      _done = null;
      _preview = _service.preview(widget.habitTitle, remove: widget.remove);
    });
  }

  Future<void> _confirm(HabitActionPreview preview) async {
    if (_working || _done != null) return;
    final verb = preview.remove ? 'Abandonar hábito' : 'Agregar hábito';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('¿$verb?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(preview.habit.title,
              style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 9),
            Text('Dificultad: ${preview.habit.difficulty}'),
            if (!preview.remove) ...[
              Text('Meta: ${preview.habit.target} registros'),
              Text('Recompensa por registro: hasta ${preview.habit.xp} XP '
                'según las reglas del hábito'),
              Text('Espacios ocupados: ${preview.activeCount}/${preview.slots}'),
              Text('Costo de activación: ${preview.estimatedCost} Habit Coins'),
            ] else ...[
              Text('Penalización estimada: ${preview.estimatedCost} Habit Coins'),
              const Text('El progreso y el XP obtenido permanecerán en tu historial.'),
            ],
            if (!preview.remove &&
                HabitActionService.isDifficult(preview.habit))
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Si después abandonas este hábito difícil, '
                  'puede aplicarse una penalización de hasta 25 Habit Coins.'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('mr-healthy-confirm-habit'),
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: preview.remove
                  ? const Color(0xFFAD4B4B)
                  : const Color(0xFF148C68),
              foregroundColor: Colors.white,
            ),
            child: Text(preview.remove ? 'Sí, abandonar' : 'Sí, agregar'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;

    setState(() => _working = true);
    try {
      final result = await _service.execute(preview);
      if (!mounted) return;
      setState(() => _done = result);
      widget.onCompleted(result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No se realizó la operación: $error'),
      ));
      _retry(); // Recalcula saldo, cupos y penalización.
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final motion = HealthyVisualEffects.enabled(context);
    final color = widget.remove
        ? const Color(0xFFE47F74)
        : HealthyAdaptive.accent;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: motion ? 0.0 : 1.0, end: 1.0),
      duration: HealthyVisualEffects.duration(
        context, const Duration(milliseconds: 420)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 10),
          child: child,
        ),
      ),
      child: Container(
        key: const Key('mr-healthy-habit-action'),
        margin: const EdgeInsets.only(top: 11),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: HealthyAdaptive.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HealthyAdaptive.border),
        ),
        child: AnimatedSwitcher(
          duration: HealthyVisualEffects.duration(
            context, const Duration(milliseconds: 250)),
          child: _done != null
              ? _success(_done!, color)
              : FutureBuilder<HabitActionPreview>(
                  future: _preview,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done ||
                        _working) {
                      return const Row(
                        key: ValueKey('mr-healthy-habit-loading'),
                        children: [
                          SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 10),
                          Expanded(child: Text('Verificando hábitos y saldo…')),
                        ],
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Column(
                        key: const ValueKey('mr-healthy-habit-error'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${snapshot.error ?? 'No hay datos disponibles.'}',
                            style: TextStyle(
                              color: HealthyAdaptive.text, fontSize: 12)),
                          TextButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Volver a revisar'),
                          ),
                        ],
                      );
                    }
                    final preview = snapshot.data!;
                    return Column(
                      key: const ValueKey('mr-healthy-habit-ready'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(widget.remove
                              ? Icons.remove_circle_outline_rounded
                              : Icons.add_task_rounded, color: color),
                          const SizedBox(width: 8),
                          Expanded(child: Text(preview.habit.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: HealthyAdaptive.text),
                            maxLines: 2, overflow: TextOverflow.ellipsis)),
                        ]),
                        const SizedBox(height: 6),
                        Text(widget.remove
                            ? 'Penalización estimada: ${preview.estimatedCost} Habit Coins'
                            : '${preview.habit.difficulty} · ${preview.habit.target} registros'
                              ' · ${preview.estimatedCost} Habit Coins',
                          style: TextStyle(
                            color: HealthyAdaptive.muted, fontSize: 11)),
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity,
                          child: FilledButton.icon(
                            key: const Key('mr-healthy-habit-review'),
                            onPressed: () => _confirm(preview),
                            icon: Icon(widget.remove
                                ? Icons.remove_circle_outline_rounded
                                : Icons.check_circle_outline_rounded),
                            label: Text(widget.remove
                                ? 'Revisar abandono'
                                : 'Revisar y agregar'),
                          )),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _success(HabitActionResult result, Color color) {
    return Column(
      key: const ValueKey('mr-healthy-habit-success'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_rounded, color: color, size: 34),
        const SizedBox(height: 5),
        Text(result.removed ? 'Hábito abandonado'
            : '¡Hábito agregado!',
          style: TextStyle(
            color: HealthyAdaptive.text,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          )),
        const SizedBox(height: 4),
        Text(result.removed
            ? 'Se descontaron ${result.chargedCoins} Habit Coins.'
            : 'Tu nuevo hábito ya está activo.',
          style: TextStyle(
            color: HealthyAdaptive.muted, fontSize: 12)),
      ],
    );
  }
}
