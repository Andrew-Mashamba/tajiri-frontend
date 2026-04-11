// lib/events/models/promo_code.dart
import 'event_enums.dart';

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _parseDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

class PromoCode {
  final int id;
  final int eventId;
  final String code;
  final PromoType type;
  final double value;
  final int? maxUses;
  final int usedCount;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final List<int>? applicableTierIds;
  final bool isActive;

  PromoCode({
    required this.id,
    required this.eventId,
    required this.code,
    this.type = PromoType.percentage,
    this.value = 0,
    this.maxUses,
    this.usedCount = 0,
    this.validFrom,
    this.validUntil,
    this.applicableTierIds,
    this.isActive = true,
  });

  bool get isValid {
    if (!isActive) return false;
    if (maxUses != null && usedCount >= maxUses!) return false;
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    return true;
  }

  double calculateDiscount(double originalPrice) {
    if (type == PromoType.percentage) {
      return originalPrice * (value / 100);
    }
    return value > originalPrice ? originalPrice : value;
  }

  factory PromoCode.fromJson(Map<String, dynamic> json) {
    return PromoCode(
      id: _parseInt(json['id']),
      eventId: _parseInt(json['event_id']),
      code: json['code']?.toString() ?? '',
      type: PromoType.fromApi(json['type']?.toString()),
      value: _parseDouble(json['value']),
      maxUses: json['max_uses'] != null ? _parseInt(json['max_uses']) : null,
      usedCount: _parseInt(json['used_count']),
      validFrom: json['valid_from'] != null ? DateTime.tryParse(json['valid_from'].toString()) : null,
      validUntil: json['valid_until'] != null ? DateTime.tryParse(json['valid_until'].toString()) : null,
      applicableTierIds: (json['applicable_tier_ids'] as List?)?.map((e) => _parseInt(e)).toList(),
      isActive: json['is_active'] != null ? _parseBool(json['is_active']) : true,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'type': type.apiValue,
    'value': value,
    if (maxUses != null) 'max_uses': maxUses,
    if (validFrom != null) 'valid_from': validFrom!.toIso8601String().split('T').first,
    if (validUntil != null) 'valid_until': validUntil!.toIso8601String().split('T').first,
    if (applicableTierIds != null) 'applicable_tier_ids': applicableTierIds,
    'is_active': isActive,
  };
}

class PromoValidation {
  final bool isValid;
  final double? discountAmount;
  final String? message;
  final PromoCode? promo;

  PromoValidation({required this.isValid, this.discountAmount, this.message, this.promo});

  factory PromoValidation.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return PromoValidation(
      isValid: json['success'] == true || _parseBool(data['is_valid']),
      discountAmount: data['discount_amount'] != null ? _parseDouble(data['discount_amount']) : null,
      message: json['message']?.toString(),
      promo: data['promo'] != null ? PromoCode.fromJson(data['promo']) : null,
    );
  }
}
