// lib/games/games/memory/memory_game.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// 8 pairs of icons for the memory cards.
const List<_CardSymbol> _kSymbols = [
  _CardSymbol(Icons.star_rounded, Color(0xFFFFB300), 'Star'),
  _CardSymbol(Icons.favorite_rounded, Color(0xFFE53935), 'Heart'),
  _CardSymbol(Icons.diamond_rounded, Color(0xFF1E88E5), 'Diamond'),
  _CardSymbol(Icons.circle, Color(0xFF43A047), 'Circle'),
  _CardSymbol(Icons.square_rounded, Color(0xFF8E24AA), 'Square'),
  _CardSymbol(Icons.change_history_rounded, Color(0xFFFF6F00), 'Triangle'),
  _CardSymbol(Icons.nightlight_round, Color(0xFF5C6BC0), 'Moon'),
  _CardSymbol(Icons.wb_sunny_rounded, Color(0xFFFDD835), 'Sun'),
];

class _CardSymbol {
  final IconData icon;
  final Color color;
  final String label;
  const _CardSymbol(this.icon, this.color, this.label);
}

class MemoryGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const MemoryGame({super.key, required this.gameContext});

  @override
  State<MemoryGame> createState() => MemoryGameState();
}

class MemoryGameState extends State<MemoryGame>
    with TickerProviderStateMixin
    implements GameInterface {
  // 16 cards = 8 pairs. Each card stores its symbol index.
  late List<int> _cardSymbolIndices; // index into _kSymbols
  late List<bool> _faceUp;
  late List<bool> _matched;
  late List<AnimationController> _flipControllers;

  int _firstFlipped = -1;
  int _secondFlipped = -1;
  bool _checking = false;
  int _moves = 0;
  int _matchesFound = 0;
  int _score = 0;
  int _secondsElapsed = 0;
  bool _gameOver = false;
  int _lastMatchIndex = -1; // for green glow
  Timer? _timer;

  gc.GameContext get _ctx => widget.gameContext;

  @override
  String get gameId => 'memory';

  @override
  void initState() {
    super.initState();
    _setupCards();
    _flipControllers = List.generate(
      16,
      (_) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (!_gameOver) setState(() => _secondsElapsed++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _flipControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _setupCards() {
    // Create 8 pairs
    final indices = <int>[];
    for (int i = 0; i < 8; i++) {
      indices.add(i);
      indices.add(i);
    }
    // Seeded shuffle
    final rng = Random(_ctx.gameSeed.hashCode);
    indices.shuffle(rng);

    _cardSymbolIndices = indices;
    _faceUp = List<bool>.filled(16, false);
    _matched = List<bool>.filled(16, false);
  }

  void _flipCard(int index) {
    if (_gameOver || _checking || _faceUp[index] || _matched[index]) return;

    setState(() {
      _faceUp[index] = true;
      _flipControllers[index].forward();
    });

    if (_firstFlipped == -1) {
      _firstFlipped = index;
    } else {
      _secondFlipped = index;
      _moves++;
      _checking = true;

      // Check match after a brief delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        final match =
            _cardSymbolIndices[_firstFlipped] == _cardSymbolIndices[_secondFlipped];

        setState(() {
          if (match) {
            _matched[_firstFlipped] = true;
            _matched[_secondFlipped] = true;
            _matchesFound++;
            _score += 10;
            _lastMatchIndex = _cardSymbolIndices[_firstFlipped];

            // Clear glow after a moment
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) setState(() => _lastMatchIndex = -1);
            });

            if (_matchesFound >= 8) {
              _endGame();
            }
          } else {
            _faceUp[_firstFlipped] = false;
            _faceUp[_secondFlipped] = false;
            _flipControllers[_firstFlipped].reverse();
            _flipControllers[_secondFlipped].reverse();
          }
          _firstFlipped = -1;
          _secondFlipped = -1;
          _checking = false;
        });
      });
    }
  }

  void _endGame() {
    _timer?.cancel();
    // Time bonus: up to 50 bonus for finishing under 30s
    int timeBonus = 0;
    if (_secondsElapsed < 30) {
      timeBonus = 50;
    } else if (_secondsElapsed < 60) {
      timeBonus = 30;
    } else if (_secondsElapsed < 90) {
      timeBonus = 10;
    }
    _score += timeBonus;

    setState(() => _gameOver = true);

    final winnerId = (_ctx.mode == GameMode.practice)
        ? (_score > 0 ? _ctx.userId : null)
        : _ctx.userId;
    _ctx.onGameComplete({
      'winner_id': winnerId,
      'player_1_score': _score,
      'player_2_score': 0,
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {}

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    final matchedData = (savedState['matched'] as List?)?.cast<bool>();
    if (matchedData != null) {
      setState(() {
        for (int i = 0; i < 16 && i < matchedData.length; i++) {
          _matched[i] = matchedData[i];
          if (_matched[i]) {
            _faceUp[i] = true;
            _flipControllers[i].forward();
          }
        }
        _matchesFound = savedState['matchesFound'] as int? ?? 0;
        _score = savedState['score'] as int? ?? 0;
        _moves = savedState['moves'] as int? ?? 0;
        _secondsElapsed = savedState['seconds'] as int? ?? 0;
      });
    }
  }

  @override
  Map<String, dynamic> getCurrentState() {
    return {
      'matched': _matched,
      'matchesFound': _matchesFound,
      'score': _score,
      'moves': _moves,
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
            const SizedBox(height: 16),
            Expanded(child: _buildCardGrid()),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Memory Match',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary)),
              Text('Moves: $_moves',
                  style:
                      const TextStyle(fontSize: 13, color: _kSecondary)),
            ],
          ),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_formatTime(_secondsElapsed),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                        fontFeatures: [FontFeature.tabularFigures()])),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$_matchesFound/8',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardGrid() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemCount: 16,
          itemBuilder: (context, index) => _buildCard(index),
        ),
      ),
    );
  }

  Widget _buildCard(int index) {
    final symbolIdx = _cardSymbolIndices[index];
    final symbol = _kSymbols[symbolIdx];
    final isMatched = _matched[index];
    final showGlow = isMatched && _lastMatchIndex == symbolIdx;

    return GestureDetector(
      onTap: () => _flipCard(index),
      child: AnimatedBuilder(
        listenable: _flipControllers[index],
        builder: (context, child) {
          final angle = _flipControllers[index].value * 3.14159;
          final showFront = angle > 1.5708; // pi/2

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: Container(
              decoration: BoxDecoration(
                color: showFront
                    ? (showGlow ? Colors.green.shade50 : Colors.white)
                    : const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: showGlow
                      ? Colors.green
                      : showFront
                          ? Colors.grey.shade300
                          : const Color(0xFF444444),
                  width: showGlow ? 2 : 1,
                ),
                boxShadow: showGlow
                    ? [
                        BoxShadow(
                            color: Colors.green.withAlpha(80),
                            blurRadius: 8)
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: showFront
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(3.14159),
                      child: Icon(symbol.icon,
                          size: 36, color: symbol.color),
                    )
                  : const Icon(Icons.question_mark_rounded,
                      size: 28, color: Color(0xFF888888)),
            ),
          );
        },
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
                const Icon(Icons.emoji_events_rounded,
                    size: 64, color: _kPrimary),
                const SizedBox(height: 16),
                const Text('All Pairs Found!',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary)),
                const SizedBox(height: 4),
                const Text('Jozi Zote Zimepatikana!',
                    style: TextStyle(fontSize: 14, color: _kSecondary)),
                const SizedBox(height: 16),
                Text(_formatTime(_secondsElapsed),
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary)),
                const SizedBox(height: 4),
                Text('$_moves moves',
                    style:
                        const TextStyle(fontSize: 14, color: _kSecondary)),
                const SizedBox(height: 16),
                Text('$_score',
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary)),
                const Text('points / pointi',
                    style: TextStyle(fontSize: 14, color: _kSecondary)),
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

/// AnimatedBuilder wrapper (same as AnimatedBuilder in Flutter).
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
  });

  // Use 'listenable' via super
  Animation<double> get animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
