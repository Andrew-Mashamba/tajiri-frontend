// lib/games/games/dots_boxes/dots_boxes_engine.dart
// Pure Dart — no Flutter imports.

/// Represents a line between two adjacent dots.
/// Dots are at positions (row, col) where row,col in [0..4].
/// Horizontal line: (r, c) -> (r, c+1), encoded as 'h_r_c'
/// Vertical line: (r, c) -> (r+1, c), encoded as 'v_r_c'
class DotsBoxesEngine {
  static const int gridSize = 5; // 5x5 dots = 4x4 boxes
  static const int boxCount = 16;

  final Set<String> _lines = {};
  final Map<String, int> _boxOwner = {}; // boxKey -> player (1 or 2)
  int currentPlayer = 1; // 1 or 2

  int player1Score = 0;
  int player2Score = 0;

  DotsBoxesEngine();

  /// All possible line IDs.
  List<String> get allLines {
    final lines = <String>[];
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize - 1; c++) {
        lines.add('h_${r}_$c'); // horizontal
      }
    }
    for (int r = 0; r < gridSize - 1; r++) {
      for (int c = 0; c < gridSize; c++) {
        lines.add('v_${r}_$c'); // vertical
      }
    }
    return lines;
  }

  /// Lines not yet drawn.
  List<String> legalMoves() {
    return allLines.where((l) => !_lines.contains(l)).toList();
  }

  bool isLineDrawn(String lineId) => _lines.contains(lineId);

  bool get isGameOver => _lines.length == allLines.length;

  int? get winner {
    if (!isGameOver) return null;
    if (player1Score > player2Score) return 1;
    if (player2Score > player1Score) return 2;
    return null; // draw
  }

  /// Draw a line. Returns number of boxes completed (0, 1, or 2).
  /// If boxes are completed, same player goes again (caller should NOT switch).
  int drawLine(String lineId) {
    if (_lines.contains(lineId)) return 0;
    _lines.add(lineId);

    int completed = 0;

    // Check which boxes this line borders
    final boxes = _boxesForLine(lineId);
    for (final boxKey in boxes) {
      if (_boxOwner.containsKey(boxKey)) continue;
      if (_isBoxComplete(boxKey)) {
        _boxOwner[boxKey] = currentPlayer;
        if (currentPlayer == 1) {
          player1Score++;
        } else {
          player2Score++;
        }
        completed++;
      }
    }

    // If no box completed, switch player
    if (completed == 0) {
      currentPlayer = currentPlayer == 1 ? 2 : 1;
    }

    return completed;
  }

  /// Get the owner of a box (1, 2, or null).
  int? boxOwner(int row, int col) => _boxOwner['box_${row}_$col'];

  /// The 4 lines of a box at grid position (row, col) where row,col in [0..3].
  List<String> _boxLines(int row, int col) {
    return [
      'h_${row}_$col', // top
      'h_${row + 1}_$col', // bottom
      'v_${row}_$col', // left
      'v_${row}_${col + 1}', // right
    ];
  }

  bool _isBoxComplete(String boxKey) {
    final parts = boxKey.split('_');
    final row = int.parse(parts[1]);
    final col = int.parse(parts[2]);
    return _boxLines(row, col).every((l) => _lines.contains(l));
  }

  /// Which boxes does this line border?
  List<String> _boxesForLine(String lineId) {
    final parts = lineId.split('_');
    final type = parts[0]; // 'h' or 'v'
    final r = int.parse(parts[1]);
    final c = int.parse(parts[2]);
    final boxes = <String>[];

    if (type == 'h') {
      // Horizontal line at row r, between col c and c+1
      // Top side of box (r, c) if r < gridSize-1
      if (r < gridSize - 1) boxes.add('box_${r}_$c');
      // Bottom side of box (r-1, c) if r > 0
      if (r > 0) boxes.add('box_${r - 1}_$c');
    } else {
      // Vertical line at row r, col c (between row r and r+1)
      // Left side of box (r, c) if c < gridSize-1
      if (c < gridSize - 1) boxes.add('box_${r}_$c');
      // Right side of box (r, c-1) if c > 0
      if (c > 0) boxes.add('box_${r}_${c - 1}');
    }

    return boxes;
  }

  /// How many sides of a given box are drawn.
  int boxSideCount(int row, int col) {
    return _boxLines(row, col).where((l) => _lines.contains(l)).length;
  }

  /// Serialise for persistence.
  Map<String, dynamic> toJson() => {
        'lines': _lines.toList(),
        'boxOwner': _boxOwner.map((k, v) => MapEntry(k, v)),
        'currentPlayer': currentPlayer,
        'player1Score': player1Score,
        'player2Score': player2Score,
      };

  /// Restore from persistence.
  factory DotsBoxesEngine.fromJson(Map<String, dynamic> json) {
    final e = DotsBoxesEngine();
    final lines = (json['lines'] as List?)?.cast<String>() ?? [];
    e._lines.addAll(lines);
    final owners = (json['boxOwner'] as Map?)?.cast<String, dynamic>() ?? {};
    for (final entry in owners.entries) {
      e._boxOwner[entry.key] = entry.value as int;
    }
    e.currentPlayer = json['currentPlayer'] as int? ?? 1;
    e.player1Score = json['player1Score'] as int? ?? 0;
    e.player2Score = json['player2Score'] as int? ?? 0;
    return e;
  }
}
