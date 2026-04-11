// lib/games/games/kadi/kadi_engine.dart
// Pure Dart — no Flutter imports.

import 'dart:math';

enum KadiSuit {
  hearts,
  diamonds,
  clubs,
  spades;

  String get symbol {
    switch (this) {
      case hearts:
        return '\u2665';
      case diamonds:
        return '\u2666';
      case clubs:
        return '\u2663';
      case spades:
        return '\u2660';
    }
  }

  bool get isRed => this == hearts || this == diamonds;
}

enum KadiRank {
  ace,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king;

  String get display {
    switch (this) {
      case ace:
        return 'A';
      case two:
        return '2';
      case three:
        return '3';
      case four:
        return '4';
      case five:
        return '5';
      case six:
        return '6';
      case seven:
        return '7';
      case eight:
        return '8';
      case nine:
        return '9';
      case ten:
        return '10';
      case jack:
        return 'J';
      case queen:
        return 'Q';
      case king:
        return 'K';
    }
  }

  int get pointValue {
    switch (this) {
      case ace:
        return 1;
      case two:
        return 2;
      case three:
        return 3;
      case four:
        return 4;
      case five:
        return 5;
      case six:
        return 6;
      case seven:
        return 7;
      case eight:
        return 8;
      case nine:
        return 9;
      case ten:
        return 10;
      case jack:
        return 10;
      case queen:
        return 10;
      case king:
        return 10;
    }
  }
}

class KadiCard {
  final KadiSuit? suit;
  final KadiRank? rank;
  final bool isJoker;

  const KadiCard({this.suit, this.rank, this.isJoker = false});

  int get pointValue {
    if (isJoker) return 50;
    return rank?.pointValue ?? 0;
  }

  String get display {
    if (isJoker) return 'JOKER';
    return '${rank?.display ?? ''}${suit?.symbol ?? ''}';
  }

  bool get isRed => isJoker ? false : (suit?.isRed ?? false);

  @override
  bool operator ==(Object other) =>
      other is KadiCard &&
      suit == other.suit &&
      rank == other.rank &&
      isJoker == other.isJoker;

  @override
  int get hashCode => Object.hash(suit, rank, isJoker);

  Map<String, dynamic> toJson() => {
        'suit': suit?.name,
        'rank': rank?.name,
        'isJoker': isJoker,
      };

  factory KadiCard.fromJson(Map<String, dynamic> json) {
    if (json['isJoker'] == true) {
      return const KadiCard(isJoker: true);
    }
    return KadiCard(
      suit: KadiSuit.values.firstWhere((s) => s.name == json['suit']),
      rank: KadiRank.values.firstWhere((r) => r.name == json['rank']),
    );
  }
}

class KadiState {
  List<KadiCard> player1Hand;
  List<KadiCard> player2Hand;
  List<KadiCard> discardPile;
  List<KadiCard> drawPile;
  int currentPlayer; // 1 or 2
  int drawPenalty;
  KadiSuit? declaredSuit;

  KadiState({
    required this.player1Hand,
    required this.player2Hand,
    required this.discardPile,
    required this.drawPile,
    this.currentPlayer = 1,
    this.drawPenalty = 0,
    this.declaredSuit,
  });

  factory KadiState.newGame(int seed) {
    final rng = Random(seed);
    final deck = <KadiCard>[];

    // 52 standard cards
    for (final suit in KadiSuit.values) {
      for (final rank in KadiRank.values) {
        deck.add(KadiCard(suit: suit, rank: rank));
      }
    }
    // 2 Jokers
    deck.add(const KadiCard(isJoker: true));
    deck.add(const KadiCard(isJoker: true));

    // Shuffle
    deck.shuffle(rng);

    final p1Hand = deck.sublist(0, 5);
    final p2Hand = deck.sublist(5, 10);
    final discard = [deck[10]];
    final draw = deck.sublist(11);

    return KadiState(
      player1Hand: p1Hand,
      player2Hand: p2Hand,
      discardPile: discard,
      drawPile: draw,
    );
  }

