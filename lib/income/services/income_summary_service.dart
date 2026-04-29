// lib/income/services/income_summary_service.dart
//
// Collected revenue (countable invoices, by issue date) minus expenses (by date).
// Prefers GET /api/business/income-summary (NOT /income/summary — that is budget
// IncomeService). 404 → parallel invoices + expenses. See docs/modules/income_backend_directive.md.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import '../../expenses/services/expenses_service.dart';
import '../../config/api_config.dart';
import '../../revenue/services/revenue_service.dart';
import '../models/income_models.dart';

class IncomeSummaryService {
  static DateTime? _periodLowerBound(RevenuePeriodScope scope) {
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

  /// Matches server rule: effective time = start of calendar [Expense.date] if set, else [Expense.createdAt].
  /// Non–all-time: exclude when both are null (same as IncomeSummaryService on Laravel).
  static DateTime? _effectiveExpenseTime(Expense e) {
    if (e.date != null) {
      final d = e.date!;
      return DateTime(d.year, d.month, d.day);
    }
    return e.createdAt;
  }

  static bool _expenseMatchesPeriod(Expense e, RevenuePeriodScope scope) {
    final start = _periodLowerBound(scope);
    final t = _effectiveExpenseTime(e);
    if (start == null) return true;
    if (t == null) return false;
    return !t.isBefore(start);
  }

  /// Collected cash from invoices (countable + period on `created_at`) minus expenses in period.
  static IncomeTotals computeFromInvoicesAndExpenses(
    List<Invoice> invoices,
    List<Expense> expenses,
    RevenuePeriodScope scope,
  ) {
    var collected = 0.0;
    for (final inv in invoices) {
      if (!RevenueService.invoiceMatchesPeriod(inv, scope)) continue;
      collected += inv.amountPaid;
    }
    var totalExpenses = 0.0;
    for (final e in expenses) {
      if (!_expenseMatchesPeriod(e, scope)) continue;
      totalExpenses += e.amount;
    }
    return IncomeTotals(
      collectedRevenue: collected,
      totalExpenses: totalExpenses,
      netIncome: collected - totalExpenses,
    );
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

  static String? _messageFromBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return null;
  }

  static IncomeTotals? _totalsFromDataMap(Map<String, dynamic> dataMap) {
    final raw = dataMap['totals'];
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    return IncomeTotals(
      collectedRevenue: _toDouble(m['collected_revenue'] ?? m['collectedRevenue']),
      totalExpenses: _toDouble(m['total_expenses'] ?? m['totalExpenses']),
      netIncome: _toDouble(m['net_income'] ?? m['netIncome']),
    );
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

  static Future<SingleBusinessIncomeLoadResult> loadBusinessTotals(
    String token,
    int businessId,
    RevenuePeriodScope scope,
  ) async {
    const zero = IncomeTotals(collectedRevenue: 0, totalExpenses: 0, netIncome: 0);
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/business/income-summary').replace(queryParameters: {
        'period': _periodQueryParam(scope),
        'basis': 'invoice_expense',
        'business_id': '$businessId',
      });
      final res = await http.get(uri, headers: ApiConfig.authHeadersWithoutTrace(token));

      if (res.statusCode == 404) {
        return _loadBusinessTotalsLegacy(token, businessId, scope);
      }

      if (res.statusCode == 403) {
        return SingleBusinessIncomeLoadResult(
          success: false,
          totals: zero,
          message: _messageFromBody(res.body) ?? 'Forbidden',
        );
      }

      if (res.statusCode != 200) {
        return SingleBusinessIncomeLoadResult(
          success: false,
          totals: zero,
          message: _messageFromBody(res.body) ?? 'HTTP ${res.statusCode}',
        );
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        return SingleBusinessIncomeLoadResult(
          success: false,
          totals: zero,
          message: decoded is Map ? (decoded['message']?.toString() ?? 'Failed') : 'Invalid response',
        );
      }

      final data = decoded['data'];
      if (data is! Map) {
        return const SingleBusinessIncomeLoadResult(
          success: false,
          totals: IncomeTotals(collectedRevenue: 0, totalExpenses: 0, netIncome: 0),
          message: 'Missing data',
        );
      }

      final totals = _totalsFromDataMap(Map<String, dynamic>.from(data));
      if (totals == null) {
        return const SingleBusinessIncomeLoadResult(
          success: false,
          totals: IncomeTotals(collectedRevenue: 0, totalExpenses: 0, netIncome: 0),
          message: 'Missing totals',
        );
      }

      return SingleBusinessIncomeLoadResult(success: true, totals: totals);
    } catch (e) {
      return SingleBusinessIncomeLoadResult(success: false, totals: zero, message: e.toString());
    }
  }

  static Future<SingleBusinessIncomeLoadResult> _loadBusinessTotalsLegacy(
    String token,
    int businessId,
    RevenuePeriodScope scope,
  ) async {
    const zero = IncomeTotals(collectedRevenue: 0, totalExpenses: 0, netIncome: 0);
    final invRes = await BusinessService.getInvoices(token, businessId);
    final expRes = await ExpensesService.getExpenses(token, businessId);
    if (!invRes.success && !expRes.success) {
      return SingleBusinessIncomeLoadResult(
        success: false,
        totals: zero,
        message: invRes.message ?? expRes.message ?? 'Failed to load',
      );
    }
    final inv = invRes.success ? invRes.data : <Invoice>[];
    final exp = expRes.success ? expRes.data : <Expense>[];
    final t = computeFromInvoicesAndExpenses(inv, exp, scope);
    return SingleBusinessIncomeLoadResult(success: true, totals: t);
  }

  static Future<PortfolioIncomeLoadResult> loadPortfolio(
    String token,
    List<Business> businesses,
    RevenuePeriodScope scope,
  ) async {
    if (businesses.isEmpty) {
      return const PortfolioIncomeLoadResult(
        success: true,
        rows: [],
        totals: IncomeTotals(collectedRevenue: 0, totalExpenses: 0, netIncome: 0),
      );
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/business/income-summary').replace(queryParameters: {
        'period': _periodQueryParam(scope),
        'basis': 'invoice_expense',
      });
      final res = await http.get(uri, headers: ApiConfig.authHeadersWithoutTrace(token));

      if (res.statusCode == 404) {
        return _loadPortfolioLegacy(token, businesses, scope);
      }

      if (res.statusCode != 200) {
        return PortfolioIncomeLoadResult(
          success: false,
          rows: const [],
          totals: const IncomeTotals(collectedRevenue: 0, totalExpenses: 0, netIncome: 0),
          message: _messageFromBody(res.body) ?? 'HTTP ${res.statusCode}',
        );
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        return const PortfolioIncomeLoadResult(
          success: false,
          rows: [],
          totals: IncomeTotals(collectedRevenue: 0, totalExpenses: 0, netIncome: 0),
          message: 'Invalid response',
        );
      }

      if (decoded['success'] != true) {
        return PortfolioIncomeLoadResult(
          success: false,
          rows: const [],
          totals: const IncomeTotals(collectedRevenue: 0, totalExpenses: 0, netIncome: 0),
          message: decoded['message']?.toString() ?? 'Failed to load income summary',
        );
      }

      final data = decoded['data'];
      if (data is! Map) {
        return const PortfolioIncomeLoadResult(
          success: false,
          rows: [],
          totals: IncomeTotals(collectedRevenue: 0, totalExpenses: 0, netIncome: 0),
          message: 'Missing data',
        );
      }

      final dataMap = Map<String, dynamic>.from(data);
      final totals = _totalsFromDataMap(dataMap);
      if (totals == null) {
        return const PortfolioIncomeLoadResult(
          success: false,
          rows: [],
          totals: IncomeTotals(collectedRevenue: 0, totalExpenses: 0, netIncome: 0),
          message: 'Missing totals',
        );
      }

      final byRaw = dataMap['by_business'] ?? dataMap['byBusiness'];
      final apiRows = <int, BusinessIncomeRow>{};
      if (byRaw is List) {
        for (final e in byRaw) {
          if (e is! Map) continue;
          final rowMap = Map<String, dynamic>.from(e);
          final id = _toInt(rowMap['business_id'] ?? rowMap['businessId']);
          if (id == null) continue;
          apiRows[id] = BusinessIncomeRow(
            businessId: id,
            businessName: (rowMap['business_name'] ?? rowMap['businessName'] ?? '').toString(),
            collectedRevenue: _toDouble(rowMap['collected_revenue'] ?? rowMap['collectedRevenue']),
            totalExpenses: _toDouble(rowMap['total_expenses'] ?? rowMap['totalExpenses']),
            netIncome: _toDouble(rowMap['net_income'] ?? rowMap['netIncome']),
          );
        }
      }

      final merged = _mergeRowsWithBusinessList(businesses, apiRows);
      merged.sort((a, b) {
        if (a.loadFailed != b.loadFailed) return a.loadFailed ? 1 : -1;
        return b.netIncome.compareTo(a.netIncome);
      });

      return PortfolioIncomeLoadResult(success: true, rows: merged, totals: totals);
    } catch (e) {
      return PortfolioIncomeLoadResult(
        success: false,
        rows: const [],
        totals: const IncomeTotals(collectedRevenue: 0, totalExpenses: 0, netIncome: 0),
        message: e.toString(),
      );
    }
  }

  static List<BusinessIncomeRow> _mergeRowsWithBusinessList(
    List<Business> businesses,
    Map<int, BusinessIncomeRow> apiRows,
  ) {
    final merged = <BusinessIncomeRow>[];
    final consumed = <int>{};

    for (final b in businesses) {
      if (b.id == null) {
        merged.add(
          BusinessIncomeRow(
            businessId: null,
            businessName: b.name,
            collectedRevenue: 0,
            totalExpenses: 0,
            netIncome: 0,
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
          BusinessIncomeRow(
            businessId: id,
            businessName: b.name.isNotEmpty ? b.name : fromApi.businessName,
            collectedRevenue: fromApi.collectedRevenue,
            totalExpenses: fromApi.totalExpenses,
            netIncome: fromApi.netIncome,
          ),
        );
        consumed.add(id);
      } else {
        merged.add(
          BusinessIncomeRow(
            businessId: id,
            businessName: b.name,
            collectedRevenue: 0,
            totalExpenses: 0,
            netIncome: 0,
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

  static Future<PortfolioIncomeLoadResult> _loadPortfolioLegacy(
    String token,
    List<Business> businesses,
    RevenuePeriodScope scope,
  ) async {
    final rows = await Future.wait(businesses.map((b) async {
      if (b.id == null) {
        return BusinessIncomeRow(
          businessId: null,
          businessName: b.name,
          collectedRevenue: 0,
          totalExpenses: 0,
          netIncome: 0,
          loadFailed: true,
          loadError: 'Business has no ID yet',
        );
      }
      final invRes = await BusinessService.getInvoices(token, b.id!);
      final expRes = await ExpensesService.getExpenses(token, b.id!);
      if (!invRes.success && !expRes.success) {
        return BusinessIncomeRow(
          businessId: b.id,
          businessName: b.name,
          collectedRevenue: 0,
          totalExpenses: 0,
          netIncome: 0,
          loadFailed: true,
          loadError: invRes.message ?? expRes.message ?? 'Failed to load',
        );
      }
      final inv = invRes.success ? invRes.data : <Invoice>[];
      final exp = expRes.success ? expRes.data : <Expense>[];
      final t = computeFromInvoicesAndExpenses(inv, exp, scope);
      return BusinessIncomeRow(
        businessId: b.id,
        businessName: b.name,
        collectedRevenue: t.collectedRevenue,
        totalExpenses: t.totalExpenses,
        netIncome: t.netIncome,
      );
    }));

    final sorted = List<BusinessIncomeRow>.from(rows)
      ..sort((a, b) {
        if (a.loadFailed != b.loadFailed) return a.loadFailed ? 1 : -1;
        return b.netIncome.compareTo(a.netIncome);
      });

    var c = 0.0, e = 0.0;
    for (final r in sorted) {
      if (r.loadFailed) continue;
      c += r.collectedRevenue;
      e += r.totalExpenses;
    }

    return PortfolioIncomeLoadResult(
      success: true,
      rows: sorted,
      totals: IncomeTotals(collectedRevenue: c, totalExpenses: e, netIncome: c - e),
    );
  }
}
