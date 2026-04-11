# TAJIRI Phase 1 Games — Design Spec (Sub-project 2)

**Date:** 2026-04-07
**Status:** Approved
**Scope:** 5 mini-games plugging into the Games Platform from Sub-project 1

## Overview

5 embedded mini-games that validate the Games Platform works end-to-end. Each implements GameInterface, registers with GameRegistry, and uses the platform's shared screens (lobby/room/play/result). All are easy to build, quick to play (1-3 minutes), and support both practice and multiplayer modes.

## Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Trivia source | Backend DB + Open Trivia DB proxy | Server-authoritative, local content + variety |
| Game validation | Client-trusted for MVP, server seed for replay | Full server-side replay deferred to Phase 3 |
| Game file structure | 2 files per game (game widget + registration) | Minimal footprint, clean plugin pattern |
| Registration | Auto-import in games_module.dart | Games register on app start |

---

## Game 1: Trivia Showdown

**ID:** `trivia`
**Category:** trivia
**Players:** 1-2
**Duration:** ~2 minutes
**Modes:** practice, friend, ranked
**Stake safe:** Yes (pure knowledge)

### Gameplay
- 10 multiple-choice questions, 4 options each
- 15 seconds per question
- Scoring: 10 points for correct + speed bonus (up to 5 extra for answering in first 3 seconds)
- Both players get same questions from server seed
- After each question: brief reveal showing who got it right
- Final score comparison after 10 questions
- Practice: solo, compete against own best

### Question Categories
- General knowledge (from Open Trivia DB, proxied through backend)
- Tanzania trivia (history, geography, culture, music, politics)
- Swahili language (vocabulary, proverbs, grammar)

### Backend
**Table: `trivia_questions`**
```
id, question, options (json array of 4 strings), correct_index (0-3),
category (general/tanzania/swahili), difficulty (easy/medium/hard),
source (internal/opentdb), timestamps
```

**Endpoint: `GET /api/games/trivia/questions`**
- Params: seed (string), count (default 10), category (optional)
- Returns deterministic question set from seed
- Mixes categories: 4 general + 3 tanzania + 3 swahili (default)
- For Open Trivia DB: fetches from `https://opentdb.com/api.php`, caches results, normalizes format

**Seeder:** 200+ internal questions (100 general, 60 Tanzania, 40 Swahili)

### Frontend
```
lib/games/games/trivia/
  ├── trivia_game.dart          — Game widget
  └── trivia_registration.dart  — Definition + registration
```

**trivia_game.dart:** StatefulWidget implementing GameInterface. State: currentQuestionIndex, score, opponentScore, selectedAnswer, timeRemaining, showingResult. UI: question text (top), 4 answer buttons (center), timer bar (top), score display. Animations: timer countdown, correct/wrong highlight, score increment.

---

## Game 2: 2048

**ID:** `twenty48`
**Category:** puzzle
**Players:** 1-2
**Duration:** ~3 minutes
**Modes:** practice, friend, ranked
**Stake safe:** Yes (pure skill)

### Gameplay
- 4x4 grid of numbered tiles
- Swipe in any direction to slide all tiles
- Same-number tiles merge and double (2+2=4, 4+4=8, etc.)
- New tile (2 or 4) spawns after each move in random empty cell
- Score = sum of all merges performed
- Game over when no valid moves remain
- Both players: same starting board and spawn sequence from seed
- Highest score wins

### Frontend
```
lib/games/games/twenty48/
  ├── twenty48_game.dart          — Game widget
  └── twenty48_registration.dart  — Definition + registration
```

**twenty48_game.dart:** StatefulWidget implementing GameInterface. State: 4x4 int grid, score, gameOver. Swipe detection via GestureDetector (up/down/left/right). Tile rendering with AnimatedContainer for merge animations. Color coding by tile value (2=light, 4=tan, 8=orange, ..., 2048=gold). Seeded Random for deterministic tile spawns.

---

## Game 3: Speed Math

**ID:** `speed_math`
**Category:** math
**Players:** 1-2
**Duration:** 60 seconds
**Modes:** practice, friend, ranked
**Stake safe:** Yes (pure skill)

### Gameplay
- 60-second round
- Arithmetic problems with 4 multiple-choice answers
- Difficulty ramp: questions 1-5 easy (single digit add/subtract), 6-10 medium (double digit), 11+ hard (multiplication, larger numbers)
- Scoring: 10 points per correct + speed bonus (up to 5)
- Wrong answer: 0 points, next question immediately
- Same problem sequence from seed for both players
- Highest score wins

### Frontend
```
lib/games/games/speed_math/
  ├── speed_math_game.dart          — Game widget
  └── speed_math_registration.dart  — Definition + registration
```

**speed_math_game.dart:** StatefulWidget implementing GameInterface. Generates problems from seeded Random. State: currentProblem, score, questionsAnswered, timeRemaining. UI: problem text (large, center), 4 answer buttons (grid), timer bar, score + question count. Problem generation: creates expression + computes answer + generates 3 plausible distractors.

---

## Game 4: Reaction Time Duel

**ID:** `reaction`
**Category:** arcade
**Players:** 1-2
**Duration:** ~1 minute
**Modes:** practice, friend, ranked
**Stake safe:** Yes (pure reflex)

