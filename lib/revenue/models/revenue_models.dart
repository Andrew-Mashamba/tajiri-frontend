// lib/revenue/models/revenue_models.dart
//
// DTOs for portfolio and per-business revenue (invoice-based).

/// Which invoices to include by issue date ([Invoice.createdAt]).
enum RevenuePeriodScope {
  allTime,
  thisMonth,
  last30Days,
}

class RevenueTotals {
  final double gross;
  final double collected;
  final double outstanding;

  const RevenueTotals({
    required this.gross,
    required this.collected,
    required this.outstanding,
  });
}

/// One row in the "by business" portfolio table.
class BusinessRevenueRow {
  final int? businessId;
  final String businessName;
  final double gross;
  final double collected;
  final double outstanding;
  final bool loadFailed;
  final String? loadError;

  const BusinessRevenueRow({
    required this.businessId,
    required this.businessName,
    required this.gross,
    required this.collected,
    required this.outstanding,
    this.loadFailed = false,
    this.loadError,
  });

  bool get canOpenDetail => businessId != null && businessId! > 0 && !loadFailed;
}

/// Optional totals from `transaction_ledger` when API returns `ledger_hint`.
class RevenueLedgerHint {
  final double incomingSuccessTotal;
  final int rowCount;

  const RevenueLedgerHint({
    required this.incomingSuccessTotal,
    required this.rowCount,
  });
}

class PortfolioRevenueLoadResult {
  final bool success;
  final List<BusinessRevenueRow> rows;
  final RevenueTotals totals;
  final String? message;
  /// Present when `GET /api/revenue/summary` was used with `include_ledger_hint`.
  final RevenueLedgerHint? ledgerHint;

  const PortfolioRevenueLoadResult({
    required this.success,
    required this.rows,
    required this.totals,
    this.message,
    this.ledgerHint,
  });
}

/// Result of single-business revenue (`GET /api/revenue/summary?business_id=` or invoice fallback).
class SingleBusinessRevenueLoadResult {
  final bool success;
  final RevenueTotals totals;
  final String? message;
  final RevenueLedgerHint? ledgerHint;

  const SingleBusinessRevenueLoadResult({
    required this.success,
    required this.totals,
    this.message,
    this.ledgerHint,
  });
}
