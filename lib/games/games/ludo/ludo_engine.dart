// lib/games/games/ludo/ludo_engine.dart
// Pure Dart — no Flutter imports.
//
// 2-player Ludo. 52 main path squares indexed 0-51.
// Player 1 starts at 0, home entry after 50 → home[0..5].
// Player 2 starts at 26, home entry after 24 → home[0..5].
// Safe squares: 0, 8, 13, 21, 26, 34, 39, 47.

import 'dart:math';

enum LudoTokenState { home, active, finished }

class LudoToken {
  LudoTokenState state;
  int position; // main path index when active, home column index (0-5) when in home column
  int homeProgress; // 0 = not in home column, 1-6 = in home column

  LudoToken({
    this.state = LudoTokenState.home,
    this.position = -1,
    this.homeProgress = 0,
  });

  LudoToken copy() => LudoToken(
        state: state,
        position: position,
        homeProgress: homeProgress,
      );

  Map<String, dynamic> toJson() => {
        'state': state.name,
        'position': position,
        'homeProgress': homeProgress,
      };

  factory LudoToken.fromJson(Map<String, dynamic> json) => LudoToken(
        state: LudoTokenState.values.firstWhere((v) => v.name == json['state']),
        position: json['position'] as int,
        homeProgress: json['homeProgress'] as int? ?? 0,
      );
}

class LudoMove {
  final int player;
  final int tokenIndex;
  final int diceValue;

  const LudoMove({
    required this.player,
    required this.tokenIndex,
    required this.diceValue,
  });

  Map<String, dynamic> toJson() => {
        'player': player,
        'tokenIndex': tokenIndex,
        'diceValue': diceValue,
      };

  factory LudoMove.fromJson(Map<String, dynamic> json) => LudoMove(
        player: json['player'] as int,
        tokenIndex: json['tokenIndex'] as int,
        diceValue: json['diceValue'] as int,
      );
}

class LudoBoard {
  // Player 1 = index 0, Player 2 = index 1
  List<List<LudoToken>> tokens; // [4 tokens for p1, 4 tokens for p2]
  int currentPlayer; // 0 or 1
  int? lastDice;
  int consecutiveSixes;

  static const List<int> startSquares = [0, 26];
  static const List<int> homeEntrySquares = [50, 24];
  static const List<int> safeSquares = [0, 8, 13, 21, 26, 34, 39, 47];
  static const int pathLength = 52;

  LudoBoard({
    List<List<LudoToken>>? tokens,
    this.currentPlayer = 0,
    this.lastDice,
    this.consecutiveSixes = 0,
  }) : tokens = tokens ??
            [
              List.generate(4, (_) => LudoToken()),
              List.generate(4, (_) => LudoToken()),
            ];

  int rollDice(Random rng) {
    final value = rng.nextInt(6) + 1;
    lastDice = value;
    return value;
  }

  int _distanceToHomeEntry(int player, int currentPos) {
    final homeEntry = homeEntrySquares[player];
    if (currentPos <= homeEntry) {
      return homeEntry - currentPos;
    }
    return pathLength - currentPos + homeEntry;
  }

  List<LudoMove> legalMoves(int player, int dice) {
    final moves = <LudoMove>[];
    final playerTokens = tokens[player];

    for (int i = 0; i < 4; i++) {
      final token = playerTokens[i];

      if (token.state == LudoTokenState.finished) continue;

      if (token.state == LudoTokenState.home) {
        // Can exit home only with a 6
        if (dice == 6) {
          moves.add(LudoMove(player: player, tokenIndex: i, diceValue: dice));
        }
        continue;
      }

      if (token.state == LudoTokenState.active) {
        if (token.homeProgress > 0) {
          // In home column — needs exact roll to finish (reach position 6)
          final newProgress = token.homeProgress + dice;
          if (newProgress <= 6) {
            moves.add(LudoMove(player: player, tokenIndex: i, diceValue: dice));
          }
          continue;
        }

        // On main path
        final dist = _distanceToHomeEntry(player, token.position);
        if (dice <= dist) {
          // Normal move on main path
          moves.add(LudoMove(player: player, tokenIndex: i, diceValue: dice));
        } else {
          // Entering home column
          final homeSteps = dice - dist;
          if (homeSteps <= 6) {
            moves.add(LudoMove(player: player, tokenIndex: i, diceValue: dice));
          }
        }
      }
    }

    return moves;
  }

