// lib/hair_nails/models/hair_nails_models.dart
import 'package:flutter/material.dart';

// ─── Hair Type ─────────────────────────────────────────────────

enum HairType {
  straight1,
  wavy2,
  curly3a,
  curly3b,
  curly3c,
  coily4a,
  coily4b,
  coily4c;

  String get displayName {
    switch (this) {
      case HairType.straight1: return 'Nyofu (1)';
      case HairType.wavy2: return 'Mawimbi (2)';
      case HairType.curly3a: return 'Mviringano 3A';
      case HairType.curly3b: return 'Mviringano 3B';
      case HairType.curly3c: return 'Mviringano 3C';
      case HairType.coily4a: return 'Nywele za Afrika 4A';
      case HairType.coily4b: return 'Nywele za Afrika 4B';
      case HairType.coily4c: return 'Nywele za Afrika 4C';
    }
  }

  String get shortLabel {
    switch (this) {
      case HairType.straight1: return '1';
      case HairType.wavy2: return '2';
      case HairType.curly3a: return '3A';
      case HairType.curly3b: return '3B';
      case HairType.curly3c: return '3C';
      case HairType.coily4a: return '4A';
      case HairType.coily4b: return '4B';
      case HairType.coily4c: return '4C';
    }
  }

  String get description {
    switch (this) {
      case HairType.straight1: return 'Nywele zilizonyooka kabisa';
      case HairType.wavy2: return 'Nywele zenye mawimbi kidogo';
      case HairType.curly3a: return 'Mviringano laini, kama "S"';
      case HairType.curly3b: return 'Mviringano wa kati';
      case HairType.curly3c: return 'Mviringano mkali, nywele nzito';
      case HairType.coily4a: return 'Nywele za Afrika zenye mduara laini';
      case HairType.coily4b: return 'Nywele za Afrika zenye zigzag';
      case HairType.coily4c: return 'Nywele za Afrika zilizosongana sana';
    }
  }

  IconData get icon {
    switch (this) {
      case HairType.straight1: return Icons.horizontal_rule_rounded;
      case HairType.wavy2: return Icons.waves_rounded;
      case HairType.curly3a:
      case HairType.curly3b:
      case HairType.curly3c: return Icons.loop_rounded;
      case HairType.coily4a:
      case HairType.coily4b:
      case HairType.coily4c: return Icons.blur_circular_rounded;
    }
  }

  static HairType fromString(String? s) {
    return HairType.values.firstWhere((v) => v.name == s, orElse: () => HairType.coily4a);
  }
}

// ─── Hair State ────────────────────────────────────────────────

enum HairState {
  natural,
  relaxed,
  transitioning,
  colorTreated,
  locced;

  String get displayName {
    switch (this) {
      case HairState.natural: return 'Asili (Natural)';
      case HairState.relaxed: return 'Relaxed';
      case HairState.transitioning: return 'Kubadilika (Transitioning)';
      case HairState.colorTreated: return 'Rangi (Color Treated)';
      case HairState.locced: return 'Dreadlocks';
    }
  }

  IconData get icon {
    switch (this) {
      case HairState.natural: return Icons.eco_rounded;
      case HairState.relaxed: return Icons.straighten_rounded;
      case HairState.transitioning: return Icons.autorenew_rounded;
      case HairState.colorTreated: return Icons.palette_rounded;
      case HairState.locced: return Icons.link_rounded;
    }
  }

  static HairState fromString(String? s) {
    return HairState.values.firstWhere((v) => v.name == s, orElse: () => HairState.natural);
  }
}

// ─── Porosity ──────────────────────────────────────────────────

enum Porosity {
  low,
  normal,
  high;

  String get displayName {
    switch (this) {
      case Porosity.low: return 'Chini (Low)';
      case Porosity.normal: return 'Wastani (Normal)';
      case Porosity.high: return 'Juu (High)';
    }
  }

  String get tip {
    switch (this) {
      case Porosity.low: return 'Nywele zako hazichukui maji haraka. Tumia mafuta mazito na joto la mvuke.';
      case Porosity.normal: return 'Nywele zako zinachukua unyevu vizuri. Endelea na utaratibu wako.';
      case Porosity.high: return 'Nywele zako zinapoteza unyevu haraka. Tumia leave-in conditioner na sili kufunga.';
    }
  }

