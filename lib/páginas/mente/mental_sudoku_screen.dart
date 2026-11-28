import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../tema/healthy_theme.dart';
import 'mental_progress_service.dart';
import 'mental_puzzles.dart';

/// Sudoku completo, local, accesible y sin recompensas económicas.
class MentalSudokuScreen extends StatefulWidget {
  const MentalSudokuScreen({super.key});

  @override
  State<MentalSudokuScreen> createState() => _MentalSudokuScreenState();
}

class _MentalSudokuScreenState extends State<MentalSudokuScreen> {
  final _progress = const MentalProgressService();
  late final DateTime _day;
  late final SudokuPuzzle _puzzle;
  late List<int> _cells;
  int? _selected;
  int _mistakes = 0;
  int _hintsUsed = 0;
  bool _completed = false;
  bool _loading = true;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _day = DateTime.now();
    _puzzle = SudokuPuzzle.forDate(_day);
    _cells = List<int>.from(_puzzle.givens);
    _load();
  }

  Future<void> _load() async {
    final saved = await _progress.sudokuCells(_day);
    final today = await _progress.progress(_day);
    if (!mounted) return;
    if (today.sudoku) {
      _cells = List<int>.from(_puzzle.solution);
    } else if (saved != null &&
        List.generate(81, (i) => i).every((i) =>
            saved[i] == 0 || saved[i] == _puzzle.solution[i]) &&
        List.generate(81, (i) => i).every((i) =>
            _puzzle.givens[i] == 0 || saved[i] == _puzzle.givens[i])) {
      _cells = saved;
    }
    setState(() {
      _completed = today.sudoku;
      _loading = false;
    });
  }

  Future<void> _place(int digit) async {
    final index = _selected;
    if (_completed || _loading || index == null ||
        _puzzle.isGiven(index)) return;
    if (digit == 0) {
      setState(() {
        _cells[index] = 0;
        _notice = null;
      });
      await _progress.saveSudoku(_day, _cells);
      return;
    }
    if (!_puzzle.isCorrect(index, digit)) {
      HapticFeedback.selectionClick();
      setState(() {
        _mistakes++;
        _notice = 'Esa cifra todavía no encaja. '
            'Observa la fila, la columna y el cuadro 3×3.';
      });
      return;
    }
    setState(() {
      _cells[index] = digit;
      _notice = null;
    });
    await _progress.saveSudoku(_day, _cells);
    if (_puzzle.isSolved(_cells)) await _finish();
  }

  Future<void> _hint() async {
    if (_loading || _completed || _hintsUsed >= 3) return;
    var index = _selected;
    if (index == null || _cells[index] != 0) {
      index = _cells.indexOf(0);
    }
    if (index < 0) return;
    setState(() {
      _selected = index;
      _cells[index!] = _puzzle.solution[index];
      _hintsUsed++;
      _notice = 'Pista ${_hintsUsed}/3: observa cómo '
          'esta cifra se relaciona con su fila y cuadro.';
    });
    await _progress.saveSudoku(_day, _cells);
    if (_puzzle.isSolved(_cells)) await _finish();
  }

  Future<void> _finish() async {
    if (_completed) return;
    await _progress.complete(_day, 'sudoku');
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _completed = true;
      _notice = '¡Sudoku completado! Has terminado el reto mental de hoy.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = HealthyAdaptive.text;
    final accent = HealthyAdaptive.accent;
    final muted = HealthyAdaptive.muted;
    final filled = _cells.where((value) => value != 0).length;
    return Scaffold(
      backgroundColor: HealthyAdaptive.background,
      appBar: AppBar(title: const Text('Sudoku diario')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.grid_on_rounded,
                              color: accent, size: 29),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Desafío de lógica',
                                style: TextStyle(color: text,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18)),
                              Text('Un tablero distinto cada día',
                                style: TextStyle(color: muted, fontSize: 12)),
                            ],
                          )),
                          if (_completed)
                            Icon(Icons.check_circle, color: accent),
                        ]),
                        const SizedBox(height: 12),
                        const Text('Completa filas, columnas y cuadros '
                            'de 3×3 con los números del 1 al 9, '
                            'sin repetir. Toca una casilla y después '
                            'elige un número.'),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(value: filled / 81,
                            minHeight: 7, borderRadius:
                                BorderRadius.circular(99)),
                        const SizedBox(height: 8),
                        Text('$filled/81 casillas · '
                            '$_mistakes intentos incorrectos · '
                            '${3 - _hintsUsed} pistas',
                          style: TextStyle(color: muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GridView.builder(
                        key: const ValueKey('mental-sudoku-grid'),
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 9),
                        itemCount: 81,
                        itemBuilder: (context, index) {
                          final row = index ~/ 9;
                          final col = index % 9;
                          final given = _puzzle.isGiven(index);
                          final selected = _selected == index;
                          final related = _selected != null &&
                              (row == _selected! ~/ 9 ||
                               col == _selected! % 9 ||
                               (row ~/ 3 == _selected! ~/ 27 &&
                                col ~/ 3 == (_selected! % 9) ~/ 3));
                          final digit = _cells[index];
                          final border = HealthyAdaptive.border;
                          return Semantics(
                            button: !given,
                            label: 'Fila ${row+1}, columna ${col+1}, '
                                '${digit == 0 ? 'vacía' : digit}, '
                                '${given ? 'pista fija' : 'editable'}',
                            child: InkWell(
                              key: ValueKey('mental-sudoku-cell-$index'),
                              onTap: () => setState(() => _selected = index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? accent.withValues(alpha: .28)
                                      : related
                                          ? accent.withValues(alpha: .09)
                                          : HealthyAdaptive.surface,
                                  border: Border(
                                    left: BorderSide(
                                      color: border,
                                      width: col % 3 == 0 ? 2 : .35,
                                    ),
                                    top: BorderSide(
                                      color: border,
                                      width: row % 3 == 0 ? 2 : .35,
                                    ),
                                    right: BorderSide(
                                      color: border,
                                      width: col == 8 ? 2 : .35,
                                    ),
                                    bottom: BorderSide(
                                      color: border,
                                      width: row == 8 ? 2 : .35,
                                    ),
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Text(
                                      digit == 0 ? '' : digit.toString(),
                                      style: TextStyle(
                                        color: given ? text : accent,
                                        fontSize: 22,
                                        fontWeight: given
                                            ? FontWeight.w900
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(builder: (context, constraints) {
                  final size = (constraints.maxWidth - 8 * 4) / 9;
                  return Wrap(
                    spacing: 4, runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var digit = 1; digit <= 9; digit++)
                        SizedBox(
                          width: size, height: 46,
                          child: FilledButton(
                            key: ValueKey('mental-sudoku-digit-$digit'),
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: HealthyAdaptive.surface,
                              foregroundColor: text,
                            ),
                            onPressed: _completed ? null
                                : () => _place(digit),
                            child: Text('$digit',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: _completed ? null : () => _place(0),
                    icon: const Icon(Icons.backspace_outlined),
                    label: const Text('Borrar'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(
                    key: const ValueKey('mental-sudoku-hint'),
                    onPressed: _completed || _hintsUsed >= 3 ? null : _hint,
                    icon: const Icon(Icons.lightbulb_outline_rounded),
                    label: const Text('Pista'),
                  )),
                ]),
                if (_notice != null) ...[
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Card(
                      key: ValueKey(_notice),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(_notice!,
                            style: TextStyle(
                              color: _completed ? accent : text)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text('Progreso guardado solo en este dispositivo. '
                    'Completar Sudoku cuenta para tu rutina mental local; '
                    'no modifica XP ni Habit Coins.',
                  style: TextStyle(color: muted, fontSize: 11)),
              ],
            ),
    );
  }
}
