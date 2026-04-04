/// TAJIRI Marketplace Models
/// Supports physical goods, digital products, and services
import '../config/api_config.dart';

// ============================================================================
// ENUMS
// ============================================================================

enum ProductType {
  physical('physical'),
  digital('digital'),
  service('service');

  final String value;
  const ProductType(this.value);

  static ProductType fromString(String? value) {
    switch (value) {
      case 'digital':
        return ProductType.digital;
      case 'service':
        return ProductType.service;
      default:
        return ProductType.physical;
    }
  }

  String get label {
    switch (this) {
      case ProductType.physical:
        return 'Bidhaa';
      case ProductType.digital:
        return 'Dijitali';
      case ProductType.service:
        return 'Huduma';
    }
  }

  String get labelEn {
    switch (this) {
      case ProductType.physical:
        return 'Physical';
      case ProductType.digital:
        return 'Digital';
      case ProductType.service:
        return 'Service';
    }
  }
}

enum ProductStatus {
  draft('draft'),
  active('active'),
  soldOut('sold_out'),
  archived('archived');

  final String value;
  const ProductStatus(this.value);

  static ProductStatus fromString(String? value) {
    switch (value) {
      case 'active':
        return ProductStatus.active;
      case 'sold_out':
        return ProductStatus.soldOut;
      case 'archived':
        return ProductStatus.archived;
      default:
        return ProductStatus.draft;
    }
  }

  String get label {
    switch (this) {
      case ProductStatus.draft:
        return 'Rasimu';
      case ProductStatus.active:
        return 'Inauzwa';
      case ProductStatus.soldOut:
        return 'Imeisha';
      case ProductStatus.archived:
        return 'Imehifadhiwa';
    }
  }
}

enum ProductCondition {
  brandNew('new'),
  used('used'),
  refurbished('refurbished');

  final String value;
  const ProductCondition(this.value);

  static ProductCondition fromString(String? value) {
    switch (value) {
      case 'used':
        return ProductCondition.used;
      case 'refurbished':
        return ProductCondition.refurbished;
      default:
        return ProductCondition.brandNew;
    }
  }

  String get label {
    switch (this) {
      case ProductCondition.brandNew:
        return 'Mpya';
      case ProductCondition.used:
        return 'Imetumika';
      case ProductCondition.refurbished:
        return 'Imefanyiwa Ukarabati';
    }
  }
}

enum OrderStatus {
  pending('pending'),
  confirmed('confirmed'),
  processing('processing'),
  shipped('shipped'),
  delivered('delivered'),
  completed('completed'),
  cancelled('cancelled'),
  refunded('refunded');

  final String value;
  const OrderStatus(this.value);

  static OrderStatus fromString(String? value) {
    switch (value) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'refunded':
        return OrderStatus.refunded;
      default:
        return OrderStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Inasubiri';
      case OrderStatus.confirmed:
        return 'Imethibitishwa';
      case OrderStatus.processing:
        return 'Inashughulikiwa';
      case OrderStatus.shipped:
        return 'Imetumwa';
      case OrderStatus.delivered:
        return 'Imepokelewa';
      case OrderStatus.completed:
        return 'Imekamilika';
      case OrderStatus.cancelled:
        return 'Imeghairiwa';
      case OrderStatus.refunded:
        return 'Imerudishiwa';
    }
  }

  bool get isActive => [pending, confirmed, processing, shipped].contains(this);
  bool get isFinal => [completed, cancelled, refunded].contains(this);
}

enum DeliveryMethod {
  pickup('pickup'),
  delivery('delivery'),
  shipping('shipping'),
  digital('digital');

  final String value;
  const DeliveryMethod(this.value);

  static DeliveryMethod fromString(String? value) {
    switch (value) {
      case 'delivery':
        return DeliveryMethod.delivery;
      case 'shipping':
        return DeliveryMethod.shipping;
      case 'digital':
        return DeliveryMethod.digital;
      default:
        return DeliveryMethod.pickup;
    }
  }

