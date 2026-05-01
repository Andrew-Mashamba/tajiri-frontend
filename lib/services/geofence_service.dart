import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Spec F4 #22 — geofence-triggered "Arrived" for mafundi service requests.
///
/// Flutter-side wrapper around `geolocator`. The mafundi partner-facing
/// status page calls [start] when the partner taps "Niko njiani" with the
/// customer's lat/lng. We poll position every [pollSeconds] and fire
/// [onArrived] once the partner crosses [radiusMeters] of the destination.
/// This is intentionally polling-based rather than native geofence
/// services so it works on stock Android + iOS without extra native code.
class GeofenceService {
  StreamSubscription<Position>? _sub;
  Timer? _poll;
  bool _arrived = false;

  /// Begin watching the partner's position relative to [destLat, destLng].
  /// Returns false when location permission is denied or services are off.
  Future<bool> start({
    required double destLat,
    required double destLng,
    double radiusMeters = 100,
    int pollSeconds = 15,
    required void Function() onArrived,
  }) async {
    final ok = await _ensurePermission();
    if (!ok) return false;

    Future<void> tick() async {
      if (_arrived) return;
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        );
        final dist = _haversineMeters(
            pos.latitude, pos.longitude, destLat, destLng);
        debugPrint('[GeofenceService] dist=${dist.toStringAsFixed(0)}m');
        if (dist <= radiusMeters) {
          _arrived = true;
          onArrived();
          await stop();
        }
      } catch (e) {
        debugPrint('[GeofenceService] poll error: $e');
      }
    }

    await tick();
    _poll = Timer.periodic(Duration(seconds: pollSeconds), (_) => tick());
    return true;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _poll?.cancel();
    _poll = null;
  }

  static Future<bool> _ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    return p == LocationPermission.always ||
        p == LocationPermission.whileInUse;
  }

  /// Haversine distance in metres.
  static double _haversineMeters(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  static double _deg2rad(double d) => d * math.pi / 180.0;
}
