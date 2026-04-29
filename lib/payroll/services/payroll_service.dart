// lib/payroll/services/payroll_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/payroll_models.dart';

void _log(String m) => debugPrint('[PayrollService] $m');

class PayrollResult<T> {
  final bool success;
  final T? data;
  final String? message;
  const PayrollResult({required this.success, this.data, this.message});
}

class PayrollListResult<T> {
  final bool success;
  final List<T> data;
  final String? message;
  const PayrollListResult({required this.success, this.data = const [], this.message});
}

class PayrollService {
  static Map<String, String> _h(String token) => ApiConfig.authHeaders(token);

  // GET /business/{id}/payroll
  static Future<PayrollListResult<PayrollRun>> getHistory(
      String token, int businessId) async {
    final url = '${ApiConfig.baseUrl}/business/$businessId/payroll';
    _log('GET $url');
    try {
      final res = await http.get(Uri.parse(url), headers: _h(token));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final list = (body['data'] as List? ?? [])
            .map((e) => PayrollRun.fromJson(e as Map<String, dynamic>))
            .toList();
        return PayrollListResult(success: true, data: list);
      }
      return PayrollListResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return PayrollListResult(success: false, message: e.toString());
    }
  }

  // POST /business/{id}/payroll/calculate
  static Future<PayrollResult<PayrollRun>> calculate(
      String token, int businessId, int month, int year) async {
    final url = '${ApiConfig.baseUrl}/business/$businessId/payroll/calculate';
    _log('POST $url');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {..._h(token), 'Content-Type': 'application/json'},
        body: jsonEncode({'month': month, 'year': year}),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 || res.statusCode == 201) {
        final d = body['data'] ?? body;
        return PayrollResult(success: true, data: PayrollRun.fromJson(d as Map<String, dynamic>));
      }
      return PayrollResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return PayrollResult(success: false, message: e.toString());
    }
  }

  // POST /business/payroll/{id}/approve
  static Future<PayrollResult<void>> approve(String token, int payrollId) async {
    final url = '${ApiConfig.baseUrl}/business/payroll/$payrollId/approve';
    _log('POST $url');
    try {
      final res = await http.post(Uri.parse(url), headers: _h(token));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 || res.statusCode == 201) {
        return const PayrollResult(success: true);
      }
      return PayrollResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return PayrollResult(success: false, message: e.toString());
    }
  }

  // GET /business/{id}/payroll/statutory
  static Future<PayrollListResult<StatutoryObligation>> getStatutory(
      String token, int businessId) async {
    final url = '${ApiConfig.baseUrl}/business/$businessId/payroll/statutory';
    _log('GET $url');
    try {
      final res = await http.get(Uri.parse(url), headers: _h(token));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['data'] as List? ?? [])
            .map((e) => StatutoryObligation.fromJson(e as Map<String, dynamic>))
            .toList();
        return PayrollListResult(success: true, data: list);
      }
      // 404 means endpoint not yet deployed — caller handles graceful degradation
      return const PayrollListResult(success: false, message: 'endpoint_unavailable');
    } catch (e) {
      return PayrollListResult(success: false, message: e.toString());
    }
  }

  // POST /business/payroll/statutory/{id}/remit
  static Future<PayrollResult<void>> markRemitted(
      String token, int obligationId) async {
    final url =
        '${ApiConfig.baseUrl}/business/payroll/statutory/$obligationId/remit';
    _log('POST $url');
    try {
      final res = await http.post(Uri.parse(url), headers: _h(token));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 || res.statusCode == 201) {
        return const PayrollResult(success: true);
      }
      return PayrollResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return PayrollResult(success: false, message: e.toString());
    }
  }
}
