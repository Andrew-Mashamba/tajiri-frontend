class TajiriPayQrCode {
  final String id;
  final int walletUserId;
  final int? businessId;
  final String sourceType; // shop | business
  final String displayName;
  final String tanqrPayload;
  final String aliasMerchantId;
  final DateTime generatedAt;

  const TajiriPayQrCode({
    required this.id,
    required this.walletUserId,
    required this.businessId,
    required this.sourceType,
    required this.displayName,
    required this.tanqrPayload,
    required this.aliasMerchantId,
    required this.generatedAt,
  });

  factory TajiriPayQrCode.fromJson(Map<String, dynamic> json) {
    return TajiriPayQrCode(
      id: json['id']?.toString() ?? '',
      walletUserId: _parseInt(json['wallet_user_id']),
      businessId: json['business_id'] == null ? null : _parseInt(json['business_id']),
      sourceType: json['source_type']?.toString() ?? 'business',
      displayName: json['display_name']?.toString() ?? '',
      tanqrPayload: json['tanqr_payload']?.toString() ?? '',
      aliasMerchantId: json['alias_merchant_id']?.toString() ?? '',
      generatedAt: DateTime.tryParse(json['generated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_user_id': walletUserId,
      'business_id': businessId,
      'source_type': sourceType,
      'display_name': displayName,
      'tanqr_payload': tanqrPayload,
      'alias_merchant_id': aliasMerchantId,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
