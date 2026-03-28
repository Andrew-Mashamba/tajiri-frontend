# Content Engine Phase 3: Content Graph — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the content graph that captures relationships between content (shares, replies, stitches, mentions, hashtag co-occurrence, threads) and creators, then run PageRank to compute `content_rank` and `creator_authority` scores. Also implement near-duplicate detection via pgvector cosine similarity.

**Architecture:** A `GraphEdgeService` constructs edges from existing database relationships (posts with `original_post_id`, `reply_to_post_id`, `stitch_from_post_id`, `tagged_users`, etc.). A `ContentGraphObserver` creates edges in real-time when content is created. A `content:build-graph` artisan command backfills all edges from existing data. The existing Python `content_rank.py` script (from Phase 0) runs hourly via cron to compute PageRank and write scores back. A `content:detect-duplicates` command uses pgvector cosine similarity for near-duplicate detection.

**Tech Stack:** Laravel 12, PHP 8.3, PostgreSQL + pgvector, Python 3 + NetworkX (already installed at /opt/tajiri-graph/)

**Server access:** `sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@zima-uat.site`

**Spec reference:** `docs/superpowers/specs/2026-03-28-tajiri-content-engine-design.md` — Section 6 (Content Graph / PageRank)

**Depends on:** Phase 0 (content_graph_edges table, ContentGraphEdge model, content_rank.py, tajiri_graph DB user) and Phase 1 (content_documents with embeddings). Key existing infrastructure:
- `content_graph_edges` table: source_type, source_id, target_type, target_id, edge_type, weight, created_at (UNIQUE constraint on source+target+edge_type)
- `ContentGraphEdge` model with 8 edge type constants (SHARED, REPLIED_TO, STITCHED, MENTIONED_CREATOR, HASHTAG_CO_OCCURRENCE, SAME_THREAD, CREATOR_OF, FOLLOWED_THEN_CREATED)
- `/opt/tajiri-graph/content_rank.py` — Python PageRank script with retry logic, reads edges, writes content_rank + creator_authority back to PG
- `posts` columns: `original_post_id` (shares), `reply_to_post_id` (replies), `stitch_from_post_id` (stitches), `tagged_users` (mentions), `content_tags` (hashtags)
- `clips` columns: `original_clip_id` (clip shares)
- `gossip_threads.seed_post_id` (thread seed)
- `content_documents.embedding` — 768-dim pgvector column for cosine similarity
- 14 posts, 0 edges currently (fresh platform — edges will grow as users create content)

---

## File Map

### Backend (on server: /var/www/html/tajiri/)

| Action | File | Purpose |
|---|---|---|
| Create | `app/Services/ContentEngine/GraphEdgeService.php` | Build edges from relationships (share, reply, stitch, mention, hashtag, thread, creator) |
| Create | `app/Services/ContentEngine/DuplicateDetectionService.php` | Near-duplicate detection via pgvector cosine similarity |
| Create | `app/Observers/ContentGraphObserver.php` | Real-time edge creation on content create/update |
| Modify | `app/Providers/AppServiceProvider.php` | Register ContentGraphObserver |
| Create | `app/Console/Commands/BuildGraph.php` | `content:build-graph` — backfill all edges from existing data |
| Create | `app/Console/Commands/DetectDuplicates.php` | `content:detect-duplicates` — find and penalize near-duplicates |
| Modify | `routes/console.php` | Add cron for PageRank and duplicate detection |
| Modify | `/opt/tajiri-graph/content_rank.py` | Minor: add scores_updated_at update on write-back |

---

## Task 1: GraphEdgeService — Build Edges from Relationships

**Files:**
- Create: `app/Services/ContentEngine/GraphEdgeService.php`

- [ ] **Step 1: Write GraphEdgeService**

Write `app/Services/ContentEngine/GraphEdgeService.php`:

