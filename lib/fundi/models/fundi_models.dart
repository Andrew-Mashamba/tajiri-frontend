// lib/fundi/models/fundi_models.dart
import 'package:flutter/material.dart';

// ─── Service Categories ────────────────────────────────────────

enum ServiceCategory {
  plumbing,
  electrical,
  carpentry,
  painting,
  cleaning,
  gardening,
  mechanic,
  mason,
  tailor,
  welding,
  aircon,
  roofing,
  other;

  String get displayName {
    switch (this) {
      case ServiceCategory.plumbing: return 'Bomba';
      case ServiceCategory.electrical: return 'Umeme';
      case ServiceCategory.carpentry: return 'Seremala';
      case ServiceCategory.painting: return 'Rangi';
      case ServiceCategory.cleaning: return 'Usafi';
      case ServiceCategory.gardening: return 'Bustani';
      case ServiceCategory.mechanic: return 'Fundi Gari';
      case ServiceCategory.mason: return 'Fundi Ujenzi';
      case ServiceCategory.tailor: return 'Mshona';
      case ServiceCategory.welding: return 'Welding';
      case ServiceCategory.aircon: return 'AC & Baridi';
      case ServiceCategory.roofing: return 'Paa';
      case ServiceCategory.other: return 'Mengineyo';
    }
  }

  String get subtitle {
    switch (this) {
      case ServiceCategory.plumbing: return 'Plumbing';
      case ServiceCategory.electrical: return 'Electrical';
      case ServiceCategory.carpentry: return 'Carpentry';
      case ServiceCategory.painting: return 'Painting';
      case ServiceCategory.cleaning: return 'Cleaning';
      case ServiceCategory.gardening: return 'Gardening';
      case ServiceCategory.mechanic: return 'Auto Mechanic';
      case ServiceCategory.mason: return 'Masonry';
      case ServiceCategory.tailor: return 'Tailoring';
      case ServiceCategory.welding: return 'Welding';
      case ServiceCategory.aircon: return 'Air Conditioning';
      case ServiceCategory.roofing: return 'Roofing';
      case ServiceCategory.other: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceCategory.plumbing: return Icons.plumbing_rounded;
      case ServiceCategory.electrical: return Icons.electrical_services_rounded;
      case ServiceCategory.carpentry: return Icons.carpenter_rounded;
      case ServiceCategory.painting: return Icons.format_paint_rounded;
      case ServiceCategory.cleaning: return Icons.cleaning_services_rounded;
      case ServiceCategory.gardening: return Icons.yard_rounded;
      case ServiceCategory.mechanic: return Icons.car_repair_rounded;
      case ServiceCategory.mason: return Icons.construction_rounded;
      case ServiceCategory.tailor: return Icons.checkroom_rounded;
      case ServiceCategory.welding: return Icons.hardware_rounded;
      case ServiceCategory.aircon: return Icons.ac_unit_rounded;
      case ServiceCategory.roofing: return Icons.roofing_rounded;
      case ServiceCategory.other: return Icons.home_repair_service_rounded;
    }
  }

  static ServiceCategory fromString(String? s) {
    return ServiceCategory.values.firstWhere(
      (v) => v.name == s,
      orElse: () => ServiceCategory.other,
    );
  }
}

// ─── Fundi Profile ─────────────────────────────────────────────

class Fundi {
  final int id;
  final int userId;
  final String name;
  final String? phone;
  final String? photoUrl;
  final List<ServiceCategory> services;
  final double rating;
  final int totalReviews;
  final int totalJobs;
  final String? location;
  final double? latitude;
  final double? longitude;
  final bool isAvailable;
  final double? hourlyRate;
  final String? bio;
  final int experienceYears;
  final bool isVerified;
  final List<String> portfolioPhotos;

  Fundi({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.photoUrl,
    this.services = const [],
    this.rating = 0,
    this.totalReviews = 0,
    this.totalJobs = 0,
    this.location,
    this.latitude,
    this.longitude,
    this.isAvailable = true,
    this.hourlyRate,
    this.bio,
    this.experienceYears = 0,
    this.isVerified = false,
    this.portfolioPhotos = const [],
  });

