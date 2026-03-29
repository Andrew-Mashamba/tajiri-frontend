import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_service.dart';
import 'local_storage_service.dart';

/// Manages AdMob ad loading and revenue reporting for TAJIRI placements.
class AdMobService {
  // Test IDs (used in debug mode)
  static const _testNativeId = 'ca-app-pub-3940256099942544/2247696110';
  static const _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  static String get _nativeAdUnitId {
    if (kDebugMode) return _testNativeId;
    // Production IDs would be stored server-side and fetched via client settings.
    // For now, fall back to test IDs.
    return _testNativeId;
  }

  static String get _interstitialAdUnitId {
    if (kDebugMode) return _testInterstitialId;
    return _testInterstitialId;
  }

  /// Load a native ad for [placement] (e.g. 'feed', 'discover').
  static Future<NativeAd?> loadNativeAd(String placement) async {
    try {
      final completer = Completer<NativeAd?>();
      final ad = NativeAd(
        adUnitId: _nativeAdUnitId,
        factoryId: 'adFactoryNative',
        listener: NativeAdListener(
          onAdLoaded: (ad) => completer.complete(ad as NativeAd),
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            completer.complete(null);
          },
          onPaidEvent: (ad, valueMicros, precision, currencyCode) {
            _reportRevenue(placement, valueMicros, currencyCode);
          },
        ),
        request: const AdRequest(),
      );
      ad.load();
      return completer.future;
    } catch (e) {
      debugPrint('[AdMobService] NativeAd load error: $e');
      return null;
    }
  }

  /// Load an interstitial ad for [placement] (e.g. 'story', 'clips').
  static Future<InterstitialAd?> loadInterstitialAd(String placement) async {
    try {
      final completer = Completer<InterstitialAd?>();
      InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
              _reportRevenue(placement, valueMicros, currencyCode);
            };
            completer.complete(ad);
          },
          onAdFailedToLoad: (error) => completer.complete(null),
        ),
      );
      return completer.future;
    } catch (e) {
      debugPrint('[AdMobService] InterstitialAd load error: $e');
      return null;
    }
  }

  /// Report AdMob revenue to the TAJIRI backend for tracking.
  static Future<void> _reportRevenue(
    String placement,
    double valueMicros,
    String currencyCode,
  ) async {
    try {
      final revenue = valueMicros / 1000000; // Convert micros to standard
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final userId = storage.getUser()?.userId ?? 0;
      await AdService.reportAdMobRevenue(token, userId, placement, revenue);
    } catch (e) {
      debugPrint('[AdMobService] Revenue report error: $e');
    }
  }
}