```php
<?php

namespace App\Services\ContentEngine;

use App\Models\ContentDocument;
use App\Models\ContentGraphEdge;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class GraphEdgeService
{
    /**
     * Build all graph edges for a single post.
     * Called by observer on post create and by backfill command.
     */
    public static function buildEdgesForPost(\App\Models\Post $post): int
    {
        $edges = 0;
        $docId = self::getDocId('post', $post->id);
        if (!$docId) return 0;

        // CREATOR_OF: creator → doc
        $edges += self::upsertEdge('creator', $post->user_id, 'doc', $docId, ContentGraphEdge::EDGE_CREATOR_OF, 1.0);

        // SHARED: sharer → original
        if ($post->original_post_id) {
            $originalDocId = self::getDocId('post', $post->original_post_id);
            if ($originalDocId) {
                $edges += self::upsertEdge('doc', $docId, 'doc', $originalDocId, ContentGraphEdge::EDGE_SHARED, 3.0);
            }
        }

        // REPLIED_TO: reply → parent
        if ($post->reply_to_post_id) {
            $parentDocId = self::getDocId('post', $post->reply_to_post_id);
            if ($parentDocId) {
                $edges += self::upsertEdge('doc', $docId, 'doc', $parentDocId, ContentGraphEdge::EDGE_REPLIED_TO, 2.5);
            }
        }

        // STITCHED: stitch → original
        if ($post->stitch_from_post_id) {
            $stitchDocId = self::getDocId('post', $post->stitch_from_post_id);
            if ($stitchDocId) {
                $edges += self::upsertEdge('doc', $docId, 'doc', $stitchDocId, ContentGraphEdge::EDGE_STITCHED, 2.0);
            }
        }

        // MENTIONED_CREATOR: post → mentioned creator
        if ($post->tagged_users) {
            $taggedIds = is_array($post->tagged_users) ? $post->tagged_users : json_decode($post->tagged_users, true);
            if (is_array($taggedIds)) {
                foreach (array_slice($taggedIds, 0, 10) as $mentionedId) {
                    $edges += self::upsertEdge('doc', $docId, 'creator', (int) $mentionedId, ContentGraphEdge::EDGE_MENTIONED_CREATOR, 1.5);
                }
            }
        }

        // HASHTAG_CO_OCCURRENCE: find other recent posts with same hashtags
        if ($post->content_tags) {
            $tags = is_array($post->content_tags) ? $post->content_tags : json_decode($post->content_tags, true);
            if (is_array($tags) && !empty($tags)) {
                $edges += self::buildHashtagCoOccurrence($docId, $tags, $post->id);
            }
        }

        return $edges;
    }

    /**
     * Build edges for a clip (shares via original_clip_id).
     */
    public static function buildEdgesForClip(\App\Models\Clip $clip): int
    {
        $edges = 0;
        $docId = self::getDocId('clip', $clip->id);
        if (!$docId) return 0;

        // CREATOR_OF
        $edges += self::upsertEdge('creator', $clip->user_id, 'doc', $docId, ContentGraphEdge::EDGE_CREATOR_OF, 1.0);

        // SHARED (clip share)
        if ($clip->original_clip_id) {
            $originalDocId = self::getDocId('clip', $clip->original_clip_id);
            if ($originalDocId) {
                $edges += self::upsertEdge('doc', $docId, 'doc', $originalDocId, ContentGraphEdge::EDGE_SHARED, 3.0);
            }
        }

        return $edges;
    }

    /**
     * Build SAME_THREAD edges for posts in a gossip thread.
     */
    public static function buildEdgesForGossipThread(\App\Models\GossipThread $thread): int
    {
        $edges = 0;

        // Get all posts in this thread
        $seedDocId = self::getDocId('post', $thread->seed_post_id);
        if (!$seedDocId) return 0;

        // Link the gossip_thread document to the seed post
        $threadDocId = self::getDocId('gossip_thread', $thread->id);
        if ($threadDocId) {
            $edges += self::upsertEdge('doc', $threadDocId, 'doc', $seedDocId, ContentGraphEdge::EDGE_SAME_THREAD, 1.0);
        }

        return $edges;
    }

    /**
     * Build CREATOR_OF edge for any content type.
     */
    public static function buildCreatorEdge(string $sourceType, int $sourceId, int $creatorId): int
    {
        $docId = self::getDocId($sourceType, $sourceId);
        if (!$docId) return 0;

        return self::upsertEdge('creator', $creatorId, 'doc', $docId, ContentGraphEdge::EDGE_CREATOR_OF, 1.0);
    }

    /**
     * Build FOLLOWED_THEN_CREATED edge (content earned a follow).
     * Called when a follow event is detected after viewing content.
     */
    public static function buildFollowedThenCreated(int $docId, int $creatorId): int
    {
        return self::upsertEdge('doc', $docId, 'creator', $creatorId, ContentGraphEdge::EDGE_FOLLOWED_THEN_CREATED, 2.0);
    }

    /**
     * Build hashtag co-occurrence edges.
     * Links this doc to up to 5 recent docs sharing the same hashtags.
     */
    private static function buildHashtagCoOccurrence(int $docId, array $tags, int $postId): int
    {
        $edges = 0;

        // Find recent documents with overlapping hashtags (last 7 days)
        // hashtags is jsonb array — check overlap with jsonb_array_elements
        $tagsJson = json_encode(array_values($tags));
        $recentDocs = DB::select("
            SELECT id, hashtags FROM content_documents
            WHERE id != ? AND published_at >= NOW() - INTERVAL '7 days'
              AND hashtags IS NOT NULL
              AND EXISTS (
                SELECT 1 FROM jsonb_array_elements_text(hashtags) AS h
                WHERE h = ANY(SELECT jsonb_array_elements_text(?::jsonb))
              )
            LIMIT 50
        ", [$docId, $tagsJson]);

        foreach ($recentDocs as $otherDoc) {
            $otherTags = json_decode($otherDoc->hashtags, true) ?? [];
            $overlap = array_intersect($tags, $otherTags);
            if (!empty($overlap)) {
                // Weight by overlap count (0.5 base * overlap)
                $weight = min(2.0, 0.5 * count($overlap));
                $edges += self::upsertEdge('doc', $docId, 'doc', $otherDoc->id, ContentGraphEdge::EDGE_HASHTAG_CO_OCCURRENCE, $weight);
                if ($edges >= 5) break; // Limit co-occurrence edges per doc
            }
        }

        return $edges;
    }

    /**
     * Get the content_documents.id for a source_type + source_id.
     */
    private static function getDocId(string $sourceType, int $sourceId): ?int
    {
        return ContentDocument::where('source_type', $sourceType)
            ->where('source_id', $sourceId)
            ->value('id');
    }

    /**
     * Upsert a graph edge (insert or ignore on unique constraint).
     * Returns 1 if inserted, 0 if already existed.
     */
    private static function upsertEdge(
        string $sourceType,
        int $sourceId,
        string $targetType,
        int $targetId,
        string $edgeType,
        float $weight
    ): int {
        try {
            $edge = ContentGraphEdge::firstOrCreate(
                [
                    'source_type' => $sourceType,
                    'source_id' => $sourceId,
                    'target_type' => $targetType,
                    'target_id' => $targetId,
                    'edge_type' => $edgeType,
                ],
                [
                    'weight' => $weight,
                    'created_at' => now(),
                ]
            );
            return $edge->wasRecentlyCreated ? 1 : 0;
        } catch (\Throwable $e) {
            Log::warning("GraphEdgeService: edge upsert failed", [
                'edge' => "{$sourceType}:{$sourceId} → {$targetType}:{$targetId} ({$edgeType})",
                'error' => $e->getMessage(),
            ]);
            return 0;
        }
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
php -l app/Services/ContentEngine/GraphEdgeService.php
```

