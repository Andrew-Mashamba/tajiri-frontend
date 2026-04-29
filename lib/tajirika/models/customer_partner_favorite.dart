int? _parseIntN(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

class CustomerPartnerFavorite {
  final int id;
  final int customerUserId;
  final int partnerUserId;
  final String? skillCategory;
  final String? partnerName;
  final String? partnerPhotoUrl;

  CustomerPartnerFavorite({
    required this.id,
    required this.customerUserId,
    required this.partnerUserId,
    required this.skillCategory,
    required this.partnerName,
    required this.partnerPhotoUrl,
  });

  factory CustomerPartnerFavorite.fromJson(Map<String, dynamic> json) {
    return CustomerPartnerFavorite(
      id: _parseIntN(json['id']) ?? 0,
      customerUserId: _parseIntN(json['customer_user_id']) ?? 0,
      partnerUserId: _parseIntN(json['partner_user_id']) ?? 0,
      skillCategory: json['skill_category']?.toString(),
      partnerName: json['name']?.toString(),
      partnerPhotoUrl: json['profile_photo']?.toString(),
    );
  }
}
