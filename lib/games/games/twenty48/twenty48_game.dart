// lib/games/games/twenty48/twenty48_game.dart

import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class Twenty48Game extends StatefulWidget {
  final gc.GameContext gameContext;
  const Twenty48Game({super.key, required this.gameContext});

  @override
  State<Twenty48Game> createState() => Twenty48GameState();
}

class Twenty48GameState extends State<Twenty48Game> implements GameInterface {
  late List<List<int>> _grid;
  late Random _rng;
  int _score = 0;
  bool _gameOver = false;
  bool _won = false;

  gc.GameContext get _ctx => widget.gameContext;

  @override
  String get gameId => 'twenty48';

  @override
  void initState() {
    super.initState();
    _rng = Random(_ctx.gameSeed.hashCode);
    _grid = List.generate(4, (_) => List.filled(4, 0));
    _spawnTile();
    _spawnTile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _spawnTile() {
    final empty = <List<int>>[];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (_grid[r][c] == 0) empty.add([r, c]);
      }
    }
    if (empty.isEmpty) return;
    final cell = empty[_rng.nextInt(empty.length)];
    _grid[cell[0]][cell[1]] = _rng.nextDouble() < 0.9 ? 2 : 4;
  }

  bool _canMove() {
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (_grid[r][c] == 0) return true;
        if (c < 3 && _grid[r][c] == _grid[r][c + 1]) return true;
        if (r < 3 && _grid[r][c] == _grid[r + 1][c]) return true;
      }
    }
    return false;
  }

  List<int> _slideAndMerge(List<int> row) {
    // Remove zeros
    final tiles = row.where((v) => v != 0).toList();
    final result = <int>[];
    int i = 0;
    while (i < tiles.length) {
      if (i + 1 < tiles.length && tiles[i] == tiles[i + 1]) {
        final merged = tiles[i] * 2;
        result.add(merged);
        _score += merged;
        if (merged == 2048 && !_won) _won = true;
        i += 2;
      } else {
        result.add(tiles[i]);
        i += 1;
      }
    }
    while (result.length < 4) {
      result.add(0);
    }
    return result;
  }

  bool _swipe(String direction) {
    final oldGrid = _grid.map((r) => List<int>.from(r)).toList();
    bool changed = false;

    switch (direction) {
      case 'left':
        for (int r = 0; r < 4; r++) {
          _grid[r] = _slideAndMerge(_grid[r]);
        }
        break;
      case 'right':
        for (int r = 0; r < 4; r++) {
          _grid[r] = _slideAndMerge(_grid[r].reversed.toList()).reversed.toList();
        }
        break;
      case 'up':
        for (int c = 0; c < 4; c++) {
          final col = [_grid[0][c], _grid[1][c], _grid[2][c], _grid[3][c]];
          final merged = _slideAndMerge(col);
          for (int r = 0; r < 4; r++) {
            _grid[r][c] = merged[r];
          }
        }
        break;
      case 'down':
        for (int c = 0; c < 4; c++) {
          final col = [_grid[3][c], _grid[2][c], _grid[1][c], _grid[0][c]];
          final merged = _slideAndMerge(col);
          for (int r = 0; r < 4; r++) {
            _grid[3 - r][c] = merged[r];
          }
        }
        break;
    }

    // Check if anything changed
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (oldGrid[r][c] != _grid[r][c]) {
          changed = true;
          break;
        }
      }
      if (changed) break;
    }

    return changed;
  }

  void _handleSwipe(String direction) {
    if (_gameOver) return;
    final changed = _swipe(direction);
    if (changed) {
      _spawnTile();
      if (!_canMove()) {
        _gameOver = true;
        _endGame();
      }
    }
    setState(() {});
  }

  void _endGame() {
    final winnerId = (_ctx.mode == GameMode.practice)
        ? (_score > 0 ? _ctx.userId : null)
        : _ctx.userId;
    _ctx.onGameComplete({
      'winner_id': winnerId,
      'player_1_score': _score,
      'player_2_score': 0,
    });
  }

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {}

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    final grid = savedState['grid'];
    if (grid is List) {
      setState(() {
        for (int r = 0; r < 4; r++) {
          for (int c = 0; c < 4; c++) {
            _grid[r][c] = (grid[r] as List)[c] as int;
          }
        }
        _score = savedState['score'] as int? ?? 0;
      });
    }
  }

  @override
  Map<String, dynamic> getCurrentState() {
    return {
      'grid': _grid.map((r) => List<int>.from(r)).toList(),
      'score': _score,
    };
  }

  Color _tileColor(int value) {
    switch (value) {
      case 0:
        return const Color(0xFFCDC1B4);
      case 2:
        return const Color(0xFFEEE4DA);
      case 4:
        return const Color(0xFFEDE0C8);
      case 8:
        return const Color(0xFFF2B179);
      case 16:
        return const Color(0xFFF59563);
      case 32:
        return const Color(0xFFF67C5F);
      case 64:
        return const Color(0xFFF65E3B);
      case 128:
        return const Color(0xFFEDCF72);
      case 256:
        return const Color(0xFFEDCC61);
      case 512:
        return const Color(0xFFEDC850);
      case 1024:
        return const Color(0xFFEDC53F);
      case 2048:
        return const Color(0xFFEDC22E);
      default:
        return const Color(0xFF3C3A32);
    }
  }

  Color _textColor(int value) {
    return value <= 4 ? _kPrimary : Colors.white;
  }

  double _fontSize(int value) {
    if (value < 100) return 28;
    if (value < 1000) return 22;
    return 18;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Expanded(child: _buildGrid()),
              if (_gameOver) ...[
                const SizedBox(height: 24),
                _buildGameOverCard(),
              ],
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
        const Text(
          '2048',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _kPrimary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                'Score',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                '$_score',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return GestureDetector(
      onPanEnd: (details) {
        final v = details.velocity.pixelsPerSecond;
        if (v.dx.abs() > v.dy.abs()) {
          _handleSwipe(v.dx > 0 ? 'right' : 'left');
        } else {
          _handleSwipe(v.dy > 0 ? 'down' : 'up');
        }
      },
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFBBADA0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: 16,
              itemBuilder: (context, index) {
                final r = index ~/ 4;
                final c = index % 4;
                final value = _grid[r][c];
                return Container(
                  decoration: BoxDecoration(
                    color: _tileColor(value),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: value > 0
                      ? Text(
                          '$value',
                          style: TextStyle(
                            fontSize: _fontSize(value),
                            fontWeight: FontWeight.bold,
                            color: _textColor(value),
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverCard() {
    return Column(
      children: [
        Text(
          _won ? 'You Win!' : 'Game Over!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _kPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _won ? 'Umeshinda!' : 'Mchezo Umekwisha!',
          style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
        ),
        const SizedBox(height: 16),
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
    );
  }
}
