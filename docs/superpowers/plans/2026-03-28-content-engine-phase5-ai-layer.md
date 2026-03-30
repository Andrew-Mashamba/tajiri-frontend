# Content Engine Phase 5: AI Intelligence Layer — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 5 Claude-powered AI features to the Content Engine: query expansion, trending digest generation, creator coaching, content moderation, and embedding text generation. (Content Scorer already exists as `ClaudeScoreContentJob`.)

**Architecture:** Each feature is a self-contained service + artisan command + queue job (where needed). All use Claude CLI via `shell_exec()` following the pattern established in `ClaudeScoreContentJob`. Batch features run on schedule. Real-time features run in queue workers. Every feature has a fallback for when Claude is unavailable.

**Tech Stack:** Laravel 12, PHP 8.3, Claude CLI (Haiku for write-time/read-time, Sonnet for batch), PostgreSQL 16, Redis, Supervisor

**Server:** `root@172.240.241.180` at `/var/www/tajiri.zimasystems.com`. Connect via `sshpass -p "$TAJIRI_SSH_PASS" ssh root@172.240.241.180` (password stored in memory, not in code).

---

## Existing Infrastructure (DO NOT recreate)

These already exist and must not be modified unless explicitly stated:

- `config/content-engine.php` — has `claude` section with `cli_path`, `scoring_model`, `query_model`, `digest_model`, `coaching_model`, `moderation_model`. **Phase 5 adds `embedding_model` key** (default `haiku`).
- `app/Jobs/ContentEngine/ClaudeScoreContentJob.php` — content scorer (Task 1 is already done)
- `app/Jobs/ContentEngine/ContentIngestionJob.php:55` — dispatches `ClaudeScoreContentJob`
- `app/Models/ContentDocument.php` — has `quality_score`, `spam_score`, `category`, `language`, `content_tier` columns
- Tables: `trending_digests` (id, headline_sw, headline_en, stories, mood, generated_at, valid_until), `creator_coaching` (id, creator_id, advice, week_start, generated_at)
- Claude CLI at `/usr/local/bin/claude` (version 2.1.83)

## File Structure

### New Files (6)

| File | Responsibility |
|------|----------------|
| `app/Services/ContentEngine/QueryExpanderService.php` | Expand search queries via Claude Haiku — intent, entities, cross-language, type boosting |
| `app/Services/ContentEngine/TrendingDigestService.php` | Generate "Kinachoendelea Sasa" trending digests via Claude Sonnet |
| `app/Services/ContentEngine/CreatorCoachService.php` | Generate weekly personalized coaching advice per creator via Claude Sonnet |
| `app/Services/ContentEngine/ContentModeratorService.php` | Review flagged content via Claude Sonnet — approve/warn/hide/ban/escalate |
| `app/Services/ContentEngine/EmbeddingTextService.php` | Generate rich English embedding text from raw content via Claude Haiku |
| `app/Jobs/ContentEngine/GenerateEmbeddingTextJob.php` | Queue job dispatched after content ingestion to generate embedding text + re-embed |

### New Artisan Commands (4)

| Command | Responsibility |
|---------|----------------|
| `app/Console/Commands/GenerateDigest.php` | `content:generate-digest` — batch trending digest generation |
| `app/Console/Commands/GenerateCoaching.php` | `content:generate-coaching` — batch weekly creator coaching |
| `app/Console/Commands/ModerateContent.php` | `content:moderate-flagged` — batch moderation of flagged content |
| `app/Console/Commands/GenerateEmbeddingText.php` | `content:generate-embedding-text` — backfill embedding text for existing content |

### New Migration (1)

| File | Responsibility |
|------|----------------|
| `database/migrations/2026_03_28_300001_add_ai_layer_columns_and_tables.php` | Add `embedding_text` column to `content_documents`, create `moderation_log` table |

### Modified Files (3)

| File | Change |
|------|--------|
| `app/Services/ContentEngine/ServingPipelineService.php` | Integrate QueryExpanderService into search pipeline |
| `app/Jobs/ContentEngine/ContentIngestionJob.php` | Dispatch GenerateEmbeddingTextJob after ingestion |
| `routes/console.php` | Add schedules for digest, coaching, moderation |

---

## Task 1: Database Migration — embedding_text column + moderation_log table

**Files:**
- Create: `database/migrations/2026_03_28_300001_add_ai_layer_columns_and_tables.php`

- [ ] **Step 1: Create migration**

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Add embedding_text column for AI-generated rich text
        Schema::table('content_documents', function (Blueprint $table) {
            $table->text('embedding_text')->nullable()->after('embedding');
        });

        // Create moderation log table
        Schema::create('moderation_log', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('document_id');
            $table->string('action'); // approve, warn, hide, ban_content, escalate
            $table->string('reason')->nullable();
            $table->float('confidence')->default(0);
            $table->string('model_used')->nullable();
            $table->json('context')->nullable(); // raw Claude response
            $table->timestamps();

            $table->foreign('document_id')->references('id')->on('content_documents')->onDelete('cascade');
            $table->index('action');
            $table->index('created_at');
        });
    }

    public function down(): void
    {
        Schema::table('content_documents', function (Blueprint $table) {
            $table->dropColumn('embedding_text');
        });
        Schema::dropIfExists('moderation_log');
    }
};
```

- [ ] **Step 2: Run migration**

```bash
cd /var/www/tajiri.zimasystems.com
php8.3 artisan migrate
```

Expected: Migration runs successfully, adds `embedding_text` column and `moderation_log` table.

- [ ] **Step 3: Verify**

```bash
php8.3 artisan tinker --execute="
echo Schema::hasColumn('content_documents', 'embedding_text') ? 'embedding_text: OK' : 'MISSING';
echo PHP_EOL;
echo Schema::hasTable('moderation_log') ? 'moderation_log: OK' : 'MISSING';
"
```

- [ ] **Step 3b: Add `embedding_model` config key**

In `config/content-engine.php`, find the `'claude'` section and add after `'moderation_model'`:

```php
        'embedding_model' => env('CLAUDE_EMBEDDING_MODEL', 'haiku'),
