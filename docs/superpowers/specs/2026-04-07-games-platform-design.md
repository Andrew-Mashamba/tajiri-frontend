# TAJIRI Games Platform — Design Spec (Sub-project 1)

**Date:** 2026-04-07
**Status:** Approved
**Scope:** Games platform infrastructure — plugin system, challenge/matchmaking, stakes/escrow, real-time multiplayer, leaderboards. No individual games yet (those are Sub-projects 2-6).

## Overview

A mini-games platform inside TAJIRI where users play embedded games, challenge friends, and wager money from their TAJIRI Wallet. Games plug into the platform via a registry/interface pattern. The platform handles all shared concerns: discovery, matchmaking, stakes, real-time communication, leaderboards, and results.

## Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Architecture | Game Engine Pattern (plugin registry) | 25 games planned — each implements GameInterface, platform never changes |
| Decomposition | 6 sub-projects | Platform first, then games in phases of 5 |
| Multiplayer | Laravel Reverb WebSocket | Already in TAJIRI stack, private channels per session |
| Stakes | TAJIRI Wallet escrow | Keep money in ecosystem, 10% platform rake |
| Anti-cheat | Server-authoritative | Server validates moves/scores, client is renderer only |
| Matchmaking | ELO-based for ranked, direct invite for friends | Fair pairing, social engagement |

---

## 1. Game Registry & Plugin System

### GameDefinition

Every game provides a static definition:

```
GameDefinition
  id: String                — 'trivia', 'bao', 'chess'
  name: String              — 'Trivia Showdown'
  nameSwahili: String       — 'Mashindano ya Maswali'
  category: GameCategory    — puzzle/trivia/word/card/board/arcade/math/strategy
  icon: IconData
  description: String
  descriptionSwahili: String
  minPlayers: int           — 1 or 2
  maxPlayers: int           — 2, 4, 6
  modes: List<GameMode>     — [practice, friend, ranked]
  stakeSafe: bool           — true for pure skill games
  maxStakeTier: StakeTier   — limits max wager for luck-heavy games
  estimatedMinutes: int     — 1-5
  builder: GameWidget Function(GameContext)  — factory
```

### GameCategory Enum

9 categories: puzzle, trivia, word, card, board, arcade, math, strategy, all.
Each has: displayName (English), displayNameSwahili, icon.

### GameRegistry

Singleton holding all registered games:
- `register(GameDefinition)` — called by each game module at import
- `allGames` → List<GameDefinition> sorted by name
- `byCategory(GameCategory)` → filtered list
- `get(String id)` → single definition or null
- `search(String query)` → name/description search

### GameContext

Runtime context passed to every game widget when it starts:

```
GameContext
  sessionId: int
  gameId: String
  userId: int
  opponentId: int?
  opponentName: String?
  mode: GameMode (practice/friend/ranked)
  gameSeed: String (server-generated deterministic seed)
  gameState: Map<String, dynamic>? (for reconnection)
  socketService: GameSocketService (for sending/receiving moves)
  onGameComplete: Function(GameResult) (callback to platform)
```

### GameInterface

Abstract class every game widget implements:

```dart
abstract class GameInterface {
  /// Unique game identifier
  String get gameId;
  
  /// Handle opponent's move received via WebSocket
  void onOpponentMove(Map<String, dynamic> moveData);
  
  /// Handle reconnection — restore from saved state
  void onReconnect(Map<String, dynamic> savedState);
  
  /// Get current game state for saving (disconnection recovery)
  Map<String, dynamic> getCurrentState();
}
```

The game widget extends StatefulWidget and implements GameInterface. It receives GameContext as a constructor parameter.

---

## 2. Game Lifecycle & Shared Screens

### Screen Flow

```
GamesHomePage (browse/discover)
  → GameLobbyPage (configure match)
    → GameRoomPage (waiting/countdown)
      → GamePlayPage (the actual game runs here)
        → GameResultPage (winner, payout, rematch)
```

### GamesHomePage (replaces current shell)

- Search bar for finding games by name
- Category filter chips (All, Puzzle, Trivia, Word, Card, Board, Arcade, Math, Strategy)
- "My Matches" section: pending challenges, active games, recent results (last 5)
- Featured games horizontal scroll
- Full game grid (2 columns, reads from GameRegistry)
- No AppBar (rendered inside _ProfileTabPage)
- Pull-to-refresh

### GameLobbyPage

