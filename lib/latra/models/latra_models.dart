// lib/latra/models/latra_models.dart

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

// ─── Fare Result ──────────────────────────────────────────────

class FareResult {
  final String origin;
  final String destination;
  final String vehicleType; // daladala, bajaji, bodaboda, bus
  final double approvedFare;
  final double? distance;

  FareResult({
    required this.origin,
    required this.destination,
    required this.vehicleType,
    required this.approvedFare,
    this.distance,
  });

  factory FareResult.fromJson(Map<String, dynamic> json) {
    return FareResult(
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      vehicleType: json['vehicle_type'] ?? 'daladala',
      approvedFare: _parseDouble(json['approved_fare']),
      distance:
          json['distance'] != null ? _parseDouble(json['distance']) : null,
    );
  }
}

// ─── Complaint ────────────────────────────────────────────────

class LatraComplaint {
  final int id;
  final String type; // overcharging, reckless, harassment, other
  final String description;
  final String? plateNumber;
  final String? routeName;
  final String status; // submitted, reviewing, resolved
  final DateTime createdAt;

  LatraComplaint({
    required this.id,
    required this.type,
    required this.description,
    this.plateNumber,
    this.routeName,
    required this.status,
    required this.createdAt,
  });

  factory LatraComplaint.fromJson(Map<String, dynamic> json) {
    return LatraComplaint(
      id: _parseInt(json['id']),
      type: json['type'] ?? 'other',
      description: json['description'] ?? '',
      plateNumber: json['plate_number'],
      routeName: json['route_name'],
      status: json['status'] ?? 'submitted',
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'description': description,
        if (plateNumber != null) 'plate_number': plateNumber,
        if (routeName != null) 'route_name': routeName,
      };
}

// ─── Operator ─────────────────────────────────────────────────

class TransportOperator {
  final int id;
  final String name;
  final String licenceNumber;
  final String vehicleType;
  final String status; // active, suspended, expired
  final String? route;
  final DateTime? expiryDate;

  TransportOperator({
    required this.id,
    required this.name,
    required this.licenceNumber,
    required this.vehicleType,
    required this.status,
    this.route,
    this.expiryDate,
  });

  factory TransportOperator.fromJson(Map<String, dynamic> json) {
    return TransportOperator(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      licenceNumber: json['licence_number'] ?? '',
      vehicleType: json['vehicle_type'] ?? '',
      status: json['status'] ?? 'active',
      route: json['route'],
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse('${json['expiry_date']}')
          : null,
    );
  }
}
