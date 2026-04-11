// lib/transport/models/transport_models.dart
import 'package:flutter/material.dart';

// ─── Vehicle Types ─────────────────────────────────────────────

enum VehicleType {
  car,
  bajaji,
  bodaboda,
  bus;

  String get displayName {
    switch (this) {
      case VehicleType.car: return 'Gari';
      case VehicleType.bajaji: return 'Bajaji';
      case VehicleType.bodaboda: return 'Bodaboda';
      case VehicleType.bus: return 'Basi';
    }
  }

  String get subtitle {
    switch (this) {
      case VehicleType.car: return 'Car';
      case VehicleType.bajaji: return 'Tuk-tuk';
      case VehicleType.bodaboda: return 'Motorcycle';
      case VehicleType.bus: return 'Bus';
    }
  }

  IconData get icon {
    switch (this) {
      case VehicleType.car: return Icons.directions_car_rounded;
      case VehicleType.bajaji: return Icons.electric_rickshaw_rounded;
      case VehicleType.bodaboda: return Icons.two_wheeler_rounded;
      case VehicleType.bus: return Icons.directions_bus_rounded;
    }
  }

  static VehicleType fromString(String? s) {
    return VehicleType.values.firstWhere(
      (v) => v.name == s,
      orElse: () => VehicleType.car,
    );
  }
}

// ─── Ride Status ───────────────────────────────────────────────

enum RideStatus {
  searching,
  driverFound,
  driverArriving,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case RideStatus.searching: return 'Inatafuta Dereva';
      case RideStatus.driverFound: return 'Dereva Amepatikana';
      case RideStatus.driverArriving: return 'Dereva Anakuja';
      case RideStatus.inProgress: return 'Safarini';
      case RideStatus.completed: return 'Imekamilika';
      case RideStatus.cancelled: return 'Imeghairiwa';
    }
  }

  Color get color {
    switch (this) {
      case RideStatus.searching: return Colors.orange;
      case RideStatus.driverFound: return Colors.blue;
      case RideStatus.driverArriving: return Colors.indigo;
      case RideStatus.inProgress: return Colors.teal;
      case RideStatus.completed: return const Color(0xFF4CAF50);
      case RideStatus.cancelled: return Colors.red;
    }
  }

  static RideStatus fromString(String? s) {
    switch (s) {
      case 'searching': return RideStatus.searching;
      case 'driver_found': return RideStatus.driverFound;
      case 'driver_arriving': return RideStatus.driverArriving;
      case 'in_progress': return RideStatus.inProgress;
      case 'completed': return RideStatus.completed;
      case 'cancelled': return RideStatus.cancelled;
      default: return RideStatus.searching;
    }
  }
}

// ─── Ride Request ──────────────────────────────────────────────

class RideRequest {
  final int id;
  final int userId;
  final String pickup;
  final String dropoff;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final VehicleType vehicleType;
  final double estimatedFare;
  final double? actualFare;
  final RideStatus status;
  final String? driverName;
  final String? driverPhone;
  final String? driverPhoto;
  final String? vehiclePlate;
  final int? estimatedMinutes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double? rating;

