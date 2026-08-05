import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../services/http_retry.dart';
import '../../config/api_config.dart';
import '../models/service_request.dart';

String get _baseUrl => ApiConfig.baseUrl;

void _log(String message) {
  debugPrint('[ServiceRequestService] $message');
}

String _snippet(String body, [int max = 300]) {
  final trimmed = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  return trimmed.length <= max ? trimmed : '${trimmed.substring(0, max)}…';
}

class ServiceRequestService {
  static Future<ServiceRequestPhotoUploadResult> uploadPhoto({
    required int userId,
    required File file,
  }) async {
    final url = '$_baseUrl/service-requests/photo';
    _log('UPLOAD $url userId=$userId path=${file.path}');
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['user_id'] = '$userId';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      _log('uploadPhoto status=${response.statusCode} body=${_snippet(response.body)}');
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final photoUrl = (body['data']?['url'] as String?) ?? '';
        return ServiceRequestPhotoUploadResult(success: true, photoUrl: photoUrl);
      }
      return ServiceRequestPhotoUploadResult(
        success: false,
        message: body['message']?.toString() ?? 'Upload failed',
      );
    } catch (e, stack) {
      _log('uploadPhoto error: $e\n$stack');
      return ServiceRequestPhotoUploadResult(success: false, message: 'Kosa: $e');
    }
  }

  /// UN-015: when [originPostId] is set, the backend can fire
  /// local_business_conversion·author on request acceptance / completion.
  static Future<ServiceRequestResult> create({
    required int userId,
    required String skillCategory,
    required String problemSummary,
    required String address,
    required ServiceRequestWindow preferredWindow,
    int? targetPartnerUserId,
    int? targetPartnerId,
    List<String> photos = const [],
    double? lat,
    double? lng,
    int? originPostId,
  }) async {
    final url = '$_baseUrl/service-requests';
    _log('POST $url skill=$skillCategory userId=$userId');
    try {
      final body = <String, dynamic>{
        'user_id': userId,
        'skill_category': skillCategory,
        'problem_summary': problemSummary,
        'address': address,
        'preferred_window': preferredWindow.apiValue,
        'photos': photos,
      };
      if (targetPartnerUserId != null) {
        body['target_partner_user_id'] = targetPartnerUserId;
      }
      if (targetPartnerId != null) {
        body['target_partner_id'] = targetPartnerId;
      }
      if (lat != null) body['lat'] = lat;
      if (lng != null) body['lng'] = lng;
      if (originPostId != null) body['origin_post_id'] = originPostId;
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _log('create status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, stack) {
      _log('create error: $e\n$stack');
      return ServiceRequestResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<ServiceRequestListResult> list({
    required int userId,
    required String role,
    String? skillCategory,
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
    if (skillCategory != null && skillCategory.isNotEmpty) {
      params['skill_category'] = skillCategory;
    }
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }
    final uri = Uri.parse('$_baseUrl/service-requests').replace(queryParameters: params);
    _log('GET $uri');
    try {
      final res = await httpGetWithRetry(uri);
      _log('list status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final items = (body['data'] as List)
            .whereType<Map>()
            .map((m) => ServiceRequest.fromJson(m.cast<String, dynamic>()))
            .toList();
        return ServiceRequestListResult(success: true, requests: items);
      }
      return ServiceRequestListResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e, stack) {
      _log('list error: $e\n$stack');
      return ServiceRequestListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<ServiceRequestResult> get({
    required int id,
    required int userId,
  }) async {
    final uri = Uri.parse('$_baseUrl/service-requests/$id')
        .replace(queryParameters: {'user_id': '$userId'});
    _log('GET $uri');
    try {
      final res = await httpGetWithRetry(uri);
      _log('get status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, stack) {
      _log('get error: $e\n$stack');
      return ServiceRequestResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<ServiceRequestResult> quote({
    required int id,
    required int userId,
    required int calloutFeeTzs,
    int? estimatedCostTzs,
    required QuoteEta eta,
    String? notes,
  }) async {
    final url = '$_baseUrl/service-requests/$id/quote';
    _log('POST $url userId=$userId callout=$calloutFeeTzs eta=${eta.apiValue}');
    try {
      final body = <String, dynamic>{
        'user_id': userId,
        'callout_fee_tzs': calloutFeeTzs,
        'eta': eta.apiValue,
      };
      if (estimatedCostTzs != null) body['estimated_cost_tzs'] = estimatedCostTzs;
      if (notes != null && notes.trim().isNotEmpty) body['notes'] = notes.trim();
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _log('quote status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, stack) {
      _log('quote error: $e\n$stack');
      return ServiceRequestResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<ServiceRequestResult> accept({
    required int id,
    required int userId,
    required int quoteId,
  }) {
    return _postAction(id, 'accept', {'user_id': userId, 'quote_id': quoteId});
  }

  static Future<ServiceRequestResult> enRoute({
    required int id,
    required int userId,
  }) {
    return _postAction(id, 'en_route', {'user_id': userId});
  }

  static Future<ServiceRequestResult> onSite({
    required int id,
    required int userId,
  }) {
    return _postAction(id, 'on_site', {'user_id': userId});
  }

  static Future<ServiceRequestResult> complete({
    required int id,
    required int userId,
  }) {
    return _postAction(id, 'complete', {'user_id': userId});
  }

  static Future<ServiceRequestResult> cancel({
    required int id,
    required int userId,
    String? reason,
  }) {
    final body = <String, dynamic>{'user_id': userId};
    if (reason != null && reason.trim().isNotEmpty) body['reason'] = reason.trim();
    return _postAction(id, 'cancel', body);
  }

  static Future<ServiceRequestResult> updateParts({
    required int id,
    required int userId,
    required List<Map<String, dynamic>> partsLineItems,
    int? partsMarkupPct,
  }) async {
    final url = '$_baseUrl/service-requests/$id/parts';
    _log('PATCH $url userId=$userId items=${partsLineItems.length}');
    try {
      final body = <String, dynamic>{
        'user_id': userId,
        'parts_line_items': partsLineItems,
      };
      if (partsMarkupPct != null) body['parts_markup_pct'] = partsMarkupPct;
      final res = await http.patch(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _log('updateParts status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, stack) {
      _log('updateParts error: $e\n$stack');
      return ServiceRequestResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<ServiceRequestResult> createSurvey({
    required int id,
    required int userId,
    required int siteSurveyFeeTzs,
  }) async {
    final url = '$_baseUrl/service-requests/$id/survey';
    _log('POST $url userId=$userId fee=$siteSurveyFeeTzs');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'site_survey_fee_tzs': siteSurveyFeeTzs,
        }),
      );
      _log('createSurvey status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, stack) {
      _log('createSurvey error: $e\n$stack');
      return ServiceRequestResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<ServiceRequestResult> _postAction(
    int id,
    String action,
    Map<String, dynamic> body,
  ) async {
    final url = '$_baseUrl/service-requests/$id/$action';
    _log('POST $url body=${jsonEncode(body)}');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _log('$action status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, stack) {
      _log('$action error: $e\n$stack');
      return ServiceRequestResult(success: false, message: 'Kosa: $e');
    }
  }

  static ServiceRequestResult _decodeOne(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        return ServiceRequestResult(
          success: true,
          request: ServiceRequest.fromJson(
            (body['data'] as Map).cast<String, dynamic>(),
          ),
          statusCode: res.statusCode,
        );
      }
      return ServiceRequestResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e) {
      return ServiceRequestResult(
        success: false,
        message: 'Decode error: $e',
        statusCode: res.statusCode,
      );
    }
  }
}
