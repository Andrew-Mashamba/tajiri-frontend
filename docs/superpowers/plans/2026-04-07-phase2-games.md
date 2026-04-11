# TAJIRI Phase 2 Games Implementation Plan (Sub-project 3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build 5 cultural flagship board/card games (Bao la Kiswahili, Kadi, Ludo, Chess, Checkers) that plug into the existing Games Platform.

**Architecture:** Each game has a separate engine file (pure Dart logic) and a game widget (Flutter UI). Engines handle board state, legal moves, captures, win detection. Widgets handle rendering, tap input, animations, and call the platform's onGameComplete when the game ends. Turn-based multiplayer uses the platform's sendMove/onOpponentMove pattern. Chess uses the `chess` Dart package for logic.

**Tech Stack:** Flutter/Dart, CustomPainter for board rendering, `chess` package for Chess game logic

**Spec:** `docs/superpowers/specs/2026-04-07-phase2-games-design.md`

**Existing platform:** `lib/games/core/` (GameInterface, GameContext, GameRegistry, enums), `lib/games/services/`, 5 Phase 1 games already registered.

---

## File Map

### Frontend (14 new files + 2 modified)

| File | Responsibility |
|---|---|
| `lib/games/games/bao/bao_engine.dart` | Bao rule engine: board state, namua/mtaji phases, sowing, captures, legal moves, win detection |
| `lib/games/games/bao/bao_game.dart` | Bao UI: board rendering, pit tap, sow animation, practice AI |
| `lib/games/games/bao/bao_registration.dart` | Register Bao with GameRegistry |
| `lib/games/games/kadi/kadi_engine.dart` | Kadi card engine: deck, dealing, play validation, special cards, penalties, scoring |
| `lib/games/games/kadi/kadi_game.dart` | Kadi UI: hand fan, discard/draw piles, play cards, Kadi call |
| `lib/games/games/kadi/kadi_registration.dart` | Register Kadi with GameRegistry |
| `lib/games/games/ludo/ludo_engine.dart` | Ludo engine: board path, movement, captures, safe squares, home entry, dice, win detection |
| `lib/games/games/ludo/ludo_board_painter.dart` | CustomPainter for the Ludo cross-shaped board |
| `lib/games/games/ludo/ludo_game.dart` | Ludo UI: board, tokens, dice roll, token selection |
| `lib/games/games/ludo/ludo_registration.dart` | Register Ludo with GameRegistry |
| `lib/games/games/chess/chess_game.dart` | Chess UI: 8x8 board, piece rendering, move input, clock, promotion |
| `lib/games/games/chess/chess_registration.dart` | Register Chess with GameRegistry |
| `lib/games/games/checkers/checkers_engine.dart` | Checkers engine: board state, diagonal moves, captures, multi-jump, kings, mandatory capture |
| `lib/games/games/checkers/checkers_game.dart` | Checkers UI: board, pieces, move input, capture highlighting |
| `lib/games/games/checkers/checkers_registration.dart` | Register Checkers with GameRegistry |
| `lib/games/games_module.dart` | **Modify:** add 5 new registration imports + calls |
| `pubspec.yaml` | **Modify:** add `chess` package dependency |

---

