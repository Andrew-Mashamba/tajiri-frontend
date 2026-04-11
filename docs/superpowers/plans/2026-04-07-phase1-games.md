# TAJIRI Phase 1 Games Implementation Plan (Sub-project 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build 5 playable mini-games (Trivia, 2048, Speed Math, Reaction Time, Tap Speed) that plug into the Games Platform via GameInterface + GameRegistry.

**Architecture:** Each game is 2 files — a StatefulWidget implementing GameInterface + a registration file calling GameRegistry.register(). Games receive a GameContext with sessionId, gameSeed, userId, socketService, and onGameComplete callback. The platform handles everything outside the game widget (lobby, matchmaking, stakes, results).

**Tech Stack:** Flutter/Dart (pure widgets, no game engine), backend Laravel 12 for trivia questions

**Spec:** `docs/superpowers/specs/2026-04-07-phase1-games-design.md`

**Backend server:** SSH `sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180`, project at `/var/www/tajiri.zimasystems.com`

**Existing platform code:**
- `lib/games/core/` — GameInterface, GameDefinition, GameContext, GameRegistry, enums
- `lib/games/services/games_service.dart` — REST API calls
- `lib/games/games_module.dart` — entry point (needs registration imports added)

---

## File Map

### Frontend (10 new files + 1 modified)

| File | Responsibility |
|---|---|
| `lib/games/games/trivia/trivia_game.dart` | Trivia game widget (10 questions, 15s each, scoring) |
| `lib/games/games/trivia/trivia_registration.dart` | Register Trivia with GameRegistry |
| `lib/games/games/twenty48/twenty48_game.dart` | 2048 game widget (4x4 grid, swipe, merge) |
| `lib/games/games/twenty48/twenty48_registration.dart` | Register 2048 with GameRegistry |
| `lib/games/games/speed_math/speed_math_game.dart` | Speed Math widget (60s, arithmetic, scoring) |
| `lib/games/games/speed_math/speed_math_registration.dart` | Register Speed Math with GameRegistry |
| `lib/games/games/reaction/reaction_game.dart` | Reaction Time widget (5 rounds, timing) |
| `lib/games/games/reaction/reaction_registration.dart` | Register Reaction Time with GameRegistry |
| `lib/games/games/tap_speed/tap_speed_game.dart` | Tap Speed widget (10s, tap count) |
| `lib/games/games/tap_speed/tap_speed_registration.dart` | Register Tap Speed with GameRegistry |
| `lib/games/games_module.dart` | **Modify:** add registration imports and calls |

### Backend (4 new files)

| File | Responsibility |
|---|---|
| `database/migrations/xxxx_create_trivia_questions_table.php` | trivia_questions table |
| `database/seeders/TriviaQuestionSeeder.php` | 200+ questions (general, Tanzania, Swahili) |
| `app/Http/Controllers/Api/Games/TriviaController.php` | Questions endpoint with seed-based selection |
| `routes/api.php` | Add trivia questions route |

---

## Task 1: Backend — Trivia Questions Table, Seeder & Controller

**Files:**
- Create: `database/migrations/2026_04_07_300000_create_trivia_questions_table.php`
- Create: `database/seeders/TriviaQuestionSeeder.php`
- Create: `app/Http/Controllers/Api/Games/TriviaController.php`
- Modify: `routes/api.php`

