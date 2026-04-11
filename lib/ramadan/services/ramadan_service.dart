// lib/ramadan/services/ramadan_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/ramadan_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class RamadanService {
  // ─── Get Ramadan Overview ───────────────────────────────────
  Future<SingleResult<RamadanOverview>> getOverview({
    required String token,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ramadan/overview'
            '?latitude=$latitude&longitude=$longitude'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return SingleResult(
            success: true,
            data: RamadanOverview.fromJson(data['data']),
          );
        }
      }
      return SingleResult(success: false, message: 'Imeshindwa kupakia Ramadan');
    } catch (e) {
      return SingleResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Get Fasting Calendar ──────────────────────────────────
  Future<PaginatedResult<RamadanDay>> getFastingCalendar({
    required String token,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ramadan/calendar'
            '?latitude=$latitude&longitude=$longitude'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => RamadanDay.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(success: true, items: items, total: items.length);
        }
      }
      return PaginatedResult(
          success: false, message: 'Imeshindwa kupakia kalenda');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Log Fasting Day ────────────────────────────────────────
  Future<SingleResult<RamadanDay>> logFastingDay({
    required String token,
    required int dayNumber,
    required bool fasted,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ramadan/log-fast'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'day_number': dayNumber, 'fasted': fasted}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return SingleResult(
            success: true,
            data: RamadanDay.fromJson(data['data']),
          );
        }
      }
      return SingleResult(success: false, message: 'Imeshindwa kuhifadhi');
    } catch (e) {
      return SingleResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Get Goals ──────────────────────────────────────────────
  Future<PaginatedResult<RamadanGoal>> getGoals({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ramadan/goals'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => RamadanGoal.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(success: true, items: items, total: items.length);
        }
      }
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia malengo');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }
}
