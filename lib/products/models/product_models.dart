import '../../models/shop_models.dart';
import '../../config/api_config.dart';

export '../../models/shop_models.dart' show ProductType, ProductStatus, ProductCondition;

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

double _parseDouble(dynamic v, [double def = 0.0]) {
  if (v == null) return def;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? def;
}

List<String> _parseStringList(dynamic v) {
  if (v == null) return [];
  if (v is List) return v.map((e) => e.toString()).toList();
  return [];
}

class BusinessProduct {
  final int id;
  final int businessId;
  final bool isShopProduct;
  final String title;
  final String? description;
  final String? slug;
  final ProductType type;
  final ProductStatus status;
  final double price;
  final double? compareAtPrice;
  final String currency;
  final int stockQuantity;
  final List<String> images;
  final String? thumbnailPath;
  final int? categoryId;
  final String? categoryName;
  final List<String> tags;
  final ProductCondition condition;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final bool allowPickup;
  final bool allowDelivery;
  final bool allowShipping;
  final double? deliveryFee;
  final String? deliveryNotes;
  final String? pickupAddress;
  final String? downloadUrl;
  final int? downloadLimit;
  final int? durationMinutes;
  final String? serviceLocation;
  final int viewsCount;
  final int favoritesCount;
  final int ordersCount;
  final double rating;
  final int reviewsCount;
  final int viewsThisWeek;
  final int viewsLastWeek;
  final double conversionRate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BusinessProduct({
    required this.id,
    required this.businessId,
    required this.isShopProduct,
    required this.title,
    this.description,
    this.slug,
    this.type = ProductType.physical,
    this.status = ProductStatus.active,
    required this.price,
    this.compareAtPrice,
    this.currency = 'TZS',
    this.stockQuantity = 0,
    this.images = const [],
    this.thumbnailPath,
    this.categoryId,
    this.categoryName,
    this.tags = const [],
    this.condition = ProductCondition.brandNew,
    this.locationName,
    this.latitude,
    this.longitude,
    this.allowPickup = true,
    this.allowDelivery = false,
    this.allowShipping = false,
    this.deliveryFee,
    this.deliveryNotes,
    this.pickupAddress,
    this.downloadUrl,
    this.downloadLimit,
    this.durationMinutes,
    this.serviceLocation,
    this.viewsCount = 0,
    this.favoritesCount = 0,
    this.ordersCount = 0,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.viewsThisWeek = 0,
    this.viewsLastWeek = 0,
    this.conversionRate = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  factory BusinessProduct.fromShopProduct(Product p, int businessId) {
    return BusinessProduct(
      id: p.id,
      businessId: businessId,
      isShopProduct: true,
      title: p.title,
      description: p.description,
      slug: p.slug,
      type: p.type,
      status: p.status,
      price: p.price,
      compareAtPrice: p.compareAtPrice,
      currency: p.currency,
      stockQuantity: p.stockQuantity,
      images: p.images.map((img) => ApiConfig.sanitizeUrl(img) ?? img).toList(),
      thumbnailPath: p.thumbnailPath != null ? ApiConfig.sanitizeUrl(p.thumbnailPath) : null,
      categoryId: p.categoryId,
      tags: p.tags ?? [],
      condition: p.condition,
      locationName: p.locationName,
      latitude: p.latitude,
      longitude: p.longitude,
      allowPickup: p.allowPickup,
      allowDelivery: p.allowDelivery,
      allowShipping: p.allowShipping,
      deliveryFee: p.deliveryFee,
      deliveryNotes: p.deliveryNotes,
      pickupAddress: p.pickupAddress,
      downloadUrl: p.downloadUrl,
      downloadLimit: p.downloadLimit,
      durationMinutes: p.durationMinutes,
      serviceLocation: p.serviceLocation,
      viewsCount: p.viewsCount,
      favoritesCount: p.favoritesCount,
      ordersCount: p.ordersCount,
      rating: p.rating,
      reviewsCount: p.reviewsCount,
      viewsThisWeek: 0,
      viewsLastWeek: 0,
      conversionRate: 0,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    );
  }

  factory BusinessProduct.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    List<String> images = [];
    if (rawImages is List) {
      images = rawImages
          .map((e) => ApiConfig.sanitizeUrl(e.toString()) ?? e.toString())
          .toList();
    }
    return BusinessProduct(
      id: _parseInt(json['id']) ?? 0,
      businessId: _parseInt(json['user_business_id']) ?? 0,
      isShopProduct: false,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      type: ProductType.fromString(json['type']?.toString()),
      status: ProductStatus.fromString(json['status']?.toString()),
      price: _parseDouble(json['price']),
      compareAtPrice: json['compare_at_price'] != null
          ? _parseDouble(json['compare_at_price'])
          : null,
      currency: json['currency']?.toString() ?? 'TZS',
      stockQuantity: _parseInt(json['stock_quantity']) ?? 0,
      images: images,
      thumbnailPath: json['thumbnail_path'] != null
          ? ApiConfig.sanitizeUrl(json['thumbnail_path'].toString())
          : null,
      categoryId: _parseInt(json['category_id']),
      categoryName: json['category_name']?.toString() ?? json['category']?.toString(),
      tags: _parseStringList(json['tags']),
      condition: ProductCondition.fromString(json['condition']?.toString()),
      locationName: json['location_name']?.toString(),
      latitude: json['latitude'] != null ? _parseDouble(json['latitude']) : null,
      longitude: json['longitude'] != null ? _parseDouble(json['longitude']) : null,
      allowPickup: json['allow_pickup'] == true,
      allowDelivery: json['allow_delivery'] == true,
      allowShipping: json['allow_shipping'] == true,
      deliveryFee: json['delivery_fee'] != null
          ? _parseDouble(json['delivery_fee'])
          : null,
      deliveryNotes: json['delivery_notes']?.toString(),
      pickupAddress: json['pickup_address']?.toString(),
      downloadUrl: json['download_url']?.toString(),
      downloadLimit: _parseInt(json['download_limit']),
      durationMinutes: _parseInt(json['duration_minutes']),
      serviceLocation: json['service_location']?.toString(),
      viewsCount: _parseInt(json['views_count']) ?? 0,
      favoritesCount: _parseInt(json['favorites_count']) ?? 0,
      ordersCount: _parseInt(json['orders_count']) ?? 0,
      rating: _parseDouble(json['rating']),
      reviewsCount: _parseInt(json['reviews_count']) ?? 0,
      viewsThisWeek: _parseInt(json['views_this_week']) ?? 0,
      viewsLastWeek: _parseInt(json['views_last_week']) ?? 0,
      conversionRate: _parseDouble(json['conversion_rate']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case ProductStatus.active:
        return 'Active';
      case ProductStatus.draft:
        return 'Draft';
      case ProductStatus.soldOut:
        return 'Sold out';
      case ProductStatus.archived:
        return 'Archived';
    }
  }

  String get thumbnail =>
      thumbnailPath ?? (images.isNotEmpty ? images.first : '');
}
