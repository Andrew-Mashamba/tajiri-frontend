# TAJIRI Content Engine — Full Technical Architecture Spec

A unified content intelligence system that powers both search and feed ranking from the same index and signals, modeled on Google's search architecture (Trawler/Alexandria/Mustang/NavBoost/Gemini) adapted for a social platform.

**Date**: 2026-03-28
**Status**: Approved Design
**Scope**: Backend (Laravel) + Frontend (Flutter) + Infrastructure

---

## Table of Contents

1. [Overview & Mapping](#1-overview--mapping)
2. [Unified Document Model](#2-unified-document-model)
3. [Ingestion Pipeline (Trawler)](#3-ingestion-pipeline-trawler)
4. [Indexing Pipeline (Alexandria)](#4-indexing-pipeline-alexandria)
5. [Real-Time Signal Processor (NavBoost)](#5-real-time-signal-processor-navboost)
6. [Content Graph (PageRank)](#6-content-graph-pagerank)
7. [Serving Pipeline (SuperRoot + Mustang)](#7-serving-pipeline-superroot--mustang)
8. [AI Intelligence Layer (Gemini)](#8-ai-intelligence-layer-gemini)
9. [Frontend — Search + Discovery](#9-frontend--search--discovery)
10. [Infrastructure & Deployment](#10-infrastructure--deployment)
11. [Migration Strategy](#11-migration-strategy)

---

## 1. Overview & Mapping

### Technology Stack

| Component | Technology | Purpose |
|---|---|---|
| Source of truth | PostgreSQL | content_documents table, all scores, graph edges |
| Vector search | pgvector (PostgreSQL extension) | Semantic similarity, "more like this" |
| Full-text search | Typesense | Instant keyword search, typo-tolerance, facets |
| Real-time signals | Redis Streams + Sorted Sets + Hashes | Engagement processing, trending detection, per-user profiles |
| Content graph | NetworkX (Python batch job) | PageRank-equivalent authority computation |
| AI intelligence | Claude CLI (Haiku + Sonnet) | Content scoring, query expansion, digests, coaching, moderation |
| Embeddings | Local model (multilingual-e5-base via Python microservice) | 768-dim vectors for semantic search |
| Queue workers | Laravel Queue (Redis driver) + Supervisor | Async ingestion, scoring, syncing |

### Google → TAJIRI Architecture Mapping

| Google System | TAJIRI Equivalent | Technology |
|---|---|---|
| Trawler (crawler) | Content Ingestion Pipeline | Laravel Queue Jobs |
| Alexandria (indexing) | Indexing Pipeline | Laravel Jobs + Claude Haiku + pgvector |
| Inverted Index | Typesense search index | Typesense (synced from PostgreSQL) |
| SegIndexer (quality tiers) | Content Tier System | PostgreSQL `content_tier` column |
| NavBoost (click signals) | Engagement Signal Processor | Redis Streams + Sorted Sets |
| Instant Glue (fast signals) | Trending Detector | Redis consumer worker (2-min cycle) |
| PageRank (authority) | ContentRank | NetworkX batch job → PostgreSQL |
| Ascorer (primary ranking) | Score Engine | Composite score from weighted signals |
| Twiddlers (re-ranking) | Re-ranking Rules | Laravel application logic |
| SuperRoot (orchestration) | Feed Orchestrator | Laravel controller + Redis cache |
| Gemini (AI layer) | Claude Intelligence Layer | Claude CLI (Haiku for batch, Sonnet for user-facing) |
| QDF (freshness) | Freshness Boost | Exponential time-decay per content type |
| SpamBrain | Content Moderation | Claude Haiku spam/toxicity detection |

---

## 2. Unified Document Model

Every piece of content in TAJIRI becomes a **ContentDocument** — a normalized representation in a single table.

### Schema

```sql
CREATE TABLE content_documents (
    id              BIGSERIAL PRIMARY KEY,

    -- Source identity
    source_type     VARCHAR(20) NOT NULL,  -- post, clip, story, music, stream, event, campaign, product, group, page, user_profile, gossip_thread
    source_id       BIGINT NOT NULL,

    -- Denormalized content (what gets indexed)
    title           TEXT,
    body            TEXT,
    media_types     VARCHAR[] DEFAULT '{}',
    hashtags        VARCHAR[] DEFAULT '{}',
    mentions        VARCHAR[] DEFAULT '{}',
    language        VARCHAR(5),

    -- Creator context
    creator_id      BIGINT NOT NULL,
    creator_tier    VARCHAR(20),
    creator_authority FLOAT DEFAULT 0,

    -- Pre-computed scores
    quality_score       FLOAT DEFAULT 0,    -- Claude AI (0-10, scaled to 0-100 in composite via *10)
    engagement_score    FLOAT DEFAULT 0,    -- Real-time from Redis (0-100)
    freshness_score     FLOAT DEFAULT 0,    -- Time-decay (0-100)
    content_rank        FLOAT DEFAULT 0,    -- Graph authority (0-100)
    trending_score      FLOAT DEFAULT 0,    -- Engagement velocity (0-100)
    spam_score          FLOAT DEFAULT 0,    -- Claude spam detection (0-10)
    composite_score     FLOAT DEFAULT 0,    -- Weighted combination

    -- Content tier (SegIndexer equivalent)
    content_tier    VARCHAR(20) DEFAULT 'medium',  -- viral, high, medium, low, blackhole

    -- Metadata
    privacy         VARCHAR(20) DEFAULT 'public',
    region_name     VARCHAR(100),
    district_name   VARCHAR(100),
    category        VARCHAR(50),

    -- Vector embedding (pgvector)
    embedding       vector(768),

    -- Timestamps
    published_at    TIMESTAMP NOT NULL,
    indexed_at      TIMESTAMP DEFAULT NOW(),
    scores_updated_at TIMESTAMP,

    UNIQUE(source_type, source_id)
);

CREATE INDEX idx_cd_composite ON content_documents(content_tier, composite_score DESC);
CREATE INDEX idx_cd_creator ON content_documents(creator_id);
CREATE INDEX idx_cd_region ON content_documents(region_name);
CREATE INDEX idx_cd_published ON content_documents(published_at DESC);
CREATE INDEX idx_cd_trending ON content_documents(trending_score DESC) WHERE trending_score > 0;
CREATE INDEX idx_cd_embedding ON content_documents USING hnsw (embedding vector_cosine_ops);
CREATE INDEX idx_cd_source ON content_documents(source_type, source_id);
CREATE INDEX idx_cd_hashtags ON content_documents USING gin (hashtags);
```

### Content Type Mapping

| Source | title | body | media_types | category |
|---|---|---|---|---|
| Post (text) | First 100 chars | Full content | [] | from hashtags |
| Post (photo) | Caption first line | Full caption | ['image'] | from hashtags |
| Post (video) | Caption first line | Full caption | ['video'] | from hashtags |
| Clip | Clip title | Description | ['video'] | from hashtags |
| Music track | Track title | Artist + album + lyrics | ['audio'] | genre |
| Live stream | Stream title | Description | ['video'] | category |
| Event | Event name | Description + location | [] | event type |
| Campaign | Campaign title | Story | [] | campaign category |
| Product | Product name | Description + specs | from media | product category |
| Group | Group name | Description | [] | group type |
| Page | Page name | Description + bio | [] | page category |
| User profile | display_name | Bio + employer + school | [] | N/A |
| Gossip thread | Thread title | First post content | [] | thread category |

---

## 3. Ingestion Pipeline (Trawler)

Processes every content creation/update event into a ContentDocument.

### Flow

```
Content Created/Updated
        │
        ▼
  Laravel Event Fired
  (PostCreated, ClipUploaded, StreamEnded, etc.)
        │
        ▼
  ContentIngestionJob (queued, high priority)
        │
        ├── 1. Extract: Pull source record + relations from PostgreSQL
        ├── 2. Normalize: Map to ContentDocument fields via ContentDocumentFactory
        ├── 3. Detect language (Swahili word frequency heuristic)
        ├── 4. Extract hashtags + mentions from body text
        ├── 5. UPSERT into content_documents table
        │
        ▼
  Fan-out downstream jobs:
        ├── SyncToTypesenseJob (search index, queue: typesense-sync)
        ├── GenerateEmbeddingJob (pgvector, queue: content-embedding)
        └── ClaudeScoreContentJob (AI quality, queue: content-scoring)
```

### Events Listened

```
PostCreated, PostUpdated, PostDeleted
ClipCreated, ClipUpdated
StoryCreated
MusicTrackUploaded
LiveStreamEnded
EventCreated, EventUpdated
CampaignCreated, CampaignUpdated
ProductCreated, ProductUpdated
GroupCreated, GroupUpdated
PageCreated, PageUpdated
UserProfileUpdated
GossipThreadCreated, GossipThreadUpdated
```

### Deletion Handling

When content is deleted:
1. Remove from `content_documents`
2. Remove from Typesense
3. pgvector row gone with the PostgreSQL row

### Initial Backfill

```bash
php artisan content:reindex --all
php artisan content:reindex --type=posts
php artisan content:reindex --since=2026-01-01
```

### Queue Configuration

```
Queue: content-ingestion  (high priority, 4 workers)
Queue: typesense-sync      (high priority, 2 workers)
Queue: content-scoring     (medium priority, 2 workers)
Queue: content-embedding   (low priority, 2 workers)
```

---

## 4. Indexing Pipeline (Alexandria)

### Signal Sources

| Source | Updates | Scores Affected |
|---|---|---|
| Redis Streams (real-time) | Every engagement event | engagement_score, trending_score |
| Claude Haiku (write-time) | On content creation/edit | quality_score, spam_score, category, language |
| NetworkX (hourly batch) | Content graph analysis | content_rank, creator_authority |
| Time Decay (continuous) | Every 5 minutes | freshness_score |
| Creator Data (from profile) | Every 30 minutes | creator_tier, creator_authority |

### Composite Score Formula (Ascorer)

```
composite_score =
    (freshness_score     * w_freshness)     +
    (engagement_score    * w_engagement)    +
    (quality_score * 10  * w_quality)       +
    (content_rank        * w_content_rank)  +
    (creator_authority   * w_creator_auth)  +
    (trending_score      * w_trending)
```

Default weights (stored in `scoring_config` table, tunable without deploys):

| Weight | Default | Purpose |
|---|---|---|
| w_freshness | 0.25 | Recency matters most in social |
| w_engagement | 0.30 | Real-time engagement velocity |
| w_quality | 0.15 | Claude AI quality assessment |
| w_content_rank | 0.15 | Graph authority (shares, replies) |
| w_creator_auth | 0.10 | Creator overall influence |
| w_trending | 0.05 | Spike detection bonus |

### Freshness Score (0-100)

Exponential decay: `freshness_score = 100 * e^(-ln(2) / half_life * hours_since_published)`

| Content Type | Half-Life | Score at 24h | Score at 48h |
|---|---|---|---|
| post | 24 hours | 50 | 25 |
| clip | 48 hours | 71 | 50 |
| music | 168 hours (7 days) | 91 | 82 |
| stream archive | 12 hours | 25 | 6 |
| event | Until event date, then rapid decay | varies | varies |
| product | 336 hours (14 days) | 95 | 91 |
| gossip_thread | 24 hours | 50 | 25 |

### Engagement Score (0-100)

```
raw = views*0.1 + likes*1.0 + comments*2.0 + shares*2.5 + saves*1.8 + replies*3.0 + avg_dwell_sec*0.05
engagement_score = 100 * (1 - e^(-raw / k))
k = normalization constant (~50 for posts)
```

Logarithmic saturation — first 50 engagements matter more than the next 500.

### Trending Score (0-100)

```
velocity = engagements_last_5min / max(engagements_avg_5min_last_24h, 1)
trending_score = min(100, velocity * 20)
```

Velocity > 3x baseline = "rising". Velocity > 10x = "breaking" (triggers push notification).

### Content Tier Assignment (SegIndexer)

| Tier | Composite Score | Treatment |
|---|---|---|
| viral | > 85 | Boosted in all feeds, trending section, push notifications |
| high | 60-85 | Primary index, appears in For You and Discover |
| medium | 30-60 | Standard, appears in following/friends, searchable |
| low | 10-30 | Deprioritized, only direct search or profile visits |
| blackhole | < 10 OR spam_score > 7 | Hidden from all feeds and search |

### Near-Duplicate Detection

Using pgvector cosine similarity > 0.95:
- Newer duplicate gets quality_score penalty (-3 points)
- Same creator duplicating → potential spam flag
- Older document treated as canonical (boosted as original)

### Score Refresh Cadence

| Score | Frequency | Mechanism |
|---|---|---|
| engagement_score | 30 seconds | Redis → PostgreSQL sync (dirty set only, see below) |
| trending_score | 2 minutes | Redis velocity calculator |
| freshness_score | 5 minutes | PostgreSQL batch update |
| composite_score | 2 minutes | Recomputed after components change |
| content_tier | 5 minutes | Derived from composite_score |
| quality_score | Once at write-time | Claude Haiku |
| content_rank | Hourly | NetworkX batch job |
| creator_authority | 30 minutes | Derived from existing creator_scores table (already in backend) |

### Dirty Set Score Sync Mechanism

Only documents with changed scores get synced from Redis to PostgreSQL (not all documents). The signal consumer maintains a Redis Set `scores:dirty` containing document IDs whose scores have changed since the last sync:

```
# When a signal updates a document's engagement_score:
SADD scores:dirty "post:123"

# Score sync worker (every 30s):
dirty_ids = SMEMBERS scores:dirty
DEL scores:dirty
# Batch UPDATE only these documents in PostgreSQL
# Batch UPDATE only these documents in Typesense
```

This ensures the sync worker only touches documents with actual changes — O(changed) not O(total).

---

## 5. Real-Time Signal Processor (NavBoost)

### Signal Flow

```
User Action → EventTrackingService → POST /api/events →
  Store in user_events + XADD to Redis Stream: engagement:signals
```

### Redis Data Structures

**Stream**: `engagement:signals` — ordered log of all events

**Sorted Sets** (pre-computed rankings):
```
trending:global              →  {doc_id: trending_score}
trending:region:{name}       →  {doc_id: trending_score}
trending:category:{cat}      →  {doc_id: trending_score}
trending:hashtag:{tag}       →  {doc_id: trending_score}
feed:user:{id}               →  {doc_id: personalized_score}
```

**Hashes** (per-document counters):
```
signals:{source_type}:{source_id} → {
    views, likes, comments, shares, saves, replies,
    total_dwell_ms, view_count_5min, engagement_5min,
    last_velocity_check
}
```

**Hashes** (per-user interest profile):
```
user:{id}:signals → {
    liked_creators, liked_categories, liked_hashtags,
    avg_dwell_ms, preferred_media, active_hours, last_updated
}
```

### Signal Consumer Workers (3 instances)

**Worker 1 — Document Score Updater**: Increments per-doc counters, recomputes engagement_score, updates trending sorted sets.

**Worker 2 — Trending Detector (Instant Glue)**: Every 2 minutes, checks velocity for active documents. Marks "rising" (>3x baseline), "breaking" (>10x, triggers push), or "cooling" (<0.5x, begins decay).

**Worker 3 — User Profile Updater**: Updates per-user affinity hashes (liked creators, categories, hashtags, media preferences).

### Signal Weights

| Signal | Weight | Rationale |
|---|---|---|
| view (< 2s dwell) | 0.05 | Scroll-past — weak negative |
| view (2-5s dwell) | 0.1 | Glanced |
| view (5-15s dwell) | 0.3 | Partial engagement |
| view (15s+ dwell) | 0.5 | Deep engagement |
| like | 1.0 | Baseline positive |
| save | 1.8 | Intentional bookmark |
| comment | 2.0 | Active engagement |
| share | 2.5 | Endorsement |
| reply | 3.0 | Conversation generation |
| follow (after viewing) | 2.0 | Content converted a follower |
| scroll-past (< 0.5s) | -0.2 | Negative signal |
| "not interested" | -5.0 | Explicit negative |

### Signal Decay (Rolling Windows)

```
Hot:   last 1 hour   — 1.0x weight
Warm:  last 24 hours — 0.5x weight
Cool:  last 7 days   — 0.2x weight
Cold:  last 30 days  — 0.05x weight
```

### Anti-Gaming

1. **Per-user cap**: Max 1 signal per type per document per hour
2. **Velocity squashing**: >100 engagements in 5min from accounts < 7 days old → fraud flag, trending_score capped at 50
3. **Social graph validation**: Accounts with 0 friends + 0 posts → 0.1x signal weight
4. **IP clustering**: >10 engagements same doc same IP in 5min → only first 3 count

---

## 6. Content Graph (PageRank)

### Graph Model

**Nodes**: ContentDocument, Creator

**Edges** (weighted, directed):

| Edge Type | Direction | Weight | Meaning |
|---|---|---|---|
| SHARED | sharer → original | 3.0 | "I endorse this" |
| REPLIED_TO | reply → parent | 2.5 | "This sparked conversation" |
| STITCHED | stitch → original | 2.0 | "I'm building on this" |
| MENTIONED_CREATOR | post → creator | 1.5 | "This person is relevant" |
| HASHTAG_CO_OCCURRENCE | doc ↔ doc | 0.5 | "Same topic" |
| SAME_THREAD | post ↔ post | 1.0 | "Part of one story" |
| CREATOR_OF | creator → doc | 1.0 | Authority flows from creator |
| FOLLOWED_THEN_CREATED | doc → creator | 2.0 | "Content earned a follow" |

### Storage

```sql
CREATE TABLE content_graph_edges (
    id          BIGSERIAL PRIMARY KEY,
    source_type VARCHAR(20) NOT NULL,
    source_id   BIGINT NOT NULL,
    target_type VARCHAR(20) NOT NULL,
    target_id   BIGINT NOT NULL,
    edge_type   VARCHAR(30) NOT NULL,
    weight      FLOAT DEFAULT 1.0,
    created_at  TIMESTAMP DEFAULT NOW(),

    UNIQUE(source_type, source_id, target_type, target_id, edge_type)
);

CREATE INDEX idx_cge_source ON content_graph_edges(source_type, source_id);
CREATE INDEX idx_cge_target ON content_graph_edges(target_type, target_id);
CREATE INDEX idx_cge_type ON content_graph_edges(edge_type);
```

### ContentRank Computation

Python script via NetworkX, runs hourly as cron:
- Builds directed graph from content_graph_edges
- Excludes blackhole-tier documents
- Runs `nx.pagerank(G, alpha=0.85, weight='weight', max_iter=100)`
- Normalizes scores to 0-100
- Writes document `content_rank` and creator `creator_authority` back to PostgreSQL

### Authority Properties

- **content_rank** (per document): Authority THIS content earned through shares, replies, stitches
- **creator_authority** (per creator): Overall creator influence. New content from high-authority creators gets a baseline composite_score floor.

---

## 7. Serving Pipeline (SuperRoot + Mustang)

### Two Serving Modes

```
SEARCH: query string + user_id + filters → ranked results across all types
FEED:   feed_type + user_id + page → ranked content (search with empty query, personalized)
```

### Pipeline

```
1. Query Understanding (search mode only)
   ├── Typesense instant search (keyword, ~50ms)
   ├── Claude query expansion (async, Swahili↔English, ~800ms)
   └── Intent classification (find_person? find_content? find_music?)

2. Candidate Generation (fan-out, parallel)
   ├── Typesense: keyword match candidates (up to 200)
   ├── pgvector: semantic similarity candidates (up to 100)
   ├── Redis: trending candidates for user's region (up to 50)
   ├── Redis: personalized candidates from user:signals (up to 100)
   └── PostgreSQL: social graph candidates (friends' content, up to 100)

3. Merge & Deduplicate & Privacy Filter
   → Remove duplicates by source_type+source_id
   → Remove documents where privacy='friends' and creator is not a friend
   → Remove documents where privacy='private' (only visible on creator's profile)
   → Remove documents from blocked users (BlockedUser::getAllBlockedIds)
   → Typical result: 300-500 unique candidates

4. Personalized Scoring (Ascorer)
   base = composite_score (pre-computed, same for all users)
   + creator_affinity (max +15): have I engaged with this creator?
   + category_affinity (max +10): do I engage with this category?
   + hashtag_affinity (max +8): have I engaged with these hashtags?
   + media_preference (max +5): do I prefer video over text?
   + social_proximity (+20 friend, +8 friend-of-friend)
   + regional_proximity (+5 same region, +3 same district)

5. Re-rank (Twiddlers)
   ├── Diversity: no 3+ same creator, no 5+ same content_type consecutive
   ├── Freshness: content < 1h → 1.2x, content < 15min → 1.4x
   ├── Exploration: 10% from unseen creators/categories (30% for new users)
   ├── Sponsored insertion: positions 4, 12, 24
   ├── Anti-bubble: 5% from outside user's interest profile
   └── Streak bonus: active creator streak → 1.1x

6. Paginate & Hydrate full source records

7. Cache in Redis (60s for feeds, 300s for search)
```

### Candidate Generation by Feed Type

| Feed Type | Typesense | pgvector | Redis Trending | Redis Personal | Social Graph |
|---|---|---|---|---|---|
| for_you | — | 100 similar | 50 regional | 100 from affinity | 50 from friends |
| friends | — | — | — | — | ALL from friends |
| discover | — | 100 diverse | 100 global | — | Exclude friends |
| trending | — | — | 200 global | — | — |
| nearby | — | — | 100 regional | — | 50 same-region |
| shorts | filter: video | — | 50 trending clips | 50 video affinity | — |
| audio | filter: media_types contains 'audio' OR source_type='music' | — | 50 trending audio | 50 audio affinity | — |
| search | 200 keyword | 100 semantic | 30 trending | — | — |

### API Endpoints

```
GET /api/v2/search
  ?q=...&user_id=...&types=...&category=...&region=...
  &tier=...&sort=relevance|trending|newest&page=...&per_page=...

GET /api/v2/feed
  ?feed_type=for_you|friends|discover|trending|nearby|shorts|audio
  &user_id=...&page=...&per_page=...
```

### Response Format

```json
{
  "success": true,
  "data": [
    {
      "document": {
        "id": 456,
        "source_type": "post",
        "source_id": 123,
        "title": "Bongo Flava mpya...",
        "content_tier": "high",
        "scores": { "composite": 72.5, "personalized": 85.3, "trending": 45.0 }
      },
      "source": { "/* Full hydrated Post/Clip/Music/etc. */" },
      "context": {
        "reason": "trending_in_region",
        "is_sponsored": false,
        "is_exploration": false
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total_candidates": 342,
    "served_from_cache": false,
    "query_time_ms": 85
  }
}
```

### Caching Strategy

```
Layer 1: feed:{user_id}:{feed_type}:page:{n} — TTL 60s, invalidated on user engagement
Layer 2: search:{query_hash}:{filters_hash}:page:{n} — TTL 300s, shared across users
Layer 3: candidates:trending:{scope} — TTL 120s, pre-computed by trending detector
```

---

## 8. AI Intelligence Layer (Gemini)

All AI powered by Claude CLI installed on the server.

### 8.1 Content Scorer (Write-time, Haiku)

Scores every new content on: quality (0-10), spam (0-10), category, language.
Non-blocking — content is searchable before Claude finishes. Scores applied retroactively.
Cost: ~$0.0002/post.

### 8.2 Query Expander (Read-time, Haiku)

Expands search queries: intent classification, entity extraction, Swahili↔English cross-language expansion, type boosting.
Runs in parallel with Typesense — if Claude returns within 800ms, merge expanded results.

Example: "nyimbo mpya bongo" → expanded: ["new bongo flava songs", "latest tanzanian music"], type_boost: "music"

### 8.3 Trending Digest Generator (Batch, Sonnet, every 4h)

Generates "Kinachoendelea Sasa" (What's Happening Now) — 3-5 story summaries from top trending content. Stored in `trending_digests` table. Shown on Discover tab.

### 8.4 Creator Coach (Batch, Sonnet, weekly)

Personalized Swahili coaching advice per creator: what worked, what to try, optimal posting times, trending opportunities, hashtag suggestions. Surfaced in Creator Dashboard.

### 8.5 Content Moderator (Batch, Sonnet, every 30min)

Reviews flagged content (high spam_score or user reports). Actions: approve, warn, hide, ban_content, escalate. Tanzanian cultural context awareness (religious content is normal, Sheng slang is not profanity).

### 8.6 Embedding Text Generator (Write-time, Haiku)

Generates rich English description from raw content (which may be short, emoji-heavy, or Swahili) for better embedding quality. The description gets embedded via local model.

### Cost Estimation

```
Content scoring (Haiku):     10,000 posts/day × $0.0002 = $2.00/day
Query expansion (Haiku):     50,000 searches/day × $0.0001 = $5.00/day (cached: ~$2/day effective)
Trending digest (Sonnet):    6/day × $0.005 = $0.03/day
Creator coaching (Sonnet):   1,000 creators/week × $0.003 = $0.43/day
Content moderation (Sonnet): 100/day × $0.003 = $0.30/day
Embedding text (Haiku):      10,000/day × $0.0001 = $1.00/day

TOTAL: ~$5.76/day (~$173/month) with caching
```

### Fallback Strategy

No Claude failure blocks the core pipeline:

| Feature | Fallback |
|---|---|
| Content scoring | quality_score=5, spam_score=0 |
| Query expansion | Typesense keyword results only |
| Trending digest | Serve previous digest |
| Creator coaching | Skip, retry next cycle |
| Content moderation | Queue for human review |
| Embedding text | Use raw content for embedding |

---

## 9. Frontend — Search + Discovery

### New Service: ContentEngineService

Follows the static-method pattern used by most TAJIRI services. For feature flag fallback to the existing `FeedService` (which is also static-method based), the `feed()` method wraps old results via `ContentEngineResult.fromLegacy()`.

```dart
class ContentEngineService {
  static Future<ContentEngineResult> search({
    required String query, required int userId,
    List<String>? types, String? category, String? region,
    String sort = 'relevance', int page = 1, int perPage = 20,
  });

  static Future<ContentEngineResult> feed({
    required String feedType, required int userId,
    int page = 1, int perPage = 20,
  });

  static Future<ContentEngineResult> similar({
    required int documentId, required int userId, int limit = 10,
  });

  static Future<TrendingDigest> getTrendingDigest();

  static Future<AutocompleteSuggestions> autocomplete({
    required String prefix, required int userId, int limit = 8,
  });

  static Future<void> markNotInterested({
    required int documentId, required int userId,
  });
}
```

### New Models

- `ContentEngineResult` — wraps list of ContentDocuments + meta
- `ContentDocument` — unified result with sourceType, scores, context, hydrated source
- `ContentScores` — composite, personalized, trending
- `ContentContext` — reason (why shown), isSponsored, isExploration
- `TrendingDigest` — headline, stories, mood
- `AutocompleteSuggestions` — queries, hashtags, people matches

### Universal Search Screen

Three states:
1. **Before typing**: Trending Digest card + trending hashtags + algorithm-driven suggestions
2. **While typing**: Autocomplete (search completions + hashtag matches + people matches)
3. **After search**: Type filter tabs (All | Posts | Clips | Music | People | ...) + mixed results with context labels

### ContentResultCard Widget

Router widget that renders the correct card per sourceType:
- post → PostCard
- clip → ClipResultCard (new)
- music → MusicResultCard (new)
- user_profile → UserResultCard (existing)
- stream → StreamResultCard (new)
- event → EventResultCard (new)
- campaign → CampaignResultCard (new)
- product → ProductResultCard (new)
- gossip_thread → GossipThreadCard (existing)
- group → GroupResultCard (new)
- page → PageResultCard (new)

### Enhanced Event Tracking

New signals via VisibilityDetector on PostCard:
- `trackView(postId, creatorId, dwellMs)` — dwell time measurement
- `trackScrollPast(postId, creatorId)` — visible < 0.5s
- `trackNotInterested(postId, creatorId)` — explicit "Sipendezwi na hii" menu option

### Feed Integration

FeedScreen migrated to use `ContentEngineService.feed()` with feature flag fallback to old `FeedService`. For You and Discover tabs now return mixed content types.

### New Widgets

| Widget | Purpose |
|---|---|
| UniversalSearchScreen | Replaces SearchScreen |
| ContentResultCard | Router for type-specific cards |
| TrendingDigestCard | AI "Kinachoendelea Sasa" summary |
| ClipResultCard | Compact clip preview |
| MusicResultCard | Track card with play button |
| StreamResultCard | Stream archive card |
| EventResultCard | Event card |
| CampaignResultCard | Michango campaign card |
| GroupResultCard | Group card |
| PageResultCard | Page card |

---

## 10. Infrastructure & Deployment

### Services

```
Existing:  PostgreSQL, Redis, Nginx, Supervisor, Claude CLI, PHP 8.2, Laravel 12
New:       Typesense (100MB RAM), pgvector extension, Python 3 + NetworkX,
           Embedding microservice (multilingual-e5-base, 1-2GB RAM)
```

### Typesense Collection

Mirrors content_documents with all searchable/filterable/sortable fields. Default sort: composite_score. Token separators: # and @.

### Queue Workers (Supervisor, 16 processes)

```
content-ingestion:   4 workers (high priority)
typesense-sync:      2 workers (high priority)
content-scoring:     2 workers (medium priority)
content-embedding:   2 workers (low priority)
signal-consumer:     3 workers (Redis stream consumers)
score-sync:          1 worker (Redis → PostgreSQL → Typesense, every 30s)
trending-detector:   1 worker (velocity calculation, every 2 min)
```

### Cron Jobs

```
*/2 * * * *    content:recompute-composite
*/5 * * * *    content:refresh-freshness
*/5 * * * *    content:assign-tiers
*/30 * * * *   content:sync-creator-authority
0 * * * *      /opt/tajiri-graph/content_rank.py (ContentRank/PageRank)
0 */4 * * *    content:generate-digest
*/30 * * * *   content:moderate-flagged
0 3 * * 0      content:generate-coaching (weekly)
0 0 * * *      content:cleanup-signals --older-than=30d
0 1 * * *      content:reconcile-typesense
```

### Health Check

`php artisan content:health-check` — verifies all subsystems (PostgreSQL, pgvector, Typesense, Redis, embedding service, Claude CLI, queue workers, ContentRank recency, score sync lag).

### Resource Requirements

```
Minimum:     16 GB RAM, 8 cores
Comfortable: 32 GB RAM, 16 cores
```

---

## 11. Migration Strategy

### Phases

```
Phase 0: Foundation (no user-visible changes)
  Install services, create tables, build ingestion pipeline, backfill data

Phase 1: Indexing pipeline live (no user-visible changes)
  Wire events, start workers, verify real-time indexing

Phase 2: Signal processing live (minimal changes)
  Enhanced EventTrackingService, Redis Streams, signal consumers

Phase 3: Search goes live (user-visible)
  /api/v2/search, UniversalSearchScreen, autocomplete, TrendingDigest

Phase 4: Feeds migrated (user-visible)
  /api/v2/feed for For You, Discover, Trending, Nearby tabs

Phase 5: AI features live
  Trending digests, creator coaching, content moderation, "More Like This"

Phase 6: Retire old endpoints
  Monitor, deprecate, redirect internally
```

### Feature Flags

Schema defined in Appendix A (`feature_flags` table). 11 flags controlling: search, each feed type, AI digest, AI coaching, AI moderation, query expansion, dwell tracking, more-like-this. Rollout percentage enables A/B testing (`user_id % 100 < rollout_pct`).

### Backward Compatibility

- All existing `/api/feed/*` and `/api/posts/*` endpoints continue working
- New `/api/v2/*` endpoints are additive
- Flutter `ContentEngineService` checks feature flags, falls back to old `FeedService`
- `ContentEngineResult.fromLegacy()` wraps old response format
- All new migrations are additive (no existing tables modified)

### Rollback

Every phase independently rollable:
- Phase 0-2: Stop workers (30 seconds)
- Phase 3-5: Set feature flags to false (instant)

### Data Integrity

Daily `php artisan content:reconcile` checks:
- Index coverage (every source record has a content_document)
- Typesense sync completeness
- Orphaned documents
- Embedding coverage percentage
- Score freshness
- Redis ↔ PostgreSQL score drift

---

## Appendix: Supporting Tables

```sql
CREATE TABLE scoring_config (
    key VARCHAR(50) PRIMARY KEY, value FLOAT NOT NULL,
    description TEXT, updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE trending_digests (
    id BIGSERIAL PRIMARY KEY, headline_sw TEXT NOT NULL, headline_en TEXT NOT NULL,
    stories JSONB NOT NULL, mood VARCHAR(30),
    generated_at TIMESTAMP DEFAULT NOW(), valid_until TIMESTAMP
);

CREATE TABLE creator_coaching (
    id BIGSERIAL PRIMARY KEY, creator_id BIGINT NOT NULL,
    advice JSONB NOT NULL, week_start DATE NOT NULL,
    generated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(creator_id, week_start)
);

CREATE TABLE feature_flags (
    key VARCHAR(50) PRIMARY KEY, enabled BOOLEAN DEFAULT false,
    rollout_pct INTEGER DEFAULT 0, description TEXT,
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE content_tier_history (
    id BIGSERIAL PRIMARY KEY, document_id BIGINT NOT NULL,
    old_tier VARCHAR(20), new_tier VARCHAR(20),
    composite_score FLOAT, changed_at TIMESTAMP DEFAULT NOW()
);

-- User engagement events (permanent storage for signal pipeline)
-- Note: user_events table may already exist in the backend from EventTrackingService.
-- If not, create it:
CREATE TABLE user_events (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    event_type  VARCHAR(30) NOT NULL,  -- view, like, comment, share, save, follow, unfollow, scroll_past, not_interested
    post_id     BIGINT,
    creator_id  BIGINT,
    duration_ms INTEGER DEFAULT 0,
    session_id  UUID,
    metadata    JSONB,
    created_at  TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_ue_user ON user_events(user_id, created_at DESC);
CREATE INDEX idx_ue_post ON user_events(post_id) WHERE post_id IS NOT NULL;
CREATE INDEX idx_ue_type ON user_events(event_type, created_at DESC);

-- Content categories controlled vocabulary
CREATE TABLE content_categories (
    slug        VARCHAR(50) PRIMARY KEY,  -- entertainment, music, sports, news, etc.
    name_en     VARCHAR(100) NOT NULL,
    name_sw     VARCHAR(100) NOT NULL
);

INSERT INTO content_categories (slug, name_en, name_sw) VALUES
('entertainment', 'Entertainment', 'Burudani'),
('music', 'Music', 'Muziki'),
('sports', 'Sports', 'Michezo'),
('news', 'News', 'Habari'),
('business', 'Business', 'Biashara'),
('education', 'Education', 'Elimu'),
('lifestyle', 'Lifestyle', 'Mtindo wa Maisha'),
('technology', 'Technology', 'Teknolojia'),
('politics', 'Politics', 'Siasa'),
('religion', 'Religion', 'Dini'),
('food', 'Food', 'Chakula'),
('travel', 'Travel', 'Safari'),
('fashion', 'Fashion', 'Mitindo'),
('health', 'Health', 'Afya'),
('comedy', 'Comedy', 'Vichekesho'),
('other', 'Other', 'Nyingine');
```

---

## Appendix B: Source Type Enum Values

Exact string values used in `content_documents.source_type`:

```
post, clip, story, music, stream, event, campaign,
product, group, page, user_profile, gossip_thread
```

---

## Appendix C: Typesense Collection Schema

```json
{
  "name": "content_documents",
  "fields": [
    {"name": "id", "type": "string"},
    {"name": "source_type", "type": "string", "facet": true},
    {"name": "source_id", "type": "int64"},
    {"name": "title", "type": "string", "optional": true},
    {"name": "body", "type": "string", "optional": true},
    {"name": "hashtags", "type": "string[]", "facet": true},
    {"name": "mentions", "type": "string[]"},
    {"name": "language", "type": "string", "facet": true, "optional": true},
    {"name": "creator_id", "type": "int64"},
    {"name": "creator_tier", "type": "string", "facet": true, "optional": true},
    {"name": "category", "type": "string", "facet": true, "optional": true},
    {"name": "content_tier", "type": "string", "facet": true},
    {"name": "media_types", "type": "string[]", "facet": true},
    {"name": "region_name", "type": "string", "facet": true, "optional": true},
    {"name": "district_name", "type": "string", "facet": true, "optional": true},
    {"name": "privacy", "type": "string"},
    {"name": "composite_score", "type": "float", "sort": true},
    {"name": "engagement_score", "type": "float", "sort": true},
    {"name": "freshness_score", "type": "float", "sort": true},
    {"name": "trending_score", "type": "float", "sort": true},
    {"name": "quality_score", "type": "float"},
    {"name": "content_rank", "type": "float"},
    {"name": "creator_authority", "type": "float"},
    {"name": "published_at", "type": "int64", "sort": true},
    {"name": "indexed_at", "type": "int64"}
  ],
  "default_sorting_field": "composite_score",
  "token_separators": ["#", "@"]
}
```

---

## Appendix D: Embedding Microservice Specification

A lightweight Python Flask service that generates 768-dim text embeddings.

### API Contract

```
POST http://localhost:8200/embed
Content-Type: application/json

Request:  {"text": "Bongo Flava mpya ya Diamond..."}
Response: {"embedding": [0.021, -0.034, ...], "dimensions": 768}

POST http://localhost:8200/embed/batch
Request:  {"texts": ["text1", "text2", ...]}  (max 50 per batch)
Response: {"embeddings": [[...], [...]], "dimensions": 768}

GET http://localhost:8200/health
Response: {"status": "ok", "model": "multilingual-e5-base", "dimensions": 768}
```

### Deployment

```
Location:     /opt/tajiri-embedding/
Virtual env:  /opt/tajiri-embedding/venv/
Model:        intfloat/multilingual-e5-base (560MB download, cached locally)
RAM usage:    ~1.5GB when loaded
Port:         8200 (localhost only, not exposed externally)
Timeout:      10s per request, 60s per batch
Retry policy: Laravel GenerateEmbeddingJob retries 2x with 30s backoff
```

### Systemd Service

```ini
[Unit]
Description=TAJIRI Embedding Service
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/tajiri-embedding
ExecStart=/opt/tajiri-embedding/venv/bin/python server.py
Restart=always
Environment=MODEL_NAME=intfloat/multilingual-e5-base

[Install]
WantedBy=multi-user.target
```

---

## Appendix E: NetworkX ContentRank Deployment

### Location and Dependencies

```
Script:       /opt/tajiri-graph/content_rank.py
Virtual env:  /opt/tajiri-graph/venv/
Dependencies: networkx==3.3, psycopg2-binary==2.9, numpy==1.26
```

### Database Authentication

Uses a dedicated read-write PostgreSQL user:
```
DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=tajiri
DB_USER=tajiri_graph
DB_PASSWORD=(stored in /opt/tajiri-graph/.env, not in code)
```

### Performance Expectations

| Graph Size | Nodes | Edges | Execution Time | RAM |
|---|---|---|---|---|
| Current (UAT) | ~200 | ~500 | < 1 second | ~50MB |
| 10K users, 50K posts | ~60K | ~200K | ~5 seconds | ~200MB |
| 100K users, 500K posts | ~600K | ~2M | ~30 seconds | ~1GB |
| 1M users, 5M posts | ~6M | ~20M | ~5 minutes | ~4GB |

If execution exceeds 10 minutes, the script logs a warning and considers graph pruning (exclude documents older than 90 days from the graph computation, apply last-known content_rank to pruned nodes).

### Error Handling

- Script logs to `/var/log/tajiri/content_rank.log`
- On database connection failure: exit with code 1, cron retries next hour
- On computation failure: log error, do not overwrite existing scores
- On write-back failure: retry 3x with 10s backoff, then log and exit

---

## Appendix F: Result Card Display Specifications

What each new result card widget shows in search/feed results:

### ClipResultCard
- Thumbnail (first frame or poster)
- Duration badge (bottom-right)
- Title (max 2 lines, ellipsis)
- Creator avatar + name
- View count + like count
- Tap → opens clip player

### MusicResultCard
- Album art thumbnail (square, 56x56)
- Track title (max 1 line)
- Artist name (secondary text)
- Duration
- Play button (inline, streams preview)
- Tap → opens music player sheet

### StreamResultCard
- Stream thumbnail or last frame
- "LIVE" badge (red) or "Archive" badge (gray)
- Title (max 2 lines)
- Viewer count (peak viewers for archives)
- Creator avatar + name
- Tap → opens stream viewer

### EventResultCard
- Event cover image (or category icon)
- Event name (max 2 lines)
- Date + time (formatted for EAT timezone)
- Location (max 1 line)
- RSVP count ("45 wanaenda" / "45 going")
- Tap → opens event detail

### CampaignResultCard
- Campaign cover image
- Campaign title (max 2 lines)
- Progress bar (raised / goal)
- Percentage funded
- Days remaining
- Tap → opens campaign detail

### GroupResultCard
- Group avatar/cover
- Group name (max 1 line)
- Member count
- Privacy badge (Public/Private/Secret)
- "Join" button (if not member)
- Tap → opens group detail

### PageResultCard
- Page avatar
- Page name (max 1 line)
- Category
- Follower count
- "Follow" button (if not following)
- Tap → opens page detail

### ProductResultCard
- Product image (square, 80x80)
- Product name (max 2 lines)
- Price (formatted with TZS)
- Seller name
- Rating stars (if reviews exist)
- Tap → opens product detail

All cards follow TAJIRI design guidelines: 12px border radius, 48dp minimum touch targets, maxLines + TextOverflow.ellipsis, monochromatic palette.

---

## Appendix G: Ingestion Pipeline Error Handling

### Retry Policy

| Job | Max Retries | Backoff | Dead Letter |
|---|---|---|---|
| ContentIngestionJob | 3 | 5s, 15s, 60s | Log + alert |
| SyncToTypesenseJob | 3 | 5s, 15s, 60s | Mark as unsynced |
| GenerateEmbeddingJob | 2 | 30s, 120s | Skip (null embedding) |
| ClaudeScoreContentJob | 2 | 30s, 120s | Use defaults (quality=5, spam=0) |

### Partial Processing Detection

The `content:reconcile` artisan command detects partially-processed documents:

```sql
-- Documents ingested but never scored by Claude
SELECT id, source_type, source_id FROM content_documents
WHERE quality_score = 0 AND spam_score = 0 AND indexed_at < NOW() - INTERVAL '1 hour';

-- Documents ingested but never embedded
SELECT id, source_type, source_id FROM content_documents
WHERE embedding IS NULL AND indexed_at < NOW() - INTERVAL '1 hour';

-- Documents in PostgreSQL but missing from Typesense
-- (checked by comparing counts and sampling IDs)
```

The reconciliation command re-dispatches failed jobs for any documents found in these states.

---

## Appendix H: Resource Scaling Guide

| Scale | Users | Posts/Day | Server Spec | Notes |
|---|---|---|---|---|
| Current (UAT) | 28 | ~5 | 4GB RAM, 2 cores | All services run fine |
| Early growth | 1,000 | 500 | 8GB RAM, 4 cores | Reduce workers to 8 total |
| Medium | 10,000 | 5,000 | 16GB RAM, 8 cores | Full worker count (16) |
| Growth | 100,000 | 50,000 | 32GB RAM, 16 cores | Consider dedicated Redis server |
| Scale | 1,000,000+ | 500,000+ | Split services across multiple servers | Typesense on own server, Redis cluster, PostgreSQL read replicas |
