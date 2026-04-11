// lib/games/games/snake/snake_game.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_interface.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

enum _Direction { up, down, left, right }

class _Point {
  final int x;
  final int y;
  const _Point(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is _Point && x == other.x && y == other.y;

  @override
  int get hashCode => x * 31 + y;
}

class SnakeGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const SnakeGame({super.key, required this.gameContext});

  @override
  State<SnakeGame> createState() => SnakeGameState();
}

class SnakeGameState extends State<SnakeGame> implements GameInterface {
  static const int gridSize = 20;
  static const int _baseIntervalMs = 200;
  static const int _minIntervalMs = 80;
  static const int _intervalDecrement = 10;

  gc.GameContext get _ctx => widget.gameContext;

  late List<_Point> _snake;
  late _Direction _direction;
  late _Direction _nextDirection;
  late _Point _food;
  late Random _rng;

  int _score = 0;
  int _foodEaten = 0;
  bool _gameOver = false;
  Timer? _gameTimer;

  @override
  String get gameId => 'snake';

  @override
  void initState() {
    super.initState();
    _rng = Random(_ctx.gameSeed.hashCode);
    _initGame();
    _startTimer();
    _ctx.setOnOpponentMove(onOpponentMove);
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _initGame() {
    // Start at center, length 3, moving right
    final cy = gridSize ~/ 2;
    final cx = gridSize ~/ 2;
    _snake = [
      _Point(cx, cy),
      _Point(cx - 1, cy),
      _Point(cx - 2, cy),
    ];
    _direction = _Direction.right;
    _nextDirection = _Direction.right;
    _spawnFood();
  }

  void _spawnFood() {
    final empty = <_Point>[];
    for (int x = 0; x < gridSize; x++) {
      for (int y = 0; y < gridSize; y++) {
        final p = _Point(x, y);
        if (!_snake.contains(p)) empty.add(p);
      }
    }
    if (empty.isEmpty) {
      _endGame();
      return;
    }
    _food = empty[_rng.nextInt(empty.length)];
  }

  void _startTimer() {
    _gameTimer?.cancel();
    final interval = max(
      _minIntervalMs,
      _baseIntervalMs - (_foodEaten * _intervalDecrement),
    );
    _gameTimer = Timer.periodic(Duration(milliseconds: interval), (_) {
      if (!mounted || _gameOver) {
        _gameTimer?.cancel();
        return;
      }
      _tick();
    });
  }

  void _tick() {
    _direction = _nextDirection;

    // Calculate new head
    final head = _snake.first;
    _Point newHead;
    switch (_direction) {
      case _Direction.up:
        newHead = _Point(head.x, head.y - 1);
      case _Direction.down:
        newHead = _Point(head.x, head.y + 1);
      case _Direction.left:
        newHead = _Point(head.x - 1, head.y);
      case _Direction.right:
        newHead = _Point(head.x + 1, head.y);
    }

    // Check wall collision
    if (newHead.x < 0 ||
        newHead.x >= gridSize ||
        newHead.y < 0 ||
        newHead.y >= gridSize) {
      _endGame();
      return;
    }

    // Check self collision
    if (_snake.contains(newHead)) {
      _endGame();
      return;
    }

    setState(() {
      _snake.insert(0, newHead);

      if (newHead == _food) {
        _score += 10;
        _foodEaten++;
        _spawnFood();
        // Speed up every 5 foods
        if (_foodEaten % 5 == 0) {
          _startTimer();
        }
      } else {
        _snake.removeLast();
      }
    });
  }

  void _changeDirection(_Direction newDir) {
    if (_gameOver) return;
    // Can't reverse
    if (_direction == _Direction.up && newDir == _Direction.down) return;
    if (_direction == _Direction.down && newDir == _Direction.up) return;
    if (_direction == _Direction.left && newDir == _Direction.right) return;
    if (_direction == _Direction.right && newDir == _Direction.left) return;
    _nextDirection = newDir;
  }

  void _endGame() {
    _gameTimer?.cancel();
    setState(() => _gameOver = true);

    // In practice mode both players play same seed, compare scores
    _ctx.onGameComplete({
      'winner_id': _score > 0 ? _ctx.userId : null,
      'player_1_score': _score,
      'player_2_score': 0,
    });
  }

  // ─── GameInterface ─────────────────────────────────────────

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {
    // Snake is single-player concurrent; opponent plays same seed separately
  }

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    setState(() {
      _score = savedState['score'] as int? ?? 0;
      _foodEaten = savedState['foodEaten'] as int? ?? 0;
    });
  }