  static Porosity fromString(String? s) {
    return Porosity.values.firstWhere((v) => v.name == s, orElse: () => Porosity.normal);
  }
}

// ─── Density ───────────────────────────────────────────────────

enum HairDensity {
  thin,
  medium,
  thick;

  String get displayName {
    switch (this) {
      case HairDensity.thin: return 'Nyembamba';
      case HairDensity.medium: return 'Wastani';
      case HairDensity.thick: return 'Nzito';
    }
  }

  static HairDensity fromString(String? s) {
    return HairDensity.values.firstWhere((v) => v.name == s, orElse: () => HairDensity.medium);
  }
}

// ─── Style Category ────────────────────────────────────────────

enum StyleCategory {
  braids,
  twists,
  locs,
  weaves,
  natural,
  updos,
  nails;

  String get displayName {
    switch (this) {
      case StyleCategory.braids: return 'Misuko';
      case StyleCategory.twists: return 'Twists';
      case StyleCategory.locs: return 'Dreadlocks';
      case StyleCategory.weaves: return 'Weave';
      case StyleCategory.natural: return 'Asili';
      case StyleCategory.updos: return 'Mtindo wa Juu';
      case StyleCategory.nails: return 'Kucha';
    }
  }

  IconData get icon {
    switch (this) {
      case StyleCategory.braids: return Icons.auto_awesome_rounded;
      case StyleCategory.twists: return Icons.loop_rounded;
      case StyleCategory.locs: return Icons.link_rounded;
      case StyleCategory.weaves: return Icons.layers_rounded;
      case StyleCategory.natural: return Icons.eco_rounded;
      case StyleCategory.updos: return Icons.arrow_upward_rounded;
      case StyleCategory.nails: return Icons.back_hand_rounded;
    }
  }

  static StyleCategory fromString(String? s) {
    return StyleCategory.values.firstWhere((v) => v.name == s, orElse: () => StyleCategory.braids);
  }
}

// ─── Service Category ──────────────────────────────────────────

enum ServiceCategory {
  hair,
  nails,
  skin;

  String get displayName {
    switch (this) {
      case ServiceCategory.hair: return 'Nywele';
      case ServiceCategory.nails: return 'Kucha';
      case ServiceCategory.skin: return 'Ngozi';
    }
  }

  static ServiceCategory fromString(String? s) {
    return ServiceCategory.values.firstWhere((v) => v.name == s, orElse: () => ServiceCategory.hair);
  }
}

// ─── Booking Status ────────────────────────────────────────────

enum BookingStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case BookingStatus.pending: return 'Inasubiri';
      case BookingStatus.confirmed: return 'Imethibitishwa';
      case BookingStatus.completed: return 'Imekamilika';
      case BookingStatus.cancelled: return 'Imefutwa';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.pending: return Colors.orange;
      case BookingStatus.confirmed: return const Color(0xFF4CAF50);
      case BookingStatus.completed: return const Color(0xFF1A1A1A);
      case BookingStatus.cancelled: return Colors.red;
    }
  }

  static BookingStatus fromString(String? s) {
    return BookingStatus.values.firstWhere((v) => v.name == s, orElse: () => BookingStatus.pending);
  }
}

// ─── Payment Status ────────────────────────────────────────────

enum PaymentStatus {
  unpaid,
  deposit,
  paid;

  String get displayName {
    switch (this) {
      case PaymentStatus.unpaid: return 'Haijalipwa';
      case PaymentStatus.deposit: return 'Amana';
      case PaymentStatus.paid: return 'Imelipwa';
    }
  }

  static PaymentStatus fromString(String? s) {
    return PaymentStatus.values.firstWhere((v) => v.name == s, orElse: () => PaymentStatus.unpaid);
  }
}

// ─── Hair Profile ──────────────────────────────────────────────

class HairProfile {
  final int id;
  final int userId;
  final HairType hairType;
  final Porosity porosity;
  final HairDensity density;
  final double? lengthCm;
  final HairState currentState;
  final String? scalpCondition;
  final List<String> goals;

  HairProfile({
    required this.id,
    required this.userId,
    required this.hairType,
    this.porosity = Porosity.normal,
    this.density = HairDensity.medium,
    this.lengthCm,
    this.currentState = HairState.natural,
    this.scalpCondition,
    this.goals = const [],
  });

