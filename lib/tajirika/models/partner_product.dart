import 'dart:convert';

import '../../config/api_config.dart';
import 'product_variant.dart';
import 'tajirika_models.dart' show SkillCategory;

// Pages reference `photo.photoUrl` and `photo.resolvedPhotoUrl` as if photos
// were objects. The model stores them as plain `List<String>` URLs, so expose
// these as identity getters on String.
extension PhotoUrlString on String {
  String get photoUrl => this;
  String get resolvedPhotoUrl => this;
}

/// Server-side product kind. Matches backend `pp.kind` enum:
/// - [standard]   — one-off custom build (cake, custom door, etc.)
/// - [productized] — repeatable catalog SKU (a fixed wig style, branded skincare jar)
/// - [amc]        — annual maintenance contract / recurring service
enum PartnerProductKind { standard, productized, amc }

extension PartnerProductKindX on PartnerProductKind {
  String get apiValue {
    switch (this) {
      case PartnerProductKind.standard:
        return 'standard';
      case PartnerProductKind.productized:
        return 'productized';
      case PartnerProductKind.amc:
        return 'amc';
    }
  }

  String get labelSwahili {
    switch (this) {
      case PartnerProductKind.standard:
        return 'Kawaida';
      case PartnerProductKind.productized:
        return 'Bidhaa kamili';
      case PartnerProductKind.amc:
        return 'Mkataba wa matengenezo';
    }
  }

  static PartnerProductKind fromString(String? raw) {
    switch (raw) {
      case 'productized':
        return PartnerProductKind.productized;
      case 'amc':
        return PartnerProductKind.amc;
      case 'standard':
      default:
        return PartnerProductKind.standard;
    }
  }
}

/// Variant of a partner_product (e.g. small/medium/jumbo for box braids).
/// Backed by the existing [ProductVariant] model; this typedef + extension
/// is the create-payload contract used by [PartnerProductService].
typedef PartnerProductVariant = ProductVariant;

