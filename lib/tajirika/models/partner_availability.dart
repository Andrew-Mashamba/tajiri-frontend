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

/// One row of weekly hours per (partner, weekday, skill_category | null).
/// `weekday` follows Carbon convention: 0=Sun..6=Sat.
class PartnerAvailability {
  final int id;
  final int partnerUserId;
  final int weekday;
  /// "HH:mm"
  final String openTime;
  /// "HH:mm"
  final String closeTime;
  final int slotMinutes;
  /// null = Default scope (applies to any skill without its own row)
  final String? skillCategory;
  final bool isActive;
  /// How often reminders fire for upcoming bookings on this row (hours).
  final int? reminderCadenceHours;
  /// Surge / discount modifier on this weekday (e.g. -10 = 10% off, +25 = 25% surge).
  final int? pricingModifierPct;
  /// Spec line 1183 — minimum lead time partner needs before a booking starts.
  final int? minNoticeMinutes;
  /// Maximum days ahead a customer can book.
  final int? bookingHorizonDays;
  /// Spec line 1186 — auto-applied last-minute discount when slot empty <48h.
  final bool lastMinuteDiscountEnabled;
  final int lastMinuteDiscountPct;
  /// Spec line 1190 — fifo | first_to_claim
  final String waitlistMode;
  /// #33 pre/post-buffer + processing time per variant config
  final int? preBufferMinutes;
  final int? processingMinutes;
  final int? postBufferMinutes;
  /// #34 travel buffer + surcharges
  final int? travelSurchargeTzs;
  final int? afterHoursSurchargeTzs;
  final int? holidayPremiumTzs;
  final int? parkingPassThroughTzs;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PartnerAvailability({
    required this.id,
    required this.partnerUserId,
    required this.weekday,
    required this.openTime,
    required this.closeTime,
    required this.slotMinutes,
    required this.skillCategory,
    required this.isActive,
    required this.reminderCadenceHours,
    required this.pricingModifierPct,
    this.minNoticeMinutes,
    this.bookingHorizonDays,
    this.lastMinuteDiscountEnabled = false,
    this.lastMinuteDiscountPct = 0,
    this.waitlistMode = 'fifo',
    this.preBufferMinutes,
    this.processingMinutes,
    this.postBufferMinutes,
    this.travelSurchargeTzs,
    this.afterHoursSurchargeTzs,
    this.holidayPremiumTzs,
    this.parkingPassThroughTzs,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PartnerAvailability.fromJson(Map<String, dynamic> json) {
    return PartnerAvailability(
      id: _parseIntN(json['id']) ?? 0,
      partnerUserId: _parseIntN(json['partner_user_id']) ?? 0,
      weekday: _parseIntN(json['weekday']) ?? 0,
      openTime: (json['open_time']?.toString() ?? '09:00').padRight(5).substring(0, 5),
      closeTime: (json['close_time']?.toString() ?? '17:00').padRight(5).substring(0, 5),
      slotMinutes: _parseIntN(json['slot_minutes']) ?? 30,
      skillCategory: json['skill_category']?.toString(),
      isActive: _parseBool(json['is_active']),
      reminderCadenceHours: _parseIntN(json['reminder_cadence_hours']),
      pricingModifierPct: _parseIntN(json['pricing_modifier_pct']),
      minNoticeMinutes: _parseIntN(json['min_notice_minutes']),
      bookingHorizonDays: _parseIntN(json['booking_horizon_days']),
      lastMinuteDiscountEnabled: _parseBool(json['last_minute_discount_enabled']),
      lastMinuteDiscountPct: _parseIntN(json['last_minute_discount_pct']) ?? 0,
      waitlistMode: json['waitlist_mode']?.toString() ?? 'fifo',
      preBufferMinutes: _parseIntN(json['pre_buffer_minutes']),
      processingMinutes: _parseIntN(json['processing_minutes']),
      postBufferMinutes: _parseIntN(json['post_buffer_minutes']),
      travelSurchargeTzs: _parseIntN(json['travel_surcharge_tzs']),
      afterHoursSurchargeTzs: _parseIntN(json['after_hours_surcharge_tzs']),
      holidayPremiumTzs: _parseIntN(json['holiday_premium_tzs']),
      parkingPassThroughTzs: _parseIntN(json['parking_pass_through_tzs']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  bool get isDefault => skillCategory == null;
}

class PartnerBlackout {
  final int id;
  final int partnerUserId;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? reason;
  final bool allDay;
  /// null = applies to all skills
  final List<String>? skillCategories;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PartnerBlackout({
    required this.id,
    required this.partnerUserId,
    required this.startsAt,
    required this.endsAt,
    required this.reason,
    required this.allDay,
    required this.skillCategories,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PartnerBlackout.fromJson(Map<String, dynamic> json) {
    final cats = json['skill_categories'];
    return PartnerBlackout(
      id: _parseIntN(json['id']) ?? 0,
      partnerUserId: _parseIntN(json['partner_user_id']) ?? 0,
      startsAt: _parseDate(json['starts_at']) ?? DateTime.now(),
      endsAt: _parseDate(json['ends_at']) ?? DateTime.now(),
      reason: json['reason']?.toString(),
      allDay: _parseBool(json['all_day']),
      skillCategories: cats is List
          ? cats.map((e) => e.toString()).toList()
          : null,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  bool appliesToAllSkills() => skillCategories == null;
}

/// One concrete bookable slot returned by the slots() endpoint.
class AvailableSlot {
  final DateTime startsAt;
  final DateTime endsAt;
  final int slotMinutes;

  AvailableSlot({
    required this.startsAt,
    required this.endsAt,
    required this.slotMinutes,
  });

  factory AvailableSlot.fromJson(Map<String, dynamic> json) {
    return AvailableSlot(
      startsAt: _parseDate(json['starts_at']) ?? DateTime.now(),
      endsAt: _parseDate(json['ends_at']) ?? DateTime.now(),
      slotMinutes: _parseIntN(json['slot_minutes']) ?? 30,
    );
  }
}

class PartnerAvailabilityResult {
  final bool success;
  final PartnerAvailability? hours;
  final String? message;
  final int? statusCode;
  PartnerAvailabilityResult({required this.success, this.hours, this.message, this.statusCode});
}

class PartnerAvailabilityListResult {
  final bool success;
  final List<PartnerAvailability> items;
  final String? message;
  final int? statusCode;
  PartnerAvailabilityListResult({
    required this.success,
    this.items = const [],
    this.message,
    this.statusCode,
  });
}

class PartnerBlackoutResult {
  final bool success;
  final PartnerBlackout? blackout;
  final String? message;
  final int? statusCode;
  PartnerBlackoutResult({required this.success, this.blackout, this.message, this.statusCode});
}

class PartnerBlackoutListResult {
  final bool success;
  final List<PartnerBlackout> items;
  final String? message;
  final int? statusCode;
  PartnerBlackoutListResult({
    required this.success,
    this.items = const [],
    this.message,
    this.statusCode,
  });
}

class AvailableSlotListResult {
  final bool success;
  final List<AvailableSlot> items;
  final String? message;
  final int? statusCode;
  AvailableSlotListResult({
    required this.success,
    this.items = const [],
    this.message,
    this.statusCode,
  });
}
