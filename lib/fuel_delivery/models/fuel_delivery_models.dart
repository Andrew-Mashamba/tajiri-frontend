// lib/fuel_delivery/models/fuel_delivery_models.dart
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

// ─── Fuel Price ───────────────────────────────────────────────

class FuelPrice {
  final String fuelType;
  final double pricePerLiter;
  final String region;
  final DateTime effectiveDate;

  FuelPrice({
    required this.fuelType,
    required this.pricePerLiter,
    required this.region,
    required this.effectiveDate,
  });

  factory FuelPrice.fromJson(Map<String, dynamic> json) {
    return FuelPrice(
      fuelType: json['fuel_type'] ?? 'petrol',
      pricePerLiter: _parseDouble(json['price_per_liter']),
      region: json['region'] ?? '',
      effectiveDate:
          DateTime.tryParse('${json['effective_date']}') ?? DateTime.now(),
    );
  }

  String get fuelLabel {
    switch (fuelType) {
      case 'petrol':
        return 'Petrol';
      case 'diesel':
        return 'Diesel';
      case 'premium':
        return 'Premium';
      default:
        return fuelType;
    }
  }
}

// ─── Delivery Order ───────────────────────────────────────────

class FuelOrder {
  final int id;
  final int userId;
  final String fuelType;
  final double liters;
  final double pricePerLiter;
  final double deliveryFee;
  final double totalCost;
  final String status; // pending, confirmed, en_route, delivered, cancelled
  final String? deliveryAddress;
  final double? latitude;
  final double? longitude;
  final String? specialInstructions;
  final int? carId;
  final String? carName;
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final DeliveryDriver? driver;

  FuelOrder({
    required this.id,
    required this.userId,
    required this.fuelType,
    required this.liters,
    required this.pricePerLiter,
    required this.deliveryFee,
    required this.totalCost,
    required this.status,
    this.deliveryAddress,
    this.latitude,
    this.longitude,
    this.specialInstructions,
    this.carId,
    this.carName,
    this.scheduledAt,
    required this.createdAt,
    this.driver,
  });

  factory FuelOrder.fromJson(Map<String, dynamic> json) {
    return FuelOrder(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      fuelType: json['fuel_type'] ?? 'petrol',
      liters: _parseDouble(json['liters']),
      pricePerLiter: _parseDouble(json['price_per_liter']),
      deliveryFee: _parseDouble(json['delivery_fee']),
      totalCost: _parseDouble(json['total_cost']),
      status: json['status'] ?? 'pending',
      deliveryAddress: json['delivery_address'],
      latitude: json['latitude'] != null ? _parseDouble(json['latitude']) : null,
      longitude:
          json['longitude'] != null ? _parseDouble(json['longitude']) : null,
      specialInstructions: json['special_instructions'],
      carId: json['car_id'] != null ? _parseInt(json['car_id']) : null,
      carName: json['car_name'],
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse('${json['scheduled_at']}')
          : null,
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
      driver: json['driver'] != null
          ? DeliveryDriver.fromJson(json['driver'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'fuel_type': fuelType,
        'liters': liters,
        if (deliveryAddress != null) 'delivery_address': deliveryAddress,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (specialInstructions != null)
          'special_instructions': specialInstructions,
        if (carId != null) 'car_id': carId,
        if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
      };

  bool get isActive =>
      status == 'pending' || status == 'confirmed' || status == 'en_route';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'en_route':
        return 'En Route';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

// ─── Delivery Driver ──────────────────────────────────────────

class DeliveryDriver {
  final int id;
  final String name;
  final String? photoUrl;
  final double rating;
  final String? phone;
  final String? vehiclePlate;

  DeliveryDriver({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.rating,
    this.phone,
    this.vehiclePlate,
  });

  factory DeliveryDriver.fromJson(Map<String, dynamic> json) {
    final rawPhoto = json['photo_url'] as String?;
    return DeliveryDriver(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      photoUrl: rawPhoto != null ? ApiConfig.sanitizeUrl(rawPhoto) : null,
      rating: _parseDouble(json['rating']),
      phone: json['phone'],
      vehiclePlate: json['vehicle_plate'],
    );
  }
}
