// lib/income/models/income_models.dart
//
// Portfolio / per-business income (collected revenue − expenses). Period uses
// [RevenuePeriodScope] from the revenue module (same presets as revenue summary).

export '../../revenue/models/revenue_models.dart' show RevenuePeriodScope;

class IncomeTotals {
  final double collectedRevenue;
  final double totalExpenses;
  final double netIncome;

  const IncomeTotals({
    required this.collectedRevenue,
    required this.totalExpenses,
    required this.netIncome,
  });
}

class BusinessIncomeRow {
  final int? businessId;
  final String businessName;
  final double collectedRevenue;
  final double totalExpenses;
  final double netIncome;
  final bool loadFailed;
  final String? loadError;

  const BusinessIncomeRow({
    required this.businessId,
    required this.businessName,
    required this.collectedRevenue,
    required this.totalExpenses,
    required this.netIncome,
    this.loadFailed = false,
    this.loadError,
  });

  bool get canOpenDetail => businessId != null && businessId! > 0 && !loadFailed;
}

class PortfolioIncomeLoadResult {
  final bool success;
  final List<BusinessIncomeRow> rows;
  final IncomeTotals totals;
  final String? message;

  const PortfolioIncomeLoadResult({
    required this.success,
    required this.rows,
    required this.totals,
    this.message,
  });
}

class SingleBusinessIncomeLoadResult {
  final bool success;
  final IncomeTotals totals;
  final String? message;

  const SingleBusinessIncomeLoadResult({
    required this.success,
    required this.totals,
    this.message,
  });
}
