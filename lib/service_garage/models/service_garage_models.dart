// lib/service_garage/models/service_garage_models.dart
import '../../config/api_config.dart';

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
double _parseDouble(dynamic v) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
bool _parseBool(dynamic v) =>
    v == true || v == 1 || v == '1' || v == 'true';

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

// ─── Garage ───────────────────────────────────────────────────

class Garage {
  final int id;
  final String name;
  final String? photoUrl;
  final String? address;
  final String? phone;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final List<String> specializations;
  final List<String> services;
  final String? operatingHours;
  final bool acceptsInsurance;
  final bool hasMobileService;
  final double? distanceKm;

  Garage({
    required this.id,
    required this.name,
    this.photoUrl,
    this.address,
    this.phone,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    this.specializations = const [],
    this.services = const [],
    this.operatingHours,
    required this.acceptsInsurance,
    required this.hasMobileService,
    this.distanceKm,
  });

  factory Garage.fromJson(Map<String, dynamic> json) {
    final rawPhoto = json['photo_url'] as String?;
    return Garage(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      photoUrl: rawPhoto != null ? ApiConfig.sanitizeUrl(rawPhoto) : null,
      address: json['address'],
      phone: json['phone'],
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      rating: _parseDouble(json['rating']),
      reviewCount: _parseInt(json['review_count']),
      isVerified: _parseBool(json['is_verified']),
      specializations:
          (json['specializations'] as List?)?.cast<String>() ?? [],
      services: (json['services'] as List?)?.cast<String>() ?? [],
      operatingHours: json['operating_hours'],
      acceptsInsurance: _parseBool(json['accepts_insurance']),
      hasMobileService: _parseBool(json['has_mobile_service']),
      distanceKm: json['distance_km'] != null
          ? _parseDouble(json['distance_km'])
          : null,
    );
  }
}

// ─── Service Booking ──────────────────────────────────────────

class ServiceBooking {
  final int id;
  final int garageId;
  final String garageName;
  final int? carId;
  final String? carName;
  final String serviceType;
  final String? description;
  final String status; // pending, confirmed, in_progress, completed, cancelled
  final DateTime appointmentDate;
  final double? estimatedCost;
  final double? actualCost;
  final String? mechanicName;
  final DateTime createdAt;

  ServiceBooking({
    required this.id,
    required this.garageId,
    required this.garageName,
    this.carId,
    this.carName,
    required this.serviceType,
    this.description,
    required this.status,
    required this.appointmentDate,
    this.estimatedCost,
    this.actualCost,
    this.mechanicName,
    required this.createdAt,
  });

  factory ServiceBooking.fromJson(Map<String, dynamic> json) {
    return ServiceBooking(
      id: _parseInt(json['id']),
      garageId: _parseInt(json['garage_id']),
      garageName: json['garage_name'] ?? '',
      carId: json['car_id'] != null ? _parseInt(json['car_id']) : null,
      carName: json['car_name'],
      serviceType: json['service_type'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'pending',
      appointmentDate:
          DateTime.tryParse('${json['appointment_date']}') ?? DateTime.now(),
      estimatedCost: json['estimated_cost'] != null
          ? _parseDouble(json['estimated_cost'])
          : null,
      actualCost: json['actual_cost'] != null
          ? _parseDouble(json['actual_cost'])
          : null,
      mechanicName: json['mechanic_name'],
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'garage_id': garageId,
        'service_type': serviceType,
        if (carId != null) 'car_id': carId,
        if (description != null) 'description': description,
        'appointment_date': appointmentDate.toIso8601String(),
      };

  bool get isActive =>
      status == 'pending' || status == 'confirmed' || status == 'in_progress';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

// ─── Garage Review ────────────────────────────────────────────

class GarageReview {
  final int id;
  final int garageId;
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  GarageReview({
    required this.id,
    required this.garageId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory GarageReview.fromJson(Map<String, dynamic> json) {
    final rawPhoto = json['user_photo_url'] as String?;
    return GarageReview(
      id: _parseInt(json['id']),
      garageId: _parseInt(json['garage_id']),
      userName: json['user_name'] ?? '',
      userPhotoUrl: rawPhoto != null ? ApiConfig.sanitizeUrl(rawPhoto) : null,
      rating: _parseDouble(json['rating']),
      comment: json['comment'],
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
    );
  }
}
