// lib/debts/models/loans_overview_models.dart
// Credit bureau active loans — personal user + per-business (see docs/modules/debts_crb_backend_directive.md).

import '../../business/models/business_models.dart';

double _parseDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

/// One open facility from CRB (`ContractOverview` / synced debt row).
class CrbActiveLoan {
  final String lenderLabel;
  final String? sector;
  final String? typeOfContract;
  final String? phaseOfContract;
  final String? contractStatus;
  final double totalAmount;
  final double pastDueAmount;
  final int pastDueDays;
  final DateTime? startDate;
  final String? description;
  final String? externalRef;
  final int? debtId;
  /// Set when this row belongs to a business workspace (not personal-only).
  final int? businessId;

  const CrbActiveLoan({
    required this.lenderLabel,
    this.sector,
    this.typeOfContract,
    this.phaseOfContract,
    this.contractStatus,
    this.totalAmount = 0,
    this.pastDueAmount = 0,
    this.pastDueDays = 0,
    this.startDate,
    this.description,
    this.externalRef,
    this.debtId,
    this.businessId,
  });

  factory CrbActiveLoan.fromJson(Map<String, dynamic> json) {
    return CrbActiveLoan(
      lenderLabel: json['lender_label']?.toString() ??
          json['customer_name']?.toString() ??
          'Facility',
      sector: json['sector']?.toString(),
      typeOfContract: json['type_of_contract']?.toString(),
      phaseOfContract: json['phase_of_contract']?.toString(),
      contractStatus: json['contract_status']?.toString(),
      totalAmount: _parseDouble(json['total_amount']),
      pastDueAmount: _parseDouble(json['past_due_amount']),
      pastDueDays: _parseInt(json['past_due_days']) ?? 0,
      startDate: _parseDate(json['start_date']),
      description: json['description']?.toString(),
      externalRef: json['external_ref']?.toString(),
      debtId: _parseInt(json['debt_id'] ?? json['id']),
      businessId: _parseInt(json['business_id']),
    );
  }

  /// When the API is not available: map a synced [Debt] row to a display loan.
  factory CrbActiveLoan.fromCrbDebt(
    Debt d, {
    int? businessId,
  }) {
    return CrbActiveLoan(
      lenderLabel: d.customerName ?? 'Credit facility',
      sector: null,
      typeOfContract: null,
      phaseOfContract: null,
      contractStatus: null,
      totalAmount: d.amount,
      pastDueAmount: d.remainingAmount,
      pastDueDays: 0,
      startDate: d.createdAt,
      description: d.description,
      externalRef: d.externalRef,
      debtId: d.id,
      businessId: businessId ?? d.businessId,
    );
  }

  bool get isLikelyOpen =>
      (phaseOfContract ?? '').toLowerCase() != 'closed' &&
      (contractStatus ?? '').toLowerCase() != 'closed';
}

class BusinessLoanSection {
  final int businessId;
  final String businessName;
  final List<CrbActiveLoan> loans;

  const BusinessLoanSection({
    required this.businessId,
    required this.businessName,
    this.loans = const [],
  });

  factory BusinessLoanSection.fromJson(Map<String, dynamic> json) {
    final raw = json['loans'] ?? json['active_loans'];
    final list = <CrbActiveLoan>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          list.add(CrbActiveLoan.fromJson(e));
        }
      }
    }
    return BusinessLoanSection(
      businessId: _parseInt(json['business_id']) ?? 0,
      businessName: json['business_name']?.toString() ?? 'Business',
      loans: list,
    );
  }
}

class LoansOverview {
  final List<CrbActiveLoan> personal;
  final List<BusinessLoanSection> businesses;
  final DateTime? syncedAt;

  const LoansOverview({
    this.personal = const [],
    this.businesses = const [],
    this.syncedAt,
  });

  factory LoansOverview.fromJson(Map<String, dynamic> json) {
    final p = <CrbActiveLoan>[];
    final per = json['personal'] ?? json['user_loans'];
    if (per is List) {
      for (final e in per) {
        if (e is Map<String, dynamic>) p.add(CrbActiveLoan.fromJson(e));
      }
    }
    final bs = <BusinessLoanSection>[];
    final biz = json['businesses'] ?? json['business_loans'];
    if (biz is List) {
      for (final e in biz) {
        if (e is Map<String, dynamic>) bs.add(BusinessLoanSection.fromJson(e));
      }
    }
    return LoansOverview(
      personal: p,
      businesses: bs,
      syncedAt: _parseDate(json['synced_at']),
    );
  }

  int get totalLoanCount =>
      personal.length +
      businesses.fold<int>(0, (a, s) => a + s.loans.length);
}