- [ ] **Step 1: SSH into backend**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180
cd /var/www/tajiri.zimasystems.com
```

- [ ] **Step 2: Create migration**

```php
<?php
// database/migrations/2026_04_07_300000_create_trivia_questions_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trivia_questions', function (Blueprint $table) {
            $table->id();
            $table->text('question');
            $table->json('options');         // ["Option A", "Option B", "Option C", "Option D"]
            $table->integer('correct_index'); // 0-3
            $table->string('category');      // general, tanzania, swahili
            $table->string('difficulty')->default('medium'); // easy, medium, hard
            $table->string('source')->default('internal');   // internal, opentdb
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trivia_questions');
    }
};
```

- [ ] **Step 3: Run migration**

```bash
php artisan migrate
```

- [ ] **Step 4: Create seeder with 200+ questions**

Create `database/seeders/TriviaQuestionSeeder.php` with questions in three categories:

**General Knowledge (100 questions)** — science, geography, history, pop culture, sports
**Tanzania (60 questions)** — Kilimanjaro, Serengeti, Julius Nyerere, Zanzibar, Dodoma, Bongo Flava, national parks, Lake Victoria, Tanganyika, independence, currency, regions
**Swahili Language (40 questions)** — vocabulary, proverbs (methali), grammar, translations

Each question: `['question' => '...', 'options' => json_encode([...4 options...]), 'correct_index' => N, 'category' => '...', 'difficulty' => '...']`

Use `DB::table('trivia_questions')->insert($questions)` in batches of 50.

- [ ] **Step 5: Run seeder**

```bash
php artisan db:seed --class=TriviaQuestionSeeder
```

- [ ] **Step 6: Create TriviaController**

```php
<?php
// app/Http/Controllers/Api/Games/TriviaController.php

namespace App\Http\Controllers\Api\Games;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TriviaController extends Controller
{
    public function questions(Request $request): JsonResponse
    {
        $seed = $request->input('seed', 'default');
        $count = $request->integer('count', 10);
        $category = $request->input('category'); // null = mix

        // Use seed to create deterministic selection
        $seedInt = crc32($seed);

        $query = DB::table('trivia_questions');

        if ($category && $category !== 'all') {
            $query->where('category', $category);
        }

        $total = $query->count();
        if ($total === 0) {
            return response()->json(['success' => true, 'data' => []]);
        }

        // Get all IDs, use seeded shuffle to pick deterministic subset
        $allIds = $query->pluck('id')->toArray();
        mt_srand($seedInt);
        shuffle($allIds);
        mt_srand(); // Reset to random

        $selectedIds = array_slice($allIds, 0, min($count, count($allIds)));

        $questions = DB::table('trivia_questions')
            ->whereIn('id', $selectedIds)
            ->get()
            ->map(function ($q) {
                return [
                    'id' => $q->id,
                    'question' => $q->question,
                    'options' => json_decode($q->options, true),
                    'correct_index' => $q->correct_index,
                    'category' => $q->category,
                    'difficulty' => $q->difficulty,
                ];
            });

        // Re-sort by the seeded order
        $idOrder = array_flip($selectedIds);
        $sorted = $questions->sort(fn($a, $b) => ($idOrder[$a['id']] ?? 0) - ($idOrder[$b['id']] ?? 0))->values();

        return response()->json([
            'success' => true,
            'data' => $sorted,
        ]);
    }
}
```

- [ ] **Step 7: Add route**

Append inside the existing `Route::prefix('games')` group in `routes/api.php`:

```php
Route::get('/trivia/questions', [App\Http\Controllers\Api\Games\TriviaController::class, 'questions']);
```

**IMPORTANT:** This route must come BEFORE `Route::get('/sessions/{id}', ...)` to prevent "trivia" being parsed as a session ID.

- [ ] **Step 8: Test**

```bash
curl -s "https://tajiri.zimasystems.com/api/games/trivia/questions?seed=test123&count=5" | python3 -m json.tool | head -20
```

Expected: 5 questions with options and correct_index.

---

## Task 2: Frontend — Trivia Showdown Game

**Files:**
- Create: `lib/games/games/trivia/trivia_game.dart`
- Create: `lib/games/games/trivia/trivia_registration.dart`

- [ ] **Step 1: Create trivia directory**

```bash
mkdir -p lib/games/games/trivia
```

- [ ] **Step 2: Write trivia_game.dart**

A StatefulWidget implementing GameInterface. Receives GameContext.

**State:** currentIndex (0-9), score, opponentScore, selectedAnswer (-1 = none), timeRemaining (15), showingResult (bool), questions (List<Map>), isLoading, gameOver.

**initState:** Calls `_loadQuestions()` which fetches from `GET /api/games/trivia/questions?seed={gameSeed}&count=10`. Falls back to locally generated questions if API fails.

**Timer:** CountdownTimer ticking every second. When it hits 0, auto-advance to next question (no points for timeout).

**Answer tap:** Set selectedAnswer, stop timer. If correct: score += 10 + speedBonus (5 if answered in first 3s, 3 if in 5s, 1 if in 10s, 0 otherwise). Show result for 2 seconds (green highlight correct, red highlight wrong). Then advance to next question.

**Game over:** After 10 questions or all answered, call `context.onGameComplete({'winner_id': null, 'player_1_score': score, 'player_2_score': opponentScore})`. For practice, winner_id is userId if score > 0.

**Multiplayer:** On opponent move via `onOpponentMove({'question_index': N, 'answer': M, 'score': S})`, update opponentScore.

**UI layout:**
- Top: question counter "Q 3/10", score display, timer bar (animated LinearProgressIndicator)
- Center: question text (large, bold)
- Bottom: 4 answer buttons in 2x2 grid. Normal: white bg. Selected+correct: green. Selected+wrong: red. Unselected+correct (on reveal): green outline.
- Between questions: brief score comparison

**Design:** _kPrimary/#1A1A1A, _kSecondary/#666666, answer buttons with BorderRadius.circular(12), 52dp height, full width.

- [ ] **Step 3: Write trivia_registration.dart**

```dart
// lib/games/games/trivia/trivia_registration.dart