## Task 1: Add chess package dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add chess package**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND
flutter pub add chess
```

- [ ] **Step 2: Verify it installed**

```bash
flutter pub deps | grep chess
```

Expected: `chess` package listed.

---

## Task 2: Checkers — Engine + Game + Registration

**Files:**
- Create: `lib/games/games/checkers/checkers_engine.dart`
- Create: `lib/games/games/checkers/checkers_game.dart`
- Create: `lib/games/games/checkers/checkers_registration.dart`

Checkers is the simplest board game of the 5 — good starting point to establish patterns.

- [ ] **Step 1: Create directory**

```bash
mkdir -p lib/games/games/checkers
```

- [ ] **Step 2: Write checkers_engine.dart**

Pure Dart — no Flutter imports. Contains:

**Enums:** `CheckersPlayer { dark, light }` with `opponent` getter.

**CheckersPiece:** `{ CheckersPlayer owner; bool isKing; }` with copyWith.

**CheckersMove:** `{ int from; int to; List<int> captured; bool promotesToKing; }`.

**CheckersBoard class:**
- `List<CheckersPiece?> squares` — 64 entries indexed 0-63 (row*8 + col). Only dark squares (where `(row+col) % 2 == 1`) hold pieces.
- `CheckersPlayer currentPlayer`
- `int movesWithoutCapture` — for 40-move draw rule
- Constructor: initializes 12 dark pieces (rows 0-2 on dark squares) and 12 light pieces (rows 5-7 on dark squares)
- `List<CheckersMove> legalMoves(CheckersPlayer player)`:
  - First check for captures (mandatory). If any capture exists for any piece, ONLY capture moves are legal.
  - Captures: jump diagonally over adjacent opponent piece to empty square. Multi-jump: recursively check for continuation jumps from landing square.
  - Non-captures: move diagonally forward one square (both directions for kings) to empty square.
  - Forward for dark = increasing row, forward for light = decreasing row.
- `void makeMove(CheckersMove move)`:
  - Move piece from → to.
  - Remove captured pieces.
  - Check promotion: dark reaches row 7, light reaches row 0 → become king.
  - Update movesWithoutCapture (reset on capture, increment otherwise).
  - Switch currentPlayer.
- `bool isGameOver()`: current player has no legal moves, or movesWithoutCapture >= 40.
- `CheckersPlayer? winner()`: if game over, the player who CAN still move wins. If 40-move rule, return null (draw).
- `toJson()` / `fromJson()` for state serialization.
- `CheckersBoard copy()` for AI.

- [ ] **Step 3: Write checkers_game.dart**

StatefulWidget implementing GameInterface. Receives GameContext.

**State:** CheckersBoard engine, selectedPiece (int? — square index), legalMovesForSelected (List<CheckersMove>), isMyTurn, isAnimating, gameOver.

**Determine sides:** Player is always "dark" (bottom). If `context.userId == session.player_1_id` → dark, else → light. For simplicity in MVP: player at bottom is always the current user, board is oriented accordingly.

**My turn flow:**
1. Tap a square with my piece → select it, compute legal moves from that square, highlight targets
2. Tap a highlighted target → make move, animate, send via `context.socketService.sendMove({'from': move.from, 'to': move.to, 'captured': move.captured})`
3. If multi-jump available after capture, auto-select the piece for continuation

**Opponent turn:** `onOpponentMove(data)` → engine.makeMove(parsed move) → animate → my turn

**Practice AI:** When opponent's turn in practice mode, delay 500ms, pick random legal move, apply.

**UI:**
- 8x8 grid using GridView.count(crossAxisCount: 8)
- Dark squares: Color(0xFF769656), light squares: Color(0xFFEEEED2)
- Pieces: Container with BoxDecoration(shape: BoxShape.circle) — dark=#1A1A1A, light=#FFFFFF with dark border
- Kings: same circle + small crown Icon(Icons.star_rounded, size: 12) overlaid in center
- Selected piece: blue border glow
- Legal move targets: green semi-transparent overlay on square
- Capture targets: red semi-transparent overlay
- Board fits in a square AspectRatio(1.0) widget

- [ ] **Step 4: Write checkers_registration.dart**

```dart
import 'package:flutter/material.dart';
import '../../core/game_registry.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_context.dart';
import 'checkers_game.dart';

void registerCheckers() {
  GameRegistry.instance.register(GameDefinition(
    id: 'checkers',
    name: 'Checkers',
    nameSwahili: 'Dama',
    category: GameCategory.board,
    icon: Icons.grid_on_rounded,
    description: 'Classic checkers. Jump and capture all opponent pieces!',
    descriptionSwahili: 'Dama ya kawaida. Ruka na kamata vipande vyote vya mpinzani!',
    minPlayers: 1,
    maxPlayers: 2,
    modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
    stakeSafe: true,
    maxStakeTier: StakeTier.diamond,
    estimatedMinutes: 3,
    builder: (GameContext ctx) => CheckersGame(context: ctx),
  ));
}
```

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/games/games/checkers/
```

