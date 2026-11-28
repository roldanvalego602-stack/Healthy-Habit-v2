import 'dart:math';

/// Partidas locales diarias. No conceden XP ni validan identidad o
/// realización fuera del dispositivo.
class MentalDailyKey {
  const MentalDailyKey._();

  static String forDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static int seed(DateTime day, {int salt = 0}) {
    final utcDay = DateTime.utc(day.year, day.month, day.day);
    return (utcDay.millisecondsSinceEpoch ~/ 86400000) ^ salt;
  }
}

class SudokuPuzzle {
  const SudokuPuzzle._({
    required this.givens,
    required this.solution,
    required this.dayKey,
  });

  final List<int> givens;
  final List<int> solution;
  final String dayKey;

  /// Un acertijo clásico de solución única, transformado mediante
  /// permutaciones que preservan las reglas del sudoku.
  static const _base = [
    '530070000', '600195000', '098000060',
    '800060003', '400803001', '700020006',
    '060000280', '000419005', '000080079',
  ];
  static const _solved = [
    '534678912', '672195348', '198342567',
    '859761423', '426853791', '713924856',
    '961537284', '287419635', '345286179',
  ];

  factory SudokuPuzzle.forDate(DateTime date) {
    final random = Random(MentalDailyKey.seed(date, salt: 27381));
    List<int> order() {
      final bands = [0, 1, 2]..shuffle(random);
      return [
        for (final band in bands)
          ...([0, 1, 2]..shuffle(random)).map((i) => band * 3 + i),
      ];
    }

    final rows = order();
    final columns = order();
    final digits = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(random);
    int digit(String raw) {
      final original = int.parse(raw);
      return original == 0 ? 0 : digits[original - 1];
    }

    final givens = <int>[];
    final solution = <int>[];
    for (var row = 0; row < 9; row++) {
      for (var col = 0; col < 9; col++) {
        givens.add(digit(_base[rows[row]][columns[col]]));
        solution.add(digit(_solved[rows[row]][columns[col]]));
      }
    }
    return SudokuPuzzle._(
      givens: List.unmodifiable(givens),
      solution: List.unmodifiable(solution),
      dayKey: MentalDailyKey.forDate(date),
    );
  }

  bool isGiven(int index) => givens[index] != 0;

  bool isSolved(List<int> cells) =>
      cells.length == 81 &&
      List.generate(81, (i) => i).every((i) => cells[i] == solution[i]);

  bool isCorrect(int index, int value) =>
      index >= 0 && index < 81 && value == solution[index];

  bool respectsSudokuRules() {
    for (var index = 0; index < 81; index++) {
      if (givens[index] != 0 && givens[index] != solution[index]) return false;
    }
    for (var k = 0; k < 9; k++) {
      final row = [for (var c = 0; c < 9; c++) solution[k * 9 + c]];
      final col = [for (var r = 0; r < 9; r++) solution[r * 9 + k]];
      final top = (k ~/ 3) * 3;
      final left = (k % 3) * 3;
      final box = [
        for (var r = top; r < top + 3; r++)
          for (var c = left; c < left + 3; c++) solution[r * 9 + c],
      ];
      for (final group in [row, col, box]) {
        if (group.toSet().length != 9 ||
            group.any((value) => value < 1 || value > 9)) return false;
      }
    }
    return true;
  }
}

class MentalWordSearchPuzzle {
  const MentalWordSearchPuzzle._({
    required this.cells,
    required this.words,
    required this.dayKey,
    required this.size,
  });

  static const side = 12;
  static const _dictionary = [
    'MEMORIA', 'LECTURA', 'ENFOQUE', 'CALMA', 'LOGICA',
    'ATENCION', 'CREATIVIDAD', 'PACIENCIA', 'APRENDER',
    'RESPIRAR', 'PENSAR', 'DESCANSO', 'IMAGINAR', 'ANALISIS',
  ];

  final List<String> cells;
  final List<String> words;
  final String dayKey;
  final int size;

  factory MentalWordSearchPuzzle.forDate(DateTime date) {
    final random = Random(MentalDailyKey.seed(date, salt: 41973));
    final board = List.filled(side * side, '');
    final candidates = [..._dictionary]..shuffle(random);
    final words = candidates.take(7).toList();
    const directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1], [0, 1],
      [1, -1], [1, 0], [1, 1],
    ];
    for (final word in words) {
      var inserted = false;
      for (var attempt = 0; attempt < 600 && !inserted; attempt++) {
        final d = directions[random.nextInt(directions.length)];
        final row = random.nextInt(side);
        final col = random.nextInt(side);
        final endR = row + d[0] * (word.length - 1);
        final endC = col + d[1] * (word.length - 1);
        if (endR < 0 || endC < 0 || endR >= side || endC >= side) continue;
        var fits = true;
        for (var i = 0; i < word.length; i++) {
          final index = (row + d[0] * i) * side + col + d[1] * i;
          if (board[index].isNotEmpty && board[index] != word[i]) {
            fits = false;
            break;
          }
        }
        if (!fits) continue;
        for (var i = 0; i < word.length; i++) {
          final index = (row + d[0] * i) * side + col + d[1] * i;
          board[index] = word[i];
        }
        inserted = true;
      }
      if (!inserted) {
        throw StateError('No se pudo construir la sopa de letras.');
      }
    }
    const alphabet = 'ABCDEFGHIJKLMNÑOPQRSTUVWXYZ';
    for (var i = 0; i < board.length; i++) {
      if (board[i].isEmpty) {
        board[i] = alphabet[random.nextInt(alphabet.length)];
      }
    }
    return MentalWordSearchPuzzle._(
      cells: List.unmodifiable(board),
      words: List.unmodifiable(words),
      dayKey: MentalDailyKey.forDate(date),
      size: side,
    );
  }

  List<int> pathBetween(int first, int last) {
    if (first < 0 || last < 0 ||
        first >= size * size || last >= size * size) return [];
    final rowA = first ~/ size;
    final colA = first % size;
    final rowB = last ~/ size;
    final colB = last % size;
    final deltaR = rowB - rowA;
    final deltaC = colB - colA;
    if (deltaR == 0 && deltaC == 0) return [first];
    if (deltaR != 0 && deltaC != 0 &&
        deltaR.abs() != deltaC.abs()) return [];
    final steps = max(deltaR.abs(), deltaC.abs());
    final dirR = deltaR.sign;
    final dirC = deltaC.sign;
    return [
      for (var i = 0; i <= steps; i++)
        (rowA + i * dirR) * size + colA + i * dirC,
    ];
  }

  String? wordBetween(int first, int last) {
    final path = pathBetween(first, last);
    if (path.isEmpty) return null;
    final text = path.map((index) => cells[index]).join();
    if (words.contains(text)) return text;
    final reversed = text.split('').reversed.join();
    return words.contains(reversed) ? reversed : null;
  }

  /// Solo para pruebas de colocación y verificabilidad de la solución.
  bool containsWord(String word) {
    if (!words.contains(word)) return false;
    for (var start = 0; start < cells.length; start++) {
      for (var end = 0; end < cells.length; end++) {
        if (wordBetween(start, end) == word) return true;
      }
    }
    return false;
  }
}
