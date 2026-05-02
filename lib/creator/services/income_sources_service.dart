// IncomeSourcesService — client for /api/creators/{id}/income/* endpoints.
// Spec: docs/superpowers/specs/2026-05-02-creator-income-sources-design.md §8
//
// Backend owns all eligibility evaluation. This service is a thin renderer-
// side client; it never decides whether a source is locked or not.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/income_source.dart';

String get _baseUrl => ApiConfig.baseUrl;

class IncomeSourcesService {
  /// GET /api/creators/{id}/income/sources?period=...
  /// Returns the panoramic payload: summary + period + sources + optional
  /// live tally. Returns null on any non-200 response or parse failure.
  Future<IncomeSourcesResponse?> getSources({
    required int creatorId,
    IncomePeriod period = IncomePeriod.month,
    String? token,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/creators/$creatorId/income/sources?period=${period.wire}',
    );
    if (kDebugMode) debugPrint('[IncomeSourcesService] getSources → $url');
    try {
      final response = await http.get(
        url,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (kDebugMode) {
        debugPrint('[IncomeSourcesService] getSources ← ${response.statusCode}');
      }
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = (body is Map && body['data'] is Map<String, dynamic>)
            ? body['data'] as Map<String, dynamic>
            : (body is Map<String, dynamic> ? body : <String, dynamic>{});
        return IncomeSourcesResponse.fromJson(data);
      }
      if (kDebugMode) {
        final excerpt = response.body.substring(
          0,
          response.body.length.clamp(0, 200),
        );
        debugPrint('[IncomeSourcesService] getSources body: $excerpt');
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[IncomeSourcesService] getSources error: $e');
      return null;
    }
  }

  /// GET /api/creators/{id}/income/sources/{sourceId}?period=...
  Future<IncomeSource?> getSourceDetail({
    required int creatorId,
    required String sourceId,
    IncomePeriod period = IncomePeriod.month,
    String? token,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/creators/$creatorId/income/sources/$sourceId?period=${period.wire}',
    );
    if (kDebugMode) debugPrint('[IncomeSourcesService] getSourceDetail → $url');
    try {
      final response = await http.get(
        url,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = (body is Map && body['data'] is Map<String, dynamic>)
            ? body['data'] as Map<String, dynamic>
            : (body is Map<String, dynamic> ? body : <String, dynamic>{});
        return IncomeSource.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[IncomeSourcesService] getSourceDetail error: $e');
      }
      return null;
    }
  }

  /// GET /api/creators/{id}/income/sources/{sourceId}/history?cursor=&limit=
  Future<HistoryPage?> getHistory({
    required int creatorId,
    required String sourceId,
    String? cursor,
    int limit = 20,
    String? token,
  }) async {
    final params = <String, String>{'limit': '$limit'};
    if (cursor != null) params['cursor'] = cursor;
    final url = Uri.parse(
      '$_baseUrl/creators/$creatorId/income/sources/$sourceId/history',
    ).replace(queryParameters: params);

    if (kDebugMode) debugPrint('[IncomeSourcesService] getHistory → $url');
    try {
      final response = await http.get(
        url,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = (body is Map && body['data'] is Map<String, dynamic>)
            ? body['data'] as Map<String, dynamic>
            : (body is Map<String, dynamic> ? body : <String, dynamic>{});
        return HistoryPage.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[IncomeSourcesService] getHistory error: $e');
      return null;
    }
  }

  /// PATCH /api/creators/{id}/income/sources/{sourceId}/settings
  /// Settings shape varies per source — backend validates the schema.
  Future<bool> updateSettings({
    required int creatorId,
    required String sourceId,
    required Map<String, dynamic> settings,
    String? token,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/creators/$creatorId/income/sources/$sourceId/settings',
    );
    if (kDebugMode) debugPrint('[IncomeSourcesService] updateSettings → $url');
    try {
      final response = await http.patch(
        url,
        headers: token != null
            ? {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'}
            : {...ApiConfig.headers, 'Content-Type': 'application/json'},
        body: jsonEncode(settings),
      );
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[IncomeSourcesService] updateSettings error: $e');
      }
      return false;
    }
  }

  /// POST /api/creators/{id}/income/sources/{sourceId}/activate
  /// Transitions a `ready` source to `earning`.
  Future<IncomeSource?> activateSource({
    required int creatorId,
    required String sourceId,
    String? token,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/creators/$creatorId/income/sources/$sourceId/activate',
    );
    if (kDebugMode) debugPrint('[IncomeSourcesService] activateSource → $url');
    try {
      final response = await http.post(
        url,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final src = body is Map && body['source'] is Map<String, dynamic>
            ? body['source'] as Map<String, dynamic>
            : (body is Map && body['data'] is Map && body['data']['source'] is Map<String, dynamic>
                ? (body['data']['source'] as Map<String, dynamic>)
                : null);
        if (src != null) return IncomeSource.fromJson(src);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[IncomeSourcesService] activateSource error: $e');
      }
      return null;
    }
  }

  /// POST /api/creators/{id}/income/sources/{sourceId}/notify-on-unlock
  /// Subscribes the creator to the FCM unlock-ready event.
  Future<bool> notifyOnUnlock({
    required int creatorId,
    required String sourceId,
    String? token,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/creators/$creatorId/income/sources/$sourceId/notify-on-unlock',
    );
    if (kDebugMode) debugPrint('[IncomeSourcesService] notifyOnUnlock → $url');
    try {
      final response = await http.post(
        url,
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[IncomeSourcesService] notifyOnUnlock error: $e');
      }
      return false;
    }
  }
}
