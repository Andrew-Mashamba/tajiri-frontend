int? _parseIntN(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

class PartnerCannedMessage {
  final int id;
  final int partnerUserId;
  final String label;
  final String body;
  final bool isActive;

  PartnerCannedMessage({
    required this.id,
    required this.partnerUserId,
    required this.label,
    required this.body,
    required this.isActive,
  });

  factory PartnerCannedMessage.fromJson(Map<String, dynamic> json) {
    return PartnerCannedMessage(
      id: _parseIntN(json['id']) ?? 0,
      partnerUserId: _parseIntN(json['partner_user_id']) ?? 0,
      label: json['label']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      isActive: json['is_active'] == true,
    );
  }
}