extension PartnerProductVariantPayloadX on ProductVariant {
  Map<String, dynamic> toCreatePayload() {
    return {
      if (id > 0) 'id': id,
      if (labelSwahili != null && labelSwahili!.isNotEmpty)
        'label_sw': labelSwahili,
      if (labelEnglish != null && labelEnglish!.isNotEmpty)
        'label_en': labelEnglish,
      'price_tzs': priceTzs,
      if (leadTimeHours != null) 'lead_time_hours': leadTimeHours,
      'duration_minutes': durationMinutes,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}

class PartnerProduct {
  final int id;
  final int partnerId;
  final int? partnerUserId;
  final String? partnerName;
  final String? partnerPhotoUrl;
  final String? partnerRegion;
  final String? partnerDistrict;

  /// Backend `partner_user_profiles.job_success_score` (0–100). Null when
  /// the partner hasn't completed enough jobs to compute one yet.
  final int? partnerJobSuccessScore;

  /// Raw `skill_category` string returned by the API (e.g. `baking`,
  /// `carpentry`). Kept verbatim so unrecognised future values still survive.
  final String skillCategoryRaw;

  /// Parsed enum view of [skillCategoryRaw]. Null when the API returns a
  /// skill the client doesn't know about yet.
  final SkillCategory? skillCategory;

  /// Cluster the product belongs to (`food`, `mafundi`, `events`, etc.).
  /// Denormalised on the server for cheap rail filtering.
  final String domain;

  final PartnerProductKind kind;
  final bool isProductized;
  final String? catalogSkuCode;

  final String title;
  final String description;
  final int basePriceTzs;
  final int leadTimeHours;
  final int minQuantity;

  /// Sale mode — kept as the raw API string (`pickup_only`, `delivery_only`,
  /// `both`, `digital_only`). The service signatures all take/return strings.
  final String mode;
  final int? deliveryRadiusKm;
  final int? deliveryFeePerKmTzs;

  /// Maximum travel radius (km) for events / travel partners. The partner
  /// posts a default on the product; per-booking overrides land on
  /// [event_bookings.travel_radius_km]. Spec line 768 (#84).
  final int? travelRadiusKm;

  /// Travel surcharge per km (TZS). Pairs with [travelRadiusKm].
  final int? travelPerKmTzs;

  final String? pickupAddress;
  final double? pickupLat;
  final double? pickupLng;

  final List<String> tags;
  final List<String> dietaryTags;
  final List<String> hairTypes;
  final List<String> photos;
  final String? coverPhotoUrl;

  // AMC / recurring fields
  final int? amcVisitCount;
  final int? amcValidityMonths;
  final int? rebookCadenceDays;

  // Surcharge fields
  final int? travelSurchargeTzs;
  final int? afterHoursSurchargeTzs;
  final int? holidayPremiumTzs;
  final int? parkingPassThroughTzs;

  final List<ProductVariant> variants;

  /// AI-suggested anchor price (TZS) for the cluster+skill+geo. When non-null,
  /// surfaces a "fair price" hint on the detail page if [basePriceTzs] is
  /// >15% off the anchor.
  final int? aiCostAnchorTzs;

  /// Optional last-minute discount percentage (0–100). When set, the detail
  /// page renders a strike-through original price.
  final int? lastMinuteDiscountPct;

  /// Partner's overall product rating (0.0–5.0). Distinct from
  /// [partnerJobSuccessScore]. Null until reviews accumulate.
  final double? partnerRating;

  /// Legal-cluster only — list of deliverables included in a fixed-fee legal
  /// pack (e.g. "Drafted contract", "30-min consult", "1 revision"). Empty
  /// for non-legal products.
  final List<String> legalPackDeliverables;

  final bool isActive;
  final bool isInStock;

  /// Spec §1 — photo consent toggle at posting time. Defaults ON for
  /// partner-uploaded photos (they own the copyright). Required OFF until
  /// customer consent for jobs that include identifiable customers.
  final bool photoConsentGiven;

  final DateTime createdAt;

  /// Spec F4 #25 — partner-set fee for an in-person inspection before quoting
  /// big jobs. When non-null and >0, customer sees the disclosure dialog.
  final int? siteSurveyFeeTzs;

  /// Spec F6 #38 — cancellation-policy tiers (free >24h / 50% 4–24h / full <4h).
  /// Each entry: {hours, refund_pct} or {label, refund_pct}.
  final List<dynamic> cancellationPolicyTiers;

  /// Spec F1 — service dependency. When true, customer must complete a
  /// dependent service (typically a patch test) ≥24h before booking the
  /// actual service. The book_appointment_page renders a gating banner.
  final bool requiresPatchTest;

  /// Spec F1 #2 — partner-defined add-ons each with delta_tzs / delta_minutes.
  /// Rendered live in BookingTotalCalculator on the customer booking sheet.
  final List<Map<String, dynamic>> addOns;

  PartnerProduct({
    required this.id,
    required this.partnerId,
    required this.partnerUserId,
    required this.partnerName,
    required this.partnerPhotoUrl,
    required this.partnerRegion,
    required this.partnerDistrict,
    required this.partnerJobSuccessScore,
    required this.skillCategoryRaw,
    required this.skillCategory,
    required this.domain,
    required this.kind,
    required this.isProductized,
    required this.catalogSkuCode,
    required this.title,
    required this.description,
    required this.basePriceTzs,
    required this.leadTimeHours,
    required this.minQuantity,
    required this.mode,
    required this.deliveryRadiusKm,
    required this.deliveryFeePerKmTzs,
    this.travelRadiusKm,
    this.travelPerKmTzs,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.tags,
    required this.dietaryTags,
    required this.hairTypes,
    required this.photos,
    required this.coverPhotoUrl,
    required this.amcVisitCount,
    required this.amcValidityMonths,
    required this.rebookCadenceDays,
    required this.travelSurchargeTzs,
    required this.afterHoursSurchargeTzs,
    required this.holidayPremiumTzs,
    required this.parkingPassThroughTzs,
    required this.variants,
    required this.aiCostAnchorTzs,
    required this.lastMinuteDiscountPct,
    required this.partnerRating,
    required this.legalPackDeliverables,
    required this.isActive,
    required this.isInStock,
    this.photoConsentGiven = true,
    required this.createdAt,
    this.siteSurveyFeeTzs,
    this.cancellationPolicyTiers = const [],
    this.requiresPatchTest = false,
    this.addOns = const [],
  });

  /// True for legal-cluster fixed-fee packs (e.g. "Drafted contract + 1 hr
  /// review for TZS X"). Drives the legal-pack deliverables block on detail
  /// pages.
  bool get isLegalPack =>
      domain == 'legal' || legalPackDeliverables.isNotEmpty;

  /// Modes the customer is allowed to pick on the booking sheet, derived from
  /// the partner-set [mode] string. `pickup_only` → `[pickup]`,
  /// `delivery_only` → `[delivery]`, `both` → `[pickup, delivery]`.
  /// Falls back to a single `pickup` entry on unrecognised values.
  List<String> get allowedModes {
    switch (mode) {
      case 'delivery_only':
        return const ['delivery'];
      case 'both':
        return const ['pickup', 'delivery'];
      case 'digital':
        return const ['digital'];
      default:
        return const ['pickup'];
    }
  }

  /// Resolved hero / cover URL for cards and detail pages. Falls back to the
  /// first photo when `cover_photo_url` is absent.
  String get heroPhotoUrl {
    final cover = _resolve(coverPhotoUrl);
    if (cover.isNotEmpty) return cover;
    final first = photos.isNotEmpty ? _resolve(photos.first) : '';
    return first;
  }

  String get resolvedPartnerPhoto => _resolve(partnerPhotoUrl);

  List<String> get resolvedPhotos =>
      photos.map(_resolve).where((p) => p.isNotEmpty).toList();

  static String _resolve(String? p) {
    if (p == null || p.isEmpty) return '';
    if (p.startsWith('http')) return ApiConfig.sanitizeUrl(p) ?? '';
    return ApiConfig.sanitizeUrl('${ApiConfig.storageUrl}/$p') ?? '';
  }

  factory PartnerProduct.fromJson(Map<String, dynamic> json) {
    final skillRaw = json['skill_category']?.toString() ?? '';
    return PartnerProduct(
      id: _parseInt(json['id']) ?? 0,
      partnerId: _parseInt(json['partner_id']) ?? 0,
      partnerUserId: _parseInt(json['partner_user_id']),
      partnerName: json['partner_name']?.toString(),
      partnerPhotoUrl: json['partner_photo_url']?.toString(),
      partnerRegion: json['partner_region']?.toString(),
      partnerDistrict: json['partner_district']?.toString(),
      partnerJobSuccessScore: _parseInt(json['partner_job_success_score']),
      skillCategoryRaw: skillRaw,
      skillCategory: SkillCategory.fromString(skillRaw),
      domain: json['domain']?.toString() ?? json['cluster']?.toString() ?? '',
      kind: PartnerProductKindX.fromString(json['kind']?.toString()),
      isProductized: _parseBool(json['is_productized']) ?? false,
      catalogSkuCode: json['catalog_sku_code']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      basePriceTzs: _parseInt(json['base_price_tzs']) ?? 0,
      leadTimeHours: _parseInt(json['lead_time_hours']) ?? 24,
      minQuantity: _parseInt(json['min_quantity']) ?? 1,
      mode: json['mode']?.toString() ?? 'pickup_only',
      deliveryRadiusKm: _parseInt(json['delivery_radius_km']),
      deliveryFeePerKmTzs: _parseInt(json['delivery_fee_per_km_tzs']),
      travelRadiusKm: _parseInt(json['travel_radius_km']),
      travelPerKmTzs: _parseInt(json['travel_per_km_tzs']),
      pickupAddress: json['pickup_address']?.toString(),
      pickupLat: _parseDouble(json['pickup_lat']),
      pickupLng: _parseDouble(json['pickup_lng']),
      tags: _parseStringList(json['tags']),
      dietaryTags: _parseStringList(json['dietary_tags']),
      hairTypes: _parseStringList(json['hair_types']),
      photos: _parseStringList(json['photos']),
      coverPhotoUrl: json['cover_photo_url']?.toString(),
      amcVisitCount: _parseInt(json['amc_visit_count']),
      amcValidityMonths: _parseInt(json['amc_validity_months']),
      rebookCadenceDays: _parseInt(json['rebook_cadence_days']),
      travelSurchargeTzs: _parseInt(json['travel_surcharge_tzs']),
      afterHoursSurchargeTzs: _parseInt(json['after_hours_surcharge_tzs']),
      holidayPremiumTzs: _parseInt(json['holiday_premium_tzs']),
      parkingPassThroughTzs: _parseInt(json['parking_pass_through_tzs']),
      variants: (json['variants'] as List?)
              ?.whereType<Map>()
              .map((m) => ProductVariant.fromJson(m.cast<String, dynamic>()))
              .toList() ??
          const [],
      aiCostAnchorTzs: _parseInt(json['ai_cost_anchor_tzs']),
      lastMinuteDiscountPct: _parseInt(json['last_minute_discount_pct']),
      partnerRating: _parseDouble(json['partner_rating']),
      legalPackDeliverables: _parseStringList(json['legal_pack_deliverables']),
      isActive: _parseBool(json['is_active']) ?? true,
      isInStock: _parseBool(json['is_in_stock']) ?? true,
      photoConsentGiven: _parseBool(json['photo_consent_given']) ?? true,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      siteSurveyFeeTzs: _parseInt(json['site_survey_fee_tzs']),
      requiresPatchTest: _parseBool(json['requires_patch_test']) ?? false,
      addOns: () {
        final raw = json['add_ons'];
        List<dynamic> list;
        if (raw is List) {
          list = raw;
        } else if (raw is String && raw.isNotEmpty) {
          try {
            final r = jsonDecode(raw);
            list = r is List ? r : <dynamic>[];
          } catch (_) {
            list = <dynamic>[];
          }
        } else {
          list = const <dynamic>[];
        }
        return list
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList();
      }(),
      cancellationPolicyTiers: (json['cancellation_policy_tiers'] is List)
          ? List<dynamic>.from(json['cancellation_policy_tiers'] as List)
          : (json['cancellation_policy_tiers'] is String)
              ? () {
                  try {
                    final r = jsonDecode(json['cancellation_policy_tiers'] as String);
                    return r is List ? List<dynamic>.from(r) : <dynamic>[];
                  } catch (_) {
                    return <dynamic>[];
                  }
                }()
              : const <dynamic>[],
    );
  }
}

class PartnerProductResult {
  final bool success;
  final PartnerProduct? product;
  final String? message;

  const PartnerProductResult({
    required this.success,
    this.product,
    this.message,
  });
}

class PartnerProductListResult {
  final bool success;
  final List<PartnerProduct> products;
  final String? message;

  const PartnerProductListResult({
    required this.success,
    this.products = const [],
    this.message,
  });
}

class PartnerProductOrderResult {
  final bool success;
  final int? orderId;
  final int? totalTzs;
  final String? message;

  const PartnerProductOrderResult({
    required this.success,
    this.orderId,
    this.totalTzs,
    this.message,
  });
}

class PartnerProductPhotoUploadResult {
  final bool success;
  final String? photoUrl;
  final String? message;

  const PartnerProductPhotoUploadResult({
    required this.success,
    this.photoUrl,
    this.message,
  });
}

/// Aggregated price-band hint for a (skill_category[, domain]) pair, surfaced
/// on the partner posting form so newcomers can sanity-check their price.
/// Backend returns null when sample_count < 3.
class PartnerProductPricingHint {
  /// 25th percentile (TZS) — lower edge of the typical band.
  final int minTzs;

  /// 75th percentile (TZS) — upper edge of the typical band.
  final int maxTzs;

  /// 50th percentile (TZS) — the headline number to show.
  final int medianTzs;

  /// Number of active partner_products contributing to the aggregate.
  final int sampleCount;

  const PartnerProductPricingHint({
    required this.minTzs,
    required this.maxTzs,
    required this.medianTzs,
    required this.sampleCount,
  });
}

/// Result of a Shangazi copy-polish call. Either field may be null when the
/// caller didn't pass that field, or when the AI editor declined to rewrite.
class PartnerProductPolishResult {
  final bool success;
  final String? title;
  final String? description;
  final String? message;

  const PartnerProductPolishResult({
    required this.success,
    this.title,
    this.description,
    this.message,
  });
}

// ── Parse helpers ─────────────────────────────────────────────────────────

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool? _parseBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    if (s == 'true' || s == '1' || s == 't') return true;
    if (s == 'false' || s == '0' || s == 'f') return false;
  }
  return null;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

List<String> _parseStringList(dynamic v) {
  if (v == null) return const [];
  if (v is List) return v.map((e) => e.toString()).toList();
  return const [];
}
