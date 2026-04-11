# TAJIRI Games Module Research

## 30 Mini-Games Catalog

### Puzzle Games (6)
| # | Game | Multiplayer | Stakes | Flutter Difficulty | Cultural Fit |
|---|------|------------|--------|-------------------|-------------|
| 1 | 2048 | Async (same board, highest score) | Excellent | Easy | Universal |
| 2 | Sudoku Duel | Race to finish same puzzle | Good | Easy-Medium | Universal |
| 3 | Sliding Puzzle (15-Puzzle) | Race mode, fewest moves | Good | Easy | Universal |
| 4 | Match-3 (Jewel Crush) | Same board seed, timed | Medium-Good | Medium-Hard | Very popular in Africa |
| 5 | Minesweeper Duel | Same board, race to clear | Good | Easy-Medium | Universal |
| 6 | Block Puzzle (Tetris-style) | Same pieces, highest score | Good | Medium | Universal |

### Trivia / Quiz Games (4)
| # | Game | Multiplayer | Stakes | Flutter Difficulty | Cultural Fit |
|---|------|------------|--------|-------------------|-------------|
| 7 | Trivia Showdown | Real-time head-to-head | Excellent | Easy | Universal (quiz shows popular in TZ) |
| 8 | Tanzania Trivia | Same as above, local questions | Excellent | Easy | Very high (Kilimanjaro, Serengeti, Bongo Flava) |
| 9 | Swahili Language Quiz | Head-to-head, same questions | Good | Easy | Extremely high (methali, vocabulary) |
| 10 | Speed Quiz (Rapid Fire) | Async, most questions in 60s | Excellent | Easy | Universal |

### Word Games (4)
| # | Game | Multiplayer | Stakes | Flutter Difficulty | Cultural Fit |
|---|------|------------|--------|-------------------|-------------|
| 11 | Word Guess (Wordle) | Both guess same word | Good | Easy | Works in Swahili + English |
| 12 | Anagram Battle | Same letters, most words | Good | Easy-Medium | Both languages |
| 13 | Word Search | Same grid, race to find | Medium | Medium | Tanzanian themes |
| 14 | Word Chain | Turn-based, last letter | Good | Easy | Played in East African schools |

