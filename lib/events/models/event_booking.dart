import 'package:flutter/material.dart';

/// Spec §10 line 959 — five event kinds drive UI defaults (icon, copy).
enum EventKind {
  wedding,
  birthday,
  safari,
  corporate,
  other;

  String get apiValue {
    switch (this) {
      case EventKind.wedding: return 'wedding';
      case EventKind.birthday: return 'birthday';
      case EventKind.safari: return 'safari';
      case EventKind.corporate: return 'corporate';
      case EventKind.other: return 'other';
    }
  }

  String get label {
    switch (this) {
      case EventKind.wedding: return 'Wedding';
      case EventKind.birthday: return 'Birthday';
      case EventKind.safari: return 'Safari';
      case EventKind.corporate: return 'Corporate';
      case EventKind.other: return 'Other';
    }
  }

  String get labelSwahili {
    switch (this) {
      case EventKind.wedding: return 'Harusi';
      case EventKind.birthday: return 'Sherehe';
      case EventKind.safari: return 'Safari';
      case EventKind.corporate: return 'Kampuni';
      case EventKind.other: return 'Nyingine';
    }
  }

  IconData get icon {
    switch (this) {
      case EventKind.wedding: return Icons.celebration_rounded;
      case EventKind.birthday: return Icons.cake_rounded;
      case EventKind.safari: return Icons.terrain_rounded;
      case EventKind.corporate: return Icons.business_rounded;
      case EventKind.other: return Icons.event_rounded;
    }
  }

  static EventKind fromString(String? raw) {
    switch (raw) {
      case 'wedding': return EventKind.wedding;
      case 'birthday': return EventKind.birthday;
      case 'safari': return EventKind.safari;
      case 'corporate': return EventKind.corporate;
      case 'other': return EventKind.other;
      default: return EventKind.other;
    }
  }
}

/// Spec §10 — full lifecycle.
enum EventBookingStatus {
  pending,
  held,
  confirmed, // deposit captured → confirmed (Wallet stub flips both in one call)
  dayOf,
  completed,
  cancelled,
  rejected;

  String get apiValue {
    switch (this) {
      case EventBookingStatus.pending: return 'pending';
      case EventBookingStatus.held: return 'held';
      case EventBookingStatus.confirmed: return 'confirmed';
      case EventBookingStatus.dayOf: return 'day_of';
      case EventBookingStatus.completed: return 'completed';
      case EventBookingStatus.cancelled: return 'cancelled';
      case EventBookingStatus.rejected: return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case EventBookingStatus.pending: return 'Pending';
      case EventBookingStatus.held: return 'Date held';
      case EventBookingStatus.confirmed: return 'Confirmed';
      case EventBookingStatus.dayOf: return 'Day of';
      case EventBookingStatus.completed: return 'Completed';
      case EventBookingStatus.cancelled: return 'Cancelled';
      case EventBookingStatus.rejected: return 'Rejected';
    }
  }

  String get labelSwahili {
    switch (this) {
      case EventBookingStatus.pending: return 'Inasubiri';
      case EventBookingStatus.held: return 'Tarehe imehifadhiwa';
      case EventBookingStatus.confirmed: return 'Imekubaliwa';
      case EventBookingStatus.dayOf: return 'Siku ya hafla';
      case EventBookingStatus.completed: return 'Imekamilika';
      case EventBookingStatus.cancelled: return 'Imeghairiwa';
      case EventBookingStatus.rejected: return 'Imekataliwa';
    }
  }

