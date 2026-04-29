int? _i(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

class PartnerVipSlot {
  final int id;
  final int partnerUserId;
  final int customerUserId;
  final String? skillCategory;
  final int weekday; // 0 = Sun, 6 = Sat
  final String slotTime; // HH:MM:SS
  final bool isActive;

  PartnerVipSlot({
    required this.id,
    required this.partnerUserId,
    required this.customerUserId,
    required this.skillCategory,
    required this.weekday,
    required this.slotTime,
    required this.isActive,
  });

  factory PartnerVipSlot.fromJson(Map<String, dynamic> json) {
    return PartnerVipSlot(
      id: _i(json['id']) ?? 0,
      partnerUserId: _i(json['partner_user_id']) ?? 0,
      customerUserId: _i(json['customer_user_id']) ?? 0,
      skillCategory: json['skill_category']?.toString(),
      weekday: _i(json['weekday']) ?? 0,
      slotTime: () {
        final raw = json['slot_time']?.toString() ?? '00:00';
        // Backend returns HH:MM:SS; trim to HH:MM for display.
        if (raw.length >= 5) return raw.substring(0, 5);
        return raw;
      }(),
      isActive: json['is_active'] == true ||
          json['is_active'] == 1 ||
          json['is_active']?.toString() == '1' ||
          json['is_active']?.toString() == 'true',
    );
  }
}
