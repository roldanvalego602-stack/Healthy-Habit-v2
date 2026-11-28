import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:healthy_habit/páginas/mente/mental_puzzles.dart';
import 'package:healthy_habit/páginas/mente/mental_training_screen.dart';
import 'package:healthy_habit/páginas/mente/mental_sudoku_screen.dart';
import 'package:healthy_habit/páginas/mente/mental_word_search_screen.dart';
import 'package:healthy_habit/páginas/mente/mental_progress_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('el centro mental muestra Sudoku y sopa sin exigir sesión',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MentalTrainingScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Entrena tu mente'), findsOneWidget);
    expect(find.text('Sudoku'), findsOneWidget);
    expect(find.text('Sopa de letras'), findsOneWidget);
    expect(find.textContaining('0/2'), findsOneWidget);
    expect(find.byKey(const ValueKey('mental-open-sudoku')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mental-open-sudoku')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mental-sudoku-grid')),
        findsOneWidget);
  });

  testWidgets('Sudoku permite introducir una solución correcta',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MentalSudokuScreen()));
    await tester.pumpAndSettle();
    final puzzle = SudokuPuzzle.forDate(DateTime.now());
    final blankIndex = puzzle.givens.indexOf(0);
    expect(blankIndex, isNonNegative);
    final cell = find.byKey(ValueKey('mental-sudoku-cell-$blankIndex'));
    await tester.ensureVisible(cell);
    await tester.tap(cell);
    await tester.pump();
    final digit = find.byKey(ValueKey(
        'mental-sudoku-digit-${puzzle.solution[blankIndex]}'));
    await tester.ensureVisible(digit);
    await tester.tap(digit);
    await tester.pumpAndSettle();
    final saved = await const MentalProgressService()
        .sudokuCells(DateTime.now());
    expect(saved![blankIndex], puzzle.solution[blankIndex]);
  });

  testWidgets('sopa de letras marca una palabra con inicio y fin',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MentalWordSearchScreen()));
    await tester.pumpAndSettle();
    final puzzle = MentalWordSearchPuzzle.forDate(DateTime.now());
    final word = puzzle.words.first;
    final path = puzzle.wordPaths[word]!;
    final start = find.byKey(
        ValueKey('mental-wordsearch-cell-${path.first}'));
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pump();
    final end = find.byKey(
        ValueKey('mental-wordsearch-cell-${path.last}'));
    await tester.ensureVisible(end);
    await tester.tap(end);
    await tester.pumpAndSettle();
    expect(find.textContaining('1/7'), findsWidgets);
    final found = await const MentalProgressService()
        .foundWords(DateTime.now());
    expect(found, contains(word));
  });
}
