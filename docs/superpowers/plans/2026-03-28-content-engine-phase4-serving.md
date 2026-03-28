# Content Engine Phase 4: Serving Pipeline — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the serving pipeline that generates personalized feeds and search results — candidate generation from multiple sources, personalized scoring, re-ranking with diversity/freshness/exploration twiddlers, caching, and API endpoints (`/api/v2/feed`, `/api/v2/search`).

**Architecture:** A `ServingPipelineService` orchestrates the 7-step pipeline: query understanding → candidate generation (fan-out to Typesense, pgvector, Redis, PostgreSQL) → merge/dedup/privacy → personalized scoring → re-ranking twiddlers → pagination/hydration → Redis caching. Two controllers expose this: `FeedController` (v2) and `SearchController` (v2). Feature flags gate rollout per feed type.

**Tech Stack:** Laravel 12, PHP 8.3, PostgreSQL + pgvector, Typesense, Redis, existing ContentEngine infrastructure from Phases 0-3

**Server access:** `sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@zima-uat.site`

**Spec reference:** `docs/superpowers/specs/2026-03-28-tajiri-content-engine-design.md` — Section 7 (Serving Pipeline), Section 9 (Frontend)

**Depends on:** Phase 0-3 complete. Key existing infrastructure:
- `content_documents` table with composite_score, content_tier, content_rank, creator_authority, trending_score, engagement_score, freshness_score, embedding (768-dim pgvector)
- `TypesenseService` for full-text search
- `SignalService` for engagement signals
- `TrendingService` for trending sorted sets in Redis
- `UserSignalService` for per-user affinity profiles (creator, category, hashtag, media preferences) in Redis hashes
- `ScoringConfig` for weight configuration
- Feature flags in `feature_flags` table (Phase 0)
- `friendships` table (NOT `friends`)
- `blocked_users` table for privacy filtering
- Redis key prefix: `laravel-database-` (auto-applied by Laravel)

---

## File Map

### Backend (on server: /var/www/html/tajiri/)

| Action | File | Purpose |
|---|---|---|
| Create | `app/Services/ContentEngine/CandidateGeneratorService.php` | Fan-out candidate generation from 5 sources |
| Create | `app/Services/ContentEngine/PersonalizedScorerService.php` | Per-user scoring (affinity, social proximity, regional) |
| Create | `app/Services/ContentEngine/ReRankerService.php` | Diversity, freshness, exploration, anti-bubble twiddlers |
| Create | `app/Services/ContentEngine/ServingPipelineService.php` | Orchestrates full 7-step pipeline |
| Create | `app/Services/ContentEngine/FeedCacheService.php` | Redis feed/search caching with TTL |
| Create | `app/Http/Controllers/Api/V2/FeedController.php` | `GET /api/v2/feed` endpoint |
| Create | `app/Http/Controllers/Api/V2/SearchController.php` | `GET /api/v2/search` endpoint |
| Create | `app/Traits/ChecksFeatureFlags.php` | Shared feature flag checking trait (used by both controllers) |
| Modify | `routes/api.php` | Add v2 routes |
| Modify | `config/content-engine.php` | Add serving config (candidate limits, scoring weights, reranker rules) |

---

## Task 1: Serving Config — Add Pipeline Configuration

**Files:**
- Modify: `config/content-engine.php`

- [ ] **Step 1: Read current config**

Read `config/content-engine.php` to see existing structure.

- [ ] **Step 2: Add serving pipeline config**

Append to the config array:

```php
    // ============================================================
    // Serving Pipeline (Phase 4)
    // ============================================================

    'serving' => [
        'candidate_limits' => [
            'typesense' => 200,
            'pgvector' => 100,
            'trending' => 50,
            'personal' => 100,
            'social' => 100,
        ],

        // Feed type → which sources to use and their limits
        'feed_sources' => [
            'for_you' => [
                'pgvector' => 100, 'trending' => 50, 'personal' => 100, 'social' => 50,
            ],
            'friends' => [
                'social' => 500,
            ],
            'discover' => [
                'pgvector' => 100, 'trending' => 100,
            ],
            'trending' => [
                'trending' => 200,
            ],
            'nearby' => [
                'trending' => 100, 'social' => 50,
            ],
            'shorts' => [
                'typesense' => 100, 'trending' => 50, 'personal' => 50,
            ],
            'audio' => [
                'typesense' => 100, 'trending' => 50, 'personal' => 50,
            ],
            'search' => [
                'typesense' => 200, 'pgvector' => 100, 'trending' => 30,
            ],
        ],

        'personalized_scoring' => [
            'creator_affinity_max' => 15,
            'category_affinity_max' => 10,
            'hashtag_affinity_max' => 8,
            'media_preference_max' => 5,
            'social_proximity_friend' => 20,
            'social_proximity_fof' => 8,
            'regional_same_region' => 5,
            'regional_same_district' => 3,
        ],

        'reranker' => [
            'max_consecutive_same_creator' => 2,
            'max_consecutive_same_type' => 4,
            'freshness_1h_boost' => 1.2,
            'freshness_15min_boost' => 1.4,
            'exploration_pct' => 0.10,
            'exploration_pct_new_user' => 0.30,
            'new_user_days' => 7,
            // Anti-bubble overlaps with exploration — the exploration pool already covers
            // "unseen creators/categories" which is effectively anti-bubble. Both are served
            // via the exploration slot mechanism. Keeping the config for tuning.
            'anti_bubble_pct' => 0.05,
            'streak_bonus' => 1.1,
            // Sponsored insertion deferred to Phase 5 (requires SponsoredPostService)
            // 'sponsored_positions' => [4, 12, 24],
        ],

        'cache' => [
            'feed_ttl' => 60,
            'search_ttl' => 300,
            'trending_ttl' => 120,
        ],

        'per_page_default' => 20,
        'per_page_max' => 50,
    ],
```

- [ ] **Step 3: Syntax check**

```bash
php -l config/content-engine.php
```

- [ ] **Step 4: Commit**

```bash
git add config/content-engine.php
git commit -m "feat(content-engine): add serving pipeline config — candidate limits, scoring weights, reranker rules, cache TTLs"
```

---

## Task 2: CandidateGeneratorService — Fan-Out Candidate Collection

**Files:**
- Create: `app/Services/ContentEngine/CandidateGeneratorService.php`

- [ ] **Step 1: Write CandidateGeneratorService**

