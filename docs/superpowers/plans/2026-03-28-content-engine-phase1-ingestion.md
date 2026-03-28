# Content Engine Phase 1: Ingestion Pipeline — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the ingestion pipeline that converts every content creation/update/delete into a unified ContentDocument, syncs to Typesense, generates embeddings, and scores with Claude AI — then backfill all existing content.

**Architecture:** When content is created or updated, a model observer dispatches `ContentIngestionJob` which uses `ContentDocumentFactory` to normalize the source record into a `content_documents` row. Three fan-out jobs then fire: `SyncToTypesenseJob` (search index), `GenerateEmbeddingJob` (vector), and `ClaudeScoreContentJob` (AI quality). A `content:reindex` artisan command backfills existing data. All jobs run on dedicated Redis queues managed by Supervisor.

**Tech Stack:** Laravel 12, PHP 8.3, PostgreSQL + pgvector, Typesense 27.1, Redis queues, Python embedding service (port 8200), Claude CLI

**Server access:** `sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@zima-uat.site`

**Spec reference:** `docs/superpowers/specs/2026-03-28-tajiri-content-engine-design.md` — Sections 3 (Ingestion) and 4 (Indexing)

**Depends on:** Phase 0 complete (Typesense running, pgvector enabled, embedding service running, tables created, models exist, `config/content-engine.php` created with all service coordinates)

---

## File Map

### Backend (on server: /var/www/html/tajiri/)

| Action | File | Purpose |
|---|---|---|
| Create | `app/Services/ContentEngine/ContentDocumentFactory.php` | Maps 12 source types → ContentDocument fields |
| Create | `app/Services/ContentEngine/LanguageDetector.php` | Swahili/English detection via word frequency |
| Create | `app/Services/ContentEngine/TypesenseService.php` | Typesense HTTP client (upsert, delete, search) |
| Create | `app/Services/ContentEngine/EmbeddingService.php` | Embedding microservice HTTP client |
| Create | `app/Jobs/ContentEngine/ContentIngestionJob.php` | Main ingestion job: extract → normalize → upsert |
| Create | `app/Jobs/ContentEngine/SyncToTypesenseJob.php` | Sync document to Typesense search index |
| Create | `app/Jobs/ContentEngine/GenerateEmbeddingJob.php` | Generate + store 768-dim embedding |
| Create | `app/Jobs/ContentEngine/ClaudeScoreContentJob.php` | AI quality + spam scoring via Claude CLI |
| Create | `app/Jobs/ContentEngine/DeleteContentDocumentJob.php` | Remove from content_documents + Typesense |
| Create | `app/Observers/ContentIngestionObserver.php` | Model observer dispatching ingestion jobs |
| Create | `app/Console/Commands/ContentReindex.php` | `content:reindex` backfill command |
| Create | `app/Console/Commands/ContentReconcile.php` | `content:reconcile` integrity check |
| Modify | `app/Providers/AppServiceProvider.php` | Register ContentIngestionObserver on all 12 models |
| Create | `/etc/supervisor/conf.d/content-engine.conf` | Supervisor config for 4 queue workers |

---

## Task 1: ContentDocumentFactory — Source Type Mappers

**Files:**
- Create: `app/Services/ContentEngine/ContentDocumentFactory.php`
- Create: `app/Services/ContentEngine/LanguageDetector.php`

- [ ] **Step 1: Create the ContentEngine services directory**

```bash
ssh root@zima-uat.site
mkdir -p /var/www/html/tajiri/app/Services/ContentEngine
```

- [ ] **Step 2: Write LanguageDetector**

Write `app/Services/ContentEngine/LanguageDetector.php`:

```php
<?php

namespace App\Services\ContentEngine;

class LanguageDetector
{
    /**
     * Common Swahili words for frequency-based detection.
     */
    private const SWAHILI_MARKERS = [
        'na', 'ya', 'wa', 'ni', 'kwa', 'katika', 'hii', 'huo', 'yake',
        'wake', 'kwamba', 'lakini', 'pia', 'sana', 'kupitia', 'baada',
        'kabla', 'mpaka', 'tangu', 'kama', 'ili', 'ingawa', 'kwani',
        'habari', 'asante', 'karibu', 'ndio', 'hapana', 'ndiyo',
        'leo', 'kesho', 'jana', 'sasa', 'bado', 'tayari', 'pamoja',
        'watu', 'mtu', 'nyumba', 'kazi', 'shule', 'dada', 'kaka',
        'mama', 'baba', 'mtoto', 'watoto', 'rafiki', 'marafiki',
    ];

    /**
     * Detect language from text. Returns 'sw' for Swahili, 'en' for English.
     */
    public static function detect(?string $text): ?string
    {
        if (empty($text)) {
            return null;
        }

        $words = preg_split('/\s+/', mb_strtolower(strip_tags($text)));
        $totalWords = count($words);

        if ($totalWords < 3) {
            return null;
        }

        $swahiliCount = 0;
        foreach ($words as $word) {
            $cleaned = preg_replace('/[^a-z]/', '', $word);
            if (in_array($cleaned, self::SWAHILI_MARKERS, true)) {
                $swahiliCount++;
            }
        }

        $ratio = $swahiliCount / $totalWords;

        return $ratio > 0.15 ? 'sw' : 'en';
    }
}
```

- [ ] **Step 3: Write ContentDocumentFactory**

Write `app/Services/ContentEngine/ContentDocumentFactory.php`:

