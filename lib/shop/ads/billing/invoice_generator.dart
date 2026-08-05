// Blueprint: docs/shop/shop.md — services/InvoiceGenerator
import '../../integrations/shop_extended_api.dart';
import '../../data/repositories/shop_repository.dart';

class InvoiceGenerator {
  InvoiceGenerator({ShopExtendedApi? api, ShopRepository? repo})
      : _api = api ?? ShopExtendedApi(),
        _repo = repo ?? ShopRepository.instance;
  final ShopExtendedApi _api;
  final ShopRepository _repo;

  ShopExtendedApi get api => _api;
  ShopRepository get repository => _repo;
}
