# TAJIRI Games Platform Implementation Plan (Sub-project 1)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the games platform infrastructure — plugin registry, shared screens, challenge/matchmaking, stake/escrow, real-time WebSocket, and leaderboards — so that individual games can be plugged in via Sub-projects 2-6.

**Architecture:** Game Engine Pattern — each game implements a GameInterface and registers via GameRegistry. The platform provides 5 shared screens (home/lobby/room/play/result), a WebSocket service for real-time multiplayer, and an escrow system for wallet-based stakes. Backend uses Laravel Reverb for broadcasting game events.

**Tech Stack:** Flutter/Dart frontend, Laravel 12 backend (PHP 8.3, PostgreSQL 16, Redis 7, Laravel Reverb WebSocket)

**Spec:** `docs/superpowers/specs/2026-04-07-games-platform-design.md`

**Backend server:** SSH `sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180`, project at `/var/www/tajiri.zimasystems.com`

**Existing code:**
- Frontend shell: `lib/games/` (7 files — will be replaced)
- Backend: `GamesController.php` with basic catalog + scores (keep as-is, add new controllers alongside)
- Reverb config: app_key=`tajiri-reverb-key-2026`, WSS at `tajiri.zimasystems.com:6001`
- Wallet: `WalletController.php` with balance/transfer/PIN. Uses `Wallet` and `WalletTransaction` models
- Friendships: `Friendship` model with pending/accepted/blocked status

---

## File Map

### Frontend (27 files in `lib/games/`)

| File | Responsibility |
|---|---|
| `games_module.dart` | Entry point wrapping GamesHomePage |
| `core/game_enums.dart` | GameCategory, GameMode, StakeTier, SessionStatus enums |
| `core/game_definition.dart` | GameDefinition data class |
| `core/game_interface.dart` | GameInterface abstract class |
| `core/game_context.dart` | GameContext runtime context |
| `core/game_registry.dart` | Singleton registry |
| `models/game_session.dart` | GameSession model with fromJson |
| `models/game_escrow.dart` | GameEscrow model |
| `models/leaderboard_entry.dart` | LeaderboardEntry model |
| `models/match_result.dart` | MatchResult model |
| `models/challenge.dart` | Challenge model (pending invites) |
| `services/games_service.dart` | REST API calls (sessions, escrow, leaderboards) |
| `services/game_socket_service.dart` | WebSocket via Reverb for real-time game events |
| `pages/games_home_page.dart` | Hub: game grid, categories, my matches, challenges |
| `pages/game_lobby_page.dart` | Mode + stake selection, friend picker |
| `pages/game_room_page.dart` | Waiting room, countdown |
| `pages/game_play_page.dart` | Wraps GameWidget, provides chrome |
| `pages/game_result_page.dart` | Winner, payout, rematch |
| `widgets/game_card.dart` | Game tile for grid |
| `widgets/challenge_card.dart` | Pending challenge card |
| `widgets/match_card.dart` | Active/recent match card |
| `widgets/leaderboard_tile.dart` | Leaderboard row |
| `widgets/stake_selector.dart` | Stake tier picker |
| `widgets/player_banner.dart` | Player info bar for gameplay |
| `widgets/game_timer.dart` | Countdown timer widget |

### Backend (via SSH)

| File | Responsibility |
|---|---|
| `database/migrations/xxxx_create_game_platform_tables.php` | 4 tables: game_sessions, game_escrows, game_transactions, game_leaderboard_entries |
| `app/Models/Games/GameSession.php` | Eloquent model |
| `app/Models/Games/GameEscrow.php` | Eloquent model |
| `app/Models/Games/GameTransaction.php` | Eloquent model |
| `app/Models/Games/GameLeaderboardEntry.php` | Eloquent model |
| `app/Http/Controllers/Api/GameSessionController.php` | Session CRUD, matchmaking, moves, results |
| `app/Http/Controllers/Api/GameEscrowController.php` | Lock/settle/refund stakes |
| `app/Http/Controllers/Api/GameLeaderboardController.php` | Leaderboard queries |
| `app/Services/Games/MatchmakingService.php` | Queue, ELO matching |
| `app/Services/Games/EscrowService.php` | Wallet integration for escrow |
| `app/Services/Games/EloService.php` | ELO rating calculations |
| `app/Events/Games/PlayerJoined.php` | Reverb broadcast event |
| `app/Events/Games/GameStarted.php` | Reverb broadcast event |
| `app/Events/Games/PlayerMove.php` | Reverb broadcast event |
| `app/Events/Games/GameEnded.php` | Reverb broadcast event |
| `app/Events/Games/PlayerDisconnected.php` | Reverb broadcast event |
| `routes/api.php` | Add games platform route group |
| `routes/channels.php` | Add game.{sessionId} private channel |

---

## Task 1: Backend — Database Migration (4 tables)

**Files:**
- Create: `database/migrations/2026_04_07_200000_create_game_platform_tables.php`

- [ ] **Step 1: SSH into backend server**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180
cd /var/www/tajiri.zimasystems.com
```

- [ ] **Step 2: Create the migration**

```bash
php artisan make:migration create_game_platform_tables
```

Write the migration:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('game_sessions', function (Blueprint $table) {
            $table->id();
            $table->string('game_id');           // 'bao', 'trivia', 'chess'
            $table->string('mode');              // practice, friend, ranked
            $table->string('status')->default('pending'); // pending/matching/active/completed/cancelled/forfeited
            $table->string('stake_tier')->default('free'); // free/bronze/silver/gold/diamond/custom
            $table->decimal('stake_amount', 12, 2)->default(0);
            $table->string('stake_currency')->default('TZS');
            $table->decimal('platform_fee', 12, 2)->default(0);
            $table->unsignedBigInteger('player_1_id');
            $table->unsignedBigInteger('player_2_id')->nullable();
            $table->integer('player_1_score')->default(0);
            $table->integer('player_2_score')->default(0);
            $table->unsignedBigInteger('winner_id')->nullable();
            $table->string('game_seed');
            $table->json('game_state')->nullable();
            $table->string('room_code')->unique();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->timestamps();

            $table->foreign('player_1_id')->references('id')->on('users');
            $table->foreign('player_2_id')->references('id')->on('users');
            $table->foreign('winner_id')->references('id')->on('users');
            $table->index(['player_1_id', 'status']);
            $table->index(['player_2_id', 'status']);
            $table->index(['game_id', 'status']);
        });

        Schema::create('game_escrows', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('session_id');
            $table->unsignedBigInteger('user_id');
            $table->decimal('amount', 12, 2);
            $table->string('currency')->default('TZS');
            $table->string('status')->default('locked'); // locked/settled/refunded
            $table->decimal('settled_amount', 12, 2)->default(0);
            $table->timestamps();

            $table->foreign('session_id')->references('id')->on('game_sessions')->onDelete('cascade');
            $table->foreign('user_id')->references('id')->on('users');
            $table->index(['session_id', 'user_id']);
        });

        Schema::create('game_transactions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('session_id');
            $table->unsignedBigInteger('user_id');
            $table->string('type');              // stake_lock/win_payout/platform_fee/refund
            $table->decimal('amount', 12, 2);
            $table->string('currency')->default('TZS');
            $table->string('wallet_transaction_id')->nullable();
            $table->timestamps();

            $table->foreign('session_id')->references('id')->on('game_sessions')->onDelete('cascade');
            $table->foreign('user_id')->references('id')->on('users');
            $table->index(['user_id', 'type']);
        });

        Schema::create('game_leaderboard_entries', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('game_id');
            $table->string('period');            // weekly/monthly/alltime
            $table->string('period_key');        // '2026-W15', '2026-04', 'all'
            $table->integer('wins')->default(0);
            $table->integer('losses')->default(0);
            $table->integer('draws')->default(0);
            $table->integer('total_score')->default(0);
            $table->integer('elo_rating')->default(1000);
            $table->integer('rank')->default(0);
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users');
            $table->unique(['user_id', 'game_id', 'period', 'period_key'], 'leaderboard_unique');
            $table->index(['game_id', 'period', 'period_key', 'elo_rating'], 'leaderboard_ranking');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('game_leaderboard_entries');
        Schema::dropIfExists('game_transactions');
        Schema::dropIfExists('game_escrows');
        Schema::dropIfExists('game_sessions');
    }
};
```

