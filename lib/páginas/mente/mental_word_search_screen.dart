import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../tema/healthy_theme.dart';
import 'mental_progress_service.dart';
import 'mental_puzzles.dart';

/// Sopa de letras completa sin fotografías, vigilancia ni recompensas
/// de Firebase. Tocar el inicio y el final de una palabra la selecciona.
class MentalWordSearchScreen extends StatefulWidget {
  const MentalWordSearchScreen({super.key});

  @override
  State<MentalWordSearchScreen> createState() => _MentalWordSearchScreenState();
}

class _MentalWordSearchScreenState extends State<MentalWordSearchScreen> {
  final _progress = const MentalProgressService();
  late final DateTime _day;
  late final MentalWordSearchPuzzle _puzzle;
  Set<String> _found = {};
  int? _start;
  int? _hintCell;
  int _hints = 0;
  bool _completed = false;
  bool _loading = true;
  String _feedback = 'Toca la primera y la última letra '
      'de una palabra, en línea recta. Puedes seleccionar al revés.';

  @override
  void initState() {
    super.initState();
    _day = DateTime.now();
    _puzzle = MentalWordSearchPuzzle.forDate(_day);
    _load();
  }

  Future<void> _load() async {
    final saved = await _progress.foundWords(_day);
    final today = await _progress.progress(_day);
    if (!mounted) return;
    setState(() {
      _found = saved.intersection(_puzzle.words.toSet());
      if (today.wordSearch) {
        _found = _puzzle.words.toSet();
      }
      _completed = today.wordSearch ||
          _found.length == _puzzle.words.length;
      _loading = false;
    });
  }

  Future<void> _select(int index) async {
    if (_loading || _completed) return;
    if (_start == null) {
      setState(() {
        _start = index;
        _hintCell = null;
        _feedback = 'Ahora selecciona la última letra '
            'de la palabra en cualquier dirección.';
      });
      return;
    }
    final first = _start!;
    if (first == index) {
      setState(() {
        _start = null;
        _feedback = 'Selección cancelada. Elige una nueva letra.';
      });
      return;
    }
    final word = _puzzle.wordBetween(first, index);
    if (word == null || _found.contains(word)) {
      setState(() {
        _start = index;
        _feedback = 'No coincide con las palabras restantes. '
            'Esta letra será el nuevo punto de partida.';
      });
      return;
    }
    HapticFeedback.selectionClick();
    final found = {..._found, word};
    setState(() {
      _found = found;
      _start = null;
      _hintCell = null;
      _feedback = 'Encontraste ${word.toLowerCase()} · '
          '${found.length}/${_puzzle.words.length} palabras.';
    });
    await _progress.saveFoundWords(_day, found);
    if (found.length == _puzzle.words.length) {
      await _progress.complete(_day, 'sopa');
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _completed = true;
        _feedback = '¡Todas las palabras encontradas! '
            'Completaste la sopa de letras de hoy.';
      });
    }
  }

  void _hint() {
    if (_loading || _completed || _hints >= 3) return;
    final word = _puzzle.words.firstWhere(
      (word) => !_found.contains(word),
    );
    final start = _puzzle.wordPaths[word]!.first;
    setState(() {
      _hintCell = start;
      _start = null;
      _hints++;
      _feedback = 'Pista $_hints/3: la primera letra '
          'de «${word.toLowerCase()}» está resaltada. '
          'Busca su última letra.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = HealthyAdaptive.text;
    final muted = HealthyAdaptive.muted;
    final accent = HealthyAdaptive.accent;
    final marked = <int>{
      for (final word in _found)
        ...?_puzzle.wordPaths[word],
    };
    return Scaffold(
      backgroundColor: HealthyAdaptive.background,
      appBar: AppBar(title: const Text('Sopa de letras diaria')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.menu_book_rounded, size: 27,
                              color: accent),
                          const SizedBox(width: 9),
                          Expanded(child: Text('Palabras para pensar',
                            style: TextStyle(color: text,
                                fontWeight: FontWeight.w800,
                                fontSize: 18))),
                          if (_completed)
                            Icon(Icons.check_circle_rounded, color: accent),
                        ]),
                        const SizedBox(height: 8),
                        const Text('Encuentra siete palabras relacionadas '
                            'con la atención, el aprendizaje y la calma. '
                            'Selecciona la primera letra y luego la última.'),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _found.length / _puzzle.words.length,
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        const SizedBox(height: 7),
                        Text('${_found.length}/${_puzzle.words.length} '
                            'palabras · ${3 - _hints} pistas disponibles',
                          style: TextStyle(color: muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 470),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GridView.builder(
                        key: const ValueKey('mental-wordsearch-grid'),
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _puzzle.cells.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _puzzle.size,
                        ),
                        itemBuilder: (context, index) {
                          final selected = _start == index;
                          final isFound = marked.contains(index);
                          final highlighted = _hintCell == index;
                          return Semantics(
                            button: true,
                            label: 'Fila ${index ~/ _puzzle.size + 1}, '
                                'columna ${index % _puzzle.size + 1}, '
                                'letra ${_puzzle.cells[index]}',
                            child: InkWell(
                              key: ValueKey('mental-wordsearch-cell-$index'),
                              onTap: () => _select(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 130),
                                margin: const EdgeInsets.all(.8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: selected || highlighted
                                      ? accent.withValues(alpha: .4)
                                      : isFound
                                          ? accent.withValues(alpha: .24)
                                          : HealthyAdaptive.surface,
                                  border: Border.all(
                                    color: selected || highlighted
                                        ? accent : HealthyAdaptive.border,
                                    width: selected || highlighted ? 1.6 : .4,
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(_puzzle.cells[index],
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isFound || selected
                                          ? FontWeight.w900
                                          : FontWeight.w600,
                                      color: isFound || selected || highlighted
                                          ? accent : text,
                                    )),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8, runSpacing: 8,
                  children: [
                    for (final word in _puzzle.words)
                      AnimatedContainer(
                        key: ValueKey('mental-wordsearch-word-$word'),
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: _found.contains(word)
                              ? accent.withValues(alpha: .2)
                              : HealthyAdaptive.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: _found.contains(word)
                                  ? accent : HealthyAdaptive.border),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (_found.contains(word)) ...[
                            Icon(Icons.check_rounded, size: 15, color: accent),
                            const SizedBox(width: 4),
                          ],
                          Text(word,
                            style: TextStyle(
                              fontSize: 12,
                              color: _found.contains(word) ? accent : text,
                              fontWeight: FontWeight.w700,
                              decoration: _found.contains(word)
                                  ? TextDecoration.lineThrough : null,
                            )),
                        ]),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  key: const ValueKey('mental-wordsearch-hint'),
                  onPressed: _completed || _hints >= 3 ? null : _hint,
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                  label: Text('Mostrar primera letra '
                      '(${3 - _hints} pistas)'),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(_feedback, style: TextStyle(
                      color: _completed ? accent : text,
                      fontSize: 13,
                    )),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Progreso guardado localmente por cuenta y día. '
                    'Esta actividad no modifica XP ni Habit Coins.',
                  style: TextStyle(color: muted, fontSize: 11)),
              ],
            ),
    );
  }
}
