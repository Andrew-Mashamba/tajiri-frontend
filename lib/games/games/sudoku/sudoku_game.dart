// lib/games/games/sudoku/sudoku_game.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';
import 'sudoku_engine.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class SudokuGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const SudokuGame({super.key, required this.gameContext});

  @override
  State<SudokuGame> createState() => SudokuGameState();
}

class SudokuGameState extends State<SudokuGame> implements GameInterface {
  late List<List<int>> _puzzle;
  late List<List<int>> _solution;
  late List<List<int>> _grid; // player's working grid
  late List<List<bool>> _isGiven; // true if cell was pre-filled

  int _selectedRow = -1;
  int _selectedCol = -1;
  int _secondsElapsed = 0;
  bool _gameOver = false;
  Timer? _timer;

  gc.GameContext get _ctx => widget.gameContext;

  @override
  String get gameId => 'sudoku';

  @override
  void initState() {
    super.initState();
    final data = SudokuEngine.generatePuzzle(
      _ctx.gameSeed.hashCode,
      'medium',
    );
    _puzzle = data['puzzle']!;
    _solution = data['solution']!;
    _grid = _puzzle.map((row) => List<int>.from(row)).toList();
    _isGiven = List.generate(
        9, (r) => List.generate(9, (c) => _puzzle[r][c] != 0));

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (!_gameOver) {
        setState(() => _secondsElapsed++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectCell(int row, int col) {
    if (_gameOver || _isGiven[row][col]) return;
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
    });
  }

  void _placeNumber(int num) {
    if (_gameOver || _selectedRow < 0 || _selectedCol < 0) return;
    if (_isGiven[_selectedRow][_selectedCol]) return;

    setState(() {
      _grid[_selectedRow][_selectedCol] = num;
    });

    // Check if complete
    if (SudokuEngine.checkComplete(_grid)) {
      _endGame();
    }
  }

  void _clearCell() {
    if (_gameOver || _selectedRow < 0 || _selectedCol < 0) return;
    if (_isGiven[_selectedRow][_selectedCol]) return;
    setState(() {
      _grid[_selectedRow][_selectedCol] = 0;
    });
  }

  void _endGame() {
    _timer?.cancel();
    setState(() => _gameOver = true);
    final score = (_secondsElapsed < 600)
        ? 600 - _secondsElapsed
        : 0;
    final winnerId = (_ctx.mode == GameMode.practice)
        ? (score > 0 ? _ctx.userId : null)
        : _ctx.userId;
    _ctx.onGameComplete({
      'winner_id': winnerId,
      'player_1_score': score,
      'player_2_score': 0,
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool _isCellInvalid(int row, int col) {
    final val = _grid[row][col];
    if (val == 0) return false;
    return val != _solution[row][col];
  }

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {}

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    final gridData = savedState['grid'] as List?;
    if (gridData != null) {
      setState(() {
        for (int r = 0; r < 9; r++) {
          final row = (gridData[r] as List).cast<int>();
          for (int c = 0; c < 9; c++) {
            _grid[r][c] = row[c];
          }
        }
        _secondsElapsed = savedState['seconds'] as int? ?? 0;
      });
    }
  }

  @override
  Map<String, dynamic> getCurrentState() {
    return {
      'grid': _grid,
      'seconds': _secondsElapsed,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_gameOver) return _buildGameOver();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildHeader(),
            const SizedBox(height: 12),
            Expanded(child: _buildGrid()),
            _buildNumberPad(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Sudoku Duel',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatTime(_secondsElapsed),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: _kPrimary, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: List.generate(9, (row) {
              return Expanded(
                child: Row(
                  children: List.generate(9, (col) {
                    final val = _grid[row][col];
                    final isSelected =
                        row == _selectedRow && col == _selectedCol;
                    final isGiven = _isGiven[row][col];
                    final isInvalid = !isGiven && _isCellInvalid(row, col);
                    final isSameValue = val != 0 &&
                        _selectedRow >= 0 &&
                        _grid[_selectedRow][_selectedCol] == val;

                    Color bg = Colors.white;
                    if (isSelected) {
                      bg = const Color(0xFFE0E0E0);
                    } else if (isSameValue) {
                      bg = const Color(0xFFF0F0F0);
                    }

                    // Highlight same row/col/box as selected
                    if (_selectedRow >= 0 && !isSelected) {
                      if (row == _selectedRow ||
                          col == _selectedCol ||
                          (row ~/ 3 == _selectedRow ~/ 3 &&
                              col ~/ 3 == _selectedCol ~/ 3)) {
                        bg = bg == Colors.white
                            ? const Color(0xFFF5F5F5)
                            : bg;
                      }
                    }

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _selectCell(row, col),
                        child: Container(
                          decoration: BoxDecoration(
                            color: bg,
                            border: Border(
                              right: BorderSide(
                                color: (col % 3 == 2 && col < 8)
                                    ? _kPrimary
                                    : Colors.grey.shade300,
                                width: (col % 3 == 2 && col < 8) ? 2 : 1,
                              ),
                              bottom: BorderSide(
                                color: (row % 3 == 2 && row < 8)
                                    ? _kPrimary
                                    : Colors.grey.shade300,
                                width: (row % 3 == 2 && row < 8) ? 2 : 1,
                              ),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: val == 0
                              ? null
                              : Text(
                                  '$val',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: isGiven
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isInvalid
                                        ? Colors.red
                                        : isGiven
                                            ? _kPrimary
                                            : const Color(0xFF1565C0),
                                  ),
                                ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ...List.generate(9, (i) {
            final num = i + 1;
            return GestureDetector(
              onTap: () => _placeNumber(num),
              child: Container(
                width: 34,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$num',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary),
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: _clearCell,
            child: Container(
              width: 34,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.backspace_outlined,
                  size: 18, color: _kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOver() {
    final score =
        (_secondsElapsed < 600) ? 600 - _secondsElapsed : 0;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded,
                    size: 64, color: _kPrimary),
                const SizedBox(height: 16),
                const Text('Puzzle Complete!',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary)),
                const SizedBox(height: 4),
                const Text('Fumbo Limekamilika!',
                    style: TextStyle(fontSize: 14, color: _kSecondary)),
                const SizedBox(height: 16),
                Text(_formatTime(_secondsElapsed),
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary)),
                const SizedBox(height: 8),
                Text('Score: $score',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _kSecondary)),
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
                          borderRadius: BorderRadius.circular(12)),
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
