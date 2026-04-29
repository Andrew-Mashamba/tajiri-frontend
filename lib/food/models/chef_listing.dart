import '../../config/api_config.dart';

enum ChefListingMode { scheduled, todayExtra, giveaway }

extension ChefListingModeX on ChefListingMode {
  String get apiValue {
    switch (this) {
      case ChefListingMode.scheduled: return 'scheduled';
      case ChefListingMode.todayExtra: return 'today_extra';
      case ChefListingMode.giveaway: return 'giveaway';
    }
  }

  String get labelSwahili {
    switch (this) {
      case ChefListingMode.scheduled: return 'Imepangwa';
      case ChefListingMode.todayExtra: return 'Chakula Zaidi Leo';
      case ChefListingMode.giveaway: return 'Mgao wa Bure';
    }
  }

  static ChefListingMode fromString(String? s) {
    switch (s) {
      case 'scheduled': return ChefListingMode.scheduled;
      case 'giveaway': return ChefListingMode.giveaway;
      default: return ChefListingMode.todayExtra;
    }
  }
}

enum ChefListingSelectionMode { open, curated }

extension ChefListingSelectionModeX on ChefListingSelectionMode {
  String get apiValue {
    switch (this) {
      case ChefListingSelectionMode.open: return 'open';
      case ChefListingSelectionMode.curated: return 'curated';
    }
  }

  String get labelSwahili {
    switch (this) {
      case ChefListingSelectionMode.open: return 'Jirani yeyote';
      case ChefListingSelectionMode.curated: return 'Nichague mwenyewe';
    }
  }

  static ChefListingSelectionMode fromString(String? s) {
    switch (s) {
      case 'curated': return ChefListingSelectionMode.curated;
      default: return ChefListingSelectionMode.open;
    }
  }
}

enum ChefListingRecipientType { public, community, organisation }

extension ChefListingRecipientTypeX on ChefListingRecipientType {
  String get apiValue {
    switch (this) {
      case ChefListingRecipientType.public: return 'public';
      case ChefListingRecipientType.community: return 'community';
      case ChefListingRecipientType.organisation: return 'organisation';
    }
  }

  static ChefListingRecipientType fromString(String? s) {
    switch (s) {
      case 'community': return ChefListingRecipientType.community;
      case 'organisation': return ChefListingRecipientType.organisation;
      default: return ChefListingRecipientType.public;
    }
  }
}

class ChefListing {
  final int id;
  final int partnerId;
  final int? partnerUserId;
  final String title;
  final String? description;
  final String? photoUrl;
  final ChefListingMode mode;
  final ChefListingRecipientType recipientType;
  final ChefListingSelectionMode selectionMode;
  final int? beneficiaryOrgId;
  final int portionsTotal;
  final int portionsRemaining;
  final int? priceTzs;
  final int? originalPriceTzs;
  final DateTime pickupWindowStart;
  final DateTime pickupWindowEnd;
  final String? pickupAddress;
  final double? pickupLat;
  final double? pickupLng;
  final List<String> dietaryTags;
  final bool deliveryEnabled;
  final int? deliveryFeeTzs;
  final double? deliveryRadiusKm;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime? cookedAt;
  final int? cascadeOrgId;
  final DateTime? cascadedAt;
  final int? cascadeListingId;

  final String? partnerName;
  final String? partnerPhotoUrl;
  final String? partnerBio;
  final String? partnerPhone;
  final String? partnerPhoneMasked;
  final String? partnerRegion;
  final String? partnerDistrict;
  final String? partnerWard;
  final double partnerRating;
  final int partnerJobsCompleted;

  final ChefListingReservation? myReservation;