```

Syntax check: `php -l config/content-engine.php`

- [ ] **Step 4: Grant graph user access**

```bash
sudo -u postgres psql -d tajiri -c "GRANT SELECT ON moderation_log TO tajiri_graph;"
```

- [ ] **Step 5: Commit**

```bash
git add database/migrations/2026_03_28_300001_add_ai_layer_columns_and_tables.php
git commit -m "feat(content-engine): add embedding_text column and moderation_log table for AI layer"
```

---

## Task 2: QueryExpanderService — Claude-powered search query expansion

**Files:**
- Create: `app/Services/ContentEngine/QueryExpanderService.php`
- Modify: `app/Services/ContentEngine/ServingPipelineService.php`

- [ ] **Step 1: Create QueryExpanderService**

```php
<?php

namespace App\Services\ContentEngine;

use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

class QueryExpanderService
{
    /**
     * Expand a search query using Claude Haiku.
     * Budget: 800ms max. Falls back to original query on timeout/failure.
     *
     * @return array{
     *   original: string,
     *   expanded_queries: string[],
     *   type_boost: string|null,
     *   intent: string|null
     * }
     */
    public static function expand(string $query): array
    {
        $fallback = [
            'original' => $query,
            'expanded_queries' => [],
            'type_boost' => null,
            'intent' => null,
        ];

        $query = trim($query);
        if (mb_strlen($query) < 2) {
            return $fallback;
        }

        // Check cache first (5 min TTL)
        $cacheKey = 'qe:' . md5(mb_strtolower($query));
        $cached = Cache::get($cacheKey);
        if ($cached) {
            return $cached;
        }

        $cliPath = config('content-engine.claude.cli_path', 'claude');
        $model = config('content-engine.claude.query_model', 'haiku');

        // Sanitize query — strip null bytes and control chars
        $safeQuery = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F]/', '', $query);

        $prompt = "You are a search query expander for TAJIRI, a Tanzanian social media platform. Users search in Swahili, English, or Sheng (slang mix).\n\nExpand this search query. Respond with ONLY a JSON object:\n\nQuery: {$safeQuery}\n\nJSON format:\n{\"expanded_queries\": [\"english expansion 1\", \"swahili expansion\"], \"type_boost\": \"<content_type or null>\", \"intent\": \"<one of: discover, specific, trending, person, topic>\"}\n\nRules:\n- expanded_queries: 1-3 alternative phrasings including cross-language (Swahili↔English)\n- type_boost: if query clearly targets a content type (music, clip, event, product, group), set it. Otherwise null.\n- intent: classify the search intent\n- Keep expansions concise (2-5 words each)";

        try {
            $escapedPrompt = escapeshellarg($prompt);

            // Use timeout 2s (spec: 800ms budget, but CLI startup overhead needs slack)
            $output = shell_exec("timeout 2 {$cliPath} -p {$escapedPrompt} --model {$model} --output-format text 2>/dev/null");

            if (empty($output)) {
                Log::debug("QueryExpander: empty response", ['query' => $query]);
                return $fallback;
            }

            preg_match('/\{.*\}/s', $output, $matches);
            if (empty($matches[0])) {
                Log::debug("QueryExpander: no JSON in response", ['query' => $query]);
                return $fallback;
            }

            $parsed = json_decode($matches[0], true);
            if (!$parsed) {
                return $fallback;
            }

            $result = [
                'original' => $query,
                'expanded_queries' => array_slice((array) ($parsed['expanded_queries'] ?? []), 0, 3),
                'type_boost' => $parsed['type_boost'] ?? null,
                'intent' => $parsed['intent'] ?? null,
            ];

            // Cache for 5 minutes
            Cache::put($cacheKey, $result, 300);

            return $result;

        } catch (\Throwable $e) {
            Log::warning("QueryExpander: failed", ['query' => $query, 'error' => $e->getMessage()]);
            return $fallback;
        }
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
php -l app/Services/ContentEngine/QueryExpanderService.php
```

- [ ] **Step 3: Integrate into ServingPipelineService::serveSearch()**

In `ServingPipelineService.php`, find the `serveSearch` method. After the cache check and before candidate generation, add query expansion. The expanded queries should be passed to `CandidateGeneratorService::generateForSearch()` as additional search terms.

Find the line where `CandidateGeneratorService::generateForSearch($query, ...)` is called. Before that call, add:

```php
// Expand query via Claude (async, cached, falls back gracefully)
$expansion = QueryExpanderService::expand($query);
$searchQueries = array_merge([$query], $expansion['expanded_queries']);
$searchOptions = [];
if ($expansion['type_boost']) {
    $searchOptions['type_boost'] = $expansion['type_boost'];
}
```

Then modify the `generateForSearch` call to pass the expanded queries. If the method only accepts a single string, pass the first expanded query concatenated: `$expandedQuery = implode(' ', $searchQueries);` and use that instead.

Also add `use App\Services\ContentEngine\QueryExpanderService;` at the top.

Add `'query_expansion' => $expansion` to the response meta.

- [ ] **Step 4: Syntax check both files**

```bash
php -l app/Services/ContentEngine/QueryExpanderService.php
php -l app/Services/ContentEngine/ServingPipelineService.php
```

- [ ] **Step 5: Test**

```bash
php8.3 artisan tinker --execute="
\$result = \App\Services\ContentEngine\QueryExpanderService::expand('nyimbo mpya bongo');
print_r(\$result);
"
```

Expected: Returns array with expanded_queries (e.g. "new bongo flava songs"), type_boost "music", intent "discover".

- [ ] **Step 6: Test search with expansion**

```bash
php8.3 artisan tinker --execute="
\$result = \App\Services\ContentEngine\ServingPipelineService::serveSearch('nyimbo mpya', 1, 1, 5);
echo 'Items: ' . count(\$result['data']) . PHP_EOL;
echo 'Expansion: '; print_r(\$result['meta']['query_expansion'] ?? 'none');
"
```

- [ ] **Step 7: Commit**

```bash
git add app/Services/ContentEngine/QueryExpanderService.php app/Services/ContentEngine/ServingPipelineService.php
git commit -m "feat(content-engine): add QueryExpanderService — Claude-powered search query expansion with Swahili↔English cross-language support"
```

---

## Task 3: TrendingDigestService + command — "Kinachoendelea Sasa" generator

**Files:**
- Create: `app/Services/ContentEngine/TrendingDigestService.php`
- Create: `app/Console/Commands/GenerateDigest.php`

- [ ] **Step 1: Create TrendingDigestService**

```php
<?php

namespace App\Services\ContentEngine;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class TrendingDigestService
{
    /**
     * Generate a trending digest from top trending content.
     * Uses Claude Sonnet to summarize into 3-5 story summaries.
     * Stores result in trending_digests table.
     */
    public static function generate(): ?array
    {
        // Get top 20 trending content from last 6 hours
        $trending = DB::table('content_documents')
            ->where('trending_score', '>', 0)
            ->where('content_tier', '!=', 'blackhole')
            ->where('published_at', '>=', now()->subHours(6))
            ->orderByDesc('trending_score')
            ->limit(20)
            ->get(['id', 'title', 'body', 'source_type', 'category', 'hashtags', 'trending_score']);

        if ($trending->isEmpty()) {
            Log::info("TrendingDigest: no trending content found, skipping");
            return null;
        }

        // Build context for Claude
        $contentSummary = $trending->map(function ($doc, $i) {
            $tags = is_string($doc->hashtags) ? json_decode($doc->hashtags, true) : $doc->hashtags;
            $hashtags = is_array($tags) ? implode(', ', $tags) : '';
            $body = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F]/', '', mb_substr($doc->body ?? '', 0, 200));
            return ($i + 1) . ". [{$doc->source_type}] {$doc->title} — {$body} (hashtags: {$hashtags}, score: {$doc->trending_score})";
        })->implode("\n");

