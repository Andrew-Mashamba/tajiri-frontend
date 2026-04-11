// lib/vehicle/models/vehicle_models.dart
import 'package:flutter/material.dart';

// ─── Fuel Type ─────────────────────────────────────────────────

enum FuelType {
  petrol,
  diesel,
  electric,
  hybrid;

  String get displayName {
    switch (this) {
      case FuelType.petrol: return 'Petroli';
      case FuelType.diesel: return 'Dizeli';
      case FuelType.electric: return 'Umeme';
      case FuelType.hybrid: return 'Mseto';
    }
  }

  String get subtitle {
    switch (this) {
      case FuelType.petrol: return 'Petrol';
      case FuelType.diesel: return 'Diesel';
      case FuelType.electric: return 'Electric';
      case FuelType.hybrid: return 'Hybrid';
    }
  }

  static FuelType fromString(String? s) {
    return FuelType.values.firstWhere(
      (v) => v.name == s,
      orElse: () => FuelType.petrol,
    );
  }
}

// ─── Service Type ──────────────────────────────────────────────

enum ServiceType {
  oilChange,
  tireRotation,
  brakeService,
  fullService,
  inspection,
  repair,
  other;

  String get displayName {
    switch (this) {
      case ServiceType.oilChange: return 'Mafuta ya Injini';
      case ServiceType.tireRotation: return 'Matairi';
      case ServiceType.brakeService: return 'Breki';
      case ServiceType.fullService: return 'Huduma Kamili';
      case ServiceType.inspection: return 'Ukaguzi';
      case ServiceType.repair: return 'Matengenezo';
      case ServiceType.other: return 'Nyingine';
    }
  }

  String get subtitle {
    switch (this) {
      case ServiceType.oilChange: return 'Oil Change';
      case ServiceType.tireRotation: return 'Tire Rotation';
      case ServiceType.brakeService: return 'Brake Service';
      case ServiceType.fullService: return 'Full Service';
      case ServiceType.inspection: return 'Inspection';
      case ServiceType.repair: return 'Repair';
      case ServiceType.other: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceType.oilChange: return Icons.oil_barrel_rounded;
      case ServiceType.tireRotation: return Icons.tire_repair_rounded;
      case ServiceType.brakeService: return Icons.speed_rounded;
      case ServiceType.fullService: return Icons.build_rounded;
      case ServiceType.inspection: return Icons.search_rounded;
      case ServiceType.repair: return Icons.handyman_rounded;
      case ServiceType.other: return Icons.more_horiz_rounded;
    }
  }

  static ServiceType fromString(String? s) {
    return ServiceType.values.firstWhere(
      (v) => v.name == s,
      orElse: () => ServiceType.other,
    );
  }
}

// ─── Vehicle ───────────────────────────────────────────────────

class Vehicle {
  final int id;
  final int userId;
  final String make;
  final String model;
  final int year;
  final String plateNumber;
  final String? color;
  final String? engineSize;
  final FuelType fuelType;
  final double? mileage;
  final int? insurancePolicyId;
  final DateTime? nextServiceDate;
  final String? photoUrl;

  Vehicle({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    required this.year,
    required this.plateNumber,
    this.color,
    this.engineSize,
    required this.fuelType,
    this.mileage,
    this.insurancePolicyId,
    this.nextServiceDate,
    this.photoUrl,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      plateNumber: json['plate_number'] ?? '',
      color: json['color'],
      engineSize: json['engine_size'],
      fuelType: FuelType.fromString(json['fuel_type']),
      mileage: (json['mileage'] as num?)?.toDouble(),
      insurancePolicyId: (json['insurance_policy_id'] as num?)?.toInt(),
      nextServiceDate: json['next_service_date'] != null
          ? DateTime.tryParse(json['next_service_date'])
          : null,
      photoUrl: json['photo_url'],
    );
  }

  String get displayName => '$make $model ($year)';

  bool get hasInsurance => insurancePolicyId != null;

  bool get serviceOverdue =>
      nextServiceDate != null && nextServiceDate!.isBefore(DateTime.now());

  int? get daysUntilService =>
      nextServiceDate?.difference(DateTime.now()).inDays;
}

// ─── Fuel Log ──────────────────────────────────────────────────

class FuelLog {
  final int id;
  final int vehicleId;
  final DateTime date;
  final double liters;
  final double pricePerLiter;
  final double totalCost;
  final double? mileage;
  final String? station;

  FuelLog({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.liters,
    required this.pricePerLiter,
    required this.totalCost,
    this.mileage,
    this.station,
  });

  factory FuelLog.fromJson(Map<String, dynamic> json) {
    return FuelLog(
      id: json['id'] ?? 0,
      vehicleId: json['vehicle_id'] ?? 0,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      liters: (json['liters'] as num?)?.toDouble() ?? 0,
      pricePerLiter: (json['price_per_liter'] as num?)?.toDouble() ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
      mileage: (json['mileage'] as num?)?.toDouble(),
      station: json['station'],
    );
  }
}

// ─── Vehicle Service Record ────────────────────────────────────

class VehicleServiceRecord {
  final int id;
  final int vehicleId;
  final ServiceType serviceType;
  final DateTime date;
  final double cost;
  final String? description;
  final DateTime? nextDue;

  VehicleServiceRecord({
    required this.id,
    required this.vehicleId,
    required this.serviceType,
    required this.date,
    required this.cost,
    this.description,
    this.nextDue,
  });

  factory VehicleServiceRecord.fromJson(Map<String, dynamic> json) {
    return VehicleServiceRecord(
      id: json['id'] ?? 0,
      vehicleId: json['vehicle_id'] ?? 0,
      serviceType: ServiceType.fromString(json['service_type']),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      description: json['description'],
      nextDue: json['next_due'] != null
          ? DateTime.tryParse(json['next_due'])
          : null,
    );
  }
}

// ─── Result wrappers ───────────────────────────────────────────

class VehicleResult<T> {
  final bool success;
  final T? data;
  final String? message;
  VehicleResult({required this.success, this.data, this.message});
}

class VehicleListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  VehicleListResult({required this.success, this.items = const [], this.message});
}
