// lib/services/network_state_service.dart
//
// App-wide connectivity state. Listens to connectivity_plus and exposes
// a [ValueNotifier<bool>] for "is the device offline right now". The
// flag is connection-type only — actual reachability still requires a
// real HTTP attempt — but it's enough to surface a persistent offline
// banner to the user.
//
// Usage:
//   • main.dart calls `NetworkStateService.instance.start()` once.
//   • Any widget can `ValueListenableBuilder<bool>(valueListenable:
//     NetworkStateService.instance.offline, ...)` to react.
//   • OfflineBannerHost wraps the app body and renders a MaterialBanner
//     when offline is true.

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkStateService {
  NetworkStateService._();
  static final NetworkStateService instance = NetworkStateService._();

  final ValueNotifier<bool> offline = ValueNotifier<bool>(false);

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    final connectivity = Connectivity();
    final initial = await connectivity.checkConnectivity();
    offline.value = _isOffline(initial);
    _sub = connectivity.onConnectivityChanged.listen((results) {
      offline.value = _isOffline(results);
    });
  }

  bool _isOffline(List<ConnectivityResult> results) {
    if (results.isEmpty) return true;
    return results.every((r) => r == ConnectivityResult.none);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _started = false;
  }
}
