// lib/expenses/services/expenses_service.dart
//
// Single entry for **business** expense HTTP flows (`/business/.../expenses`).
// Logs outgoing requests and incoming responses (debug); mutating calls also
// notify [CentralTransactionService] so the ledger can correlate with
// `GET /transactions` and future unified transaction sync.
//
// Not covered here (different APIs): [ExpenditureService] (personal budget
// envelopes), event [BudgetService] expenses, Kikoba expense requests.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../business/models/business_models.dart';
import '../../config/api_config.dart';
import '../../services/local_storage_service.dart';
import '../../transactions/services/central_transaction_service.dart';

String get _baseUrl => ApiConfig.baseUrl;

void _log(String msg) => debugPrint('[ExpensesService] $msg');

String _previewBody(String body, {int max = 900}) {
  if (body.length <= max) return body;
  return '${body.substring(0, max)}…';
}

double _toAmount(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

String _apiErrorMessage(http.Response res) {
  try {
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message']?.toString();
      final code = decoded['code']?.toString();
      if (code != null && code.isNotEmpty && message != null && message.isNotEmpty) {
        return '$code: $message';
      }
      if (message != null && message.isNotEmpty) return message;
    }
  } catch (_) {}
  return 'Error: ${res.statusCode}';
}

Future<int?> _resolveUserId(int? explicit) async {
  if (explicit != null) return explicit;
  final s = await LocalStorageService.getInstance();
  return s.getUser()?.userId;
}

/// Business expense API — Matumizi under a registered business.
class ExpensesService {
  ExpensesService._();

