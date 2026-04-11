// lib/games/games/sudoku/sudoku_engine.dart

import 'dart:math';

/// Sudoku puzzle generator and validator using backtracking.
class SudokuEngine {
  /// Check if placing [num] at [row],[col] is valid.
  static bool isValid(List<List<int>> grid, int row, int col, int num) {
    // Check row
    for (int c = 0; c < 9; c++) {
      if (grid[row][c] == num) return false;
    }
    // Check column
    for (int r = 0; r < 9; r++) {
      if (grid[r][col] == num) return false;
    }
    // Check 3x3 box
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        if (grid[r][c] == num) return false;
      }
    }
    return true;
  }

  /// Solve the grid in-place using backtracking. Returns true if solved.
  static bool solve(List<List<int>> grid) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] == 0) {
          for (int num = 1; num <= 9; num++) {
            if (isValid(grid, row, col, num)) {
              grid[row][col] = num;
              if (solve(grid)) return true;
              grid[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  /// Fill the three diagonal 3x3 boxes randomly (they don't affect each other).
  static void _fillDiagonalBoxes(List<List<int>> grid, Random rng) {
    for (int box = 0; box < 3; box++) {
      final nums = List<int>.generate(9, (i) => i + 1)..shuffle(rng);
      int idx = 0;
      final startRow = box * 3;
      final startCol = box * 3;
      for (int r = startRow; r < startRow + 3; r++) {
        for (int c = startCol; c < startCol + 3; c++) {
          grid[r][c] = nums[idx++];
        }
      }
    }
  }

  /// Generate a complete valid Sudoku grid.
  static List<List<int>> _generateFullGrid(Random rng) {
    final grid = List.generate(9, (_) => List<int>.filled(9, 0));
    _fillDiagonalBoxes(grid, rng);
    solve(grid);
    return grid;
  }

  /// Generate a puzzle by removing cells from a full grid.
  /// [difficulty]: 'easy' (38 given), 'medium' (30 given), 'hard' (24 given).
  /// Returns a map with 'puzzle' (with zeros for blanks) and 'solution'.
  static Map<String, List<List<int>>> generatePuzzle(
      int seed, String difficulty) {
    final rng = Random(seed);
    final solution = _generateFullGrid(rng);
    final puzzle = solution.map((row) => List<int>.from(row)).toList();

    int given;
    switch (difficulty) {
      case 'easy':
        given = 38;
        break;
      case 'hard':
        given = 24;
        break;
      default:
        given = 30;
    }

    final toRemove = 81 - given;
    final cells = <int>[];
    for (int i = 0; i < 81; i++) {
      cells.add(i);
    }
    cells.shuffle(rng);

    int removed = 0;
    for (final cell in cells) {
      if (removed >= toRemove) break;
      final r = cell ~/ 9;
      final c = cell % 9;
      puzzle[r][c] = 0;
      removed++;
    }

    return {'puzzle': puzzle, 'solution': solution};
  }

  /// Check if the entire grid is correctly filled (no zeros, all valid).
  static bool checkComplete(List<List<int>> grid) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] == 0) return false;
      }
    }
    // Verify all rows, columns, and boxes
    for (int i = 0; i < 9; i++) {
      final rowSet = <int>{};
      final colSet = <int>{};
      for (int j = 0; j < 9; j++) {
        rowSet.add(grid[i][j]);
        colSet.add(grid[j][i]);
      }
      if (rowSet.length != 9 || colSet.length != 9) return false;
    }
    for (int boxRow = 0; boxRow < 3; boxRow++) {
      for (int boxCol = 0; boxCol < 3; boxCol++) {
        final boxSet = <int>{};
        for (int r = boxRow * 3; r < boxRow * 3 + 3; r++) {
          for (int c = boxCol * 3; c < boxCol * 3 + 3; c++) {
            boxSet.add(grid[r][c]);
          }
        }
        if (boxSet.length != 9) return false;
      }
    }
    return true;
  }
}