- [ ] **Step 3: Run the migration**

```bash
php artisan migrate
```

- [ ] **Step 4: Verify**

```bash
php artisan tinker --execute="echo implode(', ', array_filter(Schema::getTableListing(), fn(\$t) => str_starts_with(\$t, 'game_')));"
```

Expected: `game_escrows, game_leaderboard_entries, game_scores, game_sessions, game_transactions` (game_scores is pre-existing)

---

## Task 2: Backend — Eloquent Models (4 models)

**Files:**
- Create: `app/Models/Games/GameSession.php`
- Create: `app/Models/Games/GameEscrow.php`
- Create: `app/Models/Games/GameTransaction.php`
- Create: `app/Models/Games/GameLeaderboardEntry.php`

- [ ] **Step 1: Create directory**

```bash
mkdir -p app/Models/Games
```

- [ ] **Step 2: Create GameSession model**

```php
<?php

namespace App\Models\Games;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class GameSession extends Model
{
    protected $fillable = [
        'game_id', 'mode', 'status', 'stake_tier', 'stake_amount', 'stake_currency',
        'platform_fee', 'player_1_id', 'player_2_id', 'player_1_score', 'player_2_score',
        'winner_id', 'game_seed', 'game_state', 'room_code', 'started_at', 'ended_at',
    ];

    protected $casts = [
        'stake_amount' => 'decimal:2',
        'platform_fee' => 'decimal:2',
        'game_state' => 'array',
        'started_at' => 'datetime',
        'ended_at' => 'datetime',
    ];

    public function escrows(): HasMany
    {
        return $this->hasMany(GameEscrow::class, 'session_id');
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(GameTransaction::class, 'session_id');
    }

    public static function generateRoomCode(): string
    {
        return 'GAME-' . strtoupper(substr(md5(uniqid(mt_rand(), true)), 0, 8));
    }

    public static function generateSeed(): string
    {
        return bin2hex(random_bytes(16));
    }

    public function isPlayer(int $userId): bool
    {
        return $this->player_1_id === $userId || $this->player_2_id === $userId;
    }

    public function getOpponentId(int $userId): ?int
    {
        if ($this->player_1_id === $userId) return $this->player_2_id;
        if ($this->player_2_id === $userId) return $this->player_1_id;
        return null;
    }
}
```

- [ ] **Step 3: Create GameEscrow model**

```php
<?php

namespace App\Models\Games;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GameEscrow extends Model
{
    protected $fillable = ['session_id', 'user_id', 'amount', 'currency', 'status', 'settled_amount'];

    protected $casts = [
        'amount' => 'decimal:2',
        'settled_amount' => 'decimal:2',
    ];

    public function session(): BelongsTo
    {
        return $this->belongsTo(GameSession::class, 'session_id');
    }
}
```

- [ ] **Step 4: Create GameTransaction model**

```php
<?php

namespace App\Models\Games;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GameTransaction extends Model
{
    protected $fillable = ['session_id', 'user_id', 'type', 'amount', 'currency', 'wallet_transaction_id'];

    protected $casts = [
        'amount' => 'decimal:2',
    ];

    public function session(): BelongsTo
    {
        return $this->belongsTo(GameSession::class, 'session_id');
    }
}
```

- [ ] **Step 5: Create GameLeaderboardEntry model**

```php
<?php

namespace App\Models\Games;

use Illuminate\Database\Eloquent\Model;

class GameLeaderboardEntry extends Model
{
    protected $fillable = [
        'user_id', 'game_id', 'period', 'period_key',
        'wins', 'losses', 'draws', 'total_score', 'elo_rating', 'rank',
    ];

    public function totalGames(): int
    {
        return $this->wins + $this->losses + $this->draws;
    }

    public function winRate(): float
    {
        $total = $this->totalGames();
        return $total > 0 ? round($this->wins / $total * 100, 1) : 0;
    }
}
```

- [ ] **Step 6: Verify models**

```bash
php artisan tinker --execute="new App\Models\Games\GameSession; echo 'Models OK';"
```

---

## Task 3: Backend — Services (ELO, Escrow, Matchmaking)

**Files:**
- Create: `app/Services/Games/EloService.php`
- Create: `app/Services/Games/EscrowService.php`
- Create: `app/Services/Games/MatchmakingService.php`

- [ ] **Step 1: Create directory**

```bash
mkdir -p app/Services/Games
```

- [ ] **Step 2: Create EloService**