```php
<?php

namespace App\Services\ContentEngine;

use App\Models\ContentDocument;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Redis;

class CandidateGeneratorService
{
    /**
     * Generate candidates for a feed request.
     * Fan-out to multiple sources based on feed type config.
     *
     * @return array<int, ContentDocument> keyed by doc ID
     */
    public static function generate(string $feedType, int $userId, array $options = []): array
    {
        $sources = config("content-engine.serving.feed_sources.{$feedType}", []);
        $candidates = [];

        foreach ($sources as $source => $limit) {
            try {
                $docs = match ($source) {
                    'typesense' => self::fromTypesense($feedType, $userId, $limit, $options),
                    'pgvector' => self::fromPgvector($userId, $limit, $options),
                    'trending' => self::fromTrending($userId, $limit, $options),
                    'personal' => self::fromPersonal($userId, $limit),
                    'social' => self::fromSocial($userId, $limit),
                    default => [],
                };
                foreach ($docs as $doc) {
                    $candidates[$doc->id] = $doc;
                }
            } catch (\Throwable $e) {
                Log::warning("CandidateGenerator: source {$source} failed", [
                    'feed_type' => $feedType,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        return $candidates;
    }

    /**
     * Generate candidates for a search request.
     */
    public static function generateForSearch(string $query, int $userId, array $filters = []): array
    {
        $limits = config('content-engine.serving.feed_sources.search', []);
        $candidates = [];

        // Typesense keyword search
        if ($limit = $limits['typesense'] ?? 200) {
            try {
                $ids = TypesenseService::searchIds($query, $limit, $filters);
                if (!empty($ids)) {
                    $docs = ContentDocument::whereIn('id', $ids)->get()->keyBy('id');
                    foreach ($docs as $doc) {
                        $candidates[$doc->id] = $doc;
                    }
                }
            } catch (\Throwable $e) {
                Log::warning("CandidateGenerator: typesense search failed", ['error' => $e->getMessage()]);
            }
        }

        // pgvector semantic search (if query has embedding)
        if ($limit = $limits['pgvector'] ?? 100) {
            try {
                $semanticDocs = self::semanticSearch($query, $limit);
                foreach ($semanticDocs as $doc) {
                    $candidates[$doc->id] = $doc;
                }
            } catch (\Throwable $e) {
                Log::warning("CandidateGenerator: semantic search failed", ['error' => $e->getMessage()]);
            }
        }

        // Trending boost
        if ($limit = $limits['trending'] ?? 30) {
            try {
                $trendingDocs = self::fromTrending($userId, $limit, []);
                foreach ($trendingDocs as $doc) {
                    $candidates[$doc->id] = $doc;
                }
            } catch (\Throwable $e) {
                Log::warning("CandidateGenerator: trending for search failed", ['error' => $e->getMessage()]);
            }
        }

        return $candidates;
    }

    /**
     * Typesense keyword candidates.
     */
    private static function fromTypesense(string $feedType, int $userId, int $limit, array $options): array
    {
        $filters = [];

        // Feed-type-specific filters
        if ($feedType === 'shorts') {
            $filters['source_type'] = 'clip';
        } elseif ($feedType === 'audio') {
            $filters['source_type'] = 'music';
        }

        $query = $options['query'] ?? '*';
        $ids = TypesenseService::searchIds($query, $limit, $filters);

        if (empty($ids)) return [];

        return ContentDocument::whereIn('id', $ids)
            ->where('content_tier', '!=', 'blackhole')
            ->get()
            ->all();
    }

    /**
     * pgvector semantic similarity candidates.
     * Uses the user's recent engagement to find similar content.
     */
    private static function fromPgvector(int $userId, int $limit, array $options): array
    {
        // Get user's most recently engaged document as the seed
        $seedDocId = self::getUserSeedDocument($userId);
        if (!$seedDocId) {
            // Fallback: use highest-ranked recent content
            return ContentDocument::where('content_tier', '!=', 'blackhole')
                ->whereNotNull('embedding')
                ->where('published_at', '>=', now()->subDays(7))
                ->orderByDesc('composite_score')
                ->limit($limit)
                ->get()
                ->all();
        }

        // Find similar via pgvector
        $results = DB::select("
            WITH ref AS (SELECT embedding FROM content_documents WHERE id = ?)
            SELECT id FROM content_documents
            WHERE id != ?
              AND embedding IS NOT NULL
              AND content_tier != 'blackhole'
              AND published_at >= NOW() - INTERVAL '14 days'
            ORDER BY embedding <=> (SELECT embedding FROM ref) ASC
            LIMIT ?
        ", [$seedDocId, $seedDocId, $limit]);

        if (empty($results)) return [];

        $ids = array_map(fn($r) => $r->id, $results);
        return ContentDocument::whereIn('id', $ids)->get()->all();
    }

    /**
     * Redis trending candidates.
     */
    private static function fromTrending(int $userId, int $limit, array $options): array
    {
        $region = $options['region'] ?? null;
        $key = $region ? "trending:region:{$region}" : 'trending:global';

        $docIds = Redis::zrevrange($key, 0, $limit - 1);
        if (empty($docIds)) return [];

        // Redis returns string IDs
        $docIds = array_map('intval', $docIds);

        return ContentDocument::whereIn('id', $docIds)
            ->where('content_tier', '!=', 'blackhole')
            ->get()
            ->all();
    }

    /**
     * Personalized candidates from user's affinity profile.
     */
    private static function fromPersonal(int $userId, int $limit): array
    {
        // Get user's top creators and categories from UserSignalService
        $creatorIds = UserSignalService::getTopCreators($userId, 10);
        $categories = UserSignalService::getTopCategories($userId, 5);

        if (empty($creatorIds) && empty($categories)) return [];

        $query = ContentDocument::where('content_tier', '!=', 'blackhole')
            ->where('published_at', '>=', now()->subDays(7));

        if (!empty($creatorIds) && !empty($categories)) {
            $query->where(function ($q) use ($creatorIds, $categories) {
                $q->whereIn('creator_id', $creatorIds)
                  ->orWhereIn('category', $categories);
            });
        } elseif (!empty($creatorIds)) {
            $query->whereIn('creator_id', $creatorIds);
        } else {
            $query->whereIn('category', $categories);
        }

        return $query->orderByDesc('composite_score')
            ->limit($limit)
            ->get()
            ->all();
    }

    /**
     * Social graph candidates (friends' content).
     */
    private static function fromSocial(int $userId, int $limit): array
    {
        // Get friend IDs from friendships table
        $friendIds = DB::table('friendships')
            ->where(function ($q) use ($userId) {
                $q->where('user_id', $userId)->orWhere('friend_id', $userId);
            })
            ->where('status', 'accepted')
            ->get()
            ->map(fn($f) => $f->user_id == $userId ? $f->friend_id : $f->user_id)
            ->unique()
            ->values()
            ->all();

        if (empty($friendIds)) return [];

        return ContentDocument::whereIn('creator_id', $friendIds)
            ->where('content_tier', '!=', 'blackhole')
            ->where('published_at', '>=', now()->subDays(14))
            ->orderByDesc('composite_score')
            ->limit($limit)
            ->get()
            ->all();
    }

    /**
     * Semantic search: embed query text, then find similar documents.
     */
    private static function semanticSearch(string $query, int $limit): array
    {
        // Call embedding service to get query vector
        try {
            $response = Http::timeout(5)
                ->post(config('content-engine.embedding_service_url', 'http://127.0.0.1:8200') . '/embed', [
                    'text' => $query,
                ]);

            if (!$response->ok()) return [];

            $embedding = $response->json('embedding');
            if (!$embedding) return [];

            $vectorStr = '[' . implode(',', $embedding) . ']';

            $results = DB::select("
                SELECT id FROM content_documents
                WHERE embedding IS NOT NULL
                  AND content_tier != 'blackhole'
                ORDER BY embedding <=> ?::vector ASC
                LIMIT ?
            ", [$vectorStr, $limit]);

            if (empty($results)) return [];

            $ids = array_map(fn($r) => $r->id, $results);
            return ContentDocument::whereIn('id', $ids)->get()->all();
        } catch (\Throwable $e) {
            Log::warning("CandidateGenerator: semantic search embedding failed", ['error' => $e->getMessage()]);
            return [];
        }
    }

    /**
     * Get a seed document ID based on user's recent engagement.
     */
    private static function getUserSeedDocument(int $userId): ?int
    {
        // Get user's most recent liked/viewed content
        $event = DB::table('user_events')
            ->where('user_id', $userId)
            ->whereIn('event_type', ['like', 'view', 'share'])
            ->orderByDesc('created_at')
            ->first();

        if (!$event) return null;

        return ContentDocument::where('source_type', $event->source_type ?? 'post')
            ->where('source_id', $event->source_id ?? $event->post_id)
            ->value('id');
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
php -l app/Services/ContentEngine/CandidateGeneratorService.php
```