  void makeMove(LudoMove move) {
    final token = tokens[move.player][move.tokenIndex];

    if (token.state == LudoTokenState.home && move.diceValue == 6) {
      // Exit home
      token.state = LudoTokenState.active;
      token.position = startSquares[move.player];
      token.homeProgress = 0;
      _checkCapture(move.player, token.position);
    } else if (token.state == LudoTokenState.active) {
      if (token.homeProgress > 0) {
        // In home column
        token.homeProgress += move.diceValue;
        if (token.homeProgress >= 6) {
          token.state = LudoTokenState.finished;
        }
      } else {
        // On main path
        final dist = _distanceToHomeEntry(move.player, token.position);
        if (move.diceValue <= dist) {
          token.position = (token.position + move.diceValue) % pathLength;
          _checkCapture(move.player, token.position);
        } else {
          // Enter home column
          final homeSteps = move.diceValue - dist;
          token.homeProgress = homeSteps;
          token.position = -1;
          if (token.homeProgress >= 6) {
            token.state = LudoTokenState.finished;
          }
        }
      }
    }

    // Bonus turn for 6 (max 3 consecutive)
    if (move.diceValue == 6) {
      consecutiveSixes++;
      if (consecutiveSixes >= 3) {
        // Forfeit turn after 3 sixes
        consecutiveSixes = 0;
        currentPlayer = 1 - currentPlayer;
      }
      // else: same player goes again
    } else {
      consecutiveSixes = 0;
      currentPlayer = 1 - currentPlayer;
    }
  }

  void _checkCapture(int player, int position) {
    if (safeSquares.contains(position)) return;

    final opponent = 1 - player;
    for (final token in tokens[opponent]) {
      if (token.state == LudoTokenState.active &&
          token.homeProgress == 0 &&
          token.position == position) {
        token.state = LudoTokenState.home;
        token.position = -1;
      }
    }
  }

  bool isGameOver() {
    for (int p = 0; p < 2; p++) {
      if (tokens[p].every((t) => t.state == LudoTokenState.finished)) {
        return true;
      }
    }
    return false;
  }

  int? winner() {
    for (int p = 0; p < 2; p++) {
      if (tokens[p].every((t) => t.state == LudoTokenState.finished)) {
        return p;
      }
    }
    return null;
  }

  LudoBoard copy() {
    return LudoBoard(
      tokens: tokens.map((pt) => pt.map((t) => t.copy()).toList()).toList(),
      currentPlayer: currentPlayer,
      lastDice: lastDice,
      consecutiveSixes: consecutiveSixes,
    );
  }

  Map<String, dynamic> toJson() => {
        'tokens': tokens
            .map((pt) => pt.map((t) => t.toJson()).toList())
            .toList(),
        'currentPlayer': currentPlayer,
        'lastDice': lastDice,
        'consecutiveSixes': consecutiveSixes,
      };

  factory LudoBoard.fromJson(Map<String, dynamic> json) {
    final tokensJson = json['tokens'] as List;
    final tokens = tokensJson
        .map((pt) => (pt as List)
            .map((t) => LudoToken.fromJson(Map<String, dynamic>.from(t)))
            .toList())
        .toList();
    return LudoBoard(
      tokens: tokens,
      currentPlayer: json['currentPlayer'] as int,
      lastDice: json['lastDice'] as int?,
      consecutiveSixes: json['consecutiveSixes'] as int? ?? 0,
    );
  }
}
