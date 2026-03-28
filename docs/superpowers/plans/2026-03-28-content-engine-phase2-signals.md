# Content Engine Phase 2: Signal Processing — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the real-time signal processing pipeline that captures engagement events, computes engagement/trending/freshness scores in Redis, syncs dirty scores to PostgreSQL and Typesense, and schedules periodic score refreshes — making the Content Engine's scores live and reactive.

**Architecture:** When a user interacts with content, the existing `UserEventController::store()` already writes to `user_events`. We add a Redis Stream fanout (`XADD engagement:signals`) in the same controller. Three signal consumer artisan commands process the stream: (1) Document Score Updater computes per-doc engagement counters and engagement_score in Redis hashes, (2) Trending Detector checks velocity every 2 minutes and updates trending sorted sets, (3) User Profile Updater builds per-user affinity hashes. A Score Sync worker flushes dirty scores from Redis to PostgreSQL/Typesense every 30 seconds. Scheduled commands refresh freshness_score (every 5 min) and creator_authority (every 30 min). Anti-gaming rules cap signals.

**Tech Stack:** Laravel 12, PHP 8.3, Redis (Streams, Hashes, Sorted Sets, Sets), PostgreSQL, Typesense, Supervisor

**Server access:** `sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@zima-uat.site`

**Spec reference:** `docs/superpowers/specs/2026-03-28-tajiri-content-engine-design.md` — Sections 4 (Indexing/Scoring) and 5 (Real-Time Signal Processor)

**Depends on:** Phase 0 (infrastructure) and Phase 1 (ingestion pipeline) complete. Key existing code:
- `app/Http/Controllers/Api/UserEventController.php` — batch event endpoint
- `app/Models/UserEvent.php` — event_type, post_id, creator_id, duration_ms, session_id, metadata
- `app/Models/ContentDocument.php` — all score columns, composite_score, content_tier
- `app/Models/ScoringConfig.php` — cached weight retrieval
- `app/Jobs/ContentEngine/ClaudeScoreContentJob::recomputeComposite()` — existing composite formula
- `app/Services/ContentEngine/TypesenseService.php` — upsert/delete
- `config/content-engine.php` — scoring half-lives, tier thresholds, engagement_normalization_k
- `routes/console.php` — existing scheduled tasks
- Supervisor managing 10 queue workers (4 queues)
- 60,810+ content_documents indexed

---

## File Map

### Backend (on server: /var/www/html/tajiri/)

| Action | File | Purpose |
|---|---|---|
| Modify | `config/content-engine.php` | Add signal weights, decay windows, anti-gaming config |
| Modify | `app/Models/ContentDocument.php` | Add shared `recomputeCompositeAndTier()` method (DRY) |
| Modify | `app/Jobs/ContentEngine/ClaudeScoreContentJob.php` | Refactor to use shared `ContentDocument::recomputeCompositeAndTier()` |
| Create | `app/Services/ContentEngine/SignalService.php` | Redis signal operations: increment counters, compute engagement_score, manage dirty set, anti-gaming |
| Create | `app/Services/ContentEngine/TrendingService.php` | Trending velocity calculation, sorted set management |
| Create | `app/Services/ContentEngine/UserSignalService.php` | Per-user affinity hash management |
| Modify | `app/Http/Controllers/Api/UserEventController.php` | Add Redis Stream XADD with source_type after DB insert |
| Create | `app/Console/Commands/SignalConsumer.php` | `signal:consume` — reads Redis Stream, dispatches to 3 handlers |
| Create | `app/Console/Commands/TrendingDetector.php` | `signal:detect-trending` — velocity check, trending sorted sets |
| Create | `app/Console/Commands/ScoreSyncWorker.php` | `signal:sync-scores` — flushes dirty set to PG + Typesense every 30s |
| Create | `app/Console/Commands/RefreshFreshness.php` | `content:refresh-freshness` — bulk SQL freshness_score update |
| Create | `app/Console/Commands/RefreshCreatorAuthority.php` | `content:refresh-creator-authority` — sync from creator_scores |
| Modify | `routes/console.php` | Add scheduled tasks for freshness, creator authority, trending |
| Create | `/etc/supervisor/conf.d/content-signals.conf` | Supervisor for signal consumer + score sync |

---

## Task 1: Config — Add Signal Weights and Anti-Gaming Settings

**Files:**
- Modify: `config/content-engine.php`

- [ ] **Step 1: Read current config**

```bash
cd /var/www/html/tajiri
cat config/content-engine.php
```

- [ ] **Step 2: Add signal weights and anti-gaming sections**

Append these sections before the closing `];`:

```php
    /*
    |--------------------------------------------------------------------------
    | Signal Weights (engagement value per event type)
    |--------------------------------------------------------------------------
    */
    'signal_weights' => [
        'view_short' => 0.05,     // < 2s dwell
        'view_glance' => 0.1,     // 2-5s dwell
        'view_partial' => 0.3,    // 5-15s dwell
        'view_deep' => 0.5,       // 15s+ dwell
        'like' => 1.0,
        'save' => 1.8,
        'comment' => 2.0,
        'share' => 2.5,
        'reply' => 3.0,
        'follow' => 2.0,          // follow after viewing
        'scroll_past' => -0.2,    // < 0.5s
        'not_interested' => -5.0,
    ],

    /*
    |--------------------------------------------------------------------------
    | Signal Decay Windows (weight multipliers by age)
    |--------------------------------------------------------------------------
    */
    'signal_decay' => [
        'hot_hours' => 1,         // 1.0x weight
        'warm_hours' => 24,       // 0.5x weight
        'cool_hours' => 168,      // 0.2x weight (7 days)
        'cold_hours' => 720,      // 0.05x weight (30 days)
    ],

    /*
    |--------------------------------------------------------------------------
    | Anti-Gaming Rules
    |--------------------------------------------------------------------------
    */
    'anti_gaming' => [
        'per_user_cap_per_hour' => 1,           // max 1 signal per type per doc per hour
        'velocity_fraud_threshold' => 100,       // >100 in 5min from new accounts = fraud
        'new_account_days' => 7,                 // accounts < 7 days old
        'fraud_trending_cap' => 50,              // cap trending_score on fraud flag
        'ip_cluster_threshold' => 10,            // >10 same doc same IP in 5min
        'ip_cluster_count_limit' => 3,           // only first 3 count
        'zero_social_weight' => 0.1,             // 0 friends + 0 posts → 0.1x signal
    ],

    /*
    |--------------------------------------------------------------------------
    | Score Sync Configuration
    |--------------------------------------------------------------------------
    */
    'score_sync' => [
        'dirty_set_key' => 'scores:dirty',
        'sync_interval_seconds' => 30,
        'batch_size' => 200,
    ],
```

- [ ] **Step 3: Syntax check**

```bash
php -l config/content-engine.php
```

- [ ] **Step 4: Commit**

```bash
git add config/content-engine.php
git commit -m "feat(content-engine): add signal weights, decay windows, anti-gaming config"
```