- [ ] **Step 3: Commit**

```bash
git add app/Services/ContentEngine/CandidateGeneratorService.php
git commit -m "feat(content-engine): add CandidateGeneratorService — fan-out candidate generation from 5 sources"
```

---

## Task 3: PersonalizedScorerService — Per-User Scoring

**Files:**
- Create: `app/Services/ContentEngine/PersonalizedScorerService.php`

- [ ] **Step 1: Write PersonalizedScorerService**

```php
<?php

namespace App\Services\ContentEngine;

use App\Models\ContentDocument;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;

class PersonalizedScorerService
{
    /**
     * Score an array of candidates for a specific user.
     * Adds personalized_score to each document.
     *
     * @param array<int, ContentDocument> $candidates keyed by doc ID
     * @return array<int, array{doc: ContentDocument, score: float}>
     */
    public static function score(array $candidates, int $userId): array
    {
        if (empty($candidates)) return [];

        $config = config('content-engine.serving.personalized_scoring');

        // Load user signals
        $topCreators = UserSignalService::getTopCreators($userId, 50);
        $topCategories = UserSignalService::getTopCategories($userId, 20);
        $topHashtags = UserSignalService::getTopHashtags($userId, 30);
        $mediaPrefs = UserSignalService::getMediaPreferences($userId);
        $friendIds = self::getFriendIds($userId);
        $fofIds = self::getFriendOfFriendIds($userId, $friendIds);
        $userRegion = self::getUserRegion($userId);

        $scored = [];

        foreach ($candidates as $docId => $doc) {
            $base = $doc->composite_score ?? 0;

            // Creator affinity
            $creatorBoost = 0;
            if ($doc->creator_id && in_array($doc->creator_id, $topCreators)) {
                $rank = array_search($doc->creator_id, $topCreators);
                $creatorBoost = $config['creator_affinity_max'] * (1 - ($rank / max(count($topCreators), 1)));
            }

            // Category affinity
            $categoryBoost = 0;
            if ($doc->category && in_array($doc->category, $topCategories)) {
                $rank = array_search($doc->category, $topCategories);
                $categoryBoost = $config['category_affinity_max'] * (1 - ($rank / max(count($topCategories), 1)));
            }

            // Hashtag affinity
            $hashtagBoost = 0;
            $docHashtags = is_array($doc->hashtags) ? $doc->hashtags : [];
            if (!empty($docHashtags) && !empty($topHashtags)) {
                $overlap = count(array_intersect($docHashtags, $topHashtags));
                $hashtagBoost = min($config['hashtag_affinity_max'], $overlap * 2);
            }

            // Media preference
            $mediaBoost = 0;
            $docMediaTypes = is_array($doc->media_types) ? $doc->media_types : [];
            if (!empty($docMediaTypes) && !empty($mediaPrefs)) {
                foreach ($docMediaTypes as $mt) {
                    if (in_array($mt, $mediaPrefs)) {
                        $mediaBoost = $config['media_preference_max'];
                        break;
                    }
                }
            }

            // Social proximity
            $socialBoost = 0;
            if ($doc->creator_id) {
                if (in_array($doc->creator_id, $friendIds)) {
                    $socialBoost = $config['social_proximity_friend'];
                } elseif (in_array($doc->creator_id, $fofIds)) {
                    $socialBoost = $config['social_proximity_fof'];
                }
            }

            // Regional proximity
            $regionalBoost = 0;
            if ($userRegion && $doc->region_name) {
                if ($doc->region_name === $userRegion['region']) {
                    $regionalBoost = $config['regional_same_region'];
                }
                if (isset($userRegion['district']) && $doc->district_name === $userRegion['district']) {
                    $regionalBoost += $config['regional_same_district'];
                }
            }

            $personalizedScore = $base + $creatorBoost + $categoryBoost + $hashtagBoost
                               + $mediaBoost + $socialBoost + $regionalBoost;

            $scored[$docId] = [
                'doc' => $doc,
                'score' => round($personalizedScore, 2),
                'boosts' => [
                    'base' => $base,
                    'creator' => round($creatorBoost, 1),
                    'category' => round($categoryBoost, 1),
                    'hashtag' => round($hashtagBoost, 1),
                    'media' => round($mediaBoost, 1),
                    'social' => round($socialBoost, 1),
                    'regional' => round($regionalBoost, 1),
                ],
            ];
        }

        // Sort by personalized score descending
        uasort($scored, fn($a, $b) => $b['score'] <=> $a['score']);

        return $scored;
    }

    private static function getFriendIds(int $userId): array
    {
        return DB::table('friendships')
            ->where(function ($q) use ($userId) {
                $q->where('user_id', $userId)->orWhere('friend_id', $userId);
            })
            ->where('status', 'accepted')
            ->get()
            ->map(fn($f) => $f->user_id == $userId ? $f->friend_id : $f->user_id)
            ->unique()
            ->values()
            ->all();
    }

    private static function getFriendOfFriendIds(int $userId, array $friendIds): array
    {
        if (empty($friendIds)) return [];

        return DB::table('friendships')
            ->where(function ($q) use ($friendIds) {
                $q->whereIn('user_id', $friendIds)->orWhereIn('friend_id', $friendIds);
            })
            ->where('status', 'accepted')
            ->get()
            ->map(fn($f) => in_array($f->user_id, $friendIds) ? $f->friend_id : $f->user_id)
            ->unique()
            ->reject(fn($id) => $id == $userId || in_array($id, $friendIds))
            ->values()
            ->take(200)
            ->all();
    }

    private static function getUserRegion(int $userId): ?array
    {
        $profile = DB::table('user_profiles')->where('user_id', $userId)->first(['region', 'district']);
        if (!$profile) return null;
        return ['region' => $profile->region, 'district' => $profile->district ?? null];
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
php -l app/Services/ContentEngine/PersonalizedScorerService.php
```

- [ ] **Step 3: Commit**

```bash
git add app/Services/ContentEngine/PersonalizedScorerService.php
git commit -m "feat(content-engine): add PersonalizedScorerService — per-user scoring with affinity, social, and regional boosts"
```