  factory HairProfile.fromJson(Map<String, dynamic> json) => HairProfile(
        id: json['id'] ?? 0,
        userId: json['user_id'] ?? 0,
        hairType: HairType.fromString(json['hair_type']),
        porosity: Porosity.fromString(json['porosity']),
        density: HairDensity.fromString(json['density']),
        lengthCm: (json['length_cm'] as num?)?.toDouble(),
        currentState: HairState.fromString(json['current_state']),
        scalpCondition: json['scalp_condition'],
        goals: (json['goals'] as List?)?.cast<String>() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'hair_type': hairType.name,
        'porosity': porosity.name,
        'density': density.name,
        'length_cm': lengthCm,
        'current_state': currentState.name,
        'scalp_condition': scalpCondition,
        'goals': goals,
      };
}

// ─── Salon ─────────────────────────────────────────────────────

class Salon {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final double rating;
  final int totalReviews;
  final String? imageUrl;
  final List<String> photos;
  final bool isHomeBased;
  final bool isMobile;
  final bool isVerified;
  final bool isWalkIn;
  final String? openingHours;
  final String? description;
  final List<SalonService> services;
  final List<SalonStaff> staff;

  Salon({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.rating = 0,
    this.totalReviews = 0,
    this.imageUrl,
    this.photos = const [],
    this.isHomeBased = false,
    this.isMobile = false,
    this.isVerified = false,
    this.isWalkIn = true,
    this.openingHours,
    this.description,
    this.services = const [],
    this.staff = const [],
  });

  factory Salon.fromJson(Map<String, dynamic> json) => Salon(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        address: json['address'],
        phone: json['phone'],
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
        imageUrl: json['image_url'],
        photos: (json['photos'] as List?)?.cast<String>() ?? [],
        isHomeBased: json['is_home_based'] ?? false,
        isMobile: json['is_mobile'] ?? false,
        isVerified: json['is_verified'] ?? false,
        isWalkIn: json['is_walk_in'] ?? true,
        openingHours: json['opening_hours'],
        description: json['description'],
        services: (json['services'] as List?)?.map((s) => SalonService.fromJson(s)).toList() ?? [],
        staff: (json['staff'] as List?)?.map((s) => SalonStaff.fromJson(s)).toList() ?? [],
      );

  double get minPrice {
    if (services.isEmpty) return 0;
    return services.map((s) => s.price).reduce((a, b) => a < b ? a : b);
  }

  double get maxPrice {
    if (services.isEmpty) return 0;
    return services.map((s) => s.price).reduce((a, b) => a > b ? a : b);
  }
}

// ─── Salon Service ─────────────────────────────────────────────

class SalonService {
  final int id;
  final int salonId;
  final ServiceCategory category;
  final String name;
  final double price;
  final int durationMinutes;
  final String? description;

  SalonService({
    required this.id,
    required this.salonId,
    required this.category,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.description,
  });

  factory SalonService.fromJson(Map<String, dynamic> json) => SalonService(
        id: json['id'] ?? 0,
        salonId: json['salon_id'] ?? 0,
        category: ServiceCategory.fromString(json['category']),
        name: json['name'] ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
        description: json['description'],
      );
}

// ─── Salon Staff ───────────────────────────────────────────────

class SalonStaff {
  final int id;
  final String name;
  final String? photoUrl;
  final String? specialty;
  final int experienceYears;

  SalonStaff({required this.id, required this.name, this.photoUrl, this.specialty, this.experienceYears = 0});

  factory SalonStaff.fromJson(Map<String, dynamic> json) => SalonStaff(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        photoUrl: json['photo_url'],
        specialty: json['specialty'],
        experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      );
}

// ─── Booking ───────────────────────────────────────────────────

class Booking {
  final int id;
  final int userId;
  final int salonId;
  final String salonName;
  final int serviceId;
  final String serviceName;
  final DateTime dateTime;
  final BookingStatus status;
  final double totalAmount;
  final PaymentStatus paymentStatus;
  final String? notes;
  final String? salonImageUrl;

