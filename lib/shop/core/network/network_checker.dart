// Generated for docs/shop/shop.md — see core/network/network_checker.dart
import '../../../services/network_state_service.dart';

class ShopNetworkChecker {
  static bool get hasConnection =>
      !NetworkStateService.instance.offline.value;
}