import 'package:flutter/material.dart';
import '../../core/game_registry.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_context.dart';
import 'trivia_game.dart';

void registerTrivia() {
  GameRegistry.instance.register(GameDefinition(
    id: 'trivia',
    name: 'Trivia Showdown',
    nameSwahili: 'Mashindano ya Maswali',
    category: GameCategory.trivia,
    icon: Icons.quiz_rounded,
    description: 'Answer 10 questions faster than your opponent. Test your knowledge!',
    descriptionSwahili: 'Jibu maswali 10 haraka kuliko mpinzani wako. Jaribu ujuzi wako!',
    minPlayers: 1,
    maxPlayers: 2,
    modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
    stakeSafe: true,
    maxStakeTier: StakeTier.diamond,
    estimatedMinutes: 2,
    builder: (GameContext ctx) => TriviaGame(context: ctx),
  ));
}
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/games/games/trivia/
```

---

## Task 3: Frontend — 2048 Game

**Files:**
- Create: `lib/games/games/twenty48/twenty48_game.dart`
- Create: `lib/games/games/twenty48/twenty48_registration.dart`

- [ ] **Step 1: Create directory**

```bash
mkdir -p lib/games/games/twenty48
```

- [ ] **Step 2: Write twenty48_game.dart**

StatefulWidget implementing GameInterface. Receives GameContext.

**State:** `List<List<int>> grid` (4x4, 0=empty), score (int), gameOver (bool), seededRandom (Random from gameSeed).

**initState:** Initialize empty grid. Use seeded Random to place 2 starting tiles (value 2 or 4, 90%/10% probability).

**Game logic:**
- `_swipe(Direction dir)`: Slide all tiles in direction. Merge same-value adjacent tiles. Add merged values to score. After move, spawn new tile (2 or 4) in random empty cell using seeded Random. Check if game over (no empty cells AND no adjacent same-value pairs).
- GestureDetector with `onPanEnd` to detect swipe direction (compare dx/dy magnitude + sign).

**Tile spawning:** Uses seeded Random for deterministic sequence. Both players with same seed get same spawns.

**Game over:** When no moves possible, call `context.onGameComplete({'winner_id': null, 'player_1_score': score, 'player_2_score': 0})`.

**Multiplayer:** Opponent score updated via `onOpponentMove({'score': N})`. Displayed in top bar.

**UI layout:**
- Top: score display + opponent score (if multiplayer)
- Center: 4x4 grid rendered as GridView or nested Row/Column. Each tile is an AnimatedContainer with:
  - Color based on value: 0=grey.shade200, 2=Color(0xFFEEE4DA), 4=Color(0xFFEDE0C8), 8=Color(0xFFF2B179), 16=Color(0xFFF59563), 32=Color(0xFFF67C5F), 64=Color(0xFFF65E3B), 128=Color(0xFFEDCF72), 256=Color(0xFFEDCC61), 512=Color(0xFFEDC850), 1024=Color(0xFFEDC53F), 2048=Color(0xFFEDC22E)
  - Text: tile value (bold, sized by digit count)
  - Rounded corners (BorderRadius.circular(8))
- Grid has dark background with padding between cells
- "New Game" button available in practice mode

- [ ] **Step 3: Write twenty48_registration.dart**

```dart
void registerTwenty48() {
  GameRegistry.instance.register(GameDefinition(
    id: 'twenty48',
    name: '2048',
    nameSwahili: '2048',
    category: GameCategory.puzzle,
    icon: Icons.grid_4x4_rounded,
    description: 'Slide and merge tiles to reach 2048. Highest score wins!',
    descriptionSwahili: 'Sogeza na unganisha vigae kufikia 2048. Alama za juu zinashinda!',
    minPlayers: 1,
    maxPlayers: 2,
    modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
    stakeSafe: true,
    maxStakeTier: StakeTier.diamond,
    estimatedMinutes: 3,
    builder: (GameContext ctx) => Twenty48Game(context: ctx),
  ));
}
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/games/games/twenty48/
```

---

## Task 4: Frontend — Speed Math Game

**Files:**
- Create: `lib/games/games/speed_math/speed_math_game.dart`
- Create: `lib/games/games/speed_math/speed_math_registration.dart`

- [ ] **Step 1: Create directory**

```bash
mkdir -p lib/games/games/speed_math
```

- [ ] **Step 2: Write speed_math_game.dart**

StatefulWidget implementing GameInterface. Receives GameContext.

**State:** score, questionsAnswered, timeRemaining (60), currentProblem (String), currentAnswer (int), options (List<int> of 4), isRunning, gameOver, seededRandom.

**Problem generation from seed:** Uses seeded Random.
- Easy (questions 1-5): single digit + single digit, or single digit × single digit (small)
- Medium (6-10): double digit ± single digit, or single digit × double digit
- Hard (11+): double digit ± double digit, or double digit × single digit

Generate expression string (e.g., "24 + 17"), compute correct answer, generate 3 distractors (correct ± random offset 1-10, ensuring all unique and positive).

**Timer:** 60-second countdown. When 0, game over.

**Answer tap:** If correct: score += 10 + speedBonus. Generate next problem immediately. If wrong: score += 0, generate next problem immediately (no penalty beyond lost time).

**Game over:** call onGameComplete with score.

**UI layout:**
- Top: timer bar (LinearProgressIndicator), score, questions answered count
- Center: problem text (very large, e.g., "24 + 17 = ?")
- Bottom: 4 answer buttons in 2x2 grid, large touch targets (64dp height)
- Brief green flash on correct, red flash on wrong

- [ ] **Step 3: Write speed_math_registration.dart**

```dart
void registerSpeedMath() {
  GameRegistry.instance.register(GameDefinition(
    id: 'speed_math',
    name: 'Speed Math',
    nameSwahili: 'Hesabu Haraka',
    category: GameCategory.math,
    icon: Icons.calculate_rounded,
    description: 'Solve math problems as fast as you can in 60 seconds!',
    descriptionSwahili: 'Tatua hesabu haraka uwezavyo kwa sekunde 60!',
    minPlayers: 1,
    maxPlayers: 2,
    modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
    stakeSafe: true,
    maxStakeTier: StakeTier.diamond,
    estimatedMinutes: 1,
    builder: (GameContext ctx) => SpeedMathGame(context: ctx),
  ));
}
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/games/games/speed_math/
```

---

## Task 5: Frontend — Reaction Time Duel

**Files:**
- Create: `lib/games/games/reaction/reaction_game.dart`
- Create: `lib/games/games/reaction/reaction_registration.dart`

- [ ] **Step 1: Create directory**

```bash
mkdir -p lib/games/games/reaction
```

- [ ] **Step 2: Write reaction_game.dart**

StatefulWidget implementing GameInterface. Receives GameContext.

**State:** currentRound (1-5), phase (waiting/ready/go/tapped/falseStart/result/gameOver), reactionTimeMs (int), roundResults (List<int> — ms per round, -1 for false start), delays (List<int> — pre-generated from seed, 2000-6000ms each), stopwatch (Stopwatch), opponentResults (List<int>).

**initState:** Generate 5 random delays from seeded Random (2000-6000ms range). Start first round.

**Round flow:**
1. Phase `waiting` — screen dark/red, text "SUBIRI... / WAIT..."
2. After delay[currentRound], phase → `go` — screen bright green, text "GONGA SASA! / TAP NOW!", start Stopwatch
3. Player taps:
   - If phase == `waiting` → falseStart! reactionTimeMs = 500 (penalty), show "TOO EARLY!" for 1.5s
   - If phase == `go` → stop Stopwatch, reactionTimeMs = elapsed ms, show result for 2s
4. Record result, advance to next round

**Tap detection:** GestureDetector wrapping entire screen. `onTapDown` (not onTap — faster response).

**Game over:** After 5 rounds, calculate average time (excluding false starts, using 500ms for them). Lower average wins. Call onGameComplete.

**Multiplayer:** Opponent results come via onOpponentMove. Show side-by-side comparison after each round.

**UI layout:**
- Full screen color (dark red during wait, bright green during go, grey during result)
- Large centered text for phase instruction
- Round counter "Round 3/5" top center
- After tap: large reaction time display "247 ms" with color coding (< 200ms = green "Haraka sana!", 200-300 = blue "Nzuri!", 300-500 = orange "Wastani", > 500 = red "Pole!")
- Between rounds: my time vs opponent time (if multiplayer)
- After all rounds: average time, best time, round-by-round breakdown

- [ ] **Step 3: Write reaction_registration.dart**

```dart
void registerReaction() {
  GameRegistry.instance.register(GameDefinition(
    id: 'reaction',
    name: 'Reaction Time Duel',
    nameSwahili: 'Mashindano ya Kasi',
    category: GameCategory.arcade,
    icon: Icons.flash_on_rounded,
    description: 'Test your reflexes! Tap as fast as you can when the screen turns green.',
    descriptionSwahili: 'Jaribu kasi yako! Gonga haraka iwezekanavyo skrini inapokuwa kijani.',
    minPlayers: 1,
    maxPlayers: 2,
    modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
    stakeSafe: true,
    maxStakeTier: StakeTier.diamond,
    estimatedMinutes: 1,
    builder: (GameContext ctx) => ReactionGame(context: ctx),
  ));
}
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/games/games/reaction/
```

---

## Task 6: Frontend — Tap Speed Challenge

**Files:**
- Create: `lib/games/games/tap_speed/tap_speed_game.dart`
- Create: `lib/games/games/tap_speed/tap_speed_registration.dart`

- [ ] **Step 1: Create directory**

```bash
mkdir -p lib/games/games/tap_speed
```

- [ ] **Step 2: Write tap_speed_game.dart**

StatefulWidget implementing GameInterface. Receives GameContext.

**State:** tapCount (int), timeRemaining (10.0), isRunning (bool), gameOver (bool), tapsPerSecond (double), opponentTaps (int).

**Timer:** 10-second countdown using a periodic Timer every 100ms for smooth progress bar. When 0, game over.

**Start:** Game starts immediately on build (or after a 3-2-1 countdown). First tap starts the timer.

**Tap:** GestureDetector with `onTapDown` on a large central button. Each tap: increment tapCount, recalculate tapsPerSecond = tapCount / (10 - timeRemaining). Visual feedback: button scales down briefly (AnimatedScale or Transform.scale with quick animation).

**Game over:** Call onGameComplete with tapCount as score. Higher count wins.

**UI layout:**
- Top: timer bar (LinearProgressIndicator, color changes from green → orange → red)
- Center: Giant circular tap button (200x200), dark background, white text showing tap count (very large, 48px font). Pulses/scales on each tap.
- Below button: "X.X taps/sec" live display
- Bottom: opponent tap count (if multiplayer)
- Instructions text: "Tap as fast as you can! / Gonga haraka uwezavyo!"

- [ ] **Step 3: Write tap_speed_registration.dart**

```dart
void registerTapSpeed() {
  GameRegistry.instance.register(GameDefinition(
    id: 'tap_speed',
    name: 'Tap Speed',
    nameSwahili: 'Kasi ya Kugonga',
    category: GameCategory.arcade,
    icon: Icons.touch_app_rounded,
    description: 'Tap as many times as you can in 10 seconds!',
    descriptionSwahili: 'Gonga mara nyingi uwezavyo kwa sekunde 10!',
    minPlayers: 1,
    maxPlayers: 2,
    modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
    stakeSafe: true,
    maxStakeTier: StakeTier.diamond,
    estimatedMinutes: 1,
    builder: (GameContext ctx) => TapSpeedGame(context: ctx),
  ));
}
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/games/games/tap_speed/
```

---

## Task 7: Frontend — Wire Up Registrations in games_module.dart

**Files:**
- Modify: `lib/games/games_module.dart`

- [ ] **Step 1: Add registration imports and auto-register call**

Update `games_module.dart` to import all 5 registration files and call them:

```dart
// lib/games/games_module.dart

