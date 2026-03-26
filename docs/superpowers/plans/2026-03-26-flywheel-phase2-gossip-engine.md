# Flywheel Phase 2: Gossip Engine + Personalized Feed — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** First user-visible Flywheel features — gossip threads that group trending posts into browsable stories, a personalized feed ranked by AI, and thread cards injected into the main feed.

**Architecture:** Backend creates `gossip_threads`, `gossip_thread_posts`, `thread_title_templates` tables with CRUD endpoints. Thread detection runs every 5 min (velocity spike → Claude CLI clustering → template title). Frontend adds `GossipThread` model, `GossipService`, `ThreadViewerScreen`, `GossipThreadCard` widget, thread badge on PostCard, and switches the For You feed to the personalized endpoint.

**Tech Stack:** Flutter/Dart, http package, existing PostCard/FeedService patterns, AppStrings bilingual, Material 3 monochromatic design system

**Spec:** `docs/superpowers/specs/2026-03-26-tajiri-flywheel-growth-engine-design.md` (Sections 5, 7, 8 — Phase 2)

---

## File Structure

### New Files (Create)

| File | Responsibility |
|------|---------------|
| `lib/models/gossip_models.dart` | `GossipThread`, `GossipThreadPost`, `ThreadTitleTemplate` models with `fromJson`. Thread status enum (active/cooling/archived). |
| `lib/services/gossip_service.dart` | Instance-based service. `getThreads()`, `getThread(id)`, `getDigest()`. Calls `/api/gossip/threads`, `/api/gossip/threads/{id}`, `/api/gossip/digest`. |
| `lib/screens/feed/thread_viewer_screen.dart` | Full gossip thread screen: title bar, seed post, related posts in engagement-ranked order, live counter, pull-to-refresh. |
| `lib/widgets/gossip_thread_card.dart` | Compact card injected into feed every 8-12 posts. Shows thread title, post count, velocity indicator, top reaction. Tap opens ThreadViewerScreen. |
| `lib/widgets/thread_badge.dart` | Small "Part of trending thread" badge shown on PostCard when `threadId != null`. |
| `test/models/gossip_models_test.dart` | Unit tests for GossipThread/GossipThreadPost fromJson. |
| `test/services/gossip_service_test.dart` | Unit tests for GossipService. |

### Modified Files

| File | Change |
|------|--------|
| `lib/main.dart` | Add route `/thread/:threadId` → ThreadViewerScreen. |
| `lib/widgets/post_card.dart` | Show ThreadBadge when `post.threadId != null`. |
| `lib/screens/feed/discover_feed_content.dart` | Replace Trending section with GossipThreadCard list from gossip/threads endpoint. Add filter chips (All, Entertainment, Business, Music, Sports, Local). |
| `lib/services/feed_service.dart` | Add `getPersonalizedFeed()` method calling `GET /api/feed/personalized` with fallback to `getForYouFeed()`. |
| `lib/screens/feed/feed_screen.dart` | Switch Posts tab from `getPostsFeed()` to `getPersonalizedFeed()` with fallback. |
| `lib/l10n/app_strings.dart` | Add gossip/thread bilingual strings. |

---

## Task 1: Backend Directive — Gossip Tables, Templates & Endpoints

**Files:**
- Run: `./scripts/ask_backend.sh`

- [ ] **Step 1: Send directive for gossip tables and endpoints**

