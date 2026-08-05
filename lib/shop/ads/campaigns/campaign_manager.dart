import '../../integrations/shop_extended_api.dart';

/// Thin client for seller ad campaigns when `GET …/api/shop/ads/campaigns` is enabled (see `ShopService` URL shape).
class CampaignManager {
  CampaignManager({ShopExtendedApi? api}) : _api = api ?? ShopExtendedApi();

  final ShopExtendedApi _api;

  /// Pass seller [userId] so Laravel can resolve campaigns (`GET /shop/ads/campaigns`).
  Future<List<Map<String, dynamic>>> loadCampaigns({required int userId}) =>
      _api.listAdCampaigns(userId: userId);
}
