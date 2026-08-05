import '../../integrations/shop_extended_api.dart';

class BoostProductPost {
  BoostProductPost({ShopExtendedApi? api}) : _api = api ?? ShopExtendedApi();

  final ShopExtendedApi _api;

  Future<bool> execute({
    required int postId,
    int budgetMinorUnits = 0,
  }) =>
      _api.boostProductPost(
        postId: postId,
        budgetMinorUnits: budgetMinorUnits,
      );
}
