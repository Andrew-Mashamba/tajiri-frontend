// lib/games/games/block_puzzle/block_puzzle_engine.dart
// Pure Dart — no Flutter imports.

import 'dart:math';

class BlockShape {
  final String name;
  final List<List<bool>> cells;

  const BlockShape(this.name, this.cells);

  int get rows => cells.length;
  int get cols => cells.isEmpty ? 0 : cells[0].length;
}

/// All available block shapes.
final List<BlockShape> kBlockShapes = [
  // I shapes
  BlockShape('I_h', [
    [true, true, true, true],
  ]),
  BlockShape('I_v', [
    [true],
    [true],
    [true],
    [true],
  ]),
  // O
  BlockShape('O', [
    [true, true],
    [true, true],
  ]),
  // L
  BlockShape('L', [
    [true, false],
    [true, false],
    [true, true],
  ]),
  // J
  BlockShape('J', [
    [false, true],
    [false, true],
    [true, true],
  ]),
  // T
  BlockShape('T', [
    [true, true, true],
    [false, true, false],
  ]),
  // S
  BlockShape('S', [
    [false, true, true],
    [true, true, false],
  ]),
  // Z
  BlockShape('Z', [
    [true, true, false],
    [false, true, true],
  ]),
  // Small pieces
  BlockShape('1x1', [
    [true],
  ]),
  BlockShape('1x2', [
    [true, true],
  ]),
  BlockShape('2x1', [
    [true],
    [true],
  ]),
  BlockShape('1x3', [
    [true, true, true],
  ]),
  BlockShape('3x1', [
    [true],
    [true],
    [true],
  ]),
  // Plus
  BlockShape('plus', [
    [false, true, false],
    [true, true, true],
    [false, true, false],
  ]),
  // Corner
  BlockShape('corner', [
    [true, true],
    [true, false],
  ]),
];

class BlockPuzzleEngine {
  static const int size = 10;

  /// 10x10 grid. true = occupied.
  final List<List<bool>> grid;
  int score = 0;

  late Random _rng;

  /// The 3 shapes currently available to the player.
  List<BlockShape?> currentShapes = [null, null, null];

  BlockPuzzleEngine(String seed) : grid = List.generate(size, (_) => List.filled(size, false)) {
    _rng = Random(seed.hashCode);
    _dealShapes();
  }

  void _dealShapes() {
    for (int i = 0; i < 3; i++) {
      currentShapes[i] = kBlockShapes[_rng.nextInt(kBlockShapes.length)];
    }
  }

  /// Check if all 3 shapes are placed (all null).
  bool get allShapesPlaced => currentShapes.every((s) => s == null);

  /// Can [shape] be placed at grid position (row, col)?
  bool canPlace(BlockShape shape, int row, int col) {
    for (int r = 0; r < shape.rows; r++) {
      for (int c = 0; c < shape.cols; c++) {
        if (!shape.cells[r][c]) continue;
        final gr = row + r;
        final gc = col + c;
        if (gr < 0 || gr >= size || gc < 0 || gc >= size) return false;
        if (grid[gr][gc]) return false;
      }
    }
    return true;
  }

  /// Place [shape] at (row, col). Returns number of lines cleared.
  int placeShape(BlockShape shape, int row, int col) {
    if (!canPlace(shape, row, col)) return -1;

    // Place
    for (int r = 0; r < shape.rows; r++) {
      for (int c = 0; c < shape.cols; c++) {
        if (shape.cells[r][c]) {
          grid[row + r][col + c] = true;
        }
      }
    }
    score += 1; // 1 point for placing

    // Check full rows and columns
    int cleared = 0;
    final rowsToClear = <int>[];
    final colsToClear = <int>[];

    for (int r = 0; r < size; r++) {
      if (grid[r].every((v) => v)) rowsToClear.add(r);
    }
    for (int c = 0; c < size; c++) {
      bool full = true;
      for (int r = 0; r < size; r++) {
        if (!grid[r][c]) {
          full = false;
          break;
        }
      }
      if (full) colsToClear.add(c);
    }

    // Clear
    for (final r in rowsToClear) {
      for (int c = 0; c < size; c++) {
        grid[r][c] = false;
      }
      cleared++;
    }
    for (final c in colsToClear) {
      for (int r = 0; r < size; r++) {
        grid[r][c] = false;
      }
      cleared++;
    }

    score += cleared * 10;
    return cleared;
  }

  /// Remove shape at index from current shapes.
  void consumeShape(int index) {
    currentShapes[index] = null;
    // If all placed, deal new batch
    if (allShapesPlaced) {
      _dealShapes();
    }
  }

  /// Can any of the remaining shapes fit anywhere?
  bool canAnyShapeFit() {
    for (final shape in currentShapes) {
      if (shape == null) continue;
      for (int r = 0; r < size; r++) {
        for (int c = 0; c < size; c++) {
          if (canPlace(shape, r, c)) return true;
        }
      }
    }
    return false;
  }

  bool get isGameOver => !canAnyShapeFit();

  /// Serialise.
  Map<String, dynamic> toJson() => {
        'grid': grid.map((r) => r.map((v) => v ? 1 : 0).toList()).toList(),
        'score': score,
        'shapes': currentShapes
            .map((s) => s?.name)
            .toList(),
      };

  /// Restore.
  factory BlockPuzzleEngine.fromJson(Map<String, dynamic> json, String seed) {
    final e = BlockPuzzleEngine(seed);
    final gridData = json['grid'] as List?;
    if (gridData != null) {
      for (int r = 0; r < size && r < gridData.length; r++) {
        final row = (gridData[r] as List).cast<int>();
        for (int c = 0; c < size && c < row.length; c++) {
          e.grid[r][c] = row[c] == 1;
        }
      }
    }
    e.score = json['score'] as int? ?? 0;
    final shapes = (json['shapes'] as List?)?.cast<String?>();
    if (shapes != null) {
      for (int i = 0; i < 3 && i < shapes.length; i++) {
        if (shapes[i] == null) {
          e.currentShapes[i] = null;
        } else {
          e.currentShapes[i] = kBlockShapes.firstWhere(
            (s) => s.name == shapes[i],
            orElse: () => kBlockShapes[0],
          );
        }
      }
    }
    return e;
  }
}
