import 'dart:io';

import '../../tajirika/models/partner_product.dart';
import '../../tajirika/models/product_variant.dart';
import 'graphql_media_service.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL Tajirika partner products (Phases 148–150).
class GraphqlPartnerProductService {
  static const _productFields = r'''
    id
    partnerId
    partnerUserId
    partnerName
    partnerPhotoUrl
    partnerRegion
    partnerDistrict
    partnerJobSuccessScore
    skillCategory
    domain
    kind
    isProductized
    catalogSkuCode
    title
    description
    basePriceTzs
    leadTimeHours
    minQuantity
    mode
    deliveryRadiusKm
    deliveryFeePerKmTzs
    travelRadiusKm
    travelPerKmTzs
    pickupAddress
    pickupLat
    pickupLng
    tags
    dietaryTags
    hairTypes
    photos
    coverPhotoUrl
    amcVisitCount
    amcValidityMonths
    rebookCadenceDays
    travelSurchargeTzs
    afterHoursSurchargeTzs
    holidayPremiumTzs
    parkingPassThroughTzs
    variants {
      id
      partnerProductId
      labelSw
      labelEn
      priceTzs
      leadTimeHours
      durationMinutes
      sortOrder
      isActive
    }
    aiCostAnchorTzs
    lastMinuteDiscountPct
    partnerRating
    legalPackDeliverables
    isActive
    isInStock
    photoConsentGiven
    createdAt
    siteSurveyFeeTzs
    requiresPatchTest
    addOns
    cancellationPolicyTiers
  ''';

  static Map<String, dynamic> _productToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'partner_id': int.tryParse(row['partnerId']?.toString() ?? '') ?? 0,
      if (row['partnerUserId'] != null)
        'partner_user_id': int.tryParse(row['partnerUserId'].toString()),
      if (row['partnerName'] != null) 'partner_name': row['partnerName'],
      if (row['partnerPhotoUrl'] != null) 'partner_photo_url': row['partnerPhotoUrl'],
      if (row['partnerRegion'] != null) 'partner_region': row['partnerRegion'],
      if (row['partnerDistrict'] != null) 'partner_district': row['partnerDistrict'],
      if (row['partnerJobSuccessScore'] != null)
        'partner_job_success_score': row['partnerJobSuccessScore'],
      'skill_category': row['skillCategory'] ?? '',
      'domain': row['domain'] ?? '',
      'kind': row['kind'] ?? 'standard',
      'is_productized': row['isProductized'] ?? false,
      if (row['catalogSkuCode'] != null) 'catalog_sku_code': row['catalogSkuCode'],
      'title': row['title'] ?? '',
      'description': row['description'] ?? '',
      'base_price_tzs': row['basePriceTzs'] ?? 0,
      'lead_time_hours': row['leadTimeHours'] ?? 24,
      'min_quantity': row['minQuantity'] ?? 1,
      'mode': row['mode'] ?? 'pickup_only',
      if (row['deliveryRadiusKm'] != null) 'delivery_radius_km': row['deliveryRadiusKm'],
      if (row['deliveryFeePerKmTzs'] != null)
        'delivery_fee_per_km_tzs': row['deliveryFeePerKmTzs'],
      if (row['travelRadiusKm'] != null) 'travel_radius_km': row['travelRadiusKm'],
      if (row['travelPerKmTzs'] != null) 'travel_per_km_tzs': row['travelPerKmTzs'],
      if (row['pickupAddress'] != null) 'pickup_address': row['pickupAddress'],
      if (row['pickupLat'] != null) 'pickup_lat': row['pickupLat'],
      if (row['pickupLng'] != null) 'pickup_lng': row['pickupLng'],
      'tags': row['tags'] ?? [],
      'dietary_tags': row['dietaryTags'] ?? [],
      'hair_types': row['hairTypes'] ?? [],
      'photos': row['photos'] ?? [],
      if (row['coverPhotoUrl'] != null) 'cover_photo_url': row['coverPhotoUrl'],
      if (row['amcVisitCount'] != null) 'amc_visit_count': row['amcVisitCount'],
      if (row['amcValidityMonths'] != null) 'amc_validity_months': row['amcValidityMonths'],
      if (row['rebookCadenceDays'] != null) 'rebook_cadence_days': row['rebookCadenceDays'],
      if (row['travelSurchargeTzs'] != null) 'travel_surcharge_tzs': row['travelSurchargeTzs'],
      if (row['afterHoursSurchargeTzs'] != null)
        'after_hours_surcharge_tzs': row['afterHoursSurchargeTzs'],
      if (row['holidayPremiumTzs'] != null) 'holiday_premium_tzs': row['holidayPremiumTzs'],
      if (row['parkingPassThroughTzs'] != null)
        'parking_pass_through_tzs': row['parkingPassThroughTzs'],
      'variants': (row['variants'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(
            (v) => {
              'id': int.tryParse(v['id']?.toString() ?? '') ?? 0,
              'partner_product_id':
                  int.tryParse(v['partnerProductId']?.toString() ?? '') ?? 0,
              if (v['labelSw'] != null) 'label_sw': v['labelSw'],
              if (v['labelEn'] != null) 'label_en': v['labelEn'],
              'price_tzs': v['priceTzs'] ?? 0,
              'lead_time_hours': v['leadTimeHours'] ?? 0,
              'duration_minutes': v['durationMinutes'] ?? 0,
              'sort_order': v['sortOrder'] ?? 0,
              'is_active': v['isActive'] ?? true,
            },
          )
          .toList(),
      if (row['aiCostAnchorTzs'] != null) 'ai_cost_anchor_tzs': row['aiCostAnchorTzs'],
      if (row['lastMinuteDiscountPct'] != null)
        'last_minute_discount_pct': row['lastMinuteDiscountPct'],
      if (row['partnerRating'] != null) 'partner_rating': row['partnerRating'],
      'legal_pack_deliverables': row['legalPackDeliverables'] ?? [],
      'is_active': row['isActive'] ?? true,
      'is_in_stock': row['isInStock'] ?? true,
      'photo_consent_given': row['photoConsentGiven'] ?? true,
      'created_at': row['createdAt'] ?? DateTime.now().toIso8601String(),
      if (row['siteSurveyFeeTzs'] != null) 'site_survey_fee_tzs': row['siteSurveyFeeTzs'],
      'requires_patch_test': row['requiresPatchTest'] ?? false,
      'add_ons': row['addOns'] ?? [],
      'cancellation_policy_tiers': row['cancellationPolicyTiers'] ?? [],
    };
  }