        $cliPath = config('content-engine.claude.cli_path', 'claude');
        $model = config('content-engine.claude.digest_model', 'sonnet');

        $prompt = "You are the editor for TAJIRI, a Tanzanian social media platform. Generate a trending digest called \"Kinachoendelea Sasa\" (What's Happening Now).\n\nHere are the top trending content items:\n{$contentSummary}\n\nGenerate a JSON response with:\n{\"headline_sw\": \"<catchy Swahili headline>\", \"headline_en\": \"<English translation>\", \"stories\": [{\"title\": \"<story title in Swahili>\", \"summary\": \"<2-3 sentence summary in Swahili>\", \"category\": \"<category>\"}], \"mood\": \"<one of: exciting, informative, controversial, celebratory, somber>\"}\n\nRules:\n- 3-5 stories, grouped by theme\n- Write in natural Swahili (not translated English)\n- Keep summaries brief and engaging\n- mood reflects the overall tone of trending content";

        try {
            $escapedPrompt = escapeshellarg($prompt);
            $output = shell_exec("timeout 30 {$cliPath} -p {$escapedPrompt} --model {$model} --output-format text 2>/dev/null");

            if (empty($output)) {
                Log::warning("TrendingDigest: empty Claude response");
                return null;
            }

            // Extract JSON (may have markdown fences)
            $cleaned = preg_replace('/```json\s*|\s*```/', '', $output);
            preg_match('/\{.*\}/s', $cleaned, $matches);

            if (empty($matches[0])) {
                Log::warning("TrendingDigest: no JSON found in response");
                return null;
            }

            $digest = json_decode($matches[0], true);
            if (!$digest || empty($digest['stories'])) {
                Log::warning("TrendingDigest: invalid JSON structure");
                return null;
            }

            // Store in database
            $insertData = [
                'headline_sw' => $digest['headline_sw'] ?? 'Kinachoendelea Sasa',
                'headline_en' => $digest['headline_en'] ?? "What's Happening Now",
                'stories' => json_encode($digest['stories']),
                'mood' => $digest['mood'] ?? 'informative',
                'generated_at' => now(),
                'valid_until' => now()->addHours(4),
            ];

            $id = DB::table('trending_digests')->insertGetId($insertData);

            Log::info("TrendingDigest: generated", ['id' => $id, 'stories' => count($digest['stories'])]);

            return $digest;

        } catch (\Throwable $e) {
            Log::error("TrendingDigest: failed", ['error' => $e->getMessage()]);
            return null;
        }
    }

    /**
     * Get the latest valid digest.
     * Fallback: returns previous digest if current generation failed.
     */
    public static function getLatest(): ?object
    {
        return DB::table('trending_digests')
            ->where('valid_until', '>=', now())
            ->orderByDesc('generated_at')
            ->first()
            ?? DB::table('trending_digests')
                ->orderByDesc('generated_at')
                ->first();
    }
}
```

- [ ] **Step 2: Create GenerateDigest command**

```php
<?php

namespace App\Console\Commands;

use App\Services\ContentEngine\TrendingDigestService;
use Illuminate\Console\Command;

class GenerateDigest extends Command
{
    protected $signature = 'content:generate-digest';
    protected $description = 'Generate a trending digest using Claude AI';

