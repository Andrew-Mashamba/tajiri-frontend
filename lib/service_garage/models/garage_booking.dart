import 'package:flutter/material.dart';

enum AutoSkill {
  autoMechanic,
  autoElectrician,
  panelBeating,
  sprayPainting;

  String get apiValue {
    switch (this) {
      case AutoSkill.autoMechanic: return 'autoMechanic';
      case AutoSkill.autoElectrician: return 'autoElectrician';
      case AutoSkill.panelBeating: return 'panelBeating';
      case AutoSkill.sprayPainting: return 'sprayPainting';
    }
  }

  String get label {
    switch (this) {
      case AutoSkill.autoMechanic: return 'Auto mechanic';
      case AutoSkill.autoElectrician: return 'Auto electrician';
      case AutoSkill.panelBeating: return 'Panel beating';
      case AutoSkill.sprayPainting: return 'Spray painting';
    }
  }

  String get labelSwahili {
    switch (this) {
      case AutoSkill.autoMechanic: return 'Fundi wa gari';
      case AutoSkill.autoElectrician: return 'Umeme wa gari';
      case AutoSkill.panelBeating: return 'Kupiga bodi';
      case AutoSkill.sprayPainting: return 'Kupaka rangi';
    }
  }

  IconData get icon {
    switch (this) {
      case AutoSkill.autoMechanic: return Icons.build_rounded;
      case AutoSkill.autoElectrician: return Icons.electrical_services_rounded;
      case AutoSkill.panelBeating: return Icons.car_crash_rounded;
      case AutoSkill.sprayPainting: return Icons.format_paint_rounded;
    }
  }

  static AutoSkill fromString(String? raw) {
    switch (raw) {
      case 'autoMechanic': return AutoSkill.autoMechanic;
      case 'autoElectrician': return AutoSkill.autoElectrician;
      case 'panelBeating': return AutoSkill.panelBeating;
      case 'sprayPainting': return AutoSkill.sprayPainting;
      default: return AutoSkill.autoMechanic;
    }
  }
}

enum GarageBookingStatus {
  pending,
  confirmed,
  droppedOff,
  diagnosed,
  approved,
  inProgress,
  readyForPickup,
  completed,
  cancelled,
  rejected;

  String get apiValue {
    switch (this) {
      case GarageBookingStatus.pending: return 'pending';
      case GarageBookingStatus.confirmed: return 'confirmed';
      case GarageBookingStatus.droppedOff: return 'dropped_off';
      case GarageBookingStatus.diagnosed: return 'diagnosed';
      case GarageBookingStatus.approved: return 'approved';
      case GarageBookingStatus.inProgress: return 'in_progress';
      case GarageBookingStatus.readyForPickup: return 'ready_for_pickup';
      case GarageBookingStatus.completed: return 'completed';
      case GarageBookingStatus.cancelled: return 'cancelled';
      case GarageBookingStatus.rejected: return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case GarageBookingStatus.pending: return 'Pending';
      case GarageBookingStatus.confirmed: return 'Confirmed';
      case GarageBookingStatus.droppedOff: return 'Dropped off';
      case GarageBookingStatus.diagnosed: return 'Diagnosed';
      case GarageBookingStatus.approved: return 'Approved';
      case GarageBookingStatus.inProgress: return 'In progress';
      case GarageBookingStatus.readyForPickup: return 'Ready for pickup';
      case GarageBookingStatus.completed: return 'Completed';
      case GarageBookingStatus.cancelled: return 'Cancelled';
      case GarageBookingStatus.rejected: return 'Rejected';
    }
  }

  String get labelSwahili {
    switch (this) {
      case GarageBookingStatus.pending: return 'Inasubiri';
      case GarageBookingStatus.confirmed: return 'Imethibitishwa';
      case GarageBookingStatus.droppedOff: return 'Imefika gereji';
      case GarageBookingStatus.diagnosed: return 'Tatizo limepatikana';
      case GarageBookingStatus.approved: return 'Umekubali';
      case GarageBookingStatus.inProgress: return 'Inafanyiwa kazi';
      case GarageBookingStatus.readyForPickup: return 'Tayari kuchukuliwa';
      case GarageBookingStatus.completed: return 'Imekamilika';
      case GarageBookingStatus.cancelled: return 'Imeghairiwa';
      case GarageBookingStatus.rejected: return 'Imekataliwa';
    }
  }

