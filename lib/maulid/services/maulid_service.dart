// lib/maulid/services/maulid_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/maulid_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class MaulidService {
  // ─── Get Events ─────────────────────────────────────────────
  Future<PaginatedResult<MaulidEvent>> getEvents({
    int page = 1,
    String? location,
  }) async {
    try {
      final params = <String, String>{'page': '$page'};
      if (location != null) params['location'] = location;

      final uri = Uri.parse('$_baseUrl/maulid/events')
          .replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => MaulidEvent.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(
            success: true, items: items,
            currentPage: _parseInt(data['meta']?['current_page']),
            lastPage: _parseInt(data['meta']?['last_page']),
            total: _parseInt(data['meta']?['total']),
          );
        }
      }
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Get Qaswida Recordings ─────────────────────────────────
  Future<PaginatedResult<QaswidaRecording>> getRecordings({
    int page = 1,
    int? groupId,
  }) async {
    try {
      final params = <String, String>{'page': '$page'};
      if (groupId != null) params['group_id'] = '$groupId';

      final uri = Uri.parse('$_baseUrl/maulid/qaswida')
          .replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => QaswidaRecording.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(success: true, items: items, total: items.length);
        }
      }
      return PaginatedResult(
          success: false, message: 'Imeshindwa kupakia qaswida');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Get Qaswida Groups ─────────────────────────────────────
  Future<PaginatedResult<QaswidaGroup>> getGroups() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/maulid/groups'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => QaswidaGroup.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(success: true, items: items, total: items.length);
        }
      }
      return PaginatedResult(
          success: false, message: 'Imeshindwa kupakia vikundi');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── RSVP Event ─────────────────────────────────────────────
  Future<SingleResult<bool>> rsvpEvent({
    required String token,
    required int eventId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/maulid/events/$eventId/rsvp'),
        headers: ApiConfig.authHeaders(token),
      );
      return SingleResult(
        success: response.statusCode == 200 || response.statusCode == 201,
        data: true,
      );
    } catch (e) {
      return SingleResult(success: false, message: 'Kosa: $e');
    }
  }
}

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