  factory Fundi.fromJson(Map<String, dynamic> json) {
    return Fundi(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'],
      photoUrl: json['photo_url'],
      services: (json['services'] as List?)
              ?.map((s) => ServiceCategory.fromString(s as String?))
              .toList() ??
          [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      totalJobs: (json['total_jobs'] as num?)?.toInt() ?? 0,
      location: json['location'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isAvailable: json['is_available'] ?? true,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      bio: json['bio'],
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      isVerified: json['is_verified'] ?? false,
      portfolioPhotos: (json['portfolio_photos'] as List?)?.cast<String>() ?? [],
    );
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get primaryServiceName {
    if (services.isEmpty) return 'Fundi';
    return services.first.displayName;
  }
}

// ─── Booking Status ────────────────────────────────────────────

enum BookingStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled,
  disputed;

  String get displayName {
    switch (this) {
      case BookingStatus.pending: return 'Inasubiri';
      case BookingStatus.accepted: return 'Imekubaliwa';
      case BookingStatus.inProgress: return 'Inaendelea';
      case BookingStatus.completed: return 'Imekamilika';
      case BookingStatus.cancelled: return 'Imeghairiwa';
      case BookingStatus.disputed: return 'Mzozo';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.pending: return Colors.orange;
      case BookingStatus.accepted: return Colors.blue;
      case BookingStatus.inProgress: return Colors.teal;
      case BookingStatus.completed: return const Color(0xFF4CAF50);
      case BookingStatus.cancelled: return Colors.red;
      case BookingStatus.disputed: return Colors.deepOrange;
    }
  }

  IconData get icon {
    switch (this) {
      case BookingStatus.pending: return Icons.hourglass_top_rounded;
      case BookingStatus.accepted: return Icons.check_circle_outline_rounded;
      case BookingStatus.inProgress: return Icons.engineering_rounded;
      case BookingStatus.completed: return Icons.check_circle_rounded;
      case BookingStatus.cancelled: return Icons.cancel_rounded;
      case BookingStatus.disputed: return Icons.warning_rounded;
    }
  }

  static BookingStatus fromString(String? s) {
    switch (s) {
      case 'pending': return BookingStatus.pending;
      case 'accepted': return BookingStatus.accepted;
      case 'in_progress': return BookingStatus.inProgress;
      case 'completed': return BookingStatus.completed;
      case 'cancelled': return BookingStatus.cancelled;
      case 'disputed': return BookingStatus.disputed;
      default: return BookingStatus.pending;
    }
  }
}

// ─── Fundi Booking ─────────────────────────────────────────────

class FundiBooking {
  final int id;
  final String bookingId;
  final int userId;
  final int fundiId;
  final String? fundiName;
  final String? fundiPhone;
  final String? fundiPhoto;
  final ServiceCategory service;
  final DateTime scheduledDate;
  final String? scheduledTime;
  final BookingStatus status;
  final String? description;
  final List<String> photos;
  final String? address;
  final double? estimatedCost;
  final double? actualCost;
  final String? paymentStatus;
  final double? rating;
  final String? review;
  final DateTime createdAt;

  FundiBooking({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.fundiId,
    this.fundiName,
    this.fundiPhone,
    this.fundiPhoto,
    required this.service,
    required this.scheduledDate,
    this.scheduledTime,
    required this.status,
    this.description,
    this.photos = const [],
    this.address,
    this.estimatedCost,
    this.actualCost,
    this.paymentStatus,
    this.rating,
    this.review,
    required this.createdAt,
  });

  factory FundiBooking.fromJson(Map<String, dynamic> json) {
    return FundiBooking(
      id: json['id'] ?? 0,
      bookingId: json['booking_id'] ?? '',
      userId: json['user_id'] ?? 0,
      fundiId: json['fundi_id'] ?? 0,
      fundiName: json['fundi_name'],
      fundiPhone: json['fundi_phone'],
      fundiPhoto: json['fundi_photo'],
      service: ServiceCategory.fromString(json['service']),
      scheduledDate: DateTime.parse(json['scheduled_date'] ?? DateTime.now().toIso8601String()),
      scheduledTime: json['scheduled_time'],
      status: BookingStatus.fromString(json['status']),
      description: json['description'],
      photos: (json['photos'] as List?)?.cast<String>() ?? [],
      address: json['address'],
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble(),
      actualCost: (json['actual_cost'] as num?)?.toDouble(),
      paymentStatus: json['payment_status'],
      rating: (json['rating'] as num?)?.toDouble(),
      review: json['review'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  bool get isActive => [
        BookingStatus.pending,
        BookingStatus.accepted,
        BookingStatus.inProgress,
      ].contains(status);
}

// ─── Fundi Review ──────────────────────────────────────────────

class FundiReview {
  final int id;
  final int bookingId;
  final int userId;
  final int fundiId;
  final String? userName;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  FundiReview({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.fundiId,
    this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory FundiReview.fromJson(Map<String, dynamic> json) {
    return FundiReview(
      id: json['id'] ?? 0,
      bookingId: json['booking_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      fundiId: json['fundi_id'] ?? 0,
      userName: json['user_name'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// ─── Fundi Registration ────────────────────────────────────────

class FundiRegistrationRequest {
  final String name;
  final String phone;
  final List<String> services;
  final String? location;
  final double? hourlyRate;
  final String? bio;
  final int experienceYears;
  final String? nidaNumber;

  FundiRegistrationRequest({
    required this.name,
    required this.phone,
    required this.services,
    this.location,
    this.hourlyRate,
    this.bio,
    required this.experienceYears,
    this.nidaNumber,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'services': services,
        if (location != null) 'location': location,
        if (hourlyRate != null) 'hourly_rate': hourlyRate,
        if (bio != null) 'bio': bio,
        'experience_years': experienceYears,
        if (nidaNumber != null) 'nida_number': nidaNumber,
      };
}

// ─── Result Wrappers ───────────────────────────────────────────

class FundiResult<T> {
  final bool success;
  final T? data;
  final String? message;
  FundiResult({required this.success, this.data, this.message});
}

class FundiListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  FundiListResult({required this.success, this.items = const [], this.message});
}