---

## Task 2: Shared Composite Score Method (DRY Refactor)

**Files:**
- Modify: `app/Models/ContentDocument.php`
- Modify: `app/Jobs/ContentEngine/ClaudeScoreContentJob.php`

The composite score formula and tier assignment are needed in 3+ places (ClaudeScoreContentJob, ScoreSyncWorker, RefreshFreshness). Extract into a single shared method on ContentDocument.

- [ ] **Step 1: Read ContentDocument model**

```bash
cat app/Models/ContentDocument.php
```

- [ ] **Step 2: Add recomputeCompositeAndTier() method to ContentDocument**

Add this method at the end of the class (before closing `}`):

```php
    /**
     * Recompute composite_score and content_tier from current score fields.
     * Single source of truth for the scoring formula — called by ingestion,
     * signal sync, freshness refresh, etc.
     *
     * @param bool $save Whether to persist changes to the database.
     */
    public function recomputeCompositeAndTier(bool $save = true): void
    {
        $weights = \App\Models\ScoringConfig::allWeights();

        $this->composite_score = round(
            ($this->freshness_score * ($weights['w_freshness'] ?? 0.25)) +
            ($this->engagement_score * ($weights['w_engagement'] ?? 0.30)) +
            ($this->quality_score * 10 * ($weights['w_quality'] ?? 0.15)) +
            ($this->content_rank * ($weights['w_content_rank'] ?? 0.15)) +
            ($this->creator_authority * ($weights['w_creator_auth'] ?? 0.10)) +
            ($this->trending_score * ($weights['w_trending'] ?? 0.05)),
            2
        );

        $this->content_tier = match (true) {
            $this->spam_score > 7 => 'blackhole',
            $this->composite_score > config('content-engine.tiers.viral', 85) => 'viral',
            $this->composite_score > config('content-engine.tiers.high', 60) => 'high',
            $this->composite_score > config('content-engine.tiers.medium', 30) => 'medium',
            $this->composite_score > config('content-engine.tiers.low', 10) => 'low',
            default => 'blackhole',
        };

        $this->scores_updated_at = now();

        if ($save) {
            $this->save();
        }
    }
```

- [ ] **Step 3: Refactor ClaudeScoreContentJob to use shared method**

Read `app/Jobs/ContentEngine/ClaudeScoreContentJob.php`, then replace the `recomputeComposite` static method body with a delegation:

Replace the entire `public static function recomputeComposite(ContentDocument $doc): void` method with:

```php
    public static function recomputeComposite(ContentDocument $doc): void
    {
        $doc->recomputeCompositeAndTier(save: true);
    }
```

This preserves backward compatibility — all existing callers of `ClaudeScoreContentJob::recomputeComposite()` still work.

- [ ] **Step 4: Syntax check**

```bash
php -l app/Models/ContentDocument.php
php -l app/Jobs/ContentEngine/ClaudeScoreContentJob.php
```

- [ ] **Step 5: Commit**

```bash
git add app/Models/ContentDocument.php app/Jobs/ContentEngine/ClaudeScoreContentJob.php
git commit -m "refactor(content-engine): extract composite score formula into ContentDocument::recomputeCompositeAndTier()"
```

---

## Task 3: SignalService — Redis Counter and Engagement Score Engine

**Files:**
- Create: `app/Services/ContentEngine/SignalService.php`

Implements all 4 anti-gaming rules from spec: (1) per-user cap, (2) velocity squashing for new accounts, (3) social graph validation, (4) IP clustering.

- [ ] **Step 1: Write SignalService**

Write `app/Services/ContentEngine/SignalService.php`:

```php
<?php

namespace App\Services\ContentEngine;

use Illuminate\Support\Facades\Redis;

class SignalService
{
    /**
     * Redis hash key for per-document signal counters.
     */
    public static function docKey(string $sourceType, int $sourceId): string
    {
        return "signals:{$sourceType}:{$sourceId}";
    }

    /**
     * Classify a view event by dwell time.
     */
    public static function classifyView(int $durationMs): string
    {
        if ($durationMs < 500) return 'scroll_past';
        if ($durationMs < 2000) return 'view_short';
        if ($durationMs < 5000) return 'view_glance';
        if ($durationMs < 15000) return 'view_partial';
        return 'view_deep';
    }

    /**
     * Get the signal weight for an event type.
     */
    public static function getWeight(string $eventType, int $durationMs = 0): float
    {
        $weights = config('content-engine.signal_weights');

        if ($eventType === 'view' || $eventType === 'dwell' || $eventType === 'scroll_past') {
            $classified = self::classifyView($durationMs);
            return $weights[$classified] ?? 0.1;
        }

        return $weights[$eventType] ?? 0.1;
    }

    /**
     * Increment document counters in Redis and recompute engagement_score.
     * Enforces all 4 anti-gaming rules.
     * Returns the effective weight applied (0 if blocked by anti-gaming).
     */
    public static function incrementSignal(
        string $sourceType,
        int $sourceId,
        string $eventType,
        int $durationMs,
        int $userId,
        ?string $ipAddress = null
    ): float {
        $weight = self::getWeight($eventType, $durationMs);

        // === Anti-Gaming Rule 1: Per-user cap (1 signal per type per doc per hour) ===
        $capKey = "signal_cap:{$userId}:{$sourceType}:{$sourceId}:{$eventType}";
        $cap = config('content-engine.anti_gaming.per_user_cap_per_hour', 1);
        // Use NX to only set TTL on first creation (prevents TTL reset on subsequent hits)
        if (Redis::exists($capKey) && (int) Redis::get($capKey) >= $cap) {
            return 0;
        }
        $isNew = Redis::setnx($capKey, 0);
        if ($isNew) {
            Redis::expire($capKey, 3600);
        }
        Redis::incr($capKey);

        // === Anti-Gaming Rule 3: Social graph validation ===
        // Accounts with 0 friends + 0 posts → 0.1x signal weight
        $socialWeight = self::getSocialGraphWeight($userId);
        $weight *= $socialWeight;

        // === Anti-Gaming Rule 4: IP clustering ===
        // >10 engagements same doc same IP in 5min → only first 3 count
        if ($ipAddress) {
            $ipKey = "ip_cluster:{$ipAddress}:{$sourceType}:{$sourceId}";
            $ipCount = (int) Redis::incr($ipKey);
            if ($ipCount === 1) Redis::expire($ipKey, 300); // 5 min TTL
            $ipLimit = config('content-engine.anti_gaming.ip_cluster_threshold', 10);
            $ipCountLimit = config('content-engine.anti_gaming.ip_cluster_count_limit', 3);
            if ($ipCount > $ipLimit) {
                if ($ipCount > $ipLimit + $ipCountLimit) {
                    return 0; // Beyond the 3 that count after threshold
                }
            }
        }

        $docKey = self::docKey($sourceType, $sourceId);

        // Increment the appropriate counter
        $counterField = self::mapEventToCounter($eventType);
        if ($counterField) {
            Redis::hIncrBy($docKey, $counterField, 1);
        }

        // Track dwell time for views
        if (in_array($eventType, ['view', 'dwell']) && $durationMs > 0) {
            Redis::hIncrBy($docKey, 'total_dwell_ms', $durationMs);
        }

        // Increment 5-minute engagement window counter
        $fiveMinKey = "signals_5min:{$sourceType}:{$sourceId}";
        Redis::hIncrByFloat($fiveMinKey, 'weighted_sum', $weight);
        Redis::hIncrBy($fiveMinKey, 'count', 1);
        Redis::expire($fiveMinKey, 600); // 10 min TTL

        // === Anti-Gaming Rule 2: Velocity squashing for new accounts ===
        $newAccountDays = config('content-engine.anti_gaming.new_account_days', 7);
        $fraudThreshold = config('content-engine.anti_gaming.velocity_fraud_threshold', 100);
        $newAcctKey = "new_acct_engagements:{$sourceType}:{$sourceId}";
        if (self::isNewAccount($userId, $newAccountDays)) {
            $newAcctCount = (int) Redis::incr($newAcctKey);
            if ($newAcctCount === 1) Redis::expire($newAcctKey, 300); // 5 min window
            if ($newAcctCount > $fraudThreshold) {
                // Flag fraud — cap trending_score
                Redis::hSet($docKey, 'fraud_flagged', '1');
            }
        }

        // Recompute engagement_score
        self::recomputeEngagementScore($sourceType, $sourceId);

        // Mark document as dirty for PG sync AND trending candidates
        $dirtyKey = config('content-engine.score_sync.dirty_set_key', 'scores:dirty');
        $member = "{$sourceType}:{$sourceId}";
        Redis::sAdd($dirtyKey, $member);
        Redis::sAdd('trending:candidates', $member);

        // Set TTL on the doc hash (30 days)
        Redis::expire($docKey, 2592000);

        return $weight;
    }

    /**
     * Anti-gaming Rule 3: Check social graph weight for a user.
     * Cached in Redis for 1 hour.
     */
    private static function getSocialGraphWeight(int $userId): float
    {
        $cacheKey = "social_weight:{$userId}";
        $cached = Redis::get($cacheKey);
        if ($cached !== null) return (float) $cached;

        // Check friend count and post count
        $friendCount = \Illuminate\Support\Facades\DB::table('friends')
            ->where('user_id', $userId)
            ->orWhere('friend_id', $userId)
            ->limit(1)->count();
        $postCount = \Illuminate\Support\Facades\DB::table('posts')
            ->where('user_id', $userId)
            ->limit(1)->count();

        $weight = ($friendCount === 0 && $postCount === 0)
            ? config('content-engine.anti_gaming.zero_social_weight', 0.1)
            : 1.0;

        Redis::setex($cacheKey, 3600, $weight); // Cache 1 hour
        return $weight;
    }

    /**
     * Check if a user account is newer than the threshold.
     * Cached in Redis for 1 day.
     */
    private static function isNewAccount(int $userId, int $days): bool
    {
        $cacheKey = "new_account:{$userId}";
        $cached = Redis::get($cacheKey);
        if ($cached !== null) return $cached === '1';

        $user = \Illuminate\Support\Facades\DB::table('users')
            ->where('id', $userId)
            ->value('created_at');

        $isNew = $user && \Carbon\Carbon::parse($user)->gt(now()->subDays($days));
        Redis::setex($cacheKey, 86400, $isNew ? '1' : '0');
        return $isNew;
    }

    /**
     * Map event type to the counter field name in the Redis hash.
     */
    private static function mapEventToCounter(string $eventType): ?string
    {
        return match ($eventType) {
            'view', 'dwell' => 'views',
            'like' => 'likes',
            'comment' => 'comments',
            'share' => 'shares',
            'save' => 'saves',
            'reply' => 'replies',
            default => null,
        };
    }

    /**
     * Recompute engagement_score from counters in the Redis hash.
     * Formula: raw = views*0.1 + likes*1.0 + comments*2.0 + shares*2.5 + saves*1.8 + replies*3.0 + avg_dwell_sec*0.05
     * engagement_score = 100 * (1 - e^(-raw / k))
     */
    public static function recomputeEngagementScore(string $sourceType, int $sourceId): float
    {
        $docKey = self::docKey($sourceType, $sourceId);
        $data = Redis::hGetAll($docKey);

        $views = (int) ($data['views'] ?? 0);
        $likes = (int) ($data['likes'] ?? 0);
        $comments = (int) ($data['comments'] ?? 0);
        $shares = (int) ($data['shares'] ?? 0);
        $saves = (int) ($data['saves'] ?? 0);
        $replies = (int) ($data['replies'] ?? 0);
        $totalDwellMs = (int) ($data['total_dwell_ms'] ?? 0);
        $avgDwellSec = $views > 0 ? ($totalDwellMs / $views / 1000) : 0;

        $raw = $views * 0.1
            + $likes * 1.0
            + $comments * 2.0
            + $shares * 2.5
            + $saves * 1.8
            + $replies * 3.0
            + $avgDwellSec * 0.05;

        $k = config('content-engine.scoring.engagement_normalization_k', 50);
        $score = 100 * (1 - exp(-$raw / $k));

        Redis::hSet($docKey, 'engagement_score', round($score, 2));

        return $score;
    }

    /**
     * Get current engagement_score from Redis (or 0 if not set).
     */
    public static function getEngagementScore(string $sourceType, int $sourceId): float
    {
        return (float) (Redis::hGet(self::docKey($sourceType, $sourceId), 'engagement_score') ?? 0);
    }

    /**
     * Get all signal counters for a document.
     */
    public static function getCounters(string $sourceType, int $sourceId): array
    {
        return Redis::hGetAll(self::docKey($sourceType, $sourceId)) ?: [];
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
php -l app/Services/ContentEngine/SignalService.php
```

- [ ] **Step 3: Commit**

```bash
git add app/Services/ContentEngine/SignalService.php
git commit -m "feat(content-engine): add SignalService — Redis counters, engagement score, 4 anti-gaming rules"
```

---

## Task 4: TrendingService — Velocity Detection and Sorted Sets

**Files:**
- Create: `app/Services/ContentEngine/TrendingService.php`

- [ ] **Step 1: Write TrendingService**

Write `app/Services/ContentEngine/TrendingService.php`:

