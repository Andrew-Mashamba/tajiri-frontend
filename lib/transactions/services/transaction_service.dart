// lib/transactions/services/transaction_service.dart
//
// Fetches recorded micro-transactions (GET /transactions) with business fallback.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../business/services/business_service.dart';
import '../../expenses/services/expenses_service.dart';
import '../models/transaction_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class TransactionService {
  /// List central ledger transactions.
  ///
  /// Tries `GET /api/transactions` with optional [businessId], [status], [direction], [module].
  /// On non-success or empty list with [businessId], falls back to invoices, expenses, debts, POs.
  static Future<TransactionListResult> listRecordedTransactions(
    String token, {
    int? businessId,
    int page = 1,
    int perPage = 40,
    String? status,
    String? direction,
    String? module,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
      };
      if (businessId != null) params['business_id'] = '$businessId';
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (direction != null && direction.isNotEmpty) params['direction'] = direction;
      if (module != null && module.isNotEmpty) params['module'] = module;

      final uri = Uri.parse('$_baseUrl/transactions').replace(queryParameters: params);
      final res = await http.get(uri, headers: ApiConfig.authHeaders(token));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          final parsed = _parseTransactionsPayload(
            Map<String, dynamic>.from(body),
            page: page,
            perPage: perPage,
          );
          if (parsed.items.isNotEmpty) {
            return TransactionListResult(
              success: true,
              items: parsed.items,
              meta: parsed.meta,
              source: TransactionDataSource.api,
            );
          }
          if (businessId != null) {
            return _compositeFallback(
              token,
              businessId,
              status: status,
              direction: direction,
            );
          }
          return TransactionListResult(
            success: true,
            items: [],
            meta: parsed.meta,
            source: TransactionDataSource.api,
          );
        }
      }
    } catch (_) {}

    if (businessId != null) {
      return _compositeFallback(
        token,
        businessId,
        status: status,
        direction: direction,
      );
    }

    return TransactionListResult(
      success: false,
      message: 'Unable to load transactions',
      source: TransactionDataSource.api,
    );
  }

  static Future<TransactionListResult> _compositeFallback(
    String token,
    int businessId, {
    String? status,
    String? direction,
  }) async {
    final invRes = await BusinessService.getInvoices(token, businessId);
    final expRes = await ExpensesService.getExpenses(token, businessId);
    final debtRes = await BusinessService.getDebts(token, businessId);
    final poRes = await BusinessService.getPurchaseOrders(token, businessId);
    final rows = <RecordedTransaction>[];

    final wantIncoming = direction == null || direction == 'incoming';
    final wantOutgoing = direction == null || direction == 'outgoing';

    if (invRes.success && wantIncoming) {
      for (final inv in invRes.data) {
        rows.add(RecordedTransaction.fromInvoice(inv, businessId));
      }
    }
    if (expRes.success && wantOutgoing) {
      for (final exp in expRes.data) {
        rows.add(RecordedTransaction.fromExpense(exp, businessId));
      }
    }
    if (debtRes.success && wantIncoming) {
      for (final d in debtRes.data) {
        rows.add(RecordedTransaction.fromDebt(d, businessId));
      }
    }
    if (poRes.success && wantOutgoing) {
      for (final po in poRes.data) {
        rows.add(RecordedTransaction.fromPurchaseOrder(po, businessId));
      }
    }

    if (status != null && status.isNotEmpty && status != 'success') {
      return TransactionListResult(
        success: true,
        items: [],
        meta: TransactionListMeta(currentPage: 1, lastPage: 1, total: 0),
        source: TransactionDataSource.composite,
      );
    }

    rows.sort((a, b) => b.sortTime.compareTo(a.sortTime));

    return TransactionListResult(
      success: true,
      items: rows,
      meta: TransactionListMeta(
        currentPage: 1,
        lastPage: 1,
        total: rows.length,
      ),
      source: TransactionDataSource.composite,
    );
  }

  static _ParsedList _parseTransactionsPayload(
    Map<String, dynamic> body, {
    required int page,
    required int perPage,
  }) {
    final list = <RecordedTransaction>[];
    final raw = body['data'];

    void addFromList(List? L) {
      if (L == null) return;
      for (final e in L) {
        if (e is Map<String, dynamic>) {
          list.add(RecordedTransaction.fromJson(e));
        } else if (e is Map) {
          list.add(RecordedTransaction.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    if (raw is List) {
      addFromList(raw);
    } else if (raw is Map) {
      final inner = raw['data'];
      if (inner is List) {
        addFromList(inner);
      }
    }

    var meta = _parseMetaBlock(body['meta']);
    if (meta == null && raw is Map) {
      meta = _parseMetaBlock(raw) ?? _metaFromPaginatorMap(raw);
    }
    meta ??= _inferMeta(page: page, perPage: perPage, itemCount: list.length);

    return _ParsedList(items: list, meta: meta);
  }

  static TransactionListMeta? _parseMetaBlock(dynamic raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final cur = _parseInt(m['current_page'] ?? m['currentPage']) ?? 1;
    final last = _parseInt(m['last_page'] ?? m['lastPage']) ?? 1;
    final total = _parseInt(m['total']) ?? 0;
    return TransactionListMeta(currentPage: cur, lastPage: last, total: total);
  }

  static TransactionListMeta? _metaFromPaginatorMap(Map raw) {
    if (raw['current_page'] == null && raw['last_page'] == null) return null;
    final cur = _parseInt(raw['current_page']) ?? 1;
    final last = _parseInt(raw['last_page']) ?? cur;
    final total = _parseInt(raw['total']) ?? 0;
    return TransactionListMeta(currentPage: cur, lastPage: last, total: total);
  }

  /// When API omits [meta] but returns a full page, allow load-more.
  static TransactionListMeta? _inferMeta({
    required int page,
    required int perPage,
    required int itemCount,
  }) {
    if (itemCount == 0) {
      return TransactionListMeta(currentPage: page, lastPage: page, total: 0);
    }
    if (itemCount >= perPage) {
      return TransactionListMeta(
        currentPage: page,
        lastPage: page + 1,
        total: 0,
      );
    }
    return TransactionListMeta(currentPage: page, lastPage: page, total: itemCount);
  }
}

class _ParsedList {
  final List<RecordedTransaction> items;
  final TransactionListMeta? meta;

  _ParsedList({required this.items, this.meta});
}

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}