- [ ] **Step 3: Commit**

```bash
git add app/Services/ContentEngine/GraphEdgeService.php
git commit -m "feat(content-engine): add GraphEdgeService — builds graph edges from content relationships"
```

---

## Task 2: DuplicateDetectionService — pgvector Cosine Similarity

**Files:**
- Create: `app/Services/ContentEngine/DuplicateDetectionService.php`

- [ ] **Step 1: Write DuplicateDetectionService**

Write `app/Services/ContentEngine/DuplicateDetectionService.php`:

```php
<?php

namespace App\Services\ContentEngine;

use App\Models\ContentDocument;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DuplicateDetectionService
{
    /**
     * Find near-duplicates for a document using pgvector cosine similarity.
     * Returns array of [id, source_type, source_id, creator_id, similarity].
     */
    public static function findDuplicates(int $docId, float $threshold = 0.95, int $limit = 5): array
    {
        $doc = ContentDocument::find($docId);
        if (!$doc || !$doc->embedding) return [];

        // Use pgvector cosine distance operator (<=>)
        // ORDER BY distance ASC enables HNSW index usage; filter threshold in PHP
        $results = DB::select("
            WITH ref AS (SELECT embedding FROM content_documents WHERE id = ?)
            SELECT id, source_type, source_id, creator_id,
                   1 - (embedding <=> (SELECT embedding FROM ref)) as similarity
            FROM content_documents
            WHERE id != ?
              AND embedding IS NOT NULL
              AND content_tier != 'blackhole'
            ORDER BY embedding <=> (SELECT embedding FROM ref) ASC
            LIMIT ?
        ", [$docId, $docId, $limit]);

        // Filter by threshold in PHP (WHERE clause arithmetic prevents HNSW index usage)
        return array_map(
            fn($r) => (array) $r,
            array_filter($results, fn($r) => $r->similarity >= $threshold)
        );
    }

    /**
     * Check a single document for duplicates and apply penalties.
     * - Newer duplicate gets quality_score penalty (-3 points)
     * - Same creator duplicating → potential spam flag
     * - Older document treated as canonical (no penalty)
     */
    public static function checkAndPenalize(int $docId, float $threshold = 0.95): array
    {
        $doc = ContentDocument::find($docId);
        if (!$doc) return ['checked' => false, 'duplicates' => 0];

        $duplicates = self::findDuplicates($docId, $threshold);
        $penalized = 0;

        foreach ($duplicates as $dup) {
            $dupDoc = ContentDocument::find($dup['id']);
            if (!$dupDoc) continue;

            // Newer duplicate gets penalized
            if ($doc->published_at && $dupDoc->published_at) {
                if ($doc->published_at > $dupDoc->published_at) {
                    // This doc is newer → penalize it
                    $doc->quality_score = max(0, $doc->quality_score - 3);

                    // Same creator = potential spam
                    if ($doc->creator_id === $dupDoc->creator_id) {
                        $doc->spam_score = min(10, $doc->spam_score + 2);
                        Log::info("Duplicate detection: same-creator duplicate flagged", [
                            'doc' => $docId,
                            'duplicate_of' => $dup['id'],
                            'creator' => $doc->creator_id,
                            'similarity' => $dup['similarity'],
                        ]);
                    }

                    $doc->recomputeCompositeAndTier(save: true);
                    $penalized++;
                }
            }
        }

        return [
            'checked' => true,
            'duplicates' => count($duplicates),
            'penalized' => $penalized,
        ];
    }

    /**
     * Batch scan recent documents for duplicates.
     * Used by the scheduled command.
     */
    public static function batchScan(int $hours = 24, float $threshold = 0.95, int $batchSize = 100): array
    {
        $stats = ['scanned' => 0, 'duplicates_found' => 0, 'penalized' => 0];

        ContentDocument::where('published_at', '>=', now()->subHours($hours))
            ->whereNotNull('embedding')
            ->where('content_tier', '!=', 'blackhole')
            ->orderBy('id', 'desc')
            ->chunk($batchSize, function ($docs) use (&$stats, $threshold) {
                foreach ($docs as $doc) {
                    $result = self::checkAndPenalize($doc->id, $threshold);
                    $stats['scanned']++;
                    $stats['duplicates_found'] += $result['duplicates'] ?? 0;
                    $stats['penalized'] += $result['penalized'] ?? 0;
                }
            });

        return $stats;
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
php -l app/Services/ContentEngine/DuplicateDetectionService.php
```