  String get label {
    switch (this) {
      case DeliveryMethod.pickup:
        return 'Kuchukua Mwenyewe';
      case DeliveryMethod.delivery:
        return 'Kupelekewa';
      case DeliveryMethod.shipping:
        return 'Kusafirishwa';
      case DeliveryMethod.digital:
        return 'Pakua Moja kwa Moja';
    }
  }
}

// ============================================================================
// PRODUCT MODELS
// ============================================================================

class Product {
  final int id;
  final int sellerId;
  final String title;
  final String? description;
  final String slug;
  final ProductType type;
  final ProductStatus status;
  final double price;
  final double? compareAtPrice;
  final String currency;
  final int stockQuantity;
  final List<String> images;
  final String? thumbnailPath;
  final int? categoryId;
  final List<String>? tags;
  final ProductCondition condition;

  // Location
  final String? locationName;
  final double? latitude;
  final double? longitude;

  // Delivery options
  final bool allowPickup;
  final bool allowDelivery;
  final bool allowShipping;
  final double? deliveryFee;
  final String? deliveryNotes;
  final String? pickupAddress;

  // Digital product
  final String? downloadUrl;
  final int? downloadLimit;

  // Service
  final int? durationMinutes;
  final String? serviceLocation;

  // Stats
  final int viewsCount;
  final int favoritesCount;
  final int ordersCount;
  final double rating;
  final int reviewsCount;

  // Relations
  final ProductSeller? seller;
  final ProductCategory? category;