```php
<?php

namespace App\Services\Games;

use App\Models\Games\GameLeaderboardEntry;

class EloService
{
    /**
     * Calculate new ELO ratings after a match.
     * Returns [winnerNewElo, loserNewElo]
     */
    public static function calculate(int $winnerElo, int $loserElo, int $winnerGames, int $loserGames): array
    {
        $kWinner = $winnerGames < 30 ? 32 : 16;
        $kLoser = $loserGames < 30 ? 32 : 16;

        $expectedWinner = 1 / (1 + pow(10, ($loserElo - $winnerElo) / 400));
        $expectedLoser = 1 - $expectedWinner;

        $newWinnerElo = (int) round($winnerElo + $kWinner * (1 - $expectedWinner));
        $newLoserElo = (int) round($loserElo + $kLoser * (0 - $expectedLoser));

        // Floor at 100 to prevent negative spirals
        return [max(100, $newWinnerElo), max(100, $newLoserElo)];
    }

    /**
     * Update leaderboard entries for both players after a match.
     */
    public static function updateAfterMatch(string $gameId, int $winnerId, int $loserId, int $winnerScore, int $loserScore): void
    {
        $now = now();
        $weekKey = $now->format('Y') . '-W' . str_pad($now->isoWeek(), 2, '0', STR_PAD_LEFT);
        $monthKey = $now->format('Y-m');

        $periods = [
            ['period' => 'weekly', 'period_key' => $weekKey],
            ['period' => 'monthly', 'period_key' => $monthKey],
            ['period' => 'alltime', 'period_key' => 'all'],
        ];

        foreach ($periods as $p) {
            $winnerEntry = GameLeaderboardEntry::firstOrCreate(
                ['user_id' => $winnerId, 'game_id' => $gameId, 'period' => $p['period'], 'period_key' => $p['period_key']],
                ['elo_rating' => 1000]
            );
            $loserEntry = GameLeaderboardEntry::firstOrCreate(
                ['user_id' => $loserId, 'game_id' => $gameId, 'period' => $p['period'], 'period_key' => $p['period_key']],
                ['elo_rating' => 1000]
            );

            [$newWinnerElo, $newLoserElo] = self::calculate(
                $winnerEntry->elo_rating, $loserEntry->elo_rating,
                $winnerEntry->totalGames(), $loserEntry->totalGames()
            );

            $winnerEntry->increment('wins');
            $winnerEntry->increment('total_score', $winnerScore);
            $winnerEntry->update(['elo_rating' => $newWinnerElo]);

            $loserEntry->increment('losses');
            $loserEntry->increment('total_score', $loserScore);
            $loserEntry->update(['elo_rating' => $newLoserElo]);
        }
    }

    /**
     * Update leaderboard entries for a draw.
     */
    public static function updateAfterDraw(string $gameId, int $player1Id, int $player2Id, int $p1Score, int $p2Score): void
    {
        $now = now();
        $weekKey = $now->format('Y') . '-W' . str_pad($now->isoWeek(), 2, '0', STR_PAD_LEFT);
        $monthKey = $now->format('Y-m');

        $periods = [
            ['period' => 'weekly', 'period_key' => $weekKey],
            ['period' => 'monthly', 'period_key' => $monthKey],
            ['period' => 'alltime', 'period_key' => 'all'],
        ];

        foreach ($periods as $p) {
            foreach ([[$player1Id, $p1Score], [$player2Id, $p2Score]] as [$userId, $score]) {
                $entry = GameLeaderboardEntry::firstOrCreate(
                    ['user_id' => $userId, 'game_id' => $gameId, 'period' => $p['period'], 'period_key' => $p['period_key']],
                    ['elo_rating' => 1000]
                );
                $entry->increment('draws');
                $entry->increment('total_score', $score);
            }
        }
    }
}
```

- [ ] **Step 3: Create EscrowService**

```php
<?php

namespace App\Services\Games;

use App\Models\Games\GameEscrow;
use App\Models\Games\GameTransaction;
use Illuminate\Support\Facades\DB;

class EscrowService
{
    /**
     * Lock funds from user's wallet into escrow.
     * Returns escrow record or null on failure.
     */
    public static function lock(int $sessionId, int $userId, float $amount, string $currency = 'TZS'): ?GameEscrow
    {
        return DB::transaction(function () use ($sessionId, $userId, $amount, $currency) {
            // Debit wallet
            $wallet = DB::table('wallets')->where('user_id', $userId)->lockForUpdate()->first();
            if (!$wallet || $wallet->balance < $amount) {
                return null;
            }

            DB::table('wallets')->where('user_id', $userId)->decrement('balance', $amount);

            // Create escrow
            $escrow = GameEscrow::create([
                'session_id' => $sessionId,
                'user_id' => $userId,
                'amount' => $amount,
                'currency' => $currency,
                'status' => 'locked',
            ]);

            // Log transaction
            GameTransaction::create([
                'session_id' => $sessionId,
                'user_id' => $userId,
                'type' => 'stake_lock',
                'amount' => $amount,
                'currency' => $currency,
            ]);

            return $escrow;
        });
    }

    /**
     * Settle escrow after game ends. Winner gets pool minus platform fee.
     */
    public static function settle(int $sessionId, int $winnerId, float $platformFeeRate = 0.10): void
    {
        DB::transaction(function () use ($sessionId, $winnerId, $platformFeeRate) {
            $escrows = GameEscrow::where('session_id', $sessionId)->where('status', 'locked')->get();
            $totalPool = $escrows->sum('amount');
            $platformFee = round($totalPool * $platformFeeRate, 2);
            $winnerPayout = $totalPool - $platformFee;

            foreach ($escrows as $escrow) {
                if ($escrow->user_id === $winnerId) {
                    $escrow->update(['status' => 'settled', 'settled_amount' => $winnerPayout]);
                    DB::table('wallets')->where('user_id', $winnerId)->increment('balance', $winnerPayout);
                    GameTransaction::create([
                        'session_id' => $sessionId,
                        'user_id' => $winnerId,
                        'type' => 'win_payout',
                        'amount' => $winnerPayout,
                        'currency' => $escrow->currency,
                    ]);
                } else {
                    $escrow->update(['status' => 'settled', 'settled_amount' => 0]);
                }
            }

            // Platform fee transaction
            if ($platformFee > 0) {
                GameTransaction::create([
                    'session_id' => $sessionId,
                    'user_id' => $winnerId,
                    'type' => 'platform_fee',
                    'amount' => $platformFee,
                    'currency' => 'TZS',
                ]);
            }
        });
    }

    /**
     * Refund all escrows for a session (cancel/draw/timeout).
     */
    public static function refund(int $sessionId): void
    {
        DB::transaction(function () use ($sessionId) {
            $escrows = GameEscrow::where('session_id', $sessionId)->where('status', 'locked')->get();

            foreach ($escrows as $escrow) {
                DB::table('wallets')->where('user_id', $escrow->user_id)->increment('balance', $escrow->amount);
                $escrow->update(['status' => 'refunded', 'settled_amount' => $escrow->amount]);
                GameTransaction::create([
                    'session_id' => $sessionId,
                    'user_id' => $escrow->user_id,
                    'type' => 'refund',
                    'amount' => $escrow->amount,
                    'currency' => $escrow->currency,
                ]);
            }
        });
    }
}
```

- [ ] **Step 4: Create MatchmakingService**