  static PartnerProduct _parseProduct(Map<String, dynamic> row) {
    return PartnerProduct.fromJson(_productToLegacy(row));
  }

  static Future<PartnerProductPhotoUploadResult> uploadPhoto({
    required int userId,
    required File file,
  }) async {
    try {
      final uploaded = await GraphqlMediaService.uploadFile(file);
      final path = uploaded?['file_path']?.toString();
      if (path == null) {
        return PartnerProductPhotoUploadResult(
          success: false,
          message: 'Failed to upload photo',
        );
      }
      return PartnerProductPhotoUploadResult(success: true, photoUrl: path);
    } catch (e) {
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
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaPartnerProducts(
          \$partnerId: ID
          \$mine: Boolean
          \$skillCategory: String
          \$domain: String
          \$kind: String
          \$activeOnly: Boolean
          \$query: String
          \$limit: Int
          \$offset: Int
        ) {
          tajirikaPartnerProducts(
            partnerId: \$partnerId
            mine: \$mine
            skillCategory: \$skillCategory
            domain: \$domain
            kind: \$kind
            activeOnly: \$activeOnly
            query: \$query
            limit: \$limit
            offset: \$offset
          ) {
            $_productFields
          }
        }
        ''',
        variables: {
          if (partnerId != null) 'partnerId': partnerId.toString(),
          if (mine) 'mine': true,
          if (skillCategory != null && skillCategory.isNotEmpty)
            'skillCategory': skillCategory,
          if (domain != null && domain.isNotEmpty) 'domain': domain,
          if (kind != null && kind.isNotEmpty) 'kind': kind,
          'activeOnly': activeOnly,
          if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
          'limit': limit,
          'offset': offset,
        },
        auth: mine,
      );
      final rows = data['tajirikaPartnerProducts'] as List<dynamic>? ?? [];
      final products = rows
          .whereType<Map<String, dynamic>>()
          .map(_parseProduct)
          .toList();
      return PartnerProductListResult(success: true, products: products);
    } catch (e) {
      return PartnerProductListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerProductResult> getProduct(int id) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaPartnerProduct(\$productId: ID!) {
          tajirikaPartnerProduct(productId: \$productId) {
            $_productFields
          }
        }
        ''',
        variables: {'productId': id.toString()},
      );
      final row = data['tajirikaPartnerProduct'] as Map<String, dynamic>?;
      if (row == null) {
        return PartnerProductResult(success: false, message: 'not_found');
      }
      return PartnerProductResult(success: true, product: _parseProduct(row));
    } catch (e) {
      return PartnerProductResult(success: false, message: 'Kosa: $e');
    }
  }

  static Map<String, dynamic> _createPayload({
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
  }) {
    return {
      'skillCategory': skillCategory,
      'domain': domain,
      'kind': kind.apiValue,
      'isProductized': isProductized,
      if (catalogSkuCode != null && catalogSkuCode.isNotEmpty)
        'catalogSkuCode': catalogSkuCode,
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      'basePriceTzs': basePriceTzs,
      'leadTimeHours': leadTimeHours,
      'minQuantity': minQuantity,
      'mode': mode,
      if (deliveryRadiusKm != null) 'deliveryRadiusKm': deliveryRadiusKm,
      if (deliveryFeePerKmTzs != null) 'deliveryFeePerKmTzs': deliveryFeePerKmTzs,
      if (pickupAddress != null && pickupAddress.isNotEmpty)
        'pickupAddress': pickupAddress,
      if (pickupLat != null) 'pickupLat': pickupLat,
      if (pickupLng != null) 'pickupLng': pickupLng,
      'tags': tags,
      if (dietaryTags.isNotEmpty) 'dietaryTags': dietaryTags,
      if (hairTypes.isNotEmpty) 'hairTypes': hairTypes,
      if (amcVisitCount != null) 'amcVisitCount': amcVisitCount,
      if (amcValidityMonths != null) 'amcValidityMonths': amcValidityMonths,
      if (rebookCadenceDays != null) 'rebookCadenceDays': rebookCadenceDays,
      if (travelSurchargeTzs != null) 'travelSurchargeTzs': travelSurchargeTzs,
      if (afterHoursSurchargeTzs != null)
        'afterHoursSurchargeTzs': afterHoursSurchargeTzs,
      if (holidayPremiumTzs != null) 'holidayPremiumTzs': holidayPremiumTzs,
      if (parkingPassThroughTzs != null)
        'parkingPassThroughTzs': parkingPassThroughTzs,
      'photos': photos,
      if (variants.isNotEmpty)
        'variants': variants.map((v) => v.toCreatePayload()).toList(),
    };
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
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateTajirikaPartnerProduct(\$input: CreateTajirikaPartnerProductInput!) {
          createTajirikaPartnerProduct(input: \$input) {
            $_productFields
          }
        }
        ''',
        variables: {
          'input': _createPayload(
            skillCategory: skillCategory,
            domain: domain,
            kind: kind,
            isProductized: isProductized,
            catalogSkuCode: catalogSkuCode,
            title: title,
            description: description,
            basePriceTzs: basePriceTzs,
            leadTimeHours: leadTimeHours,
            minQuantity: minQuantity,
            mode: mode,
            deliveryRadiusKm: deliveryRadiusKm,
            deliveryFeePerKmTzs: deliveryFeePerKmTzs,
            pickupAddress: pickupAddress,
            pickupLat: pickupLat,
            pickupLng: pickupLng,
            tags: tags,
            dietaryTags: dietaryTags,
            hairTypes: hairTypes,
            amcVisitCount: amcVisitCount,
            amcValidityMonths: amcValidityMonths,
            rebookCadenceDays: rebookCadenceDays,
            travelSurchargeTzs: travelSurchargeTzs,
            afterHoursSurchargeTzs: afterHoursSurchargeTzs,
            holidayPremiumTzs: holidayPremiumTzs,
            parkingPassThroughTzs: parkingPassThroughTzs,
            photos: photos,
            variants: variants,
          ),
        },
        auth: true,
      );
      final row = data['createTajirikaPartnerProduct'] as Map<String, dynamic>?;
      if (row == null) {
        return PartnerProductResult(success: false, message: 'Failed to create');
      }
      return PartnerProductResult(success: true, product: _parseProduct(row));
    } catch (e) {
      return PartnerProductResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerProductResult> updateProduct({
    required int productId,
    required int userId,
    String? skillCategory,
    String? domain,
    PartnerProductKind? kind,
    bool? isProductized,
    String? catalogSkuCode,
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
    List<String>? tags,
    List<String>? dietaryTags,
    List<String>? hairTypes,
    List<String>? photos,
    bool? isActive,
    int? amcVisitCount,
    int? amcValidityMonths,
    int? rebookCadenceDays,
    int? travelSurchargeTzs,
    int? afterHoursSurchargeTzs,
    int? holidayPremiumTzs,
    int? parkingPassThroughTzs,
    List<PartnerProductVariant>? variants,
  }) async {
    try {
      final input = <String, dynamic>{
        'productId': productId.toString(),
        if (skillCategory != null) 'skillCategory': skillCategory,
        if (domain != null) 'domain': domain,
        if (kind != null) 'kind': kind.apiValue,
        if (isProductized != null) 'isProductized': isProductized,
        if (catalogSkuCode != null) 'catalogSkuCode': catalogSkuCode,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (basePriceTzs != null) 'basePriceTzs': basePriceTzs,
        if (leadTimeHours != null) 'leadTimeHours': leadTimeHours,
        if (minQuantity != null) 'minQuantity': minQuantity,
        if (mode != null) 'mode': mode,
        if (deliveryRadiusKm != null) 'deliveryRadiusKm': deliveryRadiusKm,
        if (deliveryFeePerKmTzs != null) 'deliveryFeePerKmTzs': deliveryFeePerKmTzs,
        if (pickupAddress != null) 'pickupAddress': pickupAddress,
        if (pickupLat != null) 'pickupLat': pickupLat,
        if (pickupLng != null) 'pickupLng': pickupLng,
        if (tags != null) 'tags': tags,
        if (dietaryTags != null) 'dietaryTags': dietaryTags,
        if (hairTypes != null) 'hairTypes': hairTypes,
        if (photos != null) 'photos': photos,
        if (isActive != null) 'isActive': isActive,
        if (amcVisitCount != null) 'amcVisitCount': amcVisitCount,
        if (amcValidityMonths != null) 'amcValidityMonths': amcValidityMonths,
        if (rebookCadenceDays != null) 'rebookCadenceDays': rebookCadenceDays,
        if (travelSurchargeTzs != null) 'travelSurchargeTzs': travelSurchargeTzs,
        if (afterHoursSurchargeTzs != null)
          'afterHoursSurchargeTzs': afterHoursSurchargeTzs,
        if (holidayPremiumTzs != null) 'holidayPremiumTzs': holidayPremiumTzs,
        if (parkingPassThroughTzs != null)
          'parkingPassThroughTzs': parkingPassThroughTzs,
        if (variants != null)
          'variants': variants.map((v) => v.toCreatePayload()).toList(),
      };
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateTajirikaPartnerProduct(\$input: UpdateTajirikaPartnerProductInput!) {
          updateTajirikaPartnerProduct(input: \$input) {
            $_productFields
          }
        }
        ''',
        variables: {'input': input},
        auth: true,
      );
      final row = data['updateTajirikaPartnerProduct'] as Map<String, dynamic>?;
      if (row == null) {
        return PartnerProductResult(success: false, message: 'Failed to update');
      }
      return PartnerProductResult(success: true, product: _parseProduct(row));
    } catch (e) {
      return PartnerProductResult(success: false, message: 'Kosa: $e');
    }
  }

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
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation PlaceTajirikaPartnerProductOrder(\$input: PlaceTajirikaPartnerProductOrderInput!) {
          placeTajirikaPartnerProductOrder(input: \$input) {
            id
            totalPriceTzs
            status
          }
        }
        ''',
        variables: {
          'input': {
            'productId': productId.toString(),
            'quantity': quantity,
            'deliveryMode': deliveryMode,
            if (deliveryAddress != null && deliveryAddress.isNotEmpty)
              'deliveryAddress': deliveryAddress,
            if (deliveryLat != null) 'deliveryLat': deliveryLat,
            if (deliveryLng != null) 'deliveryLng': deliveryLng,
            if (requestedFor != null)
              'requestedFor': requestedFor.toUtc().toIso8601String(),
            if (notes != null && notes.isNotEmpty) 'notes': notes,
            if (variantId != null) 'variantId': variantId.toString(),
          },
        },
        auth: true,
      );
      final row = data['placeTajirikaPartnerProductOrder'] as Map<String, dynamic>?;
      if (row == null) {
        return PartnerProductOrderResult(success: false, message: 'Failed');
      }
      return PartnerProductOrderResult(
        success: true,
        orderId: int.tryParse(row['id']?.toString() ?? ''),
        totalTzs: int.tryParse(row['totalPriceTzs']?.toString() ?? ''),
      );
    } catch (e) {
      return PartnerProductOrderResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerProductResult> deleteProduct({
    required int productId,
    required int userId,
  }) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteTajirikaPartnerProduct(\$productId: ID!) {
          deleteTajirikaPartnerProduct(productId: \$productId)
        }
        ''',
        variables: {'productId': productId.toString()},
        auth: true,
      );
      return PartnerProductResult(success: true);
    } catch (e) {
      return PartnerProductResult(success: false, message: 'Kosa: $e');
    }
  }
}