    public function handle(): int
    {
        $this->info('Generating trending digest...');

        $result = TrendingDigestService::generate();

        if ($result) {
            $this->info('Digest generated: ' . ($result['headline_sw'] ?? 'OK'));
            $this->info('Stories: ' . count($result['stories'] ?? []));
            return Command::SUCCESS;
        }

        $this->warn('No digest generated (no trending content or Claude unavailable)');
        return Command::SUCCESS;
    }
}
```

- [ ] **Step 3: Syntax check**

```bash
php -l app/Services/ContentEngine/TrendingDigestService.php
php -l app/Console/Commands/GenerateDigest.php
```

- [ ] **Step 4: Test**

```bash
php8.3 artisan content:generate-digest
```

Expected: Either generates a digest or reports "no trending content" (since we have few posts). Check `trending_digests` table:

```bash
php8.3 artisan tinker --execute="echo \DB::table('trending_digests')->count() . ' digests';"
```

- [ ] **Step 5: Commit**

```bash
git add app/Services/ContentEngine/TrendingDigestService.php app/Console/Commands/GenerateDigest.php
git commit -m "feat(content-engine): add TrendingDigestService — Claude Sonnet generates Kinachoendelea Sasa trending digests"
```

---

## Task 4: CreatorCoachService + command — weekly personalized coaching

**Files:**
- Create: `app/Services/ContentEngine/CreatorCoachService.php`
- Create: `app/Console/Commands/GenerateCoaching.php`

- [ ] **Step 1: Create CreatorCoachService**

```php
<?php

namespace App\Services\ContentEngine;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class CreatorCoachService
{
    /**
     * Generate personalized coaching advice for a single creator.
     */
    public static function coachCreator(int $creatorId): ?string
    {
        // Get creator's content stats from last 7 days
        $stats = DB::table('content_documents')
            ->where('creator_id', $creatorId)
            ->where('published_at', '>=', now()->subDays(7))
            ->selectRaw("
                count(*) as post_count,
                avg(engagement_score) as avg_engagement,
                avg(quality_score) as avg_quality,
                max(trending_score) as max_trending
            ")
            ->first();

        // Get creator's top performing content
        $topContent = DB::table('content_documents')
            ->where('creator_id', $creatorId)
            ->where('published_at', '>=', now()->subDays(7))
            ->orderByDesc('engagement_score')
            ->limit(3)
            ->get(['title', 'source_type', 'engagement_score', 'quality_score', 'hashtags']);

        // Get platform trending topics for context
        $trending = DB::table('content_documents')
            ->where('trending_score', '>', 0)
            ->where('published_at', '>=', now()->subDays(2))
            ->orderByDesc('trending_score')
            ->limit(5)
            ->pluck('category')
            ->unique()
            ->values()
            ->implode(', ');

        $topSummary = $topContent->map(function ($doc) {
            return "- [{$doc->source_type}] {$doc->title} (engagement: {$doc->engagement_score}, quality: {$doc->quality_score})";
        })->implode("\n");

        $cliPath = config('content-engine.claude.cli_path', 'claude');
        $model = config('content-engine.claude.coaching_model', 'sonnet');

        $prompt = "You are a content coach for TAJIRI, a Tanzanian social media platform. Give personalized weekly coaching advice to this creator.\n\nCreator Stats (last 7 days):\n- Posts: {$stats->post_count}\n- Avg engagement: " . round($stats->avg_engagement ?? 0, 1) . "\n- Avg quality: " . round($stats->avg_quality ?? 0, 1) . "\n- Max trending score: " . round($stats->max_trending ?? 0, 1) . "\n\nTop content:\n{$topSummary}\n\nPlatform trending topics: {$trending}\n\nWrite coaching advice in Swahili (2-3 paragraphs). Include:\n1. What worked well this week\n2. One specific thing to try next week\n3. A trending topic opportunity they could tap into\n4. Optimal posting suggestion\n\nKeep it encouraging, practical, and concise. Respond with ONLY the advice text, no JSON.";

        try {
            $escapedPrompt = escapeshellarg($prompt);
            $output = shell_exec("timeout 30 {$cliPath} -p {$escapedPrompt} --model {$model} --output-format text 2>/dev/null");

            if (empty($output)) {
                Log::warning("CreatorCoach: empty response", ['creator' => $creatorId]);
                return null;
            }

            $advice = trim($output);

            // Store in database
            DB::table('creator_coaching')->insert([
                'creator_id' => $creatorId,
                'advice' => $advice,
                'week_start' => now()->startOfWeek()->toDateString(),
                'generated_at' => now(),
            ]);

            Log::info("CreatorCoach: advice generated", ['creator' => $creatorId, 'length' => mb_strlen($advice)]);

            return $advice;

        } catch (\Throwable $e) {
            Log::error("CreatorCoach: failed", ['creator' => $creatorId, 'error' => $e->getMessage()]);
            return null;
        }
    }

    /**
     * Batch generate coaching for all active creators.
     */
    public static function batchCoach(): int
    {
        $weekStart = now()->startOfWeek()->toDateString();

        // Find creators who posted in last 14 days and haven't been coached this week
        $creators = DB::table('content_documents')
            ->where('published_at', '>=', now()->subDays(14))
            ->whereNotNull('creator_id')
            ->distinct()
            ->pluck('creator_id');

        $alreadyCoached = DB::table('creator_coaching')
            ->where('week_start', $weekStart)
            ->pluck('creator_id');

        $toCoach = $creators->diff($alreadyCoached);

        $count = 0;
        foreach ($toCoach as $creatorId) {
            $result = self::coachCreator($creatorId);
            if ($result) $count++;
            // Rate limit: 2 second pause between Claude calls
            sleep(2);
        }

        return $count;
    }

    /**
     * Get latest coaching for a creator.
     */
    public static function getLatest(int $creatorId): ?object
    {
        return DB::table('creator_coaching')
            ->where('creator_id', $creatorId)
            ->orderByDesc('generated_at')
            ->first();
    }
}
```

- [ ] **Step 2: Create GenerateCoaching command**

```php
<?php

namespace App\Console\Commands;

use App\Services\ContentEngine\CreatorCoachService;
use Illuminate\Console\Command;

class GenerateCoaching extends Command
{
    protected $signature = 'content:generate-coaching';
    protected $description = 'Generate weekly coaching advice for active creators using Claude AI';