---

## Task 3: Chess — Game + Registration

**Files:**
- Create: `lib/games/games/chess/chess_game.dart`
- Create: `lib/games/games/chess/chess_registration.dart`

No engine file — uses the `chess` Dart package for all logic.

- [ ] **Step 1: Create directory**

```bash
mkdir -p lib/games/games/chess
```

- [ ] **Step 2: Write chess_game.dart**

StatefulWidget implementing GameInterface. Receives GameContext.

**Imports:** `import 'package:chess/chess.dart' as chess_lib;` (alias to avoid naming conflicts with our GameInterface).

**State:** `chess_lib.Chess game` (the chess engine instance), selectedSquare (String? — algebraic like 'e2'), legalMovesForSelected (List<String>), isMyTurn, gameOver, player1TimeMs (300000 = 5min), player2TimeMs, clockTimer.

**Initialize:** `game = chess_lib.Chess()` creates standard starting position. If reconnecting, use `chess_lib.Chess.fromFEN(context.gameState['fen'])`.

**My color:** Derive from userId — player_1 is always white. Board flipped for black player.

**Move flow:**
1. Tap square with my piece → select, get legal moves from `game.moves({'square': square})`
2. Tap target → `game.move({'from': selectedSquare, 'to': target, 'promotion': 'q'})` (auto-queen for now)
3. If pawn promotion to back rank: show bottom sheet with 4 options (q/r/b/n) before making move
4. Send move: `context.socketService.sendMove({'from': from, 'to': to, 'promotion': promo})`
5. Check for game over: `game.game_over` → checkmate, stalemate, draw, insufficient material

**Opponent move:** `onOpponentMove(data)` → `game.move(data)` → update UI

**Clock:** Timer.periodic every 100ms. Decrements active player's time. Time-out = loss.

**Practice AI:** Random legal move after 500ms delay.

**UI:**
- 8x8 grid, AspectRatio(1.0)
- Light squares: Color(0xFFF0D9B5), dark squares: Color(0xFFB58863)
- Pieces as Unicode characters in Text widget (fontSize 32):
  - White: ♔♕♖♗♘♙ mapped from chess_lib piece types
  - Black: ♚♛♜♝♞♟
- Selected square: blue highlight
- Legal moves: green dots (small centered circle on empty squares, red-tinted for captures)
- Check: king square pulses with red background
- Clock: two countdown timers displayed above/below board "MM:SS"
- Captured pieces: small row of taken piece symbols next to each clock

**Piece mapping helper:**
```dart
String pieceToUnicode(chess_lib.Piece? piece) {
  if (piece == null) return '';
  const white = {
    chess_lib.PieceType.KING: '♔', chess_lib.PieceType.QUEEN: '♕',
    chess_lib.PieceType.ROOK: '♖', chess_lib.PieceType.BISHOP: '♗',
    chess_lib.PieceType.KNIGHT: '♘', chess_lib.PieceType.PAWN: '♙',
  };
  const black = {
    chess_lib.PieceType.KING: '♚', chess_lib.PieceType.QUEEN: '♛',
    chess_lib.PieceType.ROOK: '♜', chess_lib.PieceType.BISHOP: '♝',
    chess_lib.PieceType.KNIGHT: '♞', chess_lib.PieceType.PAWN: '♟',
  };
  return piece.color == chess_lib.Color.WHITE ? white[piece.type]! : black[piece.type]!;
}
```

**State serialization:** `getCurrentState()` returns `{'fen': game.fen, 'p1_time': player1TimeMs, 'p2_time': player2TimeMs}`.

- [ ] **Step 3: Write chess_registration.dart**

```dart
void registerChess() {
  GameRegistry.instance.register(GameDefinition(
    id: 'chess',
    name: 'Chess',
    nameSwahili: 'Chesi',
    category: GameCategory.board,
    icon: Icons.castle_rounded,
    description: 'The classic game of strategy. Checkmate your opponent!',
    descriptionSwahili: 'Mchezo wa kawaida wa mkakati. Mshinde mpinzani wako!',
    minPlayers: 1,
    maxPlayers: 2,
    modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
    stakeSafe: true,
    maxStakeTier: StakeTier.diamond,
    estimatedMinutes: 5,
    builder: (GameContext ctx) => ChessGame(context: ctx),
  ));
}
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/games/games/chess/
```