  KadiCard get topDiscard => discardPile.last;

  KadiSuit? get effectiveSuit => declaredSuit ?? topDiscard.suit;

  List<KadiCard> hand(int player) =>
      player == 1 ? player1Hand : player2Hand;

  bool canPlay(KadiCard card) {
    // Under draw penalty, only penalty cards can be played
    if (drawPenalty > 0) {
      return card.rank == KadiRank.two ||
          card.rank == KadiRank.three ||
          card.isJoker;
    }

    // Joker/Ace always playable
    if (card.isJoker || card.rank == KadiRank.ace) return true;

    // Match rank
    if (!topDiscard.isJoker && card.rank == topDiscard.rank) return true;

    // Match effective suit
    if (card.suit == effectiveSuit) return true;

    return false;
  }

  void playCard(int player, KadiCard card, {KadiSuit? newSuit}) {
    final h = hand(player);
    h.remove(card);
    discardPile.add(card);
    declaredSuit = null;

    // Special card effects
    bool skip = false;
    if (card.rank == KadiRank.two) {
      drawPenalty += 2;
    } else if (card.rank == KadiRank.three) {
      drawPenalty += 3;
    } else if (card.isJoker) {
      drawPenalty += 5;
    } else if (card.rank == KadiRank.eight || card.rank == KadiRank.jack) {
      skip = true;
    }

    // Suit declaration for Ace/Joker
    if (card.rank == KadiRank.ace || card.isJoker) {
      declaredSuit = newSuit;
    }

    // Switch turn (unless skip)
    if (!skip) {
      currentPlayer = currentPlayer == 1 ? 2 : 1;
    }
  }

  void drawCards(int player) {
    final h = hand(player);
    int count = drawPenalty > 0 ? drawPenalty : 1;
    drawPenalty = 0;

    for (int i = 0; i < count; i++) {
      if (drawPile.isEmpty) {
        _reshuffleDiscard();
      }
      if (drawPile.isEmpty) break;
      h.add(drawPile.removeLast());
    }

    currentPlayer = currentPlayer == 1 ? 2 : 1;
  }

  void _reshuffleDiscard() {
    if (discardPile.length <= 1) return;
    final top = discardPile.removeLast();
    drawPile.addAll(discardPile);
    discardPile.clear();
    discardPile.add(top);
    drawPile.shuffle(Random());
  }

  bool isGameOver() {
    return player1Hand.isEmpty || player2Hand.isEmpty;
  }

  int? winner() {
    if (player1Hand.isEmpty) return 1;
    if (player2Hand.isEmpty) return 2;
    return null;
  }

  int score(int loserPlayer) {
    return hand(loserPlayer).fold(0, (sum, c) => sum + c.pointValue);
  }

  Map<String, dynamic> toJson() => {
        'player1Hand': player1Hand.map((c) => c.toJson()).toList(),
        'player2Hand': player2Hand.map((c) => c.toJson()).toList(),
        'discardPile': discardPile.map((c) => c.toJson()).toList(),
        'drawPile': drawPile.map((c) => c.toJson()).toList(),
        'currentPlayer': currentPlayer,
        'drawPenalty': drawPenalty,
        'declaredSuit': declaredSuit?.name,
      };

  factory KadiState.fromJson(Map<String, dynamic> json) {
    return KadiState(
      player1Hand: (json['player1Hand'] as List)
          .map((e) => KadiCard.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      player2Hand: (json['player2Hand'] as List)
          .map((e) => KadiCard.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      discardPile: (json['discardPile'] as List)
          .map((e) => KadiCard.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      drawPile: (json['drawPile'] as List)
          .map((e) => KadiCard.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      currentPlayer: json['currentPlayer'] as int,
      drawPenalty: json['drawPenalty'] as int? ?? 0,
      declaredSuit: json['declaredSuit'] != null
          ? KadiSuit.values.firstWhere((s) => s.name == json['declaredSuit'])
          : null,
    );
  }
}