```php
<?php

namespace App\Services\Games;

use App\Models\Games\GameSession;
use App\Models\Games\GameLeaderboardEntry;
use Illuminate\Support\Facades\Cache;

class MatchmakingService
{
    /**
     * Add player to matchmaking queue. Returns matched session or null.
     */
    public static function enqueue(string $gameId, string $stakeTier, int $userId): ?GameSession
    {
        $userElo = self::getPlayerElo($gameId, $userId);
        $queueKey = "matchmaking:{$gameId}:{$stakeTier}";

        // Check for existing player in queue within ELO range
        $queue = Cache::get($queueKey, []);

        foreach ($queue as $i => $entry) {
            if ($entry['user_id'] === $userId) continue;
            if (abs($entry['elo'] - $userElo) <= 400) {
                // Match found! Remove from queue
                unset($queue[$i]);
                Cache::put($queueKey, array_values($queue), 120);

                // Create session
                $stakeAmount = self::tierToAmount($stakeTier);
                $session = GameSession::create([
                    'game_id' => $gameId,
                    'mode' => 'ranked',
                    'status' => 'active',
                    'stake_tier' => $stakeTier,
                    'stake_amount' => $stakeAmount,
                    'platform_fee' => round($stakeAmount * 2 * 0.10, 2),
                    'player_1_id' => $entry['user_id'],
                    'player_2_id' => $userId,
                    'game_seed' => GameSession::generateSeed(),
                    'room_code' => GameSession::generateRoomCode(),
                    'started_at' => now(),
                ]);

                return $session;
            }
        }

        // No match — add to queue
        $queue[] = ['user_id' => $userId, 'elo' => $userElo, 'queued_at' => now()->timestamp];
        Cache::put($queueKey, $queue, 120);

        return null;
    }

    /**
     * Remove player from queue.
     */
    public static function dequeue(string $gameId, string $stakeTier, int $userId): void
    {
        $queueKey = "matchmaking:{$gameId}:{$stakeTier}";
        $queue = Cache::get($queueKey, []);
        $queue = array_values(array_filter($queue, fn($e) => $e['user_id'] !== $userId));
        Cache::put($queueKey, $queue, 120);
    }

    public static function getPlayerElo(string $gameId, int $userId): int
    {
        $entry = GameLeaderboardEntry::where('user_id', $userId)
            ->where('game_id', $gameId)
            ->where('period', 'alltime')
            ->first();
        return $entry ? $entry->elo_rating : 1000;
    }

    public static function tierToAmount(string $tier): float
    {
        return match ($tier) {
            'bronze' => 500,
            'silver' => 2000,
            'gold' => 5000,
            'diamond' => 20000,
            default => 0,
        };
    }
}
```

- [ ] **Step 5: Verify services load**

```bash
php artisan tinker --execute="new App\Services\Games\EloService; new App\Services\Games\EscrowService; new App\Services\Games\MatchmakingService; echo 'Services OK';"
```

---

## Task 4: Backend — Broadcast Events (5 events)

**Files:**
- Create: `app/Events/Games/PlayerJoined.php`
- Create: `app/Events/Games/GameStarted.php`
- Create: `app/Events/Games/PlayerMove.php`
- Create: `app/Events/Games/GameEnded.php`
- Create: `app/Events/Games/PlayerDisconnected.php`
- Modify: `routes/channels.php` — add game channel authorization

- [ ] **Step 1: Create events directory**

```bash
mkdir -p app/Events/Games
```

- [ ] **Step 2: Create all 5 events**

Each follows the existing TAJIRI Reverb event pattern (implements ShouldBroadcast, uses PrivateChannel).

**PlayerJoined.php:**
```php
<?php

namespace App\Events\Games;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class PlayerJoined implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public int $sessionId,
        public int $userId,
        public string $userName,
        public ?string $avatar,
    ) {}

    public function broadcastOn(): array
    {
        return [new PrivateChannel('game.' . $this->sessionId)];
    }

    public function broadcastAs(): string
    {
        return 'player.joined';
    }

    public function broadcastWith(): array
    {
        return [
            'user_id' => $this->userId,
            'user_name' => $this->userName,
            'avatar' => $this->avatar,
        ];
    }
}
```

**GameStarted.php:**
```php
<?php

namespace App\Events\Games;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class GameStarted implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public int $sessionId,
        public string $seed,
        public ?array $initialState,
    ) {}

    public function broadcastOn(): array
    {
        return [new PrivateChannel('game.' . $this->sessionId)];
    }

    public function broadcastAs(): string
    {
        return 'game.started';
    }

    public function broadcastWith(): array
    {
        return [
            'session_id' => $this->sessionId,
            'seed' => $this->seed,
            'initial_state' => $this->initialState,
        ];
    }
}
```

**PlayerMove.php:**
```php
<?php

namespace App\Events\Games;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class PlayerMove implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public int $sessionId,
        public int $userId,
        public array $moveData,
    ) {}

    public function broadcastOn(): array
    {
        return [new PrivateChannel('game.' . $this->sessionId)];
    }

    public function broadcastAs(): string
    {
        return 'player.move';
    }

    public function broadcastWith(): array
    {
        return [
            'user_id' => $this->userId,
            'move_data' => $this->moveData,
        ];
    }
}
```

**GameEnded.php:**
```php
<?php

namespace App\Events\Games;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class GameEnded implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public int $sessionId,
        public ?int $winnerId,
        public array $scores,
        public array $payouts,
    ) {}

    public function broadcastOn(): array
    {
        return [new PrivateChannel('game.' . $this->sessionId)];
    }

    public function broadcastAs(): string
    {
        return 'game.ended';
    }

    public function broadcastWith(): array
    {
        return [
            'session_id' => $this->sessionId,
            'winner_id' => $this->winnerId,
            'scores' => $this->scores,
            'payouts' => $this->payouts,
        ];
    }
}
```

**PlayerDisconnected.php:**
```php
<?php

namespace App\Events\Games;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class PlayerDisconnected implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public int $sessionId,
        public int $userId,
        public int $gracePeriodSeconds = 30,
    ) {}

    public function broadcastOn(): array
    {
        return [new PrivateChannel('game.' . $this->sessionId)];
    }

    public function broadcastAs(): string
    {
        return 'player.disconnected';
    }

    public function broadcastWith(): array
    {
        return [
            'user_id' => $this->userId,
            'grace_period_seconds' => $this->gracePeriodSeconds,
        ];
    }
}
```

- [ ] **Step 3: Add channel authorization to routes/channels.php**

Append:
```php
Broadcast::channel('game.{sessionId}', function ($user, $sessionId) {
    $session = \App\Models\Games\GameSession::find($sessionId);
    return $session && $session->isPlayer($user->id);
});
```