  // User state
  final bool isFavorited;

  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.sellerId,
    required this.title,
    this.description,
    required this.slug,
    this.type = ProductType.physical,
    this.status = ProductStatus.active,
    required this.price,
    this.compareAtPrice,
    this.currency = 'TZS',
    this.stockQuantity = 0,
    this.images = const [],
    this.thumbnailPath,
    this.categoryId,
    this.tags,
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
    this.seller,
    this.category,
    this.isFavorited = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Helper to parse int from either int or string
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return Product(
      id: parseInt(json['id']) ?? 0,
      sellerId: parseInt(json['seller_id']) ?? parseInt(json['user_id']) ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      slug: json['slug'] ?? '',
      type: ProductType.fromString(json['type']),
      status: ProductStatus.fromString(json['status']),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      compareAtPrice: json['compare_at_price'] != null
          ? double.tryParse(json['compare_at_price'].toString())
          : null,
      currency: json['currency'] ?? 'TZS',
      stockQuantity: parseInt(json['stock_quantity']) ?? 0,
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],
      thumbnailPath: json['thumbnail_path'] ?? json['thumbnail_url'],
      categoryId: parseInt(json['category_id']),
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      condition: ProductCondition.fromString(json['condition']),
      locationName: json['location_name'],
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      allowPickup: json['allow_pickup'] ?? true,
      allowDelivery: json['allow_delivery'] ?? false,
      allowShipping: json['allow_shipping'] ?? false,
      deliveryFee: double.tryParse(json['delivery_fee']?.toString() ?? ''),
      deliveryNotes: json['delivery_notes'],
      pickupAddress: json['pickup_address'],
      downloadUrl: json['download_url'],
      downloadLimit: parseInt(json['download_limit']),
      durationMinutes: parseInt(json['duration_minutes']),
      serviceLocation: json['service_location'],
      viewsCount: parseInt(json['views_count']) ?? 0,
      favoritesCount: parseInt(json['favorites_count']) ?? 0,
      ordersCount: parseInt(json['orders_count']) ?? 0,
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      reviewsCount: parseInt(json['reviews_count']) ?? 0,
      seller: json['seller'] != null
          ? ProductSeller.fromJson(json['seller'])
          : json['user'] != null
              ? ProductSeller.fromJson(json['user'])
              : null,
      category: json['category'] != null
          ? ProductCategory.fromJson(json['category'])
          : null,
      isFavorited: json['is_favorited'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'slug': slug,
      'type': type.value,
      'status': status.value,
      'price': price,
      if (compareAtPrice != null) 'compare_at_price': compareAtPrice,
      'currency': currency,
      'stock_quantity': stockQuantity,
      'images': images,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (categoryId != null) 'category_id': categoryId,
      if (tags != null) 'tags': tags,
      'condition': condition.value,
      if (locationName != null) 'location_name': locationName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'allow_pickup': allowPickup,
      'allow_delivery': allowDelivery,
      'allow_shipping': allowShipping,
      if (deliveryFee != null) 'delivery_fee': deliveryFee,
      if (deliveryNotes != null) 'delivery_notes': deliveryNotes,
      if (pickupAddress != null) 'pickup_address': pickupAddress,
      if (downloadUrl != null) 'download_url': downloadUrl,
      if (downloadLimit != null) 'download_limit': downloadLimit,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (serviceLocation != null) 'service_location': serviceLocation,
      'views_count': viewsCount,
      'favorites_count': favoritesCount,
      'orders_count': ordersCount,
      'rating': rating,
      'reviews_count': reviewsCount,
      if (seller != null) 'seller': seller!.toJson(),
      if (category != null) 'category': category!.toJson(),
      'is_favorited': isFavorited,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
    int? id,
    int? sellerId,
    String? title,
    String? description,
    String? slug,
    ProductType? type,
    ProductStatus? status,
    double? price,
    double? compareAtPrice,
    String? currency,
    int? stockQuantity,
    List<String>? images,
    String? thumbnailPath,
    int? categoryId,
    List<String>? tags,
    ProductCondition? condition,
    String? locationName,
    double? latitude,
    double? longitude,
    bool? allowPickup,
    bool? allowDelivery,
    bool? allowShipping,
    double? deliveryFee,
    String? deliveryNotes,
    String? pickupAddress,
    String? downloadUrl,
    int? downloadLimit,
    int? durationMinutes,
    String? serviceLocation,
    int? viewsCount,
    int? favoritesCount,
    int? ordersCount,
    double? rating,
    int? reviewsCount,
    ProductSeller? seller,
    ProductCategory? category,
    bool? isFavorited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      slug: slug ?? this.slug,
      type: type ?? this.type,
      status: status ?? this.status,
      price: price ?? this.price,
      compareAtPrice: compareAtPrice ?? this.compareAtPrice,
      currency: currency ?? this.currency,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      images: images ?? this.images,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      condition: condition ?? this.condition,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      allowPickup: allowPickup ?? this.allowPickup,
      allowDelivery: allowDelivery ?? this.allowDelivery,
      allowShipping: allowShipping ?? this.allowShipping,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      downloadLimit: downloadLimit ?? this.downloadLimit,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      serviceLocation: serviceLocation ?? this.serviceLocation,
      viewsCount: viewsCount ?? this.viewsCount,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      ordersCount: ordersCount ?? this.ordersCount,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      seller: seller ?? this.seller,
      category: category ?? this.category,
      isFavorited: isFavorited ?? this.isFavorited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Computed properties
  String get thumbnailUrl => thumbnailPath != null
      ? '${ApiConfig.storageUrl}/$thumbnailPath'
      : (images.isNotEmpty ? imageUrls.first : '');

  List<String> get imageUrls =>
      images.map((img) => '${ApiConfig.storageUrl}/$img').toList();

  String get priceFormatted => '$currency ${_formatAmount(price)}';

  String get compareAtPriceFormatted => compareAtPrice != null
      ? '$currency ${_formatAmount(compareAtPrice!)}'
      : '';

  bool get hasDiscount =>
      compareAtPrice != null && compareAtPrice! > price;

  double get discountPercent => hasDiscount
      ? ((compareAtPrice! - price) / compareAtPrice! * 100)
      : 0;

  String get discountPercentFormatted =>
      hasDiscount ? '-${discountPercent.round()}%' : '';

  bool get isInStock =>
      type != ProductType.physical || stockQuantity != 0 || status == ProductStatus.active;

  bool get isDigital => type == ProductType.digital;

  bool get isService => type == ProductType.service;

  String get ratingFormatted => rating.toStringAsFixed(1);

  bool get hasLocation => latitude != null && longitude != null;

  static String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)},${(amount % 1000).toInt().toString().padLeft(3, '0')}';
    }
    return amount.toStringAsFixed(0);
  }
}