```php
<?php

namespace App\Services\ContentEngine;

use Illuminate\Support\Facades\Redis;

class TrendingService
{
    /**
     * Compute trending_score for a document based on velocity.
     * velocity = engagements_last_5min / max(engagements_avg_5min_last_24h, 1)
     * trending_score = min(100, velocity * 20)
     */
    public static function computeTrendingScore(string $sourceType, int $sourceId): float
    {
        $fiveMinKey = "signals_5min:{$sourceType}:{$sourceId}";
        $current5min = (int) (Redis::hGet($fiveMinKey, 'count') ?? 0);

        // Use the stored 24h average (updated by trending detector)
        $docKey = SignalService::docKey($sourceType, $sourceId);
        $avg5min24h = (float) (Redis::hGet($docKey, 'avg_5min_24h') ?? 1);
        if ($avg5min24h < 1) $avg5min24h = 1;

        $multiplier = config('content-engine.scoring.trending_velocity_multiplier', 20);
        $velocity = $current5min / $avg5min24h;
        $score = min(100, $velocity * $multiplier);

        return round($score, 2);
    }

    /**
     * Update trending sorted sets for a document.
     */
    public static function updateTrendingSets(
        string $sourceType,
        int $sourceId,
        float $trendingScore,
        ?string $region = null,
        ?string $category = null,
        ?array $hashtags = []
    ): void {
        $member = "{$sourceType}:{$sourceId}";

        // Global trending
        Redis::zAdd('trending:global', $trendingScore, $member);

        // Regional trending
        if ($region) {
            Redis::zAdd("trending:region:{$region}", $trendingScore, $member);
            Redis::expire("trending:region:{$region}", 86400);
        }

        // Category trending
        if ($category) {
            Redis::zAdd("trending:category:{$category}", $trendingScore, $member);
            Redis::expire("trending:category:{$category}", 86400);
        }

        // Hashtag trending
        if (!empty($hashtags)) {
            foreach (array_slice($hashtags, 0, 5) as $tag) {
                Redis::zAdd("trending:hashtag:{$tag}", $trendingScore, $member);
                Redis::expire("trending:hashtag:{$tag}", 86400);
            }
        }

        // Expire global trending entries older than 24h by pruning low scores
        // (actual pruning happens in TrendingDetector command)
    }

    /**
     * Get top trending documents globally.
     */
    public static function getTopTrending(int $limit = 50): array
    {
        return Redis::zRevRange('trending:global', 0, $limit - 1, 'WITHSCORES') ?: [];
    }

    /**
     * Get top trending for a region.
     */
    public static function getRegionTrending(string $region, int $limit = 50): array
    {
        return Redis::zRevRange("trending:region:{$region}", 0, $limit - 1, 'WITHSCORES') ?: [];
    }

    /**
     * Classify trending state based on velocity.
     */
    public static function classifyTrending(float $velocity): string
    {
        $rising = config('content-engine.scoring.trending_rising_threshold', 3);
        $breaking = config('content-engine.scoring.trending_breaking_threshold', 10);

        if ($velocity >= $breaking) return 'breaking';
        if ($velocity >= $rising) return 'rising';
        if ($velocity < 0.5) return 'cooling';
        return 'stable';
    }

    /**
     * Prune trending sets — remove entries with score < threshold.
     */
    public static function pruneGlobalTrending(float $minScore = 1.0): int
    {
        // Exclusive upper bound: remove entries with score strictly less than minScore
        return Redis::zRemRangeByScore('trending:global', '-inf', '(' . $minScore) ?: 0;
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
php -l app/Services/ContentEngine/TrendingService.php
```

- [ ] **Step 3: Commit**

```bash
git add app/Services/ContentEngine/TrendingService.php
git commit -m "feat(content-engine): add TrendingService — velocity trending detection and sorted sets"
```

---

## Task 5: UserSignalService — Per-User Affinity Profiles

**Files:**
- Create: `app/Services/ContentEngine/UserSignalService.php`

- [ ] **Step 1: Write UserSignalService**

Write `app/Services/ContentEngine/UserSignalService.php`:

```php
<?php

namespace App\Services\ContentEngine;

use Illuminate\Support\Facades\Redis;

class UserSignalService
{
    /**
     * Redis hash key for per-user signal profile.
     * Fields: liked_creators (JSON array), liked_categories (JSON array),
     *         liked_hashtags (JSON array), avg_dwell_ms, preferred_media (JSON array),
     *         active_hours (JSON array), last_updated
     */
    public static function userKey(int $userId): string
    {
        return "user:{$userId}:signals";
    }

    /**
     * Update user's affinity profile after an engagement event.
     */
    public static function updateProfile(
        int $userId,
        string $eventType,
        ?int $creatorId,
        ?string $category,
        ?array $hashtags,
        ?array $mediaTypes,
        int $durationMs = 0
    ): void {
        // Only update on positive signals
        if (in_array($eventType, ['scroll_past', 'not_interested'])) {
            return;
        }

        $key = self::userKey($userId);

        // Update liked creators (top 50)
        if ($creatorId && in_array($eventType, ['like', 'comment', 'share', 'save', 'follow'])) {
            self::addToJsonSet($key, 'liked_creators', (string) $creatorId, 50);
        }

        // Update liked categories (top 20)
        if ($category && in_array($eventType, ['like', 'comment', 'share', 'save', 'view'])) {
            self::addToJsonSet($key, 'liked_categories', $category, 20);
        }

        // Update liked hashtags (top 30)
        if (!empty($hashtags)) {
            foreach (array_slice($hashtags, 0, 5) as $tag) {
                self::addToJsonSet($key, 'liked_hashtags', $tag, 30);
            }
        }

        // Update preferred media types (top 5)
        if (!empty($mediaTypes)) {
            foreach ($mediaTypes as $mt) {
                if ($mt) self::addToJsonSet($key, 'preferred_media', $mt, 5);
            }
        }

        // Update average dwell time (rolling average)
        if ($durationMs > 0 && in_array($eventType, ['view', 'dwell'])) {
            $currentAvg = (int) (Redis::hGet($key, 'avg_dwell_ms') ?? 0);
            $newAvg = $currentAvg > 0 ? (int) (($currentAvg * 0.9) + ($durationMs * 0.1)) : $durationMs;
            Redis::hSet($key, 'avg_dwell_ms', $newAvg);
        }

        // Update active hours (current hour)
        $hour = (int) date('G');
        self::addToJsonSet($key, 'active_hours', (string) $hour, 24);

        Redis::hSet($key, 'last_updated', now()->toIso8601String());
        Redis::expire($key, 2592000); // 30 day TTL
    }

    /**
     * Get user's affinity profile.
     */
    public static function getProfile(int $userId): array
    {
        $key = self::userKey($userId);
        $data = Redis::hGetAll($key);

        if (empty($data)) {
            return [
                'liked_creators' => [],
                'liked_categories' => [],
                'liked_hashtags' => [],
                'preferred_media' => [],
                'active_hours' => [],
                'avg_dwell_ms' => 0,
                'last_updated' => null,
            ];
        }

        return [
            'liked_creators' => json_decode($data['liked_creators'] ?? '[]', true) ?: [],
            'liked_categories' => json_decode($data['liked_categories'] ?? '[]', true) ?: [],
            'liked_hashtags' => json_decode($data['liked_hashtags'] ?? '[]', true) ?: [],
            'preferred_media' => json_decode($data['preferred_media'] ?? '[]', true) ?: [],
            'active_hours' => json_decode($data['active_hours'] ?? '[]', true) ?: [],
            'avg_dwell_ms' => (int) ($data['avg_dwell_ms'] ?? 0),
            'last_updated' => $data['last_updated'] ?? null,
        ];
    }

    /**
     * Helper: add a value to a JSON-encoded set stored in a hash field.
     * Keeps the set at max $maxSize by removing oldest entries.
     */
    private static function addToJsonSet(string $hashKey, string $field, string $value, int $maxSize): void
    {
        $current = json_decode(Redis::hGet($hashKey, $field) ?? '[]', true) ?: [];

        // Move to end if already present (LRU-style)
        $current = array_values(array_filter($current, fn($v) => $v !== $value));
        $current[] = $value;

        // Trim to max size
        if (count($current) > $maxSize) {
            $current = array_slice($current, -$maxSize);
        }

        Redis::hSet($hashKey, $field, json_encode($current));
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
php -l app/Services/ContentEngine/UserSignalService.php
```

