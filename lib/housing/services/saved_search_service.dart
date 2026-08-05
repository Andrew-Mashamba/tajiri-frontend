import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../services/http_retry.dart';
import '../../config/api_config.dart';

/// Spec line 939 — saved searches with email/push digest opt-in. Backed by
/// `property_saved_searches` and `/partner-c2b/research/saved-searches/*`.
class SavedSearchEntry {
  final int id;
  final String label;
  final Map<String, dynamic> filters;
  final bool digestEmail;
  final bool digestPush;
  final DateTime? lastDigestAt;
  final DateTime? createdAt;

  SavedSearchEntry({
    required this.id,
    required this.label,
    required this.filters,
    required this.digestEmail,
    required this.digestPush,
    required this.lastDigestAt,
    required this.createdAt,
  });

  factory SavedSearchEntry.fromJson(Map<String, dynamic> json) {
    DateTime? d(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    int? p(dynamic v) =>
        v == null ? null : (v is int ? v : int.tryParse(v.toString()));
    return SavedSearchEntry(
      id: p(json['id']) ?? 0,
      label: json['label']?.toString() ?? '',
      filters: json['filters'] is Map
          ? (json['filters'] as Map).cast<String, dynamic>()
          : <String, dynamic>{},
      digestEmail: json['digest_email'] == true,
      digestPush: json['digest_push'] == true,
      lastDigestAt: d(json['last_digest_at']),
      createdAt: d(json['created_at']),
    );
  }
}

class SavedSearchService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<List<SavedSearchEntry>> list({required int userId}) async {
    final uri = Uri.parse('$_baseUrl/partner-c2b/research/saved-searches')
        .replace(queryParameters: {'user_id': '$userId'});
    debugPrint('[SavedSearchService] GET $uri');
    try {
      final res = await httpGetWithRetry(uri);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          return (body['data'] as List)
              .whereType<Map>()
              .map((m) => SavedSearchEntry.fromJson(m.cast<String, dynamic>()))
              .toList();
        }
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> save({
    required int userId,
    required String label,
    required Map<String, dynamic> filters,
    bool digestEmail = true,
    bool digestPush = true,
  }) async {
    final uri = Uri.parse('$_baseUrl/partner-c2b/research/saved-searches');
    try {
      final res = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'label': label,
          'filters': filters,
          'digest_email': digestEmail,
          'digest_push': digestPush,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> remove({required int id, required int userId}) async {
    final uri = Uri.parse('$_baseUrl/partner-c2b/research/saved-searches/$id');
    try {
      final res = await http.delete(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
