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

  // -------------------------------------------------------------------------
  // STUBS — methods consumed by chef/beneficiary/food-runner pages whose
  // backend endpoints are not yet implemented. Return null at runtime; pages
  // that call these will need real implementations before they work.
  // -------------------------------------------------------------------------
  Future<dynamic> acceptCuratedReservation({Object? partnerUserId, Object? reservationId}) async => null;
  Future<dynamic> addFavourite({Object? targetId, Object? targetType, Object? userId}) async => null;
  Future<dynamic> cancelChefReservation({Object? reservationId, Object? userId}) async => null;
  Future<dynamic> cascadeChefListing({Object? listingId, Object? userId}) async => null;
  Future<dynamic> claimFoodRun({Object? runId, Object? runnerUserId}) async => null;
  Future<dynamic> closeBeneficiaryNeed({Object? needId, Object? userId}) async => null;
  Future<dynamic> confirmReceipt({Object? listingId, Object? orgId, Object? userId}) async => null;
  Future<dynamic> createBeneficiaryNeed({Object? orgId, Object? userId, Object? title, Object? description, Object? quantity, Object? unit, Object? deadline, Object? daysOfWeek, Object? deliveryMode, Object? dietaryConstraints, Object? dueDate, Object? durationWeeks, Object? mealType, Object? needType, Object? portionsNeeded}) async => null;
  Future<dynamic> createCashDonation({Object? amount, Object? donorType, Object? donorUserId, Object? orgId, Object? notes, Object? contactEmail, Object? contactPerson, Object? contactPhone, Object? funguLaKumiTagged, Object? organizationName, Object? paymentMethod, Object? paymentReference, Object? purpose, Object? registrationNumber, Object? zakaTagged}) async => null;
  Future<dynamic> createChefListing({Object? userId, Object? title, Object? description, Object? portions, Object? pricePerPortion, Object? availableUntil, Object? deliveryMode, Object? mode, Object? customAmount, Object? cuisineTags, Object? isGiveaway, Object? beneficiaryOrgId, Object? cascadeOrgId, Object? cookedAt, Object? deliveryEnabled, Object? deliveryFeeTzs, Object? deliveryRadiusKm, Object? dietaryTags, Object? originalPriceTzs, Object? photoUrl, Object? pickupAddress, Object? pickupWindowEnd, Object? pickupWindowStart, Object? portionsTotal, Object? priceTzs, Object? recipientType, Object? selectionMode}) async => null;
  Future<dynamic> createChefProduct({Object? title, Object? userId, Object? description, Object? price, Object? quantity, Object? cuisineTags, Object? availableUntil, Object? basePriceTzs, Object? leadTimeHours, Object? minQuantity, Object? mode, Object? photos, Object? tags}) async => null;
  Future<dynamic> createNeedPledge({Object? needId, Object? donorUserId, Object? quantity, Object? notes, Object? portions, Object? note, Object? contactPhone, Object? deliveryDate}) async => null;
  Future<dynamic> createReview({Object? stars, Object? tags, Object? targetId, Object? targetType, Object? text, Object? userId}) async => null;
  Future<dynamic> followBeneficiaryOrg({Object? orgId, Object? userId}) async => null;
  Future<dynamic> getBeneficiaryFollowState({Object? orgId, Object? userId}) async => null;
  Future<dynamic> getBeneficiaryOrg(Object? orgId, {Object? userId}) async => null;
  Future<dynamic> getChefListing(Object? listingId, {Object? userId}) async => null;
  Future<dynamic> getChefListingContact(Object? listingId, [Object? userId]) async => null;
  Future<dynamic> getChefListings({Object? mode, Object? userId, Object? page, Object? perPage, Object? location, Object? cuisine}) async => null;
  Future<dynamic> getChefProduct(Object? productId, {Object? userId}) async => null;
  Future<dynamic> getFoodEmergency(Object? userId) async => null;
  Future<dynamic> getFoodPreferences({Object? userId}) async => null;
  Future<dynamic> getMyBeneficiaryOrg(Object? userId) async => null;
  Future<dynamic> incomingDonations({Object? orgId, Object? userId}) async => null;
  Future<dynamic> listBeneficiaryNeeds({Object? limit, Object? type, Object? orgId, Object? status, Object? ward}) async => null;
  Future<dynamic> listBeneficiaryOrgs({Object? limit, Object? status, Object? type, Object? q, Object? userId, Object? page, Object? perPage}) async => null;
  Future<dynamic> listCuratedReservations({Object? listingId, Object? partnerUserId}) async => null;
  Future<dynamic> listFavourites([Object? userId]) async => null;
  Future<dynamic> listFollowedBeneficiaryOrgs([Object? userId]) async => null;
  Future<dynamic> listFoodRuns({Object? status, Object? userId}) async => null;
  Future<dynamic> listReviews({Object? targetId, Object? targetType, Object? page}) async => null;
  Future<dynamic> markChefReservationDelivered({Object? reservationId, Object? userId}) async => null;
  Future<dynamic> markChefReservationOutForDelivery({Object? reservationId, Object? userId}) async => null;
  Future<dynamic> markChefReservationPickedUp({Object? reservationId, Object? userId}) async => null;
  Future<dynamic> myFoodRuns({Object? userId}) async => null;
  Future<dynamic> orderChefProduct({Object? productId, Object? userId, Object? quantity, Object? deliveryMode, Object? deliveryAddress, Object? requestedFor, Object? notes}) async => null;
  Future<dynamic> pauseBeneficiaryNeed({Object? needId, Object? userId}) async => null;
  Future<dynamic> registerBeneficiaryOrg([Object? body, Object? userId, Object? name, Object? type, Object? location, Object? phone]) async => null;
  Future<dynamic> rejectCuratedReservation({Object? partnerUserId, Object? reservationId}) async => null;
  Future<dynamic> releaseFoodRun({Object? reason, Object? runId, Object? runnerUserId}) async => null;
  Future<dynamic> removeFavourite({Object? favouriteId, Object? userId}) async => null;
  Future<dynamic> reportBeneficiaryOrg({Object? orgId, Object? reason, Object? userId, Object? detail}) async => null;
  Future<dynamic> reserveChefListing({Object? deliveryMode, Object? listingId, Object? portions, Object? userId, Object? whyMe}) async => null;
  Future<dynamic> resumeBeneficiaryNeed({Object? needId, Object? userId}) async => null;
  Future<dynamic> search({Object? query, Object? type}) async => null;
  Future<dynamic> unfollowBeneficiaryOrg({Object? orgId, Object? userId}) async => null;
  Future<dynamic> updateChefListing({Object? addPortions, Object? close, Object? extendMinutes, Object? flipToGiveaway, Object? id, Object? userId}) async => null;
  Future<dynamic> updateChefProduct({Object? productId, Object? title, Object? userId, Object? description, Object? price, Object? basePriceTzs, Object? leadTimeHours, Object? minQuantity, Object? mode, Object? photos, Object? tags}) async => null;
  Future<dynamic> updateFoodPreferences({Object? allergens, Object? autoTagFungu, Object? autoTagZakat, Object? defaultPaymentMethod, Object? defaultWard, Object? dietaryTags, Object? hideFromCommunityFeed, Object? hideOnLeaderboard, Object? maxDeliveryRadiusKm, Object? notificationCategories, Object? quietHoursEnd, Object? quietHoursStart, Object? showSaidiaRail, Object? userId}) async => null;
  Future<dynamic> updateFoodRunStatus({Object? runId, Object? runnerUserId, Object? status}) async => null;
  Future<dynamic> uploadChefListingPhoto({Object? file, Object? userId}) async => null;
  Future<dynamic> uploadChefProductPhoto({Object? file, Object? userId}) async => null;
}
