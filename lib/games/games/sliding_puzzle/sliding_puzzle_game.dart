// lib/games/games/sliding_puzzle/sliding_puzzle_game.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_interface.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class SlidingPuzzleGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const SlidingPuzzleGame({super.key, required this.gameContext});

  @override
  State<SlidingPuzzleGame> createState() => SlidingPuzzleGameState();
}

class SlidingPuzzleGameState extends State<SlidingPuzzleGame>
    implements GameInterface {
  late Random _rng;
  gc.GameContext get _ctx => widget.gameContext;

  // 16 values: 1-15 are tiles, 0 is the blank
  // Index = position in row-major 4x4 grid
  late List<int> _tiles;
  int _moves = 0;
  int _elapsedSeconds = 0;
  bool _gameOver = false;
  bool _solved = false;
  Timer? _timer;

  @override
  String get gameId => 'sliding_puzzle';

  @override
  void initState() {
    super.initState();
    _rng = Random(_ctx.gameSeed.hashCode);
    _tiles = _generateSolvable();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Generate a solvable 15-puzzle configuration.
  List<int> _generateSolvable() {
    final tiles = List.generate(16, (i) => i); // 0=blank, 1-15
    // Shuffle using seeded random
    for (int i = tiles.length - 1; i > 0; i--) {
      final j = _rng.nextInt(i + 1);
      final tmp = tiles[i];
      tiles[i] = tiles[j];
      tiles[j] = tmp;
    }

    // Ensure solvable: count inversions among non-zero tiles
    if (!_isSolvable(tiles)) {
      // Swap two non-blank tiles to fix parity
      final nonBlank = <int>[];
      for (int i = 0; i < tiles.length; i++) {
        if (tiles[i] != 0) nonBlank.add(i);
      }
      // Swap the first two non-blank tiles
      final tmp = tiles[nonBlank[0]];
      tiles[nonBlank[0]] = tiles[nonBlank[1]];
      tiles[nonBlank[1]] = tmp;
    }

    // Don't start already solved
    if (_checkSolved(tiles)) {
      // Swap tile at 0,0 and 0,1 (positions 0 and 1) if they're not blank
      int a = 0, b = 1;
      if (tiles[a] == 0) a = 2;
      if (tiles[b] == 0) b = 2;
      final tmp = tiles[a];
      tiles[a] = tiles[b];
      tiles[b] = tmp;
    }

    return tiles;
  }

  /// A 15-puzzle is solvable iff:
  /// (inversions is even AND blank is on an even row from bottom) OR
  /// (inversions is odd AND blank is on an odd row from bottom)
  bool _isSolvable(List<int> tiles) {
    int inversions = 0;
    final flat = <int>[];
    for (final t in tiles) {
      if (t != 0) flat.add(t);
    }
    for (int i = 0; i < flat.length; i++) {
      for (int j = i + 1; j < flat.length; j++) {
        if (flat[i] > flat[j]) inversions++;
      }
    }

    final blankPos = tiles.indexOf(0);
    final blankRow = blankPos ~/ 4;
    final blankRowFromBottom = 3 - blankRow; // 0-indexed from bottom

    // Even inversions + blank on odd row from bottom (1-indexed) = solvable
    // Equivalently: inversions + blankRowFromBottom must be odd
    return (inversions + blankRowFromBottom) % 2 == 1;
  }

  bool _checkSolved(List<int> tiles) {
    for (int i = 0; i < 15; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return tiles[15] == 0;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _onTileTap(int position) {
    if (_gameOver) return;

    final blankPos = _tiles.indexOf(0);

    // Check adjacency (same row +-1 col, or same col +-1 row)
    final tileRow = position ~/ 4;
    final tileCol = position % 4;
    final blankRow = blankPos ~/ 4;
    final blankCol = blankPos % 4;

    final isAdjacent = (tileRow == blankRow && (tileCol - blankCol).abs() == 1) ||
        (tileCol == blankCol && (tileRow - blankRow).abs() == 1);

    if (!isAdjacent) return;

    setState(() {
      _tiles[blankPos] = _tiles[position];
      _tiles[position] = 0;
      _moves++;
    });

    if (_checkSolved(_tiles)) {
      _onSolved();
    }
  }

  void _onSolved() {
    _timer?.cancel();
    setState(() {
      _gameOver = true;
      _solved = true;
    });

    final moveScore = max(0, 500 - _moves);
    final timeBonus = _elapsedSeconds < 30
        ? 100
        : _elapsedSeconds < 60
            ? 50
            : _elapsedSeconds < 120
                ? 25
                : 0;
    final totalScore = moveScore + timeBonus;

    _ctx.onGameComplete({
      'winner_id': _ctx.userId,
      'player_1_score': totalScore,
      'player_2_score': 0,
    });
  }

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {}

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    final tilesData = savedState['tiles'] as List?;
    if (tilesData != null) {
      _tiles = tilesData.cast<int>();
    }
    _moves = savedState['moves'] as int? ?? 0;
    _elapsedSeconds = savedState['elapsed'] as int? ?? 0;
    setState(() {});
  }

  @override
  Map<String, dynamic> getCurrentState() {
    return {
      'tiles': _tiles,
      'moves': _moves,
      'elapsed': _elapsedSeconds,
    };
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_gameOver) return _buildGameOver();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(),
              const Spacer(),
              _buildGrid(),
              const Spacer(),
              _buildHint(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Moves: $_moves',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            _formatTime(_elapsedSeconds),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: _kPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gridSize = constraints.maxWidth;
          final tileSize = (gridSize - 12) / 4; // 4px gaps

          return Stack(
            children: List.generate(16, (index) {
              final value = _tiles[index];
              if (value == 0) return const SizedBox.shrink();

              final row = index ~/ 4;
              final col = index % 4;
              final x = col * (tileSize + 4);
              final y = row * (tileSize + 4);

              // Determine if tile is in correct position
              final isCorrect = value == index + 1;

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                left: x,
                top: y,
                width: tileSize,
                height: tileSize,
                child: GestureDetector(
                  onTap: () => _onTileTap(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Colors.grey.shade50
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCorrect
                            ? Colors.green.shade200
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$value',
                        style: TextStyle(
                          fontSize: tileSize * 0.35,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildHint() {
    return const Text(
      'Arrange tiles 1-15 in order\nPanga vigae 1-15 kwa mpangilio',
      style: TextStyle(fontSize: 13, color: _kSecondary),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildGameOver() {
    final moveScore = max(0, 500 - _moves);
    final timeBonus = _elapsedSeconds < 30
        ? 100
        : _elapsedSeconds < 60
            ? 50
            : _elapsedSeconds < 120
                ? 25
                : 0;
    final totalScore = moveScore + timeBonus;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _solved
                      ? Icons.emoji_events_rounded
                      : Icons.swap_calls_rounded,
                  size: 64,
                  color: _kPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  _solved ? 'Solved!' : 'Game Over',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary,
                  ),
                ),
                Text(
                  _solved ? 'Umetatua!' : 'Mchezo Umekwisha',
                  style: const TextStyle(fontSize: 14, color: _kSecondary),
                ),
                const SizedBox(height: 24),
                Text(
                  '$totalScore',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary,
                  ),
                ),
                const Text(
                  'points / pointi',
                  style: TextStyle(fontSize: 14, color: _kSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_moves moves in ${_formatTime(_elapsedSeconds)}',
                  style: const TextStyle(fontSize: 14, color: _kSecondary),
                ),
                if (_solved) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Move score: $moveScore + Time bonus: $timeBonus',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Done / Maliza'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