- [ ] **Step 3: Commit**

```bash
git add app/Services/ContentEngine/DuplicateDetectionService.php
git commit -m "feat(content-engine): add DuplicateDetectionService — pgvector cosine similarity near-duplicate detection"
```

---

## Task 3: ContentGraphObserver — Real-Time Edge Creation

**Files:**
- Create: `app/Observers/ContentGraphObserver.php`
- Modify: `app/Providers/AppServiceProvider.php`

- [ ] **Step 1: Write ContentGraphObserver**

Write `app/Observers/ContentGraphObserver.php`:

```php
<?php

namespace App\Observers;

use App\Services\ContentEngine\GraphEdgeService;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Log;

class ContentGraphObserver
{
    public function created(Model $model): void
    {
        $this->buildEdges($model);
    }

    public function updated(Model $model): void
    {
        // Only rebuild edges if relationship columns changed
        if ($model instanceof \App\Models\Post) {
            $changed = $model->isDirty([
                'original_post_id', 'reply_to_post_id', 'stitch_from_post_id',
                'tagged_users', 'content_tags',
            ]);
            if (!$changed) return;
        }

        $this->buildEdges($model);
    }

    private function buildEdges(Model $model): void
    {
        try {
            if ($model instanceof \App\Models\Post) {
                // Skip drafts
                if ($model->is_draft || $model->status === 'draft') return;
                GraphEdgeService::buildEdgesForPost($model);
            } elseif ($model instanceof \App\Models\Clip) {
                GraphEdgeService::buildEdgesForClip($model);
            } elseif ($model instanceof \App\Models\GossipThread) {
                GraphEdgeService::buildEdgesForGossipThread($model);
            } else {
                // For other content types, just build CREATOR_OF edge
                $sourceType = match (true) {
                    $model instanceof \App\Models\Story => 'story',
                    $model instanceof \App\Models\MusicTrack => 'music',
                    $model instanceof \App\Models\LiveStream => 'stream',
                    $model instanceof \App\Models\Event => 'event',
                    $model instanceof \App\Models\Campaign => 'campaign',
                    $model instanceof \App\Models\Shop\Product => 'product',
                    default => null,
                };
                if ($sourceType && isset($model->user_id)) {
                    GraphEdgeService::buildCreatorEdge($sourceType, $model->id, $model->user_id);
                }
            }
        } catch (\Throwable $e) {
            // Graph edge creation is non-critical
            Log::warning("ContentGraphObserver: edge creation failed", [
                'model' => get_class($model),
                'id' => $model->id,
                'error' => $e->getMessage(),
            ]);
        }
    }
}
```