    public function handle(): int
    {
        $this->info('Generating creator coaching...');

        $count = CreatorCoachService::batchCoach();

        $this->info("Coaching generated for {$count} creators");
        return Command::SUCCESS;
    }
}
```

- [ ] **Step 3: Syntax check**

```bash
php -l app/Services/ContentEngine/CreatorCoachService.php
php -l app/Console/Commands/GenerateCoaching.php
```

- [ ] **Step 4: Test with a single creator**

```bash
php8.3 artisan tinker --execute="
\$creatorId = \DB::table('content_documents')->whereNotNull('creator_id')->value('creator_id');
echo 'Testing creator: ' . \$creatorId . PHP_EOL;
\$advice = \App\Services\ContentEngine\CreatorCoachService::coachCreator(\$creatorId);
echo \$advice ? mb_substr(\$advice, 0, 200) . '...' : 'No advice generated';
"
```

- [ ] **Step 5: Commit**

```bash
git add app/Services/ContentEngine/CreatorCoachService.php app/Console/Commands/GenerateCoaching.php
git commit -m "feat(content-engine): add CreatorCoachService — weekly Claude Sonnet coaching advice in Swahili for active creators"
```

---

## Task 5: ContentModeratorService + command + moderation_log model

**Files:**
- Create: `app/Services/ContentEngine/ContentModeratorService.php`
- Create: `app/Console/Commands/ModerateContent.php`

- [ ] **Step 1: Create ContentModeratorService**

```php
<?php

namespace App\Services\ContentEngine;

use App\Models\ContentDocument;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ContentModeratorService
{
    public const ACTION_APPROVE = 'approve';
    public const ACTION_WARN = 'warn';
    public const ACTION_HIDE = 'hide';
    public const ACTION_BAN = 'ban_content';
    public const ACTION_ESCALATE = 'escalate';

    /**
     * Moderate a single flagged document using Claude Sonnet.
     *
     * @return array{action: string, reason: string, confidence: float}|null
     */
    public static function moderate(int $documentId): ?array
    {
        $doc = ContentDocument::find($documentId);
        if (!$doc) return null;

        $text = trim(($doc->title ?? '') . ' ' . ($doc->body ?? ''));
        if (empty($text)) {
            return self::logAction($documentId, self::ACTION_APPROVE, 'Empty content — auto-approved', 1.0);
        }

        // Sanitize and truncate
        $text = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F]/', '', $text);
        if (mb_strlen($text) > 2000) {
            $text = mb_substr($text, 0, 2000);
        }

        $cliPath = config('content-engine.claude.cli_path', 'claude');
        $model = config('content-engine.claude.moderation_model', 'sonnet');

        $prompt = "You are a content moderator for TAJIRI, a Tanzanian social media platform.\n\nReview this content and decide on a moderation action. Respond with ONLY a JSON object.\n\nContent type: {$doc->source_type}\nSpam score: {$doc->spam_score}\nText: {$text}\n\nJSON format:\n{\"action\": \"<approve|warn|hide|ban_content|escalate>\", \"reason\": \"<brief explanation>\", \"confidence\": <float 0-1>}\n\nGuidelines:\n- approve: Content is fine, no issues\n- warn: Minor issue, notify creator but keep visible\n- hide: Content violates guidelines, hide from feeds\n- ban_content: Serious violation, remove and flag creator\n- escalate: Needs human review (ambiguous, cultural context needed)\n\nTanzanian context:\n- Religious content is normal and expected\n- Sheng/slang is NOT profanity\n- Political discussion is allowed unless inciting violence\n- Chitenge/traditional dress is NOT inappropriate\n- Be cautious with satire — Tanzanian humor is often indirect";

        try {
            $escapedPrompt = escapeshellarg($prompt);
            $output = shell_exec("timeout 30 {$cliPath} -p {$escapedPrompt} --model {$model} --output-format text 2>/dev/null");

            if (empty($output)) {
                Log::warning("ContentModerator: empty response", ['doc' => $documentId]);
                return self::logAction($documentId, self::ACTION_ESCALATE, 'Claude unavailable — queued for human review', 0);
            }

            preg_match('/\{.*\}/s', $output, $matches);
            if (empty($matches[0])) {
                return self::logAction($documentId, self::ACTION_ESCALATE, 'Unparseable Claude response', 0, null, $output);
            }

            $result = json_decode($matches[0], true);
            if (!$result || empty($result['action'])) {
                return self::logAction($documentId, self::ACTION_ESCALATE, 'Invalid JSON structure', 0, null, $output);
            }

            $action = $result['action'];
            $reason = $result['reason'] ?? 'No reason provided';
            $confidence = max(0, min(1, (float) ($result['confidence'] ?? 0.5)));

            // Validate action
            $validActions = [self::ACTION_APPROVE, self::ACTION_WARN, self::ACTION_HIDE, self::ACTION_BAN, self::ACTION_ESCALATE];
            if (!in_array($action, $validActions)) {
                $action = self::ACTION_ESCALATE;
            }

            // Apply action to content document
            self::applyAction($doc, $action);

            return self::logAction($documentId, $action, $reason, $confidence, $model, $output);

        } catch (\Throwable $e) {
            Log::error("ContentModerator: failed", ['doc' => $documentId, 'error' => $e->getMessage()]);
            return self::logAction($documentId, self::ACTION_ESCALATE, 'Exception: ' . $e->getMessage(), 0);
        }
    }

    /**
     * Apply moderation action to the content document.
     */
    private static function applyAction(ContentDocument $doc, string $action): void
    {
        switch ($action) {
            case self::ACTION_HIDE:
                $doc->update(['content_tier' => ContentDocument::TIER_BLACKHOLE]);
                break;
            case self::ACTION_BAN:
                $doc->update(['content_tier' => ContentDocument::TIER_BLACKHOLE, 'spam_score' => 10]);
                break;
            case self::ACTION_APPROVE:
                // Reset spam score if it was elevated
                if ($doc->spam_score > 5) {
                    $doc->update(['spam_score' => max(0, $doc->spam_score - 3)]);
                    $doc->recomputeCompositeAndTier(save: true);
                }
                break;
        }
    }

