// lib/spare_parts/models/spare_parts_models.dart
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

// ─── Part Condition ───────────────────────────────────────────

enum PartCondition {
  newGenuine,
  newAftermarket,
  usedA,
  usedB,
  usedC;

  String get label {
    switch (this) {
      case newGenuine: return 'New OEM';
      case newAftermarket: return 'Aftermarket';
      case usedA: return 'Used A';
      case usedB: return 'Used B';
      case usedC: return 'Used C';
    }
  }

  static PartCondition fromString(String? s) {
    return PartCondition.values.firstWhere(
      (v) => v.name == s || v.label == s,
      orElse: () => PartCondition.newAftermarket,
    );
  }
}

// ─── Spare Part ───────────────────────────────────────────────

class SparePart {
  final int id;
  final int sellerId;
  final String name;
  final String? partNumber;
  final String category;
  final String? make;
  final String? model;
  final int? yearFrom;
  final int? yearTo;
  final PartCondition condition;
  final double price;
  final List<String> photos;
  final int stock;
  final int warrantyDays;
  final String? description;
  final int counterfeitReports;

  SparePart({
    required this.id,
    required this.sellerId,
    required this.name,
    this.partNumber,
    this.category = 'general',
    this.make,
    this.model,
    this.yearFrom,
    this.yearTo,
    this.condition = PartCondition.newAftermarket,
    this.price = 0,
    this.photos = const [],
    this.stock = 1,
    this.warrantyDays = 0,
    this.description,
    this.counterfeitReports = 0,
  });

  factory SparePart.fromJson(Map<String, dynamic> json) {
    return SparePart(
      id: _parseInt(json['id']),
      sellerId: _parseInt(json['seller_id']),
      name: json['name'] ?? '',
      partNumber: json['part_number'],
      category: json['category'] ?? 'general',
      make: json['make'],
      model: json['model'],
      yearFrom: json['year_from'] != null ? _parseInt(json['year_from']) : null,
      yearTo: json['year_to'] != null ? _parseInt(json['year_to']) : null,
      condition: PartCondition.fromString(json['condition']),
      price: _parseDouble(json['price']),
      photos: (json['photos'] as List?)
              ?.map((p) => _imageUrl(p) ?? '')
              .where((p) => p.isNotEmpty)
              .toList() ??
          [],
      stock: _parseInt(json['stock'], 1),
      warrantyDays: _parseInt(json['warranty_days']),
      description: json['description'],
      counterfeitReports: _parseInt(json['counterfeit_reports']),
    );
  }

  bool get isFlagged => counterfeitReports > 2;
}

// ─── Parts Seller ─────────────────────────────────────────────

enum SellerType {
  dealer,
  importer,
  individual;

  static SellerType fromString(String? s) {
    return SellerType.values.firstWhere(
      (v) => v.name == s,
      orElse: () => SellerType.individual,
    );
  }
}

class PartsSeller {
  final int id;
  final int userId;
  final String name;
  final SellerType type;
  final String? location;
  final double rating;
  final int salesCount;
  final bool verified;
  final List<String> specializations;
  final String? returnPolicy;

  PartsSeller({
    required this.id,
    required this.userId,
    required this.name,
    this.type = SellerType.individual,
    this.location,
    this.rating = 0,
    this.salesCount = 0,
    this.verified = false,
    this.specializations = const [],
    this.returnPolicy,
  });

  factory PartsSeller.fromJson(Map<String, dynamic> json) {
    return PartsSeller(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      name: json['name'] ?? '',
      type: SellerType.fromString(json['type']),
      location: json['location'] is Map
          ? json['location']['name']
          : json['location']?.toString(),
      rating: _parseDouble(json['rating']),
      salesCount: _parseInt(json['sales_count']),
      verified: _parseBool(json['verified']),
      specializations:
          (json['specializations'] as List?)?.cast<String>() ?? [],
      returnPolicy: json['return_policy'],
    );
  }
}

// ─── Parts Order ──────────────────────────────────────────────

enum OrderStatus {
  confirmed,
  shipped,
  delivered,
  cancelled;

  static OrderStatus fromString(String? s) {
    return OrderStatus.values.firstWhere(
      (v) => v.name == s,
      orElse: () => OrderStatus.confirmed,
    );
  }
}

class PartsOrder {
  final int id;
  final int buyerId;
  final int sellerId;
  final String? sellerName;
  final List<OrderItem> items;
  final double totalCost;
  final String deliveryOption;
  final double deliveryFee;
  final OrderStatus status;
  final DateTime? createdAt;

  PartsOrder({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    this.sellerName,
    this.items = const [],
    this.totalCost = 0,
    this.deliveryOption = 'pickup',
    this.deliveryFee = 0,
    this.status = OrderStatus.confirmed,
    this.createdAt,
  });

  factory PartsOrder.fromJson(Map<String, dynamic> json) {
    return PartsOrder(
      id: _parseInt(json['id']),
      buyerId: _parseInt(json['buyer_id']),
      sellerId: _parseInt(json['seller_id']),
      sellerName: json['seller_name'],
      items: (json['items'] as List?)
              ?.map((i) => OrderItem.fromJson(i))
              .toList() ??
          [],
      totalCost: _parseDouble(json['total_cost']),
      deliveryOption: json['delivery_option'] ?? 'pickup',
      deliveryFee: _parseDouble(json['delivery_fee']),
      status: OrderStatus.fromString(json['status']),
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
    );
  }
}

class OrderItem {
  final int partId;
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.partId,
    required this.name,
    this.quantity = 1,
    this.price = 0,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      partId: _parseInt(json['part_id']),
      name: json['name'] ?? '',
      quantity: _parseInt(json['quantity'], 1),
      price: _parseDouble(json['price']),
    );
  }
}