- [ ] **Step 4: Verify events compile**

```bash
php artisan tinker --execute="new App\Events\Games\PlayerJoined(1, 1, 'Test', null); echo 'Events OK';"
```

---

## Task 5: Backend — Controllers & Routes (12 endpoints)

**Files:**
- Create: `app/Http/Controllers/Api/GameSessionController.php`
- Create: `app/Http/Controllers/Api/GameEscrowController.php`
- Create: `app/Http/Controllers/Api/GameLeaderboardController.php`
- Modify: `routes/api.php`

- [ ] **Step 1: Create GameSessionController**

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Games\GameSession;
use App\Services\Games\EscrowService;
use App\Services\Games\MatchmakingService;
use App\Services\Games\EloService;
use App\Events\Games\PlayerJoined;
use App\Events\Games\GameStarted;
use App\Events\Games\PlayerMove;
use App\Events\Games\GameEnded;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class GameSessionController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'game_id' => 'required|string',
            'mode' => 'required|string|in:practice,friend,ranked',
            'user_id' => 'required|integer',
            'stake_tier' => 'string|in:free,bronze,silver,gold,diamond,custom',
            'stake_amount' => 'numeric|min:0',
            'opponent_id' => 'nullable|integer', // for friend challenge
        ]);

        $userId = $request->integer('user_id');
        $mode = $request->mode;
        $stakeTier = $request->input('stake_tier', 'free');
        $stakeAmount = $stakeTier === 'custom'
            ? $request->float('stake_amount', 0)
            : MatchmakingService::tierToAmount($stakeTier);

        // Practice mode — create session immediately
        if ($mode === 'practice') {
            $session = GameSession::create([
                'game_id' => $request->game_id,
                'mode' => 'practice',
                'status' => 'active',
                'stake_tier' => 'free',
                'stake_amount' => 0,
                'platform_fee' => 0,
                'player_1_id' => $userId,
                'game_seed' => GameSession::generateSeed(),
                'room_code' => GameSession::generateRoomCode(),
                'started_at' => now(),
            ]);

            return response()->json(['success' => true, 'data' => $session], 201);
        }

        // Friend challenge — create pending session
        if ($mode === 'friend') {
            $session = GameSession::create([
                'game_id' => $request->game_id,
                'mode' => 'friend',
                'status' => 'pending',
                'stake_tier' => $stakeTier,
                'stake_amount' => $stakeAmount,
                'platform_fee' => $stakeAmount > 0 ? round($stakeAmount * 2 * 0.10, 2) : 0,
                'player_1_id' => $userId,
                'player_2_id' => $request->opponent_id,
                'game_seed' => GameSession::generateSeed(),
                'room_code' => GameSession::generateRoomCode(),
            ]);

            // Lock challenger's stake
            if ($stakeAmount > 0) {
                $escrow = EscrowService::lock($session->id, $userId, $stakeAmount);
                if (!$escrow) {
                    $session->update(['status' => 'cancelled']);
                    return response()->json(['success' => false, 'message' => 'Insufficient wallet balance'], 422);
                }
            }

            return response()->json(['success' => true, 'data' => $session], 201);
        }

        // Ranked — try matchmaking
        if ($stakeAmount > 0) {
            // Verify balance first
            $wallet = DB::table('wallets')->where('user_id', $userId)->first();
            if (!$wallet || $wallet->balance < $stakeAmount) {
                return response()->json(['success' => false, 'message' => 'Insufficient wallet balance'], 422);
            }
        }

        $session = MatchmakingService::enqueue($request->game_id, $stakeTier, $userId);

        if ($session) {
            // Matched! Lock both stakes
            if ($stakeAmount > 0) {
                EscrowService::lock($session->id, $session->player_1_id, $stakeAmount);
                EscrowService::lock($session->id, $session->player_2_id, $stakeAmount);
            }

            // Broadcast to both
            $opponent = DB::table('users')->find($session->player_1_id === $userId ? $session->player_2_id : $session->player_1_id);
            if ($opponent) {
                broadcast(new PlayerJoined($session->id, $opponent->id, $opponent->name, $opponent->profile_photo_path));
            }

            return response()->json(['success' => true, 'data' => $session, 'matched' => true], 201);
        }

        // Not matched yet — player is in queue
        return response()->json(['success' => true, 'data' => null, 'matched' => false, 'message' => 'In matchmaking queue']);
    }

    public function show(int $id): JsonResponse
    {
        $session = GameSession::with('escrows')->find($id);
        if (!$session) {
            return response()->json(['success' => false, 'message' => 'Session not found'], 404);
        }
        return response()->json(['success' => true, 'data' => $session]);
    }

    public function join(Request $request, int $id): JsonResponse
    {
        $request->validate(['user_id' => 'required|integer']);
        $userId = $request->integer('user_id');

        $session = GameSession::find($id);
        if (!$session || $session->status !== 'pending') {
            return response()->json(['success' => false, 'message' => 'Session not available'], 422);
        }

        // Lock joiner's stake
        if ($session->stake_amount > 0) {
            $escrow = EscrowService::lock($session->id, $userId, (float) $session->stake_amount);
            if (!$escrow) {
                return response()->json(['success' => false, 'message' => 'Insufficient wallet balance'], 422);
            }
        }

        $session->update([
            'player_2_id' => $userId,
            'status' => 'active',
            'started_at' => now(),
        ]);

        // Broadcast
        $user = DB::table('users')->find($userId);
        broadcast(new PlayerJoined($session->id, $userId, $user->name ?? 'Player', $user->profile_photo_path ?? null));
        broadcast(new GameStarted($session->id, $session->game_seed, $session->game_state));

        return response()->json(['success' => true, 'data' => $session]);
    }

    public function move(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'user_id' => 'required|integer',
            'move_data' => 'required|array',
        ]);

        $session = GameSession::find($id);
        if (!$session || $session->status !== 'active') {
            return response()->json(['success' => false, 'message' => 'Game not active'], 422);
        }

        if (!$session->isPlayer($request->integer('user_id'))) {
            return response()->json(['success' => false, 'message' => 'Not a player in this game'], 403);
        }

        // Broadcast move to opponent
        broadcast(new PlayerMove($session->id, $request->integer('user_id'), $request->move_data));

        // Update game state if provided
        if ($request->has('game_state')) {
            $session->update(['game_state' => $request->game_state]);
        }

        return response()->json(['success' => true]);
    }

    public function end(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'winner_id' => 'nullable|integer',
            'player_1_score' => 'required|integer',
            'player_2_score' => 'required|integer',
        ]);

        $session = GameSession::find($id);
        if (!$session || $session->status !== 'active') {
            return response()->json(['success' => false, 'message' => 'Game not active'], 422);
        }

        $winnerId = $request->winner_id;
        $isDraw = $winnerId === null;

        $session->update([
            'player_1_score' => $request->player_1_score,
            'player_2_score' => $request->player_2_score,
            'winner_id' => $winnerId,
            'status' => 'completed',
            'ended_at' => now(),
        ]);

        // Handle escrow
        if ($session->stake_amount > 0) {
            if ($isDraw) {
                EscrowService::refund($session->id);
            } else {
                EscrowService::settle($session->id, $winnerId);
            }
        }

        // Update leaderboards (skip practice)
        if ($session->mode !== 'practice' && $session->player_2_id) {
            if ($isDraw) {
                EloService::updateAfterDraw(
                    $session->game_id, $session->player_1_id, $session->player_2_id,
                    $request->player_1_score, $request->player_2_score
                );
            } else {
                $loserId = $winnerId === $session->player_1_id ? $session->player_2_id : $session->player_1_id;
                $winnerScore = $winnerId === $session->player_1_id ? $request->player_1_score : $request->player_2_score;
                $loserScore = $winnerId === $session->player_1_id ? $request->player_2_score : $request->player_1_score;
                EloService::updateAfterMatch($session->game_id, $winnerId, $loserId, $winnerScore, $loserScore);
            }
        }

        // Build payouts for broadcast
        $payouts = [];
        if ($session->stake_amount > 0) {
            $escrows = $session->escrows()->get();
            foreach ($escrows as $e) {
                $payouts[] = ['user_id' => $e->user_id, 'amount' => (float) $e->settled_amount, 'status' => $e->status];
            }
        }

        broadcast(new GameEnded($session->id, $winnerId, [
            'player_1' => $request->player_1_score,
            'player_2' => $request->player_2_score,
        ], $payouts));

        $session->load('escrows');
        return response()->json(['success' => true, 'data' => $session]);
    }

    public function active(Request $request): JsonResponse
    {
        $userId = $request->integer('user_id');
        $sessions = GameSession::where(function ($q) use ($userId) {
                $q->where('player_1_id', $userId)->orWhere('player_2_id', $userId);
            })
            ->whereIn('status', ['pending', 'matching', 'active'])
            ->orderBy('created_at', 'desc')
            ->limit(20)
            ->get();

        return response()->json(['success' => true, 'data' => $sessions]);
    }

    public function history(Request $request): JsonResponse
    {
        $userId = $request->integer('user_id');
        $sessions = GameSession::where(function ($q) use ($userId) {
                $q->where('player_1_id', $userId)->orWhere('player_2_id', $userId);
            })
            ->whereIn('status', ['completed', 'forfeited'])
            ->with('escrows')
            ->orderBy('ended_at', 'desc')
            ->paginate($request->integer('per_page', 20));

        return response()->json([
            'success' => true,
            'data' => $sessions->items(),
            'meta' => [
                'total' => $sessions->total(),
                'current_page' => $sessions->currentPage(),
                'last_page' => $sessions->lastPage(),
            ],
        ]);
    }
}
```

- [ ] **Step 2: Create GameEscrowController**

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\Games\EscrowService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GameEscrowController extends Controller
{
    public function lock(Request $request): JsonResponse
    {
        $request->validate([
            'session_id' => 'required|integer',
            'user_id' => 'required|integer',
            'amount' => 'required|numeric|min:100',
        ]);

        $escrow = EscrowService::lock($request->integer('session_id'), $request->integer('user_id'), $request->float('amount'));

        if (!$escrow) {
            return response()->json(['success' => false, 'message' => 'Insufficient wallet balance'], 422);
        }

        return response()->json(['success' => true, 'data' => $escrow], 201);
    }

    public function settle(Request $request): JsonResponse
    {
        $request->validate([
            'session_id' => 'required|integer',
            'winner_id' => 'required|integer',
        ]);

        EscrowService::settle($request->integer('session_id'), $request->integer('winner_id'));

        return response()->json(['success' => true]);
    }

    public function refund(Request $request): JsonResponse
    {
        $request->validate(['session_id' => 'required|integer']);

        EscrowService::refund($request->integer('session_id'));

        return response()->json(['success' => true]);
    }
}
```

