// lib/tra/models/tra_models.dart
import '../../config/api_config.dart';

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
double _parseDouble(dynamic v) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
bool _parseBool(dynamic v) =>
    v == true || v == 1 || v == '1' || v == 'true';

class SingleResult<T> {
  final bool success;
  final T? data;
  final String? message;
  SingleResult({required this.success, this.data, this.message});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  final int currentPage;
  final int lastPage;
  PaginatedResult({
    required this.success, this.items = const [], this.message,
    this.currentPage = 1, this.lastPage = 1,
  });
  bool get hasMore => currentPage < lastPage;
}

// ─── Tax Profile ──────────────────────────────────────────────

class TaxProfile {
  final String tin;
  final String? ownerName;
  final String complianceStatus; // compliant, pending, overdue
  final List<String> registeredTaxTypes;
  final String? tccStatus;

  TaxProfile({
    required this.tin,
    this.ownerName,
    required this.complianceStatus,
    this.registeredTaxTypes = const [],
    this.tccStatus,
  });

  factory TaxProfile.fromJson(Map<String, dynamic> json) {
    return TaxProfile(
      tin: json['tin'] ?? '',
      ownerName: json['owner_name'],
      complianceStatus: json['compliance_status'] ?? 'pending',
      registeredTaxTypes: (json['registered_tax_types'] as List?)
          ?.map((e) => '$e').toList() ?? [],
      tccStatus: json['tcc_status'],
    );
  }

  bool get isCompliant => complianceStatus == 'compliant';
}

// ─── Tax Payment ──────────────────────────────────────────────

class TaxPayment {
  final int id;
  final String tin;
  final String taxType;
  final double amount;
  final String referenceNumber;
  final String paymentMethod;
  final DateTime paidAt;
  final String? receiptUrl;

  TaxPayment({
    required this.id, required this.tin, required this.taxType,
    required this.amount, required this.referenceNumber,
    required this.paymentMethod, required this.paidAt, this.receiptUrl,
  });

  factory TaxPayment.fromJson(Map<String, dynamic> json) {
    return TaxPayment(
      id: _parseInt(json['id']),
      tin: json['tin'] ?? '',
      taxType: json['tax_type'] ?? '',
      amount: _parseDouble(json['amount']),
      referenceNumber: json['reference_number'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      paidAt: DateTime.tryParse(json['paid_at'] ?? '') ?? DateTime.now(),
      receiptUrl: json['receipt_url'] != null
          ? ApiConfig.sanitizeUrl(json['receipt_url']) : null,
    );
  }
}

// ─── Tax Deadline ─────────────────────────────────────────────

class TaxDeadline {
  final int id;
  final String taxType;
  final DateTime dueDate;
  final String period;
  final String status; // upcoming, due, overdue, filed

  TaxDeadline({
    required this.id, required this.taxType, required this.dueDate,
    required this.period, required this.status,
  });

  factory TaxDeadline.fromJson(Map<String, dynamic> json) {
    return TaxDeadline(
      id: _parseInt(json['id']),
      taxType: json['tax_type'] ?? '',
      dueDate: DateTime.tryParse(json['due_date'] ?? '') ?? DateTime.now(),
      period: json['period'] ?? '',
      status: json['status'] ?? 'upcoming',
    );
  }

  bool get isOverdue => status == 'overdue';
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;
}

// ─── Tax Breakdown ────────────────────────────────────────────

class TaxBreakdown {
  final String taxType;
  final double grossIncome;
  final double deductions;
  final double taxableIncome;
  final double taxAmount;
  final List<TaxTier> tiers;

  TaxBreakdown({
    required this.taxType, required this.grossIncome,
    this.deductions = 0, required this.taxableIncome,
    required this.taxAmount, this.tiers = const [],
  });

  factory TaxBreakdown.fromJson(Map<String, dynamic> json) {
    return TaxBreakdown(
      taxType: json['tax_type'] ?? '',
      grossIncome: _parseDouble(json['gross_income']),
      deductions: _parseDouble(json['deductions']),
      taxableIncome: _parseDouble(json['taxable_income']),
      taxAmount: _parseDouble(json['tax_amount']),
      tiers: (json['tiers'] as List?)
          ?.map((j) => TaxTier.fromJson(j)).toList() ?? [],
    );
  }
}

class TaxTier {
  final String range;
  final double rate;
  final double amount;

  TaxTier({required this.range, required this.rate, required this.amount});

  factory TaxTier.fromJson(Map<String, dynamic> json) {
    return TaxTier(
      range: json['range'] ?? '',
      rate: _parseDouble(json['rate']),
      amount: _parseDouble(json['amount']),
    );
  }
}
