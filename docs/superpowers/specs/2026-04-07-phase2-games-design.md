# TAJIRI Phase 2 Games — Design Spec (Sub-project 3)

**Date:** 2026-04-07
**Status:** Approved
**Scope:** 5 cultural flagship games plugging into the Games Platform

## Overview

5 turn-based board and card games — the culturally significant games that differentiate TAJIRI. Bao la Kiswahili (Tanzania's national game) and Kadi (East Africa's card game) have no good digital versions — these are potential killer features. Chess, Checkers, and Ludo are universally popular with proven engagement.

## Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Bao variant | Full Traditional (namua + mtaji) | UNESCO heritage, authentic, no competitor has this |
| Chess engine | `chess` Dart package | Solved problem, saves weeks, we focus on UI |
| Ludo max stake | Gold (not Diamond) | Dice introduces luck element |
| Practice mode AI | Random legal move | MVP simplicity, can improve later |
| File structure | 2-4 files per game (game + engine + optional painter + registration) | Separate engine from UI for testability |
| Multiplayer | Turn-based via platform's move/receive system | All 5 games are inherently turn-based |

---

## Game 1: Bao la Kiswahili

**ID:** `bao`
**Category:** board
**Players:** 2 (practice uses random-move AI)
**Duration:** ~5 min
**Modes:** practice, friend, ranked
**Stake safe:** Yes
**Max stake:** Diamond

### Board Layout

4 rows × 8 columns = 32 pits. Players own North (rows 0-1) and South (rows 2-3). Each player's rows: outer row (away from center) and inner row (facing opponent). Special "kuu" (nyumba) pit at position index 4 in inner row (5th from left).

```
North outer:  [0] [1] [2] [3] [4] [5] [6] [7]
North inner:  [8] [9] [10][11][12*][13][14][15]
              ────────────────────────────────
South inner:  [16][17][18][19][20*][21][22][23]
South outer:  [24][25][26][27][28][29][30][31]

* = kuu pit
```

Initial setup: 2 seeds in each of the 8 inner-row pits per player (32 seeds total on board) + 10 stock seeds per player for namua phase.

### Phases

**Namua (Opening):** Each player has 10 stock seeds. On your turn, take 1 seed from stock, place it into any non-empty pit on your inner row, then sow from that pit. If the last seed lands in a non-empty inner-row pit that is opposite a non-empty opponent inner-row pit, capture opponent's seeds from both the inner and outer pit. Continue sowing with captured seeds. Namua ends when both players' stock is empty.

**Mtaji (Main Game):** No stock. On your turn, pick up all seeds from any of your pits with 2+ seeds. Sow counter-clockwise along your own two rows. Captures follow the same rule: last seed in non-empty inner pit opposite non-empty opponent inner pit → capture both opponent pits. Continue sowing captured seeds. If your last seed lands in an empty pit, turn ends.

### Win Condition

Opponent cannot make a legal move: all their pits are empty, or all contain exactly 1 seed (no pit with 2+ seeds to pick up in mtaji).

### Files

```
lib/games/games/bao/
  ├── bao_game.dart           — Game widget (board UI, tap interaction, sow animation)
  ├── bao_engine.dart         — BaoBoard class (state, legal moves, sowing, captures, phase)
  └── bao_registration.dart   — Registration
```

### bao_engine.dart

```
class BaoBoard {
  List<int> pits           — 32 ints (seed count per pit)
  int northStock           — namua seeds remaining for North
  int southStock           — namua seeds remaining for South
  BaoPhase phase           — namua / mtaji
  BaoPlayer currentPlayer  — north / south
  
  List<int> legalMoves(BaoPlayer player)
  List<BaoAnimStep> makeMove(int pitIndex)  — returns animation steps
  bool isGameOver()
  BaoPlayer? winner()
  BaoBoard copy()          — for AI/undo
  Map<String, dynamic> toJson()
  factory BaoBoard.fromJson(Map<String, dynamic>)
}

enum BaoPhase { namua, mtaji }
enum BaoPlayer { north, south }
class BaoAnimStep { BaoAnimType type; int pit; int count; }
enum BaoAnimType { place, sow, capture }
```