    /**
     * Log moderation action and return result.
     */
    private static function logAction(int $documentId, string $action, string $reason, float $confidence, ?string $model = null, ?string $rawResponse = null): array
    {
        DB::table('moderation_log')->insert([
            'document_id' => $documentId,
            'action' => $action,
            'reason' => $reason,
            'confidence' => $confidence,
            'model_used' => $model,
            'context' => $rawResponse ? json_encode(['raw_response' => mb_substr($rawResponse, 0, 2000)]) : null,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return compact('action', 'reason', 'confidence');
    }

    /**
     * Batch moderate all flagged content.
     * Flagged = spam_score > 5 OR content with user reports (future).
     */
    public static function batchModerate(): int
    {
        // Find unmoderated flagged content
        $flagged = DB::table('content_documents')
            ->where('spam_score', '>', 5)
            ->where('content_tier', '!=', 'blackhole')
            ->whereNotExists(function ($query) {
                $query->select(DB::raw(1))
                    ->from('moderation_log')
                    ->whereColumn('moderation_log.document_id', 'content_documents.id')
                    ->where('moderation_log.created_at', '>=', now()->subDays(1));
            })
            ->orderByDesc('spam_score')
            ->limit(50)
            ->pluck('id');

        $count = 0;
        foreach ($flagged as $docId) {
            $result = self::moderate($docId);
            if ($result) $count++;
            sleep(1); // Rate limit
        }

        return $count;
    }
}
```

- [ ] **Step 2: Create ModerateContent command**

```php
<?php

namespace App\Console\Commands;

use App\Services\ContentEngine\ContentModeratorService;
use Illuminate\Console\Command;

class ModerateContent extends Command
{
    protected $signature = 'content:moderate-flagged';
    protected $description = 'Review flagged content using Claude AI moderation';

    public function handle(): int
    {
        $this->info('Moderating flagged content...');

        $count = ContentModeratorService::batchModerate();

        $this->info("Moderated {$count} flagged items");
        return Command::SUCCESS;
    }
}
```

- [ ] **Step 3: Syntax check**

```bash
php -l app/Services/ContentEngine/ContentModeratorService.php
php -l app/Console/Commands/ModerateContent.php
```

- [ ] **Step 4: Test**

```bash
php8.3 artisan content:moderate-flagged
```

Expected: "Moderated 0 flagged items" (since current content likely has low spam scores).

- [ ] **Step 5: Verify moderation_log**

```bash
php8.3 artisan tinker --execute="echo \DB::table('moderation_log')->count() . ' log entries';"
```

- [ ] **Step 6: Commit**

```bash
git add app/Services/ContentEngine/ContentModeratorService.php app/Console/Commands/ModerateContent.php
git commit -m "feat(content-engine): add ContentModeratorService — Claude Sonnet moderation with Tanzanian cultural awareness"
```

---

## Task 6: EmbeddingTextService + job — rich embedding text generation

**Files:**
- Create: `app/Services/ContentEngine/EmbeddingTextService.php`
- Create: `app/Jobs/ContentEngine/GenerateEmbeddingTextJob.php`
- Create: `app/Console/Commands/GenerateEmbeddingText.php`
- Modify: `app/Jobs/ContentEngine/ContentIngestionJob.php`

- [ ] **Step 1: Create EmbeddingTextService**

```php
<?php

namespace App\Services\ContentEngine;

use App\Models\ContentDocument;
use App\Services\ContentEngine\EmbeddingService;
use Illuminate\Support\Facades\Log;

class EmbeddingTextService
{
    /**
     * Generate rich English embedding text from raw content using Claude Haiku.
     * The generated text is used for higher-quality embeddings.
     */
    public static function generate(int $documentId): ?string
    {
        $doc = ContentDocument::find($documentId);
        if (!$doc) return null;

        $text = trim(($doc->title ?? '') . ' ' . ($doc->body ?? ''));
        if (empty($text)) return null;

        // Sanitize and truncate
        $text = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F]/', '', $text);
        if (mb_strlen($text) > 800) {
            $text = mb_substr($text, 0, 800);
        }

        $tags = is_array($doc->hashtags) ? $doc->hashtags : (is_string($doc->hashtags) ? json_decode($doc->hashtags, true) : []);
        $hashtags = is_array($tags) ? implode(', ', $tags) : '';
        $media = is_array($doc->media_types) ? $doc->media_types : (is_string($doc->media_types) ? json_decode($doc->media_types, true) : []);
        $mediaTypes = is_array($media) ? implode(', ', $media) : '';

        $cliPath = config('content-engine.claude.cli_path', 'claude');
        $model = config('content-engine.claude.embedding_model', 'haiku');

        $prompt = "Generate a rich English description for embedding this content from a Tanzanian social media platform. The description should capture the semantic meaning, context, and key topics.\n\nContent type: {$doc->source_type}\nCategory: {$doc->category}\nLanguage: {$doc->language}\nText: {$text}\nHashtags: {$hashtags}\nMedia: {$mediaTypes}\n\nWrite 2-3 sentences in English that describe what this content is about, including any cultural context. Respond with ONLY the description text, nothing else.";

        try {
            $escapedPrompt = escapeshellarg($prompt);
            $output = shell_exec("timeout 10 {$cliPath} -p {$escapedPrompt} --model {$model} --output-format text 2>/dev/null");

            if (empty($output)) {
                return null; // Fallback: embedding will use raw content
            }

            $embeddingText = trim($output);

            // Update document
            $doc->update(['embedding_text' => $embeddingText]);

            // Re-generate embedding with the richer text
            EmbeddingService::embedDocument($doc);

            return $embeddingText;

        } catch (\Throwable $e) {
            Log::warning("EmbeddingText: failed", ['doc' => $documentId, 'error' => $e->getMessage()]);
            return null; // Non-blocking fallback
        }
    }
}
```

- [ ] **Step 2: Create GenerateEmbeddingTextJob**

```php
<?php

namespace App\Jobs\ContentEngine;

use App\Services\ContentEngine\EmbeddingTextService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class GenerateEmbeddingTextJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public int $timeout = 60;
    public int $backoff = 30;

