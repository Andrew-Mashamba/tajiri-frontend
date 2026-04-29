// lib/team/services/team_service.dart
// API service for the Team (Employees) module.
// Pattern: static methods, auth token as parameter.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../reminders/models/reminder_models.dart';
import '../../reminders/reminders_source_exception.dart';
import '../models/team_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

void _log(String msg) => debugPrint('[TeamService] $msg');

class TeamResult<T> {
  final bool success;
  final T? data;
  final String? message;
  TeamResult({required this.success, this.data, this.message});
}

class TeamListResult<T> {
  final bool success;
  final List<T> data;
  final String? message;
  TeamListResult({required this.success, this.data = const [], this.message});
}

class TeamService {
  static Future<TeamListResult<Employee>> getEmployees(
      String token, int businessId) async {
    try {
      final url = '$_baseUrl/business/$businessId/employees';
      _log('GET $url');
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => Employee.fromJson(e as Map<String, dynamic>))
            .toList();
        return TeamListResult(success: true, data: list);
      }
      return TeamListResult(
          success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ??
              'Error: ${res.statusCode}');
    } catch (e) {
      return TeamListResult(success: false, message: e.toString());
    }
  }

  static Future<TeamResult<Employee>> addEmployee(
      String token, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/employees';
      _log('POST $url');
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return TeamResult(
            success: true,
            data: Employee.fromJson(data['data'] ?? data),
            message: 'Employee added');
      }
      return TeamResult(
          success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ??
              'Error: ${res.statusCode}');
    } catch (e) {
      return TeamResult(success: false, message: e.toString());
    }
  }

  static Future<TeamResult<Employee>> updateEmployee(
      String token, int employeeId, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/employees/$employeeId';
      _log('PUT $url');
      final res = await http.put(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return TeamResult(
            success: true, data: Employee.fromJson(data['data'] ?? data));
      }
      return TeamResult(
          success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ??
              'Error: ${res.statusCode}');
    } catch (e) {
      return TeamResult(success: false, message: e.toString());
    }
  }

  static Future<TeamResult<void>> removeEmployee(
      String token, int employeeId) async {
    try {
      final url = '$_baseUrl/business/employees/$employeeId';
      _log('DELETE $url');
      final res = await http.delete(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) return TeamResult(success: true);
      return TeamResult(
          success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ??
              'Error: ${res.statusCode}');
    } catch (e) {
      return TeamResult(success: false, message: e.toString());
    }
  }

  static Future<TeamListResult<PlatformUser>> searchPlatformUsers(
      String token, String query) async {
    try {
      final encoded = Uri.encodeQueryComponent(query);
      final url = '$_baseUrl/users/search?q=$encoded&limit=20';
      _log('GET $url');
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => PlatformUser.fromJson(e as Map<String, dynamic>))
            .toList();
        return TeamListResult(success: true, data: list);
      }
      return TeamListResult(
          success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ??
              'Error: ${res.statusCode}');
    } catch (e) {
      return TeamListResult(success: false, message: e.toString());
    }
  }

  static Future<TeamResult<Employee>> getEmployee(
      String token, int employeeId) async {
    try {
      final url = '$_baseUrl/business/employees/$employeeId';
      _log('GET $url');
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return TeamResult(
            success: true, data: Employee.fromJson(data['data'] ?? data));
      }
      return TeamResult(
          success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ??
              'Error: ${res.statusCode}');
    } catch (e) {
      return TeamResult(success: false, message: e.toString());
    }
  }

  static Future<TeamListResult<HrAction>> getHrActions(
      String token, int employeeId) async {
    try {
      final url = '$_baseUrl/business/employees/$employeeId/hr-actions';
      _log('GET $url');
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => HrAction.fromJson(e as Map<String, dynamic>))
            .toList();
        return TeamListResult(success: true, data: list);
      }
      return TeamListResult(
          success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ??
              'Error: ${res.statusCode}');
    } catch (e) {
      return TeamListResult(success: false, message: e.toString());
    }
  }

  static Future<TeamResult<HrAction>> addHrAction(
      String token, int employeeId, Map<String, dynamic> body) async {
    try {
      final url = '$_baseUrl/business/employees/$employeeId/hr-actions';
      _log('POST $url');
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token), body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return TeamResult(
            success: true,
            data: HrAction.fromJson(data['data'] as Map<String, dynamic>),
            message: data['message']?.toString());
      }
      return TeamResult(
          success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ??
              'Error: ${res.statusCode}');
    } catch (e) {
      return TeamResult(success: false, message: e.toString());
    }
  }

  static Future<TeamResult<void>> deleteHrAction(
      String token, int actionId) async {
    try {
      final url = '$_baseUrl/business/hr-actions/$actionId';
      _log('DELETE $url');
      final res = await http.delete(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) return TeamResult(success: true);
      return TeamResult(
          success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ??
              'Error: ${res.statusCode}');
    } catch (e) {
      return TeamResult(success: false, message: e.toString());
    }
  }

  static Future<List<ReminderItem>> getExpiringEmployeeContracts(
      String token, int userId, {bool strict = false}) async {
    try {
      final url = '$_baseUrl/business/reminders/employees?user_id=$userId';
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
            '/business/reminders/employees', res.statusCode);
      }
      return [];
    } catch (e) {
      if (strict && e is! RemindersSourceException) {
        throw RemindersSourceException(
            '/business/reminders/employees', 0, cause: e);
      }
      return [];
    }
  }
}
