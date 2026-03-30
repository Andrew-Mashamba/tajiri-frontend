# Content Engine Phase 6 — Flutter Frontend Integration

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate the Content Engine v2 API into the Flutter frontend — new models, service, universal search screen, result cards, feed migration, and enhanced event tracking.

**Architecture:** `ContentEngineService` wraps v2/feed and v2/search endpoints with automatic fallback to v1 FeedService when feature flags are off (backend returns `{"success": false, "fallback": true}`). A `ContentResultCard` router widget dispatches to type-specific cards. FeedScreen's For You and Discover tabs migrate to the v2 pipeline. EventTrackingService gains dwell-time and not-interested signals.

**Tech Stack:** Flutter/Dart, http package, existing PostCard/GossipThreadCard widgets, Hive for caching. (VisibilityDetector for dwell tracking deferred — needs package addition.)

---

## API Contract Reference

**V2 Feed:** `GET /api/v2/feed?feed_type=<type>&page=&per_page=` (auth required)
**V2 Search:** `GET /api/v2/search?q=<query>&types=&category=&region=&sort=&page=&per_page=` (auth required)

**V2 Response Shape:**
```json
{
  "success": true,
  "data": [
    {
      "document": {
        "id": 123,
        "source_type": "post",
        "source_id": 456,
        "title": "...",
        "content_tier": "high",
        "scores": { "composite": 75.2, "personalized": 82.1, "trending": 45.0 }
      },
      "source": { /* full Post/Clip/MusicTrack JSON */ },
      "context": { "reason": "recommended", "is_sponsored": false, "is_exploration": false }
    }
  ],
  "meta": {
    "current_page": 1, "per_page": 20, "total_candidates": 150,
    "served_from_cache": false, "query_time_ms": 42,
    "feed_type": "for_you",
    "query_expansion": { "original": "...", "expanded_queries": [], "type_boost": null, "intent": "..." }
  }
}
```

**Fallback:** When feature flag is off, v2 returns `{"success": false, "fallback": true}` with 404. Client falls back to v1 endpoints.

**V1 Feed:** `GET /api/feed?user_id=&page=&per_page=` → `{"success": true, "data": [post objects], "meta": {pagination}}`

**Trending Digest:** `GET /api/gossip/digest` → `{"data": {"threads": [...], "proverb": "..."}}`

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `lib/models/content_engine_models.dart` | ContentEngineResult, ContentDocumentResult, ContentScores, ContentContext, TrendingDigest, AutocompleteSuggestion models |
| Create | `lib/services/content_engine_service.dart` | V2 API calls (feed, search, digest, autocomplete, markNotInterested) with v1 fallback |
| Create | `lib/widgets/content_result_card.dart` | Router widget dispatching to type-specific cards |
| Create | `lib/widgets/trending_digest_card.dart` | "Kinachoendelea Sasa" AI digest display card |
| Create | `lib/screens/search/universal_search_screen.dart` | Three-state search: trending → autocomplete → results with type tabs |
| Modify | `lib/screens/feed/feed_screen.dart` | For You tab → ContentEngineService.feed() with fallback |
| Modify | `lib/screens/feed/discover_feed_content.dart` | Discover → ContentEngineService.feed(feedType: 'discover') with fallback |
| Modify | `lib/services/event_tracking_service.dart` | Add trackView (dwell), trackScrollPast, trackNotInterested methods |
| Modify | `lib/widgets/post_card.dart` | Add VisibilityDetector for dwell-time tracking + "Sipendezwi" menu option |
| Modify | `lib/l10n/app_strings.dart` | Add Content Engine strings (Swahili/English) |
| Modify | `lib/main.dart` | Add /universal-search route, update /search to point to new screen |

---

## Task 1: Content Engine Models

**Files:**
- Create: `lib/models/content_engine_models.dart`

- [ ] **Step 1: Create the models file**