    public function __construct(public int $documentId)
    {
        $this->onQueue('content-embedding');
    }

    public function handle(): void
    {
        EmbeddingTextService::generate($this->documentId);
    }
}
```

- [ ] **Step 3: Create GenerateEmbeddingText backfill command**

```php
<?php

namespace App\Console\Commands;

use App\Jobs\ContentEngine\GenerateEmbeddingTextJob;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class GenerateEmbeddingText extends Command
{
    protected $signature = 'content:generate-embedding-text
        {--batch-size=50 : Number of documents per batch}
        {--type= : Specific source_type to process}';
    protected $description = 'Backfill embedding text for content documents missing it';

    public function handle(): int
    {
        $query = DB::table('content_documents')
            ->whereNull('embedding_text')
            ->where('content_tier', '!=', 'blackhole')
            ->whereNotNull('body');

        if ($type = $this->option('type')) {
            $query->where('source_type', $type);
        }

        $total = $query->count();
        $this->info("Found {$total} documents without embedding text");

        $batchSize = (int) $this->option('batch-size');
        $dispatched = 0;

        $query->orderByDesc('composite_score')
            ->limit($batchSize)
            ->pluck('id')
            ->each(function ($id) use (&$dispatched) {
                GenerateEmbeddingTextJob::dispatch($id);
                $dispatched++;
            });

        $this->info("Dispatched {$dispatched} embedding text jobs");
        return Command::SUCCESS;
    }
}
```

- [ ] **Step 4: Modify ContentIngestionJob to dispatch embedding text generation**

In `app/Jobs/ContentEngine/ContentIngestionJob.php`, find the line where `ClaudeScoreContentJob::dispatch($doc->id)` is called (line 55). After that line, add:

```php
            // Generate rich embedding text for better semantic search
            GenerateEmbeddingTextJob::dispatch($doc->id)->onQueue('content-embedding');
```

Also add the import at the top of the file:

```php
use App\Jobs\ContentEngine\GenerateEmbeddingTextJob;
```

- [ ] **Step 5: Syntax check all files**

```bash
php -l app/Services/ContentEngine/EmbeddingTextService.php
php -l app/Jobs/ContentEngine/GenerateEmbeddingTextJob.php
php -l app/Console/Commands/GenerateEmbeddingText.php
php -l app/Jobs/ContentEngine/ContentIngestionJob.php
```

- [ ] **Step 6: Test with a single document**

```bash
php8.3 artisan tinker --execute="
\$docId = \DB::table('content_documents')->where('source_type', 'post')->whereNotNull('body')->value('id');
echo 'Doc: ' . \$docId . PHP_EOL;
\$text = \App\Services\ContentEngine\EmbeddingTextService::generate(\$docId);
echo \$text ? 'Generated: ' . mb_substr(\$text, 0, 200) : 'No text generated';
"
```

- [ ] **Step 7: Commit**

```bash
git add app/Services/ContentEngine/EmbeddingTextService.php app/Jobs/ContentEngine/GenerateEmbeddingTextJob.php app/Console/Commands/GenerateEmbeddingText.php app/Jobs/ContentEngine/ContentIngestionJob.php
git commit -m "feat(content-engine): add EmbeddingTextService — Claude Haiku generates rich English text for better semantic embeddings"
```

---

## Task 7: Schedule all AI commands + Supervisor queue workers

**Files:**
- Modify: `routes/console.php`
- Create: `/etc/supervisor/conf.d/tajiri-workers.conf` (on server, not in git)

- [ ] **Step 1: Add schedules to routes/console.php**

Append to the end of `routes/console.php`, before the closing (or at the very end):

```php
// Content Engine Phase 5 — AI Intelligence Layer
Schedule::command('content:generate-digest')->everyFourHours()->withoutOverlapping();
Schedule::command('content:moderate-flagged')->everyThirtyMinutes()->withoutOverlapping();
Schedule::command('content:generate-coaching')->weeklyOn(0, '03:00')->withoutOverlapping(); // Sunday 3 AM
```

- [ ] **Step 2: Syntax check**

```bash
php -l routes/console.php
```

- [ ] **Step 3: Create Supervisor config** (check for existing first: `ls /etc/supervisor/conf.d/tajiri*`)

```bash
cat > /etc/supervisor/conf.d/tajiri-workers.conf << 'EOF'
[program:tajiri-default]
process_name=%(program_name)s_%(process_num)02d
command=php8.3 /var/www/tajiri.zimasystems.com/artisan queue:work redis --queue=default --sleep=3 --tries=3 --timeout=120 --max-jobs=1000
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
numprocs=2
redirect_stderr=true
stdout_logfile=/var/log/tajiri/worker-default.log
stopwaitsecs=3600

[program:tajiri-content-scoring]
process_name=%(program_name)s_%(process_num)02d
command=php8.3 /var/www/tajiri.zimasystems.com/artisan queue:work redis --queue=content-scoring --sleep=5 --tries=2 --timeout=120 --max-jobs=500
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
numprocs=1
redirect_stderr=true
stdout_logfile=/var/log/tajiri/worker-content-scoring.log
stopwaitsecs=3600