---

## Task 4: Bao la Kiswahili — Engine + Game + Registration

The most complex game. The engine file is the critical piece — it encodes the full traditional Bao rules.

**Files:**
- Create: `lib/games/games/bao/bao_engine.dart`
- Create: `lib/games/games/bao/bao_game.dart`
- Create: `lib/games/games/bao/bao_registration.dart`

- [ ] **Step 1: Create directory**

```bash
mkdir -p lib/games/games/bao
```

- [ ] **Step 2: Write bao_engine.dart**

Pure Dart. This is the core of the Bao implementation.

**Enums:**
- `BaoPlayer { north, south }` with `opponent` getter
- `BaoPhase { namua, mtaji }`
- `BaoAnimType { place, sow, capture }`

**BaoAnimStep:** `{ BaoAnimType type; int pit; int seedCount; }`

**Board layout constants:**
```
North outer: indices 0-7   (left to right from North's perspective)
North inner: indices 8-15  (left to right, pit 12 = North kuu)
South inner: indices 16-23 (left to right, pit 20 = South kuu)
South outer: indices 24-31 (left to right)
```

**Sowing direction:** Counter-clockwise within own two rows. South inner: left to right (16→23), South outer: right to left (31→24). North inner: right to left (15→8), North outer: left to right (0→7).

**BaoBoard class:**
- `List<int> pits` — 32 ints
- `int northStock, southStock` — namua seeds remaining
- `BaoPhase phase`
- `BaoPlayer currentPlayer`

- `BaoBoard()` constructor — initial state: 2 seeds in each of the 16 inner-row pits (indices 8-15 and 16-23), 0 in outer rows, 10 stock per player.

- `List<int> legalMoves(BaoPlayer player)` → list of pit indices:
  - **Namua:** Any non-empty pit in player's inner row. Plus special: if player has a capture available, they may be required to take it (standard Bao requires capturing move if available during namua).
  - **Mtaji:** Any pit on player's side with 2+ seeds.

