// lib/games/games/checkers/checkers_engine.dart
// Pure Dart — no Flutter imports.

enum CheckersPlayer {
  dark,
  light;

  CheckersPlayer get opponent =>
      this == dark ? light : dark;
}

class CheckersPiece {
  final CheckersPlayer owner;
  final bool isKing;

  const CheckersPiece({required this.owner, this.isKing = false});

  CheckersPiece promoted() => CheckersPiece(owner: owner, isKing: true);

  Map<String, dynamic> toJson() => {
        'owner': owner.name,
        'isKing': isKing,
      };

  factory CheckersPiece.fromJson(Map<String, dynamic> json) => CheckersPiece(
        owner: json['owner'] == 'dark' ? CheckersPlayer.dark : CheckersPlayer.light,
        isKing: json['isKing'] == true,
      );
}

class CheckersMove {
  final int from;
  final int to;
  final List<int> captured;
  final bool promotesToKing;

  const CheckersMove({
    required this.from,
    required this.to,
    this.captured = const [],
    this.promotesToKing = false,
  });

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'captured': captured,
        'promotesToKing': promotesToKing,
      };

  factory CheckersMove.fromJson(Map<String, dynamic> json) => CheckersMove(
        from: json['from'] as int,
        to: json['to'] as int,
        captured: List<int>.from(json['captured'] ?? []),
        promotesToKing: json['promotesToKing'] == true,
      );
}

class CheckersBoard {
  List<CheckersPiece?> squares;
  CheckersPlayer currentPlayer;
  int movesWithoutCapture;

  CheckersBoard({
    List<CheckersPiece?>? squares,
    this.currentPlayer = CheckersPlayer.dark,
    this.movesWithoutCapture = 0,
  }) : squares = squares ?? List<CheckersPiece?>.filled(64, null);