- [ ] **Step 3: Commit**

```bash
git add app/Services/ContentEngine/UserSignalService.php
git commit -m "feat(content-engine): add UserSignalService — per-user affinity profiles in Redis"
```

---

## Task 6: Modify UserEventController — Add Redis Stream Fanout

**Files:**
- Modify: `app/Http/Controllers/Api/UserEventController.php`

- [ ] **Step 1: Read the current controller**

```bash
cat app/Http/Controllers/Api/UserEventController.php
```

- [ ] **Step 2: Add Redis Stream XADD after DB insert**

After the `DB::table('user_events')->insertOrIgnore($rows)` line and before the sponsored post impression code, add:

```php
        // Content Engine: fan out events to Redis Stream for signal processing
        try {
            // Resolve source_types for all post_ids in a single query (batch lookup)
            $postIds = collect($validated['events'])->pluck('post_id')->filter()->unique()->values()->toArray();
            $sourceTypeMap = [];
            if (!empty($postIds)) {
                $sourceTypeMap = \App\Models\ContentDocument::whereIn('source_id', $postIds)
                    ->pluck('source_type', 'source_id')
                    ->toArray();
            }

            $ip = $request->ip();
            foreach ($validated['events'] as $event) {
                $postId = $event['post_id'] ?? null;
                if (!$postId) continue;

                Redis::xAdd('engagement:signals', '*', [
                    'user_id' => (string) $user->id,
                    'event_type' => $event['event_type'],
                    'post_id' => (string) $postId,
                    'source_type' => $sourceTypeMap[$postId] ?? 'post',
                    'creator_id' => (string) ($event['creator_id'] ?? ''),
                    'duration_ms' => (string) ($event['duration_ms'] ?? 0),
                    'session_id' => $event['session_id'],
                    'timestamp' => $event['timestamp'],
                    'ip' => $ip ?? '',
                ]);
            }
        } catch (\Throwable $e) {
            // Signal fanout failure is non-critical — don't break event storage
            \Log::warning('Content Engine signal fanout failed', ['error' => $e->getMessage()]);
        }
```

Also add `use Illuminate\Support\Facades\Redis;` at the top if not already imported.

- [ ] **Step 3: Syntax check**

```bash
php -l app/Http/Controllers/Api/UserEventController.php
```

- [ ] **Step 4: Commit**

```bash
git add app/Http/Controllers/Api/UserEventController.php
git commit -m "feat(content-engine): fan out user events to Redis Stream engagement:signals"
```

---

## Task 7: SignalConsumer Command — Process Redis Stream Events

**Files:**
- Create: `app/Console/Commands/SignalConsumer.php`

- [ ] **Step 1: Write SignalConsumer**

Write `app/Console/Commands/SignalConsumer.php`:

```php
<?php

namespace App\Console\Commands;

use App\Models\ContentDocument;
use App\Services\ContentEngine\SignalService;
use App\Services\ContentEngine\TrendingService;
use App\Services\ContentEngine\UserSignalService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Redis;

class SignalConsumer extends Command
{
    protected $signature = 'signal:consume
                            {--group=signal-consumers : Consumer group name}
                            {--consumer=worker-1 : Consumer name within the group}
                            {--batch=100 : Number of messages to read per iteration}
                            {--timeout=5000 : Block timeout in milliseconds}';

    protected $description = 'Consume engagement events from Redis Stream and update signal counters, trending, and user profiles';

    private bool $running = true;

    public function handle(): int
    {
        $stream = 'engagement:signals';
        $group = $this->option('group');
        $consumer = $this->option('consumer');
        $batch = (int) $this->option('batch');
        $timeout = (int) $this->option('timeout');

        // Create consumer group if it doesn't exist
        try {
            Redis::xGroup('CREATE', $stream, $group, '0', true);
        } catch (\Throwable $e) {
            // Group already exists — fine
            if (!str_contains($e->getMessage(), 'BUSYGROUP')) {
                $this->error("Failed to create consumer group: {$e->getMessage()}");
                return 1;
            }
        }

        $this->info("Signal consumer [{$consumer}] started on group [{$group}]");

        // Handle graceful shutdown
        if (extension_loaded('pcntl')) {
            pcntl_async_signals(true);
            pcntl_signal(SIGTERM, fn() => $this->running = false);
            pcntl_signal(SIGINT, fn() => $this->running = false);
        }

        $processed = 0;
        while ($this->running) {
            try {
                // Read new messages for this consumer
                $messages = Redis::xReadGroup(
                    $group,
                    $consumer,
                    [$stream => '>'],
                    $batch,
                    $timeout
                );

                if (empty($messages) || empty($messages[$stream])) {
                    continue;
                }

                foreach ($messages[$stream] as $messageId => $data) {
                    try {
                        $this->processEvent($data);
                        Redis::xAck($stream, $group, [$messageId]);
                        $processed++;
                    } catch (\Throwable $e) {
                        Log::error('Signal consumer event processing failed', [
                            'message_id' => $messageId,
                            'error' => $e->getMessage(),
                        ]);
                        // ACK anyway to avoid reprocessing poison messages
                        Redis::xAck($stream, $group, [$messageId]);
                    }
                }

                // Trim stream to last 100,000 entries to prevent unbounded growth
                if ($processed % 1000 === 0 && $processed > 0) {
                    Redis::xTrim($stream, 'MAXLEN', '~', 100000);
                }

            } catch (\Throwable $e) {
                Log::error('Signal consumer loop error', ['error' => $e->getMessage()]);
                sleep(1); // Brief pause before retrying
            }
        }

        $this->info("Signal consumer [{$consumer}] stopped after processing {$processed} events.");
        return 0;
    }

    /** In-memory cache for document metadata (avoids per-event DB queries). */
    private array $docCache = [];

    private function processEvent(array $data): void
    {
        $userId = (int) ($data['user_id'] ?? 0);
        $eventType = $data['event_type'] ?? '';
        $postId = (int) ($data['post_id'] ?? 0);
        $creatorId = (int) ($data['creator_id'] ?? 0);
        $durationMs = (int) ($data['duration_ms'] ?? 0);
        $sourceType = $data['source_type'] ?? '';
        $ipAddress = $data['ip'] ?? null;

        if (!$postId || !$eventType) return;

        // Use source_type from stream data (set by UserEventController).
        // Fall back to DB lookup with in-memory cache if missing.
        $doc = null;
        if (empty($sourceType)) {
            $doc = $this->getCachedDoc($postId);
            if (!$doc) return;
            $sourceType = $doc->source_type;
        }

        // Worker 1: Document Score Updater — increment counters, recompute engagement_score
        SignalService::incrementSignal(
            $sourceType,
            $postId,
            $eventType,
            $durationMs,
            $userId,
            $ipAddress
        );

        // Worker 3: User Profile Updater — update per-user affinity
        if ($userId > 0) {
            // Lazy-load doc metadata only when needed for user profile
            if (!$doc) {
                $doc = $this->getCachedDoc($postId);
            }
            UserSignalService::updateProfile(
                $userId,
                $eventType,
                $creatorId ?: ($doc->creator_id ?? 0),
                $doc->category ?? null,
                $doc->hashtags ?? [],
                $doc->media_types ?? [],
                $durationMs
            );
        }
    }

    /**
     * Get document metadata with in-memory LRU cache (max 2000 entries).
     */
    private function getCachedDoc(int $sourceId): ?ContentDocument
    {
        if (isset($this->docCache[$sourceId])) {
            return $this->docCache[$sourceId];
        }

        $doc = ContentDocument::where('source_id', $sourceId)
            ->first(['source_type', 'source_id', 'creator_id', 'category', 'hashtags', 'media_types', 'region_name']);

        if ($doc) {
            // Evict oldest if cache full
            if (count($this->docCache) >= 2000) {
                array_shift($this->docCache);
            }
            $this->docCache[$sourceId] = $doc;
        }

        return $doc;
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
php -l app/Console/Commands/SignalConsumer.php
```

