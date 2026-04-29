import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

/// Spec §F — partner_c2b daily metrics rows. Backend rebuilds via
/// `app:rebuild-partner-c2b-metrics` (daily 02:30 EAT scheduler).
class PartnerC2BMetricsRow {
  final String date;
  final String role;
  final String sourceType;
  final int countNew;
  final int countActive;
  final int countCompleted;
  final int countCancelled;
  final int revenueTzs;
  final double? avgRating;
  final int reviewsCount;
  PartnerC2BMetricsRow({
    required this.date,
    required this.role,
    required this.sourceType,
    required this.countNew,
    required this.countActive,
    required this.countCompleted,
    required this.countCancelled,
    required this.revenueTzs,
    required this.avgRating,
    required this.reviewsCount,
  });
  factory PartnerC2BMetricsRow.fromJson(Map<String, dynamic> json) {
    int p(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    return PartnerC2BMetricsRow(
      date: json['date']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      sourceType: json['source_type']?.toString() ?? '',
      countNew: p(json['count_new']),
      countActive: p(json['count_active']),
      countCompleted: p(json['count_completed']),
      countCancelled: p(json['count_cancelled']),
      revenueTzs: p(json['revenue_tzs']),
      avgRating: json['avg_rating'] is num
          ? (json['avg_rating'] as num).toDouble()
          : null,
      reviewsCount: p(json['reviews_count']),
    );
  }
}

class PartnerC2BMetricsTotals {
  final int totalNew;
  final int totalActive;
  final int totalCompleted;
  final int totalCancelled;
  final int totalRevenueTzs;
  final double? avgRating;
  final int totalReviews;
  PartnerC2BMetricsTotals({
    required this.totalNew,
    required this.totalActive,
    required this.totalCompleted,
    required this.totalCancelled,
    required this.totalRevenueTzs,
    required this.avgRating,
    required this.totalReviews,
  });

  factory PartnerC2BMetricsTotals.from(List<PartnerC2BMetricsRow> rows) {
    int n = 0, a = 0, c = 0, x = 0, rev = 0, rc = 0;
    double ratingSum = 0;
    int ratingDays = 0;
    for (final r in rows) {
      n += r.countNew;
      a += r.countActive;
      c += r.countCompleted;
      x += r.countCancelled;
      rev += r.revenueTzs;
      rc += r.reviewsCount;
      if (r.avgRating != null && r.reviewsCount > 0) {
        ratingSum += r.avgRating! * r.reviewsCount;
        ratingDays += r.reviewsCount;
      }
    }
    return PartnerC2BMetricsTotals(
      totalNew: n,
      totalActive: a,
      totalCompleted: c,
      totalCancelled: x,
      totalRevenueTzs: rev,
      avgRating: ratingDays > 0 ? ratingSum / ratingDays : null,
      totalReviews: rc,
    );
  }
}

class PartnerC2BMetricsApi {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<List<PartnerC2BMetricsRow>> fetch({
    required int userId,
    String? role,
    String? sourceType,
    DateTime? from,
    DateTime? to,
  }) async {
    final params = <String, String>{'user_id': '$userId'};
    if (role != null) params['role'] = role;
    if (sourceType != null) params['source_type'] = sourceType;
    if (from != null) params['from'] = from.toIso8601String().split('T').first;
    if (to != null) params['to'] = to.toIso8601String().split('T').first;
    final uri = Uri.parse('$_baseUrl/partner-c2b/metrics').replace(queryParameters: params);
    debugPrint('[PartnerC2BMetricsApi] GET $uri');
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          return (body['data'] as List)
              .whereType<Map>()
              .map((m) => PartnerC2BMetricsRow.fromJson(m.cast<String, dynamic>()))
              .toList();
        }
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
