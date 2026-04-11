// lib/food/models/food_models.dart
import 'package:flutter/material.dart';

// ─── Food Categories ───────────────────────────────────────────

enum FoodCategory {
  nyamaChoma,
  pilauBiriyani,
  chipsMayai,
  ugali,
  maharage,
  samaki,
  supu,
  juice,
  chai,
  fastFood,
  maandazi,
  mishkaki,
  wali,
  ndizi,
  other;

  String get displayName {
    switch (this) {
      case FoodCategory.nyamaChoma: return 'Nyama Choma';
      case FoodCategory.pilauBiriyani: return 'Pilau & Biriyani';
      case FoodCategory.chipsMayai: return 'Chips Mayai';
      case FoodCategory.ugali: return 'Ugali';
      case FoodCategory.maharage: return 'Maharage';
      case FoodCategory.samaki: return 'Samaki';
      case FoodCategory.supu: return 'Supu';
      case FoodCategory.juice: return 'Juice';
      case FoodCategory.chai: return 'Chai';
      case FoodCategory.fastFood: return 'Fast Food';
      case FoodCategory.maandazi: return 'Maandazi & Vitumbua';
      case FoodCategory.mishkaki: return 'Mishkaki';
      case FoodCategory.wali: return 'Wali';
      case FoodCategory.ndizi: return 'Ndizi';
      case FoodCategory.other: return 'Mengineyo';
    }
  }

  String get subtitle {
    switch (this) {
      case FoodCategory.nyamaChoma: return 'Grilled Meat';
      case FoodCategory.pilauBiriyani: return 'Pilau & Biriyani';
      case FoodCategory.chipsMayai: return 'Chips Omelette';
      case FoodCategory.ugali: return 'Ugali';
      case FoodCategory.maharage: return 'Beans';
      case FoodCategory.samaki: return 'Fish';
      case FoodCategory.supu: return 'Soup';
      case FoodCategory.juice: return 'Juice';
      case FoodCategory.chai: return 'Tea';
      case FoodCategory.fastFood: return 'Fast Food';
      case FoodCategory.maandazi: return 'Donuts & Fritters';
      case FoodCategory.mishkaki: return 'Skewers';
      case FoodCategory.wali: return 'Rice';
      case FoodCategory.ndizi: return 'Plantain';
      case FoodCategory.other: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case FoodCategory.nyamaChoma: return Icons.local_fire_department_rounded;
      case FoodCategory.pilauBiriyani: return Icons.rice_bowl_rounded;
      case FoodCategory.chipsMayai: return Icons.egg_rounded;
      case FoodCategory.ugali: return Icons.breakfast_dining_rounded;
      case FoodCategory.maharage: return Icons.grain_rounded;
      case FoodCategory.samaki: return Icons.set_meal_rounded;
      case FoodCategory.supu: return Icons.soup_kitchen_rounded;
      case FoodCategory.juice: return Icons.local_drink_rounded;
      case FoodCategory.chai: return Icons.coffee_rounded;
      case FoodCategory.fastFood: return Icons.fastfood_rounded;
      case FoodCategory.maandazi: return Icons.bakery_dining_rounded;
      case FoodCategory.mishkaki: return Icons.kebab_dining_rounded;
      case FoodCategory.wali: return Icons.rice_bowl_rounded;
      case FoodCategory.ndizi: return Icons.lunch_dining_rounded;
      case FoodCategory.other: return Icons.restaurant_rounded;
    }
  }

  static FoodCategory fromString(String? s) {
    return FoodCategory.values.firstWhere(
      (v) => v.name == s,
      orElse: () => FoodCategory.other,
    );
  }
}

// ─── Restaurant ────────────────────────────────────────────────

class Restaurant {
  final int id;
  final String name;
  final String? address;
  final String? location;
  final double rating;
  final int totalReviews;
  final int deliveryTimeMinutes;
  final double minOrder;
  final String? imageUrl;
  final bool isOpen;
  final List<FoodCategory> categories;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final double deliveryFee;