```bash
./scripts/ask_backend.sh --type implement --context "Flywheel Phase 2 — Gossip Engine" --ref "user_events and creator_scores tables from Phase 1" "Create these database tables with migrations:

1. gossip_threads table:
   - id (bigint, primary key)
   - seed_post_id (bigint, foreign key to posts, indexed)
   - title_key (string, nullable — maps to thread_title_templates.key)
   - title_slots (json, nullable — slot values for template)
   - category (string: entertainment, business, music, sports, local, general — indexed)
   - velocity_score (decimal 8,2 default 0)
   - post_count (integer default 1)
   - participant_count (integer default 1)
   - status (string: active, cooling, archived — default active, indexed)
   - geographic_scope (string: global, national, local — default global)
   - latitude (decimal 10,7 nullable)
   - longitude (decimal 10,7 nullable)
   - cooling_since (datetime, nullable)
   - created_at, updated_at timestamps
   - Index on (status, velocity_score DESC) for trending queries
   - Index on (status, category) for filtered queries

2. gossip_thread_posts table:
   - id (bigint, primary key)
   - thread_id (bigint, foreign key to gossip_threads, indexed)
   - post_id (bigint, foreign key to posts, indexed)
   - relevance_score (decimal 5,2 default 0)
   - added_at (datetime)
   - created_at, updated_at timestamps
   - Unique index on (thread_id, post_id) — a post can belong to multiple threads but only once per thread

3. thread_title_templates table:
   - id (bigint, primary key)
   - key (string, unique indexed — e.g. trending_entertainment_hot)
   - template_en (string — English template with {slot} placeholders)
   - template_sw (string — Swahili template with {slot} placeholders)
   - slots (json — array of slot names this template expects)
   - category (string: entertainment, business, music, sports, local, general)
   - tone (string: hot, breaking, milestone, battle, local)
   - is_active (boolean default true)
   - created_at, updated_at timestamps

Also seed ~30 bilingual thread title templates. Examples:
- key: trending_hot, en: '{category} Is On Fire', sw: '{category} Imewaka', slots: [category], tone: hot
- key: trending_breaking, en: 'Breaking: {topic}', sw: 'Mpya: {topic}', slots: [topic], tone: breaking
- key: trending_viral, en: '{count}+ People Talking About This', sw: 'Watu {count}+ Wanazungumzia Hii', slots: [count], tone: hot
- key: trending_battle, en: '{creator_a} vs {creator_b}', sw: '{creator_a} dhidi ya {creator_b}', slots: [creator_a, creator_b], tone: battle
- key: trending_milestone, en: '{creator} Just Hit {milestone}', sw: '{creator} Amefika {milestone}', slots: [creator, milestone], tone: milestone
- key: trending_local, en: 'Happening Near You: {topic}', sw: 'Kinachoendelea Karibu Nawe: {topic}', slots: [topic], tone: local
- key: trending_music, en: '{track} Is Taking Over', sw: '{track} Inashika', slots: [track], tone: hot
- key: trending_sports, en: 'Game Day: {event}', sw: 'Siku ya Mchezo: {event}', slots: [event], tone: hot
- key: trending_business, en: 'Market Buzz: {topic}', sw: 'Habari za Soko: {topic}', slots: [topic], tone: hot
- key: trending_general, en: 'Everyone Is Talking About {topic}', sw: 'Kila Mtu Anazungumzia {topic}', slots: [topic], tone: hot
Create at least 25-30 more variations across all categories and tones.

Create these API endpoints (all require Bearer token auth):

1. GET /api/gossip/threads
   - Query params: status (default: active), category (optional filter), page, per_page (default 20)
   - Returns: { data: [{ id, seed_post_id, title_en, title_sw (resolved from template+slots), category, velocity_score, post_count, participant_count, status, geographic_scope, created_at, seed_post: { id, content, user: { id, name, avatar_url }, media: [...] } }], meta: { current_page, last_page, total } }
   - Ordered by velocity_score DESC
   - For the title resolution: look up thread_title_templates by title_key, fill slots from title_slots JSON, return both title_en and title_sw

2. GET /api/gossip/threads/{id}
   - Returns: { data: { id, title_en, title_sw, category, velocity_score, post_count, participant_count, status, seed_post: {...}, posts: [{ id, content, user: {...}, media: [...], likes_count, comments_count, shares_count, relevance_score, created_at }] } }
   - Posts ordered by relevance_score DESC then created_at DESC

3. GET /api/gossip/digest
   - Returns top 3-5 active threads personalized for the user (or just top by velocity for now)
   - Response: { data: { threads: [...], proverb: { text_en, text_sw } } }
   - Proverb: pick a random one from a hardcoded list of ~30 Swahili proverbs (seed them)

4. GET /api/feed/personalized
   - For now: return the same as /api/posts/feed/for-you but add thread_id and thread_title fields to posts that belong to active gossip threads
   - Query params: page, per_page
   - Response same as existing feed endpoints: { data: [...posts...], meta: {...} }
   - This endpoint will be enhanced with Claude CLI ranking in a future iteration"
```

- [ ] **Step 2: Verify backend confirms status: done**

- [ ] **Step 3: Send directive for thread detection job**

```bash
./scripts/ask_backend.sh --type implement --context "Flywheel Phase 2 — Thread Detection" --ref "gossip_threads table we just created" "Create a Laravel scheduled command DetectGossipThreads that runs every 5 minutes:

1. Calculate velocity for recent posts (last 6 hours):
   velocity = (likes_count + comments_count*2 + shares_count*3) / max(hours_since_posted, 0.1)

2. Flag posts where velocity > 2x their creator's 30-day average velocity

3. Group flagged posts by shared hashtags (2+ common hashtags = same group):
   - For each group of 3+ posts: create a gossip_thread
   - Set seed_post_id to highest-velocity post
   - Set category based on most common hashtag category (map hashtags to categories)
   - Set title_key to a matching template (by category+tone), fill title_slots
   - Add all group posts to gossip_thread_posts with relevance_score = their velocity

4. Update existing active threads:
   - Recalculate velocity_score as average of member post velocities
   - If velocity_score < 10 for 6+ hours: set status to cooling, set cooling_since
   - If cooling_since > 48 hours ago: set status to archived

5. Add new high-velocity posts to existing active threads if they share 2+ hashtags with thread posts

Log: N new threads created, N threads updated, N threads archived."
```

- [ ] **Step 4: Verify backend confirms status: done**

- [ ] **Step 5: Commit (backend handles its own commits)**

---

## Task 2: Create Gossip Models

