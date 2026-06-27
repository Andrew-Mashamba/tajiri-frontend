import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/shop_models.dart';
import 'graphql_media_service.dart';
import 'graphql_shop_mapper.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL shop discovery — products, categories (Phase 10).
class GraphqlShopService {
  static final Map<String, String?> _productCursors = {};

  static const _productFields = r'''
    id
    sellerId
    title
    description
    slug
    type
    status
    price
    compareAtPrice
    currency
    stockQuantity
    images
    thumbnailUrl
    categoryId
    tags
    condition
    locationName
    latitude
    longitude
    allowPickup
    allowDelivery
    allowShipping
    deliveryFee
    deliveryNotes
    pickupAddress
    viewsCount
    favoritesCount
    ordersCount
    rating
    reviewsCount
    isFavorited
    createdAt
    updatedAt
    seller {
      id
      firstName
      lastName
      username
      avatarUrl
      rating
      totalSales
      productCount
      isVerified
    }
    category {
      id
      name
      slug
      icon
      imageUrl
      parentId
      productCount
    }
  ''';

  static const _productsQuery = '''
    query Products(\$filter: ProductFilter, \$cursor: String) {
      products(filter: \$filter, cursor: \$cursor) {
        items {
          $_productFields
        }
        nextCursor
        hasMore
      }
    }
  ''';

  static const _featuredQuery = '''
    query FeaturedProducts(\$cursor: String) {
      featuredProducts(cursor: \$cursor) {
        items {
          $_productFields
        }
        nextCursor
        hasMore
      }
    }
  ''';

  static const _trendingQuery = '''
    query TrendingProducts(\$cursor: String) {
      trendingProducts(cursor: \$cursor) {
        items {
          $_productFields
        }
        nextCursor
        hasMore
      }
    }
  ''';

  static const _recommendedQuery = '''
    query RecommendedProducts(\$cursor: String) {
      recommendedProducts(cursor: \$cursor) {
        items {
          $_productFields
        }
        nextCursor
        hasMore
      }
    }
  ''';

  static const _flashDealsQuery = '''
    query FlashDeals(\$cursor: String) {
      flashDeals(cursor: \$cursor) {
        items {
          $_productFields
        }
        nextCursor
        hasMore
      }
    }
  ''';

  static const _nearbyQuery = '''
    query NearbyProducts(\$latitude: Float!, \$longitude: Float!, \$radiusKm: Float, \$cursor: String) {
      nearbyProducts(latitude: \$latitude, longitude: \$longitude, radiusKm: \$radiusKm, cursor: \$cursor) {
        items {
          $_productFields
        }
        nextCursor
        hasMore
      }
    }
  ''';

  static const _productQuery = '''
    query Product(\$id: ID!) {
      product(id: \$id) {
        $_productFields
      }
    }
  ''';

  static const _categoriesQuery = r'''
    query ShopCategories($includeChildren: Boolean) {
      shopCategories(includeChildren: $includeChildren) {
        id
        name
        slug
        icon
        imageUrl
        parentId
        productCount
        children {
          id
          name
          slug
          icon
          imageUrl
          parentId
          productCount
        }
      }
    }
  ''';

  static const _cartFields = r'''
    items {
      productId
      quantity
      addedAt
      product {
        $_productFields
      }
    }
    subtotal
    deliveryTotal
    grandTotal
    currency
  ''';

  static const _cartQuery = '''
    query Cart {
      cart {
        $_cartFields
      }
    }
  ''';

  static const _favoritesQuery = '''
    query FavoriteProducts(\$cursor: String) {
      favoriteProducts(cursor: \$cursor) {
        items {
          $_productFields
        }
        nextCursor
        hasMore
      }
    }
  ''';

  static const _toggleFavoriteMutation = r'''
    mutation ToggleShopFavorite($productId: ID!) {
      toggleShopFavorite(productId: $productId) {
        isFavorited
      }
    }
  ''';

  static const _addCartMutation = '''
    mutation AddCartItem(\$productId: ID!, \$quantity: Int) {
      addCartItem(productId: \$productId, quantity: \$quantity) {
        $_cartFields
      }
    }
  ''';

  static const _updateCartMutation = '''
    mutation UpdateCartItem(\$productId: ID!, \$quantity: Int!) {
      updateCartItem(productId: \$productId, quantity: \$quantity) {
        $_cartFields
      }
    }
  ''';

  static const _removeCartMutation = '''
    mutation RemoveCartItem(\$productId: ID!) {
      removeCartItem(productId: \$productId) {
        $_cartFields
      }
    }
  ''';

  static const _clearCartMutation = r'''
    mutation ClearCart {
      clearCart
    }
  ''';

  static const _myShopProductsQuery = '''
    query MyShopProducts(\$status: String, \$cursor: String) {
      myShopProducts(status: \$status, cursor: \$cursor) {
        items {
          $_productFields
        }
        nextCursor
        hasMore
      }
    }
  ''';

  static const _createProductMutation = '''
    mutation CreateShopProduct(\$input: CreateShopProductInput!) {
      createShopProduct(input: \$input) {
        $_productFields
      }
    }
  ''';