```dart
/// Content Engine v2 API response models.
/// Wraps search/feed results from the backend Content Engine pipeline.

import 'dart:convert';
import 'post_models.dart';
import '../services/post_service.dart' show PaginationMeta;

/// Helper to safely parse int
int _ceParseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is double) return value.toInt();
  return 0;
}

/// Helper to safely parse double
double _ceParseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Helper to safely parse bool
bool _ceParseBool(dynamic value, [bool defaultValue = false]) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return defaultValue;
}

/// Unified result from the Content Engine v2 API.
/// Contains a list of [ContentDocumentResult] items plus pagination/query metadata.
class ContentEngineResult {
  final List<ContentDocumentResult> items;
  final ContentEngineMeta meta;

  ContentEngineResult({required this.items, required this.meta});

  factory ContentEngineResult.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] is List ? json['data'] as List : <dynamic>[];
    final items = <ContentDocumentResult>[];
    for (final raw in rawData) {
      try {
        if (raw is Map<String, dynamic>) {
          items.add(ContentDocumentResult.fromJson(raw));
        }
      } catch (_) {
        // Skip unparseable items
      }
    }
    final metaJson = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : <String, dynamic>{};
    return ContentEngineResult(
      items: items,
      meta: ContentEngineMeta.fromJson(metaJson),
    );
  }

  /// Wrap legacy v1 feed response (list of Post objects) as a ContentEngineResult.
  factory ContentEngineResult.fromLegacy(List<Post> posts, PaginationMeta? pMeta) {
    return ContentEngineResult(
      items: posts.map((p) => ContentDocumentResult.fromLegacyPost(p)).toList(),
      meta: ContentEngineMeta(
        currentPage: pMeta?.currentPage ?? 1,
        perPage: pMeta?.perPage ?? 20,
        totalCandidates: pMeta?.total ?? posts.length,
        servedFromCache: false,
        queryTimeMs: 0,
        feedType: 'legacy',
      ),
    );
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}

/// A single result item from the Content Engine.
/// Contains the indexed document metadata, the hydrated source object, and serving context.
class ContentDocumentResult {
  final int documentId;
  final String sourceType;
  final int sourceId;
  final String? title;
  final String contentTier;
  final ContentScores scores;
  final ContentContext context;

  /// The hydrated source — could be a Post, or raw JSON for other types.
  final Post? post;
  final Map<String, dynamic>? sourceJson;

  ContentDocumentResult({
    required this.documentId,
    required this.sourceType,
    required this.sourceId,
    this.title,
    this.contentTier = 'medium',
    required this.scores,
    required this.context,
    this.post,
    this.sourceJson,
  });

  factory ContentDocumentResult.fromJson(Map<String, dynamic> json) {
    final docJson = json['document'] is Map<String, dynamic>
        ? json['document'] as Map<String, dynamic>
        : <String, dynamic>{};
    final sourceJson = json['source'] is Map<String, dynamic>
        ? json['source'] as Map<String, dynamic>
        : <String, dynamic>{};
    final contextJson = json['context'] is Map<String, dynamic>
        ? json['context'] as Map<String, dynamic>
        : <String, dynamic>{};
    final scoresJson = docJson['scores'] is Map<String, dynamic>
        ? docJson['scores'] as Map<String, dynamic>
        : <String, dynamic>{};

    final sourceType = (docJson['source_type'] ?? 'post').toString();

    // Hydrate Post if source_type is 'post' or 'clip'
    Post? post;
    if ((sourceType == 'post' || sourceType == 'clip') && sourceJson.isNotEmpty) {
      try {
        post = Post.fromJson(sourceJson);
      } catch (_) {}
    }

    return ContentDocumentResult(
      documentId: _ceParseInt(docJson['id']),
      sourceType: sourceType,
      sourceId: _ceParseInt(docJson['source_id']),
      title: docJson['title']?.toString(),
      contentTier: (docJson['content_tier'] ?? 'medium').toString(),
      scores: ContentScores.fromJson(scoresJson),
      context: ContentContext.fromJson(contextJson),
      post: post,
      sourceJson: sourceJson,
    );
  }

  /// Wrap a legacy Post as a ContentDocumentResult.
  factory ContentDocumentResult.fromLegacyPost(Post post) {
    return ContentDocumentResult(
      documentId: 0,
      sourceType: post.isShortVideo ? 'clip' : 'post',
      sourceId: post.id,
      title: post.content,
      scores: ContentScores(
        composite: post.engagementScore,
        personalized: 0,
        trending: post.trendingScore,
      ),
      context: ContentContext(
        reason: 'legacy',
        isSponsored: post.isSponsored,
        isExploration: false,
      ),
      post: post,
      sourceJson: null,
    );
  }

  bool get isPost => sourceType == 'post';
  bool get isClip => sourceType == 'clip';
  bool get isMusic => sourceType == 'music';
  bool get isGossipThread => sourceType == 'gossip_thread';
  bool get isUserProfile => sourceType == 'user_profile';
  bool get isEvent => sourceType == 'event';
  bool get isCampaign => sourceType == 'campaign';
  bool get isGroup => sourceType == 'group';
  bool get isProduct => sourceType == 'product';
  bool get isStream => sourceType == 'stream';
  bool get isPage => sourceType == 'page';
}

/// Ranking scores from the Content Engine.
class ContentScores {
  final double composite;
  final double personalized;
  final double trending;

  ContentScores({
    this.composite = 0,
    this.personalized = 0,
    this.trending = 0,
  });

  factory ContentScores.fromJson(Map<String, dynamic> json) {
    return ContentScores(
      composite: _ceParseDouble(json['composite']),
      personalized: _ceParseDouble(json['personalized']),
      trending: _ceParseDouble(json['trending']),
    );
  }
}

/// Serving context — why this result was shown.
class ContentContext {
  final String reason;
  final bool isSponsored;
  final bool isExploration;

  ContentContext({
    this.reason = 'recommended',
    this.isSponsored = false,
    this.isExploration = false,
  });

  factory ContentContext.fromJson(Map<String, dynamic> json) {
    return ContentContext(
      reason: (json['reason'] ?? 'recommended').toString(),
      isSponsored: _ceParseBool(json['is_sponsored']),
      isExploration: _ceParseBool(json['is_exploration']),
    );
  }

  /// Human-readable reason label (Swahili).
  String get reasonLabel {
    switch (reason) {
      case 'trending': return 'Inavuma';
      case 'social': return 'Marafiki wako wanapenda';
      case 'personalized': return 'Kwa ajili yako';
      case 'exploration': return 'Gundua kitu kipya';
      case 'sponsored': return 'Imedhaminiwa';
      case 'similar': return 'Kama unavyopenda';
      default: return '';
    }
  }
}

/// Pagination and query metadata from v2 response.
class ContentEngineMeta {
  final int currentPage;
  final int perPage;
  final int totalCandidates;
  final bool servedFromCache;
  final int queryTimeMs;
  final String? feedType;
  final QueryExpansion? queryExpansion;

  ContentEngineMeta({
    this.currentPage = 1,
    this.perPage = 20,
    this.totalCandidates = 0,
    this.servedFromCache = false,
    this.queryTimeMs = 0,
    this.feedType,
    this.queryExpansion,
  });

  factory ContentEngineMeta.fromJson(Map<String, dynamic> json) {
    final qeJson = json['query_expansion'] is Map<String, dynamic>
        ? json['query_expansion'] as Map<String, dynamic>
        : null;
    return ContentEngineMeta(
      currentPage: _ceParseInt(json['current_page']),
      perPage: _ceParseInt(json['per_page']),
      totalCandidates: _ceParseInt(json['total_candidates']),
      servedFromCache: _ceParseBool(json['served_from_cache']),
      queryTimeMs: _ceParseInt(json['query_time_ms']),
      feedType: json['feed_type']?.toString(),
      queryExpansion: qeJson != null ? QueryExpansion.fromJson(qeJson) : null,
    );
  }

  bool get hasMore => totalCandidates > currentPage * perPage;
}

/// Query expansion metadata from AI-powered search.
class QueryExpansion {
  final String original;
  final List<String> expandedQueries;
  final String? typeBoost;
  final String? intent;

  QueryExpansion({
    required this.original,
    this.expandedQueries = const [],
    this.typeBoost,
    this.intent,
  });

  factory QueryExpansion.fromJson(Map<String, dynamic> json) {
    final queries = json['expanded_queries'];
    return QueryExpansion(
      original: (json['original'] ?? '').toString(),
      expandedQueries: queries is List
          ? queries.map((e) => e.toString()).toList()
          : <String>[],
      typeBoost: json['type_boost']?.toString(),
      intent: json['intent']?.toString(),
    );
  }
}

/// AI-generated trending digest ("Kinachoendelea Sasa").
class TrendingDigest {
  final int id;
  final String headlineSw;
  final String headlineEn;
  final List<DigestStory> stories;
  final String mood;
  final DateTime? generatedAt;
  final DateTime? validUntil;

  TrendingDigest({
    this.id = 0,
    required this.headlineSw,
    this.headlineEn = '',
    this.stories = const [],
    this.mood = 'informative',
    this.generatedAt,
    this.validUntil,
  });

  factory TrendingDigest.fromJson(Map<String, dynamic> json) {
    final storiesRaw = json['stories'];
    List<DigestStory> stories = [];
    if (storiesRaw is List) {
      stories = storiesRaw
          .whereType<Map<String, dynamic>>()
          .map((s) => DigestStory.fromJson(s))
          .toList();
    } else if (storiesRaw is String) {
      try {
        final decoded = List<Map<String, dynamic>>.from(
          (storiesRaw.isNotEmpty ? _ceJsonDecode(storiesRaw) : []) as List,
        );
        stories = decoded.map((s) => DigestStory.fromJson(s)).toList();
      } catch (_) {}
    }

    return TrendingDigest(
      id: _ceParseInt(json['id']),
      headlineSw: (json['headline_sw'] ?? 'Kinachoendelea Sasa').toString(),
      headlineEn: (json['headline_en'] ?? "What's Happening Now").toString(),
      stories: stories,
      mood: (json['mood'] ?? 'informative').toString(),
      generatedAt: json['generated_at'] != null
          ? DateTime.tryParse(json['generated_at'].toString())
          : null,
      validUntil: json['valid_until'] != null
          ? DateTime.tryParse(json['valid_until'].toString())
          : null,
    );
  }

  bool get isValid => validUntil == null || validUntil!.isAfter(DateTime.now());
}

/// Single story within a trending digest.
class DigestStory {
  final String title;
  final String summary;
  final String? category;
  final int? documentId;

  DigestStory({
    required this.title,
    required this.summary,
    this.category,
    this.documentId,
  });

  factory DigestStory.fromJson(Map<String, dynamic> json) {
    return DigestStory(
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      category: json['category']?.toString(),
      documentId: json['document_id'] != null ? _ceParseInt(json['document_id']) : null,
    );
  }
}

/// Autocomplete suggestion for search-as-you-type.
class AutocompleteSuggestion {
  final String text;
  final String type; // 'query', 'hashtag', 'user'
  final int? targetId;
  final String? avatarUrl;

  AutocompleteSuggestion({
    required this.text,
    this.type = 'query',
    this.targetId,
    this.avatarUrl,
  });

  factory AutocompleteSuggestion.fromJson(Map<String, dynamic> json) {
    return AutocompleteSuggestion(
      text: (json['text'] ?? '').toString(),
      type: (json['type'] ?? 'query').toString(),
      targetId: json['target_id'] != null ? _ceParseInt(json['target_id']) : null,
      avatarUrl: json['avatar_url']?.toString(),
    );
  }
}

dynamic _ceJsonDecode(String s) {
  try {
    return jsonDecode(s);
  } catch (_) {
    return [];
  }
}
```

