import 'package:dio/dio.dart';

import '../../services/authenticated_dio.dart';
import '../config/shop_constants.dart';

/// Optional Laravel shop extensions (ads, analytics batch, social commerce).
///
/// Paths use [ShopApiPaths] under [ApiConfig.baseUrl] — e.g. `https://host/api` +
/// `/shop/ads/campaigns` — aligned with [ShopService], not `/v1/shop/...`.
///
/// Failures return empty/false so UI stays usable when routes are absent server-side.
class ShopExtendedApi {
  ShopExtendedApi({Dio? dio}) : _dio = dio ?? AuthenticatedDio.instance;

  final Dio _dio;

  /// [userId] optional query fallback; Laravel prefers Sanctum user from Bearer token.
  Future<List<Map<String, dynamic>>> listAdCampaigns({int? userId}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ShopApiPaths.adsCampaigns,
        queryParameters: userId != null ? <String, dynamic>{'user_id': userId} : null,
      );
      final data = res.data?['data'];
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> postAnalyticsEvents(List<Map<String, dynamic>> events) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ShopApiPaths.analyticsEventsBatch,
        data: {'events': events},
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Social commerce — boost an existing feed post.
  Future<bool> boostProductPost({
    required int postId,
    int budgetMinorUnits = 0,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ShopApiPaths.socialCommerceBoostPost(postId),
        data: {'budget_minor_units': budgetMinorUnits},
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Seller ads — create campaign (`POST` body matches Laravel validation).
  Future<bool> createShopAd(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ShopApiPaths.adsCampaigns,
        data: body,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Social commerce — publish a product-tagged post.
  Future<bool> publishProductPost(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ShopApiPaths.socialCommercePosts,
        data: body,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
