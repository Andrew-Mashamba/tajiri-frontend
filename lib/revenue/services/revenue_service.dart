// lib/revenue/services/revenue_service.dart
//
// Portfolio revenue: prefers GET /api/revenue/summary; falls back to parallel
// invoice fetches on 404 (older servers). See docs/modules/revenue_backend_directive.md.

import 'dart:convert';

import '../../services/http_retry.dart';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import '../../config/api_config.dart';
import '../../services/graphql/graphql_revenue_service.dart';
import '../models/revenue_models.dart';

class RevenueService {
  /// Invoices that count toward operational revenue KPIs.
  static bool isCountableInvoice(Invoice inv) {
    switch (inv.status) {
      case InvoiceStatus.draft:
      case InvoiceStatus.cancelled:
      case InvoiceStatus.void_status:
        return false;
      default:
        return true;
    }
  }

  static DateTime? _periodStart(RevenuePeriodScope scope) {
    final now = DateTime.now();
    switch (scope) {
      case RevenuePeriodScope.allTime:
        return null;
      case RevenuePeriodScope.thisMonth:
        return DateTime(now.year, now.month, 1);
      case RevenuePeriodScope.last30Days:
        return now.subtract(const Duration(days: 30));
    }
  }

  /// Whether [inv] should be included for [scope] (by [Invoice.createdAt]).
  static bool invoiceMatchesPeriod(Invoice inv, RevenuePeriodScope scope) {
    if (!isCountableInvoice(inv)) return false;
    final start = _periodStart(scope);
    if (start == null) return true;
    final created = inv.createdAt;
    if (created == null) return false;
    return !created.isBefore(start);
  }

  static RevenueTotals computeTotals(Iterable<Invoice> invoices, RevenuePeriodScope scope) {
    var gross = 0.0;
    var collected = 0.0;
    for (final inv in invoices) {
      if (!invoiceMatchesPeriod(inv, scope)) continue;
      gross += inv.totalAmount;
      collected += inv.amountPaid;
    }
    final outstanding = (gross - collected).clamp(0.0, double.infinity);
    return RevenueTotals(gross: gross, collected: collected, outstanding: outstanding);
  }

  static String _periodQueryParam(RevenuePeriodScope scope) {
    switch (scope) {
      case RevenuePeriodScope.allTime:
        return 'all';
      case RevenuePeriodScope.thisMonth:
        return 'this_month';
      case RevenuePeriodScope.last30Days:
        return 'last_30_days';
    }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static RevenueLedgerHint? _parseLedgerHint(dynamic raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    if (m.isEmpty) return null;
    return RevenueLedgerHint(
      incomingSuccessTotal: _toDouble(m['incoming_success_total'] ?? m['incomingSuccessTotal']),
      rowCount: _toInt(m['row_count'] ?? m['rowCount']) ?? 0,
    );
  }

  static RevenueTotals? _totalsFromDataMap(Map<String, dynamic> dataMap) {
    final totalsRaw = dataMap['totals'];
    if (totalsRaw is! Map) return null;
    final totalsMap = Map<String, dynamic>.from(totalsRaw);
    return RevenueTotals(
      gross: _toDouble(totalsMap['gross_billed'] ?? totalsMap['grossBilled']),
      collected: _toDouble(totalsMap['collected']),
      outstanding: _toDouble(totalsMap['outstanding']),
    );
  }

  static String? _messageFromBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return null;
  }