  factory CheckersBoard.initial() {
    final board = CheckersBoard();
    // Dark pieces: rows 0-2 on dark squares
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 8; col++) {
        if ((row + col) % 2 == 1) {
          board.squares[row * 8 + col] =
              const CheckersPiece(owner: CheckersPlayer.dark);
        }
      }
    }
    // Light pieces: rows 5-7 on dark squares
    for (int row = 5; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        if ((row + col) % 2 == 1) {
          board.squares[row * 8 + col] =
              const CheckersPiece(owner: CheckersPlayer.light);
        }
      }
    }
    return board;
  }

  int _row(int i) => i ~/ 8;
  int _col(int i) => i % 8;
  int _idx(int r, int c) => r * 8 + c;

  bool _inBounds(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

  bool _promotes(CheckersPlayer player, int row) {
    return (player == CheckersPlayer.dark && row == 7) ||
        (player == CheckersPlayer.light && row == 0);
  }

  /// Find capture chains recursively from [pos] for [player].
  List<CheckersMove> _capturesFrom(int pos, CheckersPlayer player,
      {bool isKing = false, List<int>? alreadyCaptured}) {
    alreadyCaptured ??= [];
    final r = _row(pos);
    final c = _col(pos);
    final piece = squares[pos];
    final king = isKing || (piece?.isKing ?? false);

    // Directions: forward depends on player; kings go both ways
    List<int> rowDirs;
    if (king) {
      rowDirs = [-1, 1];
    } else if (player == CheckersPlayer.dark) {
      rowDirs = [1];
    } else {
      rowDirs = [-1];
    }
    final colDirs = [-1, 1];

    List<CheckersMove> moves = [];

    for (final dr in rowDirs) {
      for (final dc in colDirs) {
        final midR = r + dr;
        final midC = c + dc;
        final landR = r + 2 * dr;
        final landC = c + 2 * dc;

        if (!_inBounds(landR, landC)) continue;

        final midIdx = _idx(midR, midC);
        final landIdx = _idx(landR, landC);

        if (alreadyCaptured.contains(midIdx)) continue;

        final midPiece = squares[midIdx];
        if (midPiece == null || midPiece.owner == player) continue;
        if (squares[landIdx] != null && landIdx != pos) continue;

        // Valid capture step
        final newCaptured = [...alreadyCaptured, midIdx];
        final willPromote = _promotes(player, landR);
        final continueAsKing = king || willPromote;

        // Temporarily move piece to look for further captures
        final origLand = squares[landIdx];
        final origMid = squares[midIdx];
        final origPos = squares[pos];
        squares[landIdx] = origPos;
        squares[midIdx] = null;
        squares[pos] = null;

        final further = _capturesFrom(landIdx, player,
            isKing: continueAsKing, alreadyCaptured: newCaptured);

        // Restore
        squares[pos] = origPos;
        squares[midIdx] = origMid;
        squares[landIdx] = origLand;

        if (further.isEmpty) {
          moves.add(CheckersMove(
            from: pos,
            to: landIdx,
            captured: newCaptured,
            promotesToKing: willPromote && !king,
          ));
        } else {
          for (final fm in further) {
            moves.add(CheckersMove(
              from: pos,
              to: fm.to,
              captured: fm.captured,
              promotesToKing: fm.promotesToKing || (willPromote && !king),
            ));
          }
        }
      }
    }
    return moves;
  }

  List<CheckersMove> legalMoves(CheckersPlayer player) {
    List<CheckersMove> captures = [];
    List<CheckersMove> nonCaptures = [];

    for (int i = 0; i < 64; i++) {
      final piece = squares[i];
      if (piece == null || piece.owner != player) continue;

      // Captures
      final c = _capturesFrom(i, player);
      captures.addAll(c);

      // Non-captures
      final r = _row(i);
      final col = _col(i);
      List<int> rowDirs;
      if (piece.isKing) {
        rowDirs = [-1, 1];
      } else if (player == CheckersPlayer.dark) {
        rowDirs = [1];
      } else {
        rowDirs = [-1];
      }

      for (final dr in rowDirs) {
        for (final dc in [-1, 1]) {
          final nr = r + dr;
          final nc = col + dc;
          if (!_inBounds(nr, nc)) continue;
          final ni = _idx(nr, nc);
          if (squares[ni] != null) continue;
          nonCaptures.add(CheckersMove(
            from: i,
            to: ni,
            promotesToKing: _promotes(player, nr) && !piece.isKing,
          ));
        }
      }
    }

    // Mandatory capture rule
    if (captures.isNotEmpty) return captures;
    return nonCaptures;
  }

  void makeMove(CheckersMove move) {
    final piece = squares[move.from]!;
    squares[move.from] = null;

    // Remove captured pieces
    for (final idx in move.captured) {
      squares[idx] = null;
    }

    // Place piece, promote if needed
    if (move.promotesToKing || piece.isKing) {
      squares[move.to] = CheckersPiece(owner: piece.owner, isKing: true);
    } else {
      squares[move.to] = piece;
    }

    if (move.captured.isNotEmpty) {
      movesWithoutCapture = 0;
    } else {
      movesWithoutCapture++;
    }

    currentPlayer = currentPlayer.opponent;
  }

  bool isGameOver() {
    if (movesWithoutCapture >= 40) return true;
    return legalMoves(currentPlayer).isEmpty;
  }

  /// Returns winner, or null if draw.
  CheckersPlayer? winner() {
    if (movesWithoutCapture >= 40) return null;
    if (legalMoves(currentPlayer).isEmpty) return currentPlayer.opponent;
    return null;
  }

  CheckersBoard copy() {
    return CheckersBoard(
      squares: List<CheckersPiece?>.from(squares),
      currentPlayer: currentPlayer,
      movesWithoutCapture: movesWithoutCapture,
    );
  }

  Map<String, dynamic> toJson() => {
        'squares': squares
            .map((p) => p?.toJson())
            .toList(),
        'currentPlayer': currentPlayer.name,
        'movesWithoutCapture': movesWithoutCapture,
      };

  factory CheckersBoard.fromJson(Map<String, dynamic> json) {
    final sq = (json['squares'] as List).map((e) {
      if (e == null) return null;
      return CheckersPiece.fromJson(Map<String, dynamic>.from(e));
    }).toList();
    return CheckersBoard(
      squares: sq,
      currentPlayer: json['currentPlayer'] == 'dark'
          ? CheckersPlayer.dark
          : CheckersPlayer.light,
      movesWithoutCapture: json['movesWithoutCapture'] as int? ?? 0,
    );
  }
}