### Card Games (4)
| # | Game | Multiplayer | Stakes | Flutter Difficulty | Cultural Fit |
|---|------|------------|--------|-------------------|-------------|
| 15 | Kadi (East African card game) | Real-time 2-4 players | Excellent | Medium | VERY HIGH — THE card game of East Africa |
| 16 | Memory Card Match | Same layout, fewest flips | Good | Easy | Universal, TZ imagery on cards |
| 17 | Poker (Simplified Hold'em) | Real-time 2-6 players | Natural fit | Medium-Hard | Urban/cosmopolitan users |
| 18 | Snap | Real-time head-to-head | Good | Easy | Universal |

### Board Games (5)
| # | Game | Multiplayer | Stakes | Flutter Difficulty | Cultural Fit |
|---|------|------------|--------|-------------------|-------------|
| 19 | Bao la Kiswahili | 2-player turn-based | Excellent | Medium | EXTREMELY HIGH — Tanzania's national board game, UNESCO heritage |
| 20 | Checkers / Dama | 2-player turn-based | Good | Easy-Medium | Widely played in East Africa |
| 21 | Chess | 2-player turn-based (timed) | Excellent | Medium | Growing in East Africa |
| 22 | Ludo | 2-4 players turn-based | Medium (dice luck) | Medium | EXTREMELY popular, household name |
| 23 | Dots and Boxes | 2-player turn-based | Good | Easy | Played in schools |

### Arcade / Reflex Games (4)
| # | Game | Multiplayer | Stakes | Flutter Difficulty | Cultural Fit |
|---|------|------------|--------|-------------------|-------------|
| 24 | Tap Speed Challenge | Async, highest taps | Good | Easy | Universal |
| 25 | Reaction Time Duel | Real-time, fastest tap | Excellent | Easy | Universal |
| 26 | Flappy Jump | Async, same obstacles | Good | Medium | Universal (Serengeti theme) |
| 27 | Snake | Async, same food sequence | Good | Easy-Medium | Nostalgic (Nokia era, big in Africa) |

### Math / Number Games (3)
| # | Game | Multiplayer | Stakes | Flutter Difficulty | Cultural Fit |
|---|------|------------|--------|-------------------|-------------|
| 28 | Speed Math | Same problems, highest score | Excellent | Easy | Educational appeal |
| 29 | Math Duel (Head-to-Head) | Real-time, first correct wins | Excellent | Easy | Universal |
| 30 | Number Sequence | Same sequences, speed wins | Good | Easy | Universal |

---

## Top 25 Prioritized for TAJIRI

| Priority | Game | Category | Why |
|----------|------|----------|-----|
| 1 | **Bao la Kiswahili** | Board | Tanzania's national game. No good digital version exists. Already played for money |
| 2 | **Kadi** | Card | THE East African card game. Massive nostalgia. No app has nailed it |
| 3 | **Trivia Showdown** | Trivia | Easy to build, validates stake system, quiz shows popular in TZ |
| 4 | **Tanzania Trivia** | Trivia | Localized content is a moat. Cultural pride angle |
| 5 | **Ludo** | Board | Most popular board game in East Africa. Ludo King is top downloaded |
| 6 | **Chess** | Board | Pure skill, perfect for stakes. Growing in TZ |
| 7 | **Word Guess (Wordle)** | Word | Swahili Wordle is unique — no competitor offers this |
| 8 | **Speed Math** | Math | Pure skill, educational, parent-approved |
| 9 | **2048** | Puzzle | Easy to build, addictive, great for stakes |
| 10 | **Checkers/Dama** | Board | Classic, skill-based, widely known |
| 11 | **Swahili Language Quiz** | Trivia | Cultural moat. Methali (proverbs) are beloved |
| 12 | **Reaction Time Duel** | Arcade | Quick, dramatic, perfect for casual stakes |
| 13 | **Math Duel** | Math | Head-to-head makes it exciting |
| 14 | **Sudoku Duel** | Puzzle | Skill-based, competitive format |
| 15 | **Anagram Battle** | Word | Works in both Swahili and English |
| 16 | **Memory Card Match** | Card | Easy to build, TZ-themed cards |
| 17 | **Connect Four** | Strategy | Strategy, no luck, easy to build |
| 18 | **Snap** | Card | Quick rounds, reflex-based |
| 19 | **Dots and Boxes** | Strategy | Known from school, pure strategy |
| 20 | **Block Puzzle** | Puzzle | Addictive, spatial reasoning |
| 21 | **Snake** | Arcade | Nokia nostalgia, strong in Africa |
| 22 | **Tap Speed Challenge** | Arcade | Simplest possible game, validates infra |
| 23 | **Word Chain** | Word | Known as "Neno la Mwisho" in schools |
| 24 | **Speed Quiz** | Trivia | 60-second pressure, highly engaging |
| 25 | **Ultimate Tic-Tac-Toe** | Strategy | Deep strategy from simple concept |

---

## Stake / Wager System Design

### Stake Tiers
```
Free Play         — Practice, no stakes, earn virtual coins
Bronze            — TZS 500 entry → TZS 900 winner (10% rake)
Silver            — TZS 2,000 entry → TZS 3,600 winner
Gold              — TZS 5,000 entry → TZS 9,000 winner
Diamond           — TZS 20,000 entry → TZS 36,000 winner
Custom (friends)  — Any amount, min TZS 100, max wallet balance
```

### Challenge Flow
```
1. User A opens game → taps "Challenge Friend"
2. A selects stake tier → stake locked from A's wallet (escrow)
3. Challenge sent as chat message / push notification with deep link
4. User B sees challenge → Accept (stake locked) / Decline / Counter-offer
5. Both play simultaneously (server-generated same seed)
6. Game ends → server validates scores → winner determined
7. Winner gets (2x stake - 10% platform fee) → credited to wallet
8. Results posted in chat thread + optional feed post
9. "Rematch?" prompt for 30 seconds
```

### Revenue Model
- 10% rake on all stakes games
- At 10,000 games/day × TZS 2,000 avg stake = TZS 2,000,000/day (~$770 USD/day)
- Additional: rewarded video ads for free players, cosmetic purchases

### Anti-Cheat Essentials
- Server generates game seeds and validates scores
- Client sends input events, not scores
- Input timestamp verification (detect bots)
- Same-pair frequency limits for stakes (prevent collusion)
- Daily loss limits + cool-off periods

### Legal Classification
- **Skill-based games** (trivia, chess, math, Bao) = safest for stakes
- **Mixed games** (Ludo has dice) = lower stake caps
- Register with Gaming Board of Tanzania proactively
- Classify as "skill-based competitions" not "gambling"

---

## Implementation Phases

### Phase 1 — MVP (validate stake system)
Trivia Showdown, 2048, Speed Math, Reaction Time Duel, Tap Speed Challenge
— All easy to build, prove the challenge + payment flow

### Phase 2 — Cultural flagships
Bao la Kiswahili, Kadi, Ludo, Chess, Checkers
— The games that define TAJIRI as uniquely Tanzanian

### Phase 3 — Expansion
Word Guess, Sudoku, Snake, Memory Match, Anagram Battle, etc.
— Fill out the catalog, add tournaments, seasonal events

---

## Technical Approach

All 25+ games buildable with pure Flutter (no game engine needed):
- `CustomPainter` — board rendering, game canvases
- `GestureDetector` — tap, swipe, drag interactions
- `AnimationController` — piece movement, card flips, timers
- `Stack + Positioned` — layered game UIs
- WebSocket (Laravel Reverb) — real-time multiplayer

Useful packages: `chess` (chess logic), `audioplayers` (sound effects), `confetti` (win celebrations), `qr_flutter` (already added)
