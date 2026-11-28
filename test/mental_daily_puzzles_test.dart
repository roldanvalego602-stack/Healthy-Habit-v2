import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:healthy_habit/páginas/mente/mental_puzzles.dart';
import 'package:healthy_habit/páginas/mente/mental_progress_service.dart';

void main() {
  test('sudoku cambia a diario y siempre respeta filas, columnas y cuadros',
      () {
    final seeds = <String>{};
    for (var day = 1; day <= 28; day++) {
      final game = SudokuPuzzle.forDate(DateTime(2026, 11, day));
      expect(game.givens.length, 81);
      expect(game.solution.length, 81);
      expect(game.respectsSudokuRules(), isTrue);
      expect(game.isSolved(game.solution), isTrue);
      expect(game.isSolved(game.givens), isFalse);
      expect(game.givens.where((x) => x == 0).length, greaterThan(40));
      seeds.add(game.givens.join());
    }
    expect(seeds.length, greaterThan(20));
  });

  test('sudoku es idéntico para el mismo día sin importar la hora', () {
    final first = SudokuPuzzle.forDate(DateTime(2026, 11, 27, 1));
    final second = SudokuPuzzle.forDate(DateTime(2026, 11, 27, 23));
    expect(first.givens, second.givens);
    expect(first.solution, second.solution);
    expect(first.isCorrect(0, first.solution[0]), isTrue);
    expect(first.isCorrect(0, 0), isFalse);
  });

  test('sopa diaria contiene todas las palabras colocadas y es estable', () {
    for (var day = 1; day <= 20; day++) {
      final date = DateTime(2026, 11, day);
      final game = MentalWordSearchPuzzle.forDate(date);
      final copy = MentalWordSearchPuzzle.forDate(date);
      expect(game.size, 12);
      expect(game.cells.length, 144);
      expect(game.cells, copy.cells);
      expect(game.words, copy.words);
      expect(game.words.toSet().length, 7);
      for (final word in game.words) {
        expect(game.containsWord(word), isTrue, reason: word);
        final positions = game.wordPaths[word]!;
        expect(positions.length, word.length);
        expect(game.wordBetween(positions.first, positions.last), word);
        expect(game.wordBetween(positions.last, positions.first), word);
      }
    }
  });

  test('sopa rechaza diagonales imposibles y posiciones ajenas', () {
    final game = MentalWordSearchPuzzle.forDate(DateTime(2026, 11, 27));
    expect(game.pathBetween(-1, 12), isEmpty);
    expect(game.pathBetween(0, 144), isEmpty);
    expect(game.pathBetween(0, 14), isEmpty);
    expect(game.wordBetween(-1, 5), isNull);
  });

  test('progreso mental local no concede monedas ni XP y persiste',
      () async {
    SharedPreferences.setMockInitialValues({});
    const service = MentalProgressService();
    final day = DateTime(2026, 11, 27);
    final yesterday = day.subtract(const Duration(days: 1));
    await service.complete(yesterday, 'sudoku');
    await service.complete(day, 'sopa');
    final progress = await service.progress(day);
    expect(progress.sudoku, isFalse);
    expect(progress.wordSearch, isTrue);
    expect(progress.completed, 1);
    expect(progress.streak, 2);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((key) =>
      key.contains('habitCoins') || key.contains('xpAwarded')), isEmpty);
  });

  test('guardado de sudoku y palabras rechaza datos inválidos', () async {
    SharedPreferences.setMockInitialValues({});
    const service = MentalProgressService();
    final day = DateTime(2026, 11, 27);
    final puzzle = SudokuPuzzle.forDate(day);
    await service.saveSudoku(day, puzzle.givens);
    expect(await service.sudokuCells(day), puzzle.givens);
    await expectLater(
      service.saveSudoku(day, const [1, 2, 3]), throwsArgumentError);
    final search = MentalWordSearchPuzzle.forDate(day);
    await service.saveFoundWords(day, {search.words.first});
    expect(await service.foundWords(day), {search.words.first});
    await expectLater(service.saveFoundWords(day, {'INVENTADA'}),
        throwsArgumentError);
    await expectLater(service.complete(day, 'juego_inexistente'),
        throwsArgumentError);
  });
}
