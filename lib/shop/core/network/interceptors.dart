import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Optional diagnostics for shop-network debugging.
///
/// **Do not** duplicate Sanctum interceptors here — see `AuthenticatedDio`.
class ShopNetworkLogging {
  ShopNetworkLogging._();

  static bool _attached = false;

  /// Idempotent attach — avoids duplicate log spam if multiple callers bootstrap.
  static void attachIfDebug(Dio dio) {
    if (!kDebugMode || _attached) return;
    _attached = true;
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: false,
        error: true,
      ),
    );
  }
}