- Game info header (icon, name, description, estimated time)
- Mode selection cards:
  - **Practice** — Solo, no stakes. "Zoezi / Practice" label
  - **Challenge Friend** — Pick friend from contacts, set stake. "Changamoto Rafiki / Challenge Friend"
  - **Ranked Match** — Auto-matched, fixed tier. "Mechi ya Kiwango / Ranked Match"
- Stake selection (shown for friend/ranked modes):
  - Tier chips: Free | Bronze TZS 500 | Silver TZS 2,000 | Gold TZS 5,000 | Diamond TZS 20,000
  - Custom amount input for friend challenges (TZS 100 - 50,000)
  - Wallet balance shown. Insufficient funds greyed out.
- "Start Match" button
  - Practice: creates session, goes to GameRoomPage immediately (no opponent)
  - Friend: locks stake, sends challenge, goes to GameRoomPage (waiting)
  - Ranked: locks stake, enters matchmaking queue, goes to GameRoomPage (searching)

### GameRoomPage

- Shows both player slots (Player 1 filled, Player 2 waiting)
- For friend challenge: "Waiting for [name]..." with 5-minute timeout
- For ranked: "Searching for opponent..." with 60-second timeout
- Once opponent joins: player cards shown, 3-2-1 countdown animation
- Auto-cancel on timeout, refund stake
- WebSocket connected to `game.{sessionId}` channel

### GamePlayPage

- Top bar: game timer (if timed), Player 1 score | Player 2 score
- Player banners on left/right showing avatar, name, current score
- Center: the GameWidget from registry (fills available space)
- Receives WebSocket events, forwards to game widget via onOpponentMove()
- When game widget calls onGameComplete(result):
  - Sends result to backend: POST /api/games/sessions/{id}/end
  - Navigates to GameResultPage

### GameResultPage

- Winner announcement with confetti animation
- Score comparison: Player 1 vs Player 2
- Stakes result: "You won TZS 1,800!" or "You lost TZS 500" or "Draw — stakes refunded"
- Updated wallet balance
- Buttons:
  - "Rematch" — 30-second timer, same game/stake, new session
  - "New Game" — back to GameLobbyPage
  - "Home" — back to GamesHomePage
- Optional "Share to Feed" button

---

## 3. Challenge & Matchmaking System

### Friend Challenge Flow

1. User A: GameLobbyPage → "Challenge Friend" → picks friend from contacts
2. Backend: creates game_session (status=pending), locks A's stake in escrow
3. Delivery: Push notification + in-app notification + optional chat message card
   - "Andrew challenged you to Bao! Stake: TZS 2,000. Accept / Decline"
4. User B: Taps → opens GameLobbyPage with pre-filled challenge
5. Accept → B's stake locked → both to GameRoomPage → countdown → play
   OR Decline → A refunded, session cancelled
   OR 5-minute timeout → auto-decline, A refunded

### Ranked Matchmaking Flow

1. User A: selects game + stake tier → enters queue
2. Backend matches by: same game_id, same stake_tier, ELO within ±200
3. Match found: both stakes locked → session created → WebSocket room → countdown
4. No match in 30s: widen ELO to ±400. No match in 60s: "No opponent found"
5. User can cancel queue at any time (refund)

### Practice Mode

Solo play. No opponent, no stakes, no leaderboard impact. Game-specific logic handles solo mode (AI opponent for board games, target score for puzzle/trivia).

### Backend: game_sessions Table

```
game_sessions
  id
  game_id: string ('bao', 'trivia', etc.)
  mode: string (practice/friend/ranked)
  status: string (pending/matching/active/completed/cancelled/forfeited)
  stake_tier: string (free/bronze/silver/gold/diamond/custom)
  stake_amount: decimal(12,2)
  stake_currency: string (default 'TZS')
  platform_fee: decimal(12,2)
  player_1_id: FK users
  player_2_id: FK users (nullable)
  player_1_score: int (default 0)
  player_2_score: int (default 0)
  winner_id: FK users (nullable)
  game_seed: string
  game_state: json (nullable — current state for reconnection)
  room_code: string (WebSocket room identifier)
  started_at: timestamp (nullable)
  ended_at: timestamp (nullable)
  timestamps
```

### Real-Time Communication

Uses Laravel Reverb. Private channel per session: `game.{sessionId}`.