**Files:**
- Create: `lib/models/gossip_models.dart`
- Create: `test/models/gossip_models_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/models/gossip_models_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/models/gossip_models.dart';

void main() {
  group('ThreadStatus', () {
    test('fromString parses valid statuses', () {
      expect(ThreadStatus.fromString('active'), ThreadStatus.active);
      expect(ThreadStatus.fromString('cooling'), ThreadStatus.cooling);
      expect(ThreadStatus.fromString('archived'), ThreadStatus.archived);
    });

    test('fromString defaults to active for unknown', () {
      expect(ThreadStatus.fromString('unknown'), ThreadStatus.active);
      expect(ThreadStatus.fromString(null), ThreadStatus.active);
    });
  });

  group('GossipThread', () {
    test('fromJson parses full thread', () {
      final thread = GossipThread.fromJson({
        'id': 42,
        'seed_post_id': 100,
        'title_en': 'Bongo Flava Is On Fire',
        'title_sw': 'Bongo Flava Imewaka',
        'category': 'entertainment',
        'velocity_score': 85.5,
        'post_count': 23,
        'participant_count': 18,
        'status': 'active',
        'geographic_scope': 'national',
        'created_at': '2026-03-26T10:00:00.000Z',
      });
      expect(thread.id, 42);
      expect(thread.seedPostId, 100);
      expect(thread.titleEn, 'Bongo Flava Is On Fire');
      expect(thread.titleSw, 'Bongo Flava Imewaka');
      expect(thread.category, 'entertainment');
      expect(thread.velocityScore, 85.5);
      expect(thread.postCount, 23);
      expect(thread.participantCount, 18);
      expect(thread.status, ThreadStatus.active);
    });

    test('fromJson handles minimal data', () {
      final thread = GossipThread.fromJson({'id': 1});
      expect(thread.id, 1);
      expect(thread.postCount, 0);
      expect(thread.status, ThreadStatus.active);
      expect(thread.category, 'general');
    });

    test('title returns correct language', () {
      final thread = GossipThread.fromJson({
        'id': 1,
        'title_en': 'English Title',
        'title_sw': 'Kichwa cha Kiswahili',
      });
      expect(thread.title(isSwahili: false), 'English Title');
      expect(thread.title(isSwahili: true), 'Kichwa cha Kiswahili');
    });

    test('title falls back to English when Swahili missing', () {
      final thread = GossipThread.fromJson({
        'id': 1,
        'title_en': 'English Only',
      });
      expect(thread.title(isSwahili: true), 'English Only');
    });
  });

  group('GossipThreadDetail', () {
    test('fromJson parses thread with posts', () {
      final detail = GossipThreadDetail.fromJson({
        'id': 42,
        'title_en': 'Test Thread',
        'title_sw': 'Thread ya Jaribio',
        'category': 'music',
        'velocity_score': 50.0,
        'post_count': 3,
        'participant_count': 3,
        'status': 'active',
        'posts': [
          {
            'id': 1, 'user_id': 10, 'content': 'Post 1',
            'created_at': '2026-03-26T10:00:00.000Z',
            'updated_at': '2026-03-26T10:00:00.000Z',
          },
          {
            'id': 2, 'user_id': 11, 'content': 'Post 2',
            'created_at': '2026-03-26T10:05:00.000Z',
            'updated_at': '2026-03-26T10:05:00.000Z',
          },
        ],
      });
      expect(detail.thread.id, 42);
      expect(detail.posts.length, 2);
      expect(detail.posts[0].id, 1);
    });
  });

  group('DigestResponse', () {
    test('fromJson parses threads and proverb', () {
      final digest = DigestResponse.fromJson({
        'threads': [
          {'id': 1, 'title_en': 'Thread 1', 'title_sw': 'Thread 1'},
        ],
        'proverb': {
          'text_en': 'Patience brings good things',
          'text_sw': 'Subira huvuta heri',
        },
      });
      expect(digest.threads.length, 1);
      expect(digest.proverbEn, 'Patience brings good things');
      expect(digest.proverbSw, 'Subira huvuta heri');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/gossip_models_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the models**

Create `lib/models/gossip_models.dart`:

```dart
// Gossip thread models for the Flywheel gossip-virality engine.

import '../config/api_config.dart';
import 'post_models.dart';

/// Helper to safely parse int from dynamic
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Helper to safely parse double from dynamic
double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Thread lifecycle status.
enum ThreadStatus {
  active,
  cooling,
  archived;

  static ThreadStatus fromString(String? value) {
    switch (value) {
      case 'cooling':
        return ThreadStatus.cooling;
      case 'archived':
        return ThreadStatus.archived;
      default:
        return ThreadStatus.active;
    }
  }
}

/// A gossip thread grouping related trending posts.
class GossipThread {
  final int id;
  final int seedPostId;
  final String? titleEn;
  final String? titleSw;
  final String category;
  final double velocityScore;
  final int postCount;
  final int participantCount;
  final ThreadStatus status;
  final String geographicScope;
  final DateTime? createdAt;
  final Post? seedPost;