class ProductSeller {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePhotoPath;
  final double rating;
  final int totalSales;
  final int productCount;
  final bool isVerified;

  ProductSeller({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.profilePhotoPath,
    this.rating = 0.0,
    this.totalSales = 0,
    this.productCount = 0,
    this.isVerified = false,
  });

  factory ProductSeller.fromJson(Map<String, dynamic> json) {
    return ProductSeller(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'],
      profilePhotoPath: json['profile_photo_path'],
      rating: (json['rating'] ?? 0).toDouble(),
      totalSales: json['total_sales'] ?? 0,
      productCount: json['product_count'] ?? 0,
      isVerified: json['is_verified'] == true,
    );
  }

  String get fullName => '$firstName $lastName'.trim();
  String get displayName => username ?? fullName;
  String get avatarUrl => profilePhotoPath != null
      ? '${ApiConfig.storageUrl}/$profilePhotoPath'
      : '';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      if (username != null) 'username': username,
      if (profilePhotoPath != null) 'profile_photo_path': profilePhotoPath,
      'rating': rating,
      'total_sales': totalSales,
      'product_count': productCount,
      'is_verified': isVerified,
    };
  }
}

class ProductCategory {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? imagePath;
  final int? parentId;
  final int productCount;
  final List<ProductCategory>? children;

  ProductCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.imagePath,
    this.parentId,
    this.productCount = 0,
    this.children,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      icon: json['icon'],
      imagePath: json['image_path'],
      parentId: json['parent_id'],
      productCount: json['product_count'] ?? 0,
      children: json['children'] != null
          ? (json['children'] as List)
              .map((c) => ProductCategory.fromJson(c))
              .toList()
          : null,
    );
  }

  String get imageUrl => imagePath != null
      ? '${ApiConfig.storageUrl}/$imagePath'
      : '';

  bool get hasChildren => children != null && children!.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      if (icon != null) 'icon': icon,
      if (imagePath != null) 'image_path': imagePath,
      if (parentId != null) 'parent_id': parentId,
      'product_count': productCount,
      if (children != null) 'children': children!.map((c) => c.toJson()).toList(),
    };
  }
}

// ============================================================================
// ORDER MODELS
// ============================================================================

class Order {
  final int id;
  final String orderNumber;
  final int buyerId;
  final int sellerId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final String currency;
  final OrderStatus status;
  final DeliveryMethod deliveryMethod;
  final String? deliveryAddress;
  final String? deliveryNotes;
  final String? trackingNumber;
  final DateTime? estimatedDelivery;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  final Product? product;
  final OrderUser? buyer;
  final OrderUser? seller;
  final List<OrderStatusHistory>? statusHistory;

