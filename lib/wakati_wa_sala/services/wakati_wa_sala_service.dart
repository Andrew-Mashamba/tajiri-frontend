// lib/wakati_wa_sala/services/wakati_wa_sala_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/wakati_wa_sala_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class WakatiWaSalaService {
  // ─── Get Daily Prayer Schedule ──────────────────────────────
  Future<SingleResult<DailyPrayerSchedule>> getDailySchedule({
    required double latitude,
    required double longitude,
    String? date,
    CalculationMethod method = CalculationMethod.egyptian,
  }) async {
    try {
      final params = <String, String>{
        'latitude': '$latitude',
        'longitude': '$longitude',
        'method': method.name,
      };
      if (date != null) params['date'] = date;

      final uri = Uri.parse('$_baseUrl/prayer-times/daily')
          .replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return SingleResult(
            success: true,
            data: DailyPrayerSchedule.fromJson(data['data']),
          );
        }
      }
      return SingleResult(
        success: false,
        message: 'Imeshindwa kupakia nyakati za sala',
      );
    } catch (e) {
      return SingleResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Monthly Timetable ──────────────────────────────────────
  Future<PaginatedResult<DailyPrayerSchedule>> getMonthlySchedule({
    required double latitude,
    required double longitude,
    required int month,
    required int year,
  }) async {
    try {
      final params = <String, String>{
        'latitude': '$latitude',
        'longitude': '$longitude',
        'month': '$month',
        'year': '$year',
      };
      final uri = Uri.parse('$_baseUrl/prayer-times/monthly')
          .replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => DailyPrayerSchedule.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(success: true, items: items, total: items.length);
        }
      }
      return PaginatedResult(
        success: false,
        message: 'Imeshindwa kupakia ratiba ya mwezi',
      );
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Log Prayer ─────────────────────────────────────────────
  Future<SingleResult<PrayerLogEntry>> logPrayer({
    required String token,
    required PrayerLogEntry entry,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/prayer-times/log'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(entry.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return SingleResult(
            success: true,
            data: PrayerLogEntry.fromJson(data['data']),
          );
        }
      }
      return SingleResult(success: false, message: 'Imeshindwa kuhifadhi');
    } catch (e) {
      return SingleResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Get Prayer Stats ──────────────────────────────────────
  Future<SingleResult<PrayerStats>> getStats({
    required String token,
    String period = 'weekly',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/prayer-times/stats?period=$period'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return SingleResult(
            success: true,
            data: PrayerStats.fromJson(data['data']),
          );
        }
      }
      return SingleResult(success: false, message: 'Imeshindwa kupakia takwimu');
    } catch (e) {
      return SingleResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Get Prayer Log History ─────────────────────────────────
  Future<PaginatedResult<PrayerLogEntry>> getLogHistory({
    required String token,
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/prayer-times/logs?page=$page&per_page=$perPage'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => PrayerLogEntry.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(
            success: true,
            items: items,
            currentPage: _parseInt(data['meta']?['current_page']),
            lastPage: _parseInt(data['meta']?['last_page']),
            total: _parseInt(data['meta']?['total']),
          );
        }
      }
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia historia');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }
}

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