  GossipThread({
    required this.id,
    required this.seedPostId,
    this.titleEn,
    this.titleSw,
    required this.category,
    required this.velocityScore,
    required this.postCount,
    required this.participantCount,
    required this.status,
    required this.geographicScope,
    this.createdAt,
    this.seedPost,
  });

  /// Get title in the appropriate language with fallback.
  String title({required bool isSwahili}) {
    if (isSwahili) return titleSw ?? titleEn ?? '';
    return titleEn ?? '';
  }

  factory GossipThread.fromJson(Map<String, dynamic> json) {
    return GossipThread(
      id: _parseInt(json['id']),
      seedPostId: _parseInt(json['seed_post_id']),
      titleEn: json['title_en'] as String?,
      titleSw: json['title_sw'] as String?,
      category: (json['category'] as String?) ?? 'general',
      velocityScore: _parseDouble(json['velocity_score']),
      postCount: _parseInt(json['post_count']),
      participantCount: _parseInt(json['participant_count']),
      status: ThreadStatus.fromString(json['status'] as String?),
      geographicScope: (json['geographic_scope'] as String?) ?? 'global',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      seedPost: json['seed_post'] is Map<String, dynamic>
          ? Post.fromJson(json['seed_post'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Thread detail with full post list.
class GossipThreadDetail {
  final GossipThread thread;
  final List<Post> posts;

  GossipThreadDetail({required this.thread, required this.posts});

  factory GossipThreadDetail.fromJson(Map<String, dynamic> json) {
    final rawPosts = json['posts'] is List ? json['posts'] as List : [];
    final posts = <Post>[];
    for (final item in rawPosts) {
      if (item is Map<String, dynamic>) {
        try {
          posts.add(Post.fromJson(item));
        } catch (_) {}
      }
    }
    return GossipThreadDetail(
      thread: GossipThread.fromJson(json),
      posts: posts,
    );
  }
}

/// Digest response with personalized threads and proverb.
class DigestResponse {
  final List<GossipThread> threads;
  final String? proverbEn;
  final String? proverbSw;

  DigestResponse({
    required this.threads,
    this.proverbEn,
    this.proverbSw,
  });

  String proverb({required bool isSwahili}) {
    if (isSwahili) return proverbSw ?? proverbEn ?? '';
    return proverbEn ?? '';
  }

  factory DigestResponse.fromJson(Map<String, dynamic> json) {
    final rawThreads = json['threads'] is List ? json['threads'] as List : [];
    final threads = <GossipThread>[];
    for (final item in rawThreads) {
      if (item is Map<String, dynamic>) {
        try {
          threads.add(GossipThread.fromJson(item));
        } catch (_) {}
      }
    }
    final proverb = json['proverb'] is Map<String, dynamic>
        ? json['proverb'] as Map<String, dynamic>
        : <String, dynamic>{};
    return DigestResponse(
      threads: threads,
      proverbEn: proverb['text_en'] as String?,
      proverbSw: proverb['text_sw'] as String?,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/models/gossip_models_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/gossip_models.dart test/models/gossip_models_test.dart
git commit -m "feat: add GossipThread, GossipThreadDetail, DigestResponse models"
```

---

## Task 3: Create GossipService

**Files:**
- Create: `lib/services/gossip_service.dart`
- Create: `test/services/gossip_service_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/services/gossip_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/services/gossip_service.dart';

void main() {
  group('GossipService', () {
    test('instance can be created', () {
      final service = GossipService();
      expect(service, isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/gossip_service_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write GossipService**

Create `lib/services/gossip_service.dart`:

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/gossip_models.dart';
import '../models/post_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

/// Service for gossip threads and digest.
/// Instance-based (same pattern as PostService, FeedService).
class GossipService {
  /// GET /api/gossip/threads
  /// Returns paginated list of active gossip threads.
  Future<GossipThreadListResult> getThreads({
    required String token,
    String? category,
    String status = 'active',
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, String>{
        'status': status,
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (category != null) params['category'] = category;

      final url = Uri.parse('$_baseUrl/gossip/threads').replace(queryParameters: params);
      final response = await http.get(url, headers: ApiConfig.authHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawList = data['data'] is List ? data['data'] as List : [];
        final threads = <GossipThread>[];
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            try {
              threads.add(GossipThread.fromJson(item));
            } catch (e) {
              if (kDebugMode) debugPrint('[GossipService] Parse error: $e');
            }
          }
        }
        PaginationMeta meta;
        try {
          meta = PaginationMeta.fromJson(
            (data['meta'] as Map<String, dynamic>?) ?? {},
          );
        } catch (_) {
          meta = PaginationMeta.fromJson({});
        }
        return GossipThreadListResult(threads: threads, meta: meta);
      }
      if (kDebugMode) {
        debugPrint('[GossipService] getThreads ${response.statusCode}');
      }
      return GossipThreadListResult(threads: [], meta: PaginationMeta.fromJson({}));
    } catch (e) {
      if (kDebugMode) debugPrint('[GossipService] getThreads error: $e');
      return GossipThreadListResult(threads: [], meta: PaginationMeta.fromJson({}));
    }
  }

  /// GET /api/gossip/threads/{id}
  /// Returns thread detail with posts.
  Future<GossipThreadDetail?> getThread({
    required int threadId,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/gossip/threads/$threadId');
      final response = await http.get(url, headers: ApiConfig.authHeaders(token));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final threadData = data['data'] ?? data;
        return GossipThreadDetail.fromJson(threadData as Map<String, dynamic>);
      }
      if (kDebugMode) {
        debugPrint('[GossipService] getThread ${response.statusCode}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[GossipService] getThread error: $e');
      return null;
    }
  }

  /// GET /api/gossip/digest
  /// Returns personalized digest with top threads and proverb.
  Future<DigestResponse?> getDigest({required String token}) async {
    try {
      final url = Uri.parse('$_baseUrl/gossip/digest');
      final response = await http.get(url, headers: ApiConfig.authHeaders(token));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final digestData = data['data'] ?? data;
        return DigestResponse.fromJson(digestData as Map<String, dynamic>);
      }
      if (kDebugMode) {
        debugPrint('[GossipService] getDigest ${response.statusCode}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[GossipService] getDigest error: $e');
      return null;
    }
  }
}

/// Result wrapper for thread list with pagination.
class GossipThreadListResult {
  final List<GossipThread> threads;
  final PaginationMeta meta;

  GossipThreadListResult({required this.threads, required this.meta});
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/gossip_service_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/gossip_service.dart test/services/gossip_service_test.dart
git commit -m "feat: add GossipService for threads, thread detail, and digest endpoints"
```

---

## Task 4: Add Personalized Feed to FeedService

**Files:**
- Modify: `lib/services/feed_service.dart`

- [ ] **Step 1: Read feed_service.dart to find insertion point**

Read `lib/services/feed_service.dart` to find the existing `getForYouFeed` method and the file structure.

- [ ] **Step 2: Add getPersonalizedFeed method**

After the `getForYouFeed` method, add a new method that calls the personalized endpoint with fallback:

```dart
  /// Get AI-personalized feed. Falls back to For You feed if personalized endpoint fails.
  /// GET /api/feed/personalized
  Future<PostListResult> getPersonalizedFeed({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        return getForYouFeed(userId: userId, page: page, perPage: perPage);
      }
      final url = Uri.parse('$_baseUrl/feed/personalized?page=$page&per_page=$perPage');
      final response = await http.get(url, headers: ApiConfig.authHeaders(token));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final (posts, meta) = _parseFeedData(data);
        return PostListResult(posts: posts, meta: meta);
      }
      // Fallback to For You feed
      if (kDebugMode) {
        debugPrint('[FeedService] Personalized feed ${response.statusCode}, falling back to For You');
      }
      return getForYouFeed(userId: userId, page: page, perPage: perPage);
    } catch (e) {
      if (kDebugMode) debugPrint('[FeedService] Personalized feed error: $e');
      return getForYouFeed(userId: userId, page: page, perPage: perPage);
    }
  }
```

Also add the import for LocalStorageService at the top if not present:
```dart
import 'local_storage_service.dart';
```

- [ ] **Step 3: Update feed router to use personalized feed for 'posts' type**

In the `getFeed` switch method, update the `'posts'` case to use personalized:

```dart
case 'posts':
  return getPersonalizedFeed(userId: userId, page: page, perPage: perPage);
```

- [ ] **Step 4: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/services/feed_service.dart
git commit -m "feat: add personalized feed endpoint with fallback to For You"
```

---

## Task 5: Add Bilingual Gossip Strings

**Files:**
- Modify: `lib/l10n/app_strings.dart`

- [ ] **Step 1: Read app_strings.dart to find the right section**

Read the file to find existing feed/discover strings.

- [ ] **Step 2: Add gossip thread strings**

Add these getter properties to the `AppStrings` class (near the existing discover/trending strings):

```dart
  // Gossip Threads
  String get gossipThreads => isSwahili ? 'Mazungumzo' : 'Threads';
  String get trendingThreads => isSwahili ? 'Mazungumzo Yanayovuma' : 'Trending Threads';
  String get threadPosts => isSwahili ? 'machapisho' : 'posts';
  String get threadParticipants => isSwahili ? 'washiriki' : 'participants';
  String get threadActive => isSwahili ? 'Hai' : 'Active';
  String get threadCooling => isSwahili ? 'Inapoa' : 'Cooling';
  String get threadArchived => isSwahili ? 'Imehifadhiwa' : 'Archived';
  String get viewThread => isSwahili ? 'Angalia Mazungumzo' : 'View Thread';
  String get partOfThread => isSwahili ? 'Sehemu ya mazungumzo' : 'Part of trending thread';
  String get seedPost => isSwahili ? 'Chapisho la Kwanza' : 'Original Post';
  String get relatedPosts => isSwahili ? 'Machapisho Yanayohusiana' : 'Related Posts';
  String get velocityIndicator => isSwahili ? 'Kasi' : 'Velocity';
  String get noThreads => isSwahili ? 'Hakuna mazungumzo kwa sasa' : 'No threads right now';
  String get digest => isSwahili ? 'Muhtasari' : 'Digest';
  String get morningDigest => isSwahili ? 'Kumekucha! Hizi ndio habari za leo' : 'Good morning! Here\'s what\'s trending';
  String get eveningDigest => isSwahili ? 'Usiku Mwema — hivi ndivyo ulivyokosa' : 'Good evening — here\'s what you missed';
  String get proverbOfTheDay => isSwahili ? 'Methali ya Leo' : 'Proverb of the Day';

  // Thread categories
  String get categoryAll => isSwahili ? 'Zote' : 'All';
  String get categoryEntertainment => isSwahili ? 'Burudani' : 'Entertainment';
  String get categoryBusiness => isSwahili ? 'Biashara' : 'Business';
  String get categoryMusic => isSwahili ? 'Muziki' : 'Music';
  String get categorySports => isSwahili ? 'Michezo' : 'Sports';
  String get categoryLocal => isSwahili ? 'Karibu Nawe' : 'Local';
```

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/app_strings.dart
git commit -m "feat: add bilingual gossip thread strings (Swahili + English)"
```

---

## Task 6: Create GossipThreadCard Widget

**Files:**
- Create: `lib/widgets/gossip_thread_card.dart`

- [ ] **Step 1: Read existing PostCard and design system for patterns**

Read `lib/widgets/post_card.dart` (first 30 lines for imports and design tokens) and `docs/DESIGN.md` for card styling.

- [ ] **Step 2: Create GossipThreadCard widget**

Create `lib/widgets/gossip_thread_card.dart`:

```dart
import 'package:flutter/material.dart';
import '../models/gossip_models.dart';
import '../models/post_models.dart';
import '../l10n/app_strings_scope.dart';

// Design tokens (matching PostCard and DESIGN.md)
const _kSurface = Color(0xFFFFFFFF);
const _kPrimaryText = Color(0xFF1A1A1A);
const _kSecondaryText = Color(0xFF666666);
const _kTertiaryText = Color(0xFF999999);
const _kDivider = Color(0xFFE0E0E0);
const _kCardRadius = 16.0;
const _kCardPadding = 16.0;

/// Compact gossip thread card injected into the feed every 8-12 posts.
/// Shows thread title, post count, velocity indicator, and seed post preview.
/// Tap opens ThreadViewerScreen.
class GossipThreadCard extends StatelessWidget {
  final GossipThread thread;
  final VoidCallback? onTap;

  const GossipThreadCard({
    super.key,
    required this.thread,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;
    final title = thread.title(isSwahili: isSwahili);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(_kCardRadius),
          border: Border.all(color: _kDivider),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(_kCardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row: category chip + velocity indicator
              Row(
                children: [
                  _CategoryChip(category: thread.category, strings: s),
                  const Spacer(),
                  _VelocityIndicator(score: thread.velocityScore),
                ],
              ),
              const SizedBox(height: 12),
              // Thread title
              Text(
                title.isNotEmpty ? title : (s?.trendingThreads ?? 'Trending Thread'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kPrimaryText,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Seed post preview (if available)
              if (thread.seedPost?.content != null) ...[
                Text(
                  thread.seedPost!.content!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _kSecondaryText,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              // Footer: post count + participant count + view button
              Row(
                children: [
                  Icon(Icons.article_outlined, size: 16, color: _kTertiaryText),
                  const SizedBox(width: 4),
                  Text(
                    '${thread.postCount} ${s?.threadPosts ?? 'posts'}',
                    style: const TextStyle(fontSize: 12, color: _kSecondaryText),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people_outline_rounded, size: 16, color: _kTertiaryText),
                  const SizedBox(width: 4),
                  Text(
                    '${thread.participantCount}',
                    style: const TextStyle(fontSize: 12, color: _kSecondaryText),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kPrimaryText,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s?.viewThread ?? 'View Thread',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _kSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  final dynamic strings;

  const _CategoryChip({required this.category, this.strings});

  @override
  Widget build(BuildContext context) {
    final label = _categoryLabel(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _kSecondaryText,
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'entertainment':
        return strings?.categoryEntertainment ?? 'Entertainment';
      case 'business':
        return strings?.categoryBusiness ?? 'Business';
      case 'music':
        return strings?.categoryMusic ?? 'Music';
      case 'sports':
        return strings?.categorySports ?? 'Sports';
      case 'local':
        return strings?.categoryLocal ?? 'Local';
      default:
        return category.isNotEmpty
            ? '${category[0].toUpperCase()}${category.substring(1)}'
            : 'General';
    }
  }
}

class _VelocityIndicator extends StatelessWidget {
  final double score;

  const _VelocityIndicator({required this.score});

  @override
  Widget build(BuildContext context) {
    final level = score >= 50 ? 3 : (score >= 20 ? 2 : 1);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final isActive = i < level;
        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Container(
            width: 4,
            height: 8 + (i * 4).toDouble(),
            decoration: BoxDecoration(
              color: isActive ? _kPrimaryText : _kDivider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
```

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/gossip_thread_card.dart
git commit -m "feat: add GossipThreadCard widget for feed thread injection"
```

---

## Task 7: Create ThreadBadge Widget

**Files:**
- Create: `lib/widgets/thread_badge.dart`
- Modify: `lib/widgets/post_card.dart`

- [ ] **Step 1: Create ThreadBadge widget**

Create `lib/widgets/thread_badge.dart`:

```dart
import 'package:flutter/material.dart';

/// Small badge shown on PostCard when the post belongs to a gossip thread.
class ThreadBadge extends StatelessWidget {
  final String? threadTitle;
  final VoidCallback? onTap;

  const ThreadBadge({super.key, this.threadTitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department_rounded, size: 14, color: Color(0xFF666666)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                threadTitle ?? 'Trending thread',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add ThreadBadge to PostCard**

In `lib/widgets/post_card.dart`:

1. Add import: `import 'thread_badge.dart';`

2. In the `_buildHeader` method (or just below it in the Column), add the thread badge when `widget.post.threadId != null`:

```dart
if (widget.post.threadId != null)
  ThreadBadge(
    threadTitle: widget.post.threadTitle,
    onTap: () {
      Navigator.of(context).pushNamed('/thread/${widget.post.threadId}');
    },
  ),
```

Read the file first to find the exact insertion point — it should go after the header row and before the card body content.

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/thread_badge.dart lib/widgets/post_card.dart
git commit -m "feat: add ThreadBadge widget and show on PostCard when post belongs to thread"
```

---

## Task 8: Create ThreadViewerScreen

**Files:**
- Create: `lib/screens/feed/thread_viewer_screen.dart`

- [ ] **Step 1: Read PostDetailScreen for screen pattern reference**

Read `lib/screens/feed/post_detail_screen.dart` (first 50 lines) for the screen widget pattern.

- [ ] **Step 2: Create ThreadViewerScreen**

Create `lib/screens/feed/thread_viewer_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../../models/gossip_models.dart';
import '../../models/post_models.dart';
import '../../services/gossip_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/event_tracking_service.dart';
import '../../l10n/app_strings_scope.dart';
import '../../widgets/post_card.dart';

// Design tokens
const _kBackground = Color(0xFFFAFAFA);
const _kSurface = Color(0xFFFFFFFF);
const _kPrimaryText = Color(0xFF1A1A1A);
const _kSecondaryText = Color(0xFF666666);
const _kTertiaryText = Color(0xFF999999);
const _kDivider = Color(0xFFE0E0E0);

class ThreadViewerScreen extends StatefulWidget {
  final int threadId;
  final int currentUserId;

  const ThreadViewerScreen({
    super.key,
    required this.threadId,
    required this.currentUserId,
  });

  @override
  State<ThreadViewerScreen> createState() => _ThreadViewerScreenState();
}

class _ThreadViewerScreenState extends State<ThreadViewerScreen> {
  final GossipService _gossipService = GossipService();
  GossipThreadDetail? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadThread();
    // Track thread view event
    EventTrackingService.getInstance().then((tracker) {
      tracker.trackEvent(
        eventType: 'view',
        metadata: {'thread_id': widget.threadId},
      );
    });
  }

  Future<void> _loadThread() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        setState(() { _error = 'Not authenticated'; _isLoading = false; });
        return;
      }
      final detail = await _gossipService.getThread(
        threadId: widget.threadId,
        token: token,
      );
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
          if (detail == null) _error = 'Thread not found';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _detail != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _detail!.thread.title(isSwahili: isSwahili),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _kPrimaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_detail!.thread.postCount} ${s?.threadPosts ?? 'posts'} · ${_detail!.thread.participantCount} ${s?.threadParticipants ?? 'participants'}',
                    style: const TextStyle(fontSize: 12, color: _kSecondaryText),
                  ),
                ],
              )
            : Text(
                s?.gossipThreads ?? 'Thread',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimaryText),
              ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimaryText));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: _kSecondaryText)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadThread,
              child: Text(
                'Retry',
                style: const TextStyle(color: _kPrimaryText, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
    if (_detail == null || _detail!.posts.isEmpty) {
      final s = AppStringsScope.of(context);
      return Center(
        child: Text(s?.noThreads ?? 'No posts in this thread', style: const TextStyle(color: _kSecondaryText)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadThread,
      color: _kPrimaryText,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: _detail!.posts.length,
        itemBuilder: (context, index) {
          final post = _detail!.posts[index];
          return PostCard(
            post: post,
            currentUserId: widget.currentUserId,
            onTap: () {
              Navigator.of(context).pushNamed('/post/${post.id}');
            },
            onUserTap: () {
              Navigator.of(context).pushNamed('/profile/${post.userId}');
            },
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 3: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/feed/thread_viewer_screen.dart
git commit -m "feat: add ThreadViewerScreen for viewing gossip thread posts"
```

---

## Task 9: Add Thread Route to main.dart

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Read main.dart to find route definitions**

Read `lib/main.dart` around the `onGenerateRoute` section.

- [ ] **Step 2: Add import**

At the top of `lib/main.dart`, add:
```dart
import 'screens/feed/thread_viewer_screen.dart';
```

- [ ] **Step 3: Add thread route**

In the `onGenerateRoute` switch/if chain (where other routes are defined), add:

```dart
if (pathSegments.length == 2 && pathSegments[0] == 'thread') {
  final threadId = int.tryParse(pathSegments[1]);
  if (threadId != null) {
    return MaterialPageRoute(
      builder: (_) => FutureBuilder<int>(
        future: getCurrentUserId(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return ThreadViewerScreen(
            threadId: threadId,
            currentUserId: snapshot.data!,
          );
        },
      ),
    );
  }
}
```

Follow the same FutureBuilder pattern used by other routes in the file.

- [ ] **Step 4: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart
git commit -m "feat: add /thread/:threadId route for gossip thread navigation"
```

---

## Task 10: Integrate Thread Cards into Discover Feed

**Files:**
- Modify: `lib/screens/feed/discover_feed_content.dart`

- [ ] **Step 1: Read discover_feed_content.dart fully**

Read the file to understand its structure: 3 sections (Discover, Trending, Nearby) with `CustomScrollView`.

- [ ] **Step 2: Add imports**

At the top, add:
```dart
import '../../models/gossip_models.dart';
import '../../services/gossip_service.dart';
import '../../widgets/gossip_thread_card.dart';
```

- [ ] **Step 3: Add thread state and loading**

In the State class, add:
```dart
final GossipService _gossipService = GossipService();
List<GossipThread> _threads = [];
bool _threadsLoading = true;
String? _threadsError;
String? _selectedCategory;
```

In `initState` (or wherever existing data is loaded), add thread loading:
```dart
_loadThreads();
```

Add the method:
```dart
Future<void> _loadThreads() async {
  setState(() { _threadsLoading = true; _threadsError = null; });
  try {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null) return;
    final result = await _gossipService.getThreads(
      token: token,
      category: _selectedCategory,
    );
    if (mounted) {
      setState(() {
        _threads = result.threads;
        _threadsLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() { _threadsError = e.toString(); _threadsLoading = false; });
    }
  }
}
```

- [ ] **Step 4: Replace Trending section with Gossip Threads + Filter Chips**

Find the existing Trending section in the build method. Replace it with:

1. Section header: "Mazungumzo Yanayovuma" / "Trending Threads"
2. Filter chips row: All, Entertainment, Business, Music, Sports, Local
3. Thread cards list (GossipThreadCard widgets) or loading/error/empty state

The filter chips should call `_loadThreads()` when category changes:
```dart
void _onCategorySelected(String? category) {
  setState(() { _selectedCategory = category; });
  _loadThreads();
}
```

Each GossipThreadCard's `onTap` navigates to the thread:
```dart
onTap: () => Navigator.of(context).pushNamed('/thread/${thread.id}'),
```

- [ ] **Step 5: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/feed/discover_feed_content.dart
git commit -m "feat: replace Trending section with gossip thread cards and category filter chips"
```

---

## Task 11: Final Verification

- [ ] **Step 1: Run all tests**

Run: `flutter test test/models/gossip_models_test.dart test/services/gossip_service_test.dart test/models/event_models_test.dart test/services/event_tracking_service_test.dart test/services/creator_service_test.dart`
Expected: All tests pass.

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: No new errors.

- [ ] **Step 3: Build the app**

Run: `flutter build apk --debug`
Expected: Build succeeds.

- [ ] **Step 4: Manual verification checklist**

If device is available:
- Feed loads with personalized endpoint (check debug console)
- Discover screen shows "Trending Threads" section with filter chips
- Thread cards display (if backend has created threads)
- Tapping a thread card opens ThreadViewerScreen
- Posts with threadId show the ThreadBadge
- Tapping ThreadBadge navigates to thread

- [ ] **Step 5: Final commit (if any loose changes)**

```bash
git status
```

---

## Ship Gate Checklist

Phase 2 is complete when:
- [ ] Backend has `gossip_threads`, `gossip_thread_posts`, `thread_title_templates` tables
- [ ] Backend has ~30 seeded bilingual title templates
- [ ] Backend has thread detection job (every 5 min)
- [ ] `GET /api/gossip/threads`, `GET /api/gossip/threads/{id}`, `GET /api/gossip/digest` endpoints work
- [ ] `GET /api/feed/personalized` endpoint returns posts with thread_id when applicable
- [ ] `GossipThread`, `GossipThreadDetail`, `DigestResponse` models parse correctly
- [ ] `GossipService` fetches threads, thread detail, and digest
- [ ] `GossipThreadCard` widget displays in Discover feed with category filter chips
- [ ] `ThreadViewerScreen` shows thread title, post count, and related posts
- [ ] `ThreadBadge` shows on PostCard when post belongs to a thread
- [ ] Feed uses personalized endpoint with fallback to For You
- [ ] `/thread/:threadId` route works
- [ ] Bilingual strings for all gossip UI
- [ ] All tests pass, flutter analyze clean
