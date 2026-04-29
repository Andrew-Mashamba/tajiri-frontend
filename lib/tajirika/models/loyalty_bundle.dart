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

/// Spec line 1206 — partner-defined loyalty bundle (e.g. "5 haircuts for
/// TZS 50,000 valid 90 days"). Customer purchases once, redeems N times.
class LoyaltyBundle {
  final int id;
  final int partnerUserId;
  final String name;
  final String? description;
  final int servicesCount;
  final int validityDays;
  final int priceTzs;
  final int? originalPriceTzs;
  final bool isActive;
  final DateTime? createdAt;

  LoyaltyBundle({
    required this.id,
    required this.partnerUserId,
    required this.name,
    required this.description,
    required this.servicesCount,
    required this.validityDays,
    required this.priceTzs,
    required this.originalPriceTzs,
    required this.isActive,
    required this.createdAt,
  });

  factory LoyaltyBundle.fromJson(Map<String, dynamic> json) {
    return LoyaltyBundle(
      id: _parseIntN(json['id']) ?? 0,
      partnerUserId: _parseIntN(json['partner_user_id']) ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      servicesCount: _parseIntN(json['services_count']) ?? 1,
      validityDays: _parseIntN(json['validity_days']) ?? 30,
      priceTzs: _parseIntN(json['price_tzs']) ?? 0,
      originalPriceTzs: _parseIntN(json['original_price_tzs']),
      isActive: _parseBool(json['is_active']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  int get savingsTzs {
    if (originalPriceTzs == null) return 0;
    final diff = originalPriceTzs! - priceTzs;
    return diff > 0 ? diff : 0;
  }

  int get savingsPct {
    if (originalPriceTzs == null || originalPriceTzs == 0) return 0;
    return savingsTzs * 100 ~/ originalPriceTzs!;
  }
}

class LoyaltyBundleListResult {
  final bool success;
  final List<LoyaltyBundle> items;
  final String? message;
  final int? statusCode;
  LoyaltyBundleListResult({
    required this.success,
    this.items = const [],
    this.message,
    this.statusCode,
  });
}
