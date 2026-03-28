import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/flywheel_models.dart';
import '../models/payment_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

/// Service for creator metrics, streaks, and scores.
/// Instance-based (same pattern as PostService, FeedService).
class CreatorService {
  /// GET /api/creators/{id}/score
  Future<CreatorScore?> getCreatorScore({
    required int creatorId,
    String? token,
  }) async {
    final url = Uri.parse('$_baseUrl/creators/$creatorId/score');
    if (kDebugMode) debugPrint('[CreatorService] getCreatorScore → $url');
    try {
      final response = await http.get(
        url,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (kDebugMode) debugPrint('[CreatorService] getCreatorScore ← ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final scoreData = data['data'] ?? data;
        return CreatorScore.fromJson(scoreData as Map<String, dynamic>);
      }
      if (kDebugMode) debugPrint('[CreatorService] getCreatorScore body: ${response.body.substring(0, (response.body.length).clamp(0, 200))}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[CreatorService] getCreatorScore error: $e');
      return null;
    }
  }

  /// GET /api/creators/{id}/streak
  Future<CreatorStreak?> getCreatorStreak({
    required int creatorId,
    String? token,
  }) async {
    final url = Uri.parse('$_baseUrl/creators/$creatorId/streak');
    if (kDebugMode) debugPrint('[CreatorService] getCreatorStreak → $url');
    try {
      final response = await http.get(
        url,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (kDebugMode) debugPrint('[CreatorService] getCreatorStreak ← ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final streakData = data['data'] ?? data;
        return CreatorStreak.fromJson(streakData as Map<String, dynamic>);
      }
      if (kDebugMode) debugPrint('[CreatorService] getCreatorStreak body: ${response.body.substring(0, (response.body.length).clamp(0, 200))}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[CreatorService] getCreatorStreak error: $e');
      return null;
    }
  }

  /// GET /api/users/{id}/streak
  Future<ViewerStreak?> getViewerStreak({
    required int userId,
    String? token,
  }) async {
    final url = Uri.parse('$_baseUrl/users/$userId/streak');
    if (kDebugMode) debugPrint('[CreatorService] getViewerStreak → $url');
    try {
      final response = await http.get(
        url,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (kDebugMode) debugPrint('[CreatorService] getViewerStreak ← ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final streakData = data['data'] ?? data;
        return ViewerStreak.fromJson(streakData as Map<String, dynamic>);
      }
      if (kDebugMode) debugPrint('[CreatorService] getViewerStreak body: ${response.body.substring(0, (response.body.length).clamp(0, 200))}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[CreatorService] getViewerStreak error: $e');
      return null;
    }
  }

  /// GET /api/creators/{id}/weekly-report
  Future<WeeklyReport?> getWeeklyReport(int creatorId, [String? token]) async {
    final url = Uri.parse('$_baseUrl/creators/$creatorId/weekly-report');
    if (kDebugMode) debugPrint('[CreatorService] getWeeklyReport → $url');
    try {
      final response = await http.get(
        url,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (kDebugMode) debugPrint('[CreatorService] getWeeklyReport ← ${response.statusCode}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] ?? body;
        if (data is Map<String, dynamic>) {
          return WeeklyReport.fromJson(data);
        }
      }
      if (kDebugMode) debugPrint('[CreatorService] getWeeklyReport body: ${response.body.substring(0, (response.body.length).clamp(0, 200))}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[CreatorService] getWeeklyReport error: $e');
      return null;
    }
  }

  /// GET /api/creators/{id}/viral-assists
  Future<int> getViralAssists({required int creatorId, String? token}) async {
    final url = Uri.parse('$_baseUrl/creators/$creatorId/viral-assists');
    if (kDebugMode) debugPrint('[CreatorService] getViralAssists → $url');
    try {
      final response = await http.get(
        url,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data']?['count'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      if (kDebugMode) debugPrint('[CreatorService] getViralAssists error: $e');
      return 0;
    }
  }

  /// GET /api/creators/{id}/posting-nudge
  Future<PostingNudge?> getPostingNudge({required int creatorId, String? token}) async {
    final url = Uri.parse('$_baseUrl/creators/$creatorId/posting-nudge');
    try {
      final response = await http.get(url, headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final nudgeData = data['data'] ?? data;
        if (nudgeData is Map<String, dynamic>) {
          return PostingNudge.fromJson(nudgeData);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[CreatorService] getPostingNudge error: $e');
      return null;
    }
  }

  /// GET /api/creators/{id}/content-calendar
  Future<ContentCalendar?> getContentCalendar({required int creatorId, String? token}) async {
    final url = Uri.parse('$_baseUrl/creators/$creatorId/content-calendar');
    try {
      final response = await http.get(url, headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final calData = data['data'] ?? data;
        if (calData is Map<String, dynamic>) return ContentCalendar.fromJson(calData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// GET /api/creators/{id}/fund-payout
  Future<FundPayoutProjection?> getFundPayoutProjection({
    required int creatorId,
    String? token,
  }) async {
    final url = Uri.parse('$_baseUrl/creators/$creatorId/fund-payout');
    if (kDebugMode) debugPrint('[CreatorService] getFundPayoutProjection → $url');
    try {
      final response = await http.get(
        url,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (kDebugMode) debugPrint('[CreatorService] getFundPayoutProjection ← ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final payoutData = data['data'] ?? data;
        return FundPayoutProjection.fromJson(payoutData as Map<String, dynamic>);
      }
      if (kDebugMode) debugPrint('[CreatorService] getFundPayoutProjection body: ${response.body.substring(0, (response.body.length).clamp(0, 200))}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[CreatorService] getFundPayoutProjection error: $e');
      return null;
    }
  }

  /// POST /api/users/{id}/streak/resume — resumes a frozen viewer streak
  Future<bool> resumeViewerStreak({required int userId, String? token}) async {
    final url = Uri.parse('$_baseUrl/users/$userId/streak/resume');
    if (kDebugMode) debugPrint('[CreatorService] resumeViewerStreak → $url');
    try {
      final response = await http.post(
        url,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (kDebugMode) debugPrint('[CreatorService] resumeViewerStreak ← ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('[CreatorService] resumeViewerStreak error: $e');
      return false;
    }
  }
}