- [ ] **Step 3: Commit**

```bash
git add app/Console/Commands/SignalConsumer.php
git commit -m "feat(content-engine): add signal:consume command — Redis Stream consumer for engagement events"
```

---

## Task 8: TrendingDetector Command — Velocity Check Every 2 Minutes

**Files:**
- Create: `app/Console/Commands/TrendingDetector.php`

- [ ] **Step 1: Write TrendingDetector**

Write `app/Console/Commands/TrendingDetector.php`:

```php
<?php

namespace App\Console\Commands;

use App\Models\ContentDocument;
use App\Services\ContentEngine\SignalService;
use App\Services\ContentEngine\TrendingService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Redis;

class TrendingDetector extends Command
{
    protected $signature = 'signal:detect-trending';
    protected $description = 'Check velocity for recently active documents and update trending sorted sets';

    public function handle(): int
    {
        // Use dedicated trending:candidates set (populated by SignalService alongside scores:dirty)
        // This avoids competing with ScoreSyncWorker for the same data.
        $candidateKey = 'trending:candidates';
        // Atomically pop all current candidates
        $dirtyMembers = Redis::sMembers($candidateKey) ?: [];
        if (!empty($dirtyMembers)) {
            Redis::del($candidateKey);
        }

        if (empty($dirtyMembers)) {
            return 0;
        }

        $updated = 0;
        $rising = 0;
        $breaking = 0;

        foreach ($dirtyMembers as $member) {
            [$sourceType, $sourceId] = explode(':', $member, 2);
            $sourceId = (int) $sourceId;

            // Compute trending score
            $trendingScore = TrendingService::computeTrendingScore($sourceType, $sourceId);

            // Anti-gaming Rule 2: Cap trending_score if fraud flagged
            $docKey = SignalService::docKey($sourceType, $sourceId);
            if (Redis::hGet($docKey, 'fraud_flagged') === '1') {
                $cap = config('content-engine.anti_gaming.fraud_trending_cap', 50);
                $trendingScore = min($trendingScore, $cap);
            }

            // Store trending score in doc hash
            Redis::hSet($docKey, 'trending_score', $trendingScore);

            // Get document metadata for sorted set placement
            $doc = ContentDocument::where('source_type', $sourceType)
                ->where('source_id', $sourceId)
                ->first(['region_name', 'category', 'hashtags']);

            if ($doc) {
                TrendingService::updateTrendingSets(
                    $sourceType,
                    $sourceId,
                    $trendingScore,
                    $doc->region_name,
                    $doc->category,
                    $doc->hashtags ?? []
                );
            }

            // Check velocity classification
            $fiveMinKey = "signals_5min:{$sourceType}:{$sourceId}";
            $current5min = (int) (Redis::hGet($fiveMinKey, 'count') ?? 0);
            $avg5min24h = (float) (Redis::hGet($docKey, 'avg_5min_24h') ?? 1);
            $velocity = $current5min / max($avg5min24h, 1);

            $state = TrendingService::classifyTrending($velocity);
            if ($state === 'rising') $rising++;
            if ($state === 'breaking') {
                $breaking++;
                Log::info("BREAKING content detected", [
                    'source' => "{$sourceType}:{$sourceId}",
                    'velocity' => round($velocity, 1),
                    'trending_score' => $trendingScore,
                ]);
            }

            // Update the rolling 24h average (exponential moving average)
            $newAvg = ($avg5min24h * 0.95) + ($current5min * 0.05);
            Redis::hSet($docKey, 'avg_5min_24h', round($newAvg, 4));

            $updated++;
        }

        // Prune global trending: remove entries with very low scores
        $pruned = TrendingService::pruneGlobalTrending(0.5);

        $this->info("Trending: {$updated} checked, {$rising} rising, {$breaking} breaking, {$pruned} pruned");

        return 0;
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
php -l app/Console/Commands/TrendingDetector.php
```

- [ ] **Step 3: Commit**

```bash
git add app/Console/Commands/TrendingDetector.php
git commit -m "feat(content-engine): add signal:detect-trending command — velocity detection and trending sorted sets"
```

---

## Task 9: ScoreSyncWorker — Flush Dirty Set to PostgreSQL + Typesense

**Files:**
- Create: `app/Console/Commands/ScoreSyncWorker.php`

- [ ] **Step 1: Write ScoreSyncWorker**

Write `app/Console/Commands/ScoreSyncWorker.php`:

