import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../services/http_retry.dart';
import '../../config/api_config.dart';
import '../models/appointment.dart';

String get _baseUrl => ApiConfig.baseUrl;

void _log(String message) {
  debugPrint('[AppointmentService] $message');
}

String _snippet(String body, [int max = 300]) {
  final trimmed = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  return trimmed.length <= max ? trimmed : '${trimmed.substring(0, max)}…';
}

class AppointmentService {
  static Future<AppointmentResult> create({
    required int userId,
    required int targetPartnerUserId,
    required AppointmentVertical vertical,
    required String serviceTitle,
    required int servicePriceTzs,
    required int durationMin,
    required LocationKind locationKind,
    required DateTime startsAt,
    int? partnerProductId,
    String? skillCategory,
    String? customerAddress,
    double? customerLat,
    double? customerLng,
    String? notes,
    bool isRecurring = false,
    RecurringPattern? recurringPattern,
    bool anyProfessionalMode = false,
  }) async {
    final url = '$_baseUrl/appointments';
    _log('POST $url vertical=${vertical.apiValue} location=${locationKind.apiValue}');
    try {
      final body = <String, dynamic>{
        'customer_user_id': userId,
        'target_partner_user_id': targetPartnerUserId,
        'vertical': vertical.apiValue,
        'service_title': serviceTitle,
        'service_price_tzs': servicePriceTzs,
        'duration_min': durationMin,
        'location_kind': locationKind.apiValue,
        'starts_at': startsAt.toUtc().toIso8601String(),
      };
      if (partnerProductId != null) body['partner_product_id'] = partnerProductId;
      if (skillCategory != null && skillCategory.isNotEmpty) body['skill_category'] = skillCategory;
      if (customerAddress != null && customerAddress.isNotEmpty) body['customer_address'] = customerAddress;
      if (customerLat != null) body['customer_lat'] = customerLat;
      if (customerLng != null) body['customer_lng'] = customerLng;
      if (notes != null && notes.isNotEmpty) body['notes'] = notes;
      if (isRecurring) {
        body['is_recurring'] = true;
        if (recurringPattern != null) {
          body['recurring_pattern'] = recurringPattern.toJson();
        }
      }
      if (anyProfessionalMode) {
        body['any_professional_mode'] = true;
      }
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _log('create status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, stack) {
      _log('create error: $e\n$stack');
      return AppointmentResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<AppointmentListResult> list({
    required int userId,
    required String role,
    String? status,
    String? vertical,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'user_id': '$userId',
      'role': role,
      'limit': '$limit',
      'offset': '$offset',
    };
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (vertical != null && vertical.isNotEmpty) params['vertical'] = vertical;
    final uri = Uri.parse('$_baseUrl/appointments').replace(queryParameters: params);
    _log('GET $uri');
    try {
      final res = await httpGetWithRetry(uri);
      _log('list status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final items = (body['data'] as List)
            .whereType<Map>()
            .map((m) => Appointment.fromJson(m.cast<String, dynamic>()))
            .toList();
        return AppointmentListResult(success: true, appointments: items);
      }
      return AppointmentListResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e, stack) {
      _log('list error: $e\n$stack');
      return AppointmentListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<AppointmentResult> get({
    required int id,
    required int userId,
  }) async {
    final uri = Uri.parse('$_baseUrl/appointments/$id')
        .replace(queryParameters: {'user_id': '$userId'});
    _log('GET $uri');
    try {
      final res = await httpGetWithRetry(uri);
      _log('get status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, stack) {
      _log('get error: $e\n$stack');
      return AppointmentResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<AppointmentResult> accept({required int id, required int userId}) =>
      _postAction(id, 'accept', {'user_id': userId});

  static Future<AppointmentResult> reject({
    required int id,
    required int userId,
    String? reason,
  }) {
    final body = <String, dynamic>{'user_id': userId};
    if (reason != null && reason.trim().isNotEmpty) body['reason'] = reason.trim();
    return _postAction(id, 'reject', body);
  }

  static Future<AppointmentResult> checkIn({required int id, required int userId}) =>
      _postAction(id, 'check_in', {'user_id': userId});

  static Future<AppointmentResult> start({required int id, required int userId}) =>
      _postAction(id, 'start', {'user_id': userId});

  static Future<AppointmentResult> complete({required int id, required int userId}) =>
      _postAction(id, 'complete', {'user_id': userId});

  static Future<AppointmentResult> noShow({
    required int id,
    required int userId,
    int? feeTzs,
  }) {
    final body = <String, dynamic>{'user_id': userId};
    if (feeTzs != null) body['no_show_fee_tzs'] = feeTzs;
    return _postAction(id, 'no_show', body);
  }

  static Future<AppointmentResult> cancel({
    required int id,
    required int userId,
    String? reason,
  }) {
    final body = <String, dynamic>{'user_id': userId};
    if (reason != null && reason.trim().isNotEmpty) body['reason'] = reason.trim();
    return _postAction(id, 'cancel', body);
  }

  static Future<AppointmentResult> reschedule({
    required int id,
    required int userId,
    required DateTime startsAt,
  }) async {
    final url = '$_baseUrl/appointments/$id/reschedule';
    _log('PATCH $url userId=$userId startsAt=$startsAt');
    try {
      final res = await http.patch(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'starts_at': startsAt.toUtc().toIso8601String(),
        }),
      );
      _log('reschedule status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, stack) {
      _log('reschedule error: $e\n$stack');
      return AppointmentResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<AppointmentResult> _postAction(
    int id,
    String action,
    Map<String, dynamic> body,
  ) async {
    final url = '$_baseUrl/appointments/$id/$action';
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
      return AppointmentResult(success: false, message: 'Kosa: $e');
    }
  }

  static AppointmentResult _decodeOne(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      final ok = res.statusCode >= 200 && res.statusCode < 300;
      if (ok && body['success'] == true) {
        return AppointmentResult(
          success: true,
          appointment: Appointment.fromJson((body['data'] as Map).cast<String, dynamic>()),
          statusCode: res.statusCode,
        );
      }
      return AppointmentResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e) {
      return AppointmentResult(
        success: false,
        message: 'Decode error: $e',
        statusCode: res.statusCode,
      );
    }
  }
}