### UI

Board rendered with CustomPainter or GridView. Pits as circles with seed count number inside. Colors: board background tan (#D4A76A), pits darker brown (#8B6914), seeds shown as white number text. Kuu pits have a subtle border/glow. 

Player's side at bottom, opponent at top. Tap a pit → if legal, highlight it → confirm tap → animate sowing (sequential pit updates with 200ms delay). Capture animation: opponent pits flash red, seeds move to sowing player's side.

---

## Game 2: Kadi

**ID:** `kadi`
**Category:** card
**Players:** 2
**Duration:** ~3 min
**Modes:** practice, friend, ranked
**Stake safe:** Yes (skill dominates over deal luck)
**Max stake:** Diamond

### Rules

54-card deck (standard 52 + 2 Jokers). Deal 5 cards each. 1 card face-up starts discard pile.

**On your turn:** Play a card matching top discard by rank OR suit. Or draw from pile. If drawn card is playable, may play it immediately.

**Special cards:**
- **2:** Next player draws 2 cards (stackable)
- **3:** Next player draws 3 cards (stackable)
- **8:** Skip opponent's turn
- **Jack:** Reverse direction (in 2-player, same as skip)
- **Ace:** Wild — play on anything, declare desired suit
- **Joker:** Wild + opponent draws 5 (stackable on 2/3 penalty)

**Draw penalty stacking:** If you have a draw penalty (from 2/3/Joker), you can stack another 2/3/Joker to pass the accumulated penalty to opponent. If you can't stack, you draw all accumulated penalty cards.

**Kadi call:** When you have 1 card left after playing, you must tap "KADI!" button within 3 seconds. If opponent taps "Catch!" before you call Kadi, you draw 2 penalty cards.

**Win:** Empty your hand. Score = sum of opponent's remaining cards (A=1, 2-10=face value, J/Q/K=10, Joker=50).

### Files

```
lib/games/games/kadi/
  ├── kadi_game.dart           — Game widget (hand, piles, play/draw, Kadi call)
  ├── kadi_engine.dart         — Deck, dealing, play validation, special effects, scoring
  └── kadi_registration.dart   — Registration
```

### kadi_engine.dart

```
class KadiCard { Suit suit; Rank rank; bool isJoker; }
enum Suit { hearts, diamonds, clubs, spades }
enum Rank { ace, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king }

class KadiState {
  List<KadiCard> player1Hand, player2Hand
  List<KadiCard> discardPile, drawPile
  KadiPlayer currentPlayer
  int drawPenalty             — accumulated draw penalty
  Suit? declaredSuit          — set by Ace/Joker
  bool mustCallKadi           — true when hand reaches 1 card
  bool kadiCalled             — true when player tapped Kadi
  
  bool canPlay(KadiCard card)
  KadiPlayResult playCard(KadiCard card, {Suit? declaredSuit})
  KadiCard drawCard()
  void applyDrawPenalty()     — draw accumulated penalty cards
  bool isGameOver()
  int score(KadiPlayer loser) — sum of loser's remaining card values
}
```

### UI

Bottom: player's hand as overlapping cards in a horizontal fan (scrollable if > 7 cards). Each card shows suit symbol + rank. Tap to select (card rises up), tap again or tap discard pile to play.

Top: opponent's hand as face-down card backs with count badge.

Center: discard pile (top card visible) on left, draw pile (face-down with count) on right.

"KADI!" button appears (pulsing) when hand reaches 1 card. "Catch!" button appears for opponent when they suspect uncalled Kadi.

Suit selector: 4 colored buttons (♥♦♣♠) popup when playing Ace/Joker.

Card design: white card face, rounded corners (8px), colored suit symbols (red hearts/diamonds, black clubs/spades). Card size ~60×85dp.

---

## Game 3: Ludo

**ID:** `ludo`
**Category:** board
**Players:** 2 (expand to 4 later)
**Duration:** ~5 min
**Modes:** practice, friend, ranked
**Stake safe:** Medium (dice luck)
**Max stake:** Gold

### Rules (2-player)

Each player has 4 tokens in home base. Board is a cross-shaped path of 52 squares shared by both players, plus 6-square home column per player leading to center.

- Roll 6 to move a token from base onto start square
- Roll dice, choose one of your tokens to advance that many squares
- Landing on opponent's token: opponent's token returns to their base
- Safe squares (start squares, marked squares): no captures allowed
- Home column: only your tokens can enter, exact roll needed to reach center
- Roll 6: take another turn (max 3 consecutive 6s — third one loses turn)
- First to get all 4 tokens to center wins

**Dice:** Seeded Random for multiplayer fairness.

### Files

```
lib/games/games/ludo/
  ├── ludo_game.dart            — Game widget (board, tokens, dice)
  ├── ludo_engine.dart          — Game logic (movement, captures, dice, win detection)
  ├── ludo_board_painter.dart   — CustomPainter for the board
  └── ludo_registration.dart    — Registration
```

### ludo_board_painter.dart

CustomPainter draws:
- Cross-shaped board with 52 path squares
- 4 colored quadrants (corners): Player 1 = dark (#1A1A1A), Player 2 = grey (#666666). Using monochromatic scheme — not traditional colors.
- Home bases in corners (4 token slots each)
- Home columns (6 squares each) leading to center
- Safe squares marked with a star/dot
- Center triangle/square per player

### UI

Board fills most of screen. Dice display above board: shows face after roll, tap "Roll / Ruka" button to roll. After rolling, legal tokens pulse/highlight — tap one to move it. Animation: token slides along path squares. Opponent's moves animate automatically.

Score: not point-based — first to finish wins. For onGameComplete: winner gets score=1, loser=0.

---

## Game 4: Chess

**ID:** `chess`
**Category:** board
**Players:** 2
**Duration:** ~5 min (5-min blitz clock)
**Modes:** practice, friend, ranked
**Stake safe:** Yes
**Max stake:** Diamond

### Implementation

Uses `chess` Dart package for ALL game logic. No custom engine needed. The package handles:
- Legal move generation
- Check, checkmate, stalemate detection
- Castling, en passant, pawn promotion
- FEN string for board state serialization
- Move history

### Files

```
lib/games/games/chess/
  ├── chess_game.dart          — Game widget (board, pieces, move input, clock)
  └── chess_registration.dart  — Registration
```

### UI

8×8 board: light squares (#F0D9B5), dark squares (#B58863). Pieces as Unicode text characters:
- White: ♔♕♖♗♘♙ (font size ~32)
- Black: ♚♛♜♝♞♟

Tap piece → legal move squares highlighted (green dots for moves, red dots for captures). Tap target → move. 

Pawn promotion: bottom sheet with 4 options (Queen/Rook/Bishop/Knight).

Check: king's square pulses red.

Clock: 5-minute per player (optional in practice). Displayed as "MM:SS" below each player's captured pieces. Time-out = loss.

Board orientation: player's pieces always at bottom.

### Dependencies

Add `chess: ^0.8.3` to pubspec.yaml (or latest version).

---

## Game 5: Checkers / Dama

**ID:** `checkers`
**Category:** board
**Players:** 2
**Duration:** ~3 min
**Modes:** practice, friend, ranked
**Stake safe:** Yes
**Max stake:** Diamond

### Rules (8×8 International)

8×8 board, 12 pieces per player on dark squares (3 rows each).

- Pieces move diagonally forward 1 square to empty dark square
- **Capture:** Jump diagonally over adjacent opponent piece to empty square beyond. Captured piece removed.
- **Multi-jump:** If after capturing another capture is available from the landing square, must continue jumping (mandatory).
- **Mandatory capture:** If any capture is available on your turn, you MUST capture (cannot make a non-capture move).
- **King promotion:** Reaching opponent's back row promotes piece to King.
- **Kings:** Move and capture diagonally forward AND backward.
- **Win:** Capture all opponent pieces, OR opponent has no legal moves.
- **Draw:** No captures for 40 consecutive moves, or same position repeated 3 times.

### Files

```
lib/games/games/checkers/
  ├── checkers_game.dart       — Game widget (board, pieces, move input)
  ├── checkers_engine.dart     — Board state, legal moves, captures, kings, win detection
  └── checkers_registration.dart — Registration
```

### checkers_engine.dart

```
class CheckersBoard {
  List<CheckersPiece?> squares  — 64 entries (null = empty, or Piece)
  CheckersPlayer currentPlayer
  int movesWithoutCapture       — for 40-move draw rule
  
  List<CheckersMove> legalMoves(CheckersPlayer player)
  void makeMove(CheckersMove move)
  bool isGameOver()
  CheckersPlayer? winner()      — null if draw
  Map<String, dynamic> toJson()
  factory CheckersBoard.fromJson(Map<String, dynamic>)
}

class CheckersPiece { CheckersPlayer owner; bool isKing; }
class CheckersMove { int from; int to; List<int> captured; bool promotesToKing; }
enum CheckersPlayer { dark, light }
```

### UI

8×8 board: dark squares (#769656), light squares (#EEEED2). Pieces: dark player = filled circles in _kPrimary (#1A1A1A) with white border; light player = white filled circles with dark border. Kings: small crown icon overlaid or double-stacked appearance.

Tap piece → legal moves shown as green-tinted squares, capture targets shown as red-tinted. Mandatory captures have all non-capture moves disabled. Multi-jump: after first jump, only continuation jumps available until chain complete.

---

## Shared Turn-Based Multiplayer Pattern

All 5 games:

```
My turn → make move → engine validates → UI updates → socketService.sendMove(moveData)
Opponent turn → onOpponentMove(moveData) → engine applies → UI animates
Game over → engine detects → onGameComplete({winner_id, p1_score, p2_score})
```

### Practice Mode AI

All games use random legal move selection for MVP AI:
```dart
if (context.mode == GameMode.practice && isOpponentTurn) {
  final moves = engine.legalMoves(opponent);
  if (moves.isNotEmpty) {
    final aiMove = moves[Random().nextInt(moves.length)];
    engine.makeMove(aiMove);
    // Animate after brief delay (500ms)
  }
}
```

### State Serialization

All engines implement `toJson()` / `fromJson()` for:
- `getCurrentState()` (GameInterface) — platform saves state on disconnect
- `onReconnect(savedState)` — platform restores state

---

## File Structure Summary

### Frontend (14 new files + 1 modified)

```
lib/games/games/
├── bao/
│   ├── bao_game.dart
│   ├── bao_engine.dart
│   └── bao_registration.dart
├── kadi/
│   ├── kadi_game.dart
│   ├── kadi_engine.dart
│   └── kadi_registration.dart
├── ludo/
│   ├── ludo_game.dart
│   ├── ludo_engine.dart
│   ├── ludo_board_painter.dart
│   └── ludo_registration.dart
├── chess/
│   ├── chess_game.dart
│   └── chess_registration.dart
└── checkers/
    ├── checkers_game.dart
    ├── checkers_engine.dart
    └── checkers_registration.dart
```

Plus modify: `lib/games/games_module.dart` (add 5 registration imports), `pubspec.yaml` (add `chess` package)

### Backend

No new backend files for Phase 2. The existing platform endpoints (create session, submit move, end game) work for all turn-based games. Move validation is client-side for MVP (server-side validation deferred).

---

## Non-Goals

- Server-side move validation per game type (deferred — trust client for MVP)
- Smart AI opponents (random legal move for now)
- Sound effects
- 4-player Ludo (2-player for MVP)
- Animated piece sprites (use simple shapes + text)
- Chess opening database / endgame tablebase
- Bao tutorial mode
