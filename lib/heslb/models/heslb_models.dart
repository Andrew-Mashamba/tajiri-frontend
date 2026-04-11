// lib/heslb/models/heslb_models.dart

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
double _parseDouble(dynamic v) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;

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
    required this.success,
    this.items = const [],
    this.message,
    this.currentPage = 1,
    this.lastPage = 1,
  });
  bool get hasMore => currentPage < lastPage;
}

// ─── Loan Status ──────────────────────────────────────────────

class LoanStatus {
  final int id;
  final String applicationNumber;
  final String studentName;
  final String university;
  final String status; // pending, approved, disbursed, repaying, completed
  final double totalLoan;
  final double disbursed;
  final double repaid;
  final double outstanding;
  final String academicYear;

  LoanStatus({
    required this.id,
    required this.applicationNumber,
    required this.studentName,
    required this.university,
    required this.status,
    required this.totalLoan,
    required this.disbursed,
    required this.repaid,
    required this.outstanding,
    required this.academicYear,
  });

  factory LoanStatus.fromJson(Map<String, dynamic> json) {
    return LoanStatus(
      id: _parseInt(json['id']),
      applicationNumber: json['application_number'] ?? '',
      studentName: json['student_name'] ?? '',
      university: json['university'] ?? '',
      status: json['status'] ?? 'pending',
      totalLoan: _parseDouble(json['total_loan']),
      disbursed: _parseDouble(json['disbursed']),
      repaid: _parseDouble(json['repaid']),
      outstanding: _parseDouble(json['outstanding']),
      academicYear: json['academic_year'] ?? '',
    );
  }

  double get repaymentProgress =>
      totalLoan > 0 ? (repaid / totalLoan).clamp(0.0, 1.0) : 0.0;
}

// ─── Disbursement ─────────────────────────────────────────────

class Disbursement {
  final int id;
  final String type; // tuition, accommodation, meals, books
  final double amount;
  final String status; // pending, processed, failed
  final DateTime date;
  final String? reference;

  Disbursement({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.date,
    this.reference,
  });

  factory Disbursement.fromJson(Map<String, dynamic> json) {
    return Disbursement(
      id: _parseInt(json['id']),
      type: json['type'] ?? '',
      amount: _parseDouble(json['amount']),
      status: json['status'] ?? 'pending',
      date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
      reference: json['reference'],
    );
  }
}

// ─── Repayment ────────────────────────────────────────────────

class Repayment {
  final int id;
  final double amount;
  final String method; // mpesa, bank, employer
  final String status;
  final DateTime date;
  final String? transactionId;

  Repayment({
    required this.id,
    required this.amount,
    required this.method,
    required this.status,
    required this.date,
    this.transactionId,
  });

  factory Repayment.fromJson(Map<String, dynamic> json) {
    return Repayment(
      id: _parseInt(json['id']),
      amount: _parseDouble(json['amount']),
      method: json['method'] ?? 'mpesa',
      status: json['status'] ?? 'pending',
      date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
      transactionId: json['transaction_id'],
    );
  }
}
