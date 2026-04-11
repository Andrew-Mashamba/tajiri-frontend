// lib/sell_car/models/sell_car_models.dart
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

// ─── Sell Listing ─────────────────────────────────────────────

class SellListing {
  final int id;
  final int userId;
  final String make;
  final String model;
  final int year;
  final double price;
  final double mileage;
  final String fuelType;
  final String transmission;
  final String? engineSize;
  final String? color;
  final String condition;
  final String? description;
  final List<String> photos;
  final List<String> features;
  final String status; // draft, active, paused, sold, expired
  final int viewCount;
  final int inquiryCount;
  final int saveCount;
  final bool hasInspection;
  final double? suggestedPrice;
  final String? location;
  final DateTime createdAt;
  final DateTime? expiresAt;

  SellListing({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    required this.year,
    required this.price,
    required this.mileage,
    required this.fuelType,
    required this.transmission,
    this.engineSize,
    this.color,
    required this.condition,
    this.description,
    this.photos = const [],
    this.features = const [],
    required this.status,
    required this.viewCount,
    required this.inquiryCount,
    required this.saveCount,
    required this.hasInspection,
    this.suggestedPrice,
    this.location,
    required this.createdAt,
    this.expiresAt,
  });

  factory SellListing.fromJson(Map<String, dynamic> json) {
    final rawPhotos = (json['photos'] as List?) ?? [];
    return SellListing(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: _parseInt(json['year']),
      price: _parseDouble(json['price']),
      mileage: _parseDouble(json['mileage']),
      fuelType: json['fuel_type'] ?? 'petrol',
      transmission: json['transmission'] ?? 'automatic',
      engineSize: json['engine_size'],
      color: json['color'],
      condition: json['condition'] ?? 'good',
      description: json['description'],
      photos: rawPhotos
          .map((p) => ApiConfig.sanitizeUrl('$p') ?? '$p')
          .toList(),
      features: (json['features'] as List?)?.cast<String>() ?? [],
      status: json['status'] ?? 'draft',
      viewCount: _parseInt(json['view_count']),
      inquiryCount: _parseInt(json['inquiry_count']),
      saveCount: _parseInt(json['save_count']),
      hasInspection: _parseBool(json['has_inspection']),
      suggestedPrice: json['suggested_price'] != null
          ? _parseDouble(json['suggested_price'])
          : null,
      location: json['location'],
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse('${json['expires_at']}')
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'make': make,
        'model': model,
        'year': year,
        'price': price,
        'mileage': mileage,
        'fuel_type': fuelType,
        'transmission': transmission,
        'condition': condition,
        if (engineSize != null) 'engine_size': engineSize,
        if (color != null) 'color': color,
        if (description != null) 'description': description,
        if (features.isNotEmpty) 'features': features,
        if (location != null) 'location': location,
      };

  String get displayName => '$make $model ($year)';
  String get thumbnailUrl => photos.isNotEmpty ? photos.first : '';
  bool get isActive => status == 'active';
}

// ─── Offer ────────────────────────────────────────────────────

class SellOffer {
  final int id;
  final int listingId;
  final int buyerId;
  final String buyerName;
  final bool buyerVerified;
  final double amount;
  final String? message;
  final String status; // pending, accepted, rejected, countered
  final DateTime createdAt;

  SellOffer({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.buyerName,
    required this.buyerVerified,
    required this.amount,
    this.message,
    required this.status,
    required this.createdAt,
  });

  factory SellOffer.fromJson(Map<String, dynamic> json) {
    return SellOffer(
      id: _parseInt(json['id']),
      listingId: _parseInt(json['listing_id']),
      buyerId: _parseInt(json['buyer_id']),
      buyerName: json['buyer_name'] ?? '',
      buyerVerified: _parseBool(json['buyer_verified']),
      amount: _parseDouble(json['amount']),
      message: json['message'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
    );
  }
}

// ─── Price Suggestion ─────────────────────────────────────────

class PriceSuggestion {
  final double quickSalePrice;
  final double fairPrice;
  final double optimisticPrice;
  final int comparableListings;

  PriceSuggestion({
    required this.quickSalePrice,
    required this.fairPrice,
    required this.optimisticPrice,
    required this.comparableListings,
  });

  factory PriceSuggestion.fromJson(Map<String, dynamic> json) {
    return PriceSuggestion(
      quickSalePrice: _parseDouble(json['quick_sale_price']),
      fairPrice: _parseDouble(json['fair_price']),
      optimisticPrice: _parseDouble(json['optimistic_price']),
      comparableListings: _parseInt(json['comparable_listings']),
    );
  }
}
