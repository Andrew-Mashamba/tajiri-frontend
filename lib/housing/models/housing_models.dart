// lib/housing/models/housing_models.dart
import 'package:flutter/material.dart';

// ─── Property Type ─────────────────────────────────────────────

enum PropertyType {
  apartment,
  house,
  room,
  land,
  office;

  String get displayName {
    switch (this) {
      case PropertyType.apartment: return 'Fleti';
      case PropertyType.house: return 'Nyumba';
      case PropertyType.room: return 'Chumba';
      case PropertyType.land: return 'Kiwanja';
      case PropertyType.office: return 'Ofisi';
    }
  }

  String get subtitle {
    switch (this) {
      case PropertyType.apartment: return 'Apartment';
      case PropertyType.house: return 'House';
      case PropertyType.room: return 'Room';
      case PropertyType.land: return 'Land';
      case PropertyType.office: return 'Office';
    }
  }

  IconData get icon {
    switch (this) {
      case PropertyType.apartment: return Icons.apartment_rounded;
      case PropertyType.house: return Icons.home_rounded;
      case PropertyType.room: return Icons.single_bed_rounded;
      case PropertyType.land: return Icons.landscape_rounded;
      case PropertyType.office: return Icons.business_rounded;
    }
  }

  static PropertyType fromString(String? s) {
    return PropertyType.values.firstWhere(
      (v) => v.name == s,
      orElse: () => PropertyType.house,
    );
  }
}

// ─── Price Frequency ───────────────────────────────────────────

enum PriceFrequency {
  monthly,
  yearly,
  sale;

  String get displayName {
    switch (this) {
      case PriceFrequency.monthly: return 'Kwa Mwezi';
      case PriceFrequency.yearly: return 'Kwa Mwaka';
      case PriceFrequency.sale: return 'Kuuza';
    }
  }

  String get subtitle {
    switch (this) {
      case PriceFrequency.monthly: return '/month';
      case PriceFrequency.yearly: return '/year';
      case PriceFrequency.sale: return 'For Sale';
    }
  }

  static PriceFrequency fromString(String? s) {
    switch (s) {
      case 'monthly': return PriceFrequency.monthly;
      case 'yearly': return PriceFrequency.yearly;
      case 'sale': return PriceFrequency.sale;
      default: return PriceFrequency.monthly;
    }
  }
}

// ─── Amenity ───────────────────────────────────────────────────

enum Amenity {
  parking,
  security,
  water,
  electricity,
  internet,
  garden,
  balcony,
  furnished;

  String get displayName {
    switch (this) {
      case Amenity.parking: return 'Maegesho';
      case Amenity.security: return 'Ulinzi';
      case Amenity.water: return 'Maji';
      case Amenity.electricity: return 'Umeme';
      case Amenity.internet: return 'Intaneti';
      case Amenity.garden: return 'Bustani';
      case Amenity.balcony: return 'Baraza';
      case Amenity.furnished: return 'Samani';
    }
  }

  String get subtitle {
    switch (this) {
      case Amenity.parking: return 'Parking';
      case Amenity.security: return 'Security';
      case Amenity.water: return 'Water';
      case Amenity.electricity: return 'Electricity';
      case Amenity.internet: return 'Internet';
      case Amenity.garden: return 'Garden';
      case Amenity.balcony: return 'Balcony';
      case Amenity.furnished: return 'Furnished';
    }
  }

  IconData get icon {
    switch (this) {
      case Amenity.parking: return Icons.local_parking_rounded;
      case Amenity.security: return Icons.security_rounded;
      case Amenity.water: return Icons.water_drop_rounded;
      case Amenity.electricity: return Icons.bolt_rounded;
      case Amenity.internet: return Icons.wifi_rounded;
      case Amenity.garden: return Icons.park_rounded;
      case Amenity.balcony: return Icons.balcony_rounded;
      case Amenity.furnished: return Icons.chair_rounded;
    }
  }

  static Amenity? fromString(String? s) {
    if (s == null) return null;
    return Amenity.values.firstWhere(
      (v) => v.name == s,
      orElse: () => Amenity.water,
    );
  }
}

// ─── Tanzania Regions ──────────────────────────────────────────

class TzRegion {
  static const List<String> regions = [
    'Dar es Salaam', 'Arusha', 'Dodoma', 'Mwanza', 'Mbeya',
    'Morogoro', 'Tanga', 'Zanzibar', 'Kilimanjaro', 'Iringa',
    'Kagera', 'Lindi', 'Mara', 'Mtwara', 'Pwani', 'Rukwa',
    'Ruvuma', 'Shinyanga', 'Singida', 'Tabora', 'Kigoma',
    'Songwe', 'Geita', 'Katavi', 'Njombe', 'Simiyu',
  ];
}

// ─── Property ──────────────────────────────────────────────────

