import 'package:flutter/material.dart';

import '../../config/api_config.dart';

enum ListingKind {
  sale,
  rent;

  String get apiValue {
    switch (this) {
      case ListingKind.sale: return 'sale';
      case ListingKind.rent: return 'rent';
    }
  }

  String get label {
    switch (this) {
      case ListingKind.sale: return 'For sale';
      case ListingKind.rent: return 'For rent';
    }
  }

  String get labelSwahili {
    switch (this) {
      case ListingKind.sale: return 'Inauzwa';
      case ListingKind.rent: return 'Inakodishwa';
    }
  }

  static ListingKind fromString(String? raw) {
    switch (raw) {
      case 'sale': return ListingKind.sale;
      case 'rent': return ListingKind.rent;
      default: return ListingKind.sale;
    }
  }
}

enum PropertyType {
  apartment,
  house,
  land,
  office,
  shop;

  String get apiValue {
    switch (this) {
      case PropertyType.apartment: return 'apartment';
      case PropertyType.house: return 'house';
      case PropertyType.land: return 'land';
      case PropertyType.office: return 'office';
      case PropertyType.shop: return 'shop';
    }
  }

  String get label {
    switch (this) {
      case PropertyType.apartment: return 'Apartment';
      case PropertyType.house: return 'House';
      case PropertyType.land: return 'Land';
      case PropertyType.office: return 'Office';
      case PropertyType.shop: return 'Shop';
    }
  }

  String get labelSwahili {
    switch (this) {
      case PropertyType.apartment: return 'Apartment';
      case PropertyType.house: return 'Nyumba';
      case PropertyType.land: return 'Kiwanja';
      case PropertyType.office: return 'Ofisi';
      case PropertyType.shop: return 'Duka';
    }
  }

  IconData get icon {
    switch (this) {
      case PropertyType.apartment: return Icons.apartment_rounded;
      case PropertyType.house: return Icons.home_rounded;
      case PropertyType.land: return Icons.landscape_rounded;
      case PropertyType.office: return Icons.business_rounded;
      case PropertyType.shop: return Icons.storefront_rounded;
    }
  }

  static PropertyType fromString(String? raw) {
    switch (raw) {
      case 'apartment': return PropertyType.apartment;
      case 'house': return PropertyType.house;
      case 'land': return PropertyType.land;
      case 'office': return PropertyType.office;
      case 'shop': return PropertyType.shop;
      default: return PropertyType.house;
    }
  }
}

enum PriceFrequency {
  monthly,
  weekly,
  daily;

  String get apiValue {
    switch (this) {
      case PriceFrequency.monthly: return 'monthly';
      case PriceFrequency.weekly: return 'weekly';
      case PriceFrequency.daily: return 'daily';
    }
  }

  String get label {
    switch (this) {
      case PriceFrequency.monthly: return '/mo';
      case PriceFrequency.weekly: return '/wk';
      case PriceFrequency.daily: return '/day';
    }
  }

  String get labelSwahili {
    switch (this) {
      case PriceFrequency.monthly: return '/mwezi';
      case PriceFrequency.weekly: return '/wiki';
      case PriceFrequency.daily: return '/siku';
    }
  }

  static PriceFrequency? fromString(String? raw) {
    switch (raw) {
      case 'monthly': return PriceFrequency.monthly;
      case 'weekly': return PriceFrequency.weekly;
      case 'daily': return PriceFrequency.daily;
      default: return null;
    }
  }
}

