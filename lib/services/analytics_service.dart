import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/analytics_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class AnalyticsService {
  Future<AnalyticsDashboard?> getDashboard({
    required String token,
    required int creatorId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/creators/$creatorId/analytics'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dashData = data['data'] ?? data;
        if (dashData is Map<String, dynamic>) {
          return AnalyticsDashboard.fromJson(dashData);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[AnalyticsService] getDashboard error: $e');
      return null;
    }
  }

  Future<PostPerformance?> getPostPerformance({
    required String token,
    required int postId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/posts/$postId/analytics'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final perfData = data['data'] ?? data;
        if (perfData is Map<String, dynamic>) {
          return PostPerformance.fromJson(perfData);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[AnalyticsService] getPostPerformance error: $e');
      return null;
    }
  }

  Future<AudienceInsight?> getAudienceInsights({
    required String token,
    required int creatorId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/creators/$creatorId/audience'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final insightData = data['data'] ?? data;
        if (insightData is Map<String, dynamic>) {
          return AudienceInsight.fromJson(insightData);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[AnalyticsService] getAudienceInsights error: $e');
      return null;
    }
  }

  /// Get user's engagement level (gentle/medium/full).
  Future<String> getEngagementLevel({
    required String token,
    required int userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/engagement-level'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data']?['level'] as String?) ?? 'gentle';
      }
      return 'gentle';
    } catch (e) {
      debugPrint('[AnalyticsService] getEngagementLevel error: $e');
      return 'gentle';
    }
  }
}
