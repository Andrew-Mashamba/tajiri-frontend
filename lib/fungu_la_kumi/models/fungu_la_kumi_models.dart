// lib/fungu_la_kumi/models/fungu_la_kumi_models.dart

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
double _parseDouble(dynamic v) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;

// ─── Result wrappers ───────────────────────────────────────────

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

// ─── Enums ────────────────────────────────────────────────────

enum GivingType {
  tithe,
  offering,
  missions,
  building,
  thanksgiving;

  String get label {
    switch (this) {
      case tithe: return 'Zaka / Tithe';
      case offering: return 'Sadaka / Offering';
      case missions: return 'Misheni / Missions';
      case building: return 'Ujenzi / Building';
      case thanksgiving: return 'Shukrani / Thanksgiving';
    }
  }
}

// ─── Giving Record ────────────────────────────────────────────

class GivingRecord {
  final int id;
  final double amount;
  final GivingType type;
  final String? churchName;
  final String paymentMethod;
  final String? mpesaRef;
  final String date;
  final String? note;

  GivingRecord({
    required this.id,
    required this.amount,
    required this.type,
    this.churchName,
    required this.paymentMethod,
    this.mpesaRef,
    required this.date,
    this.note,
  });

  factory GivingRecord.fromJson(Map<String, dynamic> json) {
    return GivingRecord(
      id: _parseInt(json['id']),
      amount: _parseDouble(json['amount']),
      type: _parseGivingType(json['type']),
      churchName: json['church_name']?.toString(),
      paymentMethod: json['payment_method']?.toString() ?? 'mpesa',
      mpesaRef: json['mpesa_ref']?.toString(),
      date: json['date']?.toString() ?? '',
      note: json['note']?.toString(),
    );
  }
}

// ─── Giving Summary ───────────────────────────────────────────

class GivingSummary {
  final double totalThisMonth;
  final double totalThisYear;
  final double titheThisMonth;
  final double offeringThisMonth;
  final int givingStreak;

  GivingSummary({
    required this.totalThisMonth,
    required this.totalThisYear,
    required this.titheThisMonth,
    required this.offeringThisMonth,
    required this.givingStreak,
  });

  factory GivingSummary.fromJson(Map<String, dynamic> json) {
    return GivingSummary(
      totalThisMonth: _parseDouble(json['total_this_month']),
      totalThisYear: _parseDouble(json['total_this_year']),
      titheThisMonth: _parseDouble(json['tithe_this_month']),
      offeringThisMonth: _parseDouble(json['offering_this_month']),
      givingStreak: _parseInt(json['giving_streak']),
    );
  }
}

// ─── Pledge ───────────────────────────────────────────────────

class Pledge {
  final int id;
  final String title;
  final double targetAmount;
  final double paidAmount;
  final String? churchName;
  final String? deadline;
  final String createdAt;

  Pledge({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.paidAmount,
    this.churchName,
    this.deadline,
    required this.createdAt,
  });

  factory Pledge.fromJson(Map<String, dynamic> json) {
    return Pledge(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      targetAmount: _parseDouble(json['target_amount']),
      paidAmount: _parseDouble(json['paid_amount']),
      churchName: json['church_name']?.toString(),
      deadline: json['deadline']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  double get progress =>
      targetAmount > 0 ? (paidAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remaining => (targetAmount - paidAmount).clamp(0.0, targetAmount);
}

// ─── Parse helpers ────────────────────────────────────────────

GivingType _parseGivingType(dynamic v) {
  switch (v?.toString()) {
    case 'offering': return GivingType.offering;
    case 'missions': return GivingType.missions;
    case 'building': return GivingType.building;
    case 'thanksgiving': return GivingType.thanksgiving;
    default: return GivingType.tithe;
  }
}
