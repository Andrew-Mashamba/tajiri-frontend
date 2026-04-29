import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../models/consultation.dart';

String get _baseUrl => ApiConfig.baseUrl;

void _log(String message) {
  debugPrint('[ConsultationService] $message');
}

String _snippet(String body, [int max = 300]) {
  final trimmed = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  return trimmed.length <= max ? trimmed : '${trimmed.substring(0, max)}…';
}

class ConsultationService {
  static Future<ConsultationResult> create({
    required int userId,
    required int targetPartnerUserId,
    required ConsultationVertical vertical,
    required ConsultationMode mode,
    required int durationMin,
    required String serviceTitle,
    required int feeTzs,
    required String intakeSummary,
    required DateTime startsAt,
    String? skillCategory,
    int? targetPartnerId,
    List<ConsultationAttachment>? attachments,
    String? customerAddress,
    double? customerLat,
    double? customerLng,
  }) async {
    final url = '$_baseUrl/consultations';
    _log('POST $url vertical=${vertical.apiValue} mode=${mode.apiValue} duration=${durationMin}m');
    try {
      final body = <String, dynamic>{
        'customer_user_id': userId,
        'target_partner_user_id': targetPartnerUserId,
        'vertical': vertical.apiValue,
        'mode': mode.apiValue,
        'duration_min': durationMin,
        'service_title': serviceTitle,
        'fee_tzs': feeTzs,
        'intake_summary': intakeSummary,
        'nda_accepted': true,
        'starts_at': startsAt.toUtc().toIso8601String(),
      };
      if (skillCategory != null && skillCategory.isNotEmpty) {
        body['skill_category'] = skillCategory;
      }
      if (targetPartnerId != null) body['target_partner_id'] = targetPartnerId;
      if (attachments != null && attachments.isNotEmpty) {
        body['attachments'] = attachments.map((a) => a.toJson()).toList();
      }
      if (customerAddress != null && customerAddress.isNotEmpty) {
        body['customer_address'] = customerAddress;
      }
      if (customerLat != null) body['customer_lat'] = customerLat;
      if (customerLng != null) body['customer_lng'] = customerLng;

      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _log('create status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, stack) {
      _log('create error: $e\n$stack');
      return ConsultationResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<ConsultationListResult> list({
    required int userId,
    required String role,
    String? vertical,
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
    if (vertical != null && vertical.isNotEmpty) params['vertical'] = vertical;
    if (status != null && status.isNotEmpty) params['status'] = status;
    final uri = Uri.parse('$_baseUrl/consultations').replace(queryParameters: params);
    _log('GET $uri');
    try {
      final res = await http.get(uri);
      _log('list status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final items = (body['data'] as List)
            .whereType<Map>()
            .map((m) => Consultation.fromJson(m.cast<String, dynamic>()))
            .toList();
        return ConsultationListResult(success: true, items: items);
      }
      return ConsultationListResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e, stack) {
      _log('list error: $e\n$stack');
      return ConsultationListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<ConsultationResult> get({
    required int id,
    required int userId,
  }) async {
    final uri = Uri.parse('$_baseUrl/consultations/$id')
        .replace(queryParameters: {'user_id': '$userId'});
    _log('GET $uri');
    try {
      final res = await http.get(uri);
      _log('get status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, stack) {
      _log('get error: $e\n$stack');
      return ConsultationResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Spec line 670 — partner phone is gated until 15 min before starts_at
  /// (and stays revealed up to 2h after). Backend returns HTTP 423 with a
  /// `reveal_at` ISO8601 timestamp when called outside the window.
  static Future<RevealPhoneResult> revealPhone({
    required int id,
    required int userId,
  }) async {
    final uri = Uri.parse('$_baseUrl/consultations/$id/reveal_phone')
        .replace(queryParameters: {'user_id': '$userId'});
    _log('GET $uri');
    try {
      final res = await http.get(uri);
      _log('revealPhone status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map?;
        return RevealPhoneResult(
          success: true,
          phoneNumber: data?['phone_number']?.toString(),
          revealAt: DateTime.tryParse(data?['reveal_at']?.toString() ?? ''),
          closesAt: DateTime.tryParse(data?['closes_at']?.toString() ?? ''),
        );
      }
      if (res.statusCode == 423) {
        return RevealPhoneResult(
          success: false,
          locked: true,
          revealAt: DateTime.tryParse(body['reveal_at']?.toString() ?? ''),
          message: body['message']?.toString() ?? 'Locked',
        );
      }
      return RevealPhoneResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
      );
    } catch (e, s) {
      _log('revealPhone error: $e\n$s');
      return RevealPhoneResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<ConsultationResult> accept({required int id, required int userId}) =>
      _postAction(id, 'accept', {'user_id': userId});

  static Future<ConsultationResult> reject({
    required int id,
    required int userId,
    String? reason,
  }) {
    final body = <String, dynamic>{'user_id': userId};
    if (reason != null && reason.trim().isNotEmpty) body['reason'] = reason.trim();
    return _postAction(id, 'reject', body);
  }

  static Future<ConsultationResult> start({required int id, required int userId}) =>
      _postAction(id, 'start', {'user_id': userId});

  static Future<ConsultationResult> complete({required int id, required int userId}) =>
      _postAction(id, 'complete', {'user_id': userId});

  static Future<ConsultationResult> cancel({
    required int id,
    required int userId,
    String? reason,
  }) {
    final body = <String, dynamic>{'user_id': userId};
    if (reason != null && reason.trim().isNotEmpty) body['reason'] = reason.trim();
    return _postAction(id, 'cancel', body);
  }

  static Future<ConsultationResult> appendFollowUp({
    required int id,
    required int userId,
    required String notes,
  }) =>
      _postAction(id, 'follow_up_notes', {'user_id': userId, 'notes': notes});

  static Future<ConsultationResult> appendPrescription({
    required int id,
    required int userId,
    required String prescription,
  }) =>
      _postAction(id, 'prescription', {
        'user_id': userId,
        'prescription': prescription,
      });

  static Future<ConsultationAttachmentUploadResult> uploadAttachment({
    required int userId,
    required File file,
  }) async {
    final url = '$_baseUrl/consultations/attachment';
    _log('POST(multipart) $url userId=$userId path=${file.path}');
    try {
      final req = http.MultipartRequest('POST', Uri.parse(url));
      req.fields['user_id'] = '$userId';
      req.files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      _log('uploadAttachment status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        return ConsultationAttachmentUploadResult(
          success: true,
          attachment: ConsultationAttachment.fromJson(
            (body['data'] as Map).cast<String, dynamic>(),
          ),
          statusCode: res.statusCode,
        );
      }
      return ConsultationAttachmentUploadResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e, stack) {
      _log('uploadAttachment error: $e\n$stack');
      return ConsultationAttachmentUploadResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<ConsultationResult> submitPreVisitIntake({
    required int id,
    required int userId,
    required Map<String, dynamic> answers,
  }) async {
    final url = '$_baseUrl/consultations/$id/pre_visit_intake';
    _log('POST $url');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'answers': answers}),
      );
      _log('preVisitIntake status=${res.statusCode}');
      return _decodeOne(res);
    } catch (e, stack) {
      _log('preVisitIntake error: $e\n$stack');
      return ConsultationResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<ConsultationResult> submitDermIntakePhotos({
    required int id,
    required int userId,
    required List<Map<String, dynamic>> photos,
  }) async {
    final url = '$_baseUrl/consultations/$id/derm_intake_photos';
    _log('POST $url photos=${photos.length}');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'photos': photos}),
      );
      _log('dermIntakePhotos status=${res.statusCode}');
      return _decodeOne(res);
    } catch (e, stack) {
      _log('dermIntakePhotos error: $e\n$stack');
      return ConsultationResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<ConsultationResult> submitConnectivityTest({
    required int id,
    required int userId,
    required bool passed,
  }) async {
    final url = '$_baseUrl/consultations/$id/connectivity_test';
    _log('POST $url passed=$passed');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'passed': passed}),
      );
      _log('connectivityTest status=${res.statusCode}');
      return _decodeOne(res);
    } catch (e, stack) {
      _log('connectivityTest error: $e\n$stack');
      return ConsultationResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<ConsultationResult> submitConsentScreens({
    required int id,
    required int userId,
    required List<Map<String, dynamic>> screens,
  }) async {
    final url = '$_baseUrl/consultations/$id/consent_screens';
    _log('POST $url screens=${screens.length}');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'screens': screens}),
      );
      _log('consentScreens status=${res.statusCode}');
      return _decodeOne(res);
    } catch (e, stack) {
      _log('consentScreens error: $e\n$stack');
      return ConsultationResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<ConsultationResult> _postAction(
    int id,
    String action,
    Map<String, dynamic> body,
  ) async {
    final url = '$_baseUrl/consultations/$id/$action';
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
      return ConsultationResult(success: false, message: 'Kosa: $e');
    }
  }

  static ConsultationResult _decodeOne(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      final ok = res.statusCode >= 200 && res.statusCode < 300;
      if (ok && body['success'] == true) {
        return ConsultationResult(
          success: true,
          consultation: Consultation.fromJson(
            (body['data'] as Map).cast<String, dynamic>(),
          ),
          statusCode: res.statusCode,
        );
      }
      return ConsultationResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e) {
      return ConsultationResult(
        success: false,
        message: 'Decode error: $e',
        statusCode: res.statusCode,
      );
    }
  }
}