class Property {
  final int id;
  final String title;
  final PropertyType type;
  final double price;
  final PriceFrequency priceFrequency;
  final int? bedrooms;
  final int? bathrooms;
  final double? areaSqm;
  final String location;
  final String? address;
  final String? description;
  final List<String> photos;
  final List<Amenity> amenities;
  final String? agentName;
  final String? agentPhone;
  final bool isAvailable;
  final DateTime? createdAt;
  final bool isFeatured;

  Property({
    required this.id,
    required this.title,
    required this.type,
    required this.price,
    required this.priceFrequency,
    this.bedrooms,
    this.bathrooms,
    this.areaSqm,
    required this.location,
    this.address,
    this.description,
    this.photos = const [],
    this.amenities = const [],
    this.agentName,
    this.agentPhone,
    this.isAvailable = true,
    this.createdAt,
    this.isFeatured = false,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      type: PropertyType.fromString(json['type']),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      priceFrequency: PriceFrequency.fromString(json['price_frequency']),
      bedrooms: (json['bedrooms'] as num?)?.toInt(),
      bathrooms: (json['bathrooms'] as num?)?.toInt(),
      areaSqm: (json['area_sqm'] as num?)?.toDouble(),
      location: json['location'] ?? '',
      address: json['address'],
      description: json['description'],
      photos: (json['photos'] as List?)?.cast<String>() ?? [],
      amenities: (json['amenities'] as List?)
              ?.map((a) => Amenity.fromString(a as String?))
              .whereType<Amenity>()
              .toList() ??
          [],
      agentName: json['agent_name'],
      agentPhone: json['agent_phone'],
      isAvailable: json['is_available'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      isFeatured: json['is_featured'] ?? false,
    );
  }

  String get priceFormatted {
    final p = _fmtAmount(price);
    if (priceFrequency == PriceFrequency.sale) return 'TZS $p';
    return 'TZS $p${priceFrequency.subtitle}';
  }

  static String _fmtAmount(double amount) {
    if (amount >= 1000000000) return '${(amount / 1000000000).toStringAsFixed(1)}B';
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }
}

// ─── Rental Payment ────────────────────────────────────────────

enum RentalPaymentStatus {
  paid,
  pending,
  overdue;

  String get displayName {
    switch (this) {
      case RentalPaymentStatus.paid: return 'Imelipwa';
      case RentalPaymentStatus.pending: return 'Inasubiri';
      case RentalPaymentStatus.overdue: return 'Imechelewa';
    }
  }

  Color get color {
    switch (this) {
      case RentalPaymentStatus.paid: return const Color(0xFF4CAF50);
      case RentalPaymentStatus.pending: return Colors.orange;
      case RentalPaymentStatus.overdue: return Colors.red;
    }
  }

  static RentalPaymentStatus fromString(String? s) {
    switch (s) {
      case 'paid': return RentalPaymentStatus.paid;
      case 'pending': return RentalPaymentStatus.pending;
      case 'overdue': return RentalPaymentStatus.overdue;
      default: return RentalPaymentStatus.pending;
    }
  }
}

class RentalPayment {
  final int id;
  final int propertyId;
  final double amount;
  final DateTime date;
  final RentalPaymentStatus status;
  final String? reference;
  final String? month;

  RentalPayment({
    required this.id,
    required this.propertyId,
    required this.amount,
    required this.date,
    required this.status,
    this.reference,
    this.month,
  });

  factory RentalPayment.fromJson(Map<String, dynamic> json) {
    return RentalPayment(
      id: json['id'] ?? 0,
      propertyId: json['property_id'] ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      status: RentalPaymentStatus.fromString(json['status']),
      reference: json['reference'],
      month: json['month'],
    );
  }
}

// ─── My Rental ─────────────────────────────────────────────────

class MyRental {
  final int id;
  final Property property;
  final DateTime leaseStart;
  final DateTime leaseEnd;
  final double monthlyRent;
  final List<RentalPayment> payments;

  MyRental({
    required this.id,
    required this.property,
    required this.leaseStart,
    required this.leaseEnd,
    required this.monthlyRent,
    this.payments = const [],
  });

  factory MyRental.fromJson(Map<String, dynamic> json) {
    return MyRental(
      id: json['id'] ?? 0,
      property: Property.fromJson(json['property'] ?? {}),
      leaseStart: DateTime.parse(json['lease_start'] ?? DateTime.now().toIso8601String()),
      leaseEnd: DateTime.parse(json['lease_end'] ?? DateTime.now().toIso8601String()),
      monthlyRent: (json['monthly_rent'] as num?)?.toDouble() ?? 0,
      payments: (json['payments'] as List?)
              ?.map((p) => RentalPayment.fromJson(p))
              .toList() ??
          [],
    );
  }

  int get daysRemaining => leaseEnd.difference(DateTime.now()).inDays;
}

// ─── Result wrappers ───────────────────────────────────────────

class HousingResult<T> {
  final bool success;
  final T? data;
  final String? message;
  HousingResult({required this.success, this.data, this.message});
}

class HousingListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  HousingListResult({required this.success, this.items = const [], this.message});
}