  /// Single-business KPIs: [GET /api/revenue/summary?business_id=…]; on **404** only,
  /// falls back to [BusinessService.getInvoices] + [computeTotals].
  static Future<SingleBusinessRevenueLoadResult> loadBusinessTotals(
    String token,
    int businessId,
    RevenuePeriodScope scope, {
    bool includeLedgerHint = true,
  }) async {
    const zero = RevenueTotals(gross: 0, collected: 0, outstanding: 0);
    if (ApiConfig.useGraphqlBackend) {
      final data = await GraphqlRevenueService.revenueSummary(
        period: _periodQueryParam(scope),
        businessId: businessId,
        includeLedgerHint: includeLedgerHint,
      );
      if (data == null) {
        return const SingleBusinessRevenueLoadResult(
          success: false,
          totals: zero,
          message: 'Failed to load revenue summary',
        );
      }
      final totals = _totalsFromDataMap(data);
      if (totals == null) {
        return const SingleBusinessRevenueLoadResult(
          success: false,
          totals: zero,
          message: 'Missing totals',
        );
      }
      final ledgerHint = includeLedgerHint
          ? _parseLedgerHint(data['ledger_hint'] ?? data['ledgerHint'])
          : null;
      return SingleBusinessRevenueLoadResult(
        success: true,
        totals: totals,
        ledgerHint: ledgerHint,
      );
    }
    try {
      final params = <String, String>{
        'period': _periodQueryParam(scope),
        'basis': 'invoice_created',
        'business_id': '$businessId',
      };
      if (includeLedgerHint) {
        params['include_ledger_hint'] = '1';
      }
      final uri = Uri.parse('${ApiConfig.baseUrl}/revenue/summary').replace(queryParameters: params);
      final res = await httpGetWithRetry(uri, headers: ApiConfig.authHeadersWithoutTrace(token));

      if (res.statusCode == 404) {
        return _loadBusinessTotalsFromInvoices(token, businessId, scope);
      }

      if (res.statusCode == 403) {
        return SingleBusinessRevenueLoadResult(
          success: false,
          totals: zero,
          message: _messageFromBody(res.body) ?? 'Forbidden',
        );
      }

      if (res.statusCode != 200) {
        return SingleBusinessRevenueLoadResult(
          success: false,
          totals: zero,
          message: _messageFromBody(res.body) ?? 'HTTP ${res.statusCode}',
        );
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        return const SingleBusinessRevenueLoadResult(
          success: false,
          totals: RevenueTotals(gross: 0, collected: 0, outstanding: 0),
          message: 'Invalid response',
        );
      }

      if (decoded['success'] != true) {
        return SingleBusinessRevenueLoadResult(
          success: false,
          totals: zero,
          message: decoded['message']?.toString() ?? 'Failed to load revenue summary',
        );
      }

      final data = decoded['data'];
      if (data is! Map) {
        return const SingleBusinessRevenueLoadResult(
          success: false,
          totals: RevenueTotals(gross: 0, collected: 0, outstanding: 0),
          message: 'Missing data',
        );
      }

      final dataMap = Map<String, dynamic>.from(data);
      final totals = _totalsFromDataMap(dataMap);
      if (totals == null) {
        return const SingleBusinessRevenueLoadResult(
          success: false,
          totals: RevenueTotals(gross: 0, collected: 0, outstanding: 0),
          message: 'Missing totals',
        );
      }

      final ledgerHint = includeLedgerHint
          ? _parseLedgerHint(dataMap['ledger_hint'] ?? dataMap['ledgerHint'])
          : null;

      return SingleBusinessRevenueLoadResult(
        success: true,
        totals: totals,
        ledgerHint: ledgerHint,
      );
    } catch (e) {
      return SingleBusinessRevenueLoadResult(
        success: false,
        totals: zero,
        message: e.toString(),
      );
    }
  }

  static Future<SingleBusinessRevenueLoadResult> _loadBusinessTotalsFromInvoices(
    String token,
    int businessId,
    RevenuePeriodScope scope,
  ) async {
    const zero = RevenueTotals(gross: 0, collected: 0, outstanding: 0);
    final res = await BusinessService.getInvoices(token, businessId);
    if (!res.success) {
      return SingleBusinessRevenueLoadResult(
        success: false,
        totals: zero,
        message: res.message ?? 'Failed to load invoices',
      );
    }
    final t = computeTotals(res.data, scope);
    return SingleBusinessRevenueLoadResult(success: true, totals: t);
  }

