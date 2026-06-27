// lib/accounting/services/accounting_service.dart
// Static API methods for all accounting endpoints.
import 'dart:convert';
import '../../services/http_retry.dart';
import '../../config/api_config.dart';
import '../../services/graphql/graphql_accounting_service.dart';
import '../models/accounting_models.dart';

class AccountingService {
  static const String _base = '${ApiConfig.baseUrl}/accounting';

  static Map<String, String> _qp({
    required int userId,
    String? dateFrom,
    String? dateTo,
    String? sourceType,
    int? perPage,
  }) {
    final p = <String, String>{'user_id': userId.toString()};
    if (dateFrom != null) p['date_from'] = dateFrom;
    if (dateTo != null) p['date_to'] = dateTo;
    if (sourceType != null) p['source_type'] = sourceType;
    if (perPage != null) p['per_page'] = perPage.toString();
    return p;
  }

  static Future<BookSummary?> getBookSummary({
    required String token,
    required int userId,
    String? dateFrom,
    String? dateTo,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlAccountingService.getBookSummary(
        token: token,
        userId: userId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
    }
    try {
      final uri = Uri.parse('$_base/book-summary').replace(
          queryParameters: _qp(userId: userId, dateFrom: dateFrom, dateTo: dateTo));
      final res = await httpGetWithRetry(uri, headers: ApiConfig.authHeaders(token));
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body);
      final data = body['data'] ?? body;
      return BookSummary.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<List<JournalEntry>> getJournalLedger({
    required String token,
    required int userId,
    String? dateFrom,
    String? dateTo,
    String? sourceType,
    int perPage = 20,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlAccountingService.getJournalLedger(
        token: token,
        userId: userId,
        dateFrom: dateFrom,
        dateTo: dateTo,
        sourceType: sourceType,
        perPage: perPage,
      );
    }
    try {
      final uri = Uri.parse('$_base/journal-ledger').replace(
          queryParameters: _qp(
              userId: userId,
              dateFrom: dateFrom,
              dateTo: dateTo,
              sourceType: sourceType,
              perPage: perPage));
      final res = await httpGetWithRetry(uri, headers: ApiConfig.authHeaders(token));
      if (res.statusCode != 200) return [];
      final body = json.decode(res.body);
      final dataSection = body['data'];
      final raw = (dataSection is Map<String, dynamic> ? dataSection['entries'] : null)
          ?? body['entries']
          ?? [];
      if (raw is! List) return [];
      return raw.whereType<Map<String, dynamic>>().map(JournalEntry.fromJson).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<JournalEntry?> getJournalEntry({
    required String token,
    required int userId,
    required int entryId,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlAccountingService.getJournalEntry(
        token: token,
        userId: userId,
        entryId: entryId,
      );
    }
    try {
      final uri = Uri.parse('$_base/journal-entry/$entryId')
          .replace(queryParameters: _qp(userId: userId));
      final res = await httpGetWithRetry(uri, headers: ApiConfig.authHeaders(token));
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body);
      final data = body['data'] ?? body;
      return JournalEntry.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  static Future<TrialBalance?> getTrialBalance({
    required String token,
    required int userId,
    String? dateFrom,
    String? dateTo,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlAccountingService.getTrialBalance(
        token: token,
        userId: userId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
    }
    try {
      final uri = Uri.parse('$_base/trial-balance').replace(
          queryParameters: _qp(userId: userId, dateFrom: dateFrom, dateTo: dateTo));
      final res = await httpGetWithRetry(uri, headers: ApiConfig.authHeaders(token));
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body);
      final data = body['data'] ?? body;
      return TrialBalance.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<ProfitAndLoss?> getProfitAndLoss({
    required String token,
    required int userId,
    required String dateFrom,
    required String dateTo,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlAccountingService.getProfitAndLoss(
        token: token,
        userId: userId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
    }
    try {
      final uri = Uri.parse('$_base/profit-and-loss').replace(
          queryParameters: _qp(userId: userId, dateFrom: dateFrom, dateTo: dateTo));
      final res = await httpGetWithRetry(uri, headers: ApiConfig.authHeaders(token));
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body);
      final data = body['data'] ?? body;
      return ProfitAndLoss.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<BalanceSheet?> getBalanceSheet({
    required String token,
    required int userId,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlAccountingService.getBalanceSheet(
        token: token,
        userId: userId,
      );
    }
    try {
      final uri = Uri.parse('$_base/balance-sheet')
          .replace(queryParameters: _qp(userId: userId));
      final res = await httpGetWithRetry(uri, headers: ApiConfig.authHeaders(token));
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body);
      final data = body['data'] ?? body;
      return BalanceSheet.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