---

## Task 4: ReRankerService — Diversity, Freshness, Exploration Twiddlers

**Files:**
- Create: `app/Services/ContentEngine/ReRankerService.php`

- [ ] **Step 1: Write ReRankerService**

```php
<?php

namespace App\Services\ContentEngine;

use App\Models\ContentDocument;

class ReRankerService
{
    /**
     * Re-rank scored candidates applying twiddlers.
     *
     * @param array<int, array{doc: ContentDocument, score: float, boosts: array}> $scored
     * @return array<int, array{doc: ContentDocument, score: float, boosts: array, context: array}>
     */
    public static function rerank(array $scored, int $userId, string $feedType): array
    {
        $config = config('content-engine.serving.reranker');
        $isNewUser = self::isNewUser($userId, $config['new_user_days']);
        $explorationPct = $isNewUser ? $config['exploration_pct_new_user'] : $config['exploration_pct'];

        // Apply freshness boost to scores
        $scored = self::applyFreshnessBoost($scored, $config);

        // Apply streak bonus
        $scored = self::applyStreakBonus($scored, $config);

        // Re-sort after score modifications
        uasort($scored, fn($a, $b) => $b['score'] <=> $a['score']);

        // Apply diversity rules and build final list
        $result = [];
        $deferred = [];
        $creatorCount = [];
        $typeCount = [];
        $consecutiveCreator = null;
        $consecutiveCreatorRun = 0;
        $consecutiveType = null;
        $consecutiveTypeRun = 0;
        $explorationSlots = [];
        $normalSlots = [];

        // Separate exploration candidates
        // NOTE: Anti-bubble ("outside interest profile") overlaps with exploration ("unseen creators/categories").
        // The current exploration implementation covers both use cases — items from unknown creators AND
        // unknown categories are all placed in the exploration pool. No separate anti-bubble pass needed.
        $userCreators = UserSignalService::getTopCreators($userId, 50);
        $userCategories = UserSignalService::getTopCategories($userId, 20);

        foreach ($scored as $docId => $item) {
            $doc = $item['doc'];
            $isExploration = !in_array($doc->creator_id, $userCreators)
                          && !in_array($doc->category, $userCategories);

            if ($isExploration) {
                $item['context'] = ['reason' => 'exploration', 'is_exploration' => true, 'is_sponsored' => false];
                $explorationSlots[$docId] = $item;
            } else {
                $item['context'] = ['reason' => self::classifyReason($item, $feedType), 'is_exploration' => false, 'is_sponsored' => false];
                $normalSlots[$docId] = $item;
            }
        }

        // Build final list with diversity enforcement
        $totalSlots = count($scored);
        $explorationTarget = (int) ceil($totalSlots * $explorationPct);

        $explorationInserted = 0;
        $normalIterator = new \ArrayIterator($normalSlots);
        $explorationIterator = new \ArrayIterator($explorationSlots);
        $position = 0;

        while ($position < $totalSlots && ($normalIterator->valid() || $explorationIterator->valid())) {
            $position++;

            // Insert exploration at every 1/explorationPct interval
            if ($explorationInserted < $explorationTarget && $explorationIterator->valid()
                && ($position % max(1, (int)(1 / $explorationPct)) === 0)) {
                $item = $explorationIterator->current();
                $explorationIterator->next();
                $explorationInserted++;
            } elseif ($normalIterator->valid()) {
                $item = $normalIterator->current();
                $normalIterator->next();
            } elseif ($explorationIterator->valid()) {
                $item = $explorationIterator->current();
                $explorationIterator->next();
            } else {
                break;
            }

            $doc = $item['doc'];

            // Diversity: defer if too many consecutive same creator
            if ($doc->creator_id === $consecutiveCreator) {
                $consecutiveCreatorRun++;
                if ($consecutiveCreatorRun > $config['max_consecutive_same_creator']) {
                    $deferred[] = $item;
                    continue;
                }
            } else {
                $consecutiveCreator = $doc->creator_id;
                $consecutiveCreatorRun = 1;
            }

            // Diversity: defer if too many consecutive same type
            if ($doc->source_type === $consecutiveType) {
                $consecutiveTypeRun++;
                if ($consecutiveTypeRun > $config['max_consecutive_same_type']) {
                    $deferred[] = $item;
                    continue;
                }
            } else {
                $consecutiveType = $doc->source_type;
                $consecutiveTypeRun = 1;
            }

            $result[] = $item;
        }

        // Re-insert deferred items at the end (diversity-violated items still appear, just later)
        foreach ($deferred as $item) {
            $result[] = $item;
        }

        return $result;
    }

    private static function applyFreshnessBoost(array $scored, array $config): array
    {
        $now = now();
        foreach ($scored as $docId => &$item) {
            $publishedAt = $item['doc']->published_at;
            if (!$publishedAt) continue;

            $minutesAgo = $now->diffInMinutes($publishedAt);
            if ($minutesAgo < 15) {
                $item['score'] *= $config['freshness_15min_boost'];
            } elseif ($minutesAgo < 60) {
                $item['score'] *= $config['freshness_1h_boost'];
            }
        }
        return $scored;
    }

    private static function applyStreakBonus(array $scored, array $config): array
    {
        // Collect unique creator IDs to batch check streaks
        $creatorIds = array_unique(array_filter(
            array_map(fn($item) => $item['doc']->creator_id, $scored)
        ));

        if (empty($creatorIds)) return $scored;

        // Check creator_scores for active streaks
        $streakCreators = \Illuminate\Support\Facades\DB::table('creator_scores')
            ->whereIn('user_id', $creatorIds)
            ->where('current_streak_days', '>=', 3)
            ->pluck('user_id')
            ->all();

        if (empty($streakCreators)) return $scored;

        foreach ($scored as $docId => &$item) {
            if (in_array($item['doc']->creator_id, $streakCreators)) {
                $item['score'] *= $config['streak_bonus'];
            }
        }

        return $scored;
    }

    private static function isNewUser(int $userId, int $days): bool
    {
        $user = \Illuminate\Support\Facades\DB::table('users')
            ->where('id', $userId)
            ->value('created_at');

        return $user && now()->diffInDays($user) <= $days;
    }

    private static function classifyReason(array $item, string $feedType): string
    {
        $boosts = $item['boosts'] ?? [];

        if ($feedType === 'trending') return 'trending';
        if ($feedType === 'friends') return 'friend_activity';
        if (($boosts['social'] ?? 0) >= 15) return 'friend_activity';
        if (($boosts['creator'] ?? 0) >= 10) return 'favorite_creator';
        if (($boosts['category'] ?? 0) >= 7) return 'interest_match';
        if (($item['doc']->trending_score ?? 0) > 50) return 'trending_in_region';

        return 'recommended';
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
php -l app/Services/ContentEngine/ReRankerService.php
```

- [ ] **Step 3: Commit**

```bash
git add app/Services/ContentEngine/ReRankerService.php
git commit -m "feat(content-engine): add ReRankerService — diversity, freshness, exploration, streak twiddlers"
```

---

