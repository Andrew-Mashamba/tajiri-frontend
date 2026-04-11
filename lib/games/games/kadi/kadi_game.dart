// lib/games/games/kadi/kadi_game.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_enums.dart';
import '../../core/game_interface.dart';
import 'kadi_engine.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class KadiGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const KadiGame({super.key, required this.gameContext});

  @override
  State<KadiGame> createState() => KadiGameState();
}

class KadiGameState extends State<KadiGame> implements GameInterface {
  late KadiState _state;
  late Random _rng;
  bool _gameOver = false;
  bool _isMyTurn = true;
  bool _showSuitPicker = false;
  KadiCard? _pendingSuitCard;
  bool _kadiDeclared = false;
  Timer? _kadiTimer;

  gc.GameContext get _ctx => widget.gameContext;
  int get _myPlayer => 1;
  int get _opponentPlayer => 2;

  @override
  String get gameId => 'kadi';

  @override
  void initState() {
    super.initState();
    _rng = Random(_ctx.gameSeed.hashCode);
    if (_ctx.gameState != null) {
      _state = KadiState.fromJson(_ctx.gameState!);
    } else {
      _state = KadiState.newGame(_ctx.gameSeed.hashCode);
    }
    _isMyTurn = _state.currentPlayer == _myPlayer;
    _ctx.setOnOpponentMove(onOpponentMove);
    if (!_isMyTurn && _ctx.mode == GameMode.practice) {
      _scheduleAiMove();
    }
  }

  @override
  void dispose() {
    _kadiTimer?.cancel();
    super.dispose();
  }

  void _scheduleAiMove() {
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || _gameOver) return;
      final hand = _state.hand(_opponentPlayer);
      final playable = hand.where((c) => _state.canPlay(c)).toList();

      if (playable.isNotEmpty) {
        final card = playable[_rng.nextInt(playable.length)];
        KadiSuit? newSuit;
        if (card.rank == KadiRank.ace || card.isJoker) {
          newSuit = KadiSuit.values[_rng.nextInt(4)];
        }
        _state.playCard(_opponentPlayer, card, newSuit: newSuit);
      } else {
        _state.drawCards(_opponentPlayer);
      }

