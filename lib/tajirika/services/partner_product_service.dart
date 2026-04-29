import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/tajirika_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

void _log(String message) {
  debugPrint('[PartnerProductService] $message');
}

String _snippet(String body, [int max = 300]) {
  final trimmed = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  return trimmed.length <= max ? trimmed : '${trimmed.substring(0, max)}…';
}

class PartnerProductService {
  static Future<PartnerProductPhotoUploadResult> uploadPhoto({
    required int userId,
    required File file,
  }) async {
    final url = '$_baseUrl/tajirika/partner-products/photo';
    _log('UPLOAD $url userId=$userId path=${file.path}');
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['user_id'] = '$userId';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      _log('uploadPhoto status=${response.statusCode} body=${_snippet(response.body)}');
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final photoUrl = (body['data']?['url'] as String?) ?? '';
        return PartnerProductPhotoUploadResult(success: true, photoUrl: photoUrl);
      }
      return PartnerProductPhotoUploadResult(
        success: false,
        message: body['message']?.toString() ?? 'Upload failed',
      );
    } catch (e, stack) {
      _log('uploadPhoto error: $e');
      _log('stack: $stack');
      return PartnerProductPhotoUploadResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerProductListResult> listProducts({
    int? partnerId,
    int? userId,
    bool mine = false,
    String? skillCategory,
    String? domain,
    String? kind,
    bool activeOnly = true,
    String? query,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final params = <String, String>{
        'limit': '$limit',
        'offset': '$offset',
      };
      if (partnerId != null) params['partner_id'] = '$partnerId';
      if (mine && userId != null) {
        params['mine'] = '1';
        params['user_id'] = '$userId';
      }
      if (skillCategory != null && skillCategory.isNotEmpty) {
        params['skill_category'] = skillCategory;
      }
      if (domain != null && domain.isNotEmpty) params['domain'] = domain;
      if (kind != null && kind.isNotEmpty) params['kind'] = kind;
      if (activeOnly) params['active'] = '1';
      if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();

      final uri = Uri.parse('$_baseUrl/tajirika/partner-products').replace(
        queryParameters: params,
      );
      _log('GET $uri');
      final res = await http.get(uri);
      _log('listProducts status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final items = (body['data'] as List)
            .whereType<Map>()
            .map((m) => PartnerProduct.fromJson(m.cast<String, dynamic>()))
            .toList();
        return PartnerProductListResult(success: true, products: items);
      }
      return PartnerProductListResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
      );
    } catch (e, stack) {
      _log('listProducts error: $e');
      _log('stack: $stack');
      return PartnerProductListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerProductResult> getProduct(int id) async {
    final url = '$_baseUrl/tajirika/partner-products/$id';
    _log('GET $url');
    try {
      final res = await http.get(Uri.parse(url));
      _log('getProduct status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        return PartnerProductResult(
          success: true,
          product: PartnerProduct.fromJson(
              (body['data'] as Map).cast<String, dynamic>()),
        );
      }
      if (res.statusCode == 404) {
        return PartnerProductResult(success: false, message: 'not_found');
      }
      return PartnerProductResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
      );
    } catch (e, stack) {
      _log('getProduct error: $e');
      _log('stack: $stack');
      return PartnerProductResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerProductResult> createProduct({
    required int userId,
    required String skillCategory,
    required String domain,
    PartnerProductKind kind = PartnerProductKind.standard,
    bool isProductized = false,
    String? catalogSkuCode,
    required String title,
    String? description,
    required int basePriceTzs,
    int leadTimeHours = 24,
    int minQuantity = 1,
    String mode = 'pickup_only',
    int? deliveryRadiusKm,
    int? deliveryFeePerKmTzs,
    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,
    List<String> tags = const [],
    List<String> dietaryTags = const [],
    List<String> hairTypes = const [],
    int? amcVisitCount,
    int? amcValidityMonths,
    int? rebookCadenceDays,
    int? travelSurchargeTzs,
    int? afterHoursSurchargeTzs,
    int? holidayPremiumTzs,
    int? parkingPassThroughTzs,
    List<String> photos = const [],
    List<PartnerProductVariant> variants = const [],
  }) async {
    final url = '$_baseUrl/tajirika/partner-products';
    _log('POST $url userId=$userId skill=$skillCategory kind=${kind.apiValue}');
    try {
      final payload = <String, dynamic>{
        'user_id': userId,
        'skill_category': skillCategory,
        'domain': domain,
        'kind': kind.apiValue,
        'is_productized': isProductized,
        if (catalogSkuCode != null && catalogSkuCode.isNotEmpty)
          'catalog_sku_code': catalogSkuCode,
        'title': title,
        if (description != null && description.isNotEmpty) 'description': description,
        'base_price_tzs': basePriceTzs,
        'lead_time_hours': leadTimeHours,
        'min_quantity': minQuantity,
        'mode': mode,
        if (deliveryRadiusKm != null) 'delivery_radius_km': deliveryRadiusKm,
        if (deliveryFeePerKmTzs != null) 'delivery_fee_per_km_tzs': deliveryFeePerKmTzs,
        if (pickupAddress != null && pickupAddress.isNotEmpty) 'pickup_address': pickupAddress,
        if (pickupLat != null) 'pickup_lat': pickupLat,
        if (pickupLng != null) 'pickup_lng': pickupLng,
        'tags': tags,
        if (dietaryTags.isNotEmpty) 'dietary_tags': dietaryTags,
        if (hairTypes.isNotEmpty) 'hair_types': hairTypes,
        if (amcVisitCount != null) 'amc_visit_count': amcVisitCount,
        if (amcValidityMonths != null) 'amc_validity_months': amcValidityMonths,
        if (rebookCadenceDays != null) 'rebook_cadence_days': rebookCadenceDays,
        if (travelSurchargeTzs != null) 'travel_surcharge_tzs': travelSurchargeTzs,
        if (afterHoursSurchargeTzs != null) 'after_hours_surcharge_tzs': afterHoursSurchargeTzs,
        if (holidayPremiumTzs != null) 'holiday_premium_tzs': holidayPremiumTzs,
        if (parkingPassThroughTzs != null) 'parking_pass_through_tzs': parkingPassThroughTzs,
        'photos': photos,
        if (variants.isNotEmpty)
          'variants': variants.map((v) => v.toCreatePayload()).toList(),
      };
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(payload),
      );
      _log('createProduct status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          body['success'] == true) {
        return PartnerProductResult(
          success: true,
          product: PartnerProduct.fromJson(
              (body['data'] as Map).cast<String, dynamic>()),
        );
      }
      return PartnerProductResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
      );
    } catch (e, stack) {
      _log('createProduct error: $e');
      _log('stack: $stack');
      return PartnerProductResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerProductResult> updateProduct({
    required int productId,
    required int userId,
    String? title,
    String? description,
    int? basePriceTzs,
    int? leadTimeHours,
    int? minQuantity,
    String? mode,
    int? deliveryRadiusKm,
    int? deliveryFeePerKmTzs,
    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,
    PartnerProductKind? kind,
    bool? isProductized,
    String? catalogSkuCode,
    bool? isActive,
    List<String>? tags,
    List<String>? dietaryTags,
    List<String>? hairTypes,
    int? amcVisitCount,
    int? amcValidityMonths,
    int? rebookCadenceDays,
    int? travelSurchargeTzs,
    int? afterHoursSurchargeTzs,
    int? holidayPremiumTzs,
    int? parkingPassThroughTzs,
    List<String>? photos,
    List<PartnerProductVariant>? variants,
  }) async {
    final url = '$_baseUrl/tajirika/partner-products/$productId';
    _log('PATCH $url userId=$userId');
    try {
      final payload = <String, dynamic>{
        'user_id': userId,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (basePriceTzs != null) 'base_price_tzs': basePriceTzs,
        if (leadTimeHours != null) 'lead_time_hours': leadTimeHours,
        if (minQuantity != null) 'min_quantity': minQuantity,
        if (mode != null) 'mode': mode,
        if (deliveryRadiusKm != null) 'delivery_radius_km': deliveryRadiusKm,
        if (deliveryFeePerKmTzs != null) 'delivery_fee_per_km_tzs': deliveryFeePerKmTzs,
        if (pickupAddress != null) 'pickup_address': pickupAddress,
        if (pickupLat != null) 'pickup_lat': pickupLat,
        if (pickupLng != null) 'pickup_lng': pickupLng,
        if (kind != null) 'kind': kind.apiValue,
        if (isProductized != null) 'is_productized': isProductized,
        if (catalogSkuCode != null) 'catalog_sku_code': catalogSkuCode,
        if (isActive != null) 'is_active': isActive,
        if (tags != null) 'tags': tags,
        if (dietaryTags != null) 'dietary_tags': dietaryTags,
        if (hairTypes != null) 'hair_types': hairTypes,
        if (amcVisitCount != null) 'amc_visit_count': amcVisitCount,
        if (amcValidityMonths != null) 'amc_validity_months': amcValidityMonths,
        if (rebookCadenceDays != null) 'rebook_cadence_days': rebookCadenceDays,
        if (travelSurchargeTzs != null) 'travel_surcharge_tzs': travelSurchargeTzs,
        if (afterHoursSurchargeTzs != null) 'after_hours_surcharge_tzs': afterHoursSurchargeTzs,
        if (holidayPremiumTzs != null) 'holiday_premium_tzs': holidayPremiumTzs,
        if (parkingPassThroughTzs != null) 'parking_pass_through_tzs': parkingPassThroughTzs,
        if (photos != null) 'photos': photos,
        if (variants != null)
          'variants': variants.map((v) => v.toCreatePayload()).toList(),
      };
      final res = await http.patch(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(payload),
      );
      _log('updateProduct status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        return PartnerProductResult(
          success: true,
          product: PartnerProduct.fromJson(
              (body['data'] as Map).cast<String, dynamic>()),
        );
      }
      return PartnerProductResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
      );
    } catch (e, stack) {
      _log('updateProduct error: $e');
      _log('stack: $stack');
      return PartnerProductResult(success: false, message: 'Kosa: $e');
    }
  }

  /// POST /tajirika/partner-products/{id}/order
  /// Returns the created customer order on success.
  static Future<PartnerProductOrderResult> placeOrder({
    required int productId,
    required int userId,
    int quantity = 1,
    String deliveryMode = 'pickup',
    String? deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
    DateTime? requestedFor,
    String? notes,
    int? variantId,
  }) async {
    final url = '$_baseUrl/tajirika/partner-products/$productId/order';
    _log('POST $url userId=$userId qty=$quantity mode=$deliveryMode');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'quantity': quantity,
          'delivery_mode': deliveryMode,
          if (deliveryAddress != null && deliveryAddress.isNotEmpty)
            'delivery_address': deliveryAddress,
          if (deliveryLat != null) 'delivery_lat': deliveryLat,
          if (deliveryLng != null) 'delivery_lng': deliveryLng,
          if (requestedFor != null)
            'requested_for': requestedFor.toUtc().toIso8601String(),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (variantId != null) 'variant_id': variantId,
        }),
      );
      _log('placeOrder status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) && body['success'] == true) {
        final data = body['data'];
        return PartnerProductOrderResult(
          success: true,
          orderId: data is Map && data['id'] != null
              ? int.tryParse('${data['id']}')
              : null,
          totalTzs: data is Map && data['total_price_tzs'] != null
              ? int.tryParse('${data['total_price_tzs']}')
              : null,
        );
      }
      return PartnerProductOrderResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
      );
    } catch (e, stack) {
      _log('placeOrder error: $e');
      _log('stack: $stack');
      return PartnerProductOrderResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerProductResult> deleteProduct({
    required int productId,
    required int userId,
  }) async {
    final url = '$_baseUrl/tajirika/partner-products/$productId';
    _log('DELETE $url userId=$userId');
    try {
      final res = await http.delete(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      _log('deleteProduct status=${res.statusCode} body=${_snippet(res.body)}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        return PartnerProductResult(success: true);
      }
      return PartnerProductResult(
        success: false,
        message: body['message']?.toString() ?? 'HTTP ${res.statusCode}',
      );
    } catch (e, stack) {
      _log('deleteProduct error: $e');
      _log('stack: $stack');
      return PartnerProductResult(success: false, message: 'Kosa: $e');
    }
  }
}
