// lib/faith/services/faith_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/faith_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class FaithService {
  // ─── Faith Preference ──────────────────────────────────────────

  Future<FaithResult<FaithPreference>> getPreference(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/faith/preference/$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return FaithResult(
            success: true,
            data: FaithPreference.fromJson(data['data']),
          );
        }
      }
      return FaithResult(success: false, message: 'Imeshindwa kupakia mapendeleo');
    } catch (e) {
      return FaithResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FaithResult<FaithPreference>> setPreference({
    required int userId,
    required FaithType faith,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/faith/preference'),
        headers: ApiConfig.headers,
        body: jsonEncode({'user_id': userId, 'faith': faith.name}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return FaithResult(
            success: true,
            data: FaithPreference.fromJson(data['data']),
          );
        }
      }
      return FaithResult(success: false, message: 'Imeshindwa kuhifadhi');
    } catch (e) {
      return FaithResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Daily Inspiration ─────────────────────────────────────────

  Future<FaithResult<DailyInspiration>> getDailyInspiration({
    required FaithType faith,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/faith/inspiration?faith=${faith.name}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return FaithResult(
            success: true,
            data: DailyInspiration.fromJson(data['data']),
          );
        }
      }
      return FaithResult(success: false, message: 'Imeshindwa kupakia msukumo');
    } catch (e) {
      return FaithResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Prayer Times ──────────────────────────────────────────────

  Future<FaithResult<PrayerTimes>> getPrayerTimes({
    required double latitude,
    required double longitude,
    String? date,
  }) async {
    try {
      final params = <String, String>{
        'latitude': '$latitude',
        'longitude': '$longitude',
      };
      if (date != null) params['date'] = date;

      final uri = Uri.parse('$_baseUrl/faith/prayer-times')
          .replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return FaithResult(
            success: true,
            data: PrayerTimes.fromJson(data['data']),
          );
        }
      }
      return FaithResult(success: false, message: 'Imeshindwa kupakia nyakati za sala');
    } catch (e) {
      return FaithResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Places of Worship ─────────────────────────────────────────

  Future<FaithListResult<PlaceOfWorship>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    WorshipPlaceType? type,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, String>{
        'latitude': '$latitude',
        'longitude': '$longitude',
        'page': '$page',
        'per_page': '$perPage',
      };
      if (type != null) params['type'] = type.name;

      final uri = Uri.parse('$_baseUrl/faith/places')
          .replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => PlaceOfWorship.fromJson(j))
              .toList();
          return FaithListResult(success: true, items: items);
        }
      }
      return FaithListResult(
        success: false,
        message: 'Imeshindwa kupakia maeneo',
      );
    } catch (e) {
      return FaithListResult(success: false, message: 'Kosa: $e');
    }
  }
}
