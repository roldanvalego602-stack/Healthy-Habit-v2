import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mental_puzzles.dart';

/// El entrenamiento mental es un hábito LOCAL en esta fase.
/// No modificar Firestore, XP ni Habit Coins desde resultados del cliente.
class MentalDailyProgress {
  const MentalDailyProgress({
    required this.sudoku,
    required this.wordSearch,
    required this.streak,
  });

  final bool sudoku;
  final bool wordSearch;
  final int streak;
  int get completed => (sudoku ? 1 : 0) + (wordSearch ? 1 : 0);
}

class MentalProgressService {
  const MentalProgressService();

  String _namespace() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    // Los invitados conservan un estado separado. No lo mezclamos con
    // el inventario o el progreso del usuario al iniciar sesión.
    return 'hh_mental_v1_${uid ?? 'invitado'}';
  }

  String _key(DateTime day, String id) =>
      '${_namespace()}_${MentalDailyKey.forDate(day)}_$id';

  Future<MentalDailyProgress> progress(DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    final sudoku = prefs.getBool(_key(day, 'sudoku')) ?? false;
    final wordSearch = prefs.getBool(_key(day, 'sopa')) ?? false;
    var streak = 0;
    var cursor = DateTime(day.year, day.month, day.day);
    // El día actual no rompe la racha si todavía no ha terminado.
    final todayDone = sudoku || wordSearch;
    if (!todayDone) cursor = cursor.subtract(const Duration(days: 1));
    for (var i = 0; i < 365; i++) {
      final done = (prefs.getBool(_key(cursor, 'sudoku')) ?? false) ||
          (prefs.getBool(_key(cursor, 'sopa')) ?? false);
      if (!done) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return MentalDailyProgress(
      sudoku: sudoku, wordSearch: wordSearch, streak: streak,
    );
  }

  Future<void> complete(DateTime day, String game) async {
    if (!const {'sudoku', 'sopa'}.contains(game)) {
      throw ArgumentError.value(game, 'game', 'Ejercicio desconocido');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(day, game), true);
  }

  Future<List<int>?> sudokuCells(DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(day, 'sudoku_celdas'));
    if (raw == null || raw.length != 81) return null;
    final values = <int>[];
    for (final cell in raw) {
      final value = int.tryParse(cell);
      if (value == null || value < 0 || value > 9) return null;
      values.add(value);
    }
    return values;
  }

  Future<void> saveSudoku(DateTime day, List<int> cells) async {
    if (cells.length != 81 || cells.any((x) => x < 0 || x > 9)) {
      throw ArgumentError('Tablero de Sudoku inválido.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key(day, 'sudoku_celdas'),
      cells.map((value) => value.toString()).toList(),
    );
  }

  Future<Set<String>> foundWords(DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key(day, 'sopa_palabras')) ?? [])
        .toSet();
  }

  Future<void> saveFoundWords(DateTime day, Set<String> words) async {
    final puzzle = MentalWordSearchPuzzle.forDate(day);
    if (!puzzle.words.toSet().containsAll(words)) {
      throw ArgumentError('Palabras no pertenecientes a la partida.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(day, 'sopa_palabras'),
        words.toList()..sort());
  }
}
