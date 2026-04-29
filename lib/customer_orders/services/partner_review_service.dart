import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../models/customer_order.dart';
import '../models/partner_review.dart';

String get _baseUrl => ApiConfig.baseUrl;

void _log(String m) => debugPrint('[PartnerReviewService] $m');

String _snippet(String body, [int max = 300]) {
  final t = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.length <= max ? t : '${t.substring(0, max)}…';
}

class PartnerReviewService {
  static Future<PartnerReviewResult> rate({
    required CustomerOrderSource source,
    required int sourceId,
    required int reviewerUserId,
    required int stars,
    String? comment,
    List<String>? tags,
    bool isAnonymous = false,
    Map<String, int>? dimensions,
    List<String>? mediaUrls,
  }) async {
    final url = '$_baseUrl/partner-reviews';
    final body = <String, dynamic>{
      'source': source.apiValue,
      'source_id': sourceId,
      'reviewer_user_id': reviewerUserId,
      'stars': stars,
      'is_anonymous': isAnonymous,
    };
    if (comment != null && comment.isNotEmpty) body['comment'] = comment;
    if (tags != null && tags.isNotEmpty) body['tags'] = tags;
    if (dimensions != null && dimensions.isNotEmpty) body['dimensions'] = dimensions;
    if (mediaUrls != null && mediaUrls.isNotEmpty) body['media_urls'] = mediaUrls;
    _log('POST $url body=${jsonEncode(body)}');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _log('rate status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, s) {
      _log('rate error: $e\n$s');
      return PartnerReviewResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerReviewResult> edit({
    required int id,
    required int reviewerUserId,
    int? stars,
    String? comment,
    List<String>? tags,
    bool? isAnonymous,
    Map<String, int>? dimensions,
    List<String>? mediaUrls,
  }) async {
    final url = '$_baseUrl/partner-reviews/$id';
    final body = <String, dynamic>{'reviewer_user_id': reviewerUserId};
    if (stars != null) body['stars'] = stars;
    if (comment != null) body['comment'] = comment;
    if (tags != null) body['tags'] = tags;
    if (isAnonymous != null) body['is_anonymous'] = isAnonymous;
    if (dimensions != null) body['dimensions'] = dimensions;
    if (mediaUrls != null) body['media_urls'] = mediaUrls;
    _log('PATCH $url body=${jsonEncode(body)}');
    try {
      final res = await http.patch(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return _decodeOne(res);
    } catch (e, s) {
      _log('edit error: $e\n$s');
      return PartnerReviewResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Spec line 1108 — community helpfulness vote on a review.
  /// `value` must be -1 (not helpful) or 1 (helpful). Re-voting is idempotent;
  /// switching value flips the aggregate.
  static Future<PartnerReviewResult> vote({
    required int reviewId,
    required int voterUserId,
    required int value,
  }) async {
    assert(value == 1 || value == -1, 'value must be 1 or -1');
    final url = '$_baseUrl/partner-reviews/$reviewId/helpful';
    _log('POST $url value=$value');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': voterUserId, 'value': value}),
      );
      return _decodeOne(res);
    } catch (e, s) {
      _log('vote error: $e\n$s');
      return PartnerReviewResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerReviewResult> reply({
    required int id,
    required int partnerUserId,
    required String reply,
  }) async {
    final url = '$_baseUrl/partner-reviews/$id/reply';
    _log('POST $url');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'partner_user_id': partnerUserId, 'reply': reply}),
      );
      return _decodeOne(res);
    } catch (e, s) {
      _log('reply error: $e\n$s');
      return PartnerReviewResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerReviewListResult> listForPartner({
    required int partnerUserId,
    String? filterSource,
    int? minStars,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'partner_user_id': '$partnerUserId',
      'limit': '$limit',
      'offset': '$offset',
    };
    if (filterSource != null && filterSource.isNotEmpty) {
      params['filter_source'] = filterSource;
    }
    if (minStars != null) params['min_stars'] = '$minStars';
    final uri = Uri.parse('$_baseUrl/partner-reviews').replace(queryParameters: params);
    _log('GET $uri');
    try {
      final res = await http.get(uri);
      _log('list status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final agg = (body['aggregate'] as Map?)?.cast<String, dynamic>();
        return PartnerReviewListResult(
          success: true,
          items: (body['data'] as List)
              .whereType<Map>()
              .map((m) => PartnerReview.fromJson(m.cast<String, dynamic>()))
              .toList(),
          aggregate: agg != null
              ? PartnerReviewAggregate.fromJson(agg)
              : PartnerReviewAggregate.empty(),
        );
      }
      return PartnerReviewListResult(
        success: false,
        aggregate: PartnerReviewAggregate.empty(),
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e, s) {
      _log('list error: $e\n$s');
      return PartnerReviewListResult(
        success: false,
        aggregate: PartnerReviewAggregate.empty(),
        message: 'Kosa: $e',
      );
    }
  }

  /// Returns the existing review for this (source, source_id, reviewer) or null.
  /// Used to check "did I already rate this?" before opening RatePartnerPage.
  static Future<PartnerReview?> findExisting({
    required CustomerOrderSource source,
    required int sourceId,
    required int reviewerUserId,
  }) async {
    final params = <String, String>{
      'source': source.apiValue,
      'source_id': '$sourceId',
      'reviewer_user_id': '$reviewerUserId',
    };
    final uri = Uri.parse('$_baseUrl/partner-reviews').replace(queryParameters: params);
    _log('GET $uri');
    try {
      final res = await http.get(uri);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final list = body['data'] as List;
        if (list.isEmpty) return null;
        return PartnerReview.fromJson((list.first as Map).cast<String, dynamic>());
      }
    } catch (e, s) {
      _log('findExisting error: $e\n$s');
    }
    return null;
  }

  static PartnerReviewResult _decodeOne(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
        return PartnerReviewResult(
          success: true,
          review: PartnerReview.fromJson((body['data'] as Map).cast<String, dynamic>()),
          statusCode: res.statusCode,
        );
      }
      return PartnerReviewResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e) {
      return PartnerReviewResult(success: false, message: 'Decode error: $e', statusCode: res.statusCode);
    }
  }
}
