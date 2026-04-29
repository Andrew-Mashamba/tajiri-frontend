/// Spec F5 — customer-owned vehicle profile that backs the service history
/// book (auto-populated from past garage_bookings via plate match).
class CustomerVehicle {
  final int id;
  final int userId;
  final String plate;
  final String? make;
  final String? model;
  final int? year;
  final String? vin;
  final int? mileageKm;
  final String? photoUrl;
  final String? color;
  final bool isDefault;
  /// Spec line 690 — list of open OEM/dealer recall codes pulled from VIN
  /// lookup, surfaced as a warning row in the customer's vehicle profile.
  final List<String> openRecalls;
  /// AI-predicted next service kilometre (e.g. 86200) calculated from
  /// last service interval + mileage trend.
  final int? nextServiceAtKm;
  /// Predicted calendar date for the next service window.
  final DateTime? nextServiceAtDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomerVehicle({
    required this.id,
    required this.userId,
    required this.plate,
    required this.make,
    required this.model,
    required this.year,
    required this.vin,
    required this.mileageKm,
    required this.photoUrl,
    required this.color,
    required this.isDefault,
    this.openRecalls = const [],
    this.nextServiceAtKm,
    this.nextServiceAtDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerVehicle.fromJson(Map<String, dynamic> json) {
    int? p(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }
    DateTime? d(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }
    final rawRecalls = json['open_recalls'];
    return CustomerVehicle(
      id: p(json['id']) ?? 0,
      userId: p(json['user_id']) ?? 0,
      plate: json['plate']?.toString() ?? '',
      make: json['make']?.toString(),
      model: json['model']?.toString(),
      year: p(json['year']),
      vin: json['vin']?.toString(),
      mileageKm: p(json['mileage_km']),
      photoUrl: json['photo_url']?.toString(),
      color: json['color']?.toString(),
      isDefault: json['is_default'] == true,
      openRecalls: rawRecalls is List
          ? rawRecalls.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
          : const [],
      nextServiceAtKm: p(json['next_service_at_km']),
      nextServiceAtDate: d(json['next_service_at_date']),
      createdAt: d(json['created_at']),
      updatedAt: d(json['updated_at']),
    );
  }

  String get displayLabel {
    final parts = [
      if (make != null && make!.isNotEmpty) make,
      if (model != null && model!.isNotEmpty) model,
      if (year != null) '$year',
    ];
    if (parts.isEmpty) return plate;
    return '${parts.join(' ')} • $plate';
  }
}

class VehicleServiceHistoryEntry {
  final int bookingId;
  final String status;
  final String? faultSummary;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final int? costCapTzs;
  final int? finalCostTzs;
  final String? partnerName;

  VehicleServiceHistoryEntry({
    required this.bookingId,
    required this.status,
    required this.faultSummary,
    required this.completedAt,
    required this.createdAt,
    required this.costCapTzs,
    required this.finalCostTzs,
    required this.partnerName,
  });

  factory VehicleServiceHistoryEntry.fromJson(Map<String, dynamic> json) {
    DateTime? d(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    int? p(dynamic v) =>
        v == null ? null : (v is int ? v : int.tryParse(v.toString()));
    return VehicleServiceHistoryEntry(
      bookingId: p(json['id']) ?? 0,
      status: json['status']?.toString() ?? '',
      faultSummary: json['fault_summary']?.toString(),
      completedAt: d(json['completed_at']),
      createdAt: d(json['created_at']),
      costCapTzs: p(json['cost_cap_tzs']),
      finalCostTzs: p(json['final_cost_tzs']),
      partnerName: json['partner_name']?.toString(),
    );
  }
}
