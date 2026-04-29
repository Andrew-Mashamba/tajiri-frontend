// lib/crb/models/crb_models.dart
// Data models for the CRB (Credit Reference Bureau) module.

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

double _parseDouble(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

class CreditReport {
  final int? id;
  final int? businessId;
  final DateTime? reportDate;
  final int creditScore;
  final String riskGrade;
  final int totalActiveLoanAccounts;
  final int totalClosedAccounts;
  final double totalOutstandingBalance;
  final double totalOverdueAmount;
  final String? worstArrearStatus;
  final int inquiriesLast90Days;
  final List<PaymentRecord> paymentHistory;
  final String? reportPdfUrl;

  CreditReport({
    this.id,
    this.businessId,
    this.reportDate,
    this.creditScore = 0,
    this.riskGrade = 'E',
    this.totalActiveLoanAccounts = 0,
    this.totalClosedAccounts = 0,
    this.totalOutstandingBalance = 0,
    this.totalOverdueAmount = 0,
    this.worstArrearStatus,
    this.inquiriesLast90Days = 0,
    this.paymentHistory = const [],
    this.reportPdfUrl,
  });

  factory CreditReport.fromJson(Map<String, dynamic> json) {
    List<PaymentRecord> history = [];
    if (json['payment_history'] is List) {
      history = (json['payment_history'] as List)
          .map((e) => PaymentRecord.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }
    return CreditReport(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      reportDate: _parseDate(json['report_date']),
      creditScore: _parseInt(json['credit_score']) ?? _parseInt(json['score']) ?? 0,
      riskGrade: json['risk_grade']?.toString() ?? json['grade']?.toString() ?? 'E',
      totalActiveLoanAccounts: _parseInt(json['total_active_loan_accounts']) ?? 0,
      totalClosedAccounts: _parseInt(json['total_closed_accounts']) ?? 0,
      totalOutstandingBalance: _parseDouble(json['total_outstanding_balance']),
      totalOverdueAmount: _parseDouble(json['total_overdue_amount']),
      worstArrearStatus: json['worst_arrear_status']?.toString(),
      inquiriesLast90Days: _parseInt(json['inquiries_last_90_days']) ?? 0,
      paymentHistory: history,
      reportPdfUrl: json['report_pdf_url']?.toString(),
    );
  }
}

class PaymentRecord {
  final String? lender;
  final String? accountType;
  final DateTime? openDate;
  final double balance;
  final int arrearsDays;
  final String? status;

  PaymentRecord({
    this.lender,
    this.accountType,
    this.openDate,
    this.balance = 0,
    this.arrearsDays = 0,
    this.status,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      lender: json['lender']?.toString(),
      accountType: json['account_type']?.toString(),
      openDate: _parseDate(json['open_date']),
      balance: _parseDouble(json['balance']),
      arrearsDays: _parseInt(json['arrears_days']) ?? 0,
      status: json['status']?.toString(),
    );
  }
}

class CreditScore {
  final int score;
  final String grade;
  final DateTime? lastUpdated;
  final List<ScoreFactor> factors;
  final String trend; // up, down, stable

  CreditScore({
    this.score = 0,
    this.grade = 'E',
    this.lastUpdated,
    this.factors = const [],
    this.trend = 'stable',
  });

  factory CreditScore.fromJson(Map<String, dynamic> json) {
    List<ScoreFactor> factors = [];
    if (json['factors'] is List) {
      factors = (json['factors'] as List)
          .map((e) => ScoreFactor.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }
    return CreditScore(
      score: _parseInt(json['score']) ?? 0,
      grade: json['grade']?.toString() ?? 'E',
      lastUpdated: _parseDate(json['last_updated']),
      factors: factors,
      trend: json['trend']?.toString() ?? 'stable',
    );
  }
}

class ScoreFactor {
  final String? factor;
  final String? impact; // positive, negative
  final String? description;

  ScoreFactor({this.factor, this.impact, this.description});

  factory ScoreFactor.fromJson(Map<String, dynamic> json) {
    return ScoreFactor(
      factor: json['factor']?.toString(),
      impact: json['impact']?.toString(),
      description: (json['description'] ?? json['detail'])?.toString(),
    );
  }
}