  /// Loads portfolio KPIs: tries [GET /api/revenue/summary] first; on **404** only,
  /// falls back to parallel `getInvoices` per business (legacy servers).
  static Future<PortfolioRevenueLoadResult> loadPortfolio(
    String token,
    List<Business> businesses,
    RevenuePeriodScope scope,
  ) async {
    if (businesses.isEmpty) {
      return const PortfolioRevenueLoadResult(
        success: true,
        rows: [],
        totals: RevenueTotals(gross: 0, collected: 0, outstanding: 0),
      );
    }

    if (ApiConfig.useGraphqlBackend) {
      final data = await GraphqlRevenueService.revenueSummary(
        period: _periodQueryParam(scope),
        includeLedgerHint: true,
      );
      if (data == null) {
        return const PortfolioRevenueLoadResult(
          success: false,
          rows: [],
          totals: RevenueTotals(gross: 0, collected: 0, outstanding: 0),
          message: 'Failed to load revenue summary',
        );
      }
      final totals = _totalsFromDataMap(data);
      if (totals == null) {
        return const PortfolioRevenueLoadResult(
          success: false,
          rows: [],
          totals: RevenueTotals(gross: 0, collected: 0, outstanding: 0),
          message: 'Missing totals',
        );
      }
      final byRaw = data['by_business'] ?? data['byBusiness'];
      final apiRows = <int, BusinessRevenueRow>{};
      if (byRaw is List) {
        for (final e in byRaw) {
          if (e is! Map) continue;
          final rowMap = Map<String, dynamic>.from(e);
          final id = _toInt(rowMap['business_id'] ?? rowMap['businessId']);
          if (id == null) continue;
          apiRows[id] = BusinessRevenueRow(
            businessId: id,
            businessName: (rowMap['business_name'] ?? rowMap['businessName'] ?? '').toString(),
            gross: _toDouble(rowMap['gross_billed'] ?? rowMap['grossBilled']),
            collected: _toDouble(rowMap['collected']),
            outstanding: _toDouble(rowMap['outstanding']),
          );
        }
      }
      final merged = _mergeApiRowsWithBusinessList(businesses, apiRows);
      merged.sort((a, b) {
        if (a.loadFailed != b.loadFailed) return a.loadFailed ? 1 : -1;
        return b.gross.compareTo(a.gross);
      });
      final ledgerHint = _parseLedgerHint(data['ledger_hint'] ?? data['ledgerHint']);
      return PortfolioRevenueLoadResult(
        success: true,
        rows: merged,
        totals: totals,
        ledgerHint: ledgerHint,
      );
    }

    try {
      final params = <String, String>{
        'period': _periodQueryParam(scope),
        'basis': 'invoice_created',
        'include_ledger_hint': '1',
      };
      final uri = Uri.parse('${ApiConfig.baseUrl}/revenue/summary').replace(queryParameters: params);
      final res = await httpGetWithRetry(uri, headers: ApiConfig.authHeadersWithoutTrace(token));

      if (res.statusCode == 404) {
        return _loadPortfolioFromInvoices(token, businesses, scope);
      }

      if (res.statusCode != 200) {
        return PortfolioRevenueLoadResult(
          success: false,
          rows: const [],
          totals: const RevenueTotals(gross: 0, collected: 0, outstanding: 0),
          message: 'HTTP ${res.statusCode}',
        );
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        return const PortfolioRevenueLoadResult(
          success: false,
          rows: [],
          totals: RevenueTotals(gross: 0, collected: 0, outstanding: 0),
          message: 'Invalid response',
        );
      }

      if (decoded['success'] != true) {
        return PortfolioRevenueLoadResult(
          success: false,
          rows: const [],
          totals: const RevenueTotals(gross: 0, collected: 0, outstanding: 0),
          message: decoded['message']?.toString() ?? 'Failed to load revenue summary',
        );
      }

      final data = decoded['data'];
      if (data is! Map) {
        return const PortfolioRevenueLoadResult(
          success: false,
          rows: [],
          totals: RevenueTotals(gross: 0, collected: 0, outstanding: 0),
          message: 'Missing data',
        );
      }

      final dataMap = Map<String, dynamic>.from(data);
      final totals = _totalsFromDataMap(dataMap);
      if (totals == null) {
        return const PortfolioRevenueLoadResult(
          success: false,
          rows: [],
          totals: RevenueTotals(gross: 0, collected: 0, outstanding: 0),
          message: 'Missing totals',
        );
      }

      final byRaw = dataMap['by_business'] ?? dataMap['byBusiness'];
      final apiRows = <int, BusinessRevenueRow>{};
      if (byRaw is List) {
        for (final e in byRaw) {
          if (e is! Map) continue;
          final rowMap = Map<String, dynamic>.from(e);
          final id = _toInt(rowMap['business_id'] ?? rowMap['businessId']);
          if (id == null) continue;
          apiRows[id] = BusinessRevenueRow(
            businessId: id,
            businessName: (rowMap['business_name'] ?? rowMap['businessName'] ?? '').toString(),
            gross: _toDouble(rowMap['gross_billed'] ?? rowMap['grossBilled']),
            collected: _toDouble(rowMap['collected']),
            outstanding: _toDouble(rowMap['outstanding']),
          );
        }
      }

      final merged = _mergeApiRowsWithBusinessList(businesses, apiRows);
      merged.sort((a, b) {
        if (a.loadFailed != b.loadFailed) return a.loadFailed ? 1 : -1;
        return b.gross.compareTo(a.gross);
      });

      final ledgerHint = _parseLedgerHint(dataMap['ledger_hint'] ?? dataMap['ledgerHint']);

      return PortfolioRevenueLoadResult(
        success: true,
        rows: merged,
        totals: totals,
        ledgerHint: ledgerHint,
      );
    } catch (e) {
      return PortfolioRevenueLoadResult(
        success: false,
        rows: const [],
        totals: const RevenueTotals(gross: 0, collected: 0, outstanding: 0),
        message: e.toString(),
      );
    }
  }