- `List<BaoAnimStep> makeMove(int pitIndex)` → returns animation steps:
  - **Namua:** Place 1 seed from stock into pitIndex. Then sow from that pit. Check captures. If both stocks empty after this move, transition to mtaji.
  - **Mtaji:** Pick up all seeds from pitIndex. Sow counter-clockwise.
  - **Sowing:** Drop 1 seed per pit along the sowing path. If last seed lands in:
    - Non-empty pit on own inner row, AND opposite pit (opponent's inner row) is non-empty → CAPTURE: take all seeds from opponent's inner pit AND the outer pit directly behind it. Continue sowing with captured seeds from the capturing pit.
    - Non-empty pit (no capture available) → pick up all seeds including the one just placed, continue sowing (relay sowing).
    - Empty pit → turn ends.

- `bool isGameOver()` → current player has no legal moves.

- `BaoPlayer? winner()` → opponent of the player with no moves.

- `int _opposite(int innerPitIndex)` → returns the opponent's inner pit directly across. For South inner pit i (16-23): opposite is (15 - (i - 16)) = (31 - i). For North inner pit i (8-15): opposite is (16 + (15 - i)) = (31 - i). So opposite is always `31 - pitIndex` for inner pits.

- `int _outerBehind(int innerPitIndex)` → the outer pit behind an inner pit. For South inner pit i: outer = i + 8 (south outer row). For North inner pit i: outer = i - 8 (north outer row).

- `List<int> _sowingPath(BaoPlayer player, int startPit)` → ordered list of pit indices for sowing from startPit in counter-clockwise direction within player's two rows.

- `toJson()` / `fromJson()` / `copy()`

- [ ] **Step 3: Write bao_game.dart**

StatefulWidget implementing GameInterface.

**State:** BaoBoard engine, selectedPit (int?), legalPits (List<int>), animSteps (List<BaoAnimStep>), isAnimating, isMyTurn, gameOver.

**Player mapping:** South = player at bottom = context.userId if player_1. North = opponent.

**My turn:**
1. Legal pits highlighted with green tint
2. Tap a legal pit → engine.makeMove(pit) → get animation steps
3. Animate: iterate through steps with 200ms delay each (place seed → sow pit by pit → capture flash)
4. Send move: `context.socketService.sendMove({'pit': pitIndex})`
5. Switch turn

**Opponent turn:** `onOpponentMove({'pit': N})` → engine.makeMove(N) → animate → my turn

**Practice AI:** Random legal move after 500ms.

**UI:**
- Board: 4 rows × 8 columns of circular pits
- Render as Column of 4 Rows, each with 8 pit widgets
- Pit: Container(width: 40, height: 40) with CircleAvatar showing seed count
- Board background: Color(0xFFD4A76A) (wood/tan)
- Pit color: Color(0xFF8B6914) (darker brown)
- Seeds: white text number inside pit (fontSize 16, bold)
- Kuu pits: slightly larger, gold border (Color(0xFFDAA520))
- Stock display: "Stock: N" text at top (North) and bottom (South)
- Phase indicator: "Namua" or "Mtaji" badge
- Legal pits: green border when it's your turn
- Capture animation: opponent pits flash red briefly
- The board should fit in ~340dp width (8 × 42dp with 2dp spacing)

- [ ] **Step 4: Write bao_registration.dart**

```dart
void registerBao() {
  GameRegistry.instance.register(GameDefinition(
    id: 'bao',
    name: 'Bao la Kiswahili',
    nameSwahili: 'Bao la Kiswahili',
    category: GameCategory.board,
    icon: Icons.circle_outlined,
    description: 'Tanzania\'s traditional mancala board game. UNESCO cultural heritage!',
    descriptionSwahili: 'Mchezo wa jadi wa bao wa Tanzania. Urithi wa kitamaduni wa UNESCO!',
    minPlayers: 1,
    maxPlayers: 2,
    modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
    stakeSafe: true,
    maxStakeTier: StakeTier.diamond,
    estimatedMinutes: 5,
    builder: (GameContext ctx) => BaoGame(context: ctx),
  ));
}
```

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/games/games/bao/
```

---

## Task 5: Kadi — Engine + Game + Registration

**Files:**
- Create: `lib/games/games/kadi/kadi_engine.dart`
- Create: `lib/games/games/kadi/kadi_game.dart`
- Create: `lib/games/games/kadi/kadi_registration.dart`

- [ ] **Step 1: Create directory**

```bash
mkdir -p lib/games/games/kadi
```

- [ ] **Step 2: Write kadi_engine.dart**

Pure Dart card game engine.

**Enums:**
- `KadiSuit { hearts, diamonds, clubs, spades }` with symbol getter (♥♦♣♠) and color (red/black)
- `KadiRank { ace, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king }` with displayName ('A','2'...'K') and value (for scoring: A=1, 2-10=face, J/Q/K=10)

**KadiCard:** `{ KadiSuit? suit; KadiRank? rank; bool isJoker; }` with displayName, pointValue (Joker=50). Equality by suit+rank (or both Jokers equal).

**KadiState class:**
- `List<KadiCard> player1Hand, player2Hand`
- `List<KadiCard> discardPile` (top card = last element)
- `List<KadiCard> drawPile`
- `int currentPlayer` (1 or 2)
- `int drawPenalty` (accumulated from 2/3/Joker, default 0)
- `KadiSuit? declaredSuit` (set when Ace/Joker played)
- `bool kadiCalled` (per-turn flag)

- `KadiState.newGame(int seed)`: create 54-card deck, shuffle with seeded Random, deal 5 each, flip one to discard pile. If first discard is special card, just treat as normal (no effect on first turn).

- `KadiCard get topDiscard` → discardPile.last

- `bool canPlay(KadiCard card)`:
  - If drawPenalty > 0: can only play 2, 3, or Joker (to stack penalty). Everything else = must draw.
  - Joker: always playable
  - Ace: always playable (wild)
  - Otherwise: matches topDiscard rank OR matches effective suit (declaredSuit if set, else topDiscard suit)

- `void playCard(int player, KadiCard card, {KadiSuit? newSuit})`:
  - Remove card from player's hand, add to discard pile
  - Clear declaredSuit
  - Apply special effects:
    - 2: drawPenalty += 2
    - 3: drawPenalty += 3
    - Joker: drawPenalty += 5
    - 8: skip opponent (currentPlayer stays same — effectively double turn)
    - Jack: reverse (in 2-player = skip, same as 8)
    - Ace/Joker: set declaredSuit = newSuit
  - Switch turn (unless 8/Jack skip)
  - Reset kadiCalled = false

- `KadiCard drawCard(int player)`:
  - If drawPile empty, reshuffle discardPile (keep top card) into drawPile
  - Draw one card, add to player's hand
  - If drawPenalty > 0, draw penalty count cards, reset penalty to 0
  - Switch turn

- `List<KadiCard> currentHand(int player)` → hand for player 1 or 2

- `bool isGameOver()` → any hand empty

- `int? winner()` → player with empty hand (1 or 2), null if not over

- `int score(int loser)` → sum of loser's hand point values

- `toJson()` / `fromJson()`

- [ ] **Step 3: Write kadi_game.dart**

StatefulWidget implementing GameInterface.

**State:** KadiState engine, selectedCard (int? — index in hand), isMyTurn, showSuitSelector, gameOver, mustDraw (when drawPenalty > 0 and no stackable card).

**My player:** player_1 = 1, player_2 = 2. Determined from context.userId.

**Turn flow:**
1. Cards in hand shown at bottom. Playable cards slightly raised/brighter, unplayable greyed.
2. Tap a playable card → select it (card raises up)
3. Tap discard pile OR tap selected card again → play it
4. If Ace/Joker: show suit selector (4 colored buttons: ♥♦♣♠)
5. If no playable card: tap draw pile to draw
6. If drawPenalty > 0 and you have a 2/3/Joker: can play it to stack. Otherwise must tap draw pile.
7. After playing, if hand size == 1: "KADI!" button appears (3 second timer to tap it)
8. Send move: `socketService.sendMove({'type': 'play'/'draw', 'card': card.toJson(), 'suit': suit?.name})`

**Opponent turn:** `onOpponentMove(data)` → apply to engine → animate card play → my turn

**Practice AI:** If can play, play random playable card (prefer special cards). Else draw. Always calls Kadi.

**UI:**
- Bottom: player's hand — horizontal scrollable row of card widgets. Each card ~60×85dp, white background, rounded corners, suit symbol + rank text. Red for hearts/diamonds, black for clubs/spades.
- Top: opponent's hand — row of face-down cards (dark grey backs) with count badge
- Center-left: discard pile (top card visible, slight stack offset effect)
- Center-right: draw pile (face-down with count)
- "KADI!" button: appears bottom-center when hand has 1 card, pulses with gold color, 3s timer
- Suit selector: 4 large buttons in a row when playing Ace/Joker
- Draw penalty indicator: red badge on draw pile "Draw N"

- [ ] **Step 4: Write kadi_registration.dart**

```dart
void registerKadi() {
  GameRegistry.instance.register(GameDefinition(
    id: 'kadi',
    name: 'Kadi',
    nameSwahili: 'Kadi',
    category: GameCategory.card,
    icon: Icons.style_rounded,
    description: 'The classic East African card game. Play your hand, call KADI!',
    descriptionSwahili: 'Mchezo wa kadi wa Afrika Mashariki. Cheza kadi zako, piga KADI!',
    minPlayers: 1,
    maxPlayers: 2,
    modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
    stakeSafe: true,
    maxStakeTier: StakeTier.diamond,
    estimatedMinutes: 3,
    builder: (GameContext ctx) => KadiGame(context: ctx),
  ));
}
```

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/games/games/kadi/
```

---

## Task 6: Ludo — Engine + Board Painter + Game + Registration

**Files:**
- Create: `lib/games/games/ludo/ludo_engine.dart`
- Create: `lib/games/games/ludo/ludo_board_painter.dart`
- Create: `lib/games/games/ludo/ludo_game.dart`
- Create: `lib/games/games/ludo/ludo_registration.dart`

- [ ] **Step 1: Create directory**

```bash
mkdir -p lib/games/games/ludo
```

- [ ] **Step 2: Write ludo_engine.dart**

Pure Dart.

**LudoPlayer:** `{ int id; List<LudoToken> tokens; int startSquare; int homeEntrySquare; }` — 2 players for MVP.

**LudoToken:** `{ LudoTokenState state; int position; }` where state = home/active/finished.

**LudoBoard class:**
- Board path: 52 squares (0-51) in a loop
- Each player's start: player1 at square 0, player2 at square 26
- Each player's home entry: 6 squares before their start (player1 enters home at square 50, player2 at square 24)
- Home column: 6 squares per player (separate from main path, indices 100-105 and 200-205)
- Safe squares: start squares (0, 26) + additional marked squares (8, 13, 21, 34, 39, 47)
- `List<int> safeSquares`

- `int rollDice(Random rng)` → 1-6

- `List<LudoMove> legalMoves(int player, int diceValue)`:
  - If 6: can move token out of home to start square (if start square not occupied by own token)
  - For each active token: can advance diceValue squares. Check: destination not occupied by own token. If entering home column, exact count needed.
  - If no legal moves: return empty (turn lost)

- `LudoMoveResult makeMove(LudoMove move)`:
  - Move token to destination
  - If destination has opponent token (and not safe square): capture — send opponent token home
  - If token reaches end of home column: mark as finished
  - Return result with capture info

- `bool isGameOver()` → any player has all 4 tokens finished

- `int? winner()` → player with all tokens finished

- `toJson()` / `fromJson()`

**LudoMove:** `{ int tokenIndex; int from; int to; bool exitsHome; }`
**LudoMoveResult:** `{ bool captured; int? capturedTokenOwner; }`

- [ ] **Step 3: Write ludo_board_painter.dart**

CustomPainter that draws the classic Ludo board.

Simplified monochromatic design (not traditional colors):
- Board background: white
- Path squares: light grey borders, white fill
- Player 1 home base + home column: _kPrimary (#1A1A1A) tinted
- Player 2 home base + home column: _kSecondary (#666666) tinted
- Safe squares: marked with small dot
- Center: divided triangles pointing inward
- Board size: adapts to given Size (square)

Draw in order: background → grid lines → colored regions → safe markers → center triangles.

Tokens are NOT drawn by the painter — they're overlaid as positioned widgets (makes animation easier).

- [ ] **Step 4: Write ludo_game.dart**

StatefulWidget implementing GameInterface.

**State:** LudoBoard engine, diceValue (int?), hasRolled, isMyTurn, legalMoves, selectedToken, consecutiveSixes, isAnimating, gameOver, seededRandom.

**Dice:** Seeded Random for multiplayer. Animated: brief "rolling" display (cycling numbers for 500ms) then show result.

**Turn flow:**
1. "Roll Dice / Ruka Dadu" button
2. Roll → show result → compute legal moves
3. If no legal moves: show "No moves" briefly → end turn
4. If legal moves: highlight movable tokens with pulsing effect
5. Tap token → move it (animate along path)
6. If captured opponent: opponent token animates back to base
7. If rolled 6: bonus turn (up to 3, third 6 = lose turn)
8. Send move: `socketService.sendMove({'dice': value, 'token': tokenIndex, 'to': destination})`

**Practice AI:** Roll dice, pick random legal move.

**UI:**
- Board: CustomPaint with LudoBoardPainter, sized as square (AspectRatio 1.0)
- Tokens: Positioned circles (28dp diameter) overlaid on board at computed pixel positions
- Player 1 tokens: _kPrimary with white number (1-4)
- Player 2 tokens: white with _kPrimary border + number
- Dice: centered below board, 60×60 Container with rounded corners, large dice number
- "Roll" button: below dice
- Token position → pixel: `_squareToOffset(int square, Size boardSize)` maps logical square to pixel coordinates on the painted board

- [ ] **Step 5: Write ludo_registration.dart**

```dart
void registerLudo() {
  GameRegistry.instance.register(GameDefinition(
    id: 'ludo',
    name: 'Ludo',
    nameSwahili: 'Ludo',
    category: GameCategory.board,
    icon: Icons.casino_rounded,
    description: 'Roll the dice and race your tokens home. The classic board game!',
    descriptionSwahili: 'Ruka dadu na pita tokeni zako nyumbani. Mchezo wa kawaida wa bodi!',
    minPlayers: 1,
    maxPlayers: 2,
    modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
    stakeSafe: false,
    maxStakeTier: StakeTier.gold,
    estimatedMinutes: 5,
    builder: (GameContext ctx) => LudoGame(context: ctx),
  ));
}
```

Note: `stakeSafe: false` and `maxStakeTier: StakeTier.gold` because Ludo has dice luck.

- [ ] **Step 6: Verify**

```bash
flutter analyze lib/games/games/ludo/
```

---

## Task 7: Wire Up All 5 Registrations in games_module.dart

**Files:**
- Modify: `lib/games/games_module.dart`

- [ ] **Step 1: Update games_module.dart**

```dart
// lib/games/games_module.dart

import 'package:flutter/material.dart';
import 'pages/games_home_page.dart';

// Phase 1 game registrations
import 'games/trivia/trivia_registration.dart';
import 'games/twenty48/twenty48_registration.dart';
import 'games/speed_math/speed_math_registration.dart';
import 'games/reaction/reaction_registration.dart';
import 'games/tap_speed/tap_speed_registration.dart';

// Phase 2 game registrations
import 'games/bao/bao_registration.dart';
import 'games/kadi/kadi_registration.dart';
import 'games/ludo/ludo_registration.dart';
import 'games/chess/chess_registration.dart';
import 'games/checkers/checkers_registration.dart';

// Re-export core types for convenience
export 'core/game_enums.dart';
export 'core/game_definition.dart';
export 'core/game_interface.dart';
export 'core/game_context.dart';
export 'core/game_registry.dart';

/// Top-level module widget. Renders inside _ProfileTabPage (no AppBar).
class GamesModule extends StatelessWidget {
  final int userId;
  const GamesModule({super.key, required this.userId});

  static bool _registered = false;
  static void _registerGames() {
    if (_registered) return;
    _registered = true;
    // Phase 1
    registerTrivia();
    registerTwenty48();
    registerSpeedMath();
    registerReaction();
    registerTapSpeed();
    // Phase 2
    registerBao();
    registerKadi();
    registerLudo();
    registerChess();
    registerCheckers();
  }

  @override
  Widget build(BuildContext context) {
    _registerGames();
    return GamesHomePage(userId: userId);
  }
}
```

- [ ] **Step 2: Verify full module**

```bash
flutter analyze lib/games/
```

Expected: No issues found. GameRegistry.instance.count == 10 after build.

---

## Verification Checklist

After all tasks:

- [ ] `flutter pub deps | grep chess` — chess package installed
- [ ] `flutter analyze lib/games/` — zero errors
- [ ] GamesModule registers 10 games total (5 Phase 1 + 5 Phase 2)
- [ ] GamesHomePage shows 10 game cards in grid
- [ ] **Checkers:** Board renders 8x8, pieces placed correctly, tap to select/move, captures work, kings promote, mandatory captures enforced, game over detected
- [ ] **Chess:** Board renders, pieces display as Unicode, legal moves highlighted, check detected, checkmate ends game, clock counts down
- [ ] **Bao:** 4x8 board renders, pits show seed counts, namua phase places from stock, sowing animates, captures work, mtaji phase transitions, game over detected
- [ ] **Kadi:** Cards dealt, hand displayed, play by rank/suit match, special cards work (2/3 draw penalty, 8 skip, Ace wild, Joker wild+5), Kadi call button appears at 1 card, scoring on game end
- [ ] **Ludo:** Board renders with CustomPainter, dice rolls, tokens move along path, captures send opponent home, safe squares protect, home column entry works, 6=bonus turn, all-finished=win