  static GarageBookingStatus fromString(String? raw) {
    switch (raw) {
      case 'pending': return GarageBookingStatus.pending;
      case 'confirmed': return GarageBookingStatus.confirmed;
      case 'dropped_off': return GarageBookingStatus.droppedOff;
      case 'diagnosed': return GarageBookingStatus.diagnosed;
      case 'approved': return GarageBookingStatus.approved;
      case 'in_progress': return GarageBookingStatus.inProgress;
      case 'ready_for_pickup': return GarageBookingStatus.readyForPickup;
      case 'completed': return GarageBookingStatus.completed;
      case 'cancelled': return GarageBookingStatus.cancelled;
      case 'rejected': return GarageBookingStatus.rejected;
      default: return GarageBookingStatus.pending;
    }
  }
}

/// Tanzanian plate format: T followed by 3 digits then 3 uppercase letters.
final RegExp tzPlateRegex = RegExp(r'^T\d{3}[A-Z]{3}$');

bool isValidTzPlate(String raw) => tzPlateRegex.hasMatch(raw.toUpperCase().trim());

int? _parseIntN(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

class GarageBooking {
  final int id;
  final int customerUserId;
  final String? customerName;
  final String? customerPhotoUrl;
  final String? customerPhone;
  final int targetPartnerUserId;
  final int? targetPartnerId;
  final String? partnerName;
  final String? partnerPhotoUrl;
  final AutoSkill skill;
  final String skillRaw;
  final String vehicleMake;
  final String vehicleModel;
  final String vehiclePlate;
  final int? vehicleYear;
  final String faultSummary;
  final List<String> photos;
  final DateTime? dropOffAt;
  final int? costCapTzs;
  final GarageBookingStatus status;
  final String? diagnosis;
  final int? revisedCostTzs;
  final int? finalCostTzs;
  final String? declineReason;
  final DateTime? confirmedAt;
  final DateTime? droppedOffAt;
  final DateTime? diagnosedAt;
  final DateTime? approvedAt;
  final DateTime? declinedAt;
  final DateTime? inProgressAt;
  final DateTime? readyForPickupAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? rejectedAt;
  final String? cancellationReason;
  final String? rejectionReason;
  final DateTime? createdAt;

  /// Spec line 526 — drop-off mode: driveway|office|shop.
  final String? dropOffMode;
  /// Spec line 533 — partner offers pickup-and-drop courtesy.
  final bool pickupDropOffered;
  /// Spec line 539 — has the customer claimed warranty for this job.
  final bool warrantyClaimed;
  /// Default 12,000 km / 365 days warranty per RepairSmith pattern.
  final int warrantyKm;
  final int warrantyDays;
  /// Spec line 530 — OBD2 / dashboard-light photos uploaded by customer.
  final List<String> obd2Photos;

  GarageBooking({
    required this.id,
    required this.customerUserId,
    required this.customerName,
    required this.customerPhotoUrl,
    required this.customerPhone,
    required this.targetPartnerUserId,
    required this.targetPartnerId,
    required this.partnerName,
    required this.partnerPhotoUrl,
    required this.skill,
    required this.skillRaw,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehiclePlate,
    required this.vehicleYear,
    required this.faultSummary,
    required this.photos,
    required this.dropOffAt,
    required this.costCapTzs,
    required this.status,
    required this.diagnosis,
    required this.revisedCostTzs,
    required this.finalCostTzs,
    required this.declineReason,
    required this.confirmedAt,
    required this.droppedOffAt,
    required this.diagnosedAt,
    required this.approvedAt,
    required this.declinedAt,
    required this.inProgressAt,
    required this.readyForPickupAt,
    required this.completedAt,
    required this.cancelledAt,
    required this.rejectedAt,
    required this.cancellationReason,
    required this.rejectionReason,
    required this.createdAt,
    this.dropOffMode,
    this.pickupDropOffered = false,
    this.warrantyClaimed = false,
    this.warrantyKm = 12000,
    this.warrantyDays = 365,
    this.obd2Photos = const [],
  });

  factory GarageBooking.fromJson(Map<String, dynamic> json) {
    final raw = json['skill_category']?.toString() ?? '';
    final photos = (json['photos'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    return GarageBooking(
      id: _parseIntN(json['id']) ?? 0,
      customerUserId: _parseIntN(json['customer_user_id']) ?? 0,
      customerName: json['customer_name']?.toString(),
      customerPhotoUrl: json['customer_photo_url']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      targetPartnerUserId: _parseIntN(json['target_partner_user_id']) ?? 0,
      targetPartnerId: _parseIntN(json['target_partner_id']),
      partnerName: json['partner_name']?.toString(),
      partnerPhotoUrl: json['partner_photo_url']?.toString(),
      skill: AutoSkill.fromString(raw),
      skillRaw: raw,
      vehicleMake: json['vehicle_make']?.toString() ?? '',
      vehicleModel: json['vehicle_model']?.toString() ?? '',
      vehiclePlate: json['vehicle_plate']?.toString() ?? '',
      vehicleYear: _parseIntN(json['vehicle_year']),
      faultSummary: json['fault_summary']?.toString() ?? '',
      photos: photos,
      dropOffAt: _parseDate(json['drop_off_at']),
      costCapTzs: _parseIntN(json['cost_cap_tzs']),
      status: GarageBookingStatus.fromString(json['status']?.toString()),
      diagnosis: json['diagnosis']?.toString(),
      revisedCostTzs: _parseIntN(json['revised_cost_tzs']),
      finalCostTzs: _parseIntN(json['final_cost_tzs']),
      declineReason: json['decline_reason']?.toString(),
      confirmedAt: _parseDate(json['confirmed_at']),
      droppedOffAt: _parseDate(json['dropped_off_at']),
      diagnosedAt: _parseDate(json['diagnosed_at']),
      approvedAt: _parseDate(json['approved_at']),
      declinedAt: _parseDate(json['declined_at']),
      inProgressAt: _parseDate(json['in_progress_at']),
      readyForPickupAt: _parseDate(json['ready_for_pickup_at']),
      completedAt: _parseDate(json['completed_at']),
      cancelledAt: _parseDate(json['cancelled_at']),
      rejectedAt: _parseDate(json['rejected_at']),
      cancellationReason: json['cancellation_reason']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: _parseDate(json['created_at']),
      dropOffMode: json['drop_off_mode']?.toString(),
      pickupDropOffered: json['pickup_drop_offered'] == true ||
          json['pickup_drop_offered'] == 1 ||
          json['pickup_drop_offered']?.toString() == '1' ||
          json['pickup_drop_offered']?.toString() == 'true',
      warrantyClaimed: json['warranty_claimed'] == true ||
          json['warranty_claimed'] == 1 ||
          json['warranty_claimed']?.toString() == '1' ||
          json['warranty_claimed']?.toString() == 'true',
      warrantyKm: _parseIntN(json['warranty_km']) ?? 12000,
      warrantyDays: _parseIntN(json['warranty_days']) ?? 365,
      obd2Photos: (json['obd2_photos'] is List)
          ? (json['obd2_photos'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }

  DateTime? get warrantyExpiresAt {
    if (completedAt == null) return null;
    return completedAt!.add(Duration(days: warrantyDays));
  }

  bool get isWarrantyActive {
    final exp = warrantyExpiresAt;
    if (exp == null) return false;
    return DateTime.now().isBefore(exp);
  }

  bool get hasFinalised =>
      status == GarageBookingStatus.completed ||
      status == GarageBookingStatus.cancelled ||
      status == GarageBookingStatus.rejected;

  bool get awaitingDiagnosisApproval =>
      status == GarageBookingStatus.diagnosed;
}

class GarageBookingResult {
  final bool success;
  final GarageBooking? booking;
  final String? message;
  final int? statusCode;
  GarageBookingResult({required this.success, this.booking, this.message, this.statusCode});
}

class GarageBookingListResult {
  final bool success;
  final List<GarageBooking> bookings;
  final String? message;
  final int? statusCode;
  GarageBookingListResult({
    required this.success,
    this.bookings = const [],
    this.message,
    this.statusCode,
  });
}

class GarageBookingPhotoUploadResult {
  final bool success;
  final String? photoUrl;
  final String? message;
  GarageBookingPhotoUploadResult({required this.success, this.photoUrl, this.message});
}