  ChefListing({
    required this.id,
    required this.partnerId,
    required this.partnerUserId,
    required this.title,
    required this.description,
    required this.photoUrl,
    required this.mode,
    required this.recipientType,
    required this.selectionMode,
    required this.beneficiaryOrgId,
    required this.portionsTotal,
    required this.portionsRemaining,
    required this.priceTzs,
    required this.originalPriceTzs,
    required this.pickupWindowStart,
    required this.pickupWindowEnd,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dietaryTags,
    required this.deliveryEnabled,
    required this.deliveryFeeTzs,
    required this.deliveryRadiusKm,
    required this.isActive,
    required this.expiresAt,
    required this.cookedAt,
    required this.cascadeOrgId,
    required this.cascadedAt,
    required this.cascadeListingId,
    required this.partnerName,
    required this.partnerPhotoUrl,
    required this.partnerBio,
    required this.partnerPhone,
    required this.partnerPhoneMasked,
    required this.partnerRegion,
    required this.partnerDistrict,
    required this.partnerWard,
    required this.partnerRating,
    required this.partnerJobsCompleted,
    required this.myReservation,
  });

  bool get isGiveaway => mode == ChefListingMode.giveaway || priceTzs == null;
  bool get isPaid => !isGiveaway;
  bool get hasPortionsLeft => portionsRemaining > 0;
  Duration get timeUntilClose => pickupWindowEnd.difference(DateTime.now());
  bool get pickupWindowClosed => DateTime.now().isAfter(pickupWindowEnd);
  bool get hasCascadeOrg => cascadeOrgId != null;
  bool get hasCascaded => cascadedAt != null || cascadeListingId != null;
  bool get cascadeReady =>
      pickupWindowClosed && hasPortionsLeft && hasCascadeOrg && !hasCascaded && !isGiveaway;

  String get partnerLocationText {
    final parts = [partnerWard, partnerDistrict, partnerRegion]
        .where((p) => p != null && p.trim().isNotEmpty)
        .cast<String>()
        .toList();
    return parts.isEmpty ? '' : parts.join(', ');
  }

  String get resolvedPhotoUrl => ApiConfig.sanitizeUrl(photoUrl ?? '') ?? '';
  String get resolvedPartnerPhotoUrl {
    final p = partnerPhotoUrl ?? '';
    if (p.isEmpty) return '';
    if (p.startsWith('http')) return ApiConfig.sanitizeUrl(p) ?? '';
    return ApiConfig.sanitizeUrl('${ApiConfig.storageUrl}/$p') ?? '';
  }