```php
<?php

namespace App\Services\ContentEngine;

use App\Models\Campaign;
use App\Models\Clip;
use App\Models\ContentDocument;
use App\Models\Event;
use App\Models\GossipThread;
use App\Models\Group;
use App\Models\LiveStream;
use App\Models\MusicTrack;
use App\Models\Page;
use App\Models\Post;
use App\Models\Product;
use App\Models\Story;
use App\Models\UserProfile;
use Illuminate\Database\Eloquent\Model;

class ContentDocumentFactory
{
    /**
     * Build ContentDocument attributes from any source model.
     *
     * @return array<string, mixed> Attributes for ContentDocument::updateOrCreate()
     */
    public static function fromModel(Model $model): array
    {
        return match (true) {
            $model instanceof Post => self::fromPost($model),
            $model instanceof Clip => self::fromClip($model),
            $model instanceof Story => self::fromStory($model),
            $model instanceof MusicTrack => self::fromMusic($model),
            $model instanceof LiveStream => self::fromStream($model),
            $model instanceof Event => self::fromEvent($model),
            $model instanceof Campaign => self::fromCampaign($model),
            $model instanceof Product => self::fromProduct($model),
            $model instanceof Group => self::fromGroup($model),
            $model instanceof Page => self::fromPage($model),
            $model instanceof UserProfile => self::fromUserProfile($model),
            $model instanceof GossipThread => self::fromGossipThread($model),
            default => throw new \InvalidArgumentException('Unsupported model: ' . get_class($model)),
        };
    }

    /**
     * Resolve the source_type string for a model.
     */
    public static function sourceType(Model $model): string
    {
        return match (true) {
            $model instanceof Post => ContentDocument::TYPE_POST,
            $model instanceof Clip => ContentDocument::TYPE_CLIP,
            $model instanceof Story => ContentDocument::TYPE_STORY,
            $model instanceof MusicTrack => ContentDocument::TYPE_MUSIC,
            $model instanceof LiveStream => ContentDocument::TYPE_STREAM,
            $model instanceof Event => ContentDocument::TYPE_EVENT,
            $model instanceof Campaign => ContentDocument::TYPE_CAMPAIGN,
            $model instanceof Product => ContentDocument::TYPE_PRODUCT,
            $model instanceof Group => ContentDocument::TYPE_GROUP,
            $model instanceof Page => ContentDocument::TYPE_PAGE,
            $model instanceof UserProfile => ContentDocument::TYPE_USER_PROFILE,
            $model instanceof GossipThread => ContentDocument::TYPE_GOSSIP_THREAD,
            default => throw new \InvalidArgumentException('Unsupported model: ' . get_class($model)),
        };
    }

    private static function fromPost(Post $post): array
    {
        $mediaTypes = [];
        if ($post->media && $post->media->count() > 0) {
            $mediaTypes = $post->media->pluck('type')->unique()->values()->toArray();
        }
        if ($post->audio_path) {
            $mediaTypes[] = 'audio';
        }

        $body = $post->content ?? '';
        $hashtags = self::extractHashtags($body);
        $mentions = self::extractMentions($body);

        // Merge with stored hashtags/mentions if available
        if (!empty($post->hashtags)) {
            $hashtags = array_unique(array_merge($hashtags, (array) $post->hashtags));
        }
        if (!empty($post->mentions)) {
            $mentions = array_unique(array_merge($mentions, (array) $post->mentions));
        }

        return [
            'source_type' => ContentDocument::TYPE_POST,
            'source_id' => $post->id,
            'title' => $body ? mb_substr(strtok($body, "\n"), 0, 100) : null,
            'body' => $body,
            'media_types' => $mediaTypes,
            'hashtags' => array_values($hashtags),
            'mentions' => array_values($mentions),
            'language' => $post->language_code ?? LanguageDetector::detect($body),
            'creator_id' => $post->user_id,
            'privacy' => $post->privacy ?? 'public',
            'region_name' => $post->user?->region_name,
            'district_name' => $post->user?->district_name,
            'category' => $post->content_category,
            'published_at' => $post->published_at ?? $post->created_at,
        ];
    }

    private static function fromClip(Clip $clip): array
    {
        $body = $clip->description ?? $clip->caption ?? '';

        return [
            'source_type' => ContentDocument::TYPE_CLIP,
            'source_id' => $clip->id,
            'title' => $clip->title ?? ($body ? mb_substr($body, 0, 100) : null),
            'body' => $body,
            'media_types' => ['video'],
            'hashtags' => self::extractHashtags($body),
            'mentions' => self::extractMentions($body),
            'language' => LanguageDetector::detect($body),
            'creator_id' => $clip->user_id,
            'privacy' => $clip->privacy ?? 'public',
            'region_name' => $clip->user?->region_name,
            'district_name' => $clip->user?->district_name,
            'category' => null,
            'published_at' => $clip->created_at,
        ];
    }

    private static function fromStory(Story $story): array
    {
        $body = $story->caption ?? '';

        return [
            'source_type' => ContentDocument::TYPE_STORY,
            'source_id' => $story->id,
            'title' => null,
            'body' => $body,
            'media_types' => [$story->media_type ?? 'image'],
            'hashtags' => self::extractHashtags($body),
            'mentions' => self::extractMentions($body),
            'language' => LanguageDetector::detect($body),
            'creator_id' => $story->user_id,
            'privacy' => $story->privacy ?? 'public',
            'region_name' => $story->user?->region_name,
            'district_name' => $story->user?->district_name,
            'category' => null,
            'published_at' => $story->created_at,
        ];
    }

    private static function fromMusic(MusicTrack $track): array
    {
        $body = implode(' ', array_filter([
            $track->artist?->first_name,
            $track->artist?->last_name,
            $track->album,
            $track->lyrics,
        ]));

        return [
            'source_type' => ContentDocument::TYPE_MUSIC,
            'source_id' => $track->id,
            'title' => $track->title,
            'body' => $body,
            'media_types' => ['audio'],
            'hashtags' => [],
            'mentions' => [],
            'language' => LanguageDetector::detect($body),
            'creator_id' => $track->artist_id ?? $track->uploaded_by,
            'privacy' => 'public',
            'region_name' => null,
            'district_name' => null,
            'category' => $track->genre ?? 'music',
            'published_at' => $track->created_at,
        ];
    }

    private static function fromStream(LiveStream $stream): array
    {
        $body = implode(' ', array_filter([$stream->title, $stream->description]));

        return [
            'source_type' => ContentDocument::TYPE_STREAM,
            'source_id' => $stream->id,
            'title' => $stream->title,
            'body' => $body,
            'media_types' => ['video'],
            'hashtags' => self::extractHashtags($body),
            'mentions' => self::extractMentions($body),
            'language' => LanguageDetector::detect($body),
            'creator_id' => $stream->user_id,
            'privacy' => $stream->privacy ?? 'public',
            'region_name' => null,
            'district_name' => null,
            'category' => $stream->category,
            'published_at' => $stream->started_at ?? $stream->created_at,
        ];
    }

    private static function fromEvent(Event $event): array
    {
        $body = implode(' ', array_filter([$event->name, $event->description]));

        return [
            'source_type' => ContentDocument::TYPE_EVENT,
            'source_id' => $event->id,
            'title' => $event->name,
            'body' => $body,
            'media_types' => $event->cover_photo_path ? ['image'] : [],
            'hashtags' => self::extractHashtags($body),
            'mentions' => [],
            'language' => LanguageDetector::detect($body),
            'creator_id' => $event->creator_id,
            'privacy' => $event->privacy ?? 'public',
            'region_name' => null,
            'district_name' => null,
            'category' => $event->category,
            'published_at' => $event->created_at,
        ];
    }

    private static function fromCampaign(Campaign $campaign): array
    {
        $body = implode(' ', array_filter([
            $campaign->title,
            $campaign->story,
            $campaign->short_description,
        ]));

        return [
            'source_type' => ContentDocument::TYPE_CAMPAIGN,
            'source_id' => $campaign->id,
            'title' => $campaign->title,
            'body' => $body,
            'media_types' => $campaign->cover_image_path ? ['image'] : [],
            'hashtags' => self::extractHashtags($body),
            'mentions' => [],
            'language' => LanguageDetector::detect($body),
            'creator_id' => $campaign->user_id,
            'privacy' => 'public',
            'region_name' => null,
            'district_name' => null,
            'category' => $campaign->category,
            'published_at' => $campaign->created_at,
        ];
    }

    private static function fromProduct(Product $product): array
    {
        $body = implode(' ', array_filter([
            $product->name ?? $product->title,
            $product->description,
        ]));

        $mediaTypes = [];
        if ($product->images || $product->cover_image_path) {
            $mediaTypes[] = 'image';
        }

        return [
            'source_type' => ContentDocument::TYPE_PRODUCT,
            'source_id' => $product->id,
            'title' => $product->name ?? $product->title,
            'body' => $body,
            'media_types' => $mediaTypes,
            'hashtags' => self::extractHashtags($body),
            'mentions' => [],
            'language' => LanguageDetector::detect($body),
            'creator_id' => $product->user_id ?? $product->seller_id ?? $product->shop_id,
            'privacy' => 'public',
            'region_name' => null,
            'district_name' => null,
            'category' => $product->category ?? 'other',
            'published_at' => $product->created_at,
        ];
    }

    private static function fromGroup(Group $group): array
    {
        $body = implode(' ', array_filter([$group->name, $group->description]));

        return [
            'source_type' => ContentDocument::TYPE_GROUP,
            'source_id' => $group->id,
            'title' => $group->name,
            'body' => $body,
            'media_types' => $group->cover_photo_path ? ['image'] : [],
            'hashtags' => [],
            'mentions' => [],
            'language' => LanguageDetector::detect($body),
            'creator_id' => $group->creator_id,
            'privacy' => $group->privacy ?? 'public',
            'region_name' => null,
            'district_name' => null,
            'category' => null,
            'published_at' => $group->created_at,
        ];
    }

    private static function fromPage(Page $page): array
    {
        $body = implode(' ', array_filter([$page->name, $page->description, $page->category]));

        return [
            'source_type' => ContentDocument::TYPE_PAGE,
            'source_id' => $page->id,
            'title' => $page->name,
            'body' => $body,
            'media_types' => [],
            'hashtags' => [],
            'mentions' => [],
            'language' => LanguageDetector::detect($body),
            'creator_id' => $page->creator_id,
            'privacy' => 'public',
            'region_name' => null,
            'district_name' => null,
            'category' => $page->category,
            'published_at' => $page->created_at,
        ];
    }

    private static function fromUserProfile(UserProfile $profile): array
    {
        $body = implode(' ', array_filter([
            $profile->first_name,
            $profile->last_name,
            $profile->username,
            $profile->bio,
        ]));

        return [
            'source_type' => ContentDocument::TYPE_USER_PROFILE,
            'source_id' => $profile->id,
            'title' => trim(($profile->first_name ?? '') . ' ' . ($profile->last_name ?? '')),
            'body' => $body,
            'media_types' => [],
            'hashtags' => [],
            'mentions' => [],
            'language' => LanguageDetector::detect($profile->bio),
            'creator_id' => $profile->id,
            'privacy' => $profile->profile_visibility ?? 'public',
            'region_name' => $profile->region_name,
            'district_name' => $profile->district_name,
            'category' => null,
            'published_at' => $profile->created_at,
        ];
    }

    private static function fromGossipThread(GossipThread $thread): array
    {
        $title = $thread->getResolvedTitleEn() ?? $thread->title_key;
        $body = implode(' ', array_filter([
            $title,
            $thread->getResolvedTitleSw(),
            $thread->category,
        ]));

        return [
            'source_type' => ContentDocument::TYPE_GOSSIP_THREAD,
            'source_id' => $thread->id,
            'title' => $title,
            'body' => $body,
            'media_types' => [],
            'hashtags' => [],
            'mentions' => [],
            'language' => 'sw',
            'creator_id' => $thread->seedPost?->user_id ?? 0,
            'privacy' => 'public',
            'region_name' => null,
            'district_name' => null,
            'category' => $thread->category,
            'published_at' => $thread->created_at,
        ];
    }

    /**
     * Extract #hashtags from text.
     */
    public static function extractHashtags(?string $text): array
    {
        if (empty($text)) {
            return [];
        }
        preg_match_all('/#(\w+)/u', $text, $matches);
        return array_unique(array_map('mb_strtolower', $matches[1] ?? []));
    }

    /**
     * Extract @mentions from text.
     */
    public static function extractMentions(?string $text): array
    {
        if (empty($text)) {
            return [];
        }
        preg_match_all('/@(\w+)/u', $text, $matches);
        return array_unique($matches[1] ?? []);
    }
}
```

