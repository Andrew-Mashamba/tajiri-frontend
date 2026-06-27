import '../../config/api_config.dart';
import '../../models/shop_models.dart';

/// Maps greenfield GraphQL shop types → legacy REST JSON for [Product.fromJson].
class GraphqlShopMapper {
  static String? _relativeUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final storage = ApiConfig.graphqlStorageUrl;
    if (url.startsWith(storage)) {
      return url.substring(storage.length).replaceFirst(RegExp(r'^/'), '');
    }
    return url;
  }

  static Map<String, dynamic> productToLegacy(Map<String, dynamic> gql) {
    final seller = gql['seller'] as Map<String, dynamic>?;
    final category = gql['category'] as Map<String, dynamic>?;
    final imagesRaw = gql['images'] as List? ?? [];
    final images = imagesRaw.map((e) => e.toString()).toList();

    return {
      'id': int.tryParse(gql['id']?.toString() ?? '') ?? 0,
      'seller_id': int.tryParse(gql['sellerId']?.toString() ?? '') ?? 0,
      'title': gql['title'] ?? '',
      'description': gql['description'],
      'slug': gql['slug'] ?? '',
      'type': gql['type'] ?? 'physical',
      'status': gql['status'] ?? 'active',
      'price': gql['price'] ?? 0,
      if (gql['compareAtPrice'] != null) 'compare_at_price': gql['compareAtPrice'],
      'currency': gql['currency'] ?? 'TZS',
      'stock_quantity': gql['stockQuantity'] ?? 0,
      'images': images,
      'thumbnail_path': _relativeUrl(gql['thumbnailUrl']?.toString()) ??
          (images.isNotEmpty ? images.first : null),
      if (gql['categoryId'] != null) 'category_id': int.tryParse(gql['categoryId'].toString()),
      if (gql['tags'] != null) 'tags': gql['tags'],
      'condition': gql['condition'] ?? 'new',
      if (gql['locationName'] != null) 'location_name': gql['locationName'],
      if (gql['latitude'] != null) 'latitude': gql['latitude'],
      if (gql['longitude'] != null) 'longitude': gql['longitude'],
      'allow_pickup': gql['allowPickup'] ?? true,
      'allow_delivery': gql['allowDelivery'] ?? false,
      'allow_shipping': gql['allowShipping'] ?? false,
      if (gql['deliveryFee'] != null) 'delivery_fee': gql['deliveryFee'],
      if (gql['deliveryNotes'] != null) 'delivery_notes': gql['deliveryNotes'],
      if (gql['pickupAddress'] != null) 'pickup_address': gql['pickupAddress'],
      'views_count': gql['viewsCount'] ?? 0,
      'favorites_count': gql['favoritesCount'] ?? 0,
      'orders_count': gql['ordersCount'] ?? 0,
      'rating': gql['rating'] ?? 0,
      'reviews_count': gql['reviewsCount'] ?? 0,
      'is_favorited': gql['isFavorited'] == true,
      'created_at': gql['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      'updated_at': gql['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
      if (seller != null)
        'seller': {
          'id': int.tryParse(seller['id']?.toString() ?? '') ?? 0,
          'first_name': seller['firstName'] ?? '',
          'last_name': seller['lastName'] ?? '',
          'username': seller['username'],
          'profile_photo_path': _relativeUrl(seller['avatarUrl']?.toString()),
          'rating': seller['rating'] ?? 0,
          'total_sales': seller['totalSales'] ?? 0,
          'product_count': seller['productCount'] ?? 0,
          'is_verified': seller['isVerified'] == true,
        },
      if (category != null) 'category': categoryToLegacy(category),
    };
  }

  static Product productFromGraphql(Map<String, dynamic> gql) {
    return Product.fromJson(productToLegacy(gql));
  }

  static Map<String, dynamic> categoryToLegacy(Map<String, dynamic> gql) {
    final children = gql['children'] as List?;
    return {
      'id': int.tryParse(gql['id']?.toString() ?? '') ?? 0,
      'name': gql['name'] ?? '',
      'slug': gql['slug'] ?? '',
      if (gql['icon'] != null) 'icon': gql['icon'],
      'image_path': _relativeUrl(gql['imageUrl']?.toString()),
      if (gql['parentId'] != null) 'parent_id': int.tryParse(gql['parentId'].toString()),
      'product_count': gql['productCount'] ?? 0,
      if (children != null)
        'children': children
            .whereType<Map<String, dynamic>>()
            .map(categoryToLegacy)
            .toList(),
    };
  }

  static ProductCategory categoryFromGraphql(Map<String, dynamic> gql) {
    return ProductCategory.fromJson(categoryToLegacy(gql));
  }

  static Map<String, dynamic> cartToLegacy(Map<String, dynamic> gql) {
    final items = (gql['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final product = item['product'] as Map<String, dynamic>?;
          return {
            'product_id': int.tryParse(item['productId']?.toString() ?? '') ?? 0,
            'quantity': item['quantity'] ?? 1,
            if (item['addedAt'] != null) 'added_at': item['addedAt'].toString(),
            if (product != null) 'product': productToLegacy(product),
          };
        })
        .toList();
    return {
      'items': items,
      'subtotal': gql['subtotal'] ?? 0,
      'delivery_total': gql['deliveryTotal'] ?? 0,
      'grand_total': gql['grandTotal'] ?? 0,
      'currency': gql['currency'] ?? 'TZS',
    };
  }

  static Cart cartFromGraphql(Map<String, dynamic> gql) {
    return Cart.fromJson(cartToLegacy(gql));
  }

  static Map<String, dynamic> _orderUserToLegacy(Map<String, dynamic> gql) {
    return {
      'id': int.tryParse(gql['id']?.toString() ?? '') ?? 0,
      'first_name': gql['firstName'] ?? '',
      'last_name': gql['lastName'] ?? '',
      'username': gql['username'],
      'profile_photo_path': _relativeUrl(gql['avatarUrl']?.toString()),
    };
  }

  static Map<String, dynamic> orderToLegacy(Map<String, dynamic> gql) {
    final product = gql['product'] as Map<String, dynamic>?;
    final buyer = gql['buyer'] as Map<String, dynamic>?;
    final seller = gql['seller'] as Map<String, dynamic>?;
    return {
      'id': int.tryParse(gql['id']?.toString() ?? '') ?? 0,
      'order_number': gql['orderNumber'] ?? '',
      'buyer_id': int.tryParse(gql['buyerId']?.toString() ?? '') ?? 0,
      'seller_id': int.tryParse(gql['sellerId']?.toString() ?? '') ?? 0,
      'product_id': int.tryParse(gql['productId']?.toString() ?? '') ?? 0,
      'quantity': gql['quantity'] ?? 1,
      'unit_price': gql['unitPrice'] ?? 0,
      'subtotal': gql['subtotal'] ?? 0,
      'delivery_fee': gql['deliveryFee'] ?? 0,
      'total_amount': gql['totalAmount'] ?? 0,
      'currency': gql['currency'] ?? 'TZS',
      'status': gql['status'] ?? 'pending',
      'delivery_method': gql['deliveryMethod'] ?? 'pickup',
      if (gql['deliveryAddress'] != null) 'delivery_address': gql['deliveryAddress'],
      if (gql['deliveryNotes'] != null) 'delivery_notes': gql['deliveryNotes'],
      if (gql['trackingNumber'] != null) 'tracking_number': gql['trackingNumber'],
      if (gql['estimatedDelivery'] != null)
        'estimated_delivery': gql['estimatedDelivery'].toString(),
      if (gql['cancellationReason'] != null)
        'cancellation_reason': gql['cancellationReason'],
      if (gql['cancelledAt'] != null) 'cancelled_at': gql['cancelledAt'].toString(),
      'payment_method': gql['paymentMethod'] ?? 'wallet',
      if (gql['paymentStatus'] != null) 'payment_status': gql['paymentStatus'],
      if (gql['escrowStatus'] != null) 'escrow_status': gql['escrowStatus'],
      'created_at': gql['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      'updated_at': gql['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
      if (product != null) 'product': productToLegacy(product),
      if (buyer != null) 'buyer': _orderUserToLegacy(buyer),
      if (seller != null) 'seller': _orderUserToLegacy(seller),
    };
  }

  static Order orderFromGraphql(Map<String, dynamic> gql) {
    return Order.fromJson(orderToLegacy(gql));
  }

  static Map<String, dynamic> sellerStatsToLegacy(Map<String, dynamic> gql) {
    final products = gql['products'] as Map<String, dynamic>? ?? {};
    final orders = gql['orders'] as Map<String, dynamic>? ?? {};
    final revenue = gql['revenue'] as Map<String, dynamic>? ?? {};
    final rating = gql['rating'] as Map<String, dynamic>? ?? {};
    final views = gql['views'] as Map<String, dynamic>? ?? {};
    return {
      'products': {
        'total': products['total'] ?? 0,
        'active': products['active'] ?? 0,
        'draft': products['draft'] ?? 0,
        'sold_out': products['soldOut'] ?? 0,
        'archived': products['archived'] ?? 0,
      },
      'orders': {
        'total': orders['total'] ?? 0,
        'pending': orders['pending'] ?? 0,
        'completed': orders['completed'] ?? 0,
      },
      'revenue': {
        'total': revenue['total'] ?? 0,
        'currency': revenue['currency'] ?? 'TZS',
      },
      'rating': {
        'average': rating['average'] ?? 0,
        'total_reviews': rating['totalReviews'] ?? 0,
      },
      'views': {
        'total': views['total'] ?? 0,
      },
    };
  }

  static Map<String, dynamic> reviewToLegacy(Map<String, dynamic> gql) {
    final user = gql['user'] as Map<String, dynamic>?;
    final imagesRaw = gql['images'] as List? ?? [];
    return {
      'id': int.tryParse(gql['id']?.toString() ?? '') ?? 0,
      'product_id': int.tryParse(gql['productId']?.toString() ?? '') ?? 0,
      'user_id': int.tryParse(gql['userId']?.toString() ?? '') ?? 0,
      'rating': gql['rating'] ?? 0,
      if (gql['comment'] != null) 'comment': gql['comment'],
      'images': imagesRaw.map((e) => e.toString()).toList(),
      'is_verified_purchase': gql['isVerifiedPurchase'] == true,
      'helpful_count': gql['helpfulCount'] ?? 0,
      'is_helpful': gql['isHelpful'],
      'created_at': gql['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      if (user != null)
        'user': {
          'id': int.tryParse(user['id']?.toString() ?? '') ?? 0,
          'first_name': user['firstName'] ?? '',
          'last_name': user['lastName'] ?? '',
          'profile_photo_path': _relativeUrl(user['avatarUrl']?.toString()),
        },
    };
  }

  static Review reviewFromGraphql(Map<String, dynamic> gql) {
    return Review.fromJson(reviewToLegacy(gql));
  }

  static Map<String, dynamic> reviewStatsToLegacy(Map<String, dynamic> gql) {
    final distribution = <String, dynamic>{};
    for (final row in (gql['ratingDistribution'] as List? ?? [])) {
      if (row is Map<String, dynamic>) {
        distribution[row['rating']?.toString() ?? '0'] = row['count'] ?? 0;
      }
    }
    return {
      'average_rating': gql['averageRating'] ?? 0,
      'total_reviews': gql['totalReviews'] ?? 0,
      'rating_distribution': distribution,
    };
  }

  static ReviewStats reviewStatsFromGraphql(Map<String, dynamic> gql) {
    return ReviewStats.fromJson(reviewStatsToLegacy(gql));
  }
}
