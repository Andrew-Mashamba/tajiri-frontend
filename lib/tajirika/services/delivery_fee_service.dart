import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

class DeliveryFeeResult {
  final bool success;
  final double? distanceKm;
  final int? feeTzs;
  final String? method;
  final String? message;

  DeliveryFeeResult({
    required this.success,
    this.distanceKm,
    this.feeTzs,
    this.method,
    this.message,
  });
}

/// Calculates real delivery fee using GPS distance.
/// Falls back to static estimate if location unavailable or API fails.
class DeliveryFeeService {
  static Future<DeliveryFeeResult> calculate({
    required double partnerLat,
    required double partnerLng,
    required int perKmTzs,
    required int maxFeeTzs,
  }) async {
    try {
      // 1. Get customer location
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return DeliveryFeeResult(
          success: false,
          message: 'Location services disabled',
        );
      }
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        return DeliveryFeeResult(
          success: false,
          message: 'Location permission denied',
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );

      // 2. Call backend distance endpoint
      final uri = Uri.parse('$_baseUrl/delivery-fee').replace(queryParameters: {
        'from_lat': pos.latitude.toString(),
        'from_lng': pos.longitude.toString(),
        'to_lat': partnerLat.toString(),
        'to_lng': partnerLng.toString(),
        'per_km': perKmTzs.toString(),
        'max_fee': maxFeeTzs.toString(),
      });

      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode != 200) {
        return DeliveryFeeResult(
          success: false,
          message: 'HTTP ${res.statusCode}',
        );
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] != true) {
        return DeliveryFeeResult(
          success: false,
          message: body['message']?.toString() ?? 'Failed',
        );
      }

      final data = body['data'] as Map<String, dynamic>?;
      return DeliveryFeeResult(
        success: true,
        distanceKm: (data?['distance_km'] as num?)?.toDouble(),
        feeTzs: (data?['fee_tzs'] as num?)?.toInt(),
        method: data?['calculation_method']?.toString(),
      );
    } catch (e) {
      debugPrint('[DeliveryFeeService] error: $e');
      return DeliveryFeeResult(success: false, message: 'Error: $e');
    }
  }
}
