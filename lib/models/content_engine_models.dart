// Content Engine v2 API response models.
// Wraps search/feed results from the backend Content Engine pipeline.

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