## Task 5: FeedCacheService — Redis Feed/Search Caching

**Files:**
- Create: `app/Services/ContentEngine/FeedCacheService.php`

- [ ] **Step 1: Write FeedCacheService**

```php
<?php

namespace App\Services\ContentEngine;

use Illuminate\Support\Facades\Redis;

class FeedCacheService
{
    /**
     * Get cached feed page.
     * @return array|null Cached results or null if miss
     */
    public static function getFeed(int $userId, string $feedType, int $perPage, int $page): ?array
    {
        $key = self::feedKey($userId, $feedType, $perPage, $page);
        $cached = Redis::get($key);
        return $cached ? json_decode($cached, true) : null;
    }

    /**
     * Cache a feed page.
     */
    public static function setFeed(int $userId, string $feedType, int $perPage, int $page, array $data): void
    {
        $key = self::feedKey($userId, $feedType, $perPage, $page);
        $ttl = config('content-engine.serving.cache.feed_ttl', 60);
        Redis::setex($key, $ttl, json_encode($data));
    }

    /**
     * Invalidate all cached pages for a user's feed type.
     */
    public static function invalidateFeed(int $userId, string $feedType): void
    {
        // Use Redis SCAN to find and delete all matching keys for this user+feedType
        $pattern = "feed:{$userId}:{$feedType}:*";
        $cursor = '0';
        do {
            [$cursor, $keys] = Redis::scan($cursor, ['MATCH' => $pattern, 'COUNT' => 100]);
            if (!empty($keys)) {
                Redis::del(...$keys);
            }
        } while ($cursor !== '0');
    }

    /**
     * Get cached search results (per-user due to personalized scoring).
     */
    public static function getSearch(int $userId, string $query, array $filters, int $page): ?array
    {
        $key = self::searchKey($userId, $query, $filters, $page);
        $cached = Redis::get($key);
        return $cached ? json_decode($cached, true) : null;
    }

    /**
     * Cache search results (per-user due to personalized scoring).
     */
    public static function setSearch(int $userId, string $query, array $filters, int $page, array $data): void
    {
        $key = self::searchKey($userId, $query, $filters, $page);
        $ttl = config('content-engine.serving.cache.search_ttl', 300);
        Redis::setex($key, $ttl, json_encode($data));
    }

    private static function feedKey(int $userId, string $feedType, int $perPage, int $page): string
    {
        return "feed:{$userId}:{$feedType}:{$perPage}:page:{$page}";
    }

    private static function searchKey(int $userId, string $query, array $filters, int $page): string
    {
        $queryHash = md5($query);
        $filtersHash = md5(json_encode($filters));
        return "search:{$userId}:{$queryHash}:{$filtersHash}:page:{$page}";
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
php -l app/Services/ContentEngine/FeedCacheService.php
```

- [ ] **Step 3: Commit**

```bash
git add app/Services/ContentEngine/FeedCacheService.php
git commit -m "feat(content-engine): add FeedCacheService — Redis caching for feeds and search results"
```

---

## Task 6: ServingPipelineService — Full 7-Step Orchestrator

**Files:**
- Create: `app/Services/ContentEngine/ServingPipelineService.php`

- [ ] **Step 1: Write ServingPipelineService**