- [ ] **Step 4: Syntax check both files**

```bash
cd /var/www/html/tajiri
php -l app/Services/ContentEngine/LanguageDetector.php
php -l app/Services/ContentEngine/ContentDocumentFactory.php
```

Expected: No syntax errors.

- [ ] **Step 5: Commit**

```bash
cd /var/www/html/tajiri
git add app/Services/ContentEngine/
git commit -m "feat(content-engine): add ContentDocumentFactory and LanguageDetector — maps 12 source types to unified document model"
```

---

## Task 2: TypesenseService and EmbeddingService Clients

**Files:**
- Create: `app/Services/ContentEngine/TypesenseService.php`
- Create: `app/Services/ContentEngine/EmbeddingService.php`

- [ ] **Step 1: Write TypesenseService**

Write `app/Services/ContentEngine/TypesenseService.php`:

```php
<?php

namespace App\Services\ContentEngine;

use App\Models\ContentDocument;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class TypesenseService
{
    /**
     * Upsert a ContentDocument into Typesense.
     */
    public static function upsert(ContentDocument $doc): bool
    {
        $config = config('content-engine.typesense');
        $url = "{$config['protocol']}://{$config['host']}:{$config['port']}/collections/{$config['collection']}/documents?action=upsert";

        $payload = [
            'id' => (string) $doc->id,
            'source_type' => $doc->source_type,
            'source_id' => (int) $doc->source_id,
            'title' => $doc->title ?? '',
            'body' => $doc->body ?? '',
            'hashtags' => $doc->hashtags ?? [],
            'mentions' => $doc->mentions ?? [],
            'language' => $doc->language ?? '',
            'creator_id' => (int) $doc->creator_id,
            'creator_tier' => $doc->creator_tier ?? '',
            'category' => $doc->category ?? '',
            'content_tier' => $doc->content_tier ?? 'medium',
            'media_types' => $doc->media_types ?? [],
            'region_name' => $doc->region_name ?? '',
            'district_name' => $doc->district_name ?? '',
            'privacy' => $doc->privacy ?? 'public',
            'composite_score' => (float) ($doc->composite_score ?? 0),
            'engagement_score' => (float) ($doc->engagement_score ?? 0),
            'freshness_score' => (float) ($doc->freshness_score ?? 0),
            'trending_score' => (float) ($doc->trending_score ?? 0),
            'quality_score' => (float) ($doc->quality_score ?? 0),
            'content_rank' => (float) ($doc->content_rank ?? 0),
            'creator_authority' => (float) ($doc->creator_authority ?? 0),
            'published_at' => $doc->published_at ? $doc->published_at->timestamp : 0,
            'indexed_at' => now()->timestamp,
        ];

        try {
            $response = Http::withHeaders([
                'X-TYPESENSE-API-KEY' => $config['api_key'],
                'Content-Type' => 'application/json',
            ])->timeout(10)->post($url, $payload);

            if (!$response->successful()) {
                Log::error('TypesenseService::upsert failed', [
                    'doc_id' => $doc->id,
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);
                return false;
            }

            return true;
        } catch (\Throwable $e) {
            Log::error('TypesenseService::upsert exception', [
                'doc_id' => $doc->id,
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    /**
     * Delete a document from Typesense by its ContentDocument ID.
     */
    public static function delete(int $docId): bool
    {
        $config = config('content-engine.typesense');
        $url = "{$config['protocol']}://{$config['host']}:{$config['port']}/collections/{$config['collection']}/documents/{$docId}";

        try {
            $response = Http::withHeaders([
                'X-TYPESENSE-API-KEY' => $config['api_key'],
            ])->timeout(10)->delete($url);

            return $response->successful() || $response->status() === 404;
        } catch (\Throwable $e) {
            Log::error('TypesenseService::delete exception', [
                'doc_id' => $docId,
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    /**
     * Batch upsert multiple documents.
     */
    public static function batchUpsert(array $documents): int
    {
        $config = config('content-engine.typesense');
        $url = "{$config['protocol']}://{$config['host']}:{$config['port']}/collections/{$config['collection']}/documents/import?action=upsert";

        $jsonl = '';
        foreach ($documents as $doc) {
            $payload = [
                'id' => (string) $doc->id,
                'source_type' => $doc->source_type,
                'source_id' => (int) $doc->source_id,
                'title' => $doc->title ?? '',
                'body' => $doc->body ?? '',
                'hashtags' => $doc->hashtags ?? [],
                'mentions' => $doc->mentions ?? [],
                'language' => $doc->language ?? '',
                'creator_id' => (int) $doc->creator_id,
                'creator_tier' => $doc->creator_tier ?? '',
                'category' => $doc->category ?? '',
                'content_tier' => $doc->content_tier ?? 'medium',
                'media_types' => $doc->media_types ?? [],
                'region_name' => $doc->region_name ?? '',
                'district_name' => $doc->district_name ?? '',
                'privacy' => $doc->privacy ?? 'public',
                'composite_score' => (float) ($doc->composite_score ?? 0),
                'engagement_score' => (float) ($doc->engagement_score ?? 0),
                'freshness_score' => (float) ($doc->freshness_score ?? 0),
                'trending_score' => (float) ($doc->trending_score ?? 0),
                'quality_score' => (float) ($doc->quality_score ?? 0),
                'content_rank' => (float) ($doc->content_rank ?? 0),
                'creator_authority' => (float) ($doc->creator_authority ?? 0),
                'published_at' => $doc->published_at ? $doc->published_at->timestamp : 0,
                'indexed_at' => now()->timestamp,
            ];
            $jsonl .= json_encode($payload) . "\n";
        }

        try {
            $response = Http::withHeaders([
                'X-TYPESENSE-API-KEY' => $config['api_key'],
                'Content-Type' => 'text/plain',
            ])->timeout(30)->withBody($jsonl, 'text/plain')->post($url);

            if (!$response->successful()) {
                Log::error('TypesenseService::batchUpsert failed', ['status' => $response->status()]);
                return 0;
            }

            // Count successful imports from JSONL response
            $lines = explode("\n", trim($response->body()));
            $success = 0;
            foreach ($lines as $line) {
                $result = json_decode($line, true);
                if (isset($result['success']) && $result['success']) {
                    $success++;
                }
            }
            return $success;
        } catch (\Throwable $e) {
            Log::error('TypesenseService::batchUpsert exception', ['error' => $e->getMessage()]);
            return 0;
        }
    }
}
```

