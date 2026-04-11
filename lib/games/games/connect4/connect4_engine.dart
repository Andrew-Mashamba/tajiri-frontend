// lib/games/games/connect4/connect4_engine.dart
// Pure Dart — no Flutter imports.

class Connect4Engine {
  static const int cols = 7;
  static const int rows = 6;

  /// Board grid. 0 = empty, 1 = player 1, 2 = player 2.
  /// board[row][col], row 0 = top, row 5 = bottom.
  final List<List<int>> board;
  int currentPlayer; // 1 or 2

  Connect4Engine()
      : board = List.generate(rows, (_) => List.filled(cols, 0)),
        currentPlayer = 1;

  /// Columns that still have at least one empty cell.
  List<int> legalColumns() {
    final result = <int>[];
    for (int c = 0; c < cols; c++) {
      if (board[0][c] == 0) result.add(c);
    }
    return result;
  }

  /// Drop a disc into [column]. Returns the row it lands on, or -1 if full.
  int dropDisc(int column) {
    if (column < 0 || column >= cols) return -1;
    // Find lowest empty row
    for (int r = rows - 1; r >= 0; r--) {
      if (board[r][column] == 0) {
        board[r][column] = currentPlayer;
        return r;
      }
    }
    return -1; // column full
  }

  /// Switch to the other player.
  void switchPlayer() {
    currentPlayer = currentPlayer == 1 ? 2 : 1;
  }

  /// Check if the board is completely full (draw).
  bool isFull() {
    for (int c = 0; c < cols; c++) {
      if (board[0][c] == 0) return false;
    }
    return true;
  }

  /// Check for 4 in a row. Returns the winning player (1 or 2) or null.
  /// Also returns the winning cells as a list of [row, col] pairs.
  ({int player, List<List<int>> cells})? checkWin() {
    // Directions: horizontal, vertical, diagonal-down-right, diagonal-down-left
    const directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final p = board[r][c];
        if (p == 0) continue;

        for (final d in directions) {
          final cells = <List<int>>[];
          bool found = true;
          for (int i = 0; i < 4; i++) {
            final nr = r + d[0] * i;
            final nc = c + d[1] * i;
            if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) {
              found = false;
              break;
            }
            if (board[nr][nc] != p) {
              found = false;
              break;
            }
            cells.add([nr, nc]);
          }
          if (found) {
            return (player: p, cells: cells);
          }
        }
      }
    }
    return null;
  }

  /// Serialise for persistence.
  Map<String, dynamic> toJson() => {
        'board': board.map((row) => row.toList()).toList(),
        'currentPlayer': currentPlayer,
      };

  /// Restore from persistence.
  factory Connect4Engine.fromJson(Map<String, dynamic> json) {
    final e = Connect4Engine();
    final boardData = json['board'] as List?;
    if (boardData != null) {
      for (int r = 0; r < rows && r < boardData.length; r++) {
        final rowData = (boardData[r] as List).cast<int>();
        for (int c = 0; c < cols && c < rowData.length; c++) {
          e.board[r][c] = rowData[c];
        }
      }
    }
    e.currentPlayer = json['currentPlayer'] as int? ?? 1;
    return e;
  }
}
