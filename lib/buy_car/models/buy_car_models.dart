// lib/buy_car/models/buy_car_models.dart
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

// ─── Car Listing ──────────────────────────────────────────────

class CarListing {
  final int id;
  final int sellerId;
  final String sellerName;
  final bool sellerVerified;
  final String make;
  final String model;
  final int year;
  final double price;
  final String? currency;
  final double mileage;
  final String fuelType;
  final String transmission;
  final String? engineSize;
  final String? color;
  final String? bodyType;
  final String condition; // excellent, good, fair, poor
  final String source; // local_dealer, private, japan_import, dubai_import
  final String? auctionGrade;
  final List<String> photos;
  final String? description;
  final String? location;
  final bool isFeatured;
  final bool isSaved;
  final int viewCount;
  final DateTime createdAt;

  CarListing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.sellerVerified,
    required this.make,
    required this.model,
    required this.year,
    required this.price,
    this.currency,
    required this.mileage,
    required this.fuelType,
    required this.transmission,
    this.engineSize,
    this.color,
    this.bodyType,
    required this.condition,
    required this.source,
    this.auctionGrade,
    this.photos = const [],
    this.description,
    this.location,
    required this.isFeatured,
    required this.isSaved,
    required this.viewCount,
    required this.createdAt,
  });

  factory CarListing.fromJson(Map<String, dynamic> json) {
    final rawPhotos = (json['photos'] as List?) ?? [];
    return CarListing(
      id: _parseInt(json['id']),
      sellerId: _parseInt(json['seller_id']),
      sellerName: json['seller_name'] ?? '',
      sellerVerified: _parseBool(json['seller_verified']),
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: _parseInt(json['year']),
      price: _parseDouble(json['price']),
      currency: json['currency'] ?? 'TZS',
      mileage: _parseDouble(json['mileage']),
      fuelType: json['fuel_type'] ?? 'petrol',
      transmission: json['transmission'] ?? 'automatic',
      engineSize: json['engine_size'],
      color: json['color'],
      bodyType: json['body_type'],
      condition: json['condition'] ?? 'good',
      source: json['source'] ?? 'local_dealer',
      auctionGrade: json['auction_grade'],
      photos: rawPhotos
          .map((p) => ApiConfig.sanitizeUrl('$p') ?? '$p')
          .toList(),
      description: json['description'],
      location: json['location'],
      isFeatured: _parseBool(json['is_featured']),
      isSaved: _parseBool(json['is_saved']),
      viewCount: _parseInt(json['view_count']),
      createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
    );
  }

  String get displayName => '$make $model ($year)';
  String get thumbnailUrl => photos.isNotEmpty ? photos.first : '';

  String get sourceLabel {
    switch (source) {
      case 'japan_import':
        return 'Japan Import';
      case 'dubai_import':
        return 'Dubai Import';
      case 'local_dealer':
        return 'Local Dealer';
      case 'private':
        return 'Private Seller';
      default:
        return source;
    }
  }
}

// ─── Import Cost Calculation ──────────────────────────────────

class ImportCost {
  final double cifPrice;
  final double importDuty;
  final double exciseDuty;
  final double vat;
  final double otherFees;
  final double totalLandedCost;
  final String currency;

  ImportCost({
    required this.cifPrice,
    required this.importDuty,
    required this.exciseDuty,
    required this.vat,
    required this.otherFees,
    required this.totalLandedCost,
    required this.currency,
  });

  factory ImportCost.fromJson(Map<String, dynamic> json) {
    return ImportCost(
      cifPrice: _parseDouble(json['cif_price']),
      importDuty: _parseDouble(json['import_duty']),
      exciseDuty: _parseDouble(json['excise_duty']),
      vat: _parseDouble(json['vat']),
      otherFees: _parseDouble(json['other_fees']),
      totalLandedCost: _parseDouble(json['total_landed_cost']),
      currency: json['currency'] ?? 'TZS',
    );
  }
}

// ─── Dealer ───────────────────────────────────────────────────

class CarDealer {
  final int id;
  final String name;
  final String? logoUrl;
  final String? location;
  final double rating;
  final int listingCount;
  final bool isVerified;
  final String? phone;

  CarDealer({
    required this.id,
    required this.name,
    this.logoUrl,
    this.location,
    required this.rating,
    required this.listingCount,
    required this.isVerified,
    this.phone,
  });

  factory CarDealer.fromJson(Map<String, dynamic> json) {
    final rawLogo = json['logo_url'] as String?;
    return CarDealer(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      logoUrl: rawLogo != null ? ApiConfig.sanitizeUrl(rawLogo) : null,
      location: json['location'],
      rating: _parseDouble(json['rating']),
      listingCount: _parseInt(json['listing_count']),
      isVerified: _parseBool(json['is_verified']),
      phone: json['phone'],
    );
  }
}
