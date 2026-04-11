// lib/games/games/snap/snap_game.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Standard 52-card deck representation.
class _PlayingCard {
  final int rank; // 0-12 (Ace..King)
  final int suit; // 0-3

  const _PlayingCard(this.rank, this.suit);

  String get rankLabel {
    const labels = [
      'A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'
    ];
    return labels[rank];
  }

  String get suitSymbol {
    const symbols = ['\u2660', '\u2665', '\u2666', '\u2663']; // spade,heart,diamond,club
    return symbols[suit];
  }

  Color get suitColor =>
      (suit == 1 || suit == 2) ? const Color(0xFFD32F2F) : _kPrimary;
}

class SnapGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const SnapGame({super.key, required this.gameContext});

  @override
  State<SnapGame> createState() => SnapGameState();
}

class SnapGameState extends State<SnapGame>
    with TickerProviderStateMixin
    implements GameInterface {
  gc.GameContext get _ctx => widget.gameContext;

  late List<_PlayingCard> _deck;
  final List<_PlayingCard> _centerPile = [];

  int _playerCards = 26;
  int _opponentCards = 26;
  int _currentPlayer = 0; // 0=player, 1=opponent
  bool _gameOver = false;
  bool _isSnappable = false; // true when top two cards match rank
  Timer? _flipTimer;

  // Flash feedback
  Color? _flashColor;
  Timer? _flashTimer;

  // Card flip animation
  late AnimationController _flipAnimController;
  late Animation<double> _flipAnim;
  bool _isFlipping = false;

  // AI snap timer for practice mode
  Timer? _aiSnapTimer;

  @override
  String get gameId => 'snap';

  @override
  void initState() {
    super.initState();
    _flipAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flipAnim = CurvedAnimation(
      parent: _flipAnimController,
      curve: Curves.easeOut,
    );
    _setupDeck();
    _startFlipTimer();
    _ctx.setOnOpponentMove(onOpponentMove);
  }

  @override
  void dispose() {
    _flipTimer?.cancel();
    _flashTimer?.cancel();
    _aiSnapTimer?.cancel();
    _flipAnimController.dispose();
    super.dispose();
  }

  void _setupDeck() {
    final cards = <_PlayingCard>[];
    for (int suit = 0; suit < 4; suit++) {
      for (int rank = 0; rank < 13; rank++) {
        cards.add(_PlayingCard(rank, suit));
      }
    }
    final rng = Random(_ctx.gameSeed.hashCode);
    cards.shuffle(rng);
    _deck = cards;
  }

  void _startFlipTimer() {
    _flipTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted || _gameOver) {
        _flipTimer?.cancel();
        return;
      }
      _flipNextCard();
    });
  }

  void _flipNextCard() {
    if (_gameOver || _isFlipping) return;

    // Check if current player has cards
    if (_currentPlayer == 0 && _playerCards <= 0) {
      _endGame();
      return;
    }
    if (_currentPlayer == 1 && _opponentCards <= 0) {
      _endGame();
      return;
    }

    // Check if deck is exhausted
    if (_deck.isEmpty) {
      _endGame();
      return;
    }

    setState(() => _isFlipping = true);
    _flipAnimController.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() {
        final card = _deck.removeLast();
        _centerPile.add(card);

        if (_currentPlayer == 0) {
          _playerCards--;
        } else {
          _opponentCards--;
        }

        // Check if top two cards match by rank
        _isSnappable = _centerPile.length >= 2 &&
            _centerPile[_centerPile.length - 1].rank ==
                _centerPile[_centerPile.length - 2].rank;

        // Switch player
        _currentPlayer = (_currentPlayer + 1) % 2;
        _isFlipping = false;
      });

      // AI snap in practice mode
      if (_isSnappable && _ctx.mode == GameMode.practice) {
        _aiSnapTimer?.cancel();
        final rng = Random();
        final delay = 600 + rng.nextInt(800); // 600-1400ms
        _aiSnapTimer = Timer(Duration(milliseconds: delay), () {
          if (mounted && _isSnappable && !_gameOver) {
            // AI snaps — opponent gets the pile
            _handleSnap(isPlayer: false);
          }
        });
      }

      // Check for end of deck
      if (_deck.isEmpty && _playerCards <= 0 && _opponentCards <= 0) {
        _endGame();
      }
    });
  }

  void _onSnapTap() {
    if (_gameOver) return;
    _aiSnapTimer?.cancel();
    _handleSnap(isPlayer: true);
  }

  void _handleSnap({required bool isPlayer}) {
    if (_gameOver) return;

    if (_isSnappable) {
      // Correct snap — winner takes the pile
      final pileSize = _centerPile.length;
      setState(() {
        if (isPlayer) {
          _playerCards += pileSize;
        } else {
          _opponentCards += pileSize;
        }
        _centerPile.clear();
        _isSnappable = false;
      });
      _showFlash(Colors.green);

      // Check win
      if (_opponentCards <= 0 || _playerCards <= 0) {
        _endGame();
      }
    } else {
      // False snap — penalty: lose 3 cards to opponent
      if (isPlayer) {
        final penalty = _playerCards >= 3 ? 3 : _playerCards;
        setState(() {
          _playerCards -= penalty;
          _opponentCards += penalty;
        });
      } else {
        final penalty = _opponentCards >= 3 ? 3 : _opponentCards;
        setState(() {
          _opponentCards -= penalty;
          _playerCards += penalty;
        });
      }
      _showFlash(Colors.red);

      if (_playerCards <= 0 || _opponentCards <= 0) {
        _endGame();
      }
    }
  }

  void _showFlash(Color color) {
    _flashTimer?.cancel();
    setState(() => _flashColor = color);
    _flashTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _flashColor = null);
    });
  }

  void _endGame() {
    _flipTimer?.cancel();
    _aiSnapTimer?.cancel();
    setState(() => _gameOver = true);

    final p1Score = _playerCards;
    final p2Score = _opponentCards;
    int? winnerId;
    if (p1Score > p2Score) {
      winnerId = _ctx.userId;
    } else if (p2Score > p1Score) {
      winnerId = _ctx.opponentId;
    }
    _ctx.onGameComplete({
      'winner_id': winnerId,
      'player_1_score': p1Score,
      'player_2_score': p2Score,
    });
  }

  // ─── GameInterface ─────────────────────────────────────────

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {
    if (moveData['action'] == 'snap') {
      _aiSnapTimer?.cancel();
      _handleSnap(isPlayer: false);
    }
  }

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    setState(() {
      _playerCards = savedState['playerCards'] as int? ?? 26;
      _opponentCards = savedState['opponentCards'] as int? ?? 26;
    });
  }

  @override
  Map<String, dynamic> getCurrentState() {
    return {
      'playerCards': _playerCards,
      'opponentCards': _opponentCards,
      'pileSize': _centerPile.length,
    };
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_gameOver) return _buildGameOver();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: _flashColor?.withAlpha(30) ?? Colors.transparent,
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildHeader(),
              const Spacer(),
              _buildCenterPile(),
              const Spacer(),
              _buildSnapButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCardCount('You', _playerCards, true),
          Column(
            children: [
              const Text('Snap!',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary)),
              Text('Pile: ${_centerPile.length}',
                  style: const TextStyle(fontSize: 13, color: _kSecondary)),
            ],
          ),
          _buildCardCount(
            _ctx.opponentName ?? 'AI',
            _opponentCards,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildCardCount(String label, int count, bool isPlayer) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kSecondary)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isPlayer ? _kPrimary : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isPlayer ? Colors.white : _kPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterPile() {
    if (_centerPile.isEmpty) {
      return Container(
        width: 120,
        height: 170,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: const Text('...',
            style: TextStyle(fontSize: 24, color: _kSecondary)),
      );
    }

    final topCard = _centerPile.last;
    final prevCard = _centerPile.length >= 2
        ? _centerPile[_centerPile.length - 2]
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prevCard != null)
          Opacity(
            opacity: 0.4,
            child: _buildCardWidget(prevCard, small: true),
          ),
        const SizedBox(height: 8),
        ScaleTransition(
          scale: _flipAnim,
          child: _buildCardWidget(topCard, small: false),
        ),
        if (_isSnappable)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'MATCH!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCardWidget(_PlayingCard card, {required bool small}) {
    final w = small ? 80.0 : 120.0;
    final h = small ? 110.0 : 170.0;
    final fontSize = small ? 18.0 : 28.0;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: small
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.rankLabel,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: card.suitColor,
            ),
          ),
          Text(
            card.suitSymbol,
            style: TextStyle(fontSize: fontSize * 0.8, color: card.suitColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: ElevatedButton(
          onPressed: _onSnapTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: const Text(
            'SNAP!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    final won = _playerCards > _opponentCards;
    final tied = _playerCards == _opponentCards;

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
                  won ? Icons.emoji_events_rounded : Icons.sentiment_neutral_rounded,
                  size: 64,
                  color: _kPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  tied
                      ? 'Draw!'
                      : won
                          ? 'You Win!'
                          : 'You Lose!',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary),
                ),
                Text(
                  tied
                      ? 'Sare!'
                      : won
                          ? 'Umeshinda!'
                          : 'Umeshindwa!',
                  style: const TextStyle(fontSize: 14, color: _kSecondary),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildScoreColumn('You', _playerCards),
                    const SizedBox(width: 32),
                    _buildScoreColumn(_ctx.opponentName ?? 'AI', _opponentCards),
                  ],
                ),
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

  Widget _buildScoreColumn(String label, int cards) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: _kSecondary)),
        const SizedBox(height: 4),
        Text('$cards',
            style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: _kPrimary)),
        const Text('cards / kadi',
            style: TextStyle(fontSize: 12, color: _kSecondary)),
      ],
    );
  }
}