int? _parseIntN(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _parseDoubleN(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool _parseBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    return s == 'true' || s == '1';
  }
  return false;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

class PropertyListing {
  final int id;
  final int partnerUserId;
  final int? partnerId;
  final String? partnerName;
  final String? partnerPhotoUrl;

  final String title;
  final String description;
  final ListingKind listingKind;
  final PropertyType propertyType;

  final String? region;
  final String? district;
  final String? ward;
  final String? street;
  final double? lat;
  final double? lng;

  final int priceTzs;
  final PriceFrequency? priceFrequency; // null for sale

  final int? bedrooms;
  final int? bathrooms;
  final int? areaSqm;
  final int? plotSizeSqm;

  final List<String> amenities;
  final List<String> photos;

  final bool isActive;
  final int viewsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Spec line 861 — neighborhood blurb shown on detail page.
  final String? neighborhoodDescription;
  /// Spec line 932 — Walk/Bike/Transit score (0–100). Null when not computed.
  final int? walkScore;
  final int? bikeScore;
  final int? transitScore;
  /// Spec line 925 — photo verification status: none|pending|verified|rejected.
  final String photoVerificationStatus;
  /// Spec line 931 — floor plan image URLs (separate carousel tab).
  final List<String> floorPlanUrls;
  /// Spec line 933 — energy/utilities band: A|B|C|D|E.
  final String? epcBand;
  /// Spec line 934 — true while inquiry not yet confirmed (location obfuscated).
  final bool obfuscateLocationUntilInquiry;
  /// Spec line 936 — Matterport 3D tour available + URL.
  final bool matterportEnabled;
  final String? matterportUrl;
  /// Spec line 938 — fired when listing reverts pending → active.
  final DateTime? backOnMarketAt;

  PropertyListing({
    required this.id,
    required this.partnerUserId,
    required this.partnerId,
    required this.partnerName,
    required this.partnerPhotoUrl,
    required this.title,
    required this.description,
    required this.listingKind,
    required this.propertyType,
    required this.region,
    required this.district,
    required this.ward,
    required this.street,
    required this.lat,
    required this.lng,
    required this.priceTzs,
    required this.priceFrequency,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqm,
    required this.plotSizeSqm,
    required this.amenities,
    required this.photos,
    required this.isActive,
    required this.viewsCount,
    required this.createdAt,
    required this.updatedAt,
    this.neighborhoodDescription,
    this.walkScore,
    this.bikeScore,
    this.transitScore,
    this.photoVerificationStatus = 'none',
    this.floorPlanUrls = const [],
    this.epcBand,
    this.obfuscateLocationUntilInquiry = false,
    this.matterportEnabled = false,
    this.matterportUrl,
    this.backOnMarketAt,
  });

  factory PropertyListing.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return const <String>[];
    }
    return PropertyListing(
      id: _parseIntN(json['id']) ?? 0,
      partnerUserId: _parseIntN(json['partner_user_id']) ?? 0,
      partnerId: _parseIntN(json['partner_id']),
      partnerName: json['partner_name']?.toString(),
      partnerPhotoUrl: json['partner_photo_url']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      listingKind: ListingKind.fromString(json['listing_kind']?.toString()),
      propertyType: PropertyType.fromString(json['property_type']?.toString()),
      region: json['region']?.toString(),
      district: json['district']?.toString(),
      ward: json['ward']?.toString(),
      street: json['street']?.toString(),
      lat: _parseDoubleN(json['lat']),
      lng: _parseDoubleN(json['lng']),
      priceTzs: _parseIntN(json['price_tzs']) ?? 0,
      priceFrequency: PriceFrequency.fromString(json['price_frequency']?.toString()),
      bedrooms: _parseIntN(json['bedrooms']),
      bathrooms: _parseIntN(json['bathrooms']),
      areaSqm: _parseIntN(json['area_sqm']),
      plotSizeSqm: _parseIntN(json['plot_size_sqm']),
      amenities: strList(json['amenities']),
      photos: strList(json['photos']),
      isActive: _parseBool(json['is_active']),
      viewsCount: _parseIntN(json['views_count']) ?? 0,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      neighborhoodDescription: json['neighborhood_description']?.toString(),
      walkScore: _parseIntN(json['walk_score']),
      bikeScore: _parseIntN(json['bike_score']),
      transitScore: _parseIntN(json['transit_score']),
      photoVerificationStatus: json['photo_verification_status']?.toString() ?? 'none',
      floorPlanUrls: strList(json['floor_plan_urls']),
      epcBand: json['epc_band']?.toString(),
      obfuscateLocationUntilInquiry:
          _parseBool(json['obfuscate_location_until_inquiry']),
      matterportEnabled: _parseBool(json['matterport_enabled']),
      matterportUrl: json['matterport_url']?.toString(),
      backOnMarketAt: _parseDate(json['back_on_market_at']),
    );
  }

  String get coverPhoto {
    if (photos.isEmpty) return '';
    return resolvePhoto(photos.first);
  }

  static String resolvePhoto(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return ApiConfig.sanitizeUrl(raw) ?? '';
    return ApiConfig.sanitizeUrl('${ApiConfig.storageUrl}/$raw') ?? '';
  }

  String get locationDisplay {
    final parts = <String>[
      if (street != null && street!.isNotEmpty) street!,
      if (ward != null && ward!.isNotEmpty) ward!,
      if (district != null && district!.isNotEmpty) district!,
      if (region != null && region!.isNotEmpty) region!,
    ];
    return parts.join(', ');
  }
}

class PropertyListingResult {
  final bool success;
  final PropertyListing? listing;
  final String? message;
  final int? statusCode;
  PropertyListingResult({required this.success, this.listing, this.message, this.statusCode});
}

class PropertyListingListResult {
  final bool success;
  final List<PropertyListing> items;
  final String? message;
  final int? statusCode;
  PropertyListingListResult({required this.success, this.items = const [], this.message, this.statusCode});
}

class PropertyListingPhotoUploadResult {
  final bool success;
  final String? url;
  final String? message;
  final int? statusCode;
  PropertyListingPhotoUploadResult({required this.success, this.url, this.message, this.statusCode});
}