      setState(() {
        _isMyTurn = _state.currentPlayer == _myPlayer;
      });
      _checkGameOver();
      if (!_gameOver && !_isMyTurn && _ctx.mode == GameMode.practice) {
        _scheduleAiMove();
      }
    });
  }

  void _onCardTap(KadiCard card) {
    if (_gameOver || !_isMyTurn || _showSuitPicker) return;
    if (!_state.canPlay(card)) return;

    // Ace/Joker needs suit selection
    if (card.rank == KadiRank.ace || card.isJoker) {
      setState(() {
        _showSuitPicker = true;
        _pendingSuitCard = card;
      });
      return;
    }

    _playCard(card, null);
  }

  void _onSuitSelected(KadiSuit suit) {
    if (_pendingSuitCard == null) return;
    _playCard(_pendingSuitCard!, suit);
    setState(() {
      _showSuitPicker = false;
      _pendingSuitCard = null;
    });
  }

  void _playCard(KadiCard card, KadiSuit? newSuit) {
    _state.playCard(_myPlayer, card, newSuit: newSuit);

    setState(() {
      _isMyTurn = _state.currentPlayer == _myPlayer;
    });

    _sendMove({'action': 'play', 'card': card.toJson(), 'newSuit': newSuit?.name});
    _checkGameOver();

    if (!_gameOver && !_isMyTurn && _ctx.mode == GameMode.practice) {
      _scheduleAiMove();
    }
  }

  void _onDrawTap() {
    if (_gameOver || !_isMyTurn || _showSuitPicker) return;

    _state.drawCards(_myPlayer);
    setState(() {
      _isMyTurn = _state.currentPlayer == _myPlayer;
    });

    _sendMove({'action': 'draw'});
    _checkGameOver();

    if (!_gameOver && !_isMyTurn && _ctx.mode == GameMode.practice) {
      _scheduleAiMove();
    }
  }

  void _onKadiTap() {
    if (_state.hand(_myPlayer).length != 1) return;
    setState(() => _kadiDeclared = true);
    _kadiTimer?.cancel();
    _kadiTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _kadiDeclared = false);
    });
  }

  void _checkGameOver() {
    if (_state.isGameOver()) {
      setState(() => _gameOver = true);
      final w = _state.winner();
      _ctx.onGameComplete({
        'winner_id': w == _myPlayer ? _ctx.userId : (_ctx.opponentId ?? 0),
        'player_1_score': w == _myPlayer ? 1 : 0,
        'player_2_score': w == _opponentPlayer ? 1 : 0,
      });
    }
  }

  void _sendMove(Map<String, dynamic> move) {
    _ctx.socketService.sendMove(_ctx.userId, {
      'type': 'move',
      ...move,
      'state': _state.toJson(),
    });
  }

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {
    if (moveData['state'] != null) {
      setState(() {
        _state =
            KadiState.fromJson(Map<String, dynamic>.from(moveData['state']));
        _isMyTurn = _state.currentPlayer == _myPlayer;
      });
      _checkGameOver();
    }
  }

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    setState(() {
      _state = KadiState.fromJson(savedState);
      _isMyTurn = _state.currentPlayer == _myPlayer;
    });
  }

  @override
  Map<String, dynamic> getCurrentState() => _state.toJson();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildStatusBar(),
        const SizedBox(height: 8),
        _buildOpponentHand(),
        const SizedBox(height: 12),
        _buildCenterArea(),
        const SizedBox(height: 12),
        if (_showSuitPicker) _buildSuitPicker(),
        if (_state.hand(_myPlayer).length == 1 && !_kadiDeclared)
          _buildKadiButton(),
        const SizedBox(height: 8),
        _buildPlayerHand(),
        const SizedBox(height: 8),
        if (_gameOver) _buildGameOverBanner(),
      ],
    );
  }

  Widget _buildStatusBar() {
    final turnText = _gameOver
        ? (_state.winner() == _myPlayer ? 'You win!' : 'You lose!')
        : (_isMyTurn ? 'Your turn' : 'Opponent\'s turn');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(turnText,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          if (_state.declaredSuit != null)
            Text('Suit: ${_state.declaredSuit!.symbol}',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _state.declaredSuit!.isRed
                        ? Colors.red
                        : _kPrimary)),
        ],
      ),
    );
  }

  Widget _buildOpponentHand() {
    final count = _state.hand(_opponentPlayer).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            count.clamp(0, 10),
            (i) => Transform.translate(
              offset: Offset(i * -8.0, 0),
              child: Container(
                width: 36,
                height: 50,
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                alignment: Alignment.center,
                child: const Text('?',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterArea() {
    final top = _state.topDiscard;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Draw pile
          GestureDetector(
            onTap: _onDrawTap,
            child: Stack(
              children: [
                Container(
                  width: 60,
                  height: 85,
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.layers_rounded,
                          color: Colors.white, size: 20),
                      Text('${_state.drawPile.length}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
                if (_state.drawPenalty > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Draw ${_state.drawPenalty}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Discard pile
          _buildCardWidget(top, width: 60, height: 85, fontSize: 16),
        ],
      ),
    );
  }

  Widget _buildSuitPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: KadiSuit.values.map((suit) {
          return GestureDetector(
            onTap: () => _onSuitSelected(suit),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              alignment: Alignment.center,
              child: Text(
                suit.symbol,
                style: TextStyle(
                  fontSize: 28,
                  color: suit.isRed ? Colors.red : _kPrimary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKadiButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
      child: GestureDetector(
        onTap: _onKadiTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFDAA520),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('KADI!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildPlayerHand() {
    final hand = _state.hand(_myPlayer);
    return SizedBox(
      height: 95,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: hand.length,
        itemBuilder: (context, i) {
          final card = hand[i];
          final playable = _isMyTurn && _state.canPlay(card);
          return GestureDetector(
            onTap: () => _onCardTap(card),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.translate(
                offset: Offset(0, playable ? -8 : 0),
                child: Opacity(
                  opacity: playable ? 1.0 : 0.5,
                  child: _buildCardWidget(card,
                      width: 60, height: 85, fontSize: 14),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardWidget(KadiCard card,
      {double width = 60, double height = 85, double fontSize = 14}) {
    if (card.isJoker) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 1)),
          ],
        ),
        alignment: Alignment.center,
        child: Text('JKR',
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.purple)),
      );
    }

    final color = card.isRed ? Colors.red : _kPrimary;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 2,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(card.rank?.display ?? '',
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(card.suit?.symbol ?? '',
              style: TextStyle(fontSize: fontSize + 2, color: color)),
        ],
      ),
    );
  }

  Widget _buildGameOverBanner() {
    final w = _state.winner();
    final loser = w == 1 ? 2 : 1;
    final text =
        w == _myPlayer ? 'You won! Score: ${_state.score(loser)}' : 'You lost';
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