import 'package:flutter/material.dart';
import 'pages/games_home_page.dart';

// Game registrations
import 'games/trivia/trivia_registration.dart';
import 'games/twenty48/twenty48_registration.dart';
import 'games/speed_math/speed_math_registration.dart';
import 'games/reaction/reaction_registration.dart';
import 'games/tap_speed/tap_speed_registration.dart';

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
    registerTrivia();
    registerTwenty48();
    registerSpeedMath();
    registerReaction();
    registerTapSpeed();
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

Expected: No issues found. GameRegistry.instance.count should be 5 after GamesModule builds.

---

## Verification Checklist

After all tasks:

- [ ] Backend: `curl /api/games/trivia/questions?seed=test&count=5` returns 5 questions with options
- [ ] Backend: `SELECT count(*) FROM trivia_questions` returns 200+
- [ ] Frontend: `flutter analyze lib/games/` — zero errors
- [ ] Frontend: GamesModule.build() registers 5 games in GameRegistry
- [ ] Frontend: GamesHomePage shows 5 game cards in grid
- [ ] Frontend: Tapping a game card → GameLobbyPage → Practice → GameRoomPage → GamePlayPage with actual game widget
- [ ] Trivia: Shows questions with 4 options, timer, scoring works
- [ ] 2048: Grid renders, swipe moves tiles, merging works, score increments
- [ ] Speed Math: Problems display, answers validate, timer counts down, score tracks
- [ ] Reaction Time: Wait → GO color change works, timing measured, false start detected, 5 rounds complete
- [ ] Tap Speed: Tap counter works, 10s timer, taps-per-second displays, game completes