- [ ] **Step 2: Verify no compile errors**

```bash
flutter analyze lib/models/content_engine_models.dart
```

Expected: No errors (info-level warnings acceptable).

- [ ] **Step 3: Commit**

```bash
git add lib/models/content_engine_models.dart
git commit -m "feat(content-engine): add Flutter models — ContentEngineResult, ContentDocumentResult, ContentScores, ContentContext, TrendingDigest"
```

---

## Task 2: ContentEngineService — v2 API with v1 fallback

**Files:**
- Create: `lib/services/content_engine_service.dart`

**Dependencies:** Task 1 (models)

- [ ] **Step 1: Create the service**

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/content_engine_models.dart';
import '../models/post_models.dart';
import 'feed_service.dart';
import 'local_storage_service.dart';

String get _baseUrl => ApiConfig.baseUrl;

/// Service wrapping the Content Engine v2 API.
/// Falls back to v1 FeedService when the v2 feature flag is off.
class ContentEngineService {
  static final FeedService _legacyFeedService = FeedService();

  /// Fetch a personalized feed via the Content Engine v2 pipeline.
  /// Falls back to v1 FeedService if v2 returns fallback:true.
  static Future<ContentEngineResult> feed({
    required String feedType,
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    final token = await _getToken();
    if (token == null) return _emptyResult();

    try {
      final uri = Uri.parse('$_baseUrl/v2/feed').replace(queryParameters: {
        'feed_type': feedType,
        'page': page.toString(),
        'per_page': perPage.toString(),
      });

      final response = await http.get(uri, headers: ApiConfig.authHeaders(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return ContentEngineResult.fromJson(data);
        }
      }

      // Feature flag off or error → fallback to v1
      if (response.statusCode == 404) {
        return _fallbackFeed(feedType: feedType, userId: userId, page: page, perPage: perPage);
      }

      return _fallbackFeed(feedType: feedType, userId: userId, page: page, perPage: perPage);
    } catch (e) {
      debugPrint('[ContentEngineService] feed error: $e — falling back to v1');
      return _fallbackFeed(feedType: feedType, userId: userId, page: page, perPage: perPage);
    }
  }

  /// Search content via the Content Engine v2 pipeline.
  static Future<ContentEngineResult> search({
    required String query,
    required int userId,
    List<String>? types,
    String? category,
    String? region,
    String sort = 'relevance',
    int page = 1,
    int perPage = 20,
  }) async {
    final token = await _getToken();
    if (token == null) return _emptyResult();

    try {
      final params = <String, String>{
        'q': query,
        'sort': sort,
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (types != null && types.isNotEmpty) params['types'] = types.join(',');
      if (category != null) params['category'] = category;
      if (region != null) params['region'] = region;

      final uri = Uri.parse('$_baseUrl/v2/search').replace(queryParameters: params);
      final response = await http.get(uri, headers: ApiConfig.authHeaders(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return ContentEngineResult.fromJson(data);
        }
      }

      return _emptyResult();
    } catch (e) {
      debugPrint('[ContentEngineService] search error: $e');
      return _emptyResult();
    }
  }

  /// Fetch the latest AI-generated trending digest.
  /// Tries v2 endpoint first, falls back to gossip/digest.
  static Future<TrendingDigest?> getTrendingDigest() async {
    final token = await _getToken();
    try {
      // Try v2 first (Content Engine AI digest)
      final uri = Uri.parse('$_baseUrl/v2/trending-digest');
      final headers = token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers;
      final response = await http.get(uri, headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final digestJson = data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data;
        return TrendingDigest.fromJson(digestJson);
      }
      return null;
    } catch (e) {
      debugPrint('[ContentEngineService] getTrendingDigest error: $e');
      return null;
    }
  }

  /// Fetch "more like this" similar content for a document.
  static Future<ContentEngineResult> similar({
    required int documentId,
    required int userId,
    int limit = 10,
  }) async {
    final token = await _getToken();
    if (token == null) return _emptyResult();

    try {
      final uri = Uri.parse('$_baseUrl/v2/similar').replace(queryParameters: {
        'document_id': documentId.toString(),
        'limit': limit.toString(),
      });
      final response = await http.get(uri, headers: ApiConfig.authHeaders(token))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return ContentEngineResult.fromJson(data);
        }
      }
      return _emptyResult();
    } catch (e) {
      debugPrint('[ContentEngineService] similar error: $e');
      return _emptyResult();
    }
  }