  @override
  Map<String, dynamic> getCurrentState() {
    return {
      'score': _score,
      'foodEaten': _foodEaten,
    };
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_gameOver) return _buildGameOver();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragEnd: (d) {
            if (d.primaryVelocity == null) return;
            if (d.primaryVelocity! < 0) {
              _changeDirection(_Direction.up);
            } else {
              _changeDirection(_Direction.down);
            }
          },
          onHorizontalDragEnd: (d) {
            if (d.primaryVelocity == null) return;
            if (d.primaryVelocity! < 0) {
              _changeDirection(_Direction.left);
            } else {
              _changeDirection(_Direction.right);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildHeader(),
              const SizedBox(height: 8),
              Expanded(child: _buildGrid()),
              const SizedBox(height: 8),
              _buildControls(),
              const SizedBox(height: 16),
            ],
          ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Snake / Nyoka',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary)),
              Text('Food: $_foodEaten',
                  style: const TextStyle(fontSize: 13, color: _kSecondary)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$_score',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
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
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(
              painter: _SnakePainter(
                snake: _snake,
                food: _food,
                gridSize: gridSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          _arrowButton(Icons.arrow_upward_rounded, _Direction.up),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _arrowButton(Icons.arrow_back_rounded, _Direction.left),
              const SizedBox(width: 48),
              _arrowButton(Icons.arrow_forward_rounded, _Direction.right),
            ],
          ),
          _arrowButton(Icons.arrow_downward_rounded, _Direction.down),
        ],
      ),
    );
  }

  Widget _arrowButton(IconData icon, _Direction dir) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _changeDirection(dir),
          child: Icon(icon, color: _kPrimary, size: 28),
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sentiment_neutral_rounded,
                    size: 64, color: _kPrimary),
                const SizedBox(height: 16),
                const Text('Game Over!',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary)),
                const Text('Mchezo Umekwisha!',
                    style: TextStyle(fontSize: 14, color: _kSecondary)),
                const SizedBox(height: 24),
                Text('$_score',
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary)),
                const Text('points / pointi',
                    style: TextStyle(fontSize: 14, color: _kSecondary)),
                const SizedBox(height: 4),
                Text('$_foodEaten food eaten',
                    style: const TextStyle(fontSize: 13, color: _kSecondary)),
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

class _SnakePainter extends CustomPainter {
  final List<_Point> snake;
  final _Point food;
  final int gridSize;

  _SnakePainter({
    required this.snake,
    required this.food,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / gridSize;
    final cellH = size.height / gridSize;

    // Food
    final foodPaint = Paint()..color = const Color(0xFFE53935);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          food.x * cellW + 1,
          food.y * cellH + 1,
          cellW - 2,
          cellH - 2,
        ),
        const Radius.circular(3),
      ),
      foodPaint,
    );

    // Snake
    for (int i = 0; i < snake.length; i++) {
      final p = snake[i];
      final isHead = i == 0;
      final paint = Paint()
        ..color = isHead ? _kPrimary : _kPrimary.withAlpha(180);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            p.x * cellW + 0.5,
            p.y * cellH + 0.5,
            cellW - 1,
            cellH - 1,
          ),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SnakePainter old) => true;
}