- [ ] **Step 2: Write EmbeddingService**

Write `app/Services/ContentEngine/EmbeddingService.php`:

```php
<?php

namespace App\Services\ContentEngine;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class EmbeddingService
{
    /**
     * Generate embedding for a single text.
     *
     * @return float[]|null 768-dim embedding or null on failure
     */
    public static function embed(string $text): ?array
    {
        $config = config('content-engine.embedding');

        try {
            $response = Http::timeout($config['timeout'])
                ->post($config['url'] . '/embed', ['text' => $text]);

            if (!$response->successful()) {
                Log::error('EmbeddingService::embed failed', [
                    'status' => $response->status(),
                ]);
                return null;
            }

            $data = $response->json();
            return $data['embedding'] ?? null;
        } catch (\Throwable $e) {
            Log::error('EmbeddingService::embed exception', [
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Generate embeddings for multiple texts (max 50).
     *
     * @param string[] $texts
     * @return array<int, float[]> Indexed embeddings array
     */
    public static function embedBatch(array $texts): array
    {
        $config = config('content-engine.embedding');
        $batchSize = $config['batch_size'] ?? 50;
        $chunks = array_chunk($texts, $batchSize);
        $allEmbeddings = [];

        foreach ($chunks as $chunk) {
            try {
                $response = Http::timeout(60)
                    ->post($config['url'] . '/embed/batch', ['texts' => $chunk]);

                if ($response->successful()) {
                    $data = $response->json();
                    $allEmbeddings = array_merge($allEmbeddings, $data['embeddings'] ?? []);
                } else {
                    Log::error('EmbeddingService::embedBatch failed', [
                        'status' => $response->status(),
                    ]);
                    // Fill with nulls for failed batch
                    $allEmbeddings = array_merge($allEmbeddings, array_fill(0, count($chunk), null));
                }
            } catch (\Throwable $e) {
                Log::error('EmbeddingService::embedBatch exception', [
                    'error' => $e->getMessage(),
                ]);
                $allEmbeddings = array_merge($allEmbeddings, array_fill(0, count($chunk), null));
            }
        }

        return $allEmbeddings;
    }
}
```

- [ ] **Step 3: Syntax check both files**

```bash
cd /var/www/html/tajiri
php -l app/Services/ContentEngine/TypesenseService.php
php -l app/Services/ContentEngine/EmbeddingService.php
```

- [ ] **Step 4: Commit**

```bash
cd /var/www/html/tajiri
git add app/Services/ContentEngine/TypesenseService.php app/Services/ContentEngine/EmbeddingService.php
git commit -m "feat(content-engine): add TypesenseService and EmbeddingService HTTP clients"
```

---

## Task 3: ContentIngestionJob and DeleteContentDocumentJob

**Files:**
- Create: `app/Jobs/ContentEngine/ContentIngestionJob.php`
- Create: `app/Jobs/ContentEngine/DeleteContentDocumentJob.php`

- [ ] **Step 1: Create the jobs directory**

```bash
mkdir -p /var/www/html/tajiri/app/Jobs/ContentEngine
```

- [ ] **Step 2: Write ContentIngestionJob**

Write `app/Jobs/ContentEngine/ContentIngestionJob.php`:

```php
<?php

namespace App\Jobs\ContentEngine;

use App\Models\ContentDocument;
use App\Services\ContentEngine\ContentDocumentFactory;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class ContentIngestionJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 30;

    public function __construct(
        public string $sourceType,
        public int $sourceId,
        public string $modelClass,
    ) {
        $this->onQueue('content-ingestion');
    }

    public function handle(): void
    {
        $model = $this->modelClass::find($this->sourceId);

        if (!$model) {
            Log::warning("ContentIngestionJob: source not found", [
                'source_type' => $this->sourceType,
                'source_id' => $this->sourceId,
            ]);
            return;
        }

        try {
            $attributes = ContentDocumentFactory::fromModel($model);

            // Compute initial freshness score
            $halfLife = config("content-engine.scoring.freshness_half_lives.{$this->sourceType}", 24);
            $hoursSince = now()->diffInSeconds($attributes['published_at']) / 3600;
            $attributes['freshness_score'] = 100 * exp(-log(2) / $halfLife * $hoursSince);

            $doc = ContentDocument::updateOrCreate(
                ['source_type' => $this->sourceType, 'source_id' => $this->sourceId],
                array_merge($attributes, ['indexed_at' => now()])
            );

            // Fan out downstream jobs
            SyncToTypesenseJob::dispatch($doc->id)->onQueue('typesense-sync');
            GenerateEmbeddingJob::dispatch($doc->id)->onQueue('content-embedding');
            ClaudeScoreContentJob::dispatch($doc->id)->onQueue('content-scoring');

            Log::info("ContentIngestionJob: ingested", [
                'doc_id' => $doc->id,
                'source' => "{$this->sourceType}:{$this->sourceId}",
            ]);
        } catch (\Throwable $e) {
            Log::error("ContentIngestionJob: failed", [
                'source' => "{$this->sourceType}:{$this->sourceId}",
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
    }
}
```

