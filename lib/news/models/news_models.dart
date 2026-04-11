// lib/news/models/news_models.dart
import 'package:flutter/material.dart';

// ─── News Category ────────────────────────────────────────────

enum NewsCategory {
  politics,
  business,
  sports,
  entertainment,
  technology,
  health,
  education,
  international,
  local;

  String get displayName {
    switch (this) {
      case NewsCategory.politics:
        return 'Siasa';
      case NewsCategory.business:
        return 'Biashara';
      case NewsCategory.sports:
        return 'Michezo';
      case NewsCategory.entertainment:
        return 'Burudani';
      case NewsCategory.technology:
        return 'Teknolojia';
      case NewsCategory.health:
        return 'Afya';
      case NewsCategory.education:
        return 'Elimu';
      case NewsCategory.international:
        return 'Kimataifa';
      case NewsCategory.local:
        return 'Ndani';
    }
  }

  String get subtitle {
    switch (this) {
      case NewsCategory.politics:
        return 'Politics';
      case NewsCategory.business:
        return 'Business';
      case NewsCategory.sports:
        return 'Sports';
      case NewsCategory.entertainment:
        return 'Entertainment';
      case NewsCategory.technology:
        return 'Technology';
      case NewsCategory.health:
        return 'Health';
      case NewsCategory.education:
        return 'Education';
      case NewsCategory.international:
        return 'International';
      case NewsCategory.local:
        return 'Local';
    }
  }

  IconData get icon {
    switch (this) {
      case NewsCategory.politics:
        return Icons.gavel_rounded;
      case NewsCategory.business:
        return Icons.trending_up_rounded;
      case NewsCategory.sports:
        return Icons.sports_soccer_rounded;
      case NewsCategory.entertainment:
        return Icons.movie_rounded;
      case NewsCategory.technology:
        return Icons.computer_rounded;
      case NewsCategory.health:
        return Icons.health_and_safety_rounded;
      case NewsCategory.education:
        return Icons.school_rounded;
      case NewsCategory.international:
        return Icons.public_rounded;
      case NewsCategory.local:
        return Icons.location_on_rounded;
    }
  }

  static NewsCategory fromString(String? s) {
    return NewsCategory.values.firstWhere(
      (v) => v.name == s,
      orElse: () => NewsCategory.local,
    );
  }
}

// ─── News Article ─────────────────────────────────────────────

class NewsArticle {
  final int id;
  final String title;
  final String summary;
  final String content;
  final String? imageUrl;
  final String source;
  final String? sourceUrl;
  final String? author;
  final DateTime publishedAt;
  final NewsCategory category;
  final bool isSaved;
  final int readTimeMinutes;

  NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    this.imageUrl,
    required this.source,
    this.sourceUrl,
    this.author,
    required this.publishedAt,
    required this.category,
    this.isSaved = false,
    this.readTimeMinutes = 3,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      source: json['source']?.toString() ?? '',
      sourceUrl: json['source_url']?.toString(),
      author: json['author']?.toString(),
      publishedAt: DateTime.tryParse(json['published_at']?.toString() ?? '') ?? DateTime.now(),
      category: NewsCategory.fromString(json['category']?.toString()),
      isSaved: _parseBool(json['is_saved']),
      readTimeMinutes: _parseInt(json['read_time_minutes']),
    );
  }
}

// ─── Result wrappers ──────────────────────────────────────────

class NewsResult<T> {
  final bool success;
  final T? data;
  final String? message;

  NewsResult({required this.success, this.data, this.message});
}

class NewsListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  NewsListResult({required this.success, this.items = const [], this.message});
}

// ─── Parse helpers ────────────────────────────────────────────

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}