```php
<?php

namespace App\Services\ContentEngine;

use App\Models\ContentDocument;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ServingPipelineService
{
    /**
     * Serve a feed request through the full pipeline.
     */
    public static function serveFeed(string $feedType, int $userId, int $page = 1, int $perPage = 20): array
    {
        $startTime = microtime(true);

        // Step 0: Check cache
        $cached = FeedCacheService::getFeed($userId, $feedType, $perPage, $page);
        if ($cached) {
            $cached['meta']['served_from_cache'] = true;
            return $cached;
        }

        // TODO: Cache ranked candidate IDs for pagination efficiency
        // Currently the full pipeline re-runs for page > 1. Acceptable for MVP.

        // Step 1: No query understanding needed for feeds

        // Step 2: Candidate generation
        $options = [];

        // For 'nearby' feed, detect user's region and pass as option
        if ($feedType === 'nearby') {
            $profile = DB::table('user_profiles')->where('user_id', $userId)->first(['region', 'district']);
            if ($profile && $profile->region) {
                $options['region'] = $profile->region;
            }
        }

        $candidates = CandidateGeneratorService::generate($feedType, $userId, $options);

        // Step 3: Merge, dedup, privacy filter
        $candidates = self::filterPrivacyAndBlocked($candidates, $userId);

        // For 'discover' feed, exclude friends' content to ensure diverse discovery
        if ($feedType === 'discover') {
            $friendIds = DB::table('friendships')
                ->where(function ($q) use ($userId) {
                    $q->where('user_id', $userId)->orWhere('friend_id', $userId);
                })
                ->where('status', 'accepted')
                ->get()
                ->map(fn($f) => $f->user_id == $userId ? $f->friend_id : $f->user_id)
                ->unique()
                ->all();
            if (!empty($friendIds)) {
                $candidates = array_filter($candidates, function (ContentDocument $doc) use ($friendIds) {
                    return !in_array($doc->creator_id, $friendIds);
                });
            }
        }

        // Step 4: Personalized scoring
        $scored = PersonalizedScorerService::score($candidates, $userId);

        // Step 5: Re-rank with twiddlers
        $reranked = ReRankerService::rerank($scored, $userId, $feedType);

        // Step 6: Paginate
        $offset = ($page - 1) * $perPage;
        $pageItems = array_slice($reranked, $offset, $perPage);

        // Step 7: Hydrate full source records
        $hydrated = self::hydrate($pageItems);

        $queryTimeMs = round((microtime(true) - $startTime) * 1000);

        $result = [
            'success' => true,
            'data' => $hydrated,
            'meta' => [
                'current_page' => $page,
                'per_page' => $perPage,
                'total_candidates' => count($reranked),
                'served_from_cache' => false,
                'query_time_ms' => $queryTimeMs,
                'feed_type' => $feedType,
            ],
        ];

        // Cache the result
        FeedCacheService::setFeed($userId, $feedType, $perPage, $page, $result);

        return $result;
    }

    /**
     * Serve a search request through the full pipeline.
     */
    public static function serveSearch(
        string $query, int $userId, int $page = 1, int $perPage = 20,
        array $filters = []
    ): array {
        $startTime = microtime(true);

        // Step 0: Check cache (per-user because results are personalized)
        $cached = FeedCacheService::getSearch($userId, $query, $filters, $page);
        if ($cached) {
            $cached['meta']['served_from_cache'] = true;
            return $cached;
        }

        // Step 1: Query understanding (Typesense handles keyword matching)
        // Claude query expansion deferred to Phase 5 (AI Layer)

        // Step 2: Candidate generation
        $candidates = CandidateGeneratorService::generateForSearch($query, $userId, $filters);

        // Step 3: Privacy filter
        $candidates = self::filterPrivacyAndBlocked($candidates, $userId);

        // Step 4: Personalized scoring
        $scored = PersonalizedScorerService::score($candidates, $userId);

        // Step 5: Re-rank
        $reranked = ReRankerService::rerank($scored, $userId, 'search');

        // Step 6: Paginate
        $offset = ($page - 1) * $perPage;
        $pageItems = array_slice($reranked, $offset, $perPage);

        // Step 7: Hydrate
        $hydrated = self::hydrate($pageItems);

        $queryTimeMs = round((microtime(true) - $startTime) * 1000);

        $result = [
            'success' => true,
            'data' => $hydrated,
            'meta' => [
                'current_page' => $page,
                'per_page' => $perPage,
                'total_candidates' => count($reranked),
                'served_from_cache' => false,
                'query_time_ms' => $queryTimeMs,
                'query' => $query,
            ],
        ];

        // Cache search results (per-user)
        FeedCacheService::setSearch($userId, $query, $filters, $page, $result);

        return $result;
    }

    /**
     * Privacy filtering: remove documents from blocked users,
     * private docs, and friends-only docs from non-friends.
     */
    private static function filterPrivacyAndBlocked(array $candidates, int $userId): array
    {
        if (empty($candidates)) return [];

        // Get blocked user IDs (both directions)
        $blockedIds = DB::table('blocked_users')
            ->where(function ($q) use ($userId) {
                $q->where('user_id', $userId)->orWhere('blocked_user_id', $userId);
            })
            ->get()
            ->map(fn($b) => $b->user_id == $userId ? $b->blocked_user_id : $b->user_id)
            ->unique()
            ->all();

        // Get friend IDs for friends-only filter
        $friendIds = DB::table('friendships')
            ->where(function ($q) use ($userId) {
                $q->where('user_id', $userId)->orWhere('friend_id', $userId);
            })
            ->where('status', 'accepted')
            ->get()
            ->map(fn($f) => $f->user_id == $userId ? $f->friend_id : $f->user_id)
            ->unique()
            ->all();

        return array_filter($candidates, function (ContentDocument $doc) use ($userId, $blockedIds, $friendIds) {
            // Remove blocked users' content
            if ($doc->creator_id && in_array($doc->creator_id, $blockedIds)) {
                return false;
            }

            // Remove private content (only visible on creator's profile)
            if ($doc->privacy === 'private' && $doc->creator_id !== $userId) {
                return false;
            }

            // Remove friends-only content from non-friends
            if ($doc->privacy === 'friends' && $doc->creator_id !== $userId
                && !in_array($doc->creator_id, $friendIds)) {
                return false;
            }

            return true;
        });
    }

    /**
     * Hydrate documents with full source records.
     * Returns the API response format.
     */
    private static function hydrate(array $items): array
    {
        $hydrated = [];

        // Group by source_type for batch loading
        $byType = [];
        foreach ($items as $item) {
            $doc = $item['doc'];
            $byType[$doc->source_type][$doc->source_id] = $item;
        }

        // Model mapping for hydration
        $modelMap = [
            'post' => \App\Models\Post::class,
            'clip' => \App\Models\Clip::class,
            'story' => \App\Models\Story::class,
            'music' => \App\Models\MusicTrack::class,
            'stream' => \App\Models\LiveStream::class,
            'event' => \App\Models\Event::class,
            'campaign' => \App\Models\Campaign::class,
            'product' => \App\Models\Shop\Product::class,
            'group' => \App\Models\Group::class,
            'gossip_thread' => \App\Models\GossipThread::class,
            'user_profile' => \App\Models\UserProfile::class,
        ];

        foreach ($byType as $sourceType => $itemsBySourceId) {
            $modelClass = $modelMap[$sourceType] ?? null;
            if (!$modelClass) continue;

            $sourceIds = array_keys($itemsBySourceId);
            $sources = $modelClass::whereIn('id', $sourceIds)->get()->keyBy('id');

            foreach ($itemsBySourceId as $sourceId => $item) {
                $source = $sources->get($sourceId);
                if (!$source) continue;

                $doc = $item['doc'];
                $hydrated[] = [
                    'document' => [
                        'id' => $doc->id,
                        'source_type' => $doc->source_type,
                        'source_id' => $doc->source_id,
                        'title' => $doc->title,
                        'content_tier' => $doc->content_tier,
                        'scores' => [
                            'composite' => $doc->composite_score,
                            'personalized' => $item['score'],
                            'trending' => $doc->trending_score ?? 0,
                        ],
                    ],
                    'source' => $source->toArray(),
                    'context' => $item['context'] ?? [
                        'reason' => 'recommended',
                        'is_sponsored' => false,
                        'is_exploration' => false,
                    ],
                ];
            }
        }

        // Re-sort by personalized score to maintain order after batch hydration
        usort($hydrated, fn($a, $b) => ($b['document']['scores']['personalized'] ?? 0) <=> ($a['document']['scores']['personalized'] ?? 0));

        return $hydrated;
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
php -l app/Services/ContentEngine/ServingPipelineService.php
```

- [ ] **Step 3: Commit**

```bash
git add app/Services/ContentEngine/ServingPipelineService.php
git commit -m "feat(content-engine): add ServingPipelineService — full 7-step pipeline orchestrator with privacy, scoring, reranking, hydration"
```

---

## Task 7: API Controllers + Routes + ChecksFeatureFlags Trait

**Files:**
- Create: `app/Traits/ChecksFeatureFlags.php`
- Create: `app/Http/Controllers/Api/V2/FeedController.php`
- Create: `app/Http/Controllers/Api/V2/SearchController.php`
- Modify: `routes/api.php`

- [ ] **Step 1: Create directories**

```bash
mkdir -p /var/www/html/tajiri/app/Http/Controllers/Api/V2
mkdir -p /var/www/html/tajiri/app/Traits
```

- [ ] **Step 2: Write ChecksFeatureFlags trait**

```php
<?php

namespace App\Traits;

use Illuminate\Support\Facades\DB;

trait ChecksFeatureFlags
{
    protected static function isFeatureEnabled(string $flag, int $userId): bool
    {
        $feature = DB::table('feature_flags')->where('flag_name', $flag)->first();
        if (!$feature) return false;
        if (!$feature->is_enabled) return false;
        return ($userId % 100) < $feature->rollout_pct;
    }
}
```

- [ ] **Step 3: Write FeedController**

```php
<?php

namespace App\Http\Controllers\Api\V2;

use App\Http\Controllers\Controller;
use App\Services\ContentEngine\ServingPipelineService;
use App\Traits\ChecksFeatureFlags;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FeedController extends Controller
{
    use ChecksFeatureFlags;

    public function feed(Request $request): JsonResponse
    {
        $request->validate([
            'feed_type' => 'required|in:for_you,friends,discover,trending,nearby,shorts,audio',
            'page' => 'integer|min:1',
            'per_page' => 'integer|min:1|max:50',
        ]);

        $userId = $request->user()->id;
        if (!$userId) {
            return response()->json(['success' => false, 'message' => 'Authentication required'], 401);
        }

        $feedType = $request->input('feed_type', 'for_you');
        $page = (int) $request->input('page', 1);
        $perPage = (int) $request->input('per_page', config('content-engine.serving.per_page_default', 20));

        // Check feature flag
        $flagName = "feed_{$feedType}";
        if (!self::isFeatureEnabled($flagName, $userId)) {
            return response()->json([
                'success' => false,
                'message' => 'This feed type is not available yet',
                'fallback' => true,
            ], 404);
        }

        try {
            $result = ServingPipelineService::serveFeed($feedType, $userId, $page, $perPage);
            return response()->json($result);
        } catch (\Throwable $e) {
            \Log::error("V2 Feed error", ['feed_type' => $feedType, 'error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Feed generation failed',
                'fallback' => true,
            ], 500);
        }
    }
}
```