- [ ] **Step 2: Fix ContentDocument graphEdgesAsSource/AsTarget relations**

In `app/Models/ContentDocument.php`, find the `graphEdgesAsSource()` and `graphEdgesAsTarget()` relations. They use `source_type = 'document'` but the actual edges use `'doc'` and `'creator'`. Fix:

```php
public function graphEdgesAsSource()
{
    return $this->hasMany(ContentGraphEdge::class, 'source_id')
        ->where('source_type', 'doc');
}

public function graphEdgesAsTarget()
{
    return $this->hasMany(ContentGraphEdge::class, 'target_id')
        ->where('target_type', 'doc');
}
```

- [ ] **Step 3: Register observer in AppServiceProvider**

Read `app/Providers/AppServiceProvider.php` and add inside the `boot()` method (after the ContentIngestionObserver registrations):

```php
        // Content Engine: observe content models for graph edge creation
        $graphObserver = \App\Observers\ContentGraphObserver::class;
        \App\Models\Post::observe($graphObserver);
        \App\Models\Clip::observe($graphObserver);
        \App\Models\GossipThread::observe($graphObserver);
        \App\Models\Story::observe($graphObserver);
        \App\Models\MusicTrack::observe($graphObserver);
        \App\Models\LiveStream::observe($graphObserver);
        \App\Models\Event::observe($graphObserver);
        \App\Models\Campaign::observe($graphObserver);
        \App\Models\Shop\Product::observe($graphObserver);
```