  factory ChefListing.fromJson(Map<String, dynamic> json) {
    final tags = <String>[];
    final raw = json['dietary_tags'];
    if (raw is List) {
      for (final t in raw) {
        if (t is String && t.isNotEmpty) tags.add(t);
      }
    }
    return ChefListing(
      id: _parseInt(json['id']) ?? 0,
      partnerId: _parseInt(json['partner_id']) ?? 0,
      partnerUserId: _parseInt(json['partner_user_id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      mode: ChefListingModeX.fromString(json['mode']?.toString()),
      recipientType: ChefListingRecipientTypeX.fromString(json['recipient_type']?.toString()),
      selectionMode: ChefListingSelectionModeX.fromString(json['selection_mode']?.toString()),
      beneficiaryOrgId: _parseInt(json['beneficiary_org_id']),
      portionsTotal: _parseInt(json['portions_total']) ?? 0,
      portionsRemaining: _parseInt(json['portions_remaining']) ?? 0,
      priceTzs: _parseInt(json['price_tzs']),
      originalPriceTzs: _parseInt(json['original_price_tzs']),
      pickupWindowStart: _parseDate(json['pickup_window_start']) ?? DateTime.now(),
      pickupWindowEnd: _parseDate(json['pickup_window_end']) ?? DateTime.now(),
      pickupAddress: json['pickup_address']?.toString(),
      pickupLat: _parseDouble(json['pickup_lat']),
      pickupLng: _parseDouble(json['pickup_lng']),
      dietaryTags: tags,
      deliveryEnabled: json['delivery_enabled'] == true || json['delivery_enabled'] == 1,
      deliveryFeeTzs: _parseInt(json['delivery_fee_tzs']),
      deliveryRadiusKm: _parseDouble(json['delivery_radius_km']),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      expiresAt: _parseDate(json['expires_at']),
      cookedAt: _parseDate(json['cooked_at']),
      cascadeOrgId: _parseInt(json['cascade_org_id']),
      cascadedAt: _parseDate(json['cascaded_at']),
      cascadeListingId: _parseInt(json['cascade_listing_id']),
      partnerName: json['partner_name']?.toString(),
      partnerPhotoUrl: json['partner_photo_url']?.toString(),
      partnerBio: json['partner_bio']?.toString(),
      partnerPhone: json['partner_phone']?.toString(),
      partnerPhoneMasked: json['partner_phone_masked']?.toString(),
      partnerRegion: json['partner_region']?.toString(),
      partnerDistrict: json['partner_district']?.toString(),
      partnerWard: json['partner_ward']?.toString(),
      partnerRating: _parseDouble(json['partner_rating']) ?? 0.0,
      partnerJobsCompleted: _parseInt(json['partner_jobs_completed']) ?? 0,
      myReservation: json['my_reservation'] is Map<String, dynamic>
          ? ChefListingReservation.fromJson(json['my_reservation'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ChefListingReservation {
  final int id;
  final int listingId;
  final int userId;
  final int portions;
  final int totalPriceTzs;
  final String status;
  final String paymentMethod;
  final String deliveryMode;
  final int deliveryFeeTzs;
  final DateTime? reservedAt;
  final DateTime? pickedUpAt;
  final DateTime? outForDeliveryAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;

  ChefListingReservation({
    required this.id,
    required this.listingId,
    required this.userId,
    required this.portions,
    required this.totalPriceTzs,
    required this.status,
    required this.paymentMethod,
    required this.deliveryMode,
    required this.deliveryFeeTzs,
    required this.reservedAt,
    required this.pickedUpAt,
    required this.outForDeliveryAt,
    required this.deliveredAt,
    required this.cancelledAt,
  });

  bool get isReserved => status == 'reserved';
  bool get isPickedUp => status == 'picked_up';
  bool get isCancelled => status == 'cancelled';
  bool get isDelivery => deliveryMode == 'delivery';
  bool get isOutForDelivery => status == 'out_for_delivery';
  bool get isDelivered => status == 'delivered';

  /// 0 = preparing, 1 = out for delivery, 2 = delivered
  int get deliveryStepIndex {
    if (isDelivered) return 2;
    if (isOutForDelivery) return 1;
    return 0;
  }

  factory ChefListingReservation.fromJson(Map<String, dynamic> json) {
    return ChefListingReservation(
      id: _parseInt(json['id']) ?? 0,
      listingId: _parseInt(json['listing_id']) ?? 0,
      userId: _parseInt(json['user_id']) ?? 0,
      portions: _parseInt(json['portions']) ?? 0,
      totalPriceTzs: _parseInt(json['total_price_tzs']) ?? 0,
      status: json['status']?.toString() ?? 'reserved',
      paymentMethod: json['payment_method']?.toString() ?? 'wallet',
      deliveryMode: json['delivery_mode']?.toString() ?? 'pickup',
      deliveryFeeTzs: _parseInt(json['delivery_fee_tzs']) ?? 0,
      reservedAt: _parseDate(json['reserved_at']),
      pickedUpAt: _parseDate(json['picked_up_at']),
      outForDeliveryAt: _parseDate(json['out_for_delivery_at']),
      deliveredAt: _parseDate(json['delivered_at']),
      cancelledAt: _parseDate(json['cancelled_at']),
    );
  }
}

class ChefListingContact {
  final String? phoneMasked;
  final String? phoneFull;
  final bool canReveal;
  final int partnerUserId;

  ChefListingContact({
    required this.phoneMasked,
    required this.phoneFull,
    required this.canReveal,
    required this.partnerUserId,
  });

  factory ChefListingContact.fromJson(Map<String, dynamic> json) {
    return ChefListingContact(
      phoneMasked: json['phone_masked']?.toString(),
      phoneFull: json['phone_full']?.toString(),
      canReveal: json['can_reveal'] == true,
      partnerUserId: _parseInt(json['partner_user_id']) ?? 0,
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
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