  static const _updateProductMutation = '''
    mutation UpdateShopProduct(\$input: UpdateShopProductInput!) {
      updateShopProduct(input: \$input) {
        $_productFields
      }
    }
  ''';

  static const _deleteProductMutation = r'''
    mutation DeleteShopProduct($productId: ID!) {
      deleteShopProduct(productId: $productId)
    }
  ''';

  static const _sellerStatsQuery = r'''
    query ShopSellerStats($sellerId: ID!) {
      shopSellerStats(sellerId: $sellerId) {
        products {
          total
          active
          draft
          soldOut
          archived
        }
        orders {
          total
          pending
          completed
        }
        revenue {
          total
          currency
        }
        rating {
          average
          totalReviews
        }
        views {
          total
        }
      }
    }
  ''';

  static const _recordProductViewMutation = r'''
    mutation RecordShopProductView($productId: ID!, $originPostId: ID) {
      recordShopProductView(productId: $productId, originPostId: $originPostId)
    }
  ''';

  static const _reviewFields = r'''
    id
    productId
    userId
    rating
    comment
    images
    isVerifiedPurchase
    helpfulCount
    isHelpful
    createdAt
    user {
      id
      firstName
      lastName
      avatarUrl
    }
  ''';

  static const _productReviewsQuery = '''
    query ProductReviews(\$productId: ID!, \$rating: Int, \$cursor: String) {
      productReviews(productId: \$productId, rating: \$rating, cursor: \$cursor) {
        items {
          $_reviewFields
        }
        stats {
          averageRating
          totalReviews
          ratingDistribution {
            rating
            count
          }
        }
        nextCursor
        hasMore
      }
    }
  ''';

  static const _createReviewMutation = '''
    mutation CreateShopReview(\$productId: ID!, \$input: CreateShopReviewInput!) {
      createShopReview(productId: \$productId, input: \$input) {
        $_reviewFields
      }
    }
  ''';

  static const _markReviewHelpfulMutation = '''
    mutation MarkShopReviewHelpful(\$reviewId: ID!) {
      markShopReviewHelpful(reviewId: \$reviewId) {
        $_reviewFields
      }
    }
  ''';

  static const _deleteReviewMutation = r'''
    mutation DeleteShopReview($reviewId: ID!) {
      deleteShopReview(reviewId: $reviewId)
    }
  ''';

  static const _orderUserFields = r'''
    id
    firstName
    lastName
    username
    avatarUrl
  ''';

  static const _orderFields = '''
    id
    orderNumber
    buyerId
    sellerId
    productId
    quantity
    unitPrice
    subtotal
    deliveryFee
    totalAmount
    currency
    status
    deliveryMethod
    deliveryAddress
    deliveryNotes
    trackingNumber
    estimatedDelivery
    cancellationReason
    cancelledAt
    paymentMethod
    paymentStatus
    escrowStatus
    createdAt
    updatedAt
    product {
      $_productFields
    }
    buyer {
      $_orderUserFields
    }
    seller {
      $_orderUserFields
    }
  ''';

  static const _shopOrderQuery = '''
    query ShopOrder(\$id: ID!) {
      shopOrder(id: \$id) {
        $_orderFields
      }
    }
  ''';

  static const _buyerOrdersQuery = '''
    query BuyerOrders(\$status: String, \$cursor: String) {
      buyerOrders(status: \$status, cursor: \$cursor) {
        items {
          $_orderFields
        }
        nextCursor
        hasMore
      }
    }
  ''';

  static const _sellerOrdersQuery = '''
    query SellerOrders(\$status: String, \$cursor: String) {
      sellerOrders(status: \$status, cursor: \$cursor) {
        items {
          $_orderFields
        }
        nextCursor
        hasMore
      }
    }
  ''';

  static const _createOrderMutation = '''
    mutation CreateShopOrder(\$input: CreateShopOrderInput!) {
      createShopOrder(input: \$input) {
        $_orderFields
      }
    }
  ''';

  static const _checkoutMutation = '''
    mutation CheckoutCart(\$input: CheckoutInput!) {
      checkoutCart(input: \$input) {
        $_orderFields
      }
    }
  ''';

  static const _cancelOrderMutation = '''
    mutation CancelShopOrder(\$orderId: ID!, \$reason: String) {
      cancelShopOrder(orderId: \$orderId, reason: \$reason) {
        $_orderFields
      }
    }
  ''';

  static const _confirmReceivedMutation = '''
    mutation ConfirmShopOrderReceived(\$orderId: ID!) {
      confirmShopOrderReceived(orderId: \$orderId) {
        $_orderFields
      }
    }
  ''';

  static const _updateOrderStatusMutation = '''
    mutation UpdateShopOrderStatus(\$input: UpdateShopOrderStatusInput!) {
      updateShopOrderStatus(input: \$input) {
        $_orderFields
      }
    }
  ''';

  static String? _favoriteCursor;
  static final Map<String, String?> _sellerProductCursors = {};
  static final Map<String, String?> _reviewCursors = {};
  static final Map<String, String?> _buyerOrderCursors = {};
  static final Map<String, String?> _sellerOrderCursors = {};

