import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../services/http_retry.dart';
import '../../config/api_config.dart';
import '../models/garage_booking.dart';

String get _baseUrl => ApiConfig.baseUrl;

void _log(String message) {
  debugPrint('[GarageBookingService] $message');
}

String _snippet(String body, [int max = 300]) {
  final trimmed = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  return trimmed.length <= max ? trimmed : '${trimmed.substring(0, max)}…';
}

class GarageBookingService {
  static Future<GarageBookingPhotoUploadResult> uploadPhoto({
    required int userId,
    required File file,
  }) async {
    final url = '$_baseUrl/garage-bookings/photo';
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
        return GarageBookingPhotoUploadResult(success: true, photoUrl: photoUrl);
      }
      return GarageBookingPhotoUploadResult(
        success: false,
        message: body['message']?.toString() ?? 'Upload failed',
      );
    } catch (e, stack) {
      _log('uploadPhoto error: $e\n$stack');
      return GarageBookingPhotoUploadResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<GarageBookingResult> create({
    required int userId,
    required int targetPartnerUserId,
    required AutoSkill skill,
    required String vehicleMake,
    required String vehicleModel,
    required String vehiclePlate,
    int? vehicleYear,
    required String faultSummary,
    required DateTime dropOffAt,
    int? costCapTzs,
    List<String> photos = const [],
    String? dropOffMode,
    List<String> obd2Photos = const [],
  }) async {
    final url = '$_baseUrl/garage-bookings';
    _log('POST $url skill=${skill.apiValue} plate=$vehiclePlate');
    try {
      final body = <String, dynamic>{
        'user_id': userId,
        'target_partner_user_id': targetPartnerUserId,
        'skill_category': skill.apiValue,
        'vehicle_make': vehicleMake,
        'vehicle_model': vehicleModel,
        'vehicle_plate': vehiclePlate.toUpperCase(),
        'fault_summary': faultSummary,
        'drop_off_at': dropOffAt.toUtc().toIso8601String(),
        'photos': photos,
      };
      if (vehicleYear != null) body['vehicle_year'] = vehicleYear;
      if (costCapTzs != null) body['cost_cap_tzs'] = costCapTzs;
      if (dropOffMode != null) body['drop_off_mode'] = dropOffMode;
      if (obd2Photos.isNotEmpty) body['obd2_photos'] = obd2Photos;
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _log('create status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, stack) {
      _log('create error: $e\n$stack');
      return GarageBookingResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<GarageBookingListResult> list({
    required int userId,
    required String role,
    String? status,
    String? skillCategory,
    String? vehiclePlate,
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
    if (skillCategory != null && skillCategory.isNotEmpty) {
      params['skill_category'] = skillCategory;
    }
    if (vehiclePlate != null && vehiclePlate.isNotEmpty) {
      params['vehicle_plate'] = vehiclePlate;
    }
    final uri = Uri.parse('$_baseUrl/garage-bookings').replace(queryParameters: params);
    _log('GET $uri');
    try {
      final res = await httpGetWithRetry(uri);
      _log('list status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final items = (body['data'] as List)
            .whereType<Map>()
            .map((m) => GarageBooking.fromJson(m.cast<String, dynamic>()))
            .toList();
        return GarageBookingListResult(success: true, bookings: items);
      }
      return GarageBookingListResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e, stack) {
      _log('list error: $e\n$stack');
      return GarageBookingListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<GarageBookingResult> get({
    required int id,
    required int userId,
  }) async {
    final uri = Uri.parse('$_baseUrl/garage-bookings/$id')
        .replace(queryParameters: {'user_id': '$userId'});
    _log('GET $uri');
    try {
      final res = await httpGetWithRetry(uri);
      _log('get status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, stack) {
      _log('get error: $e\n$stack');
      return GarageBookingResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<GarageBookingResult> accept({required int id, required int userId}) =>
      _postAction(id, 'accept', {'user_id': userId});

  static Future<GarageBookingResult> reject({
    required int id,
    required int userId,
    String? reason,
  }) {
    final body = <String, dynamic>{'user_id': userId};
    if (reason != null && reason.trim().isNotEmpty) body['reason'] = reason.trim();
    return _postAction(id, 'reject', body);
  }

  static Future<GarageBookingResult> droppedOff({required int id, required int userId}) =>
      _postAction(id, 'dropped_off', {'user_id': userId});

  static Future<GarageBookingResult> diagnose({
    required int id,
    required int userId,
    required String diagnosis,
    required int revisedCostTzs,
  }) =>
      _postAction(id, 'diagnose', {
        'user_id': userId,
        'diagnosis': diagnosis,
        'revised_cost_tzs': revisedCostTzs,
      });

  static Future<GarageBookingResult> approve({required int id, required int userId}) =>
      _postAction(id, 'approve', {'user_id': userId});

  static Future<GarageBookingResult> decline({
    required int id,
    required int userId,
    String? reason,
  }) {
    final body = <String, dynamic>{'user_id': userId};
    if (reason != null && reason.trim().isNotEmpty) body['reason'] = reason.trim();
    return _postAction(id, 'decline', body);
  }

  static Future<GarageBookingResult> startWork({required int id, required int userId}) =>
      _postAction(id, 'start_work', {'user_id': userId});

  static Future<GarageBookingResult> readyForPickup({
    required int id,
    required int userId,
    required int finalCostTzs,
  }) =>
      _postAction(id, 'ready_for_pickup', {
        'user_id': userId,
        'final_cost_tzs': finalCostTzs,
      });

  static Future<GarageBookingResult> complete({required int id, required int userId}) =>
      _postAction(id, 'complete', {'user_id': userId});

  static Future<GarageBookingResult> cancel({
    required int id,
    required int userId,
    String? reason,
  }) {
    final body = <String, dynamic>{'user_id': userId};
    if (reason != null && reason.trim().isNotEmpty) body['reason'] = reason.trim();
    return _postAction(id, 'cancel', body);
  }

  static Future<String?> interpretObd2Photo({
    required String photoUrl,
    required bool isSwahili,
  }) async {
    final prompt = isSwahili
        ? 'Tafsiri picha hii ya dashboard ya gari. Andika kila taa ya onyo inayoonekana na fumbo lake kwa Kiswahili na Kiingereza. Format: "Swahili / English".'
        : 'Interpret this car dashboard photo. List every warning light visible and its likely meaning in English and Swahili. Format: "English / Swahili".';
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/ai/ask'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': '$prompt\nImage URL: $photoUrl',
          'response_type': 'json',
        }),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final answer = body['data']?['answer']?.toString();
        return answer;
      }
      _log('interpretObd2Photo non-200: \${res.statusCode} \${res.body}');
    } catch (e) {
      _log('interpretObd2Photo error: \$e');
    }
    return null;
  }

  static Future<GarageBookingResult> _postAction(
    int id,
    String action,
    Map<String, dynamic> body,
  ) async {
    final url = '$_baseUrl/garage-bookings/$id/$action';
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
      return GarageBookingResult(success: false, message: 'Kosa: $e');
    }
  }

  static GarageBookingResult _decodeOne(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      final ok = res.statusCode >= 200 && res.statusCode < 300;
      if (ok && body['success'] == true) {
        return GarageBookingResult(
          success: true,
          booking: GarageBooking.fromJson((body['data'] as Map).cast<String, dynamic>()),
          statusCode: res.statusCode,
        );
      }
      return GarageBookingResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e) {
      return GarageBookingResult(
        success: false,
        message: 'Decode error: $e',
        statusCode: res.statusCode,
      );
    }
  }
}
