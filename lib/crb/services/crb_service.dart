// lib/crb/services/crb_service.dart
// API service for the CRB (Credit Reference Bureau) module.
// Pattern: static methods, auth token as parameter.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../reminders/models/reminder_models.dart';
import '../../reminders/reminders_source_exception.dart';
import '../models/crb_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

void _log(String msg) => debugPrint('[CrbService] $msg');

// Re-export BusinessResult-style wrapper local to this module
class CrbResult<T> {
  final bool success;
  final T? data;
  final String? message;
  CrbResult({required this.success, this.data, this.message});
}

class CrbService {
  static Future<CrbResult<CreditReport>> getCreditReport(
      String token, int businessId) async {
    try {
      final url = '$_baseUrl/business/$businessId/credit-report';
      _log('GET $url');
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return CrbResult(
            success: true,
            data: CreditReport.fromJson(body['data'] ?? body));
      }
      return CrbResult(
          success: false,
          message: body['message']?.toString() ?? 'Error: ${res.statusCode}');
    } catch (e) {
      return CrbResult(success: false, message: e.toString());
    }
  }

  static Future<CrbResult<CreditScore>> getCreditScore(
      String token, int businessId) async {
    try {
      final url = '$_baseUrl/business/$businessId/credit-score';
      _log('GET $url');
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return CrbResult(
            success: true,
            data: CreditScore.fromJson(body['data'] ?? body));
      }
      return CrbResult(
          success: false,
          message: body['message']?.toString() ?? 'Error: ${res.statusCode}');
    } catch (e) {
      return CrbResult(success: false, message: e.toString());
    }
  }

  static Future<CrbResult<CreditReport>> requestCreditReport(
      String token, int businessId) async {
    try {
      final url = '$_baseUrl/business/$businessId/credit-report/request';
      _log('POST $url');
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 || res.statusCode == 201) {
        return CrbResult(
            success: true,
            data: CreditReport.fromJson(body['data'] ?? body),
            message: 'Ripoti mpya imeombwa kutoka CreditInfo Tanzania');
      }
      return CrbResult(
          success: false,
          message: body['message']?.toString() ?? 'Error: ${res.statusCode}');
    } catch (e) {
      return CrbResult(success: false, message: e.toString());
    }
  }

  // Reminders aggregator source — returns empty list until backend route is live.
  static Future<List<ReminderItem>> getCrbPastDueEntries(
      String token, int userId, {bool strict = false}) async {
    try {
      final url = '$_baseUrl/business/reminders/crb?user_id=$userId';
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['data'] is List ? data['data'] as List : [];
        return list
            .whereType<Map<String, dynamic>>()
            .map(ReminderItem.fromJson)
            .toList();
      }
      if (strict) {
        throw RemindersSourceException(
            '/business/reminders/crb', res.statusCode);
      }
      return [];
    } catch (e) {
      if (strict && e is! RemindersSourceException) {
        throw RemindersSourceException('/business/reminders/crb', 0, cause: e);
      }
      return [];
    }
  }
}