- [ ] **Step 4: Syntax check**

```bash
php -l app/Observers/ContentGraphObserver.php
php -l app/Providers/AppServiceProvider.php
php -l app/Models/ContentDocument.php
```

- [ ] **Step 5: Commit**

```bash
git add app/Observers/ContentGraphObserver.php app/Providers/AppServiceProvider.php app/Models/ContentDocument.php
git commit -m "feat(content-engine): add ContentGraphObserver, fix graph edge relations — real-time edge creation on content changes"
```

---

## Task 4: BuildGraph Command — Backfill All Edges

**Files:**
- Create: `app/Console/Commands/BuildGraph.php`

- [ ] **Step 1: Write BuildGraph command**

Write `app/Console/Commands/BuildGraph.php`:

```php
<?php

namespace App\Console\Commands;

use App\Models\Clip;
use App\Models\ContentDocument;
use App\Models\GossipThread;
use App\Models\Post;
use App\Services\ContentEngine\GraphEdgeService;
use Illuminate\Console\Command;

class BuildGraph extends Command
{
    protected $signature = 'content:build-graph
                            {--type= : Only build for a specific type (posts, clips, gossip, creators)}
                            {--batch-size=100 : Records per batch}';
    protected $description = 'Backfill content_graph_edges from existing content relationships';

    public function handle(): int
    {
        $type = $this->option('type');
        $batchSize = (int) $this->option('batch-size');
        $totalEdges = 0;

        $types = $type ? [$type] : ['posts', 'clips', 'gossip', 'creators'];

        foreach ($types as $typeName) {
            $this->info("Building edges for {$typeName}...");
            $edges = match ($typeName) {
                'posts' => $this->buildPostEdges($batchSize),
                'clips' => $this->buildClipEdges($batchSize),
                'gossip' => $this->buildGossipEdges($batchSize),
                'creators' => $this->buildCreatorEdges($batchSize),
                default => 0,
            };
            $this->info("  {$edges} edges created");
            $totalEdges += $edges;
        }

        $this->info("Total edges created: {$totalEdges}");
        $edgeCount = \App\Models\ContentGraphEdge::count();
        $this->info("Total edges in graph: {$edgeCount}");

        return 0;
    }

    private function buildPostEdges(int $batchSize): int
    {
        $edges = 0;
        Post::where(function ($q) {
            $q->where('is_draft', false)->orWhereNull('is_draft');
        })->orderBy('id')->chunk($batchSize, function ($posts) use (&$edges) {
            foreach ($posts as $post) {
                $edges += GraphEdgeService::buildEdgesForPost($post);
            }
        });
        return $edges;
    }

    private function buildClipEdges(int $batchSize): int
    {
        $edges = 0;
        Clip::orderBy('id')->chunk($batchSize, function ($clips) use (&$edges) {
            foreach ($clips as $clip) {
                $edges += GraphEdgeService::buildEdgesForClip($clip);
            }
        });
        return $edges;
    }

    private function buildGossipEdges(int $batchSize): int
    {
        $edges = 0;
        GossipThread::orderBy('id')->chunk($batchSize, function ($threads) use (&$edges) {
            foreach ($threads as $thread) {
                $edges += GraphEdgeService::buildEdgesForGossipThread($thread);
            }
        });
        return $edges;
    }

    private function buildCreatorEdges(int $batchSize): int
    {
        $edges = 0;
        // Build CREATOR_OF edges for all content types
        ContentDocument::whereNotNull('creator_id')
            ->orderBy('id')
            ->chunk($batchSize, function ($docs) use (&$edges) {
                foreach ($docs as $doc) {
                    $edges += GraphEdgeService::buildCreatorEdge(
                        $doc->source_type,
                        $doc->source_id,
                        $doc->creator_id
                    );
                }
            });
        return $edges;
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
php -l app/Console/Commands/BuildGraph.php
```

