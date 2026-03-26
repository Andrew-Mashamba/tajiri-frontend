import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/collaboration_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class CollaborationService {
  Future<List<CollaborationSuggestion>> getSuggestions({
    required String token,
    required int creatorId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/creators/$creatorId/collaborations'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawList = data['data'] is List ? data['data'] as List : [];
        return rawList.whereType<Map<String, dynamic>>()
            .map((e) => CollaborationSuggestion.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[CollaborationService] getSuggestions error: $e');
      return [];
    }
  }

  Future<bool> respond({
    required String token,
    required int suggestionId,
    required String action, // 'accepted' or 'dismissed'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/collaborations/$suggestionId/respond'),
        headers: {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'},
        body: jsonEncode({'action': action}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[CollaborationService] respond error: $e');
      return false;
    }
  }
}
