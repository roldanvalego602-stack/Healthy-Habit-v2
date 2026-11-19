import 'package:flutter/material.dart';
import '../../tema/healthy_theme.dart';
import '../../tema/healthy_visual_mode.dart';
import '../habitos/habit_action_service.dart';
import '../habitos/catalogo.dart';
import '../habitos/modelo/habit.dart';

/// Selector dentro de la conversación. Solo selecciona, nunca escribe datos.
class HealthyChatHabitPicker extends StatefulWidget {
  const HealthyChatHabitPicker({
    super.key,
    required this.remove,
    required this.onSelected,
  });
  final bool remove;
  final ValueChanged<Habit> onSelected;

  @override
  State<HealthyChatHabitPicker> createState() => _HealthyChatHabitPickerState();
}

class _HealthyChatHabitPickerState extends State<HealthyChatHabitPicker> {
  final _search = TextEditingController();
  final _service = const HabitActionService();
  late Future<List<Habit>> _items;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _items = widget.remove
        ? _service.listActiveCatalogHabits()
        : Future.value(habitCatalog.map((h) =>
            Habit.fromMap(Map<String, dynamic>.from(h), h['id'] as String))
            .toList());
    _search.addListener(_update);
  }

  void _update() {
    if (mounted) {
      setState(() => _query = _search.text.toLowerCase().trim());
    }
  }

  @override
  void dispose() {
    _search.removeListener(_update);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = HealthyVisualEffects.enabled(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.72;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: SizedBox(
          height: (sheetHeight - keyboard).clamp(220.0, sheetHeight).toDouble(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.remove
                          ? '¿Cuál hábito deseas abandonar?'
                          : 'Elige un hábito para comenzar',
                      style: TextStyle(
                        color: HealthyAdaptive.text,
                        fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text(widget.remove
                          ? 'Solo se muestran hábitos oficiales con un intento activo.'
                          : 'Revisaremos los requisitos antes de activarlo.',
                      style: TextStyle(
                        color: HealthyAdaptive.muted, fontSize: 12)),
                    const SizedBox(height: 13),
                    TextField(
                      controller: _search,
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: 'Buscar hábito…',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: HealthyAdaptive.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: FutureBuilder<List<Habit>>(
                future: _items,
                builder: (context, snapshot) {
                  if (!snapshot.hasData && !snapshot.hasError) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text('No pude cargar tus hábitos activos. '
                          'Revisa la conexión y vuelve a intentarlo.',
                        textAlign: TextAlign.center)));
                  }
                  final visible = snapshot.data!.where((habit) =>
                    _query.isEmpty ||
                    habit.title.toLowerCase().contains(_query) ||
                    habit.category.toLowerCase().contains(_query)).toList();
                  if (visible.isEmpty) {
                    return Center(child: Text(
                      widget.remove
                          ? 'No hay hábitos oficiales activos con ese nombre.'
                          : 'No encontré hábitos con ese nombre.',
                      textAlign: TextAlign.center));
                  }
                  return AnimatedSwitcher(
                    duration: HealthyVisualEffects.duration(
                      context, const Duration(milliseconds: 180)),
                    child: ListView.separated(
                      key: ValueKey('${widget.remove}-$_query'),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 7),
                      itemBuilder: (context, i) {
                        final habit = visible[i];
                        return Material(
                          color: HealthyAdaptive.background,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            key: ValueKey('mr-healthy-picker-${habit.id}'),
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onSelected(habit);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 11, horizontal: 13),
                              child: Row(children: [
                                Icon(widget.remove
                                      ? Icons.remove_circle_outline_rounded
                                      : Icons.add_task_rounded,
                                  color: HealthyAdaptive.accent),
                                const SizedBox(width: 10),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(habit.title,
                                      style: TextStyle(
                                        color: HealthyAdaptive.text,
                                        fontWeight: FontWeight.w800)),
                                    Text('${habit.category} · ${habit.difficulty}',
                                      style: TextStyle(
                                        color: HealthyAdaptive.muted,
                                        fontSize: 11)),
                                  ],
                                )),
                                Icon(Icons.chevron_right_rounded,
                                  color: HealthyAdaptive.muted),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              )),
              if (motion)
                const SizedBox(height: 1),
            ],
          ),
        ),
      ),
    );
  }
}
