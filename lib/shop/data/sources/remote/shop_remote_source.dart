// Generated for docs/shop/shop.md — see data/sources/remote/shop_remote_source.dart
import '../../repositories/shop_repository.dart';

/// Remote API source wrapping [`ShopRepository`].
class ShopRemoteSource {
  ShopRemoteSource({ShopRepository? repo}) : _repo = repo ?? ShopRepository.instance;
  final ShopRepository _repo;
  ShopRepository get repository => _repo;
}
