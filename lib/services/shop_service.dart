// TAJIRI Marketplace Service
// Handles all shop API operations: products, cart, orders, reviews
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/shop_models.dart';
import '../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

// ============================================================================
// LOGGING UTILITIES
// ============================================================================

void _log(String message) {
  debugPrint('[ShopService] $message');
}

void _logRequest(String method, String url, {Map<String, dynamic>? params, dynamic body}) {
  _log('');
  _log('========== API REQUEST ==========');
  _log('[$method] $url');
  if (params != null && params.isNotEmpty) {
    _log('PARAMS: $params');
  }
  if (body != null) {
    final bodyStr = body is String ? body : jsonEncode(body);
    // Truncate large bodies
    if (bodyStr.length > 500) {
      _log('BODY: ${bodyStr.substring(0, 500)}... (truncated)');
    } else {
      _log('BODY: $bodyStr');
    }
  }
  _log('=================================');
}

void _logResponse(int statusCode, dynamic body, {Duration? duration}) {
  _log('');
  _log('========== API RESPONSE ==========');
  _log('STATUS: $statusCode');
  if (duration != null) {
    _log('DURATION: ${duration.inMilliseconds}ms');
  }
  final bodyStr = body is String ? body : jsonEncode(body);
  // Truncate large responses
  if (bodyStr.length > 1000) {
    _log('BODY: ${bodyStr.substring(0, 1000)}... (truncated, total ${bodyStr.length} chars)');
  } else {
    _log('BODY: $bodyStr');
  }
  _log('==================================');
}

void _logError(String method, String url, dynamic error, {StackTrace? stackTrace}) {
  _log('');
  _log('========== API ERROR ==========');
  _log('[$method] $url');
  _log('ERROR: $error');
  if (stackTrace != null) {
    _log('STACK: ${stackTrace.toString().split('\n').take(5).join('\n')}');
  }
  _log('===============================');
}

/// Parse and log detailed server error
String _handleServerError(Map<String, dynamic> data, int statusCode) {
  _log('=== SERVER ERROR DETAILS ===');
  _log('Status Code: $statusCode');
  _log('Full Response: $data');

  if (data.containsKey('errors') && data['errors'] is Map) {
    final errors = data['errors'] as Map<String, dynamic>;
    _log('Validation Errors:');
    errors.forEach((field, messages) {
      _log('  - $field: $messages');
    });
  }

  if (data.containsKey('message')) {
    _log('Server Message: ${data['message']}');
  }

  if (data.containsKey('error')) {
    _log('Server Error: ${data['error']}');
  }

  if (data.containsKey('exception')) {
    _log('Exception: ${data['exception']}');
  }

  _log('=== END ERROR DETAILS ===');

  // Return user-friendly message
  return data['message']?.toString() ?? 'An error occurred';
}

class ShopService {
  // ============================================================================
  // PRODUCT DISCOVERY
  // ============================================================================

