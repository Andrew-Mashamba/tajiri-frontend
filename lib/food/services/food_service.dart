// lib/food/services/food_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../models/food_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class FoodService {
  // ─── Restaurants ──────────────────────────────────────────────

  Future<FoodListResult<Restaurant>> getRestaurants({
    String? category,
    String? search,
    bool? openOnly,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
      };
      if (category != null) params['category'] = category;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (openOnly == true) params['open'] = '1';

      final uri = Uri.parse('$_baseUrl/food/restaurants').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => Restaurant.fromJson(j))
              .toList();
          return FoodListResult(success: true, items: items);
        }
      }
      return FoodListResult(success: false, message: 'Imeshindwa kupakia mikahawa');
    } catch (e) {
      return FoodListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FoodResult<Restaurant>> getRestaurant(int restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/food/restaurants/$restaurantId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return FoodResult(success: true, data: Restaurant.fromJson(data['data']));
        }
      }
      return FoodResult(success: false, message: 'Imeshindwa kupakia mkahawa');
    } catch (e) {
      return FoodResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Menu ─────────────────────────────────────────────────────

  Future<FoodListResult<MenuItem>> getMenu(int restaurantId, {String? category}) async {
    try {
      String url = '$_baseUrl/food/restaurants/$restaurantId/menu';
      if (category != null) url += '?category=$category';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => MenuItem.fromJson(j))
              .toList();
          return FoodListResult(success: true, items: items);
        }
      }
      return FoodListResult(success: false, message: 'Imeshindwa kupakia menyu');
    } catch (e) {
      return FoodListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Orders ───────────────────────────────────────────────────

  Future<FoodResult<FoodOrder>> placeOrder({
    required int userId,
    required int restaurantId,
    required List<CartItem> items,
    required String deliveryAddress,
    required String phone,
    required String paymentMethod,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/food/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'restaurant_id': restaurantId,
          'items': items.map((i) => i.toJson()).toList(),
          'delivery_address': deliveryAddress,
          'phone': phone,
          'payment_method': paymentMethod,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final order = FoodOrder.fromJson(data['data']);
        // Fire-and-forget: record expenditure for budget tracking
        LocalStorageService.getInstance().then((storage) {
          final token = storage.getAuthToken();
          if (token != null) {
            ExpenditureService.recordExpenditure(
              token: token,
              amount: order.total,
              category: 'chakula',
              description: 'Chakula: ${order.restaurantName}',
              referenceId: 'food_order_${order.id}',
              sourceModule: 'food',
            ).catchError((_) => null);
          }
        }).catchError((_) {
          debugPrint('[FoodService] expenditure tracking skipped');
        });
        return FoodResult(success: true, data: order);
      }
      return FoodResult(success: false, message: data['message'] ?? 'Imeshindwa kuagiza');
    } catch (e) {
      return FoodResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FoodListResult<FoodOrder>> getMyOrders({
    required int userId,
    String? status,
    int page = 1,
  }) async {
    try {
      String url = '$_baseUrl/food/orders?user_id=$userId&page=$page';
      if (status != null) url += '&status=$status';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => FoodOrder.fromJson(j))
              .toList();
          return FoodListResult(success: true, items: items);
        }
      }
      return FoodListResult(success: false, message: 'Imeshindwa kupakia oda');
    } catch (e) {
      return FoodListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FoodResult<FoodOrder>> getOrder(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/food/orders/$orderId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return FoodResult(success: true, data: FoodOrder.fromJson(data['data']));
        }
      }
      return FoodResult(success: false, message: 'Imeshindwa kupakia oda');
    } catch (e) {
      return FoodResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FoodResult<void>> cancelOrder(int orderId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/food/orders/$orderId/cancel'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FoodResult(success: true);
      }
      return FoodResult(success: false, message: data['message'] ?? 'Imeshindwa kughairi');
    } catch (e) {
      return FoodResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<FoodResult<void>> rateOrder({
    required int orderId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/food/orders/$orderId/rate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rating': rating,
          if (comment != null) 'comment': comment,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return FoodResult(success: true);
      }
      return FoodResult(success: false, message: data['message'] ?? 'Imeshindwa');
    } catch (e) {
      return FoodResult(success: false, message: 'Kosa: $e');
    }
  }
}
