// lib/fee_status/models/fee_status_models.dart

// ─── FeeCategory ─────────────────────────────────────────────

class FeeCategory {
  final String name;
  final double amount;
  final double paid;

  FeeCategory({
    required this.name,
    required this.amount,
    required this.paid,
  });

  factory FeeCategory.fromJson(Map<String, dynamic> json) {
    return FeeCategory(
      name: json['name']?.toString() ?? '',
      amount: _parseDouble(json['amount']) ?? 0,
      paid: _parseDouble(json['paid']) ?? 0,
    );
  }

  double get remaining => amount - paid;
  bool get isPaid => paid >= amount;
}

// ─── FeeBalance ──────────────────────────────────────────────

class FeeBalance {
  final double totalFees;
  final double totalPaid;
  final double balance;
  final String semester;
  final int year;
  final List<FeeCategory> categories;
  final DateTime? nextDeadline;
  final String? deadlineLabel;

  FeeBalance({
    required this.totalFees,
    required this.totalPaid,
    required this.balance,
    required this.semester,
    required this.year,
    this.categories = const [],
    this.nextDeadline,
    this.deadlineLabel,
  });

  factory FeeBalance.fromJson(Map<String, dynamic> json) {
    return FeeBalance(
      totalFees: _parseDouble(json['total_fees']) ?? 0,
      totalPaid: _parseDouble(json['total_paid']) ?? 0,
      balance: _parseDouble(json['balance']) ?? 0,
      semester: json['semester']?.toString() ?? '',
      year: _parseInt(json['year']),
      categories: (json['categories'] as List?)
              ?.map((c) => FeeCategory.fromJson(c))
              .toList() ??
          [],
      nextDeadline:
          DateTime.tryParse(json['next_deadline']?.toString() ?? ''),
      deadlineLabel: json['deadline_label']?.toString(),
    );
  }

  double get paidPercent => totalFees > 0 ? totalPaid / totalFees : 0;
}

// ─── Payment ─────────────────────────────────────────────────

class FeePayment {
  final int id;
  final double amount;
  final String method; // mpesa, bank, heslb
  final String referenceNumber;
  final String? receiptUrl;
  final DateTime paidAt;
  final String status; // confirmed, pending, failed

  FeePayment({
    required this.id,
    required this.amount,
    required this.method,
    required this.referenceNumber,
    this.receiptUrl,
    required this.paidAt,
    required this.status,
  });

  factory FeePayment.fromJson(Map<String, dynamic> json) {
    return FeePayment(
      id: _parseInt(json['id']),
      amount: _parseDouble(json['amount']) ?? 0,
      method: json['method']?.toString() ?? '',
      referenceNumber: json['reference_number']?.toString() ?? '',
      receiptUrl: json['receipt_url']?.toString(),
      paidAt: DateTime.tryParse(json['paid_at']?.toString() ?? '') ??
          DateTime.now(),
      status: json['status']?.toString() ?? 'pending',
    );
  }

  String get methodDisplay {
    switch (method) {
      case 'mpesa':
        return 'M-Pesa';
      case 'bank':
        return 'Benki';
      case 'heslb':
        return 'HESLB';
      default:
        return method;
    }
  }
}

// ─── HESLB Status ────────────────────────────────────────────

class HeslbStatus {
  final double allocated;
  final double disbursed;
  final double remaining;
  final DateTime? lastDisbursement;
  final String status; // active, pending, suspended

  HeslbStatus({
    required this.allocated,
    required this.disbursed,
    required this.remaining,
    this.lastDisbursement,
    required this.status,
  });

  factory HeslbStatus.fromJson(Map<String, dynamic> json) {
    return HeslbStatus(
      allocated: _parseDouble(json['allocated']) ?? 0,
      disbursed: _parseDouble(json['disbursed']) ?? 0,
      remaining: _parseDouble(json['remaining']) ?? 0,
      lastDisbursement:
          DateTime.tryParse(json['last_disbursement']?.toString() ?? ''),
      status: json['status']?.toString() ?? 'pending',
    );
  }
}

// ─── ClearanceItem ───────────────────────────────────────────

class ClearanceItem {
  final String department;
  final bool isCleared;
  final String? note;

  ClearanceItem({
    required this.department,
    required this.isCleared,
    this.note,
  });

  factory ClearanceItem.fromJson(Map<String, dynamic> json) {
    return ClearanceItem(
      department: json['department']?.toString() ?? '',
      isCleared: _parseBool(json['is_cleared']),
      note: json['note']?.toString(),
    );
  }
}

// ─── Result wrappers ─────────────────────────────────────────

class FeeResult<T> {
  final bool success;
  final T? data;
  final String? message;

  FeeResult({required this.success, this.data, this.message});
}

class FeeListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  FeeListResult({required this.success, this.items = const [], this.message});
}

// ─── Parse helpers ───────────────────────────────────────────

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}