  /// Ensures every local [Business] appears: API may omit zero-activity businesses.
  static List<BusinessRevenueRow> _mergeApiRowsWithBusinessList(
    List<Business> businesses,
    Map<int, BusinessRevenueRow> apiRows,
  ) {
    final merged = <BusinessRevenueRow>[];
    final consumed = <int>{};

    for (final b in businesses) {
      if (b.id == null) {
        merged.add(
          BusinessRevenueRow(
            businessId: null,
            businessName: b.name,
            gross: 0,
            collected: 0,
            outstanding: 0,
            loadFailed: true,
            loadError: 'Business has no ID yet',
          ),
        );
        continue;
      }
      final id = b.id!;
      final fromApi = apiRows[id];
      if (fromApi != null) {
        merged.add(
          BusinessRevenueRow(
            businessId: id,
            businessName: b.name.isNotEmpty ? b.name : fromApi.businessName,
            gross: fromApi.gross,
            collected: fromApi.collected,
            outstanding: fromApi.outstanding,
          ),
        );
        consumed.add(id);
      } else {
        merged.add(
          BusinessRevenueRow(
            businessId: id,
            businessName: b.name,
            gross: 0,
            collected: 0,
            outstanding: 0,
          ),
        );
      }
    }

    for (final entry in apiRows.entries) {
      if (consumed.contains(entry.key)) continue;
      merged.add(entry.value);
    }

    return merged;
  }

  /// Legacy: parallel invoice fetch + Dart aggregation (matches pre-API semantics).
  static Future<PortfolioRevenueLoadResult> _loadPortfolioFromInvoices(
    String token,
    List<Business> businesses,
    RevenuePeriodScope scope,
  ) async {
    final rows = await Future.wait(businesses.map((b) async {
      if (b.id == null) {
        return BusinessRevenueRow(
          businessId: null,
          businessName: b.name,
          gross: 0,
          collected: 0,
          outstanding: 0,
          loadFailed: true,
          loadError: 'Business has no ID yet',
        );
      }
      final res = await BusinessService.getInvoices(token, b.id!);
      if (!res.success) {
        return BusinessRevenueRow(
          businessId: b.id,
          businessName: b.name,
          gross: 0,
          collected: 0,
          outstanding: 0,
          loadFailed: true,
          loadError: res.message ?? 'Failed to load invoices',
        );
      }
      final t = computeTotals(res.data, scope);
      return BusinessRevenueRow(
        businessId: b.id,
        businessName: b.name,
        gross: t.gross,
        collected: t.collected,
        outstanding: t.outstanding,
      );
    }));

    final sorted = List<BusinessRevenueRow>.from(rows)
      ..sort((a, b) {
        if (a.loadFailed != b.loadFailed) return a.loadFailed ? 1 : -1;
        return b.gross.compareTo(a.gross);
      });

    var tg = 0.0;
    var tc = 0.0;
    for (final r in sorted) {
      if (r.loadFailed) continue;
      tg += r.gross;
      tc += r.collected;
    }
    final to = (tg - tc).clamp(0.0, double.infinity);

    return PortfolioRevenueLoadResult(
      success: true,
      rows: sorted,
      totals: RevenueTotals(gross: tg, collected: tc, outstanding: to),
    );
  }
}
