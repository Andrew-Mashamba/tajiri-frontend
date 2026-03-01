import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/subscription_models.dart';
import '../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

class SubscriptionService {
  /// Get subscription tiers for a creator
  Future<TierListResult> getCreatorTiers(int creatorId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/subscriptions/tiers/$creatorId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final tiers = (data['data'] as List)
              .map((t) => SubscriptionTier.fromJson(t))
              .toList();
          return TierListResult(success: true, tiers: tiers);
        }
      }
      return TierListResult(success: false, message: 'Imeshindwa kupakia viwango');
    } catch (e) {
      return TierListResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Create a subscription tier (for creators)
  Future<TierResult> createTier({
    required int userId,
    required String name,
    String? description,
    required double price,
    String billingPeriod = 'monthly',
    List<String>? benefits,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/subscriptions/tiers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'name': name,
          if (description != null) 'description': description,
          'price': price,
          'billing_period': billingPeriod,
          if (benefits != null) 'benefits': benefits,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return TierResult(
          success: true,
          tier: SubscriptionTier.fromJson(data['data']),
        );
      }
      return TierResult(success: false, message: data['message'] ?? 'Imeshindwa kuunda kiwango');
    } catch (e) {
      return TierResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Update a subscription tier
  Future<TierResult> updateTier({
    required int userId,
    required int tierId,
    String? name,
    String? description,
    double? price,
    List<String>? benefits,
    bool? isActive,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/subscriptions/tiers/$tierId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (price != null) 'price': price,
          if (benefits != null) 'benefits': benefits,
          if (isActive != null) 'is_active': isActive,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return TierResult(
          success: true,
          tier: SubscriptionTier.fromJson(data['data']),
        );
      }
      return TierResult(success: false, message: data['message'] ?? 'Imeshindwa kubadilisha kiwango');
    } catch (e) {
      return TierResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Delete a subscription tier
  Future<bool> deleteTier({
    required int userId,
    required int tierId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/subscriptions/tiers/$tierId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Subscribe to a creator's tier
  Future<SubscriptionResult> subscribe({
    required int userId,
    required int tierId,
    required String paymentMethod, // wallet, mobile_money
    String? provider, // for mobile money
    String? phoneNumber,
    String? pin, // for wallet
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/subscriptions/subscribe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'tier_id': tierId,
          'payment_method': paymentMethod,
          if (provider != null) 'provider': provider,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (pin != null) 'pin': pin,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return SubscriptionResult(
          success: true,
          subscription: Subscription.fromJson(data['data']),
        );
      }
      return SubscriptionResult(success: false, message: data['message'] ?? 'Imeshindwa kujisajili');
    } catch (e) {
      return SubscriptionResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Cancel a subscription
  Future<SubscriptionResult> cancelSubscription({
    required int userId,
    required int subscriptionId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/subscriptions/$subscriptionId/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return SubscriptionResult(success: true);
      }
      return SubscriptionResult(success: false, message: data['message'] ?? 'Failed to cancel');
    } catch (e) {
      return SubscriptionResult(success: false, message: 'Error: $e');
    }
  }

  /// Toggle auto-renewal for a subscription
  Future<SubscriptionResult> toggleAutoRenew({
    required int userId,
    required int subscriptionId,
    required bool autoRenew,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/subscriptions/$subscriptionId/auto-renew'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'auto_renew': autoRenew,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return SubscriptionResult(success: true);
      }
      return SubscriptionResult(success: false, message: data['message'] ?? 'Failed to update');
    } catch (e) {
      return SubscriptionResult(success: false, message: 'Error: $e');
    }
  }

  /// Get user's subscriptions
  Future<SubscriptionListResult> getMySubscriptions({
    required int userId,
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    try {
      String url = '$_baseUrl/subscriptions/my?user_id=$userId&page=$page&per_page=$perPage';
      if (status != null) url += '&status=$status';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final subscriptions = (data['data'] as List)
              .map((s) => Subscription.fromJson(s))
              .toList();
          return SubscriptionListResult(
            success: true,
            subscriptions: subscriptions,
            meta: data['meta'] != null ? SubscriptionPaginationMeta.fromJson(data['meta']) : null,
          );
        }
      }
      return SubscriptionListResult(success: false, message: 'Imeshindwa kupakia usajili');
    } catch (e) {
      return SubscriptionListResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Get creator's subscribers
  Future<SubscriptionListResult> getSubscribers({
    required int userId,
    int page = 1,
    int perPage = 20,
    int? tierId,
  }) async {
    try {
      String url = '$_baseUrl/subscriptions/subscribers?user_id=$userId&page=$page&per_page=$perPage';
      if (tierId != null) url += '&tier_id=$tierId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final subscriptions = (data['data'] as List)
              .map((s) => Subscription.fromJson(s))
              .toList();
          return SubscriptionListResult(
            success: true,
            subscriptions: subscriptions,
            meta: data['meta'] != null ? SubscriptionPaginationMeta.fromJson(data['meta']) : null,
          );
        }
      }
      return SubscriptionListResult(success: false, message: 'Imeshindwa kupakia wasajili');
    } catch (e) {
      return SubscriptionListResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Send a tip to a creator
  Future<TipResult> sendTip({
    required int userId,
    required int creatorId,
    required double amount,
    String? message,
    required String paymentMethod,
    String? provider,
    String? phoneNumber,
    String? pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/subscriptions/tips'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'creator_id': creatorId,
          'amount': amount,
          if (message != null) 'message': message,
          'payment_method': paymentMethod,
          if (provider != null) 'provider': provider,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (pin != null) 'pin': pin,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return TipResult(success: true, message: 'Tuzo imetumwa!');
      }
      return TipResult(success: false, message: data['message'] ?? 'Imeshindwa kutuma tuzo');
    } catch (e) {
      return TipResult(success: false, message: 'Kosa: $e');
    }
  }

  // ========== CREATOR EARNINGS ==========

  /// Get creator earnings
  Future<EarningsListResult> getEarnings({
    required int userId,
    int page = 1,
    int perPage = 20,
    String? type, // subscription, tip, gift
    String? status, // pending, paid
  }) async {
    try {
      String url = '$_baseUrl/subscriptions/earnings?user_id=$userId&page=$page&per_page=$perPage';
      if (type != null) url += '&type=$type';
      if (status != null) url += '&status=$status';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final earnings = (data['data'] as List)
              .map((e) => CreatorEarning.fromJson(e))
              .toList();
          return EarningsListResult(
            success: true,
            earnings: earnings,
            meta: data['meta'] != null ? SubscriptionPaginationMeta.fromJson(data['meta']) : null,
          );
        }
      }
      return EarningsListResult(success: false, message: 'Imeshindwa kupakia mapato');
    } catch (e) {
      return EarningsListResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Get earnings summary
  Future<EarningsSummaryResult> getEarningsSummary(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/subscriptions/earnings/summary?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return EarningsSummaryResult(
            success: true,
            summary: EarningsSummary.fromJson(data['data']),
          );
        }
      }
      return EarningsSummaryResult(success: false, message: 'Imeshindwa kupakia muhtasari');
    } catch (e) {
      return EarningsSummaryResult(success: false, message: 'Kosa: $e');
    }
  }

  // ========== PAYOUTS ==========

  /// Request a payout
  Future<PayoutResult> requestPayout({
    required int userId,
    required double amount,
    required String paymentMethod,
    required String accountNumber,
    required String accountName,
    String? provider,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/subscriptions/payouts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'amount': amount,
          'payment_method': paymentMethod,
          'account_number': accountNumber,
          'account_name': accountName,
          if (provider != null) 'provider': provider,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return PayoutResult(
          success: true,
          payout: CreatorPayout.fromJson(data['data']),
        );
      }
      return PayoutResult(success: false, message: data['message'] ?? 'Imeshindwa kutuma ombi la malipo');
    } catch (e) {
      return PayoutResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Get payout history
  Future<PayoutListResult> getPayouts({
    required int userId,
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    try {
      String url = '$_baseUrl/subscriptions/payouts?user_id=$userId&page=$page&per_page=$perPage';
      if (status != null) url += '&status=$status';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final payouts = (data['data'] as List)
              .map((p) => CreatorPayout.fromJson(p))
              .toList();
          return PayoutListResult(
            success: true,
            payouts: payouts,
            meta: data['meta'] != null ? SubscriptionPaginationMeta.fromJson(data['meta']) : null,
          );
        }
      }
      return PayoutListResult(success: false, message: 'Imeshindwa kupakia historia ya malipo');
    } catch (e) {
      return PayoutListResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Check if user is subscribed to a creator
  Future<bool> isSubscribed({
    required int userId,
    required int creatorId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/subscriptions/check/$creatorId?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true && data['data']['is_subscribed'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

// Result classes
class TierListResult {
  final bool success;
  final List<SubscriptionTier> tiers;
  final String? message;

  TierListResult({required this.success, this.tiers = const [], this.message});
}

class TierResult {
  final bool success;
  final SubscriptionTier? tier;
  final String? message;

  TierResult({required this.success, this.tier, this.message});
}

class SubscriptionResult {
  final bool success;
  final Subscription? subscription;
  final String? message;

  SubscriptionResult({required this.success, this.subscription, this.message});
}

class SubscriptionListResult {
  final bool success;
  final List<Subscription> subscriptions;
  final SubscriptionPaginationMeta? meta;
  final String? message;

  SubscriptionListResult({
    required this.success,
    this.subscriptions = const [],
    this.meta,
    this.message,
  });
}

class TipResult {
  final bool success;
  final String? message;

  TipResult({required this.success, this.message});
}

class EarningsListResult {
  final bool success;
  final List<CreatorEarning> earnings;
  final SubscriptionPaginationMeta? meta;
  final String? message;

  EarningsListResult({
    required this.success,
    this.earnings = const [],
    this.meta,
    this.message,
  });
}

class EarningsSummaryResult {
  final bool success;
  final EarningsSummary? summary;
  final String? message;

  EarningsSummaryResult({required this.success, this.summary, this.message});
}

class PayoutResult {
  final bool success;
  final CreatorPayout? payout;
  final String? message;

  PayoutResult({required this.success, this.payout, this.message});
}

class PayoutListResult {
  final bool success;
  final List<CreatorPayout> payouts;
  final SubscriptionPaginationMeta? meta;
  final String? message;

  PayoutListResult({
    required this.success,
    this.payouts = const [],
    this.meta,
    this.message,
  });
}

class SubscriptionPaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  SubscriptionPaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory SubscriptionPaginationMeta.fromJson(Map<String, dynamic> json) {
    return SubscriptionPaginationMeta(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      total: json['total'] ?? 0,
    );
  }
}