- [ ] **Step 3: Create GameLeaderboardController**

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Games\GameLeaderboardEntry;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class GameLeaderboardController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $gameId = $request->input('game_id');
        $period = $request->input('period', 'alltime');
        $limit = $request->integer('limit', 50);

        $now = now();
        $periodKey = match ($period) {
            'weekly' => $now->format('Y') . '-W' . str_pad($now->isoWeek(), 2, '0', STR_PAD_LEFT),
            'monthly' => $now->format('Y-m'),
            default => 'all',
        };

        $query = GameLeaderboardEntry::where('period', $period)
            ->where('period_key', $periodKey);

        if ($gameId) {
            $query->where('game_id', $gameId);
        }

        $entries = $query->orderBy('elo_rating', 'desc')
            ->limit($limit)
            ->get();

        // Join user data
        $userIds = $entries->pluck('user_id')->unique();
        $users = DB::table('users')->whereIn('id', $userIds)->get()->keyBy('id');
        $profiles = DB::table('user_profiles')->whereIn('user_id', $userIds)->get()->keyBy('user_id');

        $data = $entries->values()->map(function ($entry, $index) use ($users, $profiles) {
            $user = $users->get($entry->user_id);
            $profile = $profiles->get($entry->user_id);
            return [
                'rank' => $index + 1,
                'user_id' => $entry->user_id,
                'user_name' => $user->name ?? 'Unknown',
                'avatar' => $profile->profile_image ?? $user->profile_photo_path ?? null,
                'game_id' => $entry->game_id,
                'wins' => $entry->wins,
                'losses' => $entry->losses,
                'draws' => $entry->draws,
                'total_score' => $entry->total_score,
                'elo_rating' => $entry->elo_rating,
            ];
        });

        return response()->json(['success' => true, 'data' => $data]);
    }

    public function friends(Request $request): JsonResponse
    {
        $userId = $request->integer('user_id');
        $gameId = $request->input('game_id');
        $period = $request->input('period', 'alltime');

        $now = now();
        $periodKey = match ($period) {
            'weekly' => $now->format('Y') . '-W' . str_pad($now->isoWeek(), 2, '0', STR_PAD_LEFT),
            'monthly' => $now->format('Y-m'),
            default => 'all',
        };

        // Get friend IDs
        $friendIds = DB::table('friendships')
            ->where(function ($q) use ($userId) {
                $q->where('user_id', $userId)->orWhere('friend_id', $userId);
            })
            ->where('status', 'accepted')
            ->get()
            ->map(fn($f) => $f->user_id === $userId ? $f->friend_id : $f->user_id)
            ->push($userId) // Include self
            ->unique()
            ->values();

        $query = GameLeaderboardEntry::whereIn('user_id', $friendIds)
            ->where('period', $period)
            ->where('period_key', $periodKey);

        if ($gameId) {
            $query->where('game_id', $gameId);
        }

        $entries = $query->orderBy('elo_rating', 'desc')->limit(50)->get();

        $users = DB::table('users')->whereIn('id', $friendIds)->get()->keyBy('id');
        $profiles = DB::table('user_profiles')->whereIn('user_id', $friendIds)->get()->keyBy('user_id');

        $data = $entries->values()->map(function ($entry, $index) use ($users, $profiles) {
            $user = $users->get($entry->user_id);
            $profile = $profiles->get($entry->user_id);
            return [
                'rank' => $index + 1,
                'user_id' => $entry->user_id,
                'user_name' => $user->name ?? 'Unknown',
                'avatar' => $profile->profile_image ?? $user->profile_photo_path ?? null,
                'game_id' => $entry->game_id,
                'wins' => $entry->wins,
                'losses' => $entry->losses,
                'elo_rating' => $entry->elo_rating,
            ];
        });

        return response()->json(['success' => true, 'data' => $data]);
    }
}
```

- [ ] **Step 4: Add routes to api.php**

Append:
```php
// Games Platform
Route::prefix('games')->group(function () {
    Route::post('/sessions', [App\Http\Controllers\Api\GameSessionController::class, 'store']);
    Route::get('/sessions/{id}', [App\Http\Controllers\Api\GameSessionController::class, 'show']);
    Route::post('/sessions/{id}/join', [App\Http\Controllers\Api\GameSessionController::class, 'join']);
    Route::post('/sessions/{id}/move', [App\Http\Controllers\Api\GameSessionController::class, 'move']);
    Route::post('/sessions/{id}/end', [App\Http\Controllers\Api\GameSessionController::class, 'end']);
    Route::get('/sessions/active', [App\Http\Controllers\Api\GameSessionController::class, 'active']);
    Route::get('/sessions/history', [App\Http\Controllers\Api\GameSessionController::class, 'history']);

    Route::post('/escrow/lock', [App\Http\Controllers\Api\GameEscrowController::class, 'lock']);
    Route::post('/escrow/settle', [App\Http\Controllers\Api\GameEscrowController::class, 'settle']);
    Route::post('/escrow/refund', [App\Http\Controllers\Api\GameEscrowController::class, 'refund']);

    Route::get('/leaderboard', [App\Http\Controllers\Api\GameLeaderboardController::class, 'index']);
    Route::get('/leaderboard/friends', [App\Http\Controllers\Api\GameLeaderboardController::class, 'friends']);
});
```

**IMPORTANT:** The `active` and `history` routes must come BEFORE the `{id}` wildcard routes, otherwise Laravel will interpret "active" and "history" as session IDs. Reorder so static routes come first:

```php
Route::prefix('games')->group(function () {
    // Static session routes first
    Route::get('/sessions/active', [App\Http\Controllers\Api\GameSessionController::class, 'active']);
    Route::get('/sessions/history', [App\Http\Controllers\Api\GameSessionController::class, 'history']);

    // Dynamic session routes
    Route::post('/sessions', [App\Http\Controllers\Api\GameSessionController::class, 'store']);
    Route::get('/sessions/{id}', [App\Http\Controllers\Api\GameSessionController::class, 'show']);
    Route::post('/sessions/{id}/join', [App\Http\Controllers\Api\GameSessionController::class, 'join']);
    Route::post('/sessions/{id}/move', [App\Http\Controllers\Api\GameSessionController::class, 'move']);
    Route::post('/sessions/{id}/end', [App\Http\Controllers\Api\GameSessionController::class, 'end']);

    Route::post('/escrow/lock', [App\Http\Controllers\Api\GameEscrowController::class, 'lock']);
    Route::post('/escrow/settle', [App\Http\Controllers\Api\GameEscrowController::class, 'settle']);
    Route::post('/escrow/refund', [App\Http\Controllers\Api\GameEscrowController::class, 'refund']);

    Route::get('/leaderboard', [App\Http\Controllers\Api\GameLeaderboardController::class, 'index']);
    Route::get('/leaderboard/friends', [App\Http\Controllers\Api\GameLeaderboardController::class, 'friends']);
});
```

- [ ] **Step 5: Verify routes**

```bash
php artisan route:list --path=games/sessions
php artisan route:list --path=games/escrow
php artisan route:list --path=games/leaderboard
```

Expected: 12 new routes total.

- [ ] **Step 6: Test session creation**

```bash
curl -s -X POST https://tajiri.zimasystems.com/api/games/sessions \
  -H 'Content-Type: application/json' \
  -d '{"game_id":"trivia","mode":"practice","user_id":38}' | python3 -m json.tool
