// lib/brela/models/brela_models.dart
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
  PaginatedResult({required this.success, this.items = const [], this.message,
    this.currentPage = 1, this.lastPage = 1});
  bool get hasMore => currentPage < lastPage;
}

// ─── Business ─────────────────────────────────────────────────

class Business {
  final int id;
  final String name;
  final String type; // soleProprietorship, partnership, privateLtd, publicLtd
  final String? registrationNumber;
  final String status; // active, dormant, deregistered
  final DateTime? registeredAt;
  final String? annualReturnsDue;

  Business({
    required this.id, required this.name, required this.type,
    this.registrationNumber, required this.status,
    this.registeredAt, this.annualReturnsDue,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      registrationNumber: json['registration_number'],
      status: json['status'] ?? 'active',
      registeredAt: json['registered_at'] != null
          ? DateTime.tryParse(json['registered_at']) : null,
      annualReturnsDue: json['annual_returns_due'],
    );
  }

  bool get isActive => status == 'active';

  String get typeLabel {
    switch (type) {
      case 'soleProprietorship': return 'Biashara Binafsi';
      case 'partnership': return 'Ubia';
      case 'privateLtd': return 'Kampuni Ltd';
      case 'publicLtd': return 'Kampuni ya Umma';
      default: return type;
    }
  }
}

// ─── Name Search Result ───────────────────────────────────────

class NameResult {
  final String name;
  final bool available;
  final String? registeredBy;

  NameResult({required this.name, required this.available, this.registeredBy});

  factory NameResult.fromJson(Map<String, dynamic> json) {
    return NameResult(
      name: json['name'] ?? '',
      available: _parseBool(json['available']),
      registeredBy: json['registered_by'],
    );
  }
}

// ─── Name Reservation ────────────────────────────────────────

class NameReservation {
  final int id;
  final String name;
  final DateTime reservedAt;
  final DateTime expiresAt;
  final String status;

  NameReservation({
    required this.id, required this.name,
    required this.reservedAt, required this.expiresAt,
    required this.status,
  });

  factory NameReservation.fromJson(Map<String, dynamic> json) {
    return NameReservation(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      reservedAt: DateTime.tryParse(json['reserved_at'] ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expires_at'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'active',
    );
  }
}

// ─── Compliance Item ──────────────────────────────────────────

class ComplianceItem {
  final int id;
  final int businessId;
  final String type;
  final DateTime dueDate;
  final String status; // upcoming, due, overdue, completed

  ComplianceItem({
    required this.id, required this.businessId, required this.type,
    required this.dueDate, required this.status,
  });

  factory ComplianceItem.fromJson(Map<String, dynamic> json) {
    return ComplianceItem(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      type: json['type'] ?? '',
      dueDate: DateTime.tryParse(json['due_date'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'upcoming',
    );
  }

  bool get isOverdue => status == 'overdue';
}