  /// Get products with filtering and pagination
  Future<ProductListResult> getProducts({
    int page = 1,
    int perPage = 20,
    int? categoryId,
    String? search,
    String? sortBy, // newest, price_asc, price_desc, popular, rating
    double? minPrice,
    double? maxPrice,
    ProductCondition? condition,
    ProductType? type,
    int? sellerId,
    int? currentUserId,
  }) async {
    final stopwatch = Stopwatch()..start();
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (categoryId != null) params['category_id'] = categoryId.toString();
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (sortBy != null) params['sort_by'] = sortBy;
    if (minPrice != null) params['min_price'] = minPrice.toString();
    if (maxPrice != null) params['max_price'] = maxPrice.toString();
    if (condition != null) params['condition'] = condition.value;
    if (type != null) params['type'] = type.value;
    if (sellerId != null) params['seller_id'] = sellerId.toString();
    if (currentUserId != null) params['user_id'] = currentUserId.toString();

    final uri = Uri.parse('$_baseUrl/shop/products').replace(queryParameters: params);
    _logRequest('GET', uri.toString(), params: params);

    try {
      final response = await http.get(uri);
      stopwatch.stop();
      _logResponse(response.statusCode, response.body, duration: stopwatch.elapsed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Handle both formats: data as List OR data.items as List
          final responseData = data['data'];
          List<dynamic> productsList;
          PaginationMeta? meta;

          if (responseData is List) {
            productsList = responseData;
            meta = data['meta'] != null ? PaginationMeta.fromJson(data['meta']) : null;
          } else if (responseData is Map && responseData['items'] != null) {
            productsList = responseData['items'] as List;
            meta = responseData['pagination'] != null
                ? PaginationMeta.fromJson(responseData['pagination'])
                : null;
          } else {
            productsList = [];
          }

          final products = productsList.map((p) => Product.fromJson(p)).toList();
          _log('Successfully loaded ${products.length} products');
          return ProductListResult(
            success: true,
            products: products,
            meta: meta,
          );
        }
        _handleServerError(data, response.statusCode);
      }
      return ProductListResult(
        success: false,
        message: 'Imeshindwa kupakia bidhaa',
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logError('GET', uri.toString(), e, stackTrace: stackTrace);
      return ProductListResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Get featured products
  Future<ProductListResult> getFeaturedProducts({int? currentUserId}) async {
    try {
      String url = '$_baseUrl/shop/products/featured';
      if (currentUserId != null) url += '?user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final products = (data['data'] as List)
              .map((p) => Product.fromJson(p))
              .toList();
          return ProductListResult(success: true, products: products);
        }
      }
      return ProductListResult(
        success: false,
        message: 'Imeshindwa kupakia bidhaa zilizoangaziwa',
      );
    } catch (e) {
      return ProductListResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Get trending products
  Future<ProductListResult> getTrendingProducts({int? currentUserId}) async {
    try {
      String url = '$_baseUrl/shop/products/trending';
      if (currentUserId != null) url += '?user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final products = (data['data'] as List)
              .map((p) => Product.fromJson(p))
              .toList();
          return ProductListResult(success: true, products: products);
        }
      }
      return ProductListResult(
        success: false,
        message: 'Imeshindwa kupakia bidhaa maarufu',
      );
    } catch (e) {
      return ProductListResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Get recommended products for user
  Future<ProductListResult> getRecommendedProducts(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/shop/products/recommended?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final products = (data['data'] as List)
              .map((p) => Product.fromJson(p))
              .toList();
          return ProductListResult(success: true, products: products);
        }
      }
      return ProductListResult(
        success: false,
        message: 'Imeshindwa kupakia mapendekezo',
      );
    } catch (e) {
      return ProductListResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Get nearby products based on location
  Future<ProductListResult> getNearbyProducts({
    required double latitude,
    required double longitude,
    double radius = 10, // km
    int? currentUserId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, String>{
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'radius': radius.toString(),
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (currentUserId != null) params['user_id'] = currentUserId.toString();

      final uri = Uri.parse('$_baseUrl/shop/products/nearby')
          .replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final products = (data['data'] as List)
              .map((p) => Product.fromJson(p))
              .toList();
          return ProductListResult(
            success: true,
            products: products,
            meta: data['meta'] != null
                ? PaginationMeta.fromJson(data['meta'])
                : null,
          );
        }
      }
      return ProductListResult(
        success: false,
        message: 'Imeshindwa kupakia bidhaa za karibu',
      );
    } catch (e) {
      return ProductListResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Get all categories
  Future<CategoryListResult> getCategories({bool includeChildren = true}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/shop/categories?include_children=$includeChildren'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final categories = (data['data'] as List)
              .map((c) => ProductCategory.fromJson(c))
              .toList();
          return CategoryListResult(success: true, categories: categories);
        }
      }
      return CategoryListResult(
        success: false,
        message: 'Imeshindwa kupakia kategoria',
      );
    } catch (e) {
      return CategoryListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ============================================================================
  // PRODUCT CRUD
  // ============================================================================

  /// Get single product details
  Future<ProductResult> getProduct(int productId, {int? currentUserId}) async {
    final stopwatch = Stopwatch()..start();
    String url = '$_baseUrl/shop/products/$productId';
    if (currentUserId != null) url += '?user_id=$currentUserId';
    _logRequest('GET', url, params: {'product_id': productId, 'user_id': currentUserId});

    try {
      final response = await http.get(Uri.parse(url));
      stopwatch.stop();
      _logResponse(response.statusCode, response.body, duration: stopwatch.elapsed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final product = Product.fromJson(data['data']);
          _log('Loaded product #$productId: "${product.title}"');
          return ProductResult(
            success: true,
            product: product,
          );
        }
        _handleServerError(data, response.statusCode);
      }
      return ProductResult(
        success: false,
        message: 'Bidhaa haipatikani',
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logError('GET', url, e, stackTrace: stackTrace);
      return ProductResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Create a new product
  Future<ProductResult> createProduct({
    required int sellerId,
    required String title,
    String? description,
    required ProductType type,
    required double price,
    double? compareAtPrice,
    String currency = 'TZS',
    int stockQuantity = 0,
    int? categoryId,
    List<String>? tags,
    ProductCondition condition = ProductCondition.brandNew,
    String? locationName,
    double? latitude,
    double? longitude,
    bool allowPickup = true,
    bool allowDelivery = false,
    bool allowShipping = false,
    double? deliveryFee,
    String? deliveryNotes,
    String? pickupAddress,
    String? downloadUrl,
    int? downloadLimit,
    int? durationMinutes,
    String? serviceLocation,
    List<File>? images,
  }) async {
    final stopwatch = Stopwatch()..start();
    final url = '$_baseUrl/shop/products';
    _logRequest('POST', url, body: {
      'seller_id': sellerId,
      'title': title,
      'type': type.value,
      'price': price,
      'currency': currency,
      'stock_quantity': stockQuantity,
      'images_count': images?.length ?? 0,
    });

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add fields
      request.fields['seller_id'] = sellerId.toString();
      request.fields['title'] = title;
      if (description != null) request.fields['description'] = description;
      request.fields['type'] = type.value;
      request.fields['price'] = price.toString();
      if (compareAtPrice != null) {
        request.fields['compare_at_price'] = compareAtPrice.toString();
      }
      request.fields['currency'] = currency;
      request.fields['stock_quantity'] = stockQuantity.toString();
      if (categoryId != null) {
        request.fields['category_id'] = categoryId.toString();
      }
      if (tags != null && tags.isNotEmpty) {
        request.fields['tags'] = jsonEncode(tags);
      }
      request.fields['condition'] = condition.value;
      if (locationName != null) request.fields['location_name'] = locationName;
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();
      request.fields['allow_pickup'] = allowPickup.toString();
      request.fields['allow_delivery'] = allowDelivery.toString();
      request.fields['allow_shipping'] = allowShipping.toString();
      if (deliveryFee != null) {
        request.fields['delivery_fee'] = deliveryFee.toString();
      }
      if (deliveryNotes != null) request.fields['delivery_notes'] = deliveryNotes;
      if (pickupAddress != null) request.fields['pickup_address'] = pickupAddress;
      if (downloadUrl != null) request.fields['download_url'] = downloadUrl;
      if (downloadLimit != null) {
        request.fields['download_limit'] = downloadLimit.toString();
      }
      if (durationMinutes != null) {
        request.fields['duration_minutes'] = durationMinutes.toString();
      }
      if (serviceLocation != null) {
        request.fields['service_location'] = serviceLocation;
      }

      // Add images
      if (images != null) {
        _log('Uploading ${images.length} product images');
        for (int i = 0; i < images.length; i++) {
          final file = images[i];
          final extension = file.path.split('.').last.toLowerCase();
          final mimeType = extension == 'png'
              ? 'image/png'
              : extension == 'gif'
                  ? 'image/gif'
                  : 'image/jpeg';

          request.files.add(await http.MultipartFile.fromPath(
            'images[$i]',
            file.path,
            contentType: MediaType.parse(mimeType),
          ));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      stopwatch.stop();
      _logResponse(response.statusCode, response.body, duration: stopwatch.elapsed);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final product = Product.fromJson(data['data']);
        _log('Product created successfully: #${product.id} "${product.title}"');
        return ProductResult(
          success: true,
          product: product,
        );
      }
      _handleServerError(data, response.statusCode);
      return ProductResult(
        success: false,
        message: data['message'] ?? 'Imeshindwa kuunda bidhaa',
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logError('POST', url, e, stackTrace: stackTrace);
      return ProductResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Update an existing product
  Future<ProductResult> updateProduct({
    required int productId,
    required int sellerId,
    String? title,
    String? description,
    double? price,
    double? compareAtPrice,
    int? stockQuantity,
    ProductStatus? status,
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
    List<File>? newImages,
    List<String>? removeImages,
  }) async {
    final stopwatch = Stopwatch()..start();
    final url = '$_baseUrl/shop/products/$productId';
    final updateFields = <String, dynamic>{
      'product_id': productId,
      'seller_id': sellerId,
      if (title != null) 'title': title,
      if (status != null) 'status': status.value,
      if (price != null) 'price': price,
      if (stockQuantity != null) 'stock_quantity': stockQuantity,
    };
    _logRequest('PUT', url, body: updateFields);

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));

      request.fields['_method'] = 'PUT';
      request.fields['seller_id'] = sellerId.toString();

      if (title != null) request.fields['title'] = title;
      if (description != null) request.fields['description'] = description;
      if (price != null) request.fields['price'] = price.toString();
      if (compareAtPrice != null) {
        request.fields['compare_at_price'] = compareAtPrice.toString();
      }
      if (stockQuantity != null) {
        request.fields['stock_quantity'] = stockQuantity.toString();
      }
      if (status != null) request.fields['status'] = status.value;
      if (categoryId != null) {
        request.fields['category_id'] = categoryId.toString();
      }
      if (tags != null) request.fields['tags'] = jsonEncode(tags);
      if (condition != null) request.fields['condition'] = condition.value;
      if (locationName != null) request.fields['location_name'] = locationName;
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();
      if (allowPickup != null) {
        request.fields['allow_pickup'] = allowPickup.toString();
      }
      if (allowDelivery != null) {
        request.fields['allow_delivery'] = allowDelivery.toString();
      }
      if (allowShipping != null) {
        request.fields['allow_shipping'] = allowShipping.toString();
      }
      if (deliveryFee != null) {
        request.fields['delivery_fee'] = deliveryFee.toString();
      }
      if (deliveryNotes != null) request.fields['delivery_notes'] = deliveryNotes;
      if (pickupAddress != null) request.fields['pickup_address'] = pickupAddress;
      if (downloadUrl != null) request.fields['download_url'] = downloadUrl;
      if (downloadLimit != null) {
        request.fields['download_limit'] = downloadLimit.toString();
      }
      if (durationMinutes != null) {
        request.fields['duration_minutes'] = durationMinutes.toString();
      }
      if (serviceLocation != null) {
        request.fields['service_location'] = serviceLocation;
      }
      if (removeImages != null && removeImages.isNotEmpty) {
        request.fields['remove_images'] = jsonEncode(removeImages);
      }

      // Add new images
      if (newImages != null) {
        _log('Uploading ${newImages.length} new images');
        for (int i = 0; i < newImages.length; i++) {
          final file = newImages[i];
          final extension = file.path.split('.').last.toLowerCase();
          final mimeType = extension == 'png'
              ? 'image/png'
              : extension == 'gif'
                  ? 'image/gif'
                  : 'image/jpeg';

          request.files.add(await http.MultipartFile.fromPath(
            'new_images[$i]',
            file.path,
            contentType: MediaType.parse(mimeType),
          ));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      stopwatch.stop();
      _logResponse(response.statusCode, response.body, duration: stopwatch.elapsed);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _log('Product #$productId updated successfully');
        return ProductResult(
          success: true,
          product: Product.fromJson(data['data']),
        );
      }
      _handleServerError(data, response.statusCode);
      return ProductResult(
        success: false,
        message: data['message'] ?? 'Imeshindwa kubadilisha bidhaa',
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logError('PUT', url, e, stackTrace: stackTrace);
      return ProductResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Delete a product
  Future<bool> deleteProduct(int productId, int sellerId) async {
    final stopwatch = Stopwatch()..start();
    final url = '$_baseUrl/shop/products/$productId';
    final body = {'seller_id': sellerId};
    _logRequest('DELETE', url, body: body);

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      stopwatch.stop();
      _logResponse(response.statusCode, response.body, duration: stopwatch.elapsed);

      final data = jsonDecode(response.body);
      final success = response.statusCode == 200 && data['success'] == true;
      if (success) {
        _log('Product #$productId deleted successfully');
      } else {
        _handleServerError(data, response.statusCode);
      }
      return success;
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logError('DELETE', url, e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get seller's products
  Future<ProductListResult> getSellerProducts(
    int sellerId, {
    ProductStatus? status,
    int page = 1,
    int perPage = 20,
    int? currentUserId,
  }) async {
    final stopwatch = Stopwatch()..start();
    final params = <String, String>{
      'seller_id': sellerId.toString(),
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (status != null) params['status'] = status.value;
    if (currentUserId != null) params['user_id'] = currentUserId.toString();

    final uri = Uri.parse('$_baseUrl/shop/products/seller')
        .replace(queryParameters: params);
    _logRequest('GET', uri.toString(), params: params);

    try {
      final response = await http.get(uri);
      stopwatch.stop();
      _logResponse(response.statusCode, response.body, duration: stopwatch.elapsed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Handle both formats: data as List OR data.items as List
          final responseData = data['data'];
          List<dynamic> productsList;
          PaginationMeta? meta;

          if (responseData is List) {
            productsList = responseData;
            meta = data['meta'] != null ? PaginationMeta.fromJson(data['meta']) : null;
          } else if (responseData is Map && responseData['items'] != null) {
            productsList = responseData['items'] as List;
            meta = responseData['pagination'] != null
                ? PaginationMeta.fromJson(responseData['pagination'])
                : null;
          } else {
            productsList = [];
          }

          final products = productsList.map((p) => Product.fromJson(p)).toList();
          _log('Loaded ${products.length} seller products for seller #$sellerId');
          return ProductListResult(
            success: true,
            products: products,
            meta: meta,
          );
        }
        _handleServerError(data, response.statusCode);
      }
      return ProductListResult(
        success: false,
        message: 'Imeshindwa kupakia bidhaa za muuzaji',
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logError('GET', uri.toString(), e, stackTrace: stackTrace);
      return ProductListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ============================================================================
  // FAVORITES
  // ============================================================================

  /// Toggle favorite status for a product
  Future<FavoriteResult> toggleFavorite(int userId, int productId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/shop/products/$productId/favorite'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return FavoriteResult(
          success: true,
          isFavorited: data['data']['is_favorited'] == true,
        );
      }
      return FavoriteResult(
        success: false,
        message: data['message'] ?? 'Imeshindwa kubadilisha kipendwa',
      );
    } catch (e) {
      return FavoriteResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Get user's favorite products
  Future<ProductListResult> getFavorites(
    int userId, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/shop/favorites?user_id=$userId&page=$page&per_page=$perPage',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final products = (data['data'] as List)
              .map((p) => Product.fromJson(p))
              .toList();
          return ProductListResult(
            success: true,
            products: products,
            meta: data['meta'] != null
                ? PaginationMeta.fromJson(data['meta'])
                : null,
          );
        }
      }
      return ProductListResult(
        success: false,
        message: 'Imeshindwa kupakia vipendwa',
      );
    } catch (e) {
      return ProductListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ============================================================================
  // CART
  // ============================================================================

  /// Get user's cart
  Future<CartResult> getCart(int userId) async {
    final stopwatch = Stopwatch()..start();
    final url = '$_baseUrl/shop/cart?user_id=$userId';
    _logRequest('GET', url, params: {'user_id': userId});

    try {
      final response = await http.get(Uri.parse(url));
      stopwatch.stop();
      _logResponse(response.statusCode, response.body, duration: stopwatch.elapsed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final cart = Cart.fromJson(data['data']);
          _log('Cart loaded: ${cart.itemCount} items, total ${cart.grandTotalFormatted}');
          return CartResult(
            success: true,
            cart: cart,
          );
        }
        _handleServerError(data, response.statusCode);
      }
      return CartResult(
        success: false,
        message: 'Imeshindwa kupakia kikapu',
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logError('GET', url, e, stackTrace: stackTrace);
      return CartResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Add item to cart
  Future<CartResult> addToCart(int userId, int productId, {int quantity = 1}) async {
    final stopwatch = Stopwatch()..start();
    final url = '$_baseUrl/shop/cart/items';
    final body = {
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
    };
    _logRequest('POST', url, body: body);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      stopwatch.stop();
      _logResponse(response.statusCode, response.body, duration: stopwatch.elapsed);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _log('Added product #$productId to cart (qty: $quantity)');
        return CartResult(
          success: true,
          cart: Cart.fromJson(data['data']),
          message: 'Imeongezwa kwenye kikapu',
        );
      }
      _handleServerError(data, response.statusCode);
      return CartResult(
        success: false,
        message: data['message'] ?? 'Imeshindwa kuongeza kwenye kikapu',
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logError('POST', url, e, stackTrace: stackTrace);
      return CartResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Update cart item quantity
  Future<CartResult> updateCartItem(
    int userId,
    int productId,
    int quantity,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/shop/cart/items/$productId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'quantity': quantity,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return CartResult(
          success: true,
          cart: Cart.fromJson(data['data']),
        );
      }
      return CartResult(
        success: false,
        message: data['message'] ?? 'Imeshindwa kubadilisha kikapu',
      );
    } catch (e) {
      return CartResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Remove item from cart
  Future<CartResult> removeFromCart(int userId, int productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/shop/cart/items/$productId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return CartResult(
          success: true,
          cart: Cart.fromJson(data['data']),
        );
      }
      return CartResult(
        success: false,
        message: data['message'] ?? 'Imeshindwa kuondoa kwenye kikapu',
      );
    } catch (e) {
      return CartResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Clear entire cart
  Future<bool> clearCart(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/shop/cart'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // ORDERS
  // ============================================================================

  /// Create a new order
  Future<OrderResult> createOrder({
    required int buyerId,
    required int productId,
    required int quantity,
    required DeliveryMethod deliveryMethod,
    String? deliveryAddress,
    String? deliveryNotes,
    String? pin, // TAJIRI Wallet PIN for payment
  }) async {
    final stopwatch = Stopwatch()..start();
    final url = '$_baseUrl/shop/orders';
    final body = {
      'buyer_id': buyerId,
      'product_id': productId,
      'quantity': quantity,
      'delivery_method': deliveryMethod.value,
      if (deliveryAddress != null) 'delivery_address': deliveryAddress,
      if (deliveryNotes != null) 'delivery_notes': deliveryNotes,
      // Note: PIN not logged for security
    };
    _logRequest('POST', url, body: {...body, 'pin': pin != null ? '***' : null});

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          ...body,
          if (pin != null) 'pin': pin,
        }),
      );
      stopwatch.stop();
      _logResponse(response.statusCode, response.body, duration: stopwatch.elapsed);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final order = Order.fromJson(data['data']);
        _log('Order created: #${order.orderNumber} for product #$productId');
        return OrderResult(
          success: true,
          order: order,
        );
      }
      _handleServerError(data, response.statusCode);
      return OrderResult(
        success: false,
        message: data['message'] ?? 'Imeshindwa kuunda oda',
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logError('POST', url, e, stackTrace: stackTrace);
      return OrderResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Create multiple orders from cart (checkout)
  Future<OrderListResult> checkout({
    required int buyerId,
    required List<CheckoutItem> items,
    String? pin, // TAJIRI Wallet PIN for payment
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/shop/checkout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'buyer_id': buyerId,
          'items': items.map((i) => i.toJson()).toList(),
          if (pin != null) 'pin': pin,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final orders = (data['data'] as List)
            .map((o) => Order.fromJson(o))
            .toList();
        return OrderListResult(
          success: true,
          orders: orders,
        );
      }
      return OrderListResult(
        success: false,
        message: data['message'] ?? 'Imeshindwa kufanya checkout',
      );
    } catch (e) {
      return OrderListResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Get buyer's orders
  Future<OrderListResult> getBuyerOrders(
    int userId, {
    OrderStatus? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final stopwatch = Stopwatch()..start();
    final params = <String, String>{
      'user_id': userId.toString(),
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (status != null) params['status'] = status.value;

    final uri = Uri.parse('$_baseUrl/shop/orders/buyer')
        .replace(queryParameters: params);
    _logRequest('GET', uri.toString(), params: params);

    try {
      final response = await http.get(uri);
      stopwatch.stop();
      _logResponse(response.statusCode, response.body, duration: stopwatch.elapsed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Handle both formats: data as List OR data.items as List
          final responseData = data['data'];
          List<dynamic> ordersList;
          PaginationMeta? meta;

          if (responseData is List) {
            ordersList = responseData;
            meta = data['meta'] != null ? PaginationMeta.fromJson(data['meta']) : null;
          } else if (responseData is Map && responseData['items'] != null) {
            ordersList = responseData['items'] as List;
            meta = responseData['pagination'] != null
                ? PaginationMeta.fromJson(responseData['pagination'])
                : null;
          } else {
            ordersList = [];
          }

          final orders = ordersList.map((o) => Order.fromJson(o)).toList();
          _log('Loaded ${orders.length} buyer orders for user #$userId');
          return OrderListResult(
            success: true,
            orders: orders,
            meta: meta,
          );
        }
        _handleServerError(data, response.statusCode);
      }
      return OrderListResult(
        success: false,
        message: 'Imeshindwa kupakia oda',
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logError('GET', uri.toString(), e, stackTrace: stackTrace);
      return OrderListResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Get seller's orders
  Future<OrderListResult> getSellerOrders(
    int userId, {
    OrderStatus? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final stopwatch = Stopwatch()..start();
    final params = <String, String>{
      'user_id': userId.toString(),
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (status != null) params['status'] = status.value;

    final uri = Uri.parse('$_baseUrl/shop/orders/seller')
        .replace(queryParameters: params);
    _logRequest('GET', uri.toString(), params: params);

    try {
      final response = await http.get(uri);
      stopwatch.stop();
      _logResponse(response.statusCode, response.body, duration: stopwatch.elapsed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Handle both formats: data as List OR data.items as List
          final responseData = data['data'];
          List<dynamic> ordersList;
          PaginationMeta? meta;

          if (responseData is List) {
            ordersList = responseData;
            meta = data['meta'] != null ? PaginationMeta.fromJson(data['meta']) : null;
          } else if (responseData is Map && responseData['items'] != null) {
            ordersList = responseData['items'] as List;
            meta = responseData['pagination'] != null
                ? PaginationMeta.fromJson(responseData['pagination'])
                : null;
          } else {
            ordersList = [];
          }

          final orders = ordersList.map((o) => Order.fromJson(o)).toList();
          _log('Loaded ${orders.length} seller orders for user #$userId (status: ${status?.value ?? 'all'})');
          return OrderListResult(
            success: true,
            orders: orders,
            meta: meta,
          );
        }
        _handleServerError(data, response.statusCode);
      }
      return OrderListResult(
        success: false,
        message: 'Imeshindwa kupakia oda',
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logError('GET', uri.toString(), e, stackTrace: stackTrace);
      return OrderListResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Get single order details
  Future<OrderResult> getOrder(int orderId, {required int userId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/shop/orders/$orderId?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return OrderResult(
            success: true,
            order: Order.fromJson(data['data']),
          );
        }
      }
      return OrderResult(
        success: false,
        message: 'Oda haipatikani',
      );
    } catch (e) {
      return OrderResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Update order status (for sellers)
  Future<OrderResult> updateOrderStatus(
    int orderId, {
    required int sellerId,
    required OrderStatus status,
    String? trackingNumber,
    String? note,
    DateTime? estimatedDelivery,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/shop/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'seller_id': sellerId,
          'status': status.value,
          if (trackingNumber != null) 'tracking_number': trackingNumber,
          if (note != null) 'note': note,
          if (estimatedDelivery != null)
            'estimated_delivery': estimatedDelivery.toIso8601String(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return OrderResult(
          success: true,
          order: Order.fromJson(data['data']),
        );
      }
      return OrderResult(
        success: false,
        message: data['message'] ?? 'Imeshindwa kubadilisha hali ya oda',
      );
    } catch (e) {
      return OrderResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Cancel an order
  Future<OrderResult> cancelOrder(
    int orderId, {
    required int userId,
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/shop/orders/$orderId/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          if (reason != null) 'reason': reason,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return OrderResult(
          success: true,
          order: Order.fromJson(data['data']),
        );
      }
      return OrderResult(
        success: false,
        message: data['message'] ?? 'Imeshindwa kughairi oda',
      );
    } catch (e) {
      return OrderResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Mark order as received (for buyers)
  Future<OrderResult> confirmReceived(int orderId, {required int buyerId}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/shop/orders/$orderId/received'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'buyer_id': buyerId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return OrderResult(
          success: true,
          order: Order.fromJson(data['data']),
        );
      }
      return OrderResult(
        success: false,
        message: data['message'] ?? 'Imeshindwa kuthibitisha kupokea',
      );
    } catch (e) {
      return OrderResult(success: false, message: 'Kosa: $e');
    }
  }

  // ============================================================================
  // REVIEWS
  // ============================================================================

  /// Get product reviews
  Future<ReviewListResult> getProductReviews(
    int productId, {
    int page = 1,
    int perPage = 20,
    int? rating, // Filter by specific rating
    int? currentUserId,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (rating != null) params['rating'] = rating.toString();
      if (currentUserId != null) params['user_id'] = currentUserId.toString();

      final uri = Uri.parse('$_baseUrl/shop/products/$productId/reviews')
          .replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final reviews = (data['data'] as List)
              .map((r) => Review.fromJson(r))
              .toList();
          return ReviewListResult(
            success: true,
            reviews: reviews,
            stats: data['stats'] != null
                ? ReviewStats.fromJson(data['stats'])
                : null,
            meta: data['meta'] != null
                ? PaginationMeta.fromJson(data['meta'])
                : null,
          );
        }
      }
      return ReviewListResult(
        success: false,
        message: 'Imeshindwa kupakia maoni',
      );
    } catch (e) {
      return ReviewListResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Create a review for a product
  Future<ReviewResult> createReview({
    required int productId,
    required int userId,
    required int rating,
    String? comment,
    List<File>? images,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/shop/products/$productId/reviews'),
      );

      request.fields['user_id'] = userId.toString();
      request.fields['rating'] = rating.toString();
      if (comment != null && comment.isNotEmpty) {
        request.fields['comment'] = comment;
      }

      // Add images
      if (images != null) {
        for (int i = 0; i < images.length; i++) {
          final file = images[i];
          final extension = file.path.split('.').last.toLowerCase();
          final mimeType = extension == 'png'
              ? 'image/png'
              : extension == 'gif'
                  ? 'image/gif'
                  : 'image/jpeg';

          request.files.add(await http.MultipartFile.fromPath(
            'images[$i]',
            file.path,
            contentType: MediaType.parse(mimeType),
          ));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return ReviewResult(
          success: true,
          review: Review.fromJson(data['data']),
        );
      }
      return ReviewResult(
        success: false,
        message: data['message'] ?? 'Imeshindwa kutuma tathmini',
      );
    } catch (e) {
      return ReviewResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Mark a review as helpful
  Future<bool> markReviewHelpful(int reviewId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/shop/reviews/$reviewId/helpful'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Delete own review
  Future<bool> deleteReview(int reviewId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/shop/reviews/$reviewId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // SELLER STATS
  // ============================================================================

  /// Get seller statistics
  Future<SellerStatsResult> getSellerStats(int sellerId) async {
    final stopwatch = Stopwatch()..start();
    final url = '$_baseUrl/shop/seller/$sellerId/stats';
    _logRequest('GET', url, params: {'seller_id': sellerId});

    try {
      final response = await http.get(Uri.parse(url));
      stopwatch.stop();
      _logResponse(response.statusCode, response.body, duration: stopwatch.elapsed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Handle both formats: data directly OR data.stats
          final responseData = data['data'];
          Map<String, dynamic> statsData;

          if (responseData is Map && responseData['stats'] != null) {
            statsData = responseData['stats'] as Map<String, dynamic>;
          } else {
            statsData = responseData as Map<String, dynamic>;
          }

          final stats = SellerStats.fromJson(statsData);
          _log('Seller #$sellerId stats: ${stats.totalProducts} products, ${stats.totalOrders} orders, ${stats.revenueFormatted} revenue');
          return SellerStatsResult(
            success: true,
            stats: stats,
          );
        }
        _handleServerError(data, response.statusCode);
      }
      return SellerStatsResult(
        success: false,
        message: 'Imeshindwa kupakia takwimu',
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logError('GET', url, e, stackTrace: stackTrace);
      return SellerStatsResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Record product view
  Future<void> recordProductView(int productId, {int? userId}) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/shop/products/$productId/view'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (userId != null) 'user_id': userId,
        }),
      );
    } catch (_) {
      // Silently fail - view tracking is not critical
    }
  }
}

// ============================================================================
// ADDITIONAL RESULT CLASSES
// ============================================================================

class FavoriteResult {
  final bool success;
  final bool isFavorited;
  final String? message;

  FavoriteResult({
    required this.success,
    this.isFavorited = false,
    this.message,
  });
}

class CheckoutItem {
  final int productId;
  final int quantity;
  final DeliveryMethod deliveryMethod;
  final String? deliveryAddress;
  final String? deliveryNotes;

  CheckoutItem({
    required this.productId,
    required this.quantity,
    required this.deliveryMethod,
    this.deliveryAddress,
    this.deliveryNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'delivery_method': deliveryMethod.value,
      if (deliveryAddress != null) 'delivery_address': deliveryAddress,
      if (deliveryNotes != null) 'delivery_notes': deliveryNotes,
    };
  }
}

class SellerStats {
  final int totalProducts;
  final int activeProducts;
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final double totalRevenue;
  final double averageRating;
  final int totalReviews;
  final int totalViews;
  final String currency;

  SellerStats({
    this.totalProducts = 0,
    this.activeProducts = 0,
    this.totalOrders = 0,
    this.pendingOrders = 0,
    this.completedOrders = 0,
    this.totalRevenue = 0,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.totalViews = 0,
    this.currency = 'TZS',
  });

  factory SellerStats.fromJson(Map<String, dynamic> json) {
    // Handle both flat format and nested format from backend
    // Nested format: { products: {total, active}, orders: {total, pending}, ... }
    // Flat format: { total_products, active_products, total_orders, ... }

    if (json.containsKey('products') && json['products'] is Map) {
      // Nested format from backend
      final products = json['products'] as Map<String, dynamic>;
      final orders = json['orders'] as Map<String, dynamic>? ?? {};
      final revenue = json['revenue'] as Map<String, dynamic>? ?? {};
      final rating = json['rating'] as Map<String, dynamic>? ?? {};
      final views = json['views'] as Map<String, dynamic>? ?? {};

      return SellerStats(
        totalProducts: products['total'] ?? 0,
        activeProducts: products['active'] ?? 0,
        totalOrders: orders['total'] ?? 0,
        pendingOrders: orders['pending'] ?? 0,
        completedOrders: orders['completed'] ?? 0,
        totalRevenue: (revenue['total'] ?? 0).toDouble(),
        averageRating: (rating['average'] ?? 0).toDouble(),
        totalReviews: rating['total_reviews'] ?? 0,
        totalViews: views['total'] ?? 0,
        currency: revenue['currency'] ?? 'TZS',
      );
    }

    // Flat format (fallback)
    return SellerStats(
      totalProducts: json['total_products'] ?? 0,
      activeProducts: json['active_products'] ?? 0,
      totalOrders: json['total_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      totalViews: json['total_views'] ?? 0,
      currency: json['currency'] ?? 'TZS',
    );
  }

  String get revenueFormatted {
    if (totalRevenue >= 1000000) {
      return '$currency ${(totalRevenue / 1000000).toStringAsFixed(1)}M';
    } else if (totalRevenue >= 1000) {
      return '$currency ${(totalRevenue / 1000).toStringAsFixed(0)}K';
    }
    return '$currency ${totalRevenue.toStringAsFixed(0)}';
  }
}

class SellerStatsResult {
  final bool success;
  final SellerStats? stats;
  final String? message;

  SellerStatsResult({
    required this.success,
    this.stats,
    this.message,
  });
}
