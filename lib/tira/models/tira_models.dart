// lib/tira/models/tira_models.dart

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
    required this.success,
    this.items = const [],
    this.message,
    this.currentPage = 1,
    this.lastPage = 1,
  });
  bool get hasMore => currentPage < lastPage;
}

// ─── Insurance Policy ─────────────────────────────────────────

class InsurancePolicy {
  final int id;
  final String policyNumber;
  final String insurerName;
  final String type; // motor, health, life, property, travel
  final String status; // active, expired, cancelled
  final DateTime startDate;
  final DateTime endDate;
  final double premium;
  final String? holderName;

  InsurancePolicy({
    required this.id,
    required this.policyNumber,
    required this.insurerName,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.premium,
    this.holderName,
  });

  factory InsurancePolicy.fromJson(Map<String, dynamic> json) {
    return InsurancePolicy(
      id: _parseInt(json['id']),
      policyNumber: json['policy_number'] ?? '',
      insurerName: json['insurer_name'] ?? '',
      type: json['type'] ?? 'motor',
      status: json['status'] ?? 'active',
      startDate:
          DateTime.tryParse('${json['start_date']}') ?? DateTime.now(),
      endDate: DateTime.tryParse('${json['end_date']}') ?? DateTime.now(),
      premium: _parseDouble(json['premium']),
      holderName: json['holder_name'],
    );
  }

  bool get isExpired => endDate.isBefore(DateTime.now());
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
}

// ─── Insurer ──────────────────────────────────────────────────

class Insurer {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? website;
  final double rating;
  final List<String> products;

  Insurer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.website,
    required this.rating,
    this.products = const [],
  });

  factory Insurer.fromJson(Map<String, dynamic> json) {
    return Insurer(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      website: json['website'],
      rating: _parseDouble(json['rating']),
      products:
          (json['products'] as List?)?.map((e) => '$e').toList() ?? [],
    );
  }
}

// ─── TIRA Complaint ───────────────────────────────────────────

class TiraComplaint {
  final int id;
  final String insurerName;
  final String type;
  final String description;
  final String status;
  final DateTime createdAt;

  TiraComplaint({
    required this.id,
    required this.insurerName,
    required this.type,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory TiraComplaint.fromJson(Map<String, dynamic> json) {
    return TiraComplaint(
      id: _parseInt(json['id']),
      insurerName: json['insurer_name'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'submitted',
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
    );
  }
}