[program:tajiri-content-embedding]
process_name=%(program_name)s_%(process_num)02d
command=php8.3 /var/www/tajiri.zimasystems.com/artisan queue:work redis --queue=content-embedding --sleep=5 --tries=2 --timeout=60 --max-jobs=500
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
numprocs=1
redirect_stderr=true
stdout_logfile=/var/log/tajiri/worker-content-embedding.log
stopwaitsecs=3600
EOF
```

- [ ] **Step 4: Install and start Supervisor**

```bash
apt install -y supervisor
mkdir -p /var/log/tajiri
supervisorctl reread
supervisorctl update
supervisorctl status
```

Expected: 4 workers running (2 default, 1 content-scoring, 1 content-embedding).

- [ ] **Step 5: Verify workers are processing**

```bash
php8.3 artisan tinker --execute="echo 'Queued jobs: ' . \Illuminate\Support\Facades\Redis::llen('queues:default');"
supervisorctl status
```

- [ ] **Step 6: Commit schedule changes**

```bash
git add routes/console.php
git commit -m "feat(content-engine): add AI layer schedules — digest every 4h, moderation every 30min, coaching weekly"
```

---

## Task 8: Update health check + end-to-end verification

**Files:**
- Modify: `app/Console/Commands/ContentHealthCheck.php`

- [ ] **Step 1: Add AI subsystem checks to health check**

Read the existing `ContentHealthCheck.php`. Add checks for:
- Supervisor workers running (check `supervisorctl status` output)
- Claude CLI accessible (already checked)
- Moderation log table exists
- Latest digest age (warn if > 8h)

Add after the existing checks:

```php
// Check Supervisor workers
try {
    $output = shell_exec('supervisorctl status 2>/dev/null');
    $running = substr_count($output ?? '', 'RUNNING');
    if ($running >= 3) {
        $this->info("  ✓ Queue Workers: OK ({$running} running)");
    } else {
        $this->error("  ✗ Queue Workers: FAILED — only {$running} running");
        $allOk = false;
    }
} catch (\Throwable $e) {
    $this->error("  ✗ Queue Workers: FAILED — supervisor not accessible");
    $allOk = false;
}

// Check latest digest freshness
$latestDigest = DB::table('trending_digests')->orderByDesc('generated_at')->value('generated_at');
if ($latestDigest && now()->diffInHours($latestDigest) < 8) {
    $this->info("  ✓ Trending Digest: OK (generated " . now()->diffForHumans($latestDigest, true) . " ago)");
} elseif ($latestDigest) {
    $this->warn("  ⚠ Trending Digest: STALE (generated " . now()->diffForHumans($latestDigest, true) . " ago)");
} else {
    $this->warn("  ⚠ Trending Digest: NONE generated yet");
}
```

- [ ] **Step 2: Syntax check**

```bash
php -l app/Console/Commands/ContentHealthCheck.php
```

- [ ] **Step 3: Run full health check**

```bash
php8.3 artisan content:health-check
```

Expected: All subsystems operational including new AI checks.

- [ ] **Step 4: Run full syntax check on all Phase 5 files**

```bash
find /var/www/tajiri.zimasystems.com/app/Services/ContentEngine/ -name "*.php" -exec php -l {} \;
find /var/www/tajiri.zimasystems.com/app/Jobs/ContentEngine/ -name "*.php" -exec php -l {} \;
find /var/www/tajiri.zimasystems.com/app/Console/Commands/ -name "*.php" -exec php -l {} \;
php -l routes/console.php
```

Expected: Zero syntax errors.

- [ ] **Step 5: Test all AI features end-to-end**

```bash
# Query expansion
php8.3 artisan tinker --execute="
\$r = \App\Services\ContentEngine\QueryExpanderService::expand('biashara tanzania');
echo 'Expansion: '; print_r(\$r);
"

# Digest
php8.3 artisan content:generate-digest

# Moderation
php8.3 artisan content:moderate-flagged

# Coaching (single creator)
php8.3 artisan tinker --execute="
\$cid = \DB::table('content_documents')->whereNotNull('creator_id')->value('creator_id');
\$a = \App\Services\ContentEngine\CreatorCoachService::coachCreator(\$cid);
echo \$a ? 'OK: ' . mb_substr(\$a, 0, 100) : 'No advice';
"

# Embedding text (single doc)
php8.3 artisan tinker --execute="
\$id = \DB::table('content_documents')->where('source_type','post')->whereNotNull('body')->value('id');
\$t = \App\Services\ContentEngine\EmbeddingTextService::generate(\$id);
echo \$t ? 'OK: ' . mb_substr(\$t, 0, 100) : 'No text';
"
```

- [ ] **Step 6: Commit health check update**

```bash
git add app/Console/Commands/ContentHealthCheck.php
git commit -m "feat(content-engine): add AI layer checks to health dashboard — queue workers, digest freshness"
```

---

## Phase 5 Completion Criteria

After all 8 tasks:

- [ ] Migration applied: `embedding_text` column on `content_documents`, `moderation_log` table
- [ ] `QueryExpanderService::expand()` returns expanded queries with cross-language support, cached
- [ ] `content:generate-digest` produces Swahili trending digest stored in `trending_digests`
- [ ] `content:generate-coaching` produces weekly Swahili coaching stored in `creator_coaching`
- [ ] `content:moderate-flagged` reviews high-spam content, logs actions to `moderation_log`
- [ ] `EmbeddingTextService::generate()` produces rich English text, re-embeds via pgvector
- [ ] `ContentIngestionJob` dispatches both `ClaudeScoreContentJob` AND `GenerateEmbeddingTextJob`
- [ ] Supervisor runs 4 queue workers (2 default, 1 scoring, 1 embedding)
- [ ] Schedules configured: digest every 4h, moderation every 30min, coaching weekly
- [ ] `content:health-check` reports all AI subsystems
- [ ] All code committed, zero syntax errors

**Deferred to Phase 6:** Flutter frontend changes (ContentEngineService, UniversalSearchScreen, ContentResultCard, feed integration, event tracking).

**Cost estimate:** ~$5.76/day ($173/month) at scale with caching.
