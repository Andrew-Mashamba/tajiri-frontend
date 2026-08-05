import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../services/http_retry.dart';
import '../../config/api_config.dart';
import '../models/property_listing.dart';

String get _baseUrl => ApiConfig.baseUrl;

void _log(String m) => debugPrint('[PropertyListingService] $m');

String _snippet(String body, [int max = 300]) {
  final t = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.length <= max ? t : '${t.substring(0, max)}…';
}

class PropertyListingService {
  static Future<PropertyListingResult> create({
    required int userId,
    required String title,
    required String description,
    required ListingKind listingKind,
    required PropertyType propertyType,
    required int priceTzs,
    int? partnerId,
    String? region,
    String? district,
    String? ward,
    String? street,
    double? lat,
    double? lng,
    PriceFrequency? priceFrequency,
    int? bedrooms,
    int? bathrooms,
    int? areaSqm,
    int? plotSizeSqm,
    List<String>? amenities,
    List<String>? photos,
  }) async {
    final url = '$_baseUrl/property-listings';
    _log('POST $url kind=${listingKind.apiValue} type=${propertyType.apiValue}');
    try {
      final body = <String, dynamic>{
        'partner_user_id': userId,
        'title': title,
        'description': description,
        'listing_kind': listingKind.apiValue,
        'property_type': propertyType.apiValue,
        'price_tzs': priceTzs,
      };
      if (partnerId != null) body['partner_id'] = partnerId;
      if (region != null && region.isNotEmpty) body['region'] = region;
      if (district != null && district.isNotEmpty) body['district'] = district;
      if (ward != null && ward.isNotEmpty) body['ward'] = ward;
      if (street != null && street.isNotEmpty) body['street'] = street;
      if (lat != null) body['lat'] = lat;
      if (lng != null) body['lng'] = lng;
      if (priceFrequency != null) body['price_frequency'] = priceFrequency.apiValue;
      if (bedrooms != null) body['bedrooms'] = bedrooms;
      if (bathrooms != null) body['bathrooms'] = bathrooms;
      if (areaSqm != null) body['area_sqm'] = areaSqm;
      if (plotSizeSqm != null) body['plot_size_sqm'] = plotSizeSqm;
      if (amenities != null && amenities.isNotEmpty) body['amenities'] = amenities;
      if (photos != null && photos.isNotEmpty) body['photos'] = photos;

      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _log('create status=${res.statusCode} body=${_snippet(res.body)}');
      return _decodeOne(res);
    } catch (e, s) {
      _log('create error: $e\n$s');
      return PropertyListingResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PropertyListingResult> update({
    required int id,
    required int userId,
    String? title,
    String? description,
    ListingKind? listingKind,
    PropertyType? propertyType,
    String? region,
    String? district,
    String? ward,
    String? street,
    double? lat,
    double? lng,
    int? priceTzs,
    PriceFrequency? priceFrequency,
    int? bedrooms,
    int? bathrooms,
    int? areaSqm,
    int? plotSizeSqm,
    List<String>? amenities,
    List<String>? photos,
  }) async {
    final url = '$_baseUrl/property-listings/$id';
    final body = <String, dynamic>{'user_id': userId};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (listingKind != null) body['listing_kind'] = listingKind.apiValue;
    if (propertyType != null) body['property_type'] = propertyType.apiValue;
    if (region != null) body['region'] = region;
    if (district != null) body['district'] = district;
    if (ward != null) body['ward'] = ward;
    if (street != null) body['street'] = street;
    if (lat != null) body['lat'] = lat;
    if (lng != null) body['lng'] = lng;
    if (priceTzs != null) body['price_tzs'] = priceTzs;
    if (priceFrequency != null) body['price_frequency'] = priceFrequency.apiValue;
    if (bedrooms != null) body['bedrooms'] = bedrooms;
    if (bathrooms != null) body['bathrooms'] = bathrooms;
    if (areaSqm != null) body['area_sqm'] = areaSqm;
    if (plotSizeSqm != null) body['plot_size_sqm'] = plotSizeSqm;
    if (amenities != null) body['amenities'] = amenities;
    if (photos != null) body['photos'] = photos;
    _log('PATCH $url body=${jsonEncode(body)}');
    try {
      final res = await http.patch(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return _decodeOne(res);
    } catch (e, s) {
      _log('update error: $e\n$s');
      return PropertyListingResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PropertyListingListResult> list({
    int? ownerUserId,
    ListingKind? listingKind,
    PropertyType? propertyType,
    String? region,
    String? district,
    String? ward,
    int? minPriceTzs,
    int? maxPriceTzs,
    int? bedrooms,
    bool includeInactive = false,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
    };
    if (ownerUserId != null) params['owner_user_id'] = '$ownerUserId';
    if (listingKind != null) params['listing_kind'] = listingKind.apiValue;
    if (propertyType != null) params['property_type'] = propertyType.apiValue;
    if (region != null && region.isNotEmpty) params['region'] = region;
    if (district != null && district.isNotEmpty) params['district'] = district;
    if (ward != null && ward.isNotEmpty) params['ward'] = ward;
    if (minPriceTzs != null) params['min_price_tzs'] = '$minPriceTzs';
    if (maxPriceTzs != null) params['max_price_tzs'] = '$maxPriceTzs';
    if (bedrooms != null) params['bedrooms'] = '$bedrooms';
    if (includeInactive) params['include_inactive'] = '1';

    final uri = Uri.parse('$_baseUrl/property-listings').replace(queryParameters: params);
    _log('GET $uri');
    try {
      final res = await httpGetWithRetry(uri);
      _log('list status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final items = (body['data'] as List)
            .whereType<Map>()
            .map((m) => PropertyListing.fromJson(m.cast<String, dynamic>()))
            .toList();
        return PropertyListingListResult(success: true, items: items);
      }
      return PropertyListingListResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e, s) {
      _log('list error: $e\n$s');
      return PropertyListingListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PropertyListingResult> get({required int id, int? viewerUserId}) async {
    final params = <String, String>{};
    if (viewerUserId != null) params['user_id'] = '$viewerUserId';
    final uri = Uri.parse('$_baseUrl/property-listings/$id')
        .replace(queryParameters: params.isEmpty ? null : params);
    _log('GET $uri');
    try {
      final res = await httpGetWithRetry(uri);
      return _decodeOne(res);
    } catch (e, s) {
      _log('get error: $e\n$s');
      return PropertyListingResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PropertyListingResult> toggleActive({required int id, required int userId}) async {
    final url = '$_baseUrl/property-listings/$id/toggle-active';
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return _decodeOne(res);
    } catch (e, s) {
      _log('toggleActive error: $e\n$s');
      return PropertyListingResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<bool> delete({required int id, required int userId}) async {
    final url = '$_baseUrl/property-listings/$id?user_id=$userId';
    try {
      final res = await http.delete(Uri.parse(url));
      final body = jsonDecode(res.body);
      return res.statusCode == 200 && body['success'] == true;
    } catch (e, s) {
      _log('delete error: $e\n$s');
      return false;
    }
  }

  static Future<PropertyListingPhotoUploadResult> uploadPhoto({
    required int userId,
    required File file,
  }) async {
    final url = '$_baseUrl/property-listings/photo';
    _log('POST(multipart) $url userId=$userId path=${file.path}');
    try {
      final req = http.MultipartRequest('POST', Uri.parse(url));
      req.fields['user_id'] = '$userId';
      req.files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      _log('uploadPhoto status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        return PropertyListingPhotoUploadResult(
          success: true,
          url: (body['data'] as Map)['url']?.toString(),
          statusCode: res.statusCode,
        );
      }
      return PropertyListingPhotoUploadResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e, s) {
      _log('uploadPhoto error: $e\n$s');
      return PropertyListingPhotoUploadResult(success: false, message: 'Kosa: $e');
    }
  }

  static PropertyListingResult _decodeOne(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
        return PropertyListingResult(
          success: true,
          listing: PropertyListing.fromJson((body['data'] as Map).cast<String, dynamic>()),
          statusCode: res.statusCode,
        );
      }
      return PropertyListingResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (e) {
      return PropertyListingResult(success: false, message: 'Decode error: $e', statusCode: res.statusCode);
    }
  }
}
