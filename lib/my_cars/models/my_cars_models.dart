// lib/my_cars/models/my_cars_models.dart
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

// ─── Car ───────────────────────────────────────────────────────

class Car {
  final int id;
  final int userId;
  final String make;
  final String model;
  final int year;
  final String plateNumber;
  final String? color;
  final String? engineSize;
  final String? vinNumber;
  final String fuelType;
  final double mileage;
  final String? photoUrl;
  final bool hasInsurance;
  final DateTime? insuranceExpiry;
  final DateTime? nextServiceDate;
  final DateTime? roadLicenseExpiry;
  final double totalExpenses;
  final DateTime createdAt;

  Car({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    required this.year,
    required this.plateNumber,
    this.color,
    this.engineSize,
    this.vinNumber,
    required this.fuelType,
    required this.mileage,
    this.photoUrl,
    required this.hasInsurance,
    this.insuranceExpiry,
    this.nextServiceDate,
    this.roadLicenseExpiry,
    required this.totalExpenses,
    required this.createdAt,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    final rawPhoto = json['photo_url'] as String?;
    return Car(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: _parseInt(json['year']),
      plateNumber: json['plate_number'] ?? '',
      color: json['color'],
      engineSize: json['engine_size'],
      vinNumber: json['vin_number'],
      fuelType: json['fuel_type'] ?? 'petrol',
      mileage: _parseDouble(json['mileage']),
      photoUrl: rawPhoto != null ? ApiConfig.sanitizeUrl(rawPhoto) : null,
      hasInsurance: _parseBool(json['has_insurance']),
      insuranceExpiry: json['insurance_expiry'] != null
          ? DateTime.tryParse('${json['insurance_expiry']}')
          : null,
      nextServiceDate: json['next_service_date'] != null
          ? DateTime.tryParse('${json['next_service_date']}')
          : null,
      roadLicenseExpiry: json['road_license_expiry'] != null
          ? DateTime.tryParse('${json['road_license_expiry']}')
          : null,
      totalExpenses: _parseDouble(json['total_expenses']),
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'make': make,
        'model': model,
        'year': year,
        'plate_number': plateNumber,
        if (color != null) 'color': color,
        if (engineSize != null) 'engine_size': engineSize,
        if (vinNumber != null) 'vin_number': vinNumber,
        'fuel_type': fuelType,
        'mileage': mileage,
      };

  String get displayName => '$make $model ($year)';

  bool get serviceOverdue =>
      nextServiceDate != null && nextServiceDate!.isBefore(DateTime.now());

  int? get daysUntilService =>
      nextServiceDate?.difference(DateTime.now()).inDays;

  int? get daysUntilInsurance =>
      insuranceExpiry?.difference(DateTime.now()).inDays;
}

// ─── Car Document ─────────────────────────────────────────────

class CarDocument {
  final int id;
  final int carId;
  final String type;
  final String? title;
  final String? fileUrl;
  final DateTime? expiryDate;
  final DateTime createdAt;

  CarDocument({
    required this.id,
    required this.carId,
    required this.type,
    this.title,
    this.fileUrl,
    this.expiryDate,
    required this.createdAt,
  });

  factory CarDocument.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['file_url'] as String?;
    return CarDocument(
      id: _parseInt(json['id']),
      carId: _parseInt(json['car_id']),
      type: json['type'] ?? 'other',
      title: json['title'],
      fileUrl: rawUrl != null ? ApiConfig.sanitizeUrl(rawUrl) : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse('${json['expiry_date']}')
          : null,
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
    );
  }

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  int? get daysUntilExpiry =>
      expiryDate?.difference(DateTime.now()).inDays;
}

// ─── Service Record ────────────────────────────────────────────

class CarServiceRecord {
  final int id;
  final int carId;
  final String serviceType;
  final String? description;
  final double cost;
  final double mileageAtService;
  final String? garageName;
  final DateTime date;
  final DateTime? nextDue;

  CarServiceRecord({
    required this.id,
    required this.carId,
    required this.serviceType,
    this.description,
    required this.cost,
    required this.mileageAtService,
    this.garageName,
    required this.date,
    this.nextDue,
  });

  factory CarServiceRecord.fromJson(Map<String, dynamic> json) {
    return CarServiceRecord(
      id: _parseInt(json['id']),
      carId: _parseInt(json['car_id']),
      serviceType: json['service_type'] ?? 'other',
      description: json['description'],
      cost: _parseDouble(json['cost']),
      mileageAtService: _parseDouble(json['mileage_at_service']),
      garageName: json['garage_name'],
      date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
      nextDue: json['next_due'] != null
          ? DateTime.tryParse('${json['next_due']}')
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'service_type': serviceType,
        if (description != null) 'description': description,
        'cost': cost,
        'mileage_at_service': mileageAtService,
        if (garageName != null) 'garage_name': garageName,
        if (nextDue != null) 'next_due': nextDue!.toIso8601String(),
      };
}

// ─── Fuel Log ──────────────────────────────────────────────────

class CarFuelLog {
  final int id;
  final int carId;
  final DateTime date;
  final double liters;
  final double pricePerLiter;
  final double totalCost;
  final double? mileage;
  final String? station;
  final String fuelType;

  CarFuelLog({
    required this.id,
    required this.carId,
    required this.date,
    required this.liters,
    required this.pricePerLiter,
    required this.totalCost,
    this.mileage,
    this.station,
    required this.fuelType,
  });

  factory CarFuelLog.fromJson(Map<String, dynamic> json) {
    return CarFuelLog(
      id: _parseInt(json['id']),
      carId: _parseInt(json['car_id']),
      date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
      liters: _parseDouble(json['liters']),
      pricePerLiter: _parseDouble(json['price_per_liter']),
      totalCost: _parseDouble(json['total_cost']),
      mileage: json['mileage'] != null ? _parseDouble(json['mileage']) : null,
      station: json['station'],
      fuelType: json['fuel_type'] ?? 'petrol',
    );
  }

  Map<String, dynamic> toJson() => {
        'liters': liters,
        'price_per_liter': pricePerLiter,
        'total_cost': totalCost,
        'fuel_type': fuelType,
        if (mileage != null) 'mileage': mileage,
        if (station != null) 'station': station,
      };
}