  Booking({
    required this.id,
    required this.userId,
    required this.salonId,
    required this.salonName,
    required this.serviceId,
    required this.serviceName,
    required this.dateTime,
    required this.status,
    required this.totalAmount,
    this.paymentStatus = PaymentStatus.unpaid,
    this.notes,
    this.salonImageUrl,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] ?? 0,
        userId: json['user_id'] ?? 0,
        salonId: json['salon_id'] ?? 0,
        salonName: json['salon_name'] ?? '',
        serviceId: json['service_id'] ?? 0,
        serviceName: json['service_name'] ?? '',
        dateTime: DateTime.parse(json['date_time'] ?? DateTime.now().toIso8601String()),
        status: BookingStatus.fromString(json['status']),
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
        paymentStatus: PaymentStatus.fromString(json['payment_status']),
        notes: json['notes'],
        salonImageUrl: json['salon_image_url'],
      );

  bool get isUpcoming => status == BookingStatus.pending || status == BookingStatus.confirmed;
  bool get isPast => status == BookingStatus.completed || status == BookingStatus.cancelled;
}

// ─── Style Inspiration ─────────────────────────────────────────

class StyleInspiration {
  final int id;
  final String title;
  final StyleCategory category;
  final String? imageUrl;
  final String? description;
  final double? estimatedPrice;
  final int? estimatedDurationMinutes;
  final List<HairType> hairTypeRecommended;
  final bool isSaved;

  StyleInspiration({
    required this.id,
    required this.title,
    required this.category,
    this.imageUrl,
    this.description,
    this.estimatedPrice,
    this.estimatedDurationMinutes,
    this.hairTypeRecommended = const [],
    this.isSaved = false,
  });

  factory StyleInspiration.fromJson(Map<String, dynamic> json) => StyleInspiration(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        category: StyleCategory.fromString(json['category']),
        imageUrl: json['image_url'],
        description: json['description'],
        estimatedPrice: (json['estimated_price'] as num?)?.toDouble(),
        estimatedDurationMinutes: (json['estimated_duration_minutes'] as num?)?.toInt(),
        hairTypeRecommended: (json['hair_type_recommended'] as List?)?.map((h) => HairType.fromString(h)).toList() ?? [],
        isSaved: json['is_saved'] ?? false,
      );

  String get durationLabel {
    if (estimatedDurationMinutes == null) return '';
    if (estimatedDurationMinutes! >= 60) {
      final hours = estimatedDurationMinutes! ~/ 60;
      final mins = estimatedDurationMinutes! % 60;
      return mins > 0 ? '${hours}saa ${mins}dk' : '${hours}saa';
    }
    return '${estimatedDurationMinutes}dk';
  }
}

// ─── Growth Log ────────────────────────────────────────────────

class GrowthLog {
  final int id;
  final int userId;
  final DateTime date;
  final double lengthCm;
  final String? photoUrl;
  final String? notes;

  GrowthLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.lengthCm,
    this.photoUrl,
    this.notes,
  });

  factory GrowthLog.fromJson(Map<String, dynamic> json) => GrowthLog(
        id: json['id'] ?? 0,
        userId: json['user_id'] ?? 0,
        date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
        lengthCm: (json['length_cm'] as num?)?.toDouble() ?? 0,
        photoUrl: json['photo_url'],
        notes: json['notes'],
      );
}

// ─── Nail Log ──────────────────────────────────────────────────

class NailLog {
  final int id;
  final int userId;
  final DateTime date;
  final String serviceType;
  final String? notes;

  NailLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.serviceType,
    this.notes,
  });

  factory NailLog.fromJson(Map<String, dynamic> json) => NailLog(
        id: json['id'] ?? 0,
        userId: json['user_id'] ?? 0,
        date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
        serviceType: json['service_type'] ?? '',
        notes: json['notes'],
      );
}

// ─── Salon Review ──────────────────────────────────────────────

class SalonReview {
  final int id;
  final int userId;
  final String userName;
  final String? userPhotoUrl;
  final int salonId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  SalonReview({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.salonId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory SalonReview.fromJson(Map<String, dynamic> json) => SalonReview(
        id: json['id'] ?? 0,
        userId: json['user_id'] ?? 0,
        userName: json['user_name'] ?? '',
        userPhotoUrl: json['user_photo_url'],
        salonId: json['salon_id'] ?? 0,
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        comment: json['comment'],
        createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      );
}

// ─── Result Wrappers ───────────────────────────────────────────

class HairNailsResult<T> {
  final bool success;
  final T? data;
  final String? message;
  HairNailsResult({required this.success, this.data, this.message});
}

class HairNailsListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  HairNailsListResult({required this.success, this.items = const [], this.message});
}
