import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/flywheel_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

/// Service for creator metrics, streaks, and scores.
/// Instance-based (same pattern as PostService, FeedService).
class CreatorService {
  /// GET /api/creators/{id}/score
  Future<CreatorScore?> getCreatorScore({
    required int creatorId,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/creators/$creatorId/score');
      final response = await http.get(url, headers: ApiConfig.authHeaders(token));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final scoreData = data['data'] ?? data;
        return CreatorScore.fromJson(scoreData as Map<String, dynamic>);
      }
      if (kDebugMode) {
        debugPrint('[CreatorService] getCreatorScore ${response.statusCode}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[CreatorService] getCreatorScore error: $e');
      return null;
    }
  }

  /// GET /api/creators/{id}/streak
  Future<CreatorStreak?> getCreatorStreak({
    required int creatorId,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/creators/$creatorId/streak');
      final response = await http.get(url, headers: ApiConfig.authHeaders(token));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final streakData = data['data'] ?? data;
        return CreatorStreak.fromJson(streakData as Map<String, dynamic>);
      }
      if (kDebugMode) {
        debugPrint('[CreatorService] getCreatorStreak ${response.statusCode}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[CreatorService] getCreatorStreak error: $e');
      return null;
    }
  }

  /// GET /api/users/{id}/streak
  Future<ViewerStreak?> getViewerStreak({
    required int userId,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/users/$userId/streak');
      final response = await http.get(url, headers: ApiConfig.authHeaders(token));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final streakData = data['data'] ?? data;
        return ViewerStreak.fromJson(streakData as Map<String, dynamic>);
      }
      if (kDebugMode) {
        debugPrint('[CreatorService] getViewerStreak ${response.statusCode}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[CreatorService] getViewerStreak error: $e');
      return null;
    }
  }

  /// GET /api/creators/{id}/fund-payout
  Future<FundPayoutProjection?> getFundPayoutProjection({
    required int creatorId,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/creators/$creatorId/fund-payout');
      final response = await http.get(url, headers: ApiConfig.authHeaders(token));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final payoutData = data['data'] ?? data;
        return FundPayoutProjection.fromJson(payoutData as Map<String, dynamic>);
      }
      if (kDebugMode) {
        debugPrint('[CreatorService] getFundPayoutProjection ${response.statusCode}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[CreatorService] getFundPayoutProjection error: $e');
      return null;
    }
  }
}
