import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../models/listing_inquiry.dart';

String get _baseUrl => ApiConfig.baseUrl;

void _log(String m) => debugPrint('[ListingInquiryService] $m');

String _snippet(String body, [int max = 300]) {
  final t = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.length <= max ? t : '${t.substring(0, max)}…';
}

class ListingInquiryService {
  static Future<ListingInquiryResult> create({
    required int listingId,
    required int customerUserId,
    required InquiryKind kind,
    String? message,
    DateTime? preferredViewingAt,
    int? offerPriceTzs,
    int? parentInquiryId,
    String? prequalMoveIn,
    String? prequalFinancing,
    bool? prequalWorkingWithAgent,
  }) async {
    final url = '$_baseUrl/listing-inquiries';
    final body = <String, dynamic>{
      'listing_id': listingId,
      'customer_user_id': customerUserId,
      'kind': kind.apiValue,
    };
    if (message != null && message.isNotEmpty) body['message'] = message;
    if (preferredViewingAt != null) body['preferred_viewing_at'] = preferredViewingAt.toUtc().toIso8601String();
    if (offerPriceTzs != null) body['offer_price_tzs'] = offerPriceTzs;
    if (parentInquiryId != null) body['parent_inquiry_id'] = parentInquiryId;
    if (prequalMoveIn != null) body['prequal_move_in'] = prequalMoveIn;
    if (prequalFinancing != null) body['prequal_financing'] = prequalFinancing;
    if (prequalWorkingWithAgent != null) {
      body['prequal_working_with_agent'] = prequalWorkingWithAgent;
    }
    if (prequalMoveIn != null || prequalFinancing != null || prequalWorkingWithAgent != null) {
      body['prequal_completed_at'] = DateTime.now().toUtc().toIso8601String();
    }
    _log('POST $url body=${jsonEncode(body)}');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _log('create status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, s) {
      _log('create error: $e\n$s');
      return ListingInquiryResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<ListingInquiryListResult> list({
    required int userId,
    required String role,
    int? listingId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'user_id': '$userId',
      'role': role,
      'limit': '$limit',
      'offset': '$offset',
    };
    if (listingId != null) params['listing_id'] = '$listingId';
    if (status != null && status.isNotEmpty) params['status'] = status;
    final uri = Uri.parse('$_baseUrl/listing-inquiries').replace(queryParameters: params);
    _log('GET $uri');
    try {
      final res = await http.get(uri);
      _log('list status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final items = (body['data'] as List)
            .whereType<Map>()
            .map((m) => ListingInquiry.fromJson(m.cast<String, dynamic>()))
            .toList();
        return ListingInquiryListResult(success: true, items: items);
      }
      return ListingInquiryListResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e, s) {
      _log('list error: $e\n$s');
      return ListingInquiryListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<ListingInquiryResult> get({required int id, required int userId}) async {
    final uri = Uri.parse('$_baseUrl/listing-inquiries/$id')
        .replace(queryParameters: {'user_id': '$userId'});
    _log('GET $uri');
    try {
      final res = await http.get(uri);
      return _decodeOne(res);
    } catch (e, s) {
      _log('get error: $e\n$s');
      return ListingInquiryResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<ListingInquiryResult> acknowledge({required int id, required int userId}) =>
      _action(id, 'acknowledge', {'user_id': userId});

  static Future<ListingInquiryResult> schedule({
    required int id,
    required int userId,
    required DateTime scheduledAt,
  }) =>
      _action(id, 'schedule', {'user_id': userId, 'scheduled_at': scheduledAt.toUtc().toIso8601String()});

  static Future<ListingInquiryResult> markViewed({required int id, required int userId}) =>
      _action(id, 'mark-viewed', {'user_id': userId});

  static Future<ListingInquiryResult> acceptOffer({required int id, required int userId}) =>
      _action(id, 'accept-offer', {'user_id': userId});

  static Future<ListingInquiryResult> rejectOffer({
    required int id,
    required int userId,
    String? reason,
  }) {
    final body = <String, dynamic>{'user_id': userId};
    if (reason != null && reason.trim().isNotEmpty) body['reason'] = reason.trim();
    return _action(id, 'reject-offer', body);
  }

  static Future<ListingInquiryResult> cancel({
    required int id,
    required int userId,
    String? reason,
  }) {
    final body = <String, dynamic>{'user_id': userId};
    if (reason != null && reason.trim().isNotEmpty) body['reason'] = reason.trim();
    return _action(id, 'cancel', body);
  }

  static Future<ListingInquiryResult> _action(
    int id,
    String action,
    Map<String, dynamic> body,
  ) async {
    final url = '$_baseUrl/listing-inquiries/$id/$action';
    _log('POST $url body=${jsonEncode(body)}');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _log('$action status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, s) {
      _log('$action error: $e\n$s');
      return ListingInquiryResult(success: false, message: 'Kosa: $e');
    }
  }

  static ListingInquiryResult _decodeOne(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
        return ListingInquiryResult(
          success: true,
          inquiry: ListingInquiry.fromJson((body['data'] as Map).cast<String, dynamic>()),
          statusCode: res.statusCode,
        );
      }
      return ListingInquiryResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e) {
      return ListingInquiryResult(success: false, message: 'Decode error: $e', statusCode: res.statusCode);
    }
  }
}