  RideRequest({
    required this.id,
    required this.userId,
    required this.pickup,
    required this.dropoff,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    required this.vehicleType,
    required this.estimatedFare,
    this.actualFare,
    required this.status,
    this.driverName,
    this.driverPhone,
    this.driverPhoto,
    this.vehiclePlate,
    this.estimatedMinutes,
    required this.createdAt,
    this.completedAt,
    this.rating,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      pickup: json['pickup'] ?? '',
      dropoff: json['dropoff'] ?? '',
      pickupLat: (json['pickup_lat'] as num?)?.toDouble(),
      pickupLng: (json['pickup_lng'] as num?)?.toDouble(),
      dropoffLat: (json['dropoff_lat'] as num?)?.toDouble(),
      dropoffLng: (json['dropoff_lng'] as num?)?.toDouble(),
      vehicleType: VehicleType.fromString(json['vehicle_type']),
      estimatedFare: (json['estimated_fare'] as num?)?.toDouble() ?? 0,
      actualFare: (json['actual_fare'] as num?)?.toDouble(),
      status: RideStatus.fromString(json['status']),
      driverName: json['driver_name'],
      driverPhone: json['driver_phone'],
      driverPhoto: json['driver_photo'],
      vehiclePlate: json['vehicle_plate'],
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  bool get isActive => [
        RideStatus.searching,
        RideStatus.driverFound,
        RideStatus.driverArriving,
        RideStatus.inProgress,
      ].contains(status);
}

// ─── Bus Route ─────────────────────────────────────────────────

class BusRoute {
  final int id;
  final String from;
  final String to;
  final String company;
  final String? companyLogo;
  final DateTime departureTime;
  final DateTime? arrivalTime;
  final double price;
  final int totalSeats;
  final int availableSeats;
  final String? busType;
  final List<String> amenities;

  BusRoute({
    required this.id,
    required this.from,
    required this.to,
    required this.company,
    this.companyLogo,
    required this.departureTime,
    this.arrivalTime,
    required this.price,
    this.totalSeats = 0,
    this.availableSeats = 0,
    this.busType,
    this.amenities = const [],
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      id: json['id'] ?? 0,
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      company: json['company'] ?? '',
      companyLogo: json['company_logo'],
      departureTime: DateTime.parse(json['departure_time'] ?? DateTime.now().toIso8601String()),
      arrivalTime: json['arrival_time'] != null ? DateTime.tryParse(json['arrival_time']) : null,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      totalSeats: (json['total_seats'] as num?)?.toInt() ?? 0,
      availableSeats: (json['available_seats'] as num?)?.toInt() ?? 0,
      busType: json['bus_type'],
      amenities: (json['amenities'] as List?)?.cast<String>() ?? [],
    );
  }

  bool get hasSeats => availableSeats > 0;

  String get durationText {
    if (arrivalTime == null) return '';
    final diff = arrivalTime!.difference(departureTime);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }
}

// ─── Trip (History) ────────────────────────────────────────────

enum TripType { ride, bus }

class Trip {
  final int id;
  final TripType type;
  final String from;
  final String to;
  final double fare;
  final DateTime date;
  final String status;
  final VehicleType? vehicleType;
  final String? company;
  final double? rating;

  Trip({
    required this.id,
    required this.type,
    required this.from,
    required this.to,
    required this.fare,
    required this.date,
    required this.status,
    this.vehicleType,
    this.company,
    this.rating,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] ?? 0,
      type: json['type'] == 'bus' ? TripType.bus : TripType.ride,
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      fare: (json['fare'] as num?)?.toDouble() ?? 0,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'completed',
      vehicleType: json['vehicle_type'] != null
          ? VehicleType.fromString(json['vehicle_type'])
          : null,
      company: json['company'],
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }
}

// ─── Bus Ticket ────────────────────────────────────────────────

class BusTicket {
  final int id;
  final String ticketId;
  final int userId;
  final int busRouteId;
  final String from;
  final String to;
  final String company;
  final DateTime departureTime;
  final String seatNumber;
  final double price;
  final String status;
  final String? passengerName;
  final String? phone;
  final DateTime createdAt;

  BusTicket({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.busRouteId,
    required this.from,
    required this.to,
    required this.company,
    required this.departureTime,
    required this.seatNumber,
    required this.price,
    required this.status,
    this.passengerName,
    this.phone,
    required this.createdAt,
  });

  factory BusTicket.fromJson(Map<String, dynamic> json) {
    return BusTicket(
      id: json['id'] ?? 0,
      ticketId: json['ticket_id'] ?? '',
      userId: json['user_id'] ?? 0,
      busRouteId: json['bus_route_id'] ?? 0,
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      company: json['company'] ?? '',
      departureTime: DateTime.parse(json['departure_time'] ?? DateTime.now().toIso8601String()),
      seatNumber: json['seat_number'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? 'active',
      passengerName: json['passenger_name'],
      phone: json['phone'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// ─── Fare Estimate ─────────────────────────────────────────────

class FareEstimate {
  final VehicleType vehicleType;
  final double estimatedFare;
  final int estimatedMinutes;
  final double distance;

  FareEstimate({
    required this.vehicleType,
    required this.estimatedFare,
    required this.estimatedMinutes,
    required this.distance,
  });

  factory FareEstimate.fromJson(Map<String, dynamic> json) {
    return FareEstimate(
      vehicleType: VehicleType.fromString(json['vehicle_type']),
      estimatedFare: (json['estimated_fare'] as num?)?.toDouble() ?? 0,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ─── Result Wrappers ───────────────────────────────────────────

class TransportResult<T> {
  final bool success;
  final T? data;
  final String? message;
  TransportResult({required this.success, this.data, this.message});
}

class TransportListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  TransportListResult({required this.success, this.items = const [], this.message});
}