  Order({
    required this.id,
    required this.orderNumber,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.deliveryFee = 0,
    required this.totalAmount,
    this.currency = 'TZS',
    this.status = OrderStatus.pending,
    this.deliveryMethod = DeliveryMethod.pickup,
    this.deliveryAddress,
    this.deliveryNotes,
    this.trackingNumber,
    this.estimatedDelivery,
    this.cancellationReason,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
    this.product,
    this.buyer,
    this.seller,
    this.statusHistory,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['order_number'] ?? '',
      buyerId: json['buyer_id'],
      sellerId: json['seller_id'],
      productId: json['product_id'],
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['delivery_fee'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'TZS',
      status: OrderStatus.fromString(json['status']),
      deliveryMethod: DeliveryMethod.fromString(json['delivery_method']),
      deliveryAddress: json['delivery_address'],
      deliveryNotes: json['delivery_notes'],
      trackingNumber: json['tracking_number'],
      estimatedDelivery: json['estimated_delivery'] != null
          ? DateTime.parse(json['estimated_delivery'])
          : null,
      cancellationReason: json['cancellation_reason'],
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      product: json['product'] != null
          ? Product.fromJson(json['product'])
          : null,
      buyer: json['buyer'] != null
          ? OrderUser.fromJson(json['buyer'])
          : null,
      seller: json['seller'] != null
          ? OrderUser.fromJson(json['seller'])
          : null,
      statusHistory: json['status_history'] != null
          ? (json['status_history'] as List)
              .map((s) => OrderStatusHistory.fromJson(s))
              .toList()
          : null,
    );
  }

  String get totalFormatted => '$currency ${Product._formatAmount(totalAmount)}';
  String get subtotalFormatted => '$currency ${Product._formatAmount(subtotal)}';
  String get deliveryFeeFormatted => '$currency ${Product._formatAmount(deliveryFee)}';

  bool get canCancel => status == OrderStatus.pending;
  bool get canConfirm => status == OrderStatus.pending;
  bool get canShip => status == OrderStatus.confirmed || status == OrderStatus.processing;
  bool get canComplete => status == OrderStatus.delivered;
}

class OrderUser {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePhotoPath;
  final String? phoneNumber;

  OrderUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.profilePhotoPath,
    this.phoneNumber,
  });

  factory OrderUser.fromJson(Map<String, dynamic> json) {
    return OrderUser(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'],
      profilePhotoPath: json['profile_photo_path'],
      phoneNumber: json['phone_number'],
    );
  }

  String get fullName => '$firstName $lastName'.trim();
  String get displayName => username ?? fullName;
  String get avatarUrl => profilePhotoPath != null
      ? '${ApiConfig.storageUrl}/$profilePhotoPath'
      : '';
}

class OrderStatusHistory {
  final int id;
  final OrderStatus status;
  final String? note;
  final DateTime createdAt;