  /// Mark content as "not interested" — sends negative signal to Content Engine.
  static Future<void> markNotInterested({
    required int documentId,
    required int userId,
  }) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final uri = Uri.parse('$_baseUrl/v2/not-interested');
      await http.post(
        uri,
        headers: ApiConfig.authHeaders(token),
        body: json.encode({'document_id': documentId}),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[ContentEngineService] markNotInterested error: $e');
    }
  }

  // --- Private helpers ---

  static Future<ContentEngineResult> _fallbackFeed({
    required String feedType,
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final result = await _legacyFeedService.getFeed(
        userId: userId,
        page: page,
        perPage: perPage,
        feedType: feedType,
      );
      return ContentEngineResult.fromLegacy(result.posts, result.meta);
    } catch (e) {
      debugPrint('[ContentEngineService] v1 fallback also failed: $e');
      return _emptyResult();
    }
  }

  static ContentEngineResult _emptyResult() {
    return ContentEngineResult(items: [], meta: ContentEngineMeta());
  }

  static Future<String?> _getToken() async {
    try {
      final storage = await LocalStorageService.getInstance();
      return storage.getAuthToken();
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 2: Verify no compile errors**

```bash
flutter analyze lib/services/content_engine_service.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/services/content_engine_service.dart
git commit -m "feat(content-engine): add ContentEngineService — v2 feed/search with automatic v1 fallback"
```

---

## Task 3: App Strings — Content Engine Swahili/English additions

**Files:**
- Modify: `lib/l10n/app_strings.dart`

- [ ] **Step 1: Read the file and find the last section**

Read `lib/l10n/app_strings.dart` in full. Find the last getter before the closing `}`.

- [ ] **Step 2: Add Content Engine strings**

Append before the closing `}` of the `AppStrings` class:

```dart
  // ——— Content Engine ———
  String get whatsHappeningNow => isSwahili ? 'Kinachoendelea Sasa' : "What's Happening Now";
  String get searchEverything => isSwahili ? 'Tafuta kila kitu...' : 'Search everything...';
  String get allTypes => isSwahili ? 'Zote' : 'All';
  String get posts => isSwahili ? 'Machapisho' : 'Posts';
  String get clips => isSwahili ? 'Klipu' : 'Clips';
  String get musicType => isSwahili ? 'Muziki' : 'Music';
  String get people => isSwahili ? 'Watu' : 'People';
  String get eventsType => isSwahili ? 'Matukio' : 'Events';
  String get groupsType => isSwahili ? 'Makundi' : 'Groups';
  String get productsType => isSwahili ? 'Bidhaa' : 'Products';
  String get campaignsType => isSwahili ? 'Michango' : 'Campaigns';
  String get notInterestedInThis => isSwahili ? 'Sipendezwi na hii' : 'Not interested in this';
  String get showingYouThis => isSwahili ? 'Tunakuonyesha hii kwa sababu' : 'Showing you this because';
  String get trendingContent => isSwahili ? 'Inavuma' : 'Trending';
  String get forYouContent => isSwahili ? 'Kwa ajili yako' : 'For you';
  String get friendsLikeThis => isSwahili ? 'Marafiki wako wanapenda' : 'Your friends like this';
  String get discoverSomethingNew => isSwahili ? 'Gundua kitu kipya' : 'Discover something new';
  String get sponsored => isSwahili ? 'Imedhaminiwa' : 'Sponsored';
  String get moreLikeThis => isSwahili ? 'Zaidi kama hii' : 'More like this';
  String get trendingSearches => isSwahili ? 'Tafuta zinazovuma' : 'Trending searches';
  String get recentSearches => isSwahili ? 'Ulizotafuta hivi karibuni' : 'Recent searches';
  String get nGoingCount => isSwahili ? 'wanaenda' : 'going';
  String get membersCount => isSwahili ? 'wanachama' : 'members';
  String get followersCount => isSwahili ? 'wafuasi' : 'followers';
  String get joinGroup => isSwahili ? 'Jiunge' : 'Join';
  String get followPage => isSwahili ? 'Fuata' : 'Follow';
  String get live => isSwahili ? 'MOJA KWA MOJA' : 'LIVE';
  String get archive => isSwahili ? 'Kumbukumbu' : 'Archive';
  String get daysRemaining => isSwahili ? 'siku zimebaki' : 'days remaining';
  String get funded => isSwahili ? 'imekusanywa' : 'funded';
  String get viewerCount => isSwahili ? 'watazamaji' : 'viewers';
```

- [ ] **Step 3: Verify no compile errors**

```bash
flutter analyze lib/l10n/app_strings.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/app_strings.dart
git commit -m "feat(content-engine): add Swahili/English strings for search, result cards, and content context labels"
```

---

## Task 4: ContentResultCard + TrendingDigestCard widgets

**Files:**
- Create: `lib/widgets/content_result_card.dart`
- Create: `lib/widgets/trending_digest_card.dart`

**Dependencies:** Task 1 (models), Task 3 (strings)

- [ ] **Step 1: Create ContentResultCard**

This is a router widget that delegates to the correct card based on `sourceType`. For types we already have widgets for (post, gossip_thread), it delegates directly. For new types, it renders a compact generic card showing title + type icon + key metric.

```dart
import 'package:flutter/material.dart';
import '../models/content_engine_models.dart';
import '../models/post_models.dart';
import '../l10n/app_strings.dart';
import 'post_card.dart';
import 'gossip_thread_card.dart';

/// Router widget that renders the correct card per content sourceType.
/// For post/clip → PostCard. For gossip_thread → GossipThreadCard.
/// For other types → compact preview card.
class ContentResultCard extends StatelessWidget {
  final ContentDocumentResult result;
  final int currentUserId;
  final Function(Post)? onPostTap;
  final Function(String)? onHashtagTap;
  final Function(String)? onMentionTap;
  final Function(int)? onUserTap;
  final VoidCallback? onTap;

  const ContentResultCard({
    super.key,
    required this.result,
    required this.currentUserId,
    this.onPostTap,
    this.onHashtagTap,
    this.onMentionTap,
    this.onUserTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Show context reason label if non-empty
    final reason = result.context.reasonLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reason.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Row(
              children: [
                Icon(
                  _reasonIcon(result.context.reason),
                  size: 14,
                  color: Colors.black54,
                ),
                const SizedBox(width: 4),
                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        _buildCard(context),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    // Post or Clip → delegate to PostCard
    if ((result.isPost || result.isClip) && result.post != null) {
      return PostCard(
        post: result.post!,
        currentUserId: currentUserId,
        onTap: onPostTap != null ? () => onPostTap!(result.post!) : null,
        onHashtagTap: onHashtagTap,
        onMentionTap: onMentionTap,
        onUserTap: onUserTap != null ? () => onUserTap!(result.post!.userId) : null,
      );
    }

    // Gossip Thread → delegate to GossipThreadCard
    if (result.isGossipThread && result.sourceJson != null) {
      return _buildGenericCard(
        context,
        icon: Icons.forum_rounded,
        typeLabel: 'Mada',
      );
    }

    // Music
    if (result.isMusic) {
      return _buildMusicCard(context);
    }

    // Event
    if (result.isEvent) {
      return _buildEventCard(context);
    }

    // Campaign (Michango)
    if (result.isCampaign) {
      return _buildCampaignCard(context);
    }

    // Group
    if (result.isGroup) {
      return _buildGroupCard(context);
    }

    // Product
    if (result.isProduct) {
      return _buildProductCard(context);
    }

    // User Profile
    if (result.isUserProfile) {
      return _buildUserCard(context);
    }

    // Stream
    if (result.isStream) {
      return _buildGenericCard(context, icon: Icons.live_tv_rounded, typeLabel: 'Live');
    }

    // Page
    if (result.isPage) {
      return _buildGenericCard(context, icon: Icons.flag_rounded, typeLabel: 'Ukurasa');
    }

    // Fallback
    return _buildGenericCard(context, icon: Icons.article_rounded, typeLabel: result.sourceType);
  }

  Widget _buildMusicCard(BuildContext context) {
    final src = result.sourceJson ?? {};
    final title = src['title']?.toString() ?? result.title ?? '';
    final artist = src['artist_name']?.toString() ?? src['artist']?.toString() ?? '';
    final albumArt = src['cover_url']?.toString() ?? src['album_art']?.toString();
    final duration = src['duration']?.toString() ?? '';

    return _tappableCard(
      context,
      child: Row(
        children: [
          // Album art
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 56,
              height: 56,
              color: Colors.grey[200],
              child: albumArt != null
                  ? Image.network(albumArt, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.music_note_rounded, color: Colors.black38))
                  : const Icon(Icons.music_note_rounded, color: Colors.black38),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (artist.isNotEmpty) Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                if (duration.isNotEmpty) Text(duration, style: const TextStyle(color: Colors.black38, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_filled_rounded, size: 36, color: Color(0xFF1A1A1A)),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final src = result.sourceJson ?? {};
    final name = src['name']?.toString() ?? src['title']?.toString() ?? result.title ?? '';
    final date = src['event_date']?.toString() ?? src['start_date']?.toString() ?? '';
    final location = src['location']?.toString() ?? '';
    final rsvpCount = src['rsvp_count'] ?? src['attendees_count'] ?? 0;

    return _tappableCard(
      context,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.event_rounded, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (date.isNotEmpty) Text(date, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                if (location.isNotEmpty) Text(location, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black38, fontSize: 12)),
                if (rsvpCount > 0) Text('$rsvpCount ${strings.nGoingCount}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final src = result.sourceJson ?? {};
    final title = src['title']?.toString() ?? result.title ?? '';
    final raised = src['amount_raised'] ?? src['raised'] ?? 0;
    final goal = src['goal_amount'] ?? src['goal'] ?? 1;
    final pct = goal > 0 ? ((raised / goal) * 100).clamp(0, 100).toInt() : 0;
    final daysLeft = src['days_remaining'] ?? src['days_left'] ?? 0;

    return _tappableCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: Colors.grey[200],
              color: const Color(0xFF1A1A1A),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$pct% ${strings.funded}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              if (daysLeft > 0) Text('$daysLeft ${strings.daysRemaining}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final src = result.sourceJson ?? {};
    final name = src['name']?.toString() ?? result.title ?? '';
    final memberCount = src['member_count'] ?? src['members_count'] ?? 0;
    final privacy = src['privacy']?.toString() ?? 'public';

    return _tappableCard(
      context,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.group_rounded, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('$memberCount ${strings.membersCount} · ${privacy[0].toUpperCase()}${privacy.substring(1)}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A1A1A),
              side: const BorderSide(color: Color(0xFF1A1A1A)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 36),
            ),
            child: Text(strings.joinGroup),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context) {
    final src = result.sourceJson ?? {};
    final name = src['name']?.toString() ?? src['title']?.toString() ?? result.title ?? '';
    final price = src['price'] ?? src['amount'] ?? 0;
    final seller = src['seller_name']?.toString() ?? src['shop_name']?.toString() ?? '';
    final imageUrl = src['image_url']?.toString() ?? src['thumbnail']?.toString();

    return _tappableCard(
      context,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 80,
              color: Colors.grey[200],
              child: imageUrl != null
                  ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_rounded, color: Colors.black38))
                  : const Icon(Icons.shopping_bag_rounded, color: Colors.black38),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text('TZS ${_formatNumber(price)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                if (seller.isNotEmpty) Text(seller, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final src = result.sourceJson ?? {};
    final name = src['name']?.toString() ?? src['display_name']?.toString() ?? result.title ?? '';
    final username = src['username']?.toString() ?? '';
    final avatarUrl = src['avatar_url']?.toString() ?? src['profile_photo']?.toString();
    final followers = src['followers_count'] ?? 0;

    return _tappableCard(
      context,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? const Icon(Icons.person_rounded, color: Colors.black54) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (username.isNotEmpty) Text('@$username', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                Text('$followers ${strings.followersCount}', style: const TextStyle(color: Colors.black38, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericCard(BuildContext context, {required IconData icon, required String typeLabel}) {
    return _tappableCard(
      context,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(typeLabel, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tappableCard(BuildContext context, {required Widget child}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: child,
      ),
    );
  }

  IconData _reasonIcon(String reason) {
    switch (reason) {
      case 'trending': return Icons.trending_up_rounded;
      case 'social': return Icons.people_rounded;
      case 'personalized': return Icons.auto_awesome_rounded;
      case 'exploration': return Icons.explore_rounded;
      case 'sponsored': return Icons.campaign_rounded;
      case 'similar': return Icons.recommend_rounded;
      default: return Icons.info_outline_rounded;
    }
  }

  static String _formatNumber(dynamic n) {
    final value = n is int ? n : (n is double ? n.toInt() : int.tryParse(n.toString()) ?? 0);
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)},${(value % 1000).toString().padLeft(3, '0')}';
    return value.toString();
  }
}
```

- [ ] **Step 2: Create TrendingDigestCard**

```dart
import 'package:flutter/material.dart';
import '../models/content_engine_models.dart';
import '../l10n/app_strings.dart';

/// Displays the AI-generated "Kinachoendelea Sasa" trending digest.
/// Shows headline + expandable story list.
class TrendingDigestCard extends StatefulWidget {
  final TrendingDigest digest;
  final Function(int documentId)? onStoryTap;

  const TrendingDigestCard({
    super.key,
    required this.digest,
    this.onStoryTap,
  });

  @override
  State<TrendingDigestCard> createState() => _TrendingDigestCardState();
}

class _TrendingDigestCardState extends State<TrendingDigestCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final digest = widget.digest;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.whatsHappeningNow,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.isSwahili ? digest.headlineSw : digest.headlineEn,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: Colors.black54,
                  ),
                ],
              ),

              // Expanded stories
              if (_expanded && digest.stories.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ...digest.stories.map((story) => _buildStoryRow(story)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryRow(DigestStory story) {
    return InkWell(
      onTap: story.documentId != null && widget.onStoryTap != null
          ? () => widget.onStoryTap!(story.documentId!)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 6, right: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    story.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Verify no compile errors**

```bash
flutter analyze lib/widgets/content_result_card.dart lib/widgets/trending_digest_card.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/content_result_card.dart lib/widgets/trending_digest_card.dart
git commit -m "feat(content-engine): add ContentResultCard router + TrendingDigestCard widgets"
```

---

## Task 5: UniversalSearchScreen — three-state search UI

**Files:**
- Create: `lib/screens/search/universal_search_screen.dart`

**Dependencies:** Tasks 1-4

- [ ] **Step 1: Create the search screen**

Three states: (1) Before typing → trending digest + trending hashtags, (2) While typing → autocomplete/suggestions, (3) After search → type-filtered results.

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../models/content_engine_models.dart';
import '../../services/content_engine_service.dart';
import '../../widgets/content_result_card.dart';
import '../../widgets/trending_digest_card.dart';

class UniversalSearchScreen extends StatefulWidget {
  final int currentUserId;

  const UniversalSearchScreen({super.key, required this.currentUserId});

  @override
  State<UniversalSearchScreen> createState() => _UniversalSearchScreenState();
}

class _UniversalSearchScreenState extends State<UniversalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  int get _currentUserId => widget.currentUserId;
  bool _isLoading = false;
  String? _activeQuery;

  // Pre-search state
  TrendingDigest? _digest;
  bool _digestLoading = true;

  // Search results
  ContentEngineResult? _searchResult;
  String _selectedType = 'all';
  int _currentPage = 1;
  bool _loadingMore = false;
  final ScrollController _scrollController = ScrollController();

  Timer? _debounce;

  static const _typeFilters = ['all', 'post', 'clip', 'music', 'user_profile', 'event', 'group', 'campaign', 'product'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _loadDigest();
  }

  Future<void> _loadDigest() async {
    final digest = await ContentEngineService.getTrendingDigest();
    if (mounted) {
      setState(() {
        _digest = digest;
        _digestLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _activeQuery = null;
        _searchResult = null;
        _currentPage = 1;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query, reset: true);
    });
  }

  Future<void> _performSearch(String query, {bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _activeQuery = query;
      });
    }

    final types = _selectedType == 'all' ? null : [_selectedType];
    final result = await ContentEngineService.search(
      query: query,
      userId: _currentUserId,
      types: types,
      page: _currentPage,
    );

    if (mounted) {
      setState(() {
        if (reset || _searchResult == null) {
          _searchResult = result;
        } else {
          // Append for pagination
          _searchResult = ContentEngineResult(
            items: [..._searchResult!.items, ...result.items],
            meta: result.meta,
          );
        }
        _isLoading = false;
        _loadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 300) {
      if (!_loadingMore && _activeQuery != null && (_searchResult?.meta.hasMore ?? false)) {
        setState(() {
          _loadingMore = true;
          _currentPage++;
        });
        _performSearch(_activeQuery!);
      }
    }
  }

  void _onTypeFilterChanged(String type) {
    if (type == _selectedType) return;
    setState(() => _selectedType = type);
    if (_activeQuery != null) {
      _performSearch(_activeQuery!, reset: true);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            autofocus: true,
            decoration: InputDecoration(
              hintText: strings.searchEverything,
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 15),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.black38),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.black38),
                      onPressed: () {
                        _searchController.clear();
                        _searchFocus.requestFocus();
                      },
                    )
                  : null,
            ),
            onSubmitted: (q) {
              if (q.trim().isNotEmpty) _performSearch(q.trim(), reset: true);
            },
          ),
        ),
      ),
      body: SafeArea(
        child: _activeQuery == null ? _buildPreSearchState(strings) : _buildSearchResults(strings),
      ),
    );
  }

  /// State 1: Before typing — show trending digest + suggestions
  Widget _buildPreSearchState(AppStrings strings) {
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        // Trending digest card
        if (_digestLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A))),
          )
        else if (_digest != null)
          TrendingDigestCard(
            digest: _digest!,
            onStoryTap: (docId) {
              // Navigate to post/document detail
              Navigator.pushNamed(context, '/post/$docId');
            },
          ),

        // Trending searches section (placeholder — populated by backend)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            strings.trendingSearches,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1A1A)),
          ),
        ),
        // We'll show trending hashtags as tap targets
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            strings.noData,
            style: const TextStyle(color: Colors.black38, fontSize: 13),
          ),
        ),
      ],
    );
  }

  /// State 3: After search — type filter tabs + results list
  Widget _buildSearchResults(AppStrings strings) {
    return Column(
      children: [
        // Type filter chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: _typeFilters.length,
            itemBuilder: (context, index) {
              final type = _typeFilters[index];
              final isSelected = type == _selectedType;
              return ChoiceChip(
                label: Text(_typeLabel(type, strings)),
                selected: isSelected,
                onSelected: (_) => _onTypeFilterChanged(type),
                selectedColor: const Color(0xFF1A1A1A),
                backgroundColor: Colors.grey[100],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide.none,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              );
            },
          ),
        ),

        // Query expansion info
        if (_searchResult?.meta.queryExpansion != null &&
            (_searchResult!.meta.queryExpansion!.expandedQueries.isNotEmpty))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Pia tumetafuta: ${_searchResult!.meta.queryExpansion!.expandedQueries.take(3).join(", ")}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.black38),
            ),
          ),

        // Results list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A)))
              : _searchResult == null || _searchResult!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 48, color: Colors.black26),
                          const SizedBox(height: 12),
                          Text(strings.noResults, style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 32),
                      itemCount: _searchResult!.items.length + (_loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _searchResult!.items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A))),
                          );
                        }
                        final item = _searchResult!.items[index];
                        return ContentResultCard(
                          result: item,
                          currentUserId: _currentUserId,
                          onPostTap: (post) => Navigator.pushNamed(context, '/post/${post.id}'),
                          onHashtagTap: (tag) {
                            _searchController.text = '#$tag';
                            _performSearch('#$tag', reset: true);
                          },
                          onUserTap: (userId) => Navigator.pushNamed(context, '/profile/$userId'),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  String _typeLabel(String type, AppStrings strings) {
    switch (type) {
      case 'all': return strings.allTypes;
      case 'post': return strings.posts;
      case 'clip': return strings.clips;
      case 'music': return strings.musicType;
      case 'user_profile': return strings.people;
      case 'event': return strings.eventsType;
      case 'group': return strings.groupsType;
      case 'campaign': return strings.campaignsType;
      case 'product': return strings.productsType;
      default: return type;
    }
  }
}
```

- [ ] **Step 2: Verify no compile errors**

```bash
flutter analyze lib/screens/search/universal_search_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/search/universal_search_screen.dart
git commit -m "feat(content-engine): add UniversalSearchScreen — three-state search with type filters, query expansion, and trending digest"
```

---

## Task 6: Enhanced Event Tracking — dwell time, scroll past, not interested

**Files:**
- Modify: `lib/services/event_tracking_service.dart`

**Dependencies:** None (independent)

- [ ] **Step 1: Read the full EventTrackingService file**

Read `lib/services/event_tracking_service.dart` in full. Understand the `trackEvent()` method signature and the existing event types.

- [ ] **Step 2: Add three new convenience methods**

Add these methods to the `EventTrackingService` class, near the existing `trackEvent()` method:

```dart
  /// Track a content view with dwell time measurement.
  /// Called when a post leaves the viewport after being visible.
  void trackView({required int postId, required int creatorId, required int dwellMs}) {
    final eventType = dwellMs < 500 ? 'view_glance' : (dwellMs < 3000 ? 'view_partial' : 'view_deep');
    trackEvent(eventType: eventType, postId: postId, creatorId: creatorId, durationMs: dwellMs);
  }

  /// Track when a user scrolls past content quickly (< 500ms visible).
  void trackScrollPast({required int postId, required int creatorId}) {
    trackEvent(eventType: 'scroll_past', postId: postId, creatorId: creatorId);
  }

  /// Track explicit "not interested" signal.
  void trackNotInterested({required int postId, required int creatorId}) {
    trackEvent(eventType: 'not_interested', postId: postId, creatorId: creatorId);
  }
```

- [ ] **Step 3: Verify no compile errors**

```bash
flutter analyze lib/services/event_tracking_service.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/services/event_tracking_service.dart
git commit -m "feat(content-engine): add trackView/trackScrollPast/trackNotInterested to EventTrackingService"
```

---

## Task 7: PostCard enhancements — "Sipendezwi" menu + dwell tracking

**Files:**
- Modify: `lib/widgets/post_card.dart`

**Dependencies:** Task 6 (event tracking methods)

- [ ] **Step 1: Read the full PostCard file**

Read `lib/widgets/post_card.dart` in full. Understand:
1. The existing menu/popup (onMenuTap or PopupMenuButton)
2. Where the card renders (the main build method)
3. Existing callback signatures

- [ ] **Step 2: Add `onNotInterested` callback to PostCard**

PostCard delegates menu handling to the parent via `onMenuTap` callback (line 44, 64, 491 in post_card.dart). It does NOT have its own PopupMenuButton. So we:

1. Add the callback parameter to PostCard's constructor alongside the other 14 callbacks:

```dart
final VoidCallback? onNotInterested;
```

2. Add it to the constructor: `this.onNotInterested,`

3. The parent screens (FeedScreen, UniversalSearchScreen) are responsible for showing the menu popup and including the "Sipendezwi na hii" option when they handle `onMenuTap`. The ContentResultCard already passes through callbacks, so no changes needed in the card router.

**Note:** The actual menu popup lives in the parent screen's `_showPostMenu()` method (or equivalent). When integrating in Task 8 (feed integration), add the "not interested" option there.

- [ ] **Step 3: Add context reason badge**

If the PostCard is being used inside ContentResultCard, the reason label is already shown by ContentResultCard. No changes needed to PostCard itself for this.

- [ ] **Step 4: Verify no compile errors**

```bash
flutter analyze lib/widgets/post_card.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/post_card.dart
git commit -m "feat(content-engine): add 'Sipendezwi na hii' menu option to PostCard + onNotInterested callback"
```

---

## Task 8: Feed integration — FeedScreen + DiscoverFeedContent use ContentEngineService

**Files:**
- Modify: `lib/screens/feed/feed_screen.dart`
- Modify: `lib/screens/feed/discover_feed_content.dart`

**Dependencies:** Tasks 1-2 (models + service)

- [ ] **Step 1: Read both files in full**

Read `lib/screens/feed/feed_screen.dart` and `lib/screens/feed/discover_feed_content.dart` completely. Understand:
1. How `FeedService.getFeed()` is called
2. Where posts lists are stored
3. How the scroll/pagination works
4. How errors are handled

- [ ] **Step 2: Modify FeedScreen — For You tab uses ContentEngineService**

In `feed_screen.dart`, find the method that loads the "for_you" or "posts" feed (likely `_loadFeed()` or similar). Add a v2 path that tries `ContentEngineService.feed()` first, with fallback already handled inside the service.

Key changes:
1. Import `content_engine_service.dart` and `content_engine_models.dart`
2. Add a field: `List<ContentDocumentResult> _engineResults = [];`
3. Add a bool: `bool _useContentEngine = true;`
4. In the feed loading method for 'for_you' or 'posts' feed type, try ContentEngineService first:

```dart
// Try v2 Content Engine first
if (_useContentEngine) {
  final engineResult = await ContentEngineService.feed(
    feedType: feedType,
    userId: _currentUserId,
    page: page,
    perPage: perPage,
  );
  // If we got results (even from legacy fallback), use them
  if (engineResult.isNotEmpty) {
    // Extract Post objects from ContentDocumentResults
    final posts = engineResult.items
        .where((item) => item.post != null)
        .map((item) => item.post!)
        .toList();
    // ... update state with posts ...
    return;
  }
}
// Direct v1 fallback
```

**IMPORTANT:** The ContentEngineService already handles fallback internally. So the FeedScreen change is minimal — just call ContentEngineService.feed() instead of FeedService.getFeed() for the for_you feed type. Keep FeedService for other feed types (friends, etc.) that don't go through the Content Engine.

- [ ] **Step 3: Modify DiscoverFeedContent — use ContentEngineService for discover**

In `discover_feed_content.dart`, find the method that loads discover posts. Replace the direct API call with:

```dart
final engineResult = await ContentEngineService.feed(
  feedType: 'discover',
  userId: _currentUserId,
  page: page,
);
final posts = engineResult.items
    .where((item) => item.post != null)
    .map((item) => item.post!)
    .toList();
```

- [ ] **Step 4: Verify no compile errors**

```bash
flutter analyze lib/screens/feed/feed_screen.dart lib/screens/feed/discover_feed_content.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/screens/feed/feed_screen.dart lib/screens/feed/discover_feed_content.dart
git commit -m "feat(content-engine): migrate For You + Discover feeds to ContentEngineService with automatic v1 fallback"
```

---

## Task 9: Routes + wiring — connect UniversalSearchScreen

**Files:**
- Modify: `lib/main.dart`

**Dependencies:** Task 5 (UniversalSearchScreen)

- [ ] **Step 1: Read the routing section of main.dart**

Read `lib/main.dart`. Find the `onGenerateRoute` handler and the existing `/search` route.

- [ ] **Step 2: Update the /search route**

Change the `/search` route to use `UniversalSearchScreen` instead of the old `SearchScreen`:

```dart
// Add import at top:
import 'screens/search/universal_search_screen.dart';

// In onGenerateRoute, replace the /search case body (the existing FutureBuilder pattern):
// Change: return SearchScreen(currentUserId: snapshot.data!);
// To:     return UniversalSearchScreen(currentUserId: snapshot.data!);
// The FutureBuilder<int> wrapper stays the same.
```

Keep the old SearchScreen import in case other routes reference it (e.g., a direct users-only search).

- [ ] **Step 3: Verify no compile errors**

```bash
flutter analyze lib/main.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat(content-engine): wire UniversalSearchScreen to /search route"
```

---

## Task 10: Full verification — flutter analyze + manual review

**Files:** All modified files

- [ ] **Step 1: Run flutter analyze on all Phase 6 files**

```bash
flutter analyze \
  lib/models/content_engine_models.dart \
  lib/services/content_engine_service.dart \
  lib/widgets/content_result_card.dart \
  lib/widgets/trending_digest_card.dart \
  lib/screens/search/universal_search_screen.dart \
  lib/services/event_tracking_service.dart \
  lib/widgets/post_card.dart \
  lib/screens/feed/feed_screen.dart \
  lib/screens/feed/discover_feed_content.dart \
  lib/l10n/app_strings.dart \
  lib/main.dart
```

Expected: Zero errors. Info-level warnings acceptable.

- [ ] **Step 2: Verify existing tests still pass**

```bash
flutter test
```

- [ ] **Step 3: Verify app builds**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: Build succeeds.

- [ ] **Step 4: Final commit if any fixes were needed**

```bash
git add -A
git commit -m "fix(content-engine): resolve Phase 6 analysis warnings"
```

---

## Phase 6 Completion Criteria

- [ ] `ContentEngineResult`, `ContentDocumentResult`, `ContentScores`, `ContentContext`, `TrendingDigest` models parse v2 response
- [ ] `ContentEngineResult.fromLegacy()` wraps v1 Post list correctly
- [ ] `ContentEngineService.feed()` calls v2 endpoint, falls back to v1 on 404/error
- [ ] `ContentEngineService.search()` calls v2 endpoint with type/category/region filters
- [ ] `ContentResultCard` routes post → PostCard, other types → compact cards
- [ ] `TrendingDigestCard` displays AI digest with expandable stories
- [ ] `UniversalSearchScreen` has three states: trending → autocomplete → results with type tabs
- [ ] `EventTrackingService` has `trackView()`, `trackScrollPast()`, `trackNotInterested()`
- [ ] PostCard has "Sipendezwi na hii" menu option + `onNotInterested` callback
- [ ] FeedScreen For You tab uses `ContentEngineService.feed()` with fallback
- [ ] DiscoverFeedContent uses `ContentEngineService.feed(feedType: 'discover')` with fallback
- [ ] `/search` route points to `UniversalSearchScreen`
- [ ] All Swahili strings added to `AppStrings`
- [ ] `flutter analyze` — zero errors
- [ ] `flutter test` — all existing tests pass
- [ ] `flutter build apk --debug` — builds successfully

**Deferred:**
- Autocomplete API endpoint (backend doesn't have `/api/v2/autocomplete` yet)
- Trending hashtags in pre-search state (need backend endpoint)
- VisibilityDetector on PostCard for automatic dwell tracking (needs `visibility_detector` package in pubspec.yaml)
- `/api/v2/trending-digest` endpoint (backend has `trending_digests` table but no API route — will need backend Task to expose it)
- GossipThreadCard hydration in ContentResultCard (needs thread model parsing from sourceJson)