- [ ] **Step 3: Write DeleteContentDocumentJob**

Write `app/Jobs/ContentEngine/DeleteContentDocumentJob.php`:

```php
<?php

namespace App\Jobs\ContentEngine;

use App\Models\ContentDocument;
use App\Services\ContentEngine\TypesenseService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class DeleteContentDocumentJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 10;

    public function __construct(
        public string $sourceType,
        public int $sourceId,
    ) {
        $this->onQueue('content-ingestion');
    }

    public function handle(): void
    {
        $doc = ContentDocument::where('source_type', $this->sourceType)
            ->where('source_id', $this->sourceId)
            ->first();

        if (!$doc) {
            return;
        }

        $docId = $doc->id;

        // Delete from PostgreSQL (cascade removes pgvector row)
        $doc->delete();

        // Delete from Typesense
        TypesenseService::delete($docId);

        Log::info("DeleteContentDocumentJob: deleted", [
            'source' => "{$this->sourceType}:{$this->sourceId}",
            'doc_id' => $docId,
        ]);
    }
}
```

- [ ] **Step 4: Syntax check**

```bash
cd /var/www/html/tajiri
php -l app/Jobs/ContentEngine/ContentIngestionJob.php
php -l app/Jobs/ContentEngine/DeleteContentDocumentJob.php
```

- [ ] **Step 5: Commit**

```bash
cd /var/www/html/tajiri
git add app/Jobs/ContentEngine/
git commit -m "feat(content-engine): add ContentIngestionJob and DeleteContentDocumentJob"
```

---

## Task 4: SyncToTypesenseJob and GenerateEmbeddingJob

**Files:**
- Create: `app/Jobs/ContentEngine/SyncToTypesenseJob.php`
- Create: `app/Jobs/ContentEngine/GenerateEmbeddingJob.php`

- [ ] **Step 1: Write SyncToTypesenseJob**

Write `app/Jobs/ContentEngine/SyncToTypesenseJob.php`:

```php
<?php

namespace App\Jobs\ContentEngine;

use App\Models\ContentDocument;
use App\Services\ContentEngine\TypesenseService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SyncToTypesenseJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 15;

    public function __construct(public int $documentId)
    {
        $this->onQueue('typesense-sync');
    }

    public function handle(): void
    {
        $doc = ContentDocument::find($this->documentId);

        if (!$doc) {
            Log::warning("SyncToTypesenseJob: document not found", ['id' => $this->documentId]);
            return;
        }

        $success = TypesenseService::upsert($doc);

        if (!$success) {
            Log::error("SyncToTypesenseJob: upsert failed", ['id' => $this->documentId]);
            throw new \RuntimeException("Typesense upsert failed for document {$this->documentId}");
        }
    }
}
```

- [ ] **Step 2: Write GenerateEmbeddingJob**

Write `app/Jobs/ContentEngine/GenerateEmbeddingJob.php`:

```php
<?php

namespace App\Jobs\ContentEngine;

use App\Models\ContentDocument;
use App\Services\ContentEngine\EmbeddingService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class GenerateEmbeddingJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public int $backoff = 30;

    public function __construct(public int $documentId)
    {
        $this->onQueue('content-embedding');
    }

    public function handle(): void
    {
        $doc = ContentDocument::find($this->documentId);

        if (!$doc) {
            return;
        }

        // Build text for embedding: title + body (truncated to ~500 words)
        $text = trim(($doc->title ?? '') . ' ' . ($doc->body ?? ''));

        if (empty($text)) {
            Log::info("GenerateEmbeddingJob: empty text, skipping", ['id' => $this->documentId]);
            return;
        }

        // Truncate to ~500 words to stay within model limits
        $words = preg_split('/\s+/', $text);
        if (count($words) > 500) {
            $text = implode(' ', array_slice($words, 0, 500));
        }

        $embedding = EmbeddingService::embed($text);

        if ($embedding === null) {
            Log::error("GenerateEmbeddingJob: embedding failed", ['id' => $this->documentId]);
            throw new \RuntimeException("Embedding generation failed for document {$this->documentId}");
        }

        // Store via raw SQL (Eloquent doesn't handle pgvector)
        $vectorStr = '[' . implode(',', $embedding) . ']';
        DB::statement(
            'UPDATE content_documents SET embedding = ?::vector WHERE id = ?',
            [$vectorStr, $this->documentId]
        );
    }
}
```

- [ ] **Step 3: Syntax check**

```bash
cd /var/www/html/tajiri
php -l app/Jobs/ContentEngine/SyncToTypesenseJob.php
php -l app/Jobs/ContentEngine/GenerateEmbeddingJob.php
```

- [ ] **Step 4: Commit**

```bash
cd /var/www/html/tajiri
git add app/Jobs/ContentEngine/SyncToTypesenseJob.php app/Jobs/ContentEngine/GenerateEmbeddingJob.php
git commit -m "feat(content-engine): add SyncToTypesenseJob and GenerateEmbeddingJob"
```

---

## Task 5: ClaudeScoreContentJob

**Files:**
- Create: `app/Jobs/ContentEngine/ClaudeScoreContentJob.php`

- [ ] **Step 1: Write ClaudeScoreContentJob**

Write `app/Jobs/ContentEngine/ClaudeScoreContentJob.php`:

```php
<?php

namespace App\Jobs\ContentEngine;

use App\Models\ContentDocument;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class ClaudeScoreContentJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public int $timeout = 120;
    public int $backoff = 60;

    public function __construct(public int $documentId)
    {
        $this->onQueue('content-scoring');
    }

    public function handle(): void
    {
        $doc = ContentDocument::find($this->documentId);

        if (!$doc) {
            return;
        }

        $text = trim(($doc->title ?? '') . ' ' . ($doc->body ?? ''));

        if (empty($text)) {
            $doc->update(['quality_score' => 5.0, 'spam_score' => 0]);
            $this->recomputeComposite($doc);
            return;
        }

        // Truncate for Claude (keep under 1000 chars for Haiku efficiency)
        if (mb_strlen($text) > 1000) {
            $text = mb_substr($text, 0, 1000);
        }

        $cliPath = config('content-engine.claude.cli_path', 'claude');
        $model = config('content-engine.claude.scoring_model', 'haiku');

        $prompt = <<<PROMPT
You are a content quality scorer for a Tanzanian social media platform.
Evaluate this content and respond with ONLY a JSON object (no other text):

Content type: {$doc->source_type}
Text: {$text}
Has media: {$this->hasMedia($doc)}

Respond with exactly this JSON format:
{"quality_score": <float 0-10>, "spam_score": <float 0-10>, "category": "<string>"}

quality_score: 0=garbage, 5=average, 10=exceptional. Consider: originality, effort, coherence, value to community.
spam_score: 0=legitimate, 5=borderline, 10=definite spam. Consider: repetition, link spam, engagement bait.
category: One of: entertainment, music, sports, news, business, education, lifestyle, technology, politics, religion, food, travel, fashion, health, comedy, other
PROMPT;

        try {
            $escapedPrompt = escapeshellarg($prompt);
            $output = shell_exec("{$cliPath} -p {$escapedPrompt} --model {$model} --output-format text 2>/dev/null");

            if (empty($output)) {
                Log::warning("ClaudeScoreContentJob: empty Claude response", ['id' => $this->documentId]);
                $doc->update(['quality_score' => 5.0, 'spam_score' => 0]);
                $this->recomputeComposite($doc);
                return;
            }

            // Extract JSON from response (Claude may include wrapping text)
            preg_match('/\{[^}]+\}/', $output, $matches);

            if (empty($matches[0])) {
                Log::warning("ClaudeScoreContentJob: no JSON in response", [
                    'id' => $this->documentId,
                    'output' => substr($output, 0, 200),
                ]);
                $doc->update(['quality_score' => 5.0, 'spam_score' => 0]);
                $this->recomputeComposite($doc);
                return;
            }

            $scores = json_decode($matches[0], true);

            $qualityScore = max(0, min(10, (float) ($scores['quality_score'] ?? 5)));
            $spamScore = max(0, min(10, (float) ($scores['spam_score'] ?? 0)));
            $category = $scores['category'] ?? $doc->category;

            $updates = [
                'quality_score' => $qualityScore,
                'spam_score' => $spamScore,
            ];

            if ($category && empty($doc->category)) {
                $updates['category'] = $category;
            }

            // Auto-blackhole if spam_score > 7
            if ($spamScore > 7) {
                $updates['content_tier'] = ContentDocument::TIER_BLACKHOLE;
            }

            $doc->update($updates);
            $this->recomputeComposite($doc);

        } catch (\Throwable $e) {
            Log::error("ClaudeScoreContentJob: failed", [
                'id' => $this->documentId,
                'error' => $e->getMessage(),
            ]);
            // Default scores on failure — don't block content
            $doc->update(['quality_score' => 5.0, 'spam_score' => 0]);
            $this->recomputeComposite($doc);
        }
    }

    private function recomputeComposite(ContentDocument $doc): void
    {
        $weights = \App\Models\ScoringConfig::allWeights();

        $composite =
            ($doc->freshness_score * ($weights['w_freshness'] ?? 0.25)) +
            ($doc->engagement_score * ($weights['w_engagement'] ?? 0.30)) +
            ($doc->quality_score * 10 * ($weights['w_quality'] ?? 0.15)) +
            ($doc->content_rank * ($weights['w_content_rank'] ?? 0.15)) +
            ($doc->creator_authority * ($weights['w_creator_auth'] ?? 0.10)) +
            ($doc->trending_score * ($weights['w_trending'] ?? 0.05));

        $tier = match (true) {
            $doc->spam_score > 7 => ContentDocument::TIER_BLACKHOLE,
            $composite > 85 => ContentDocument::TIER_VIRAL,
            $composite > 60 => ContentDocument::TIER_HIGH,
            $composite > 30 => ContentDocument::TIER_MEDIUM,
            $composite > 10 => ContentDocument::TIER_LOW,
            default => ContentDocument::TIER_BLACKHOLE,
        };

        $doc->update([
            'composite_score' => $composite,
            'content_tier' => $tier,
            'scores_updated_at' => now(),
        ]);
    }

    private function hasMedia(ContentDocument $doc): string
    {
        $types = $doc->media_types ?? [];
        return empty($types) ? 'no' : implode(', ', $types);
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
cd /var/www/html/tajiri
php -l app/Jobs/ContentEngine/ClaudeScoreContentJob.php
```

- [ ] **Step 3: Commit**

```bash
cd /var/www/html/tajiri
git add app/Jobs/ContentEngine/ClaudeScoreContentJob.php
git commit -m "feat(content-engine): add ClaudeScoreContentJob — AI quality and spam scoring via Claude CLI"
```

---

## Task 6: ContentIngestionObserver and Model Registration

**Files:**
- Create: `app/Observers/ContentIngestionObserver.php`
- Modify: `app/Providers/AppServiceProvider.php`

- [ ] **Step 1: Write ContentIngestionObserver**

Write `app/Observers/ContentIngestionObserver.php`:

```php
<?php

namespace App\Observers;

use App\Jobs\ContentEngine\ContentIngestionJob;
use App\Jobs\ContentEngine\DeleteContentDocumentJob;
use App\Services\ContentEngine\ContentDocumentFactory;
use Illuminate\Database\Eloquent\Model;

class ContentIngestionObserver
{
    /**
     * Map of model classes to source types for deletion.
     */
    private static array $sourceTypeMap = [
        \App\Models\Post::class => 'post',
        \App\Models\Clip::class => 'clip',
        \App\Models\Story::class => 'story',
        \App\Models\MusicTrack::class => 'music',
        \App\Models\LiveStream::class => 'stream',
        \App\Models\Event::class => 'event',
        \App\Models\Campaign::class => 'campaign',
        \App\Models\Product::class => 'product',
        \App\Models\Group::class => 'group',
        \App\Models\Page::class => 'page',
        \App\Models\UserProfile::class => 'user_profile',
        \App\Models\GossipThread::class => 'gossip_thread',
    ];

    public function created(Model $model): void
    {
        $this->dispatch($model);
    }

    public function updated(Model $model): void
    {
        $this->dispatch($model);
    }

    public function deleted(Model $model): void
    {
        $sourceType = self::$sourceTypeMap[get_class($model)] ?? null;

        if ($sourceType) {
            DeleteContentDocumentJob::dispatch($sourceType, $model->id);
        }
    }

    private function dispatch(Model $model): void
    {
        // Skip drafts and unpublished posts
        if ($model instanceof \App\Models\Post) {
            if ($model->is_draft || $model->status === 'draft') {
                return;
            }
        }

        // Skip non-ended streams (only index archives)
        if ($model instanceof \App\Models\LiveStream) {
            if (!in_array($model->status, ['ended'], true)) {
                return;
            }
        }

        try {
            $sourceType = ContentDocumentFactory::sourceType($model);
            ContentIngestionJob::dispatch($sourceType, $model->id, get_class($model));
        } catch (\InvalidArgumentException $e) {
            // Unsupported model type — skip
        }
    }
}
```

- [ ] **Step 2: Register observer in AppServiceProvider**

Find the `boot()` method in `app/Providers/AppServiceProvider.php` and add observer registrations. Read the file first to find the right insertion point.

Add inside the `boot()` method:

```php
        // Content Engine: observe all content models for ingestion
        $ingestionObserver = \App\Observers\ContentIngestionObserver::class;
        \App\Models\Post::observe($ingestionObserver);
        \App\Models\Clip::observe($ingestionObserver);
        \App\Models\Story::observe($ingestionObserver);
        \App\Models\MusicTrack::observe($ingestionObserver);
        \App\Models\LiveStream::observe($ingestionObserver);
        \App\Models\Event::observe($ingestionObserver);
        \App\Models\Campaign::observe($ingestionObserver);
        \App\Models\Product::observe($ingestionObserver);
        \App\Models\Group::observe($ingestionObserver);
        \App\Models\Page::observe($ingestionObserver);
        \App\Models\UserProfile::observe($ingestionObserver);
        \App\Models\GossipThread::observe($ingestionObserver);
```

