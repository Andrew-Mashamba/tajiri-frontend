// lib/games/games/chess/chess_game.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kLightSquare = Color(0xFFF0D9B5);
const Color _kDarkSquare = Color(0xFFB58863);

class ChessGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const ChessGame({super.key, required this.gameContext});

  @override
  State<ChessGame> createState() => ChessGameState();
}

class ChessGameState extends State<ChessGame> implements GameInterface {
  late chess_lib.Chess _game;
  late Random _rng;
  String? _selectedSquare;
  List<String> _legalTargets = [];
  bool _gameOver = false;
  bool _isPlayerWhite = true;
  int _player1TimeMs = 300000; // 5 min
  int _player2TimeMs = 300000;
  Timer? _clockTimer;

  gc.GameContext get _ctx => widget.gameContext;

  @override
  String get gameId => 'chess';

  bool get _isMyTurn {
    final whiteToMove = _game.turn == chess_lib.Color.WHITE;
    return _isPlayerWhite ? whiteToMove : !whiteToMove;
  }

  @override
  void initState() {
    super.initState();
    _rng = Random(_ctx.gameSeed.hashCode);
    _isPlayerWhite = true; // Player 1 is white
    if (_ctx.gameState != null) {
      final fen = _ctx.gameState!['fen'] as String?;
      _game = fen != null ? chess_lib.Chess.fromFEN(fen) : chess_lib.Chess();
      _player1TimeMs = _ctx.gameState!['p1_time'] as int? ?? 300000;
      _player2TimeMs = _ctx.gameState!['p2_time'] as int? ?? 300000;
    } else {
      _game = chess_lib.Chess();
    }
    _startClock();
    _ctx.setOnOpponentMove(onOpponentMove);
    if (!_isMyTurn && _ctx.mode == GameMode.practice) {
      _scheduleAiMove();
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_gameOver) return;
      setState(() {
        final whiteToMove = _game.turn == chess_lib.Color.WHITE;
        if (whiteToMove) {
          _player1TimeMs = (_player1TimeMs - 100).clamp(0, 999999);
        } else {
          _player2TimeMs = (_player2TimeMs - 100).clamp(0, 999999);
        }
        if (_player1TimeMs <= 0 || _player2TimeMs <= 0) {
          _gameOver = true;
          _clockTimer?.cancel();
          final winnerId = _player1TimeMs <= 0
              ? (_ctx.opponentId ?? 0)
              : _ctx.userId;
          _ctx.onGameComplete({
            'winner_id': winnerId,
            'player_1_score': _player1TimeMs <= 0 ? 0 : 1,
            'player_2_score': _player2TimeMs <= 0 ? 0 : 1,
          });
        }
      });
    });
  }

  void _scheduleAiMove() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _gameOver) return;
      final moves = _game.moves();
      if (moves.isEmpty) {
        _checkGameOver();
        return;
      }
      final moveStr = moves[_rng.nextInt(moves.length)] as String;
      _game.move(moveStr);
      setState(() {});
      _checkGameOver();
    });
  }

  String _formatTime(int ms) {
    final secs = ms ~/ 1000;
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // Convert row,col to algebraic notation
  String _toAlgebraic(int row, int col) {
    final file = String.fromCharCode('a'.codeUnitAt(0) + col);
    final rank = (8 - row).toString();
    return '$file$rank';
  }

  // Convert algebraic to row,col
  (int, int) _fromAlgebraic(String sq) {
    final col = sq.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(sq[1]);
    return (row, col);
  }

  void _onSquareTap(int row, int col) {
    if (_gameOver || !_isMyTurn) return;

    // If board is flipped for black
    final actualRow = _isPlayerWhite ? row : (7 - row);
    final actualCol = _isPlayerWhite ? col : (7 - col);
    final sq = _toAlgebraic(actualRow, actualCol);

    // Tapping a legal target
    if (_selectedSquare != null && _legalTargets.contains(sq)) {
      _makePlayerMove(_selectedSquare!, sq);
      return;
    }

    // Selecting a piece
    final piece = _game.get(sq);
    if (piece != null) {
      final isMyPiece = (_isPlayerWhite && piece.color == chess_lib.Color.WHITE) ||
          (!_isPlayerWhite && piece.color == chess_lib.Color.BLACK);
      if (isMyPiece) {
        final movesRaw = _game.moves({'square': sq, 'verbose': true});
        final targets = <String>[];
        for (final m in movesRaw) {
          if (m is Map) {
            targets.add(m['to'] as String);
          }
        }
        setState(() {
          _selectedSquare = sq;
          _legalTargets = targets;
        });
        return;
      }
    }

    setState(() {
      _selectedSquare = null;
      _legalTargets = [];
    });
  }

  void _makePlayerMove(String from, String to) {
    // Check for pawn promotion
    final piece = _game.get(from);
    final (toRow, _) = _fromAlgebraic(to);
    final isPromotion = piece != null &&
        piece.type == chess_lib.PieceType.PAWN &&
        (toRow == 0 || toRow == 7);

    if (isPromotion) {
      _showPromotionDialog(from, to);
      return;
    }

    final result = _game.move({'from': from, 'to': to});
    if (result) {
      setState(() {
        _selectedSquare = null;
        _legalTargets = [];
      });
      _sendMove(from, to, null);
      _checkGameOver();
      if (!_gameOver && _ctx.mode == GameMode.practice) {
        _scheduleAiMove();
      }
    }
  }

  void _showPromotionDialog(String from, String to) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['q', 'r', 'b', 'n'].map((p) {
              final labels = {'q': 'Queen', 'r': 'Rook', 'b': 'Bishop', 'n': 'Knight'};
              final symbols = _isPlayerWhite
                  ? {'q': '\u2655', 'r': '\u2656', 'b': '\u2657', 'n': '\u2658'}
                  : {'q': '\u265B', 'r': '\u265C', 'b': '\u265D', 'n': '\u265E'};
              return GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  final result =
                      _game.move({'from': from, 'to': to, 'promotion': p});
                  if (result) {
                    setState(() {
                      _selectedSquare = null;
                      _legalTargets = [];
                    });
                    _sendMove(from, to, p);
                    _checkGameOver();
                    if (!_gameOver && _ctx.mode == GameMode.practice) {
                      _scheduleAiMove();
                    }
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(symbols[p]!, style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 4),
                    Text(labels[p]!, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _checkGameOver() {
    if (_game.game_over) {
      setState(() => _gameOver = true);
      _clockTimer?.cancel();
      int winnerId = 0;
      int p1 = 0, p2 = 0;
      if (_game.in_checkmate) {
        // Loser is the one whose turn it is
        final loserIsWhite = _game.turn == chess_lib.Color.WHITE;
        if (_isPlayerWhite) {
          winnerId = loserIsWhite ? (_ctx.opponentId ?? 0) : _ctx.userId;
          p1 = loserIsWhite ? 0 : 1;
          p2 = loserIsWhite ? 1 : 0;
        } else {
          winnerId = loserIsWhite ? _ctx.userId : (_ctx.opponentId ?? 0);
          p1 = loserIsWhite ? 0 : 1;
          p2 = loserIsWhite ? 1 : 0;
        }
      }
      _ctx.onGameComplete({
        'winner_id': winnerId,
        'player_1_score': p1,
        'player_2_score': p2,
      });
    }
  }

  void _sendMove(String from, String to, String? promotion) {
    _ctx.socketService.sendMove(_ctx.userId, {
      'type': 'move',
      'from': from,
      'to': to,
      'promotion': promotion,
      'fen': _game.fen,
      'p1_time': _player1TimeMs,
      'p2_time': _player2TimeMs,
    });
  }

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {
    final from = moveData['from'] as String?;
    final to = moveData['to'] as String?;
    final promotion = moveData['promotion'] as String?;
    if (from != null && to != null) {
      final moveMap = <String, String>{'from': from, 'to': to};
      if (promotion != null) moveMap['promotion'] = promotion;
      _game.move(moveMap);
      if (moveData['p1_time'] != null) {
        _player1TimeMs = moveData['p1_time'] as int;
      }
      if (moveData['p2_time'] != null) {
        _player2TimeMs = moveData['p2_time'] as int;
      }
      setState(() {});
      _checkGameOver();
    }
  }

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    final fen = savedState['fen'] as String?;
    if (fen != null) {
      setState(() {
        _game = chess_lib.Chess.fromFEN(fen);
        _player1TimeMs = savedState['p1_time'] as int? ?? _player1TimeMs;
        _player2TimeMs = savedState['p2_time'] as int? ?? _player2TimeMs;
      });
    }
  }

  @override
  Map<String, dynamic> getCurrentState() => {
        'fen': _game.fen,
        'p1_time': _player1TimeMs,
        'p2_time': _player2TimeMs,
      };

  String _pieceToUnicode(chess_lib.Piece piece) {
    final white = piece.color == chess_lib.Color.WHITE;
    switch (piece.type) {
      case chess_lib.PieceType.KING:
        return white ? '\u2654' : '\u265A';
      case chess_lib.PieceType.QUEEN:
        return white ? '\u2655' : '\u265B';
      case chess_lib.PieceType.ROOK:
        return white ? '\u2656' : '\u265C';
      case chess_lib.PieceType.BISHOP:
        return white ? '\u2657' : '\u265D';
      case chess_lib.PieceType.KNIGHT:
        return white ? '\u2658' : '\u265E';
      case chess_lib.PieceType.PAWN:
        return white ? '\u2659' : '\u265F';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildClockBar(),
        const SizedBox(height: 8),
        _buildBoard(),
        const SizedBox(height: 8),
        _buildClockBarBottom(),
        if (_gameOver) ...[
          const SizedBox(height: 12),
          _buildGameOverBanner(),
        ],
      ],
    );
  }

  Widget _buildClockBar() {
    // Top = opponent
    final opponentTime =
        _isPlayerWhite ? _player2TimeMs : _player1TimeMs;
    final opponentActive = !_isMyTurn && !_gameOver;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            _ctx.opponentName ?? 'AI',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: opponentActive ? _kPrimary : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _formatTime(opponentTime),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                color: opponentActive ? Colors.white : _kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockBarBottom() {
    final myTime = _isPlayerWhite ? _player1TimeMs : _player2TimeMs;
    final myActive = _isMyTurn && !_gameOver;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            'You',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: myActive ? _kPrimary : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _formatTime(myTime),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                color: myActive ? Colors.white : _kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    // Find king in check
    String? kingInCheckSq;
    if (_game.in_check) {
      // Find current player's king
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          final sq = _toAlgebraic(r, c);
          final p = _game.get(sq);
          if (p != null &&
              p.type == chess_lib.PieceType.KING &&
              p.color == _game.turn) {
            kingInCheckSq = sq;
          }
        }
      }
    }

    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: _kPrimary, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
            ),
            itemCount: 64,
            itemBuilder: (context, index) {
              final displayRow = index ~/ 8;
              final displayCol = index % 8;
              final actualRow =
                  _isPlayerWhite ? displayRow : (7 - displayRow);
              final actualCol =
                  _isPlayerWhite ? displayCol : (7 - displayCol);
              final sq = _toAlgebraic(actualRow, actualCol);
              final piece = _game.get(sq);
              final isDark = (actualRow + actualCol) % 2 == 1;
              final isSelected = sq == _selectedSquare;
              final isTarget = _legalTargets.contains(sq);
              final isKingCheck = sq == kingInCheckSq;

              Color bgColor = isDark ? _kDarkSquare : _kLightSquare;
              if (isKingCheck) bgColor = Colors.red.shade300;
              if (isSelected) bgColor = Colors.blue.shade200;

              return GestureDetector(
                onTap: () => _onSquareTap(displayRow, displayCol),
                child: Container(
                  color: bgColor,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isTarget)
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (piece != null)
                        Text(
                          _pieceToUnicode(piece),
                          style: const TextStyle(fontSize: 28, height: 1),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverBanner() {
    String text;
    if (_game.in_checkmate) {
      text = _isMyTurn ? 'Checkmate - You lost' : 'Checkmate - You won!';
    } else if (_game.in_stalemate) {
      text = 'Stalemate - Draw';
    } else if (_player1TimeMs <= 0 || _player2TimeMs <= 0) {
      text = 'Time out';
    } else {
      text = 'Game over - Draw';
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
      ),
    );
  }
}