Broadcast events:
- `PlayerJoined` — opponent connected, payload: {userId, userName, avatar}
- `GameStarted` — countdown done, game begins, payload: {seed, initialState}
- `PlayerMove` — move from opponent, payload: game-specific {moveType, moveData}
- `GameEnded` — server-determined result, payload: {winnerId, scores, payouts}
- `PlayerDisconnected` — grace period started, payload: {userId, gracePeriodSeconds: 30}
- `PlayerReconnected` — resumed, payload: {userId, gameState}

---

## 4. Stake & Escrow System

### Escrow Flow

```
LOCK:    Player accepts → POST /api/games/escrow/lock → wallet debited → escrow_id returned
PLAY:    Stakes locked, untouchable during game
SETTLE:  Game ends → POST /api/games/escrow/settle → winner credited, platform fee taken
REFUND:  Cancel/no opponent → POST /api/games/escrow/refund → full return to wallet
DRAW:    Both refunded in full, no rake
```

### Stake Tiers

| Tier | Entry | Winner Gets | Platform Fee (10%) |
|---|---|---|---|
| Free | TZS 0 | Bragging rights | TZS 0 |
| Bronze | TZS 500 | TZS 900 | TZS 100 |
| Silver | TZS 2,000 | TZS 3,600 | TZS 400 |
| Gold | TZS 5,000 | TZS 9,000 | TZS 1,000 |
| Diamond | TZS 20,000 | TZS 36,000 | TZS 4,000 |
| Custom | TZS 100 - 50,000 | (2x - 10%) | 10% of pool |

### Backend Tables

```
game_escrows
  id, session_id, user_id
  amount: decimal(12,2)
  currency: string (default 'TZS')
  status: string (locked/settled/refunded)
  settled_amount: decimal(12,2) (what user received, 0 if lost)
  timestamps

game_transactions
  id, session_id, user_id
  type: string (stake_lock/win_payout/platform_fee/refund)
  amount: decimal(12,2)
  currency: string
  wallet_transaction_id: string (nullable — reference to wallet system)
  timestamps
```

### Safety Guards

- **Insufficient funds:** Check wallet balance before showing stake options. Grey out unaffordable tiers.
- **Daily loss limit:** TZS 50,000/day default. User can lower in settings. Cannot raise same day.
- **Cool-off prompt:** After 5 consecutive losses, show "Take a break?" (dismissable).
- **Age gate:** Stakes require verified age 18+ from user profile.
- **Practice first:** Must play 3 practice games before stakes for any game.
- **Stake-safety per game:** Games with luck elements (Ludo) have lower maxStakeTier than pure skill games (Chess).

---

## 5. Leaderboards & Social

### Leaderboard Scopes

| Scope | Shows | Engagement Driver |
|---|---|---|
| Global | All TAJIRI players | Status/prestige |
| Friends | People you follow | 3-5x more replay |
| Per-game | Rankings for one game | Mastery |

Time periods: Weekly (resets Monday), Monthly (resets 1st), All-time.

### Backend: game_leaderboard_entries Table

```
game_leaderboard_entries
  id
  user_id: FK users
  game_id: string
  period: string (weekly/monthly/alltime)
  period_key: string ('2026-W15' / '2026-04' / 'all')
  wins: int (default 0)
  losses: int (default 0)
  draws: int (default 0)
  total_score: int (default 0)
  elo_rating: int (default 1000)
  rank: int (computed)
  timestamps

  Unique on [user_id, game_id, period, period_key]
```

ELO: K-factor 32 for first 30 games, then 16. Winner gains, loser loses proportional to rating difference.

### Social Integration

- **Challenge via Chat:** Special message card with game icon, stake, Accept/Decline buttons
- **Feed posts:** Optional after win: "Andrew beat John at Bao! 🏆" — tappable, opens game lobby
- **Match history per friend:** Visible on profile: "You vs Andrew: 5W-3L Chess, 2W-1L Trivia"
- **My Matches on home:** Pending challenges, active games (rejoin), recent results (rematch)

---

## 6. Anti-Cheat & Fair Play

### Server-Authoritative Model

**Turn-based games (Chess, Bao, Checkers):**
- Client sends move request → server validates → server updates game_state → broadcasts to both
- Illegal moves rejected with error

**Score-based games (Trivia, 2048, Speed Math):**
- Server generates seed (questions, board layout)
- Client sends answers/actions with timestamps
- Server replays against seed, computes authoritative score
- Client-reported score ignored

**Reflex games (Reaction Time, Tap Speed):**
- Server sends signal timestamp
- Client sends response timestamp
- Server computes: response - signal - estimated_latency
- Reactions < 100ms rejected as impossible

### Cheat Detection