- [ ] **Step 3: Syntax check**

```bash
cd /var/www/html/tajiri
php -l app/Observers/ContentIngestionObserver.php
php -l app/Providers/AppServiceProvider.php
```

- [ ] **Step 4: Commit**

```bash
cd /var/www/html/tajiri
git add app/Observers/ContentIngestionObserver.php app/Providers/AppServiceProvider.php
git commit -m "feat(content-engine): add ContentIngestionObserver — auto-ingest on content create/update/delete"
```

---

## Task 7: content:reindex Backfill Command

**Files:**
- Create: `app/Console/Commands/ContentReindex.php`

- [ ] **Step 1: Write the reindex command**

Write `app/Console/Commands/ContentReindex.php`:

```php
<?php

namespace App\Console\Commands;

use App\Jobs\ContentEngine\ContentIngestionJob;
use App\Models\Campaign;
use App\Models\Clip;
use App\Models\ContentDocument;
use App\Models\Event;
use App\Models\GossipThread;
use App\Models\Group;
use App\Models\LiveStream;
use App\Models\MusicTrack;
use App\Models\Page;
use App\Models\Post;
use App\Models\Product;
use App\Models\Story;
use App\Models\UserProfile;
use Illuminate\Console\Command;

class ContentReindex extends Command
{
    protected $signature = 'content:reindex
                            {--all : Reindex all content types}
                            {--type= : Specific type to reindex (posts, clips, stories, music, streams, events, campaigns, groups, pages, profiles, gossip)}
                            {--since= : Only reindex content created/updated after this date (Y-m-d)}
                            {--batch-size=100 : Number of records per batch}';

    protected $description = 'Backfill content_documents by dispatching ingestion jobs for existing content';

    private const TYPE_MAP = [
        'posts' => [Post::class, 'post'],
        'clips' => [Clip::class, 'clip'],
        'stories' => [Story::class, 'story'],
        'music' => [MusicTrack::class, 'music'],
        'streams' => [LiveStream::class, 'stream'],
        'events' => [Event::class, 'event'],
        'campaigns' => [Campaign::class, 'campaign'],
        'products' => [Product::class, 'product'],
        'groups' => [Group::class, 'group'],
        'pages' => [Page::class, 'page'],
        'profiles' => [UserProfile::class, 'user_profile'],
        'gossip' => [GossipThread::class, 'gossip_thread'],
    ];

    public function handle(): int
    {
        $types = $this->option('all')
            ? array_keys(self::TYPE_MAP)
            : ($this->option('type') ? [$this->option('type')] : []);

        if (empty($types)) {
            $this->error('Specify --all or --type=<type>. Available types: ' . implode(', ', array_keys(self::TYPE_MAP)));
            return 1;
        }

        $since = $this->option('since');
        $batchSize = (int) $this->option('batch-size');
        $totalDispatched = 0;

        foreach ($types as $typeName) {
            if (!isset(self::TYPE_MAP[$typeName])) {
                $this->error("Unknown type: {$typeName}");
                continue;
            }

            [$modelClass, $sourceType] = self::TYPE_MAP[$typeName];

            $this->info("Reindexing {$typeName}...");

            $query = $modelClass::query();

            // Filter by date if specified
            if ($since) {
                $query->where('created_at', '>=', $since);
            }

            // Type-specific filters
            if ($modelClass === Post::class) {
                $query->where(function ($q) {
                    $q->where('is_draft', false)->orWhereNull('is_draft');
                })->where(function ($q) {
                    $q->where('status', 'published')->orWhereNull('status');
                });
            }
            if ($modelClass === LiveStream::class) {
                $query->where('status', 'ended');
            }

            $total = $query->count();
            $this->info("  Found {$total} records");

            $bar = $this->output->createProgressBar($total);
            $bar->start();

            $query->orderBy('id')
                ->chunk($batchSize, function ($records) use ($sourceType, $modelClass, &$totalDispatched, $bar) {
                    foreach ($records as $record) {
                        ContentIngestionJob::dispatch($sourceType, $record->id, $modelClass);
                        $totalDispatched++;
                        $bar->advance();
                    }
                });

            $bar->finish();
            $this->newLine();
        }

        $this->info("Dispatched {$totalDispatched} ingestion jobs total.");
        return 0;
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
cd /var/www/html/tajiri
php -l app/Console/Commands/ContentReindex.php
```

- [ ] **Step 3: Commit**

```bash
cd /var/www/html/tajiri
git add app/Console/Commands/ContentReindex.php
git commit -m "feat(content-engine): add content:reindex backfill command — dispatches ingestion jobs for existing content"
```

---

## Task 8: content:reconcile Integrity Check

**Files:**
- Create: `app/Console/Commands/ContentReconcile.php`

- [ ] **Step 1: Write the reconcile command**

Write `app/Console/Commands/ContentReconcile.php`:

```php
<?php

namespace App\Console\Commands;

use App\Models\ContentDocument;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

class ContentReconcile extends Command
{
    protected $signature = 'content:reconcile';
    protected $description = 'Check Content Engine data integrity — index coverage, sync completeness, orphans';

    public function handle(): int
    {
        $this->info('Content Engine Reconciliation');
        $this->info(str_repeat('=', 50));

        $issues = 0;

        // 1. Index coverage — every published post should have a content_document
        $postCount = DB::table('posts')
            ->where(function ($q) {
                $q->where('is_draft', false)->orWhereNull('is_draft');
            })
            ->count();
        $indexedPosts = ContentDocument::where('source_type', 'post')->count();
        $coverage = $postCount > 0 ? round($indexedPosts / $postCount * 100, 1) : 100;
        $this->line("  Posts: {$indexedPosts}/{$postCount} indexed ({$coverage}%)");
        if ($coverage < 95) {
            $this->warn("    LOW COVERAGE — run: php artisan content:reindex --type=posts");
            $issues++;
        }

        // 2. Total documents indexed
        $totalDocs = ContentDocument::count();
        $this->line("  Total documents: {$totalDocs}");

        // 3. Typesense sync check
        $config = config('content-engine.typesense');
        try {
            $url = "{$config['protocol']}://{$config['host']}:{$config['port']}/collections/{$config['collection']}";
            $response = Http::withHeaders(['X-TYPESENSE-API-KEY' => $config['api_key']])->timeout(5)->get($url);
            $typesenseCount = $response->json()['num_documents'] ?? 0;
            $drift = abs($totalDocs - $typesenseCount);
            $this->line("  Typesense documents: {$typesenseCount} (drift: {$drift})");
            if ($drift > max(10, $totalDocs * 0.05)) {
                $this->warn("    SYNC DRIFT — Typesense is out of sync");
                $issues++;
            }
        } catch (\Throwable $e) {
            $this->error("  Typesense: UNREACHABLE — {$e->getMessage()}");
            $issues++;
        }

        // 4. Embedding coverage
        $withEmbedding = DB::table('content_documents')
            ->whereNotNull('embedding')
            ->count();
        $embeddingPct = $totalDocs > 0 ? round($withEmbedding / $totalDocs * 100, 1) : 100;
        $this->line("  Embeddings: {$withEmbedding}/{$totalDocs} ({$embeddingPct}%)");
        if ($embeddingPct < 80 && $totalDocs > 0) {
            $this->warn("    LOW EMBEDDING COVERAGE");
            $issues++;
        }

        // 5. Score freshness
        $staleCount = ContentDocument::where('scores_updated_at', '<', now()->subHours(2))
            ->orWhereNull('scores_updated_at')
            ->count();
        $stalePct = $totalDocs > 0 ? round($staleCount / $totalDocs * 100, 1) : 0;
        $this->line("  Stale scores (>2h): {$staleCount} ({$stalePct}%)");

        // 6. Tier distribution
        $tiers = ContentDocument::selectRaw('content_tier, COUNT(*) as cnt')
            ->groupBy('content_tier')
            ->pluck('cnt', 'content_tier')
            ->toArray();
        $this->line("  Tier distribution: " . json_encode($tiers));

        $this->newLine();
        if ($issues === 0) {
            $this->info("No issues found.");
        } else {
            $this->warn("{$issues} issue(s) found. See warnings above.");
        }

        return $issues > 0 ? 1 : 0;
    }
}
```

