// lib/qibla/services/qibla_service.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/qibla_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

/// Kaaba coordinates
const double _kaabaLat = 21.4225;
const double _kaabaLng = 39.8262;

class QiblaService {
  // ─── Calculate Qibla Bearing (Offline) ──────────────────────
  static QiblaDirection calculateOffline({
    required double latitude,
    required double longitude,
    String locationName = '',
  }) {
    final bearing = _greatCircleBearing(latitude, longitude);
    final distance = _haversineDistance(latitude, longitude);
    return QiblaDirection(
      bearing: bearing,
      distanceKm: distance,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
    );
  }

  // ─── Fetch Qibla from Server (with declination) ────────────
  Future<SingleResult<QiblaDirection>> getQiblaDirection({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/qibla/direction').replace(
        queryParameters: {
          'latitude': '$latitude',
          'longitude': '$longitude',
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return SingleResult(
            success: true,
            data: QiblaDirection.fromJson(data['data']),
          );
        }
      }
      // Fallback to offline calculation
      return SingleResult(
        success: true,
        data: calculateOffline(latitude: latitude, longitude: longitude),
      );
    } catch (_) {
      return SingleResult(
        success: true,
        data: calculateOffline(latitude: latitude, longitude: longitude),
      );
    }
  }

  // ─── Great Circle Bearing ───────────────────────────────────
  static double _greatCircleBearing(double lat, double lng) {
    final lat1 = lat * math.pi / 180;
    final lng1 = lng * math.pi / 180;
    final lat2 = _kaabaLat * math.pi / 180;
    final lng2 = _kaabaLng * math.pi / 180;

    final dLng = lng2 - lng1;
    final x = math.sin(dLng) * math.cos(lat2);
    final y = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    var bearing = math.atan2(x, y) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  // ─── Haversine Distance ─────────────────────────────────────
  static double _haversineDistance(double lat, double lng) {
    const r = 6371.0; // Earth radius km
    final dLat = (_kaabaLat - lat) * math.pi / 180;
    final dLng = (_kaabaLng - lng) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat * math.pi / 180) *
            math.cos(_kaabaLat * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