```

Expected: `{"success": true, "data": {"id": 1, "game_id": "trivia", "mode": "practice", "status": "active", ...}}`

---

## Task 6: Frontend — Core (enums, definition, interface, context, registry)

**Files:**
- Create: `lib/games/core/game_enums.dart`
- Create: `lib/games/core/game_definition.dart`
- Create: `lib/games/core/game_interface.dart`
- Create: `lib/games/core/game_context.dart`
- Create: `lib/games/core/game_registry.dart`

These are the foundation of the plugin system. All pure Dart — no Flutter UI, no API calls.

- [ ] **Step 1: Create core directory and write all 5 files**

The enums, definition, interface, context, and registry files. GameCategory has 9 values (puzzle, trivia, word, card, board, arcade, math, strategy, all) each with displayName, displayNameSwahili, and icon. GameMode: practice, friend, ranked. StakeTier: free, bronze, silver, gold, diamond, custom — each with amount getter. SessionStatus: pending, matching, active, completed, cancelled, forfeited.

GameDefinition is a const data class with all fields from the spec. GameInterface is an abstract class with gameId getter, onOpponentMove(), onReconnect(), getCurrentState(). GameContext holds runtime session data. GameRegistry is a singleton with register(), allGames, byCategory(), get(), search().

- [ ] **Step 2: Verify with flutter analyze**

```bash
flutter analyze lib/games/core/
```

---

## Task 7: Frontend — Models (5 model files)

**Files:**
- Create: `lib/games/models/game_session.dart`
- Create: `lib/games/models/game_escrow.dart`
- Create: `lib/games/models/leaderboard_entry.dart`
- Create: `lib/games/models/match_result.dart`
- Create: `lib/games/models/challenge.dart`

All follow TAJIRI fromJson pattern with _parseInt, _parseDouble, _parseBool helpers.

GameSession: id, gameId, mode, status (SessionStatus), stakeTier, stakeAmount, currency, platformFee, player1Id, player2Id, player1Score, player2Score, winnerId, gameSeed, gameState, roomCode, startedAt, endedAt. Computed: isActive, isCompleted, isMyWin(userId).

GameEscrow: id, sessionId, userId, amount, currency, status, settledAmount.

LeaderboardEntry: rank, userId, userName, avatar, gameId, wins, losses, draws, totalScore, eloRating. Computed: totalGames, winRate.

MatchResult: winnerId, scores (Map), payouts (List), isDraw.

Challenge: sessionId, gameId, challengerId, challengerName, challengerAvatar, stakeTier, stakeAmount, createdAt.

---

## Task 8: Frontend — Services (REST + WebSocket)

**Files:**
- Create: `lib/games/services/games_service.dart` (replace existing)
- Create: `lib/games/services/game_socket_service.dart`

GamesService: REST calls to all 12 endpoints. createSession(), getSession(), joinSession(), submitMove(), endGame(), getActiveSessions(), getHistory(), lockEscrow(), settleEscrow(), refundEscrow(), getLeaderboard(), getFriendsLeaderboard().

GameSocketService: WebSocket connection to Laravel Reverb. Methods: connect(sessionId), disconnect(), sendMove(moveData), onPlayerJoined callback, onGameStarted callback, onPlayerMove callback, onGameEnded callback, onPlayerDisconnected callback. Uses `web_socket_channel` package connecting to `wss://tajiri.zimasystems.com:6001/app/tajiri-reverb-key-2026`.

