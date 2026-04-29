import '../../config/api_config.dart';

/// Sale mode for a chef product.
enum ChefProductMode { pickupOnly, deliveryOnly, both }

extension ChefProductModeX on ChefProductMode {
  String get apiValue {
    switch (this) {
      case ChefProductMode.pickupOnly: return 'pickup_only';
      case ChefProductMode.deliveryOnly: return 'delivery_only';
      case ChefProductMode.both: return 'both';
    }
  }

  String get labelSwahili {
    switch (this) {
      case ChefProductMode.pickupOnly: return 'Kuchukuliwa pekee';
      case ChefProductMode.deliveryOnly: return 'Kuletewa pekee';
      case ChefProductMode.both: return 'Kuchukua au kuletewa';
    }
  }

  static ChefProductMode fromString(String? s) {
    switch (s) {
      case 'pickup_only': return ChefProductMode.pickupOnly;
      case 'delivery_only': return ChefProductMode.deliveryOnly;
      default: return ChefProductMode.both;
    }
  }
}

class ChefProduct {
  final int id;
  final int partnerId;
  final int? partnerUserId;
  final String? partnerName;
  final String? partnerPhotoUrl;
  final String? partnerRegion;
  final String? partnerDistrict;

  final String title;
  final String? description;
  final int basePriceTzs;
  final int leadTimeHours;
  final int minQuantity;

  final ChefProductMode mode;
  final int? deliveryRadiusKm;
  final int? deliveryFeePerKmTzs;

  final String? pickupAddress;
  final double? pickupLat;
  final double? pickupLng;

  final List<String> tags;
  final List<String> photos;
  final String? coverPhotoUrl;

  final bool isActive;
  final DateTime createdAt;

  ChefProduct({
    required this.id,
    required this.partnerId,
    required this.partnerUserId,
    required this.partnerName,
    required this.partnerPhotoUrl,
    required this.partnerRegion,
    required this.partnerDistrict,
    required this.title,
    required this.description,
    required this.basePriceTzs,
    required this.leadTimeHours,
    required this.minQuantity,
    required this.mode,
    required this.deliveryRadiusKm,
    required this.deliveryFeePerKmTzs,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.tags,
    required this.photos,
    required this.coverPhotoUrl,
    required this.isActive,
    required this.createdAt,
  });

  String get resolvedCover => _resolve(coverPhotoUrl);

  List<String> get resolvedPhotos =>
      photos.map(_resolve).where((p) => p.isNotEmpty).toList();

  String get resolvedPartnerPhoto => _resolve(partnerPhotoUrl);

  static String _resolve(String? p) {
    if (p == null || p.isEmpty) return '';
    if (p.startsWith('http')) return ApiConfig.sanitizeUrl(p) ?? '';
    return ApiConfig.sanitizeUrl('${ApiConfig.storageUrl}/$p') ?? '';
  }

  factory ChefProduct.fromJson(Map<String, dynamic> json) {
    return ChefProduct(
      id: _parseInt(json['id']) ?? 0,
      partnerId: _parseInt(json['partner_id']) ?? 0,
      partnerUserId: _parseInt(json['partner_user_id']),
      partnerName: json['partner_name']?.toString(),
      partnerPhotoUrl: json['partner_photo_url']?.toString(),
      partnerRegion: json['partner_region']?.toString(),
      partnerDistrict: json['partner_district']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      basePriceTzs: _parseInt(json['base_price_tzs']) ?? 0,
      leadTimeHours: _parseInt(json['lead_time_hours']) ?? 24,
      minQuantity: _parseInt(json['min_quantity']) ?? 1,
      mode: ChefProductModeX.fromString(json['mode']?.toString()),
      deliveryRadiusKm: _parseInt(json['delivery_radius_km']),
      deliveryFeePerKmTzs: _parseInt(json['delivery_fee_per_km_tzs']),
      pickupAddress: json['pickup_address']?.toString(),
      pickupLat: _parseDouble(json['pickup_lat']),
      pickupLng: _parseDouble(json['pickup_lng']),
      tags: (json['tags'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      photos: (json['photos'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      coverPhotoUrl: json['cover_photo_url']?.toString(),
      isActive: _parseBool(json['is_active']) ?? true,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }
}

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