- [ ] **Step 2: Syntax check**

```bash
cd /var/www/html/tajiri
php -l app/Console/Commands/ContentReconcile.php
```

- [ ] **Step 3: Commit**

```bash
cd /var/www/html/tajiri
git add app/Console/Commands/ContentReconcile.php
git commit -m "feat(content-engine): add content:reconcile integrity check command"
```

---

## Task 9: Supervisor Queue Worker Configuration

**Files:**
- Create: `/etc/supervisor/conf.d/content-engine.conf`

- [ ] **Step 1: Write Supervisor config**

Write `/etc/supervisor/conf.d/content-engine.conf`:

```ini
[program:content-ingestion]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/tajiri/artisan queue:work redis --queue=content-ingestion --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=4
redirect_stderr=true
stdout_logfile=/var/log/tajiri/content-ingestion.log
stopwaitsecs=3600

[program:typesense-sync]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/tajiri/artisan queue:work redis --queue=typesense-sync --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/log/tajiri/typesense-sync.log
stopwaitsecs=3600

[program:content-scoring]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/tajiri/artisan queue:work redis --queue=content-scoring --sleep=5 --tries=2 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/log/tajiri/content-scoring.log
stopwaitsecs=3600

[program:content-embedding]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/tajiri/artisan queue:work redis --queue=content-embedding --sleep=5 --tries=2 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/log/tajiri/content-embedding.log
stopwaitsecs=3600

[group:content-engine]
programs=content-ingestion,typesense-sync,content-scoring,content-embedding
```

- [ ] **Step 2: Create log files with correct ownership**

```bash
touch /var/log/tajiri/content-ingestion.log /var/log/tajiri/typesense-sync.log /var/log/tajiri/content-scoring.log /var/log/tajiri/content-embedding.log
chown www-data:www-data /var/log/tajiri/*.log
```

- [ ] **Step 3: Start Supervisor workers**

```bash
supervisorctl reread
supervisorctl update
supervisorctl start content-engine:*
```

- [ ] **Step 4: Verify workers are running**

```bash
supervisorctl status content-engine:*
```

Expected: All 10 processes (4+2+2+2) running.

- [ ] **Step 5: Commit supervisor config** (optional — infrastructure file, not in git)

No commit needed for `/etc/supervisor/` — it's server config, not application code.

---

## Task 10: Backfill Existing Content and Verify

- [ ] **Step 1: Run the backfill for posts first (most important)**

```bash
cd /var/www/html/tajiri
php artisan content:reindex --type=posts --batch-size=50
```

Watch the progress bar. This dispatches jobs that the Supervisor workers will process.

- [ ] **Step 2: Monitor queue processing**

```bash
# Check Redis queue sizes
redis-cli llen queues:content-ingestion
redis-cli llen queues:typesense-sync
redis-cli llen queues:content-embedding
redis-cli llen queues:content-scoring
```

Wait until all queues drain to 0.

- [ ] **Step 3: Verify some documents were created**

```bash
cd /var/www/html/tajiri
php artisan tinker --execute="
echo 'Documents: ' . \App\Models\ContentDocument::count() . PHP_EOL;
echo 'With embeddings: ' . \DB::table('content_documents')->whereNotNull('embedding')->count() . PHP_EOL;
echo 'Tier distribution: ' . json_encode(\App\Models\ContentDocument::selectRaw('content_tier, count(*) as cnt')->groupBy('content_tier')->pluck('cnt','content_tier')) . PHP_EOL;
"
```

- [ ] **Step 4: Verify Typesense has documents**

```bash
curl -s 'http://localhost:8108/collections/content_documents' \
  -H "X-TYPESENSE-API-KEY: tajiri-typesense-key-2026" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'Typesense docs: {d[\"num_documents\"]}')"
```

- [ ] **Step 5: Test a search**

```bash
curl -s 'http://localhost:8108/collections/content_documents/documents/search?q=Diamond&query_by=title,body&per_page=3' \
  -H "X-TYPESENSE-API-KEY: tajiri-typesense-key-2026" | python3 -m json.tool
```

Should return search results (if any posts mention "Diamond").

- [ ] **Step 6: Backfill remaining types**

```bash
cd /var/www/html/tajiri
php artisan content:reindex --all --batch-size=50
```

- [ ] **Step 7: Run reconciliation**

```bash
php artisan content:reconcile
```

Should show coverage stats and no critical issues.

- [ ] **Step 8: Run health check (from Phase 0)**

```bash
php artisan content:health-check
```

All 9 subsystems should pass (command was created in Phase 0).

- [ ] **Step 9: Final commit**

```bash
cd /var/www/html/tajiri
git status
git add -A
git diff --cached --stat
git commit -m "feat(content-engine): Phase 1 complete — ingestion pipeline live with backfill"
```

---

## Phase 1 Completion Criteria

After all 10 tasks:

- [ ] ContentDocumentFactory maps all 12 source types (Post, Clip, Story, Music, Stream, Event, Campaign, Product, Group, Page, UserProfile, GossipThread)
- [ ] ContentIngestionJob extracts, normalizes, upserts, and fans out 3 downstream jobs
- [ ] SyncToTypesenseJob keeps Typesense in sync
- [ ] GenerateEmbeddingJob stores 768-dim vectors in pgvector
- [ ] ClaudeScoreContentJob scores quality + spam via Claude CLI
- [ ] ContentIngestionObserver fires on create/update/delete for all 12 models
- [ ] `content:reindex` can backfill all existing content
- [ ] `content:reconcile` checks data integrity
- [ ] Supervisor runs 10 workers across 4 queues
- [ ] Existing posts are indexed in both PostgreSQL and Typesense
- [ ] Search returns results from Typesense
- [ ] All code committed

**Deferred to Phase 2:** Real-time signal processing (Redis Streams, engagement score updates, trending detection, dirty-set score sync).

**Next:** Phase 2 — Signal Processing (Redis Streams consumer, engagement score computation, trending detection, freshness refresh scheduler, dirty-set sync)