  static EventBookingStatus fromString(String? raw) {
    switch (raw) {
      case 'pending': return EventBookingStatus.pending;
      case 'held': return EventBookingStatus.held;
      case 'deposit_paid': return EventBookingStatus.confirmed; // backend skips deposit_paid for now
      case 'confirmed': return EventBookingStatus.confirmed;
      case 'day_of': return EventBookingStatus.dayOf;
      case 'completed': return EventBookingStatus.completed;
      case 'cancelled': return EventBookingStatus.cancelled;
      case 'rejected': return EventBookingStatus.rejected;
      default: return EventBookingStatus.pending;
    }
  }
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

int? _parseIntN(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _parseDoubleN(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

class EventAddOn {
  final String label;
  final int qty;
  final int priceTzs;

  EventAddOn({required this.label, required this.qty, required this.priceTzs});

  factory EventAddOn.fromJson(Map<String, dynamic> json) {
    return EventAddOn(
      label: json['label']?.toString() ?? '',
      qty: _parseIntN(json['qty']) ?? 1,
      priceTzs: _parseIntN(json['price_tzs']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'qty': qty,
        'price_tzs': priceTzs,
      };

  int get subtotalTzs => qty * priceTzs;
}

class ItineraryDay {
  final int day;
  final String? location;
  final String? activity;
  final String? accommodation;
  final String? includedMeals;

  ItineraryDay({
    required this.day,
    this.location,
    this.activity,
    this.accommodation,
    this.includedMeals,
  });

  factory ItineraryDay.fromJson(Map<String, dynamic> json) {
    return ItineraryDay(
      day: _parseIntN(json['day']) ?? 1,
      location: json['location']?.toString(),
      activity: json['activity']?.toString(),
      accommodation: json['accommodation']?.toString(),
      includedMeals: json['included_meals']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        if (location != null) 'location': location,
        if (activity != null) 'activity': activity,
        if (accommodation != null) 'accommodation': accommodation,
        if (includedMeals != null) 'included_meals': includedMeals,
      };
}

/// Encrypted-at-rest in spec; v1 stores plain JSON (same deferral as F7 intake).
class Traveler {
  final String name;
  final String? nidaOrPassport;
  final String? dietary;
  final String? medical;
  final String? emergencyContact;

  Traveler({
    required this.name,
    this.nidaOrPassport,
    this.dietary,
    this.medical,
    this.emergencyContact,
  });

  factory Traveler.fromJson(Map<String, dynamic> json) {
    return Traveler(
      name: json['name']?.toString() ?? '',
      nidaOrPassport: json['nida_or_passport']?.toString(),
      dietary: json['dietary']?.toString(),
      medical: json['medical']?.toString(),
      emergencyContact: json['emergency_contact']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (nidaOrPassport != null) 'nida_or_passport': nidaOrPassport,
        if (dietary != null) 'dietary': dietary,
        if (medical != null) 'medical': medical,
        if (emergencyContact != null) 'emergency_contact': emergencyContact,
      };
}

class EventBooking {
  final int id;
  final int customerUserId;
  final String? customerName;
  final String? customerPhotoUrl;
  final String? customerPhone;
  final int partnerUserId;
  final int? partnerId;
  final String? partnerName;
  final String? partnerPhotoUrl;
  final int? partnerProductId;

  final String? skillCategory;
  final EventKind eventKind;
  final String eventTitle;
  final DateTime eventStartsAt;
  final DateTime? eventEndsAt;
  final String? eventAddress;
  final double? eventLat;
  final double? eventLng;
  final int partySize;

  final int basePriceTzs;
  final List<EventAddOn> addOns;
  final int totalTzs;
  final int depositTzs;
  final DateTime? depositDueAt;
  final DateTime? depositPaidAt;
  final int balanceTzs;
  final DateTime? balancePaidAt;

  final List<ItineraryDay> itinerary;
  final List<Traveler> travelers;

  final EventBookingStatus status;
  final DateTime? heldAt;
  final DateTime? rejectedAt;
  final DateTime? dayOfAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? rejectionReason;
  final String? cancellationReason;

  /// Spec line 1208 — set when partner has confirmed a backup performer.
  /// Provides peace-of-mind chip on day-of dashboards.
  final String? backupPerformerName;
  final int? backupPerformerAmountTzs;
  /// ISO date when force majeure was triggered (auto-cancel/refund flow).
  final DateTime? forceMajeureAt;
  /// Spec line 1019 — partner's travel cap (km) + per-km surcharge.
  final int? travelRadiusKm;
  final int? travelPerKmTzs;
  /// Spec line 1022 — refund-policy tiers, e.g. {tier_60: 100, tier_30: 50, tier_0: 0}.
  final Map<String, dynamic>? refundPolicy;
  /// Spec line 1031 — package tier label: basix|original|comfort|premium.
  final String? packageTier;
  /// Spec line 1033 — QR-redeemable voucher code for shorter tours.
  final String? qrVoucherCode;
  /// Spec line 1037 — true when customer opted into travel insurance upsell.
  final bool travelInsuranceOptin;
  /// Spec line 1041 — auto-applied early-bird discount (12+ months out).
  final bool earlyBirdApplied;
  /// Spec line 1042 — auto-applied group discount.
  final bool groupDiscountApplied;
  final int groupDiscountPct;
  /// Spec line 1045 — per-stop reviews captured on multi-day tours.
  final List<Map<String, dynamic>> perStopReviews;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  EventBooking({
    required this.id,
    required this.customerUserId,
    required this.customerName,
    required this.customerPhotoUrl,
    required this.customerPhone,
    required this.partnerUserId,
    required this.partnerId,
    required this.partnerName,
    required this.partnerPhotoUrl,
    required this.partnerProductId,
    required this.skillCategory,
    required this.eventKind,
    required this.eventTitle,
    required this.eventStartsAt,
    required this.eventEndsAt,
    required this.eventAddress,
    required this.eventLat,
    required this.eventLng,
    required this.partySize,
    required this.basePriceTzs,
    required this.addOns,
    required this.totalTzs,
    required this.depositTzs,
    required this.depositDueAt,
    required this.depositPaidAt,
    required this.balanceTzs,
    required this.balancePaidAt,
    required this.itinerary,
    required this.travelers,
    required this.status,
    required this.heldAt,
    required this.rejectedAt,
    required this.dayOfAt,
    required this.completedAt,
    required this.cancelledAt,
    required this.rejectionReason,
    required this.cancellationReason,
    this.backupPerformerName,
    this.backupPerformerAmountTzs,
    this.forceMajeureAt,
    this.travelRadiusKm,
    this.travelPerKmTzs,
    this.refundPolicy,
    this.packageTier,
    this.qrVoucherCode,
    this.travelInsuranceOptin = false,
    this.earlyBirdApplied = false,
    this.groupDiscountApplied = false,
    this.groupDiscountPct = 0,
    this.perStopReviews = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventBooking.fromJson(Map<String, dynamic> json) {
    final addOnsRaw = json['add_ons'];
    final iterRaw = json['itinerary'];
    final travelersRaw = json['travelers'];
    return EventBooking(
      id: _parseIntN(json['id']) ?? 0,
      customerUserId: _parseIntN(json['customer_user_id']) ?? 0,
      customerName: json['customer_name']?.toString(),
      customerPhotoUrl: json['customer_photo_url']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      partnerUserId: _parseIntN(json['partner_user_id']) ?? 0,
      partnerId: _parseIntN(json['partner_id']),
      partnerName: json['partner_name']?.toString(),
      partnerPhotoUrl: json['partner_photo_url']?.toString(),
      partnerProductId: _parseIntN(json['partner_product_id']),
      skillCategory: json['skill_category']?.toString(),
      eventKind: EventKind.fromString(json['event_kind']?.toString()),
      eventTitle: json['event_title']?.toString() ?? '',
      eventStartsAt: _parseDate(json['event_starts_at']) ?? DateTime.now(),
      eventEndsAt: _parseDate(json['event_ends_at']),
      eventAddress: json['event_address']?.toString(),
      eventLat: _parseDoubleN(json['event_lat']),
      eventLng: _parseDoubleN(json['event_lng']),
      partySize: _parseIntN(json['party_size']) ?? 1,
      basePriceTzs: _parseIntN(json['base_price_tzs']) ?? 0,
      addOns: addOnsRaw is List
          ? addOnsRaw
              .whereType<Map>()
              .map((m) => EventAddOn.fromJson(m.cast<String, dynamic>()))
              .toList()
          : const <EventAddOn>[],
      totalTzs: _parseIntN(json['total_tzs']) ?? 0,
      depositTzs: _parseIntN(json['deposit_tzs']) ?? 0,
      depositDueAt: _parseDate(json['deposit_due_at']),
      depositPaidAt: _parseDate(json['deposit_paid_at']),
      balanceTzs: _parseIntN(json['balance_tzs']) ?? 0,
      balancePaidAt: _parseDate(json['balance_paid_at']),
      itinerary: iterRaw is List
          ? iterRaw
              .whereType<Map>()
              .map((m) => ItineraryDay.fromJson(m.cast<String, dynamic>()))
              .toList()
          : const <ItineraryDay>[],
      travelers: travelersRaw is List
          ? travelersRaw
              .whereType<Map>()
              .map((m) => Traveler.fromJson(m.cast<String, dynamic>()))
              .toList()
          : const <Traveler>[],
      status: EventBookingStatus.fromString(json['status']?.toString()),
      heldAt: _parseDate(json['held_at']),
      rejectedAt: _parseDate(json['rejected_at']),
      dayOfAt: _parseDate(json['day_of_at']),
      completedAt: _parseDate(json['completed_at']),
      cancelledAt: _parseDate(json['cancelled_at']),
      rejectionReason: json['rejection_reason']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
      backupPerformerName: json['backup_performer']?.toString(),
      backupPerformerAmountTzs: _parseIntN(json['backup_performer_amount_tzs']),
      forceMajeureAt: _parseDate(json['force_majeure_at']),
      travelRadiusKm: _parseIntN(json['travel_radius_km']),
      travelPerKmTzs: _parseIntN(json['travel_per_km_tzs']),
      refundPolicy: json['refund_policy'] is Map
          ? (json['refund_policy'] as Map).cast<String, dynamic>()
          : null,
      packageTier: json['package_tier'] is Map
          ? json['package_tier'].toString()
          : json['package_tier']?.toString(),
      qrVoucherCode: json['qr_voucher_code']?.toString(),
      travelInsuranceOptin: _parseBool(json['travel_insurance_optin']),
      earlyBirdApplied: _parseBool(json['early_bird_applied']),
      groupDiscountApplied: _parseBool(json['group_discount_applied']),
      groupDiscountPct: _parseIntN(json['group_discount_pct']) ?? 0,
      perStopReviews: (json['per_stop_reviews'] is List)
          ? (json['per_stop_reviews'] as List)
              .whereType<Map>()
              .map((m) => m.cast<String, dynamic>())
              .toList()
          : const [],
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  bool get hasFinalised =>
      status == EventBookingStatus.completed ||
      status == EventBookingStatus.cancelled ||
      status == EventBookingStatus.rejected;

  bool get isDepositOverdue {
    if (status != EventBookingStatus.held) return false;
    if (depositDueAt == null) return false;
    return DateTime.now().isAfter(depositDueAt!);
  }

  bool get isCancellableByEither =>
      !hasFinalised && status != EventBookingStatus.dayOf;
}

class EventBookingResult {
  final bool success;
  final EventBooking? booking;
  final String? message;
  final int? statusCode;
  EventBookingResult({required this.success, this.booking, this.message, this.statusCode});
}

class EventBookingListResult {
  final bool success;
  final List<EventBooking> items;
  final String? message;
  final int? statusCode;
  EventBookingListResult({required this.success, this.items = const [], this.message, this.statusCode});
}
