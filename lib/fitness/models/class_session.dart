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

class FitnessClassSession {
  final int id;
  final int partnerId;
  final int? partnerProductId;
  final String title;
  final DateTime startsAt;
  final int durationMinutes;
  final int capacity;
  final int bookedCount;
  final int waitlistCapacity;
  final int priceTzs;
  final bool isDropin;
  final bool isActive;

  FitnessClassSession({
    required this.id,
    required this.partnerId,
    required this.partnerProductId,
    required this.title,
    required this.startsAt,
    required this.durationMinutes,
    required this.capacity,
    required this.bookedCount,
    required this.waitlistCapacity,
    required this.priceTzs,
    required this.isDropin,
    required this.isActive,
  });

  factory FitnessClassSession.fromJson(Map<String, dynamic> json) {
    return FitnessClassSession(
      id: _parseIntN(json['id']) ?? 0,
      partnerId: _parseIntN(json['partner_id']) ?? 0,
      partnerProductId: _parseIntN(json['partner_product_id']),
      title: json['title']?.toString() ?? '',
      startsAt: _parseDate(json['starts_at']) ?? DateTime.now(),
      durationMinutes: _parseIntN(json['duration_minutes']) ?? 60,
      capacity: _parseIntN(json['capacity']) ?? 1,
      bookedCount: _parseIntN(json['booked_count']) ?? 0,
      waitlistCapacity: _parseIntN(json['waitlist_capacity']) ?? 0,
      priceTzs: _parseIntN(json['price_tzs']) ?? 0,
      isDropin: _parseBool(json['is_dropin']),
      isActive: _parseBool(json['is_active']),
    );
  }

  bool get isFull => bookedCount >= capacity;
  int get spotsLeft => (capacity - bookedCount).clamp(0, capacity);
}

class ClassSessionBooking {
  final int id;
  final int classSessionId;
  final int customerUserId;
  final String status;
  final int? spotNumber;

  ClassSessionBooking({
    required this.id,
    required this.classSessionId,
    required this.customerUserId,
    required this.status,
    required this.spotNumber,
  });

  factory ClassSessionBooking.fromJson(Map<String, dynamic> json) {
    return ClassSessionBooking(
      id: _parseIntN(json['id']) ?? 0,
      classSessionId: _parseIntN(json['class_session_id']) ?? 0,
      customerUserId: _parseIntN(json['customer_user_id']) ?? 0,
      status: json['status']?.toString() ?? 'confirmed',
      spotNumber: _parseIntN(json['spot_number']),
    );
  }
}
