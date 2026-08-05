/// Trust profile model returned by GET /api/v1/shop/sellers/{id}/trust-profile
class SellerTrustProfile {
  final bool nidaVerified;
  final bool brelaRegistered;
  final int totalSales;

  /// e.g. '10+' | '50+' | '100+' | '500+' | '1000+' or null
  final String? salesBadge;

  /// 0–100 percentage
  final double responseRate;

  /// '< 1hr' | '< 3hrs' | '< 24hrs' | 'Slow'
  final String responseLabel;

  /// 'basic' | 'verified' | 'trusted'
  final String trustLevel;

  /// 'unverified' | 'pending' | 'verified' | 'rejected'
  final String verificationStatus;

  const SellerTrustProfile({
    required this.nidaVerified,
    required this.brelaRegistered,
    required this.totalSales,
    this.salesBadge,
    required this.responseRate,
    required this.responseLabel,
    required this.trustLevel,
    required this.verificationStatus,
  });

  factory SellerTrustProfile.fromJson(Map<String, dynamic> json) {
    return SellerTrustProfile(
      nidaVerified:       _parseBool(json['nida_verified']),
      brelaRegistered:    _parseBool(json['brela_registered']),
      totalSales:         _parseInt(json['total_sales']),
      salesBadge:         json['sales_badge'] as String?,
      responseRate:       _parseDouble(json['response_rate']),
      responseLabel:      (json['response_label'] as String?) ?? 'Slow',
      trustLevel:         (json['trust_level'] as String?) ?? 'basic',
      verificationStatus: (json['verification_status'] as String?) ?? 'unverified',
    );
  }

  bool get isVerified => trustLevel == 'verified' || trustLevel == 'trusted';
  bool get isTrusted  => trustLevel == 'trusted';

  static bool _parseBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v != 0;
    return false;
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

/// Verification status as seen by the authenticated seller.
class SellerVerificationStatus {
  final String verificationStatus;
  final bool nidaVerified;
  final bool brelaRegistered;
  final String? brelaNumber;
  final DateTime? verificationSubmittedAt;
  final String? verificationNotes;
  final String trustLevel;

  const SellerVerificationStatus({
    required this.verificationStatus,
    required this.nidaVerified,
    required this.brelaRegistered,
    this.brelaNumber,
    this.verificationSubmittedAt,
    this.verificationNotes,
    required this.trustLevel,
  });

  factory SellerVerificationStatus.fromJson(Map<String, dynamic> json) {
    return SellerVerificationStatus(
      verificationStatus:       (json['verification_status'] as String?) ?? 'unverified',
      nidaVerified:             _parseBool(json['nida_verified']),
      brelaRegistered:          _parseBool(json['brela_registered']),
      brelaNumber:              json['brela_number'] as String?,
      verificationSubmittedAt:  json['verification_submitted_at'] != null
          ? DateTime.tryParse(json['verification_submitted_at'] as String)
          : null,
      verificationNotes:        json['verification_notes'] as String?,
      trustLevel:               (json['trust_level'] as String?) ?? 'basic',
    );
  }

  static bool _parseBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v != 0;
    return false;
  }
}