  static String _cursorKey({
    int? categoryId,
    String? search,
    String? sortBy,
    int? sellerId,
  }) =>
      '${categoryId ?? 0}_${search ?? ''}_${sortBy ?? ''}_${sellerId ?? 0}';

  static Future<
      ({
        bool success,
        List<Product> products,
        PaginationMeta? meta,
        String? message,
      })> getProducts({
    int page = 1,
    int perPage = 20,
    int? categoryId,
    String? search,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
    ProductCondition? condition,
    ProductType? type,
    int? sellerId,
  }) async {
    try {
      final key = _cursorKey(categoryId: categoryId, search: search, sortBy: sortBy, sellerId: sellerId);
      String? cursor;
      if (page > 1) {
        cursor = _productCursors[key];
        if (cursor == null) {
          return (success: true, products: <Product>[], meta: null, message: null);
        }
      }

      final filter = <String, dynamic>{
        if (categoryId != null) 'categoryId': categoryId.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (sortBy != null) 'sortBy': sortBy,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (condition != null) 'condition': condition.value,
        if (type != null) 'productType': type.value,
        if (sellerId != null) 'sellerId': sellerId.toString(),
      };

      final data = await TajiriGraphqlClient.instance.query(
        _productsQuery,
        variables: {
          if (filter.isNotEmpty) 'filter': filter,
          if (cursor != null) 'cursor': cursor,
        },
      );
      final conn = data['products'] as Map<String, dynamic>? ?? {};
      final products = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlShopMapper.productFromGraphql)
          .toList();
      _productCursors[key] = conn['nextCursor']?.toString();
      final hasMore = conn['hasMore'] == true;

      return (
        success: true,
        products: products,
        meta: PaginationMeta(
          currentPage: page,
          perPage: perPage,
          total: hasMore ? page * perPage + 1 : (page - 1) * perPage + products.length,
          lastPage: hasMore ? page + 1 : page,
        ),
        message: null,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlShopService] getProducts: $e');
      return (success: false, products: <Product>[], meta: null, message: e.toString());
    }
  }

  static Future<
      ({
        bool success,
        List<Product> products,
        PaginationMeta? meta,
        String? message,
      })> getFeaturedProducts({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      const key = 'featured';
      String? cursor;
      if (page > 1) {
        cursor = _productCursors[key];
        if (cursor == null) {
          return (success: true, products: <Product>[], meta: null, message: null);
        }
      }
      final data = await TajiriGraphqlClient.instance.query(
        _featuredQuery,
        variables: {if (cursor != null) 'cursor': cursor},
      );
      final conn = data['featuredProducts'] as Map<String, dynamic>? ?? {};
      final products = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlShopMapper.productFromGraphql)
          .toList();
      _productCursors[key] = conn['nextCursor']?.toString();
      final hasMore = conn['hasMore'] == true;
      return (
        success: true,
        products: products,
        meta: PaginationMeta(
          currentPage: page,
          perPage: perPage,
          total: hasMore ? page * perPage + 1 : (page - 1) * perPage + products.length,
          lastPage: hasMore ? page + 1 : page,
        ),
        message: null,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlShopService] getFeaturedProducts: $e');
      return (success: false, products: <Product>[], meta: null, message: e.toString());
    }
  }

  static Future<
      ({
        bool success,
        List<Product> products,
        PaginationMeta? meta,
        String? message,
      })> getTrendingProducts({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      const key = 'trending';
      String? cursor;
      if (page > 1) {
        cursor = _productCursors[key];
        if (cursor == null) {
          return (success: true, products: <Product>[], meta: null, message: null);
        }
      }
      final data = await TajiriGraphqlClient.instance.query(
        _trendingQuery,
        variables: {if (cursor != null) 'cursor': cursor},
      );
      final conn = data['trendingProducts'] as Map<String, dynamic>? ?? {};
      final products = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlShopMapper.productFromGraphql)
          .toList();
      _productCursors[key] = conn['nextCursor']?.toString();
      final hasMore = conn['hasMore'] == true;
      return (
        success: true,
        products: products,
        meta: PaginationMeta(
          currentPage: page,
          perPage: perPage,
          total: hasMore ? page * perPage + 1 : (page - 1) * perPage + products.length,
          lastPage: hasMore ? page + 1 : page,
        ),
        message: null,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlShopService] getTrendingProducts: $e');
      return (success: false, products: <Product>[], meta: null, message: e.toString());
    }
  }

  static Future<
      ({
        bool success,
        List<Product> products,
        PaginationMeta? meta,
        String? message,
      })> getRecommendedProducts({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      const key = 'recommended';
      String? cursor;
      if (page > 1) {
        cursor = _productCursors[key];
        if (cursor == null) {
          return (success: true, products: <Product>[], meta: null, message: null);
        }
      }
      final data = await TajiriGraphqlClient.instance.query(
        _recommendedQuery,
        variables: {if (cursor != null) 'cursor': cursor},
        auth: true,
      );
      final conn = data['recommendedProducts'] as Map<String, dynamic>? ?? {};
      final products = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlShopMapper.productFromGraphql)
          .toList();
      _productCursors[key] = conn['nextCursor']?.toString();
      final hasMore = conn['hasMore'] == true;
      return (
        success: true,
        products: products,
        meta: PaginationMeta(
          currentPage: page,
          perPage: perPage,
          total: hasMore ? page * perPage + 1 : (page - 1) * perPage + products.length,
          lastPage: hasMore ? page + 1 : page,
        ),
        message: null,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlShopService] getRecommendedProducts: $e');
      return (success: false, products: <Product>[], meta: null, message: e.toString());
    }
  }

  static Future<
      ({
        bool success,
        List<Product> products,
        PaginationMeta? meta,
        String? message,
      })> getFlashDeals({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      const key = 'flash_deals';
      String? cursor;
      if (page > 1) {
        cursor = _productCursors[key];
        if (cursor == null) {
          return (success: true, products: <Product>[], meta: null, message: null);
        }
      }
      final data = await TajiriGraphqlClient.instance.query(
        _flashDealsQuery,
        variables: {if (cursor != null) 'cursor': cursor},
      );
      final conn = data['flashDeals'] as Map<String, dynamic>? ?? {};
      final products = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlShopMapper.productFromGraphql)
          .toList();
      _productCursors[key] = conn['nextCursor']?.toString();
      final hasMore = conn['hasMore'] == true;
      return (
        success: true,
        products: products,
        meta: PaginationMeta(
          currentPage: page,
          perPage: perPage,
          total: hasMore ? page * perPage + 1 : (page - 1) * perPage + products.length,
          lastPage: hasMore ? page + 1 : page,
        ),
        message: null,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlShopService] getFlashDeals: $e');
      return (success: false, products: <Product>[], meta: null, message: e.toString());
    }
  }

  static Future<
      ({
        bool success,
        List<Product> products,
        PaginationMeta? meta,
        String? message,
      })> getNearbyProducts({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final key = 'nearby:$latitude:$longitude:$radiusKm';
      String? cursor;
      if (page > 1) {
        cursor = _productCursors[key];
        if (cursor == null) {
          return (success: true, products: <Product>[], meta: null, message: null);
        }
      }
      final data = await TajiriGraphqlClient.instance.query(
        _nearbyQuery,
        variables: {
          'latitude': latitude,
          'longitude': longitude,
          'radiusKm': radiusKm,
          if (cursor != null) 'cursor': cursor,
        },
      );
      final conn = data['nearbyProducts'] as Map<String, dynamic>? ?? {};
      final products = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlShopMapper.productFromGraphql)
          .toList();
      _productCursors[key] = conn['nextCursor']?.toString();
      final hasMore = conn['hasMore'] == true;
      return (
        success: true,
        products: products,
        meta: PaginationMeta(
          currentPage: page,
          perPage: perPage,
          total: hasMore ? page * perPage + 1 : (page - 1) * perPage + products.length,
          lastPage: hasMore ? page + 1 : page,
        ),
        message: null,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlShopService] getNearbyProducts: $e');
      return (success: false, products: <Product>[], meta: null, message: e.toString());
    }
  }

  static Future<PromoCodeResult> validatePromoCode({
    required String code,
    double? subtotal,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ValidateShopPromoCode(\$code: String!, \$subtotal: Float) {
          validateShopPromoCode(code: \$code, subtotal: \$subtotal) {
            valid
            discount
            description
            message
          }
        }
        ''',
        variables: {
          'code': code,
          if (subtotal != null) 'subtotal': subtotal,
        },
        auth: true,
      );
      final result = data['validateShopPromoCode'] as Map<String, dynamic>? ?? {};
      if (result['valid'] == true) {
        return PromoCodeResult(
          success: true,
          discount: (result['discount'] as num?)?.toDouble() ?? 0,
          description: result['description'] as String?,
        );
      }
      return PromoCodeResult(
        success: false,
        message: result['message'] as String? ?? 'Invalid code',
      );
    } catch (e) {
      return PromoCodeResult(success: false, message: 'Failed to validate: $e');
    }
  }

  static Future<({bool success, Product? product, String? message})> getProduct(
    int productId,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        _productQuery,
        variables: {'id': productId.toString()},
      );
      final gql = data['product'] as Map<String, dynamic>?;
      if (gql == null) {
        return (success: false, product: null, message: 'Product not found');
      }
      return (
        success: true,
        product: GraphqlShopMapper.productFromGraphql(gql),
        message: null,
      );
    } catch (e) {
      return (success: false, product: null, message: e.toString());
    }
  }

  static Future<
      ({
        bool success,
        List<ProductCategory> categories,
        String? message,
      })> getCategories({bool includeChildren = true}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        _categoriesQuery,
        variables: {'includeChildren': includeChildren},
      );
      final categories = (data['shopCategories'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlShopMapper.categoryFromGraphql)
          .toList();
      return (success: true, categories: categories, message: null);
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlShopService] getCategories: $e');
      return (success: false, categories: <ProductCategory>[], message: e.toString());
    }
  }

  static Future<({bool success, bool isFavorited, String? message})> toggleFavorite(
    int productId,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _toggleFavoriteMutation,
        variables: {'productId': productId.toString()},
        auth: true,
      );
      final state = data['toggleShopFavorite'] as Map<String, dynamic>?;
      if (state == null) {
        return (success: false, isFavorited: false, message: 'Failed to update favorite');
      }
      return (
        success: true,
        isFavorited: state['isFavorited'] == true,
        message: null,
      );
    } catch (e) {
      return (success: false, isFavorited: false, message: e.toString());
    }
  }

  static Future<
      ({
        bool success,
        List<Product> products,
        PaginationMeta? meta,
        String? message,
      })> getFavorites({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      String? cursor;
      if (page > 1) {
        cursor = _favoriteCursor;
        if (cursor == null) {
          return (success: true, products: <Product>[], meta: null, message: null);
        }
      }
      final data = await TajiriGraphqlClient.instance.query(
        _favoritesQuery,
        variables: {if (cursor != null) 'cursor': cursor},
        auth: true,
      );
      final conn = data['favoriteProducts'] as Map<String, dynamic>? ?? {};
      final products = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlShopMapper.productFromGraphql)
          .toList();
      _favoriteCursor = conn['nextCursor']?.toString();
      final hasMore = conn['hasMore'] == true;
      return (
        success: true,
        products: products,
        meta: PaginationMeta(
          currentPage: page,
          perPage: perPage,
          total: hasMore ? page * perPage + 1 : (page - 1) * perPage + products.length,
          lastPage: hasMore ? page + 1 : page,
        ),
        message: null,
      );
    } catch (e) {
      return (success: false, products: <Product>[], meta: null, message: e.toString());
    }
  }

  static Future<({bool success, Cart? cart, String? message})> getCart() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(_cartQuery, auth: true);
      final gql = data['cart'] as Map<String, dynamic>?;
      if (gql == null) {
        return (success: false, cart: null, message: 'Failed to load cart');
      }
      return (
        success: true,
        cart: GraphqlShopMapper.cartFromGraphql(gql),
        message: null,
      );
    } catch (e) {
      return (success: false, cart: null, message: e.toString());
    }
  }

  static Future<({bool success, Cart? cart, String? message})> addToCart(
    int productId, {
    int quantity = 1,
  }) async {
    return _runCartMutation(_addCartMutation, {
      'productId': productId.toString(),
      'quantity': quantity,
    }, 'addCartItem');
  }

  static Future<({bool success, Cart? cart, String? message})> updateCartItem(
    int productId,
    int quantity,
  ) async {
    return _runCartMutation(_updateCartMutation, {
      'productId': productId.toString(),
      'quantity': quantity,
    }, 'updateCartItem');
  }

  static Future<({bool success, Cart? cart, String? message})> removeFromCart(
    int productId,
  ) async {
    return _runCartMutation(_removeCartMutation, {
      'productId': productId.toString(),
    }, 'removeCartItem');
  }

  static Future<bool> clearCart() async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _clearCartMutation,
        auth: true,
      );
      return data['clearCart'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<
      ({
        bool success,
        List<Product> products,
        PaginationMeta? meta,
        String? message,
      })> getSellerProducts({
    ProductStatus? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final key = status?.value ?? 'all';
      String? cursor;
      if (page > 1) {
        cursor = _sellerProductCursors[key];
        if (cursor == null) {
          return (success: true, products: <Product>[], meta: null, message: null);
        }
      }
      final data = await TajiriGraphqlClient.instance.query(
        _myShopProductsQuery,
        variables: {
          if (status != null) 'status': status.value,
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final conn = data['myShopProducts'] as Map<String, dynamic>? ?? {};
      final products = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlShopMapper.productFromGraphql)
          .toList();
      _sellerProductCursors[key] = conn['nextCursor']?.toString();
      final hasMore = conn['hasMore'] == true;
      return (
        success: true,
        products: products,
        meta: PaginationMeta(
          currentPage: page,
          perPage: perPage,
          total: hasMore ? page * perPage + 1 : (page - 1) * perPage + products.length,
          lastPage: hasMore ? page + 1 : page,
        ),
        message: null,
      );
    } catch (e) {
      return (success: false, products: <Product>[], meta: null, message: e.toString());
    }
  }

  static Future<({bool success, Product? product, String? message})> createProduct({
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
    List<File>? images,
    ProductStatus status = ProductStatus.active,
  }) async {
    try {
      final imagePaths = <String>[];
      if (images != null) {
        for (final file in images) {
          final uploaded = await GraphqlMediaService.uploadFile(file);
          final path = uploaded?['file_path']?.toString();
          if (path == null) {
            return (success: false, product: null, message: 'Failed to upload product image');
          }
          imagePaths.add(path);
        }
      }

      final data = await TajiriGraphqlClient.instance.mutate(
        _createProductMutation,
        variables: {
          'input': {
            'title': title,
            if (description != null) 'description': description,
            'type': type.value,
            'price': price,
            if (compareAtPrice != null) 'compareAtPrice': compareAtPrice,
            'currency': currency,
            'stockQuantity': stockQuantity,
            if (categoryId != null) 'categoryId': categoryId.toString(),
            if (tags != null && tags.isNotEmpty) 'tags': tags,
            'condition': condition.value,
            if (locationName != null) 'locationName': locationName,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
            'allowPickup': allowPickup,
            'allowDelivery': allowDelivery,
            'allowShipping': allowShipping,
            if (deliveryFee != null) 'deliveryFee': deliveryFee,
            if (deliveryNotes != null) 'deliveryNotes': deliveryNotes,
            if (pickupAddress != null) 'pickupAddress': pickupAddress,
            if (imagePaths.isNotEmpty) 'imagePaths': imagePaths,
            'status': status.value,
          },
        },
        auth: true,
      );
      final gql = data['createShopProduct'] as Map<String, dynamic>?;
      if (gql == null) {
        return (success: false, product: null, message: 'Failed to create product');
      }
      return (
        success: true,
        product: GraphqlShopMapper.productFromGraphql(gql),
        message: null,
      );
    } catch (e) {
      return (success: false, product: null, message: e.toString());
    }
  }

  static Future<({bool success, Product? product, String? message})> updateProduct({
    required int productId,
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
    List<File>? newImages,
    List<String>? removeImages,
  }) async {
    try {
      final addImagePaths = <String>[];
      if (newImages != null) {
        for (final file in newImages) {
          final uploaded = await GraphqlMediaService.uploadFile(file);
          final path = uploaded?['file_path']?.toString();
          if (path == null) {
            return (success: false, product: null, message: 'Failed to upload product image');
          }
          addImagePaths.add(path);
        }
      }

      final input = <String, dynamic>{
        'productId': productId.toString(),
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (price != null) 'price': price,
        if (compareAtPrice != null) 'compareAtPrice': compareAtPrice,
        if (stockQuantity != null) 'stockQuantity': stockQuantity,
        if (status != null) 'status': status.value,
        if (categoryId != null) 'categoryId': categoryId.toString(),
        if (tags != null) 'tags': tags,
        if (condition != null) 'condition': condition.value,
        if (locationName != null) 'locationName': locationName,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (allowPickup != null) 'allowPickup': allowPickup,
        if (allowDelivery != null) 'allowDelivery': allowDelivery,
        if (allowShipping != null) 'allowShipping': allowShipping,
        if (deliveryFee != null) 'deliveryFee': deliveryFee,
        if (deliveryNotes != null) 'deliveryNotes': deliveryNotes,
        if (pickupAddress != null) 'pickupAddress': pickupAddress,
        if (addImagePaths.isNotEmpty) 'addImagePaths': addImagePaths,
        if (removeImages != null && removeImages.isNotEmpty) 'removeImages': removeImages,
      };

      final data = await TajiriGraphqlClient.instance.mutate(
        _updateProductMutation,
        variables: {'input': input},
        auth: true,
      );
      final gql = data['updateShopProduct'] as Map<String, dynamic>?;
      if (gql == null) {
        return (success: false, product: null, message: 'Failed to update product');
      }
      return (
        success: true,
        product: GraphqlShopMapper.productFromGraphql(gql),
        message: null,
      );
    } catch (e) {
      return (success: false, product: null, message: e.toString());
    }
  }

  static Future<bool> deleteProduct(int productId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _deleteProductMutation,
        variables: {'productId': productId.toString()},
        auth: true,
      );
      return data['deleteShopProduct'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<
      ({
        bool success,
        Map<String, dynamic>? stats,
        String? message,
      })> getSellerStats(int sellerId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        _sellerStatsQuery,
        variables: {'sellerId': sellerId.toString()},
      );
      final gql = data['shopSellerStats'] as Map<String, dynamic>?;
      if (gql == null) {
        return (success: false, stats: null, message: 'Failed to load seller stats');
      }
      return (
        success: true,
        stats: GraphqlShopMapper.sellerStatsToLegacy(gql),
        message: null,
      );
    } catch (e) {
      return (success: false, stats: null, message: e.toString());
    }
  }

  static Future<void> recordProductView(
    int productId, {
    int? originPostId,
  }) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        _recordProductViewMutation,
        variables: {
          'productId': productId.toString(),
          if (originPostId != null) 'originPostId': originPostId.toString(),
        },
      );
    } catch (_) {
      // Fire-and-forget — view tracking is not critical.
    }
  }

  static Future<
      ({
        bool success,
        List<Review> reviews,
        ReviewStats? stats,
        PaginationMeta? meta,
        String? message,
      })> getProductReviews(
    int productId, {
    int page = 1,
    int perPage = 20,
    int? rating,
  }) async {
    try {
      final key = '${productId}_${rating ?? 0}';
      String? cursor;
      if (page > 1) {
        cursor = _reviewCursors[key];
        if (cursor == null) {
          return (
            success: true,
            reviews: <Review>[],
            stats: null,
            meta: null,
            message: null,
          );
        }
      }
      final data = await TajiriGraphqlClient.instance.query(
        _productReviewsQuery,
        variables: {
          'productId': productId.toString(),
          if (rating != null) 'rating': rating,
          if (cursor != null) 'cursor': cursor,
        },
      );
      final conn = data['productReviews'] as Map<String, dynamic>? ?? {};
      final reviews = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlShopMapper.reviewFromGraphql)
          .toList();
      _reviewCursors[key] = conn['nextCursor']?.toString();
      final hasMore = conn['hasMore'] == true;
      final statsGql = conn['stats'] as Map<String, dynamic>?;
      return (
        success: true,
        reviews: reviews,
        stats: statsGql != null ? GraphqlShopMapper.reviewStatsFromGraphql(statsGql) : null,
        meta: PaginationMeta(
          currentPage: page,
          perPage: perPage,
          total: hasMore ? page * perPage + 1 : (page - 1) * perPage + reviews.length,
          lastPage: hasMore ? page + 1 : page,
        ),
        message: null,
      );
    } catch (e) {
      return (
        success: false,
        reviews: <Review>[],
        stats: null,
        meta: null,
        message: e.toString(),
      );
    }
  }

  static Future<({bool success, Review? review, String? message})> createReview({
    required int productId,
    required int rating,
    String? comment,
    List<File>? images,
  }) async {
    try {
      final imagePaths = <String>[];
      if (images != null) {
        for (final file in images) {
          final uploaded = await GraphqlMediaService.uploadFile(file);
          final path = uploaded?['file_path']?.toString();
          if (path == null) {
            return (success: false, review: null, message: 'Failed to upload review image');
          }
          imagePaths.add(path);
        }
      }
      final data = await TajiriGraphqlClient.instance.mutate(
        _createReviewMutation,
        variables: {
          'productId': productId.toString(),
          'input': {
            'rating': rating,
            if (comment != null && comment.isNotEmpty) 'comment': comment,
            if (imagePaths.isNotEmpty) 'imagePaths': imagePaths,
          },
        },
        auth: true,
      );
      final gql = data['createShopReview'] as Map<String, dynamic>?;
      if (gql == null) {
        return (success: false, review: null, message: 'Failed to create review');
      }
      return (
        success: true,
        review: GraphqlShopMapper.reviewFromGraphql(gql),
        message: null,
      );
    } catch (e) {
      return (success: false, review: null, message: e.toString());
    }
  }

  static Future<bool> markReviewHelpful(int reviewId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _markReviewHelpfulMutation,
        variables: {'reviewId': reviewId.toString()},
        auth: true,
      );
      return data['markShopReviewHelpful'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteReview(int reviewId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _deleteReviewMutation,
        variables: {'reviewId': reviewId.toString()},
        auth: true,
      );
      return data['deleteShopReview'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<({bool success, Cart? cart, String? message})> _runCartMutation(
    String mutation,
    Map<String, dynamic> variables,
    String resultKey,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        mutation,
        variables: variables,
        auth: true,
      );
      final gql = data[resultKey] as Map<String, dynamic>?;
      if (gql == null) {
        return (success: false, cart: null, message: 'Cart update failed');
      }
      return (
        success: true,
        cart: GraphqlShopMapper.cartFromGraphql(gql),
        message: null,
      );
    } catch (e) {
      return (success: false, cart: null, message: e.toString());
    }
  }

  static Future<({bool success, Order? order, String? message})> createOrder({
    required int productId,
    required int quantity,
    required DeliveryMethod deliveryMethod,
    String? deliveryAddress,
    String? deliveryNotes,
    String? pin,
    String paymentMethod = 'wallet',
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _createOrderMutation,
        variables: {
          'input': {
            'productId': productId.toString(),
            'quantity': quantity,
            'deliveryMethod': deliveryMethod.value,
            if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
            if (deliveryNotes != null) 'deliveryNotes': deliveryNotes,
            'paymentMethod': paymentMethod,
            if (pin != null) 'pin': pin,
          },
        },
        auth: true,
      );
      final gql = data['createShopOrder'] as Map<String, dynamic>?;
      if (gql == null) {
        return (success: false, order: null, message: 'Failed to create order');
      }
      return (
        success: true,
        order: GraphqlShopMapper.orderFromGraphql(gql),
        message: null,
      );
    } catch (e) {
      return (success: false, order: null, message: e.toString());
    }
  }

  static Future<
      ({
        bool success,
        List<Order> orders,
        String? message,
      })> checkout({
    required List<Map<String, dynamic>> items,
    String? pin,
    String paymentMethod = 'wallet',
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _checkoutMutation,
        variables: {
          'input': {
            'items': items,
            'paymentMethod': paymentMethod,
            if (pin != null) 'pin': pin,
          },
        },
        auth: true,
      );
      final ordersRaw = data['checkoutCart'] as List? ?? [];
      final orders = ordersRaw
          .whereType<Map<String, dynamic>>()
          .map(GraphqlShopMapper.orderFromGraphql)
          .toList();
      return (success: true, orders: orders, message: null);
    } catch (e) {
      return (success: false, orders: <Order>[], message: e.toString());
    }
  }

  static Future<
      ({
        bool success,
        List<Order> orders,
        PaginationMeta? meta,
        String? message,
      })> getBuyerOrders({
    OrderStatus? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final key = status?.value ?? 'all';
      String? cursor;
      if (page > 1) {
        cursor = _buyerOrderCursors[key];
        if (cursor == null) {
          return (success: true, orders: <Order>[], meta: null, message: null);
        }
      }
      final data = await TajiriGraphqlClient.instance.query(
        _buyerOrdersQuery,
        variables: {
          if (status != null) 'status': status.value,
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final conn = data['buyerOrders'] as Map<String, dynamic>? ?? {};
      final orders = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlShopMapper.orderFromGraphql)
          .toList();
      _buyerOrderCursors[key] = conn['nextCursor']?.toString();
      final hasMore = conn['hasMore'] == true;
      return (
        success: true,
        orders: orders,
        meta: PaginationMeta(
          currentPage: page,
          perPage: perPage,
          total: hasMore ? page * perPage + 1 : (page - 1) * perPage + orders.length,
          lastPage: hasMore ? page + 1 : page,
        ),
        message: null,
      );
    } catch (e) {
      return (success: false, orders: <Order>[], meta: null, message: e.toString());
    }
  }

  static Future<
      ({
        bool success,
        List<Order> orders,
        PaginationMeta? meta,
        String? message,
      })> getSellerOrders({
    OrderStatus? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final key = status?.value ?? 'all';
      String? cursor;
      if (page > 1) {
        cursor = _sellerOrderCursors[key];
        if (cursor == null) {
          return (success: true, orders: <Order>[], meta: null, message: null);
        }
      }
      final data = await TajiriGraphqlClient.instance.query(
        _sellerOrdersQuery,
        variables: {
          if (status != null) 'status': status.value,
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final conn = data['sellerOrders'] as Map<String, dynamic>? ?? {};
      final orders = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlShopMapper.orderFromGraphql)
          .toList();
      _sellerOrderCursors[key] = conn['nextCursor']?.toString();
      final hasMore = conn['hasMore'] == true;
      return (
        success: true,
        orders: orders,
        meta: PaginationMeta(
          currentPage: page,
          perPage: perPage,
          total: hasMore ? page * perPage + 1 : (page - 1) * perPage + orders.length,
          lastPage: hasMore ? page + 1 : page,
        ),
        message: null,
      );
    } catch (e) {
      return (success: false, orders: <Order>[], meta: null, message: e.toString());
    }
  }

  static Future<({bool success, Order? order, String? message})> getOrder(
    int orderId,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        _shopOrderQuery,
        variables: {'id': orderId.toString()},
        auth: true,
      );
      final gql = data['shopOrder'] as Map<String, dynamic>?;
      if (gql == null) {
        return (success: false, order: null, message: 'Order not found');
      }
      return (
        success: true,
        order: GraphqlShopMapper.orderFromGraphql(gql),
        message: null,
      );
    } catch (e) {
      return (success: false, order: null, message: e.toString());
    }
  }

  static Future<({bool success, Order? order, String? message})> cancelOrder(
    int orderId, {
    String? reason,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _cancelOrderMutation,
        variables: {
          'orderId': orderId.toString(),
          if (reason != null) 'reason': reason,
        },
        auth: true,
      );
      final gql = data['cancelShopOrder'] as Map<String, dynamic>?;
      if (gql == null) {
        return (success: false, order: null, message: 'Failed to cancel order');
      }
      return (
        success: true,
        order: GraphqlShopMapper.orderFromGraphql(gql),
        message: null,
      );
    } catch (e) {
      return (success: false, order: null, message: e.toString());
    }
  }

  static Future<({bool success, Order? order, String? message})> confirmReceived(
    int orderId,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _confirmReceivedMutation,
        variables: {'orderId': orderId.toString()},
        auth: true,
      );
      final gql = data['confirmShopOrderReceived'] as Map<String, dynamic>?;
      if (gql == null) {
        return (success: false, order: null, message: 'Failed to confirm receipt');
      }
      return (
        success: true,
        order: GraphqlShopMapper.orderFromGraphql(gql),
        message: null,
      );
    } catch (e) {
      return (success: false, order: null, message: e.toString());
    }
  }

  static Future<({bool success, Order? order, String? message})> updateOrderStatus(
    int orderId, {
    required OrderStatus status,
    String? trackingNumber,
    DateTime? estimatedDelivery,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _updateOrderStatusMutation,
        variables: {
          'input': {
            'orderId': orderId.toString(),
            'status': status.value,
            if (trackingNumber != null) 'trackingNumber': trackingNumber,
            if (estimatedDelivery != null)
              'estimatedDelivery': estimatedDelivery.toIso8601String(),
          },
        },
        auth: true,
      );
      final gql = data['updateShopOrderStatus'] as Map<String, dynamic>?;
      if (gql == null) {
        return (success: false, order: null, message: 'Failed to update order status');
      }
      return (
        success: true,
        order: GraphqlShopMapper.orderFromGraphql(gql),
        message: null,
      );
    } catch (e) {
      return (success: false, order: null, message: e.toString());
    }
  }
}
