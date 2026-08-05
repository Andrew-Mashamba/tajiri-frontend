import '../../../models/shop_models.dart';
import '../../data/repositories/shop_repository.dart';

/// Validate promo — delegates to [ShopRepository.validatePromoCode].
class ApplyCoupon {
  ApplyCoupon({ShopRepository? repo}) : _repo = repo ?? ShopRepository.instance;

  final ShopRepository _repo;

  Future<PromoCodeResult> execute({
    required String code,
    required int userId,
  }) =>
      _repo.validatePromoCode(code: code, userId: userId);
}
