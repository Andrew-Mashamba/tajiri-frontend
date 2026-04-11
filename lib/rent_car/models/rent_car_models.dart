// lib/rent_car/models/rent_car_models.dart
import '../../config/api_config.dart';

// ─── Helpers ───────────────────────────────────────────────────

int _parseInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double _parseDouble(dynamic v, [double fallback = 0.0]) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

bool _parseBool(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return fallback;
}

String? _imageUrl(dynamic v) {
  if (v == null) return null;
  return ApiConfig.sanitizeUrl(v.toString());
}

// ─── Result wrappers ──────────────────────────────────────────

class SingleResult<T> {
  final bool success;
  final T? data;
  final String? message;
  SingleResult({required this.success, this.data, this.message});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final String? message;
  PaginatedResult({
    required this.success,
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.message,
  });
}

// ─── Vehicle Category ─────────────────────────────────────────

enum VehicleCategory {
  sedan,
  suv,
  fourByFour,
  van,
  luxury,
  bus,
  safari;

  String get label {
    switch (this) {
      case sedan: return 'Sedan';
      case suv: return 'SUV';
      case fourByFour: return '4x4';
      case van: return 'Van';
      case luxury: return 'Luxury';
      case bus: return 'Bus';
      case safari: return 'Safari';
    }
  }

  static VehicleCategory fromString(String? s) {
    return VehicleCategory.values.firstWhere(
      (v) => v.name == s || v.label.toLowerCase() == s?.toLowerCase(),
      orElse: () => VehicleCategory.sedan,
    );
  }
}

// ─── Rental Vehicle ───────────────────────────────────────────

class RentalVehicle {
  final int id;
  final int hostId;
  final String make;
  final String model;
  final int year;
  final VehicleCategory category;
  final int seats;
  final String transmission;
  final String fuelType;
  final List<String> photos;
  final double dailyRate;
  final double weeklyRate;
  final double monthlyRate;
  final String mileagePolicy;
  final String fuelPolicy;
  final double rating;
  final int reviewCount;
  final String? location;
  final bool isActive;

  RentalVehicle({
    required this.id,
    required this.hostId,
    required this.make,
    required this.model,
    required this.year,
    required this.category,
    this.seats = 5,
    this.transmission = 'automatic',
    this.fuelType = 'petrol',
    this.photos = const [],
    this.dailyRate = 0,
    this.weeklyRate = 0,
    this.monthlyRate = 0,
    this.mileagePolicy = 'unlimited',
    this.fuelPolicy = 'full-to-full',
    this.rating = 0,
    this.reviewCount = 0,
    this.location,
    this.isActive = true,
  });

  factory RentalVehicle.fromJson(Map<String, dynamic> json) {
    return RentalVehicle(
      id: _parseInt(json['id']),
      hostId: _parseInt(json['host_id']),
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: _parseInt(json['year'], 2020),
      category: VehicleCategory.fromString(json['category']),
      seats: _parseInt(json['seats'], 5),
      transmission: json['transmission'] ?? 'automatic',
      fuelType: json['fuel_type'] ?? 'petrol',
      photos: (json['photos'] as List?)
              ?.map((p) => _imageUrl(p) ?? '')
              .where((p) => p.isNotEmpty)
              .toList() ??
          [],
      dailyRate: _parseDouble(json['daily_rate']),
      weeklyRate: _parseDouble(json['weekly_rate']),
      monthlyRate: _parseDouble(json['monthly_rate']),
      mileagePolicy: json['mileage_policy'] ?? 'unlimited',
      fuelPolicy: json['fuel_policy'] ?? 'full-to-full',
      rating: _parseDouble(json['rating']),
      reviewCount: _parseInt(json['review_count']),
      location: json['location'] is Map
          ? json['location']['name']
          : json['location']?.toString(),
      isActive: _parseBool(json['is_active'], true),
    );
  }

  String get title => '$make $model ($year)';
}

// ─── Rental Booking ───────────────────────────────────────────

enum BookingStatus {
  pending,
  confirmed,
  active,
  returned,
  completed,
  cancelled;

  static BookingStatus fromString(String? s) {
    return BookingStatus.values.firstWhere(
      (v) => v.name == s,
      orElse: () => BookingStatus.pending,
    );
  }
}

class RentalBooking {
  final int id;
  final int vehicleId;
  final int renterId;
  final String? vehicleTitle;
  final String? vehiclePhoto;
  final DateTime? pickupDate;
  final DateTime? returnDate;
  final String? pickupLocation;
  final String? returnLocation;
  final String insuranceTier;
  final double totalCost;
  final double deposit;
  final BookingStatus status;
  final DateTime? createdAt;

  RentalBooking({
    required this.id,
    required this.vehicleId,
    required this.renterId,
    this.vehicleTitle,
    this.vehiclePhoto,
    this.pickupDate,
    this.returnDate,
    this.pickupLocation,
    this.returnLocation,
    this.insuranceTier = 'basic',
    this.totalCost = 0,
    this.deposit = 0,
    this.status = BookingStatus.pending,
    this.createdAt,
  });

  factory RentalBooking.fromJson(Map<String, dynamic> json) {
    return RentalBooking(
      id: _parseInt(json['id']),
      vehicleId: _parseInt(json['vehicle_id']),
      renterId: _parseInt(json['renter_id']),
      vehicleTitle: json['vehicle_title'],
      vehiclePhoto: _imageUrl(json['vehicle_photo']),
      pickupDate: DateTime.tryParse(json['pickup_date'] ?? ''),
      returnDate: DateTime.tryParse(json['return_date'] ?? ''),
      pickupLocation: json['pickup_location']?.toString(),
      returnLocation: json['return_location']?.toString(),
      insuranceTier: json['insurance_tier'] ?? 'basic',
      totalCost: _parseDouble(json['total_cost']),
      deposit: _parseDouble(json['deposit']),
      status: BookingStatus.fromString(json['status']),
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
    );
  }
}

// ─── Chauffeur ────────────────────────────────────────────────

class Chauffeur {
  final int id;
  final String name;
  final String? photo;
  final int experienceYears;
  final List<String> languages;
  final double rating;
  final bool isSafariGuide;
  final bool isAvailable;

  Chauffeur({
    required this.id,
    required this.name,
    this.photo,
    this.experienceYears = 0,
    this.languages = const [],
    this.rating = 0,
    this.isSafariGuide = false,
    this.isAvailable = true,
  });

  factory Chauffeur.fromJson(Map<String, dynamic> json) {
    return Chauffeur(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      photo: _imageUrl(json['photo']),
      experienceYears: _parseInt(json['experience_years']),
      languages: (json['languages'] as List?)?.cast<String>() ?? [],
      rating: _parseDouble(json['rating']),
      isSafariGuide: _parseBool(json['safari_guide']),
      isAvailable: _parseBool(json['is_available'], true),
    );
  }
}