### Gameplay
- Best of 5 rounds
- Each round: screen shows "SUBIRI... / WAIT..." on red/dark background
- After random delay (2-6 seconds, from seed), screen turns green with "GONGA SASA! / TAP NOW!"
- Tap as fast as possible. Reaction time measured in milliseconds.
- Tapping before green = false start, round lost (500ms penalty added)
- In multiplayer: both see same delay (from seed), fastest tap wins the round
- Best of 5 rounds wins the match
- Practice: solo, 5 rounds, shows average + best time

### Frontend
```
lib/games/games/reaction/
  ├── reaction_game.dart          — Game widget
  └── reaction_registration.dart  — Definition + registration
```

**reaction_game.dart:** StatefulWidget implementing GameInterface. State: currentRound, roundResults (List of ms values), phase (waiting/ready/tapped/falseStart/result), delay timer. UI: full-screen color change (dark red → bright green), large text instructions, tap anywhere gesture, round counter, results between rounds. Uses Stopwatch for precise timing.

---

## Game 5: Tap Speed Challenge

**ID:** `tap_speed`
**Category:** arcade
**Players:** 1-2
**Duration:** 10 seconds
**Modes:** practice, friend, ranked
**Stake safe:** Yes (pure reflex)

### Gameplay
- Tap a large button as many times as possible in 10 seconds
- Live counter shows tap count
- Live taps-per-second display
- Both players play simultaneously
- Highest tap count wins
- Practice: solo, beat personal best

### Frontend
```
lib/games/games/tap_speed/
  ├── tap_speed_game.dart          — Game widget
  └── tap_speed_registration.dart  — Definition + registration
```

**tap_speed_game.dart:** StatefulWidget implementing GameInterface. State: tapCount, timeRemaining, isRunning, tapsPerSecond. UI: giant tap button (center, pulsing animation on tap), counter (large number), timer bar, tps display. GestureDetector with onTapDown for rapid counting.

---

## Shared Registration Pattern

Every registration file:
```dart
import '../../core/game_registry.dart';
import '../../core/game_definition.dart';
import '../../core/game_enums.dart';
import '../../core/game_context.dart';
import '{game_id}_game.dart';

void register{GameName}() {
  GameRegistry.instance.register(GameDefinition(
    id: '{game_id}',
    name: '{Game Name}',
    nameSwahili: '{Jina la Mchezo}',
    category: GameCategory.{cat},
    icon: Icons.{icon}_rounded,
    description: '{English description}',
    descriptionSwahili: '{Swahili description}',
    minPlayers: 1,
    maxPlayers: 2,
    modes: [GameMode.practice, GameMode.friend, GameMode.ranked],
    stakeSafe: true,
    maxStakeTier: StakeTier.diamond,
    estimatedMinutes: {N},
    builder: (GameContext ctx) => {GameName}Game(context: ctx),
  ));
}
```

**games_module.dart** imports all registration files and calls register functions in build():
```dart
import 'games/trivia/trivia_registration.dart';
import 'games/twenty48/twenty48_registration.dart';
// ... etc

// Called once on first build
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
```

---

## Backend Addition: Trivia Questions

### Migration
**Table: `trivia_questions`**
- id, question (text), options (json), correct_index (int), category (string), difficulty (string), source (string, default 'internal'), timestamps

### Controller
**`TriviaController.php`** — single endpoint:
- `GET /api/games/trivia/questions?seed=X&count=10&category=all`
- Uses seed to deterministically select and order questions
- Mixes from internal DB + cached Open Trivia DB results
- Open Trivia DB: fetches `https://opentdb.com/api.php?amount=50&type=multiple`, caches in `trivia_questions` table with source='opentdb'

### Seeder
**`TriviaQuestionSeeder.php`** — seeds 200+ questions:
- 100 general knowledge
- 60 Tanzania (history, geography, culture, Bongo Flava, national parks, politics)
- 40 Swahili language (vocabulary, proverbs/methali, grammar)

### Route
```php
Route::get('/games/trivia/questions', [TriviaController::class, 'questions']);
```

---

## File Structure Summary

### Frontend (10 new files)
```
lib/games/games/
├── trivia/
│   ├── trivia_game.dart
│   └── trivia_registration.dart
├── twenty48/
│   ├── twenty48_game.dart
│   └── twenty48_registration.dart
├── speed_math/
│   ├── speed_math_game.dart
│   └── speed_math_registration.dart
├── reaction/
│   ├── reaction_game.dart
│   └── reaction_registration.dart
└── tap_speed/
    ├── tap_speed_game.dart
    └── tap_speed_registration.dart
```

Plus modify: `lib/games/games_module.dart` (add registration imports + calls)

### Backend (3 new files)
```
database/migrations/create_trivia_questions_table.php
database/seeders/TriviaQuestionSeeder.php
app/Http/Controllers/Api/Games/TriviaController.php
routes/api.php (add trivia route)
```

---

## Non-Goals
- Server-side move replay/validation (deferred — client-trusted for MVP)
- AI opponents for practice mode (simple target score instead)
- Sound effects (deferred to polish phase)
- Animations beyond basic (tile merge, color change, tap pulse)
