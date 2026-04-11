// lib/games/games/ultimate_ttt/ultimate_ttt_engine.dart
// Pure Dart — no Flutter imports.

class UltimateTttEngine {
  /// 9 small boards, each with 9 cells. Values: 0=empty, 1=X, 2=O.
  final List<List<int>> boards;

  /// Winner of each small board: 0=undecided, 1=X, 2=O, 3=draw.
  final List<int> boardWinners;

  /// Which small board the current player must play in (null = any open board).
  int? activeBoard;

  /// Current player: 1=X, 2=O.
  int currentPlayer;

  UltimateTttEngine()
      : boards = List.generate(9, (_) => List.filled(9, 0)),
        boardWinners = List.filled(9, 0),
        activeBoard = null,
        currentPlayer = 1;

  /// Returns all legal moves as {board, cell} pairs.
  List<({int board, int cell})> legalMoves() {
    final moves = <({int board, int cell})>[];
    if (isGameOver()) return moves;

    if (activeBoard != null && boardWinners[activeBoard!] == 0) {
      // Must play in the active board
      for (int c = 0; c < 9; c++) {
        if (boards[activeBoard!][c] == 0) {
          moves.add((board: activeBoard!, cell: c));
        }
      }
    } else {
      // Can play in any open board
      for (int b = 0; b < 9; b++) {
        if (boardWinners[b] != 0) continue; // board already decided
        for (int c = 0; c < 9; c++) {
          if (boards[b][c] == 0) {
            moves.add((board: b, cell: c));
          }
        }
      }
    }
    return moves;
  }

  /// Place current player's mark at [board][cell].
  /// Returns false if move is illegal.
  bool makeMove(int board, int cell) {
    if (board < 0 || board >= 9 || cell < 0 || cell >= 9) return false;
    if (boards[board][cell] != 0) return false;
    if (boardWinners[board] != 0) return false;

    // Check active board constraint
    if (activeBoard != null &&
        boardWinners[activeBoard!] == 0 &&
        board != activeBoard!) {
      return false;
    }

    boards[board][cell] = currentPlayer;

    // Check if this small board is now won
    final smallWinner = _checkBoardWin(boards[board]);
    if (smallWinner != 0) {
      boardWinners[board] = smallWinner;
    } else if (!boards[board].contains(0)) {
      // Board is full with no winner -> draw
      boardWinners[board] = 3;
    }

    // Set next active board
    if (boardWinners[cell] != 0) {
      // Target board is already decided -> free choice
      activeBoard = null;
    } else {
      activeBoard = cell;
    }

    // Switch player
    currentPlayer = currentPlayer == 1 ? 2 : 1;
    return true;
  }

  /// Check if the game is over (meta-board has a winner or all boards decided).
  bool isGameOver() {
    if (winner() != null) return true;
    // All boards decided?
    return boardWinners.every((w) => w != 0);
  }

  /// Returns the meta-game winner (1 or 2), or null if no winner yet.
  int? winner() {
    return _checkMetaWin();
  }

  int _checkMetaWin() {
    // Check rows, cols, diags on meta-board
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // cols
      [0, 4, 8], [2, 4, 6], // diags
    ];
    for (final line in lines) {
      final a = boardWinners[line[0]];
      final b = boardWinners[line[1]];
      final c = boardWinners[line[2]];
      if (a != 0 && a != 3 && a == b && b == c) return a;
    }
    return 0; // 0 means no winner
  }

  /// Check 3-in-a-row on a single 3x3 board.
  /// Returns 1 (X wins), 2 (O wins), or 0 (no winner).
  static int _checkBoardWin(List<int> b) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    for (final line in lines) {
      final a = b[line[0]];
      final bb = b[line[1]];
      final c = b[line[2]];
      if (a != 0 && a == bb && bb == c) return a;
    }
    return 0;
  }

  /// Serialise for persistence.
  Map<String, dynamic> toJson() => {
        'boards': boards.map((b) => b.toList()).toList(),
        'boardWinners': boardWinners.toList(),
        'activeBoard': activeBoard,
        'currentPlayer': currentPlayer,
      };

  /// Restore from persistence.
  factory UltimateTttEngine.fromJson(Map<String, dynamic> json) {
    final e = UltimateTttEngine();
    final boardsData = json['boards'] as List?;
    if (boardsData != null) {
      for (int i = 0; i < 9 && i < boardsData.length; i++) {
        final row = (boardsData[i] as List).cast<int>();
        for (int j = 0; j < 9 && j < row.length; j++) {
          e.boards[i][j] = row[j];
        }
      }
    }
    final winnersData = json['boardWinners'] as List?;
    if (winnersData != null) {
      for (int i = 0; i < 9 && i < winnersData.length; i++) {
        e.boardWinners[i] = winnersData[i] as int;
      }
    }
    e.activeBoard = json['activeBoard'] as int?;
    e.currentPlayer = json['currentPlayer'] as int? ?? 1;
    return e;
  }
}