- [ ] **Step 3: Commit**

```bash
git add app/Console/Commands/BuildGraph.php
git commit -m "feat(content-engine): add content:build-graph command — backfill graph edges from existing relationships"
```

---

## Task 5: DetectDuplicates Command

**Files:**
- Create: `app/Console/Commands/DetectDuplicates.php`

- [ ] **Step 1: Write DetectDuplicates command**

Write `app/Console/Commands/DetectDuplicates.php`:

```php
<?php

namespace App\Console\Commands;

use App\Services\ContentEngine\DuplicateDetectionService;
use Illuminate\Console\Command;

class DetectDuplicates extends Command
{
    protected $signature = 'content:detect-duplicates
                            {--hours=24 : Scan content from the last N hours}
                            {--threshold=0.95 : Cosine similarity threshold}';
    protected $description = 'Scan recent content for near-duplicates using pgvector cosine similarity';

    public function handle(): int
    {
        $hours = (int) $this->option('hours');
        $threshold = (float) $this->option('threshold');
        $this->info("Scanning content from the last {$hours} hours for near-duplicates (threshold: {$threshold})...");

        $stats = DuplicateDetectionService::batchScan($hours, threshold: $threshold);

        $this->info("Scanned: {$stats['scanned']}");
        $this->info("Duplicates found: {$stats['duplicates_found']}");
        $this->info("Penalized: {$stats['penalized']}");

        return 0;
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
php -l app/Console/Commands/DetectDuplicates.php
```

- [ ] **Step 3: Commit**

```bash
git add app/Console/Commands/DetectDuplicates.php
git commit -m "feat(content-engine): add content:detect-duplicates command — pgvector cosine similarity scan"
```

---

## Task 6: Update content_rank.py + Schedule + Cron

**Files:**
- Modify: `/opt/tajiri-graph/content_rank.py`
- Modify: `routes/console.php` (on server at `/var/www/html/tajiri/routes/console.php`)

- [ ] **Step 1: Grant UPDATE permission on scores_updated_at to tajiri_graph user**

Phase 0 only granted UPDATE on `content_rank` and `creator_authority`. We need `scores_updated_at` too:

```bash
sudo -u postgres psql -d tajiri -c "GRANT UPDATE (scores_updated_at) ON content_documents TO tajiri_graph;"
```

- [ ] **Step 2: Update content_rank.py to set scores_updated_at**

Read the current script first to verify exact code. Then modify the batch update section. After the `UPDATE content_documents SET content_rank = %s WHERE id = %s` line, also update `scores_updated_at`:

Change:
```python
cur.executemany(
    "UPDATE content_documents SET content_rank = %s WHERE id = %s",
    doc_scores
)
```

To:
```python
cur.executemany(
    "UPDATE content_documents SET content_rank = %s, scores_updated_at = NOW() WHERE id = %s",
    doc_scores
)
```

And change:
```python
cur.execute(
    "UPDATE content_documents SET creator_authority = %s WHERE creator_id = %s",
    (authority, creator_id)
)
```

To:
```python
cur.execute(
    "UPDATE content_documents SET creator_authority = %s, scores_updated_at = NOW() WHERE creator_id = %s",
    (authority, creator_id)
)
```

- [ ] **Step 3: Add cron for PageRank (hourly)**

```bash
# Add hourly cron for content_rank.py
(crontab -l 2>/dev/null; echo "0 * * * * cd /opt/tajiri-graph && /opt/tajiri-graph/venv/bin/python content_rank.py >> /var/log/tajiri/content_rank_cron.log 2>&1") | crontab -
```

- [ ] **Step 4: Add schedule entries to routes/console.php**

Append to `routes/console.php`:

```php

// Content Engine Phase 3 — Graph schedules
Schedule::command('content:detect-duplicates')->hourly()->withoutOverlapping();
Schedule::command('content:build-graph --type=posts')->dailyAt('02:00')->withoutOverlapping();
```

- [ ] **Step 5: Syntax check console.php**

```bash
php -l routes/console.php
```

- [ ] **Step 6: Create log file**

```bash
touch /var/log/tajiri/content_rank_cron.log
chown www-data:www-data /var/log/tajiri/content_rank_cron.log
```

- [ ] **Step 7: Commit**

```bash
cd /var/www/html/tajiri
git add routes/console.php
git commit -m "feat(content-engine): add graph schedules — hourly duplicate detection, daily graph rebuild"
```

---

## Task 7: Backfill Graph + Run PageRank + Verify

- [ ] **Step 1: Build graph edges from existing data**

```bash
cd /var/www/html/tajiri
php artisan content:build-graph
```

- [ ] **Step 2: Check edge count**

```bash
php artisan tinker --execute="
echo 'Total edges: ' . \App\Models\ContentGraphEdge::count() . PHP_EOL;
echo 'By type: ' . json_encode(\App\Models\ContentGraphEdge::selectRaw('edge_type, count(*) as cnt')->groupBy('edge_type')->pluck('cnt','edge_type')) . PHP_EOL;
"
```

- [ ] **Step 3: Run PageRank**

```bash
cd /opt/tajiri-graph
/opt/tajiri-graph/venv/bin/python content_rank.py
cat /var/log/tajiri/content_rank.log | tail -5
```

- [ ] **Step 4: Verify content_rank was written back**

```bash
cd /var/www/html/tajiri
php artisan tinker --execute="
\$withRank = \App\Models\ContentDocument::where('content_rank', '>', 0)->count();
\$total = \App\Models\ContentDocument::count();
echo \"Documents with content_rank > 0: {\$withRank}/{\$total}\" . PHP_EOL;
echo 'Top 5 by content_rank: ' . PHP_EOL;
\App\Models\ContentDocument::where('content_rank', '>', 0)->orderByDesc('content_rank')->limit(5)->get(['id','source_type','source_id','content_rank','creator_authority'])->each(fn(\$d) => print(\"  {\$d->source_type}:{\$d->source_id} rank={\$d->content_rank} authority={\$d->creator_authority}\" . PHP_EOL));
"
```

- [ ] **Step 5: Run duplicate detection**

```bash
php artisan content:detect-duplicates --hours=720
```

- [ ] **Step 6: Run health check**

```bash
php artisan content:health-check
```

- [ ] **Step 7: Run reconciliation**

```bash
php artisan content:reconcile
```

No git commit needed for this step (verification only).

---

## Phase 3 Completion Criteria

After all 7 tasks:

- [ ] GraphEdgeService builds edges for all 8 edge types (SHARED, REPLIED_TO, STITCHED, MENTIONED_CREATOR, HASHTAG_CO_OCCURRENCE, SAME_THREAD, CREATOR_OF, FOLLOWED_THEN_CREATED)
- [ ] ContentGraphObserver creates edges in real-time on content create/update
- [ ] DuplicateDetectionService finds near-duplicates via pgvector cosine similarity > 0.95
- [ ] Duplicate penalty: newer duplicate gets -3 quality_score, same-creator gets +2 spam_score
- [ ] `content:build-graph` backfills all edges from existing relationships
- [ ] `content:detect-duplicates` scans recent content for near-duplicates
- [ ] `content_rank.py` runs hourly via cron, computes PageRank, writes content_rank + creator_authority back
- [ ] Cron entries installed (PageRank hourly, duplicate detection hourly, graph rebuild daily at 2am)
- [ ] All code committed

**Deferred to Phase 4:** Serving Pipeline (search API, feed API, candidate generation, personalized scoring, re-ranking, caching).

**Next:** Phase 4 — Serving Pipeline (query understanding, candidate generation, personalized scoring, re-ranking, API endpoints)