  static Future<BusinessListResult<Expense>> getExpenses(
    String token,
    int businessId, {
    int? month,
    int? year,
    String? category,
    int? userId,
  }) async {
    final uid = await _resolveUserId(userId);
    if (uid == null) {
      return BusinessListResult(success: false, message: 'Not logged in');
    }
    var url = '$_baseUrl/business/$businessId/expenses';
    final params = <String>['user_id=${Uri.encodeComponent(uid.toString())}'];
    if (month != null) params.add('month=$month');
    if (year != null) params.add('year=$year');
    if (category != null && category.isNotEmpty) {
      params.add('category=${Uri.encodeComponent(category)}');
    }
    url += '?${params.join('&')}';
    _log('getExpenses → GET $url');
    try {
      final res = await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      _log('getExpenses ← HTTP ${res.statusCode} ${_previewBody(res.body)}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => Expense.fromJson(e as Map<String, dynamic>))
            .toList();
        _log('getExpenses parsed count=${list.length}');
        return BusinessListResult(success: true, data: list);
      }
      return BusinessListResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e, st) {
      _log('getExpenses error: $e');
      debugPrintStack(stackTrace: st);
      return BusinessListResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<ExpenseSummary>> getExpenseSummary(
    String token,
    int businessId, {
    int? month,
    int? year,
    int? userId,
  }) async {
    final uid = await _resolveUserId(userId);
    if (uid == null) {
      return BusinessResult(success: false, message: 'Not logged in');
    }
    var url = '$_baseUrl/business/$businessId/expenses/summary';
    final params = <String>['user_id=${Uri.encodeComponent(uid.toString())}'];
    if (month != null) params.add('month=$month');
    if (year != null) params.add('year=$year');
    url += '?${params.join('&')}';
    _log('getExpenseSummary → GET $url');
    try {
      final res = await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      _log('getExpenseSummary ← HTTP ${res.statusCode} ${_previewBody(res.body)}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return BusinessResult(
          success: true,
          data: ExpenseSummary.fromJson(data['data'] ?? data),
        );
      }
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e, st) {
      _log('getExpenseSummary error: $e');
      debugPrintStack(stackTrace: st);
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<Expense>> addExpense(
    String token,
    int businessId,
    Map<String, dynamic> body, {
    int? userId,
  }) async {
    final uid = await _resolveUserId(userId);
    if (uid == null) {
      return BusinessResult(success: false, message: 'Not logged in');
    }
    final payload = Map<String, dynamic>.from(body)..['user_id'] = uid;
    final traceId = await CentralTransactionService.start(
      token: token,
      module: 'expenses',
      action: 'add_expense',
      direction: 'outgoing',
      amount: _toAmount(body['amount']),
      businessId: businessId,
      metadata: {
        'endpoint': '/business/$businessId/expenses',
        'category': body['category']?.toString(),
      },
    );
    final url = '$_baseUrl/business/$businessId/expenses';
    _log('addExpense → POST $url body=${_previewBody(jsonEncode(payload))}');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(payload),
      );
      _log('addExpense ← HTTP ${res.statusCode} ${_previewBody(res.body)}');
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        await CentralTransactionService.complete(
          token: token,
          traceId: traceId,
          referenceId: (data['data']?['id'] ?? data['id'])?.toString(),
          metadata: {'operation': 'add_expense'},
        );
        return BusinessResult(
          success: true,
          data: Expense.fromJson(data['data'] ?? data),
          message: 'Matumizi yameongezwa',
        );
      }
      await CentralTransactionService.fail(
        token: token,
        traceId: traceId,
        message: _apiErrorMessage(res),
      );
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      await CentralTransactionService.fail(
        token: token,
        traceId: traceId,
        message: e.toString(),
      );
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<Expense>> uploadReceipt(
    String token,
    int expenseId,
    File file, {
    int? userId,
  }) async {
    final uid = await _resolveUserId(userId);
    if (uid == null) {
      return BusinessResult(success: false, message: 'Not logged in');
    }
    final traceId = await CentralTransactionService.start(
      token: token,
      module: 'expenses',
      action: 'upload_receipt',
      direction: 'outgoing',
      amount: 0,
      metadata: {
        'endpoint': '/business/expenses/$expenseId/receipt',
        'expense_id': expenseId,
      },
    );
    final url =
        '$_baseUrl/business/expenses/$expenseId/receipt?user_id=${Uri.encodeComponent(uid.toString())}';
    _log('uploadReceipt → POST $url file=${file.path}');
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(ApiConfig.authHeaders(token));
      final ext = file.path.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (ext == 'png') mimeType = 'image/png';
      if (ext == 'pdf') mimeType = 'application/pdf';
      request.files.add(await http.MultipartFile.fromPath(
        'receipt',
        file.path,
        contentType: MediaType.parse(mimeType),
      ));
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      _log('uploadReceipt ← HTTP ${res.statusCode} ${_previewBody(res.body)}');
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        await CentralTransactionService.complete(
          token: token,
          traceId: traceId,
          referenceId: expenseId.toString(),
          metadata: {'operation': 'upload_receipt'},
        );
        return BusinessResult(
          success: true,
          data: Expense.fromJson(data['data'] ?? data),
          message: 'Risiti imepakiwa',
        );
      }
      await CentralTransactionService.fail(
        token: token,
        traceId: traceId,
        message: _apiErrorMessage(res),
      );
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      await CentralTransactionService.fail(
        token: token,
        traceId: traceId,
        message: e.toString(),
      );
      return BusinessResult(success: false, message: e.toString());
    }
  }

  static Future<BusinessResult<void>> deleteExpense(
    String token,
    int expenseId, {
    int? userId,
  }) async {
    final uid = await _resolveUserId(userId);
    if (uid == null) {
      return BusinessResult(success: false, message: 'Not logged in');
    }
    final traceId = await CentralTransactionService.start(
      token: token,
      module: 'expenses',
      action: 'delete_expense',
      direction: 'outgoing',
      amount: 0,
      metadata: {
        'endpoint': '/business/expenses/$expenseId',
        'expense_id': expenseId,
      },
    );
    final url =
        '$_baseUrl/business/expenses/$expenseId?user_id=${Uri.encodeComponent(uid.toString())}';
    _log('deleteExpense → DELETE $url');
    try {
      final res = await http.delete(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      _log('deleteExpense ← HTTP ${res.statusCode} ${_previewBody(res.body)}');
      if (res.statusCode == 200) {
        await CentralTransactionService.complete(
          token: token,
          traceId: traceId,
          referenceId: expenseId.toString(),
          metadata: {'operation': 'delete_expense'},
        );
        return BusinessResult(success: true, message: 'Matumizi yamefutwa');
      }
      await CentralTransactionService.fail(
        token: token,
        traceId: traceId,
        message: _apiErrorMessage(res),
      );
      return BusinessResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      await CentralTransactionService.fail(
        token: token,
        traceId: traceId,
        message: e.toString(),
      );
      return BusinessResult(success: false, message: e.toString());
    }
  }
}
