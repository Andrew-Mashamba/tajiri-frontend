import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/analytics_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class AnalyticsService {
  Future<AnalyticsDashboard?> getDashboard({
    String? token,
    required int creatorId,
  }) async {
    final url = Uri.parse('$_baseUrl/creators/$creatorId/analytics/dashboard');
    if (kDebugMode) debugPrint('[AnalyticsService] getDashboard → $url');
    try {
      final response = await http.get(
        url,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (kDebugMode) debugPrint('[AnalyticsService] getDashboard ← ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dashData = data['data'] ?? data;
        if (dashData is Map<String, dynamic>) {
          return AnalyticsDashboard.fromJson(dashData);
        }
      }
      if (kDebugMode) debugPrint('[AnalyticsService] getDashboard body: ${response.body.substring(0, (response.body.length).clamp(0, 200))}');
      return null;
    } catch (e) {
      debugPrint('[AnalyticsService] getDashboard error: $e');
      return null;
    }
  }

  Future<List<PostPerformance>> getPostPerformance({
    String? token,
    required int creatorId,
  }) async {
    final url = Uri.parse('$_baseUrl/creators/$creatorId/analytics/posts');
    if (kDebugMode) debugPrint('[AnalyticsService] getPostPerformance → $url');
    try {
      final response = await http.get(
        url,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (kDebugMode) debugPrint('[AnalyticsService] getPostPerformance ← ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawList = data['data'] is List ? data['data'] as List : [];
        return rawList.whereType<Map<String, dynamic>>()
            .map((e) => PostPerformance.fromJson(e)).toList();
      }
      if (kDebugMode) debugPrint('[AnalyticsService] getPostPerformance body: ${response.body.substring(0, (response.body.length).clamp(0, 200))}');
      return [];
    } catch (e) {
      debugPrint('[AnalyticsService] getPostPerformance error: $e');
      return [];
    }
  }

  Future<AudienceInsight?> getAudienceInsights({
    String? token,
    required int creatorId,
  }) async {
    final url = Uri.parse('$_baseUrl/creators/$creatorId/analytics/audience');
    if (kDebugMode) debugPrint('[AnalyticsService] getAudienceInsights → $url');
    try {
      final response = await http.get(
        url,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (kDebugMode) debugPrint('[AnalyticsService] getAudienceInsights ← ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final insightData = data['data'] ?? data;
        if (insightData is Map<String, dynamic>) {
          return AudienceInsight.fromJson(insightData);
        }
      }
      if (kDebugMode) debugPrint('[AnalyticsService] getAudienceInsights body: ${response.body.substring(0, (response.body.length).clamp(0, 200))}');
      return null;
    } catch (e) {
      debugPrint('[AnalyticsService] getAudienceInsights error: $e');
      return null;
    }
  }

  /// Get user's engagement level (gentle/medium/full).
  Future<String> getEngagementLevel({
    String? token,
    required int userId,
  }) async {
    final url = Uri.parse('$_baseUrl/users/$userId/engagement-level');
    if (kDebugMode) debugPrint('[AnalyticsService] getEngagementLevel → $url');
    try {
      final response = await http.get(
        url,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (kDebugMode) debugPrint('[AnalyticsService] getEngagementLevel ← ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data']?['level'] as String?) ?? 'gentle';
      }
      if (kDebugMode) debugPrint('[AnalyticsService] getEngagementLevel body: ${response.body.substring(0, (response.body.length).clamp(0, 200))}');
      return 'gentle';
    } catch (e) {
      debugPrint('[AnalyticsService] getEngagementLevel error: $e');
      return 'gentle';
    }
  }
}
