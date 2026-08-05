import '../../integrations/shop_extended_api.dart';

class CreateShopAd {
  CreateShopAd({ShopExtendedApi? api}) : _api = api ?? ShopExtendedApi();

  final ShopExtendedApi _api;

  Future<bool> execute(Map<String, dynamic> body) => _api.createShopAd(body);
}