| Check | Catches |
|---|---|
| Impossible scores | Bots/automation |
| Input speed > human limit | Auto-clickers |
| Same-pair win patterns | Collusion |
| Win rate > 85% over 50+ games | Exploits |
| Device integrity | Rooted/emulator |

Flagged → stakes held → manual review → cleared or banned.

### Disconnection Policy

- 30-second grace period, game state saved in game_sessions.game_state
- Reconnect: resume from saved state
- Timeout: disconnected player forfeits, opponent wins, stakes settled
- Server crash: both refunded, match voided

---

## 7. File Structure

### Frontend (27 files in `lib/games/`)

```
lib/games/
├── games_module.dart
├── core/
│   ├── game_interface.dart
│   ├── game_definition.dart
│   ├── game_registry.dart
│   ├── game_context.dart
│   └── game_enums.dart
├── models/
│   ├── game_session.dart
│   ├── game_escrow.dart
│   ├── leaderboard_entry.dart
│   ├── match_result.dart
│   └── challenge.dart
├── services/
│   ├── games_service.dart
│   └── game_socket_service.dart
├── pages/
│   ├── games_home_page.dart
│   ├── game_lobby_page.dart
│   ├── game_room_page.dart
│   ├── game_play_page.dart
│   └── game_result_page.dart
├── widgets/
│   ├── game_card.dart
│   ├── challenge_card.dart
│   ├── match_card.dart
│   ├── leaderboard_tile.dart
│   ├── stake_selector.dart
│   ├── player_banner.dart
│   └── game_timer.dart
└── games/
    └── (empty — individual games added in Sub-projects 2-6)
```

### Backend (Laravel)

```
app/Http/Controllers/Api/
  ├── GameSessionController.php
  ├── GameEscrowController.php
  └── GameLeaderboardController.php

app/Services/Games/
  ├── MatchmakingService.php
  ├── EscrowService.php
  ├── GameValidationService.php
  └── EloService.php

app/Models/Games/
  ├── GameSession.php
  ├── GameEscrow.php
  ├── GameTransaction.php
  └── GameLeaderboardEntry.php

app/Events/Games/
  ├── PlayerJoined.php
  ├── GameStarted.php
  ├── PlayerMove.php
  ├── GameEnded.php
  └── PlayerDisconnected.php

database/migrations/
  ├── create_game_sessions_table.php
  ├── create_game_escrows_table.php
  ├── create_game_transactions_table.php
  └── create_game_leaderboard_entries_table.php
```

### Backend API Endpoints (12)

```
POST   /api/games/sessions              — Create session
GET    /api/games/sessions/{id}         — Get session state
POST   /api/games/sessions/{id}/join    — Opponent joins
POST   /api/games/sessions/{id}/move    — Submit move (validated)
POST   /api/games/sessions/{id}/end     — End game
GET    /api/games/sessions/active       — Active/pending sessions
GET    /api/games/sessions/history      — Match history

POST   /api/games/escrow/lock           — Lock stake
POST   /api/games/escrow/settle         — Settle payout
POST   /api/games/escrow/refund         — Refund

GET    /api/games/leaderboard           — Global/game leaderboard
GET    /api/games/leaderboard/friends   — Friend-scoped leaderboard
```

---

## 8. Integration with TAJIRI

### Profile Tab

Already registered in `profile_tab_config.dart` as `id: 'games'`. The `_ProfileTabPage._buildContent()` switch case returns `GamesModule(userId: userId)`. Module entry point signature preserved.

### Wallet Integration

GameEscrowController calls existing wallet APIs for debit/credit. Escrow is a game-layer concept — wallet just sees debits and credits.

### Chat Integration

Friend challenges appear as special message cards in existing TAJIRI messaging. Requires a new message type `game_challenge` with structured payload.

### Feed Integration

Game results can be shared as feed posts. Requires a new post type `game_result` with structured payload.

### Design System

Follows `docs/DESIGN.md`: monochromatic palette (#1A1A1A/#FAFAFA), Material 3, SafeArea, 48dp touch targets.

---

## Non-Goals (Explicitly Out of Scope for Sub-project 1)

- Individual game implementations (Sub-projects 2-6)
- Tournaments / bracket system (future)
- Achievement / badge system (future)
- Spectator mode (future)
- Game replays (future)
- Virtual coins / dual currency (future — stakes use real wallet only)
- Ad monetization for free players (future)
- Chat integration message type (noted, deferred)
- Feed integration post type (noted, deferred)