- [ ] **Step 4: Write SearchController**

```php
<?php

namespace App\Http\Controllers\Api\V2;

use App\Http\Controllers\Controller;
use App\Services\ContentEngine\ServingPipelineService;
use App\Traits\ChecksFeatureFlags;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SearchController extends Controller
{
    use ChecksFeatureFlags;

    public function search(Request $request): JsonResponse
    {
        $request->validate([
            'q' => 'required|string|min:1|max:200',
            'types' => 'nullable|string',
            'category' => 'nullable|string',
            'region' => 'nullable|string',
            'sort' => 'nullable|in:relevance,trending,newest',
            'page' => 'integer|min:1',
            'per_page' => 'integer|min:1|max:50',
        ]);

        $userId = $request->user()->id;
        if (!$userId) {
            return response()->json(['success' => false, 'message' => 'Authentication required'], 401);
        }

        // Check feature flag
        if (!self::isFeatureEnabled('search_v2', $userId)) {
            return response()->json([
                'success' => false,
                'message' => 'Search v2 is not available yet',
                'fallback' => true,
            ], 404);
        }

        $query = $request->input('q');
        $page = (int) $request->input('page', 1);
        $perPage = (int) $request->input('per_page', config('content-engine.serving.per_page_default', 20));

        $filters = array_filter([
            'types' => $request->input('types') ? explode(',', $request->input('types')) : null,
            'category' => $request->input('category'),
            'region' => $request->input('region'),
            'sort' => $request->input('sort', 'relevance'),
        ]);

        try {
            $result = ServingPipelineService::serveSearch($query, $userId, $page, $perPage, $filters);
            return response()->json($result);
        } catch (\Throwable $e) {
            \Log::error("V2 Search error", ['query' => $query, 'error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Search failed',
                'fallback' => true,
            ], 500);
        }
    }
}
```

- [ ] **Step 5: Add v2 routes to routes/api.php**

Read `routes/api.php` and append v2 routes at the end:

```php

// Content Engine v2 API
Route::prefix('v2')->middleware('auth:sanctum')->group(function () {
    Route::get('/feed', [\App\Http\Controllers\Api\V2\FeedController::class, 'feed']);
    Route::get('/search', [\App\Http\Controllers\Api\V2\SearchController::class, 'search']);
});
```

- [ ] **Step 6: Syntax check all files**

```bash
php -l app/Traits/ChecksFeatureFlags.php
php -l app/Http/Controllers/Api/V2/FeedController.php
php -l app/Http/Controllers/Api/V2/SearchController.php
php -l routes/api.php
```

- [ ] **Step 7: Commit**

```bash
git add app/Traits/ChecksFeatureFlags.php app/Http/Controllers/Api/V2/ routes/api.php
git commit -m "feat(content-engine): add v2 Feed and Search API endpoints with feature flag gating via shared trait"
```

---

## Task 8: Add UserSignalService Helper Methods + TypesenseService.searchIds

**Files:**
- Modify: `app/Services/ContentEngine/UserSignalService.php`
- Modify: `app/Services/ContentEngine/TypesenseService.php`

The CandidateGeneratorService and PersonalizedScorerService call helper methods that may not yet exist on UserSignalService and TypesenseService. This task adds them.

- [ ] **Step 1: Read UserSignalService and check existing methods**

```bash
grep -n "public static function" /var/www/html/tajiri/app/Services/ContentEngine/UserSignalService.php
```

- [ ] **Step 2: Add missing helper methods to UserSignalService**

Add these methods if they don't already exist. These read from the SINGLE Redis hash `user:{userId}:signals` that UserSignalService already writes to (each field is a JSON array):

```php
    /**
     * Get user's top N creators by recency (most recently liked first).
     * Reads from the single user signals hash: user:{userId}:signals, field: liked_creators
     * @return int[] Array of creator user IDs
     */
    public static function getTopCreators(int $userId, int $limit = 10): array
    {
        $key = "user:{$userId}:signals";
        $json = Redis::hGet($key, 'liked_creators');
        $creators = $json ? json_decode($json, true) : [];
        // Return array of IDs, limited to $limit, ordered by recency (last element = most recent)
        return array_slice(array_reverse($creators), 0, $limit);
    }

    /**
     * Get user's top N categories by recency.
     * Reads from the single user signals hash: user:{userId}:signals, field: liked_categories
     * @return string[] Array of category names
     */
    public static function getTopCategories(int $userId, int $limit = 5): array
    {
        $key = "user:{$userId}:signals";
        $json = Redis::hGet($key, 'liked_categories');
        $categories = $json ? json_decode($json, true) : [];
        return array_slice(array_reverse($categories), 0, $limit);
    }

    /**
     * Get user's top N hashtags by recency.
     * Reads from the single user signals hash: user:{userId}:signals, field: liked_hashtags
     * @return string[]
     */
    public static function getTopHashtags(int $userId, int $limit = 30): array
    {
        $key = "user:{$userId}:signals";
        $json = Redis::hGet($key, 'liked_hashtags');
        $hashtags = $json ? json_decode($json, true) : [];
        return array_slice(array_reverse($hashtags), 0, $limit);
    }

    /**
     * Get user's media type preferences by recency.
     * Reads from the single user signals hash: user:{userId}:signals, field: liked_media
     * @return string[] Sorted by recency (most recent first)
     */
    public static function getMediaPreferences(int $userId): array
    {
        $key = "user:{$userId}:signals";
        $json = Redis::hGet($key, 'liked_media');
        $media = $json ? json_decode($json, true) : [];
        return array_reverse($media);
    }
```

- [ ] **Step 3: Read TypesenseService and check for searchIds method**

```bash
grep -n "public static function" /var/www/html/tajiri/app/Services/ContentEngine/TypesenseService.php
```

- [ ] **Step 4: Add searchIds method to TypesenseService if missing**

