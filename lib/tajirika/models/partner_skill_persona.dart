import '../../config/api_config.dart';

enum SkillPersonaStatus {
  active,
  paused,
  pendingVerification,
  rejected;

  String get apiValue {
    switch (this) {
      case SkillPersonaStatus.active: return 'active';
      case SkillPersonaStatus.paused: return 'paused';
      case SkillPersonaStatus.pendingVerification: return 'pending_verification';
      case SkillPersonaStatus.rejected: return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case SkillPersonaStatus.active: return 'Active';
      case SkillPersonaStatus.paused: return 'Paused';
      case SkillPersonaStatus.pendingVerification: return 'Pending verification';
      case SkillPersonaStatus.rejected: return 'Rejected';
    }
  }

  String get labelSwahili {
    switch (this) {
      case SkillPersonaStatus.active: return 'Hai';
      case SkillPersonaStatus.paused: return 'Imesimamishwa';
      case SkillPersonaStatus.pendingVerification: return 'Inahakikiwa';
      case SkillPersonaStatus.rejected: return 'Imekataliwa';
    }
  }

  static SkillPersonaStatus fromString(String? raw) {
    switch (raw) {
      case 'active': return SkillPersonaStatus.active;
      case 'paused': return SkillPersonaStatus.paused;
      case 'pending_verification': return SkillPersonaStatus.pendingVerification;
      case 'rejected': return SkillPersonaStatus.rejected;
      default: return SkillPersonaStatus.active;
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

class PartnerSkillPersona {
  final int partnerUserId;
  final String skillCategory;
  final SkillPersonaStatus status;
  final String? displayName;
  final String? profilePhotoUrl;
  final String? bio;
  final int? pricingBandLowTzs;
  final int? pricingBandHighTzs;
  final List<String>? tagPreset;
  final String? autoReplyText;
  final String? credentialsUrl;
  final DateTime? verifiedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime? pausedAt;
  /// True when no persona row exists yet (server returns defaults derived
  /// from the partner's user.name + skill icon).
  final bool isDefault;
  /// Spec line 1278 — auto-assigned tier from cluster median: budget|standard|premium.
  final String? pricingTier;
  /// Spec line 1283 — partner has paused this skill alone.
  final bool isPaused;
  /// Spec line 1281 — shareable persona URL slug (tajiri.com/p/{slug}).
  final String? publicSlug;
  /// Spec line 1208 — TALA license number for tour-operator personas.
  final String? talaLicenseNumber;
  final bool talaVerified;

  PartnerSkillPersona({
    required this.partnerUserId,
    required this.skillCategory,
    required this.status,
    required this.displayName,
    required this.profilePhotoUrl,
    required this.bio,
    required this.pricingBandLowTzs,
    required this.pricingBandHighTzs,
    required this.tagPreset,
    required this.autoReplyText,
    required this.credentialsUrl,
    required this.verifiedAt,
    required this.rejectedAt,
    required this.rejectionReason,
    required this.pausedAt,
    required this.isDefault,
    this.pricingTier,
    this.isPaused = false,
    this.publicSlug,
    this.talaLicenseNumber,
    this.talaVerified = false,
  });

  factory PartnerSkillPersona.fromJson(Map<String, dynamic> json) {
    final tags = json['tag_preset'];
    return PartnerSkillPersona(
      partnerUserId: _parseIntN(json['partner_user_id']) ?? 0,
      skillCategory: json['skill_category']?.toString() ?? '',
      status: SkillPersonaStatus.fromString(json['status']?.toString()),
      displayName: json['display_name']?.toString(),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      bio: json['bio']?.toString(),
      pricingBandLowTzs: _parseIntN(json['pricing_band_low_tzs']),
      pricingBandHighTzs: _parseIntN(json['pricing_band_high_tzs']),
      tagPreset: tags is List ? tags.map((e) => e.toString()).toList() : null,
      autoReplyText: json['auto_reply_text']?.toString(),
      credentialsUrl: json['credentials_url']?.toString(),
      verifiedAt: _parseDate(json['verified_at']),
      rejectedAt: _parseDate(json['rejected_at']),
      rejectionReason: json['rejection_reason']?.toString(),
      pausedAt: _parseDate(json['paused_at']),
      isDefault: _parseBool(json['is_default']),
      pricingTier: json['pricing_tier']?.toString(),
      isPaused: _parseBool(json['is_paused']),
      publicSlug: json['public_slug']?.toString(),
      talaLicenseNumber: json['tala_license_number']?.toString(),
      talaVerified: _parseBool(json['tala_verified']),
    );
  }

  String get resolvedPhotoUrl {
    final raw = profilePhotoUrl ?? '';
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return ApiConfig.sanitizeUrl(raw) ?? '';
    return ApiConfig.sanitizeUrl('${ApiConfig.storageUrl}/$raw') ?? '';
  }

  bool get hasPricingBand =>
      pricingBandLowTzs != null && pricingBandHighTzs != null;
}

class PartnerSkillPersonaResult {
  final bool success;
  final PartnerSkillPersona? persona;
  final String? message;
  final int? statusCode;
  PartnerSkillPersonaResult({required this.success, this.persona, this.message, this.statusCode});
}

class PartnerSkillPersonaListResult {
  final bool success;
  final List<PartnerSkillPersona> items;
  final String? message;
  final int? statusCode;
  PartnerSkillPersonaListResult({
    required this.success,
    this.items = const [],
    this.message,
    this.statusCode,
  });
}