  OrderStatusHistory({
    required this.id,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      id: json['id'],
      status: OrderStatus.fromString(json['status']),
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// ============================================================================
// CART MODELS
// ============================================================================

class Cart {
  final List<CartItem> items;
  final double subtotal;
  final double deliveryTotal;
  final double grandTotal;
  final String currency;

  Cart({
    this.items = const [],
    this.subtotal = 0,
    this.deliveryTotal = 0,
    this.grandTotal = 0,
    this.currency = 'TZS',
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: json['items'] != null
          ? (json['items'] as List)
              .map((i) => CartItem.fromJson(i))
              .toList()
          : [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryTotal: (json['delivery_total'] ?? 0).toDouble(),
      grandTotal: (json['grand_total'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'TZS',
    );
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get subtotalFormatted => '$currency ${Product._formatAmount(subtotal)}';
  String get deliveryTotalFormatted => '$currency ${Product._formatAmount(deliveryTotal)}';
  String get grandTotalFormatted => '$currency ${Product._formatAmount(grandTotal)}';

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}

class CartItem {
  final int productId;
  final int quantity;
  final Product? product;
  final DateTime? addedAt;

  CartItem({
    required this.productId,
    required this.quantity,
    this.product,
    this.addedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['product_id'],
      quantity: json['quantity'] ?? 1,
      product: json['product'] != null
          ? Product.fromJson(json['product'])
          : null,
      addedAt: json['added_at'] != null
          ? DateTime.parse(json['added_at'])
          : null,
    );
  }

  double get lineTotal => (product?.price ?? 0) * quantity;
  String get lineTotalFormatted =>
      '${product?.currency ?? 'TZS'} ${Product._formatAmount(lineTotal)}';
}

// ============================================================================
// REVIEW MODELS
// ============================================================================

class Review {
  final int id;
  final int productId;
  final int userId;
  final int rating;
  final String? comment;
  final List<String>? images;
  final bool isVerifiedPurchase;
  final int helpfulCount;
  final bool? isHelpful;
  final DateTime createdAt;
  final ReviewUser? user;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.rating,
    this.comment,
    this.images,
    this.isVerifiedPurchase = false,
    this.helpfulCount = 0,
    this.isHelpful,
    required this.createdAt,
    this.user,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      productId: json['product_id'],
      userId: json['user_id'],
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : null,
      isVerifiedPurchase: json['is_verified_purchase'] == true,
      helpfulCount: json['helpful_count'] ?? 0,
      isHelpful: json['is_helpful'],
      createdAt: DateTime.parse(json['created_at']),
      user: json['user'] != null
          ? ReviewUser.fromJson(json['user'])
          : null,
    );
  }

  List<String> get imageUrls =>
      images?.map((img) => '${ApiConfig.storageUrl}/$img').toList() ?? [];

  bool get hasImages => images != null && images!.isNotEmpty;
}

class ReviewUser {
  final int id;
  final String firstName;
  final String lastName;
  final String? profilePhotoPath;

  ReviewUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePhotoPath,
  });

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    return ReviewUser(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profilePhotoPath: json['profile_photo_path'],
    );
  }

  String get fullName => '$firstName $lastName'.trim();
  String get avatarUrl => profilePhotoPath != null
      ? '${ApiConfig.storageUrl}/$profilePhotoPath'
      : '';
}

class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  ReviewStats({
    this.averageRating = 0,
    this.totalReviews = 0,
    this.ratingDistribution = const {},
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    final dist = <int, int>{};
    if (json['rating_distribution'] != null) {
      final rawDist = json['rating_distribution'] as Map<String, dynamic>;
      rawDist.forEach((key, value) {
        dist[int.parse(key)] = value as int;
      });
    }

    return ReviewStats(
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      ratingDistribution: dist,
    );
  }

  int getCountForRating(int rating) => ratingDistribution[rating] ?? 0;

  double getPercentForRating(int rating) {
    if (totalReviews == 0) return 0;
    return (getCountForRating(rating) / totalReviews) * 100;
  }
}

// ============================================================================
// RESULT CLASSES
// ============================================================================

class ProductListResult {
  final bool success;
  final List<Product> products;
  final PaginationMeta? meta;
  final String? message;

  ProductListResult({
    required this.success,
    this.products = const [],
    this.meta,
    this.message,
  });
}

class ProductResult {
  final bool success;
  final Product? product;
  final String? message;

  ProductResult({
    required this.success,
    this.product,
    this.message,
  });
}

class CategoryListResult {
  final bool success;
  final List<ProductCategory> categories;
  final String? message;

  CategoryListResult({
    required this.success,
    this.categories = const [],
    this.message,
  });
}

class CartResult {
  final bool success;
  final Cart? cart;
  final String? message;

  CartResult({
    required this.success,
    this.cart,
    this.message,
  });
}

class OrderListResult {
  final bool success;
  final List<Order> orders;
  final PaginationMeta? meta;
  final String? message;

  OrderListResult({
    required this.success,
    this.orders = const [],
    this.meta,
    this.message,
  });
}

class OrderResult {
  final bool success;
  final Order? order;
  final String? message;

  OrderResult({
    required this.success,
    this.order,
    this.message,
  });
}

class ReviewListResult {
  final bool success;
  final List<Review> reviews;
  final ReviewStats? stats;
  final PaginationMeta? meta;
  final String? message;

  ReviewListResult({
    required this.success,
    this.reviews = const [],
    this.stats,
    this.meta,
    this.message,
  });
}

class ReviewResult {
  final bool success;
  final Review? review;
  final String? message;

  ReviewResult({
    required this.success,
    this.review,
    this.message,
  });
}

class PaginationMeta {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  PaginationMeta({
    this.currentPage = 1,
    this.perPage = 20,
    this.total = 0,
    this.lastPage = 1,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      total: json['total'] ?? 0,
      lastPage: json['last_page'] ?? 1,
    );
  }

  bool get hasMore => currentPage < lastPage;
}

class PromoCodeResult {
  final bool success;
  final double? discount;
  final String? description;
  final String? message;
  const PromoCodeResult({required this.success, this.discount, this.description, this.message});
}
