import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../services/http_retry.dart';
import '../../config/api_config.dart';
import '../../services/graphql/graphql_creator_metrics_service.dart';
import '../models/collaboration_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class CollaborationService {
  Future<List<CollaborationSuggestion>> getSuggestions({
    String? token,
    required int creatorId,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      final rows = await GraphqlCreatorMetricsService.getCollaborations(creatorId);
      return rows.map((e) => CollaborationSuggestion.fromJson(e)).toList();
    }
    final url = Uri.parse('$_baseUrl/creators/$creatorId/collaborations');
    if (kDebugMode) debugPrint('[CollaborationService] getSuggestions → $url');
    try {
      final response = await httpGetWithRetry(
        url,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (kDebugMode) debugPrint('[CollaborationService] getSuggestions ← ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawList = data['data'] is List ? data['data'] as List : [];
        return rawList.whereType<Map<String, dynamic>>()
            .map((e) => CollaborationSuggestion.fromJson(e)).toList();
      }
      if (kDebugMode) debugPrint('[CollaborationService] getSuggestions body: ${response.body.substring(0, (response.body.length).clamp(0, 200))}');
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('[CollaborationService] getSuggestions error: $e');
      return [];
    }
  }

  Future<bool> respond({
    required String token,
    required int suggestionId,
    required String action, // 'accepted' or 'dismissed'
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlCreatorMetricsService.respondToCollaboration(
        suggestionId: suggestionId,
        action: action,
      );
    }
    final url = Uri.parse('$_baseUrl/collaborations/$suggestionId/respond');
    if (kDebugMode) debugPrint('[CollaborationService] respond → $url ($action)');
    try {
      final response = await http.post(
        url,
        headers: {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'},
        body: jsonEncode({'action': action}),
      );
      if (kDebugMode) debugPrint('[CollaborationService] respond ← ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('[CollaborationService] respond error: $e');
      return false;
    }
  }
}
