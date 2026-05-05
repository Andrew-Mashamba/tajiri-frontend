// lib/creator/services/creator_earnings_service.dart
//
// Creators Fund engine API client + Hive SWR cache. Strategy §1.2 + §9.

import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../models/creator_earnings_models.dart';

class CreatorEarningsService {
  String get _base => ApiConfig.baseUrl;

  static const _boxName = 'creator_earnings_cache';
  Future<Box> _box() => Hive.openBox(_boxName);

  // ── Dashboard ───────────────────────────────────────────────────────

  Future<CreatorEarningsDashboard> getDashboard({
    required int userId,
    required String token,
  }) async {
    final uri = Uri.parse('$_base/users/me/earnings?user_id=$userId');
    final resp = await http.get(uri, headers: ApiConfig.authHeaders(token));
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200 && body['success'] == true) {
      final dashboard =
          CreatorEarningsDashboard.fromJson(body['data'] as Map<String, dynamic>);
      await _cacheDashboard(userId, dashboard);
      return dashboard;
    }
    throw Exception(body['message'] ?? 'Failed to load earnings dashboard');
  }

  Future<CreatorEarningsDashboard?> getCachedDashboard(int userId) async {
    final box = await _box();
    final raw = box.get('dashboard_$userId');
    if (raw == null) return null;
    try {
      return CreatorEarningsDashboard.fromJson(
          jsonDecode(raw as String) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheDashboard(int userId, CreatorEarningsDashboard d) async {
    final box = await _box();
    await box.put('dashboard_$userId', jsonEncode({
      'user_id': d.userId,
      'total_cleared_tsh': d.totalClearedTsh,
      'total_pending_tsh': d.totalPendingTsh,
      'estimated_this_period_tsh': d.estimatedThisPeriodTsh,
      'currency': d.currency,
      'tier': d.tier,
      'is_mwanzo_active': d.isMwanzoActive,
      'mwanzo_expires_at': d.mwanzoExpiresAt,
      'monetization_paused': d.monetizationPaused,
      'breakdown_by_stream': d.breakdownByStream.map((k, v) => MapEntry(k, {
            'cleared_tsh': v.clearedTsh,
            'pending_tsh': v.pendingTsh,
            'event_count': v.eventCount,
          })),
      'current_period': d.currentPeriod == null
          ? null
          : {
              'period_start': d.currentPeriod!.periodStart,
              'period_end': d.currentPeriod!.periodEnd,
              'phase': d.currentPeriod!.phase,
              'fund_size_tsh': d.currentPeriod!.fundSizeTsh,
              'fund_per_point': d.currentPeriod!.fundPerPoint,
              'your_points': d.currentPeriod!.yourPoints,
            },
    }));
  }

  // ── Per-user events ────────────────────────────────────────────────

  Future<({List<EarningEventItem> items, int lastPage})> getEvents({
    required int userId,
    required String token,
    int page = 1,
    int perPage = 20,
    String? stream,
    String? status,
  }) async {
    final params = <String, String>{
      'user_id': '$userId',
      'page': '$page',
      'per_page': '$perPage',
      if (stream != null) 'stream': stream,
      if (status != null) 'status': status,
    };
    final uri = Uri.parse('$_base/users/me/earnings/events').replace(queryParameters: params);
    final resp = await http.get(uri, headers: ApiConfig.authHeaders(token));
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200 && body['success'] == true) {
      final items = (body['data'] as List)
          .map((e) => EarningEventItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final lastPage = (body['meta']?['last_page'] as int?) ?? 1;
      return (items: items, lastPage: lastPage);
    }
    throw Exception(body['message'] ?? 'Failed to load events');
  }

  // ── Per-post earnings ──────────────────────────────────────────────

  Future<PostEarningsV2> getPostEarnings(int postId, {String? token}) async {
    final uri = Uri.parse('$_base/posts/$postId/earnings');
    final headers = token != null ? ApiConfig.authHeaders(token) : <String, String>{};
    final resp = await http.get(uri, headers: headers);
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200 && body['success'] == true) {
      return PostEarningsV2.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to load post earnings');
  }

  Future<({List<EarningEventItem> items, int lastPage})> getPostEarningEvents({
    required int postId,
    required String token,
    int page = 1,
    int perPage = 20,
  }) async {
    final uri = Uri.parse('$_base/posts/$postId/earnings/events?page=$page&per_page=$perPage');
    final resp = await http.get(uri, headers: ApiConfig.authHeaders(token));
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200 && body['success'] == true) {
      final items = (body['data'] as List)
          .map((e) => EarningEventItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final lastPage = (body['meta']?['last_page'] as int?) ?? 1;
      return (items: items, lastPage: lastPage);
    }
    throw Exception(body['message'] ?? 'Failed to load post earning events');
  }

  // ── Rate card / discovery / disputes ───────────────────────────────

  Future<Map<String, dynamic>> getRateCard() async {
    final uri = Uri.parse('$_base/creators/rate-card');
    final resp = await http.get(uri);
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200 && body['success'] == true) {
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception('Failed to load rate card');
  }

  Future<void> enableDiscoveryMode({
    required int postId,
    required int userId,
    required String token,
  }) async {
    final uri = Uri.parse('$_base/posts/$postId/discovery-mode');
    final resp = await http.post(
      uri,
      headers: ApiConfig.authHeaders(token),
      body: jsonEncode({'user_id': userId}),
    );
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to enable Discovery Mode');
    }
  }

  Future<int> fileDispute({
    required int userId,
    required int eventId,
    required String reason,
    required String token,
  }) async {
    final uri = Uri.parse('$_base/users/me/earnings/disputes');
    final resp = await http.post(
      uri,
      headers: ApiConfig.authHeaders(token),
      body: jsonEncode({'user_id': userId, 'event_id': eventId, 'reason': reason}),
    );
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if ((resp.statusCode == 200 || resp.statusCode == 201) && body['success'] == true) {
      return (body['data']?['dispute_id'] as int?) ?? 0;
    }
    throw Exception(body['message'] ?? 'Failed to file dispute');
  }

  // ── Earnings by derivative kind (strategy §1C) ───────────────────

  Future<DerivativeKindResponse> getByDerivativeKind({
    required int userId,
    required String token,
    String period = 'month',
    String? postType,
  }) async {
    final params = <String, String>{
      'user_id': '$userId',
      'period': period,
      if (postType != null) 'post_type': postType,
    };
    final uri = Uri.parse('$_base/users/me/earnings/by-derivative-kind')
        .replace(queryParameters: params);
    final resp = await http.get(uri, headers: ApiConfig.authHeaders(token));
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200 && body['success'] == true) {
      return DerivativeKindResponse.fromJson(
          body['data'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to load derivative-kind breakdown');
  }

  // ── Multiplier contributions (§XI.A bonuses + §XI.B clamps) ─────

  Future<MultiplierContributionResponse> getByMultiplier({
    required int userId,
    required String token,
    String period = 'month',
    String? postType,
  }) async {
    final params = <String, String>{
      'user_id': '$userId',
      'period': period,
      if (postType != null) 'post_type': postType,
    };
    final uri = Uri.parse('$_base/users/me/earnings/by-multiplier')
        .replace(queryParameters: params);
    final resp = await http.get(uri, headers: ApiConfig.authHeaders(token));
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200 && body['success'] == true) {
      return MultiplierContributionResponse.fromJson(
          body['data'] as Map<String, dynamic>);
    }
    throw Exception(
        body['message'] ?? 'Failed to load multiplier contributions');
  }

  // ── Downstream creators (strategy §6) ────────────────────────────

  Future<List<DownstreamCreator>> getDownstreamCreators({
    required int userId,
    required String token,
    String period = 'month',
    int limit = 10,
  }) async {
    final params = <String, String>{
      'user_id': '$userId',
      'period': period,
      'limit': '$limit',
    };
    final uri = Uri.parse('$_base/users/me/downstream-creators')
        .replace(queryParameters: params);
    final resp = await http.get(uri, headers: ApiConfig.authHeaders(token));
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200 && body['success'] == true) {
      final data = body['data'] as Map<String, dynamic>;
      final rows = (data['rows'] as List<dynamic>?) ?? const [];
      return rows
          .map((e) => DownstreamCreator.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['message'] ?? 'Failed to load downstream creators');
  }

  // ── Per-post earnings list (Creator → Posts page) ────────────────

  Future<PostEarningsListResponse> getMyPostsEarnings({
    required int userId,
    required String token,
    String period = 'month',
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, String>{
      'user_id': '$userId',
      'period': period,
      'page': '$page',
      'per_page': '$perPage',
    };
    final uri = Uri.parse('$_base/users/me/posts/earnings')
        .replace(queryParameters: params);
    final resp = await http.get(uri, headers: ApiConfig.authHeaders(token));
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200 && body['success'] == true) {
      return PostEarningsListResponse.fromJson(body);
    }
    throw Exception(body['message'] ?? 'Failed to load posts earnings');
  }

  // ── Per-metric breakdown (B+C table for category pages) ───────────

  Future<MetricBreakdownResponse> getByMetric({
    required int userId,
    required String token,
    String period = 'month',
    String? stream,
    String? postType,
  }) async {
    final params = <String, String>{
      'user_id': '$userId',
      'period': period,
      if (stream != null) 'stream': stream,
      if (postType != null) 'post_type': postType,
    };
    final uri = Uri.parse('$_base/users/me/earnings/by-metric')
        .replace(queryParameters: params);
    final resp = await http.get(uri, headers: ApiConfig.authHeaders(token));
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200 && body['success'] == true) {
      return MetricBreakdownResponse.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to load metric breakdown');
  }

  // ── Tax (YTD WHT) ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTaxSummary({
    required int userId,
    required String token,
    int? year,
  }) async {
    final params = <String, String>{
      'user_id': '$userId',
      if (year != null) 'year': '$year',
    };
    final uri = Uri.parse('$_base/users/me/earnings/tax').replace(queryParameters: params);
    final resp = await http.get(uri, headers: ApiConfig.authHeaders(token));
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200 && body['success'] == true) {
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception(body['message'] ?? 'Failed to load tax summary');
  }
}