  Restaurant({
    required this.id,
    required this.name,
    this.address,
    this.location,
    this.rating = 0,
    this.totalReviews = 0,
    this.deliveryTimeMinutes = 30,
    this.minOrder = 0,
    this.imageUrl,
    this.isOpen = true,
    this.categories = const [],
    this.phone,
    this.latitude,
    this.longitude,
    this.deliveryFee = 0,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'],
      location: json['location'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      deliveryTimeMinutes: (json['delivery_time_minutes'] as num?)?.toInt() ?? 30,
      minOrder: (json['min_order'] as num?)?.toDouble() ?? 0,
      imageUrl: json['image_url'],
      isOpen: json['is_open'] ?? true,
      categories: (json['categories'] as List?)
              ?.map((c) => FoodCategory.fromString(c as String?))
              .toList() ??
          [],
      phone: json['phone'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
    );
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ─── Menu Item ─────────────────────────────────────────────────

class MenuItem {
  final int id;
  final int restaurantId;
  final String name;
  final double price;
  final String? description;
  final String? imageUrl;
  final FoodCategory category;
  final bool isAvailable;
  final bool isPopular;

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    this.category = FoodCategory.other,
    this.isAvailable = true,
    this.isPopular = false,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? 0,
      restaurantId: json['restaurant_id'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      description: json['description'],
      imageUrl: json['image_url'],
      category: FoodCategory.fromString(json['category']),
      isAvailable: json['is_available'] ?? true,
      isPopular: json['is_popular'] ?? false,
    );
  }
}

// ─── Cart Item ─────────────────────────────────────────────────

class CartItem {
  final MenuItem menuItem;
  int quantity;
  final String? specialInstructions;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    this.specialInstructions,
  });

  double get total => menuItem.price * quantity;

  Map<String, dynamic> toJson() => {
        'menu_item_id': menuItem.id,
        'quantity': quantity,
        if (specialInstructions != null) 'special_instructions': specialInstructions,
      };
}

// ─── Food Order ────────────────────────────────────────────────

enum FoodOrderStatus {
  pending,
  confirmed,
  preparing,
  readyForPickup,
  onTheWay,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case FoodOrderStatus.pending: return 'Inasubiri';
      case FoodOrderStatus.confirmed: return 'Imethibitishwa';
      case FoodOrderStatus.preparing: return 'Inaandaliwa';
      case FoodOrderStatus.readyForPickup: return 'Tayari Kuchukuliwa';
      case FoodOrderStatus.onTheWay: return 'Njiani';
      case FoodOrderStatus.delivered: return 'Imefikishwa';
      case FoodOrderStatus.cancelled: return 'Imeghairiwa';
    }
  }

  Color get color {
    switch (this) {
      case FoodOrderStatus.pending: return Colors.orange;
      case FoodOrderStatus.confirmed: return Colors.blue;
      case FoodOrderStatus.preparing: return Colors.purple;
      case FoodOrderStatus.readyForPickup: return Colors.teal;
      case FoodOrderStatus.onTheWay: return Colors.indigo;
      case FoodOrderStatus.delivered: return const Color(0xFF4CAF50);
      case FoodOrderStatus.cancelled: return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case FoodOrderStatus.pending: return Icons.hourglass_top_rounded;
      case FoodOrderStatus.confirmed: return Icons.check_circle_outline_rounded;
      case FoodOrderStatus.preparing: return Icons.restaurant_rounded;
      case FoodOrderStatus.readyForPickup: return Icons.takeout_dining_rounded;
      case FoodOrderStatus.onTheWay: return Icons.delivery_dining_rounded;
      case FoodOrderStatus.delivered: return Icons.check_circle_rounded;
      case FoodOrderStatus.cancelled: return Icons.cancel_rounded;
    }
  }

  static FoodOrderStatus fromString(String? s) {
    switch (s) {
      case 'pending': return FoodOrderStatus.pending;
      case 'confirmed': return FoodOrderStatus.confirmed;
      case 'preparing': return FoodOrderStatus.preparing;
      case 'ready_for_pickup': return FoodOrderStatus.readyForPickup;
      case 'on_the_way': return FoodOrderStatus.onTheWay;
      case 'delivered': return FoodOrderStatus.delivered;
      case 'cancelled': return FoodOrderStatus.cancelled;
      default: return FoodOrderStatus.pending;
    }
  }
}

class FoodOrderItem {
  final int menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? specialInstructions;

  FoodOrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.specialInstructions,
  });

  factory FoodOrderItem.fromJson(Map<String, dynamic> json) {
    return FoodOrderItem(
      menuItemId: json['menu_item_id'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      specialInstructions: json['special_instructions'],
    );
  }

  double get total => price * quantity;
}

class FoodOrder {
  final int id;
  final String orderId;
  final int userId;
  final int restaurantId;
  final String restaurantName;
  final List<FoodOrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final FoodOrderStatus status;
  final String? deliveryAddress;
  final String? phone;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? driverName;
  final String? driverPhone;
  final DateTime createdAt;
  final DateTime? estimatedDelivery;
  final double? rating;

  FoodOrder({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    this.items = const [],
    required this.subtotal,
    this.deliveryFee = 0,
    required this.total,
    required this.status,
    this.deliveryAddress,
    this.phone,
    this.paymentMethod,
    this.paymentStatus,
    this.driverName,
    this.driverPhone,
    required this.createdAt,
    this.estimatedDelivery,
    this.rating,
  });

  factory FoodOrder.fromJson(Map<String, dynamic> json) {
    return FoodOrder(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? '',
      userId: json['user_id'] ?? 0,
      restaurantId: json['restaurant_id'] ?? 0,
      restaurantName: json['restaurant_name'] ?? '',
      items: (json['items'] as List?)
              ?.map((i) => FoodOrderItem.fromJson(i))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      status: FoodOrderStatus.fromString(json['status']),
      deliveryAddress: json['delivery_address'],
      phone: json['phone'],
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      driverName: json['driver_name'],
      driverPhone: json['driver_phone'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      estimatedDelivery: json['estimated_delivery'] != null
          ? DateTime.tryParse(json['estimated_delivery'])
          : null,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  bool get isActive => [
        FoodOrderStatus.pending,
        FoodOrderStatus.confirmed,
        FoodOrderStatus.preparing,
        FoodOrderStatus.readyForPickup,
        FoodOrderStatus.onTheWay,
      ].contains(status);
}

// ─── Result Wrappers ───────────────────────────────────────────

class FoodResult<T> {
  final bool success;
  final T? data;
  final String? message;
  FoodResult({required this.success, this.data, this.message});
}

class FoodListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  FoodListResult({required this.success, this.items = const [], this.message});
}