---

## Task 9: Frontend — Widgets (7 widgets)

**Files:**
- Create: `lib/games/widgets/game_card.dart` (replace existing)
- Create: `lib/games/widgets/challenge_card.dart`
- Create: `lib/games/widgets/match_card.dart`
- Create: `lib/games/widgets/leaderboard_tile.dart`
- Create: `lib/games/widgets/stake_selector.dart`
- Create: `lib/games/widgets/player_banner.dart`
- Create: `lib/games/widgets/game_timer.dart`

All follow TAJIRI widget patterns: _kPrimary/#1A1A1A, _kSecondary/#666666, BorderRadius.circular(12), bilingual labels.

GameCard: game tile showing icon/image, name, category badge, estimated time, player count. Tap → lobby.

ChallengeCard: pending challenge showing challenger avatar, game name, stake amount, Accept/Decline buttons.

MatchCard: active/recent match showing game icon, opponent name, status, score, time ago.

LeaderboardTile: rank (medals for top 3), avatar, name, wins/losses, ELO rating.

StakeSelector: horizontal tier chips (Free/Bronze/Silver/Gold/Diamond) + custom input. Shows wallet balance. Grey out unaffordable.

PlayerBanner: avatar, name, current score. Used in GamePlayPage top bar.

GameTimer: circular countdown timer widget with seconds remaining, color changes at 10s/5s warning.

---

## Task 10: Frontend — Pages (5 pages)

**Files:**
- Create: `lib/games/pages/games_home_page.dart` (replace existing)
- Create: `lib/games/pages/game_lobby_page.dart`
- Create: `lib/games/pages/game_room_page.dart`
- Create: `lib/games/pages/game_play_page.dart`
- Create: `lib/games/pages/game_result_page.dart`

GamesHomePage: No AppBar (inside _ProfileTabPage). Search bar, category chips, "My Matches" section (pending challenges as ChallengeCards, active games as MatchCards), featured games horizontal scroll, full game grid (2 columns of GameCards). Reads from GameRegistry. Pull-to-refresh loads active sessions from API.

GameLobbyPage: Receives GameDefinition. Game info header. Mode cards (Practice/Challenge Friend/Ranked). StakeSelector shown for friend/ranked. Friend picker (bottom sheet listing accepted friendships). "Start Match" button. Calls GamesService.createSession().

GameRoomPage: Receives GameSession. Shows both player slots. Connects to WebSocket. Listens for PlayerJoined event. Once opponent joins: 3-2-1 countdown animation → navigate to GamePlayPage. Timeout handling (5min friend, 60s ranked) → cancel + refund.

GamePlayPage: Receives GameSession + GameDefinition. Top bar with PlayerBanner (left/right), GameTimer (center). Builds game widget from GameDefinition.builder(gameContext). Forwards WebSocket events to game widget. When game calls onGameComplete → calls GamesService.endGame() → navigates to GameResultPage.

GameResultPage: Receives GameSession (completed). Winner announcement (confetti for winner). Score comparison. Payout display. Buttons: Rematch (creates new session with same params), New Game (pop to lobby), Home (pop to home). "Share" button (SnackBar placeholder).

---

## Task 11: Frontend — Module Entry & Cleanup

**Files:**
- Modify: `lib/games/games_module.dart`
- Delete: `lib/games/models/games_models.dart` (old)
- Delete: `lib/games/pages/game_detail_page.dart` (old)
- Delete: `lib/games/pages/leaderboard_page.dart` (old)

- [ ] **Step 1: Replace games_module.dart**

```dart
import 'package:flutter/material.dart';
import 'pages/games_home_page.dart';

class GamesModule extends StatelessWidget {
  final int userId;
  const GamesModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) => GamesHomePage(userId: userId);
}
```

- [ ] **Step 2: Delete old files**

```bash
rm lib/games/models/games_models.dart
rm lib/games/pages/game_detail_page.dart
rm lib/games/pages/leaderboard_page.dart
```

- [ ] **Step 3: Create empty games directory for future game implementations**

```bash
mkdir -p lib/games/games
```

- [ ] **Step 4: Verify full module**

```bash
flutter analyze lib/games/
```

Expected: No issues found.

---

## Verification Checklist

After all tasks:

- [ ] Backend: `php artisan route:list --path=games` shows 12 routes (plus pre-existing games catalog routes)
- [ ] Backend: `POST /api/games/sessions` creates a practice session
- [ ] Backend: `POST /api/games/sessions` with friend mode creates pending session
- [ ] Backend: `POST /api/games/sessions/{id}/join` activates session and broadcasts PlayerJoined
- [ ] Backend: `POST /api/games/sessions/{id}/end` completes session, settles escrow, updates ELO
- [ ] Backend: `GET /api/games/leaderboard` returns ranked entries
- [ ] Frontend: `flutter analyze lib/games/` — zero errors
- [ ] Frontend: GamesModule opens from profile tab
- [ ] Frontend: GameRegistry accepts registrations and returns games
- [ ] Frontend: Home page shows game grid from registry + active sessions from API
- [ ] Frontend: Lobby → Room → Play → Result flow navigates correctly
- [ ] Frontend: StakeSelector shows wallet balance and disables unaffordable tiers
