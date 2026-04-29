import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../models/property_listing.dart';

/// Spec line 936 — polygon-bounded property search backed by PostGIS
/// `ST_Covers()`. Caller passes a list of lat/lng vertices (≥3) plus
/// optional filters; backend returns listings whose `geo` falls inside.
class PolygonSearchService {
  static Future<List<PropertyListing>> search({
    required List<({double lat, double lng})> points,
    String? listingKind,
    String? propertyType,
    int? minPriceTzs,
    int? maxPriceTzs,
    int? bedrooms,
  }) async {
    if (points.length < 3) return const [];
    final body = <String, dynamic>{
      'points': points
          .map((p) => {'lat': p.lat, 'lng': p.lng})
          .toList(),
    };
    final params = <String, String>{};
    if (listingKind != null) params['listing_kind'] = listingKind;
    if (propertyType != null) params['property_type'] = propertyType;
    if (minPriceTzs != null) params['min_price_tzs'] = '$minPriceTzs';
    if (maxPriceTzs != null) params['max_price_tzs'] = '$maxPriceTzs';
    if (bedrooms != null) params['bedrooms'] = '$bedrooms';

    final uri = Uri.parse('${ApiConfig.baseUrl}/listings/search-polygon')
        .replace(queryParameters: params.isEmpty ? null : params);
    try {
      final res = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode != 200) return const [];
      final r = jsonDecode(res.body);
      if (r['success'] != true) return const [];
      return ((r['data'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => PropertyListing.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      debugPrint('[PolygonSearchService] error: $e');
      return const [];
    }
  }

  /// Convenience: Tanzania Dar-es-Salaam bounding box example for callers
  /// that want an "Anywhere in Dar" preset until the user draws their own.
  static List<({double lat, double lng})> daresSalaamBoundingBox() {
    return const [
      (lat: -6.65, lng: 39.10),
      (lat: -6.65, lng: 39.45),
      (lat: -7.00, lng: 39.45),
      (lat: -7.00, lng: 39.10),
    ];
  }
}
