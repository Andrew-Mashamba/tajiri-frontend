// Gossip thread models for the Flywheel gossip-virality engine.

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
  final String? topReaction;

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
    this.topReaction,
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
      topReaction: json['top_reaction'] as String?,
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
