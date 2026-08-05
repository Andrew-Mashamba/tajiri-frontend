// lib/services/translation_service.dart
//
// Localization MVP — strategy posts.md §VI / G-F-003.
// Submit a translation/dub for an existing post; backend fires
// translation_create·translator (or dub_create·voice_actor when audio_url
// is present) and the translator earns from translated_view·translator.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_retry.dart';
import '../config/api_config.dart';

class PostTranslation {
  final int id;
  final int postId;
  final int translatorUserId;
  final String locale;
  final String content;
  final String? audioUrl;
  final String status;

  PostTranslation({
    required this.id,
    required this.postId,
    required this.translatorUserId,
    required this.locale,
    required this.content,
    this.audioUrl,
    required this.status,
  });

  factory PostTranslation.fromJson(Map<String, dynamic> j) => PostTranslation(
        id: (j['id'] as num?)?.toInt() ?? 0,
        postId: (j['post_id'] as num?)?.toInt() ?? 0,
        translatorUserId: (j['translator_user_id'] as num?)?.toInt() ?? 0,
        locale: j['locale'] as String? ?? 'en',
        content: j['content'] as String? ?? '',
        audioUrl: j['audio_url'] as String?,
        status: j['status'] as String? ?? 'pending',
      );
}

class TranslationService {
  String get _base => ApiConfig.baseUrl;

  /// List approved translations available for a post (for locale switcher).
  Future<List<PostTranslation>> listApproved(int postId) async {
    try {
      final resp = await httpGetWithRetry(
        Uri.parse('$_base/posts/$postId/translations'),
      );
      if (resp.statusCode != 200) return const [];
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      if (body['success'] != true) return const [];
      final raw = body['data'] as List<dynamic>? ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(PostTranslation.fromJson)
          .where((t) => t.status == 'approved')
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// UN-010 / posts.md row 55 — translated_view·translator.
  /// Fire when the viewer reads a translated variant of a post.
  Future<bool> recordView({
    required int postId,
    required String locale,
    required int userId,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/posts/$postId/translations/$locale/view'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<int?> submit({
    required int postId,
    required int translatorUserId,
    required String locale,
    required String content,
    String? audioUrl,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/translations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'post_id': postId,
          'translator_user_id': translatorUserId,
          'locale': locale,
          'content': content,
          if (audioUrl != null && audioUrl.isNotEmpty) 'audio_url': audioUrl,
        }),
      );
      if (resp.statusCode != 200 && resp.statusCode != 201) return null;
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      if (body['success'] != true) return null;
      final inner = body['data'];
      if (inner is Map && inner['id'] is num) return (inner['id'] as num).toInt();
      return null;
    } catch (_) {
      return null;
    }
  }
}