```php
    /**
     * Search Typesense and return matching content_document IDs.
     * Used by CandidateGeneratorService for keyword candidate generation.
     *
     * @return int[] Array of content_document IDs
     */
    public static function searchIds(string $query, int $limit = 200, array $filters = []): array
    {
        $tsConfig = config('content-engine.typesense');
        $baseUrl = "{$tsConfig['protocol']}://{$tsConfig['host']}:{$tsConfig['port']}";
        $apiKey = $tsConfig['api_key'];
        $collection = $tsConfig['collection'];

        $params = [
            'q' => $query,
            'query_by' => 'title,body,hashtags',
            'per_page' => $limit,
            'sort_by' => '_text_match:desc,composite_score:desc',
        ];

        // Build filter string
        $filterParts = [];
        if (isset($filters['source_type'])) {
            $filterParts[] = "source_type:={$filters['source_type']}";
        }
        if (isset($filters['types']) && is_array($filters['types'])) {
            $filterParts[] = "source_type:[" . implode(',', $filters['types']) . "]";
        }
        if (isset($filters['category'])) {
            $filterParts[] = "category:={$filters['category']}";
        }
        if (isset($filters['region'])) {
            $filterParts[] = "region_name:={$filters['region']}";
        }
        $filterParts[] = "content_tier:!=blackhole";

        if (!empty($filterParts)) {
            $params['filter_by'] = implode(' && ', $filterParts);
        }

        try {
            $response = \Illuminate\Support\Facades\Http::timeout(5)
                ->withHeaders(['X-TYPESENSE-API-KEY' => $apiKey])
                ->get("{$baseUrl}/collections/{$collection}/documents/search", $params);

            if (!$response->ok()) return [];

            $hits = $response->json('hits', []);
            return array_map(fn($hit) => (int) ($hit['document']['id'] ?? 0), $hits);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::warning("TypesenseService::searchIds failed", ['error' => $e->getMessage()]);
            return [];
        }
    }
```

- [ ] **Step 5: Syntax check**

```bash
php -l app/Services/ContentEngine/UserSignalService.php
php -l app/Services/ContentEngine/TypesenseService.php
```

- [ ] **Step 6: Commit**

```bash
git add app/Services/ContentEngine/UserSignalService.php app/Services/ContentEngine/TypesenseService.php
git commit -m "feat(content-engine): add helper methods for serving pipeline — UserSignalService getters, TypesenseService.searchIds"
```

---

## Task 9: Enable Feature Flags + End-to-End Verify

- [ ] **Step 1: Enable feed feature flags**

```bash
cd /var/www/html/tajiri
php artisan tinker --execute="
\$flags = ['feed_for_you', 'feed_friends', 'feed_discover', 'feed_trending', 'feed_nearby', 'feed_shorts', 'feed_audio', 'search_v2'];
foreach (\$flags as \$flag) {
    \DB::table('feature_flags')->updateOrInsert(
        ['flag_name' => \$flag],
        ['is_enabled' => true, 'rollout_pct' => 100, 'description' => 'Content Engine v2 ' . \$flag, 'updated_at' => now()]
    );
    echo \"Enabled: {\$flag}\" . PHP_EOL;
}
"
```

- [ ] **Step 2: Test feed endpoint**

```bash
# Test with curl (adjust token as needed)
curl -s "http://localhost:8000/api/v2/feed?feed_type=for_you&page=1&per_page=5" \
  -H "Authorization: Bearer TEST_TOKEN" | python3 -m json.tool | head -30
```

If auth middleware blocks it, test via tinker:

```bash
php artisan tinker --execute="
\$result = \App\Services\ContentEngine\ServingPipelineService::serveFeed('for_you', 1, 1, 5);
echo 'Success: ' . (\$result['success'] ? 'true' : 'false') . PHP_EOL;
echo 'Items: ' . count(\$result['data']) . PHP_EOL;
echo 'Candidates: ' . \$result['meta']['total_candidates'] . PHP_EOL;
echo 'Time: ' . \$result['meta']['query_time_ms'] . 'ms' . PHP_EOL;
if (!empty(\$result['data'])) {
    \$first = \$result['data'][0];
    echo 'First item: ' . \$first['document']['source_type'] . ':' . \$first['document']['source_id'] . PHP_EOL;
    echo 'Score: ' . \$first['document']['scores']['personalized'] . PHP_EOL;
    echo 'Reason: ' . \$first['context']['reason'] . PHP_EOL;
}
"
```

- [ ] **Step 3: Test search endpoint**

```bash
php artisan tinker --execute="
\$result = \App\Services\ContentEngine\ServingPipelineService::serveSearch('bongo', 1, 1, 5);
echo 'Success: ' . (\$result['success'] ? 'true' : 'false') . PHP_EOL;
echo 'Items: ' . count(\$result['data']) . PHP_EOL;
echo 'Candidates: ' . \$result['meta']['total_candidates'] . PHP_EOL;
echo 'Time: ' . \$result['meta']['query_time_ms'] . 'ms' . PHP_EOL;
"
```

- [ ] **Step 4: Test cache hit**

```bash
php artisan tinker --execute="
// First call (cache miss)
\$t1 = microtime(true);
\$r1 = \App\Services\ContentEngine\ServingPipelineService::serveFeed('trending', 1, 1, 5);
\$ms1 = round((microtime(true) - \$t1) * 1000);

// Second call (should be cache hit)
\$t2 = microtime(true);
\$r2 = \App\Services\ContentEngine\ServingPipelineService::serveFeed('trending', 1, 1, 5);
\$ms2 = round((microtime(true) - \$t2) * 1000);

echo \"First call: {\$ms1}ms (cached=\" . (\$r1['meta']['served_from_cache'] ? 'true' : 'false') . \")\" . PHP_EOL;
echo \"Second call: {\$ms2}ms (cached=\" . (\$r2['meta']['served_from_cache'] ? 'true' : 'false') . \")\" . PHP_EOL;
"
```

- [ ] **Step 5: Run health check**

```bash
php artisan content:health-check
```

- [ ] **Step 6: Verify all syntax**

```bash
find /var/www/html/tajiri/app/Services/ContentEngine/ -name "*.php" -exec php -l {} \;
find /var/www/html/tajiri/app/Http/Controllers/Api/V2/ -name "*.php" -exec php -l {} \;
php -l /var/www/html/tajiri/app/Traits/ChecksFeatureFlags.php
```

No git commit needed for this verification step.

---

## Phase 4 Completion Criteria

After all 9 tasks:

- [ ] `GET /api/v2/feed?feed_type=for_you` returns personalized content through full pipeline
- [ ] `GET /api/v2/feed?feed_type=friends` returns friends' content only
- [ ] `GET /api/v2/feed?feed_type=discover` returns diverse content excluding friends
- [ ] `GET /api/v2/feed?feed_type=trending` returns top trending content
- [ ] `GET /api/v2/feed?feed_type=nearby` uses user's region from profile
- [ ] `GET /api/v2/search?q=...` returns ranked search results from Typesense + pgvector
- [ ] Personalized scoring applies 6 boost types (creator, category, hashtag, media, social, regional)
- [ ] Re-ranker enforces diversity (max 2 consecutive same creator, max 4 same type) with deferred queue
- [ ] Exploration content injected at configured rate (10% default, 30% new users)
- [ ] Redis caching works (60s feed, 300s search) with per-user search cache keys
- [ ] Privacy filtering removes blocked users, private content, friends-only from non-friends
- [ ] Feature flags gate each feed type independently via shared ChecksFeatureFlags trait
- [ ] All code committed

**Deferred to Phase 5:** Claude AI layer (query expansion, trending digests, creator coaching, content moderation, embedding text generation), sponsored post insertion (requires SponsoredPostService).

**Next:** Phase 5 — AI Intelligence Layer (Claude-powered content scoring, query expansion, trending digests, creator coaching, moderation)
