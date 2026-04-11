// lib/kalenda_hijri/services/kalenda_hijri_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/kalenda_hijri_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class KalendaHijriService {
  // ─── Get Today's Hijri Date ─────────────────────────────────
  Future<SingleResult<HijriDate>> getTodayHijri() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/hijri/today'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return SingleResult(
            success: true,
            data: HijriDate.fromJson(data['data']),
          );
        }
      }
      return SingleResult(success: false, message: 'Imeshindwa kupakia tarehe');
    } catch (e) {
      return SingleResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Convert Dates ──────────────────────────────────────────
  Future<SingleResult<HijriDate>> convertToHijri(String gregorianDate) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/hijri/convert?date=$gregorianDate&to=hijri'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return SingleResult(
            success: true,
            data: HijriDate.fromJson(data['data']),
          );
        }
      }
      return SingleResult(success: false, message: 'Imeshindwa kubadilisha tarehe');
    } catch (e) {
      return SingleResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Get Islamic Events ─────────────────────────────────────
  Future<PaginatedResult<IslamicEvent>> getEvents({
    int? year,
    int page = 1,
  }) async {
    try {
      final params = <String, String>{'page': '$page'};
      if (year != null) params['year'] = '$year';

      final uri = Uri.parse('$_baseUrl/hijri/events')
          .replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => IslamicEvent.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(
            success: true,
            items: items,
            total: items.length,
          );
        }
      }
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia matukio');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Moon Sighting Reports ──────────────────────────────────
  Future<PaginatedResult<MoonSightingReport>> getMoonSightings({
    int page = 1,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/hijri/moon-sightings?page=$page'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => MoonSightingReport.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(success: true, items: items, total: items.length);
        }
      }
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia taarifa');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Submit Moon Sighting ───────────────────────────────────
  Future<SingleResult<MoonSightingReport>> submitSighting({
    required String token,
    required String location,
    required String hijriMonth,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/hijri/moon-sightings'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'location': location,
          'hijri_month': hijriMonth,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return SingleResult(
            success: true,
            data: MoonSightingReport.fromJson(data['data']),
          );
        }
      }
      return SingleResult(success: false, message: 'Imeshindwa kutuma taarifa');
    } catch (e) {
      return SingleResult(success: false, message: 'Kosa: $e');
    }
  }
}