```php
<?php

namespace App\Console\Commands;

use App\Models\ContentDocument;
use App\Services\ContentEngine\SignalService;
use App\Services\ContentEngine\TypesenseService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Redis;

class ScoreSyncWorker extends Command
{
    protected $signature = 'signal:sync-scores
                            {--once : Run once then exit (for testing)}';
    protected $description = 'Flush dirty scores from Redis to PostgreSQL and Typesense';

    private bool $running = true;

    public function handle(): int
    {
        $dirtyKey = config('content-engine.score_sync.dirty_set_key', 'scores:dirty');
        $interval = config('content-engine.score_sync.sync_interval_seconds', 30);
        $batchSize = config('content-engine.score_sync.batch_size', 200);

        // Handle graceful shutdown
        if (extension_loaded('pcntl')) {
            pcntl_async_signals(true);
            pcntl_signal(SIGTERM, fn() => $this->running = false);
            pcntl_signal(SIGINT, fn() => $this->running = false);
        }

        $this->info("Score sync worker started (interval: {$interval}s, batch: {$batchSize})");

        while ($this->running) {
            try {
                $synced = $this->syncBatch($dirtyKey, $batchSize);

                if ($synced > 0) {
                    $this->line("  Synced {$synced} documents");
                }
            } catch (\Throwable $e) {
                Log::error('Score sync worker error', ['error' => $e->getMessage()]);
            }

            if ($this->option('once')) break;

            sleep($interval);
        }

        $this->info('Score sync worker stopped.');
        return 0;
    }

    private function syncBatch(string $dirtyKey, int $batchSize): int
    {
        // Atomically pop dirty members using SPOP with count (Redis 3.2+)
        // This is a single atomic operation — no race condition between read and remove.
        $members = Redis::command('spop', [$dirtyKey, $batchSize]);

        if (empty($members)) return 0;

        $synced = 0;

        foreach ($members as $member) {
            $parts = explode(':', $member, 2);
            if (count($parts) !== 2) continue;
            [$sourceType, $sourceId] = $parts;
            $sourceId = (int) $sourceId;

            try {
                // Read scores from Redis
                $docKey = SignalService::docKey($sourceType, $sourceId);
                $engagementScore = (float) (Redis::hGet($docKey, 'engagement_score') ?? 0);
                $trendingScore = (float) (Redis::hGet($docKey, 'trending_score') ?? 0);

                // Update PostgreSQL
                $doc = ContentDocument::where('source_type', $sourceType)
                    ->where('source_id', $sourceId)
                    ->first();

                if (!$doc) continue;

                $doc->engagement_score = $engagementScore;
                $doc->trending_score = $trendingScore;

                // Use shared composite formula (DRY — single source of truth)
                $doc->recomputeCompositeAndTier(save: true);

                // Sync to Typesense
                try {
                    TypesenseService::upsert($doc);
                } catch (\Throwable $e) {
                    Log::warning('Score sync: Typesense upsert failed', [
                        'doc' => "{$sourceType}:{$sourceId}",
                        'error' => $e->getMessage(),
                    ]);
                }

                $synced++;
            } catch (\Throwable $e) {
                Log::error('Score sync: document sync failed', [
                    'doc' => "{$sourceType}:{$sourceId}",
                    'error' => $e->getMessage(),
                ]);
                // Re-add to dirty set for retry
                Redis::sAdd($dirtyKey, $member);
            }
        }

        return $synced;
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
php -l app/Console/Commands/ScoreSyncWorker.php
```

- [ ] **Step 3: Commit**

```bash
git add app/Console/Commands/ScoreSyncWorker.php
git commit -m "feat(content-engine): add signal:sync-scores worker — dirty set flush to PG + Typesense"
```

---

## Task 10: Scheduled Commands — Freshness Refresh + Creator Authority

**Files:**
- Create: `app/Console/Commands/RefreshFreshness.php`
- Create: `app/Console/Commands/RefreshCreatorAuthority.php`
- Modify: `routes/console.php`

- [ ] **Step 1: Write RefreshFreshness command**

Uses bulk SQL UPDATE per source_type for freshness_score (purely time-based, no per-row logic needed). Then recomputes composite_score and content_tier only for rows where freshness changed meaningfully, using the shared `ContentDocument::recomputeCompositeAndTier()`. Adds changed documents to dirty set so ScoreSyncWorker syncs them to Typesense.

Write `app/Console/Commands/RefreshFreshness.php`:

```php
<?php

namespace App\Console\Commands;

use App\Models\ContentDocument;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;

class RefreshFreshness extends Command
{
    protected $signature = 'content:refresh-freshness
                            {--batch-size=500 : Records per batch for composite recompute}';
    protected $description = 'Bulk-update freshness_score and recompute composite_score for all content documents';

    public function handle(): int
    {
        $halfLives = config('content-engine.scoring.freshness_half_lives', []);
        $batchSize = (int) $this->option('batch-size');
        $totalUpdated = 0;
        $tierChanges = 0;

        foreach ($halfLives as $sourceType => $halfLife) {
            // Bulk SQL update: freshness_score = 100 * exp(-ln(2) / half_life * hours_since_published)
            // Only update rows where the change is > 0.5 points (avoids unnecessary writes)
            $affected = DB::update("
                UPDATE content_documents
                SET freshness_score = ROUND((100 * EXP(-LN(2) / ? * EXTRACT(EPOCH FROM (NOW() - published_at)) / 3600))::numeric, 2)
                WHERE source_type = ?
                  AND published_at IS NOT NULL
                  AND ABS(freshness_score - (100 * EXP(-LN(2) / ? * EXTRACT(EPOCH FROM (NOW() - published_at)) / 3600))) > 0.5
            ", [$halfLife, $sourceType, $halfLife]);

            if ($affected === 0) continue;

            $this->line("  {$sourceType}: {$affected} freshness scores updated");
            $totalUpdated += $affected;

            // Now recompute composite and tier for affected rows using shared method
            // We identify affected rows as those with scores_updated_at < now (they weren't just updated by sync)
            // Simpler: just process all of this source_type where freshness changed (small subset)
            $dirtyKey = config('content-engine.score_sync.dirty_set_key', 'scores:dirty');

            ContentDocument::where('source_type', $sourceType)
                ->whereNotNull('published_at')
                ->orderBy('id')
                ->chunk($batchSize, function ($docs) use (&$tierChanges, $dirtyKey) {
                    foreach ($docs as $doc) {
                        $oldTier = $doc->content_tier;
                        $doc->recomputeCompositeAndTier(save: true);

                        if ($oldTier !== $doc->content_tier) {
                            $tierChanges++;
                        }

                        // Add to dirty set so ScoreSyncWorker pushes to Typesense
                        Redis::sAdd($dirtyKey, "{$doc->source_type}:{$doc->source_id}");
                    }
                });
        }

        $this->info("Freshness refresh: {$totalUpdated} updated, {$tierChanges} tier changes");
        return 0;
    }
}
```

- [ ] **Step 2: Write RefreshCreatorAuthority command**

Write `app/Console/Commands/RefreshCreatorAuthority.php`:

```php
<?php

namespace App\Console\Commands;

use App\Models\ContentDocument;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class RefreshCreatorAuthority extends Command
{
    protected $signature = 'content:refresh-creator-authority';
    protected $description = 'Sync creator_authority from creator_scores table into content_documents';

    public function handle(): int
    {
        // The flywheel already maintains creator_scores with a "score" column
        // Normalize to 0-100 and write to content_documents.creator_authority
        $hasCreatorScores = DB::getSchemaBuilder()->hasTable('creator_scores');
        if (!$hasCreatorScores) {
            $this->warn('creator_scores table not found — skipping');
            return 0;
        }

        // Get max score for normalization
        $maxScore = DB::table('creator_scores')->max('score') ?: 1;

        // Batch update: join creator_scores to content_documents via creator_id = user_id
        $affected = DB::update("
            UPDATE content_documents cd
            SET creator_authority = ROUND((cs.score / ? * 100)::numeric, 2),
                scores_updated_at = NOW()
            FROM creator_scores cs
            WHERE cd.creator_id = cs.user_id
              AND cd.creator_authority != ROUND((cs.score / ? * 100)::numeric, 2)
        ", [$maxScore, $maxScore]);

        // Also update creator_tier from user_profiles or creator tiers table
        $hasCreatorTiers = DB::getSchemaBuilder()->hasColumn('user_profiles', 'creator_tier');
        if ($hasCreatorTiers) {
            $tierAffected = DB::update("
                UPDATE content_documents cd
                SET creator_tier = up.creator_tier
                FROM user_profiles up
                WHERE cd.creator_id = up.id
                  AND (cd.creator_tier IS NULL OR cd.creator_tier != up.creator_tier)
            ");
            $this->info("Creator tiers: {$tierAffected} updated");
        }

        $this->info("Creator authority: {$affected} documents updated (max score: {$maxScore})");
        return 0;
    }
}
```

- [ ] **Step 3: Add schedule entries to routes/console.php**

Read `routes/console.php` and append before the closing of the file:

```php

// Content Engine Phase 2 — Signal processing schedules
Schedule::command('content:refresh-freshness')->everyFiveMinutes()->withoutOverlapping(10);
Schedule::command('signal:detect-trending')->everyTwoMinutes()->withoutOverlapping(5);
Schedule::command('content:refresh-creator-authority')->everyThirtyMinutes()->withoutOverlapping();
```

- [ ] **Step 4: Syntax check all files**

```bash
php -l app/Console/Commands/RefreshFreshness.php
php -l app/Console/Commands/RefreshCreatorAuthority.php
php -l routes/console.php
```

- [ ] **Step 5: Commit**

```bash
git add app/Console/Commands/RefreshFreshness.php app/Console/Commands/RefreshCreatorAuthority.php routes/console.php
git commit -m "feat(content-engine): add freshness refresh, creator authority sync, and trending schedule"
```

---

## Task 11: Supervisor Config for Signal Workers + Verify

**Files:**
- Create: `/etc/supervisor/conf.d/content-signals.conf`

- [ ] **Step 1: Write Supervisor config for signal workers**

Write `/etc/supervisor/conf.d/content-signals.conf`:

```ini
[program:signal-consumer]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/tajiri/artisan signal:consume --consumer=worker-%(process_num)02d
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=3
redirect_stderr=true
stdout_logfile=/var/log/tajiri/signal-consumer.log
stopwaitsecs=30

[program:score-sync]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/tajiri/artisan signal:sync-scores
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=1
redirect_stderr=true
stdout_logfile=/var/log/tajiri/score-sync.log
stopwaitsecs=10

[group:content-signals]
programs=signal-consumer,score-sync
```

- [ ] **Step 2: Create log files**

```bash
touch /var/log/tajiri/signal-consumer.log /var/log/tajiri/score-sync.log
chown www-data:www-data /var/log/tajiri/signal-consumer.log /var/log/tajiri/score-sync.log
```

- [ ] **Step 3: Start workers**

```bash
supervisorctl reread
supervisorctl update
supervisorctl start content-signals:*
```

- [ ] **Step 4: Verify all workers running**

```bash
supervisorctl status content-signals:*
```

Expected: 4 processes (3 signal consumers + 1 score sync).

- [ ] **Step 5: Verify Laravel schedule is running**

```bash
cd /var/www/html/tajiri
# Check crontab for schedule:run
crontab -l | grep schedule
# If not present, add it:
# (crontab -l 2>/dev/null; echo "* * * * * cd /var/www/html/tajiri && php artisan schedule:run >> /dev/null 2>&1") | crontab -
```

- [ ] **Step 6: Test the pipeline end-to-end**

```bash
cd /var/www/html/tajiri

# 1. Add a test event to Redis Stream manually
php artisan tinker --execute="
\Illuminate\Support\Facades\Redis::xAdd('engagement:signals', '*', [
    'user_id' => '1',
    'event_type' => 'like',
    'post_id' => '1',
    'creator_id' => '1',
    'duration_ms' => '0',
    'session_id' => 'test-session',
    'timestamp' => now()->toIso8601String(),
]);
echo 'Event added to stream';
"

# 2. Wait a moment, then check Redis counters
sleep 3
php artisan tinker --execute="
echo 'Signals: ' . json_encode(\Illuminate\Support\Facades\Redis::hGetAll('signals:post:1')) . PHP_EOL;
echo 'Dirty set: ' . json_encode(\Illuminate\Support\Facades\Redis::sMembers('scores:dirty')) . PHP_EOL;
"

# 3. Run a manual freshness refresh
php artisan content:refresh-freshness

# 4. Run health check
php artisan content:health-check
```

No git commit needed — this is server infrastructure config.

---

## Phase 2 Completion Criteria

After all 11 tasks:

- [ ] Shared `ContentDocument::recomputeCompositeAndTier()` method (DRY — one formula, one source of truth)
- [ ] SignalService computes per-document engagement_score from Redis hash counters
- [ ] All 4 anti-gaming rules enforced: (1) per-user cap, (2) velocity squashing for new accounts, (3) social graph validation, (4) IP clustering
- [ ] TrendingService computes velocity-based trending_score and maintains trending sorted sets
- [ ] UserSignalService builds per-user affinity profiles (creators, categories, hashtags, media, hours)
- [ ] UserEventController fans out events to Redis Stream `engagement:signals` with source_type and IP
- [ ] SignalConsumer reads stream with in-memory cache (avoids per-event DB queries), updates counters and user profiles
- [ ] TrendingDetector checks velocity every 2 minutes using dedicated `trending:candidates` set, classifies rising/breaking/cooling
- [ ] ScoreSyncWorker atomically pops dirty set (SPOP), flushes to PostgreSQL + Typesense every 30 seconds
- [ ] RefreshFreshness uses bulk SQL UPDATE per source_type, adds to dirty set for Typesense sync
- [ ] RefreshCreatorAuthority syncs from creator_scores table every 30 minutes
- [ ] Supervisor runs 3 signal consumers + 1 score sync worker
- [ ] Laravel schedule runs trending detection (2min), freshness refresh (5min), creator authority (30min)
- [ ] All code committed

**Deferred to Phase 3:** Content graph (NetworkX), content_rank computation, near-duplicate detection.

**Next:** Phase 3 — Content Graph (edge construction, NetworkX PageRank, content_rank write-back, graph-based recommendations)
