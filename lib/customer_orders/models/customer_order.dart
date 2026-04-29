import '../../config/api_config.dart';
import '../../tajirika/models/tajirika_models.dart' show SkillCategory;

/// Source module that originated this consumer-to-partner order.
enum CustomerOrderSource {
  chefListing,
  chefProduct,
  partnerProduct,
  serviceRequest,
  garageBooking,
  appointment,
  consultation,
  engagement,
  listingInquiry,
  eventBooking,
}

extension CustomerOrderSourceX on CustomerOrderSource {
  String get apiValue {
    switch (this) {
      case CustomerOrderSource.chefListing:
        return 'chef_listing';
      case CustomerOrderSource.chefProduct:
        return 'chef_product';
      case CustomerOrderSource.partnerProduct:
        return 'partner_product';
      case CustomerOrderSource.serviceRequest:
        return 'service_request';
      case CustomerOrderSource.garageBooking:
        return 'garage_booking';
      case CustomerOrderSource.appointment:
        return 'appointment';
      case CustomerOrderSource.consultation:
        return 'consultation';
      case CustomerOrderSource.engagement:
        return 'engagement';
      case CustomerOrderSource.listingInquiry:
        return 'listing_inquiry';
      case CustomerOrderSource.eventBooking:
        return 'event_booking';
    }
  }

  String get labelSwahili {
    switch (this) {
      case CustomerOrderSource.chefListing:
        return 'Chakula cha siku';
      case CustomerOrderSource.chefProduct:
        return 'Bidhaa ya kuagiza';
      case CustomerOrderSource.partnerProduct:
        return 'Bidhaa ya mshirika';
      case CustomerOrderSource.serviceRequest:
        return 'Huduma ya nyumbani';
      case CustomerOrderSource.garageBooking:
        return 'Booking ya gari';
      case CustomerOrderSource.appointment:
        return 'Miadi';
      case CustomerOrderSource.consultation:
        return 'Ushauri';
      case CustomerOrderSource.engagement:
        return 'Mkataba';
      case CustomerOrderSource.listingInquiry:
        return 'Mali';
      case CustomerOrderSource.eventBooking:
        return 'Hafla';
    }
  }

  static CustomerOrderSource fromString(String? s) {
    switch (s) {
      case 'chef_product':
        return CustomerOrderSource.chefProduct;
      case 'partner_product':
        return CustomerOrderSource.partnerProduct;
      case 'service_request':
        return CustomerOrderSource.serviceRequest;
      case 'garage_booking':
        return CustomerOrderSource.garageBooking;
      case 'appointment':
        return CustomerOrderSource.appointment;
      case 'consultation':
        return CustomerOrderSource.consultation;
      case 'engagement':
        return CustomerOrderSource.engagement;
      case 'listing_inquiry':
        return CustomerOrderSource.listingInquiry;
      case 'event_booking':
        return CustomerOrderSource.eventBooking;
      default:
        return CustomerOrderSource.chefListing;
    }
  }
}

enum CustomerOrderStatus {
  pending,
  accepted,
  preparing,
  ready,
  outForDelivery,
  completed,
  cancelled,
  rejected,
}

extension CustomerOrderStatusX on CustomerOrderStatus {
  String get apiValue {
    switch (this) {
      case CustomerOrderStatus.pending:
        return 'pending';
      case CustomerOrderStatus.accepted:
        return 'accepted';
      case CustomerOrderStatus.preparing:
        return 'preparing';
      case CustomerOrderStatus.ready:
        return 'ready';
      case CustomerOrderStatus.outForDelivery:
        return 'out_for_delivery';
      case CustomerOrderStatus.completed:
        return 'completed';
      case CustomerOrderStatus.cancelled:
        return 'cancelled';
      case CustomerOrderStatus.rejected:
        return 'rejected';
    }
  }

  String get labelSwahili {
    switch (this) {
      case CustomerOrderStatus.pending:
        return 'Inasubiri';
      case CustomerOrderStatus.accepted:
        return 'Imekubaliwa';
      case CustomerOrderStatus.preparing:
        return 'Inaandaliwa';
      case CustomerOrderStatus.ready:
        return 'Tayari';
      case CustomerOrderStatus.outForDelivery:
        return 'Njiani';
      case CustomerOrderStatus.completed:
        return 'Imekamilika';
      case CustomerOrderStatus.cancelled:
        return 'Imeghairiwa';
      case CustomerOrderStatus.rejected:
        return 'Imekataliwa';
    }
  }

  bool get isTerminal =>
      this == CustomerOrderStatus.completed ||
      this == CustomerOrderStatus.cancelled ||
      this == CustomerOrderStatus.rejected;

  static CustomerOrderStatus fromString(String? s) {
    switch (s) {
      case 'accepted':
        return CustomerOrderStatus.accepted;
      case 'preparing':
        return CustomerOrderStatus.preparing;
      case 'ready':
      case 'ready_for_pickup':
        return CustomerOrderStatus.ready;
      case 'out_for_delivery':
        return CustomerOrderStatus.outForDelivery;
      case 'completed':
      case 'delivered':
      case 'picked_up':
        return CustomerOrderStatus.completed;
      case 'cancelled':
      case 'canceled':
        return CustomerOrderStatus.cancelled;
      case 'rejected':
        return CustomerOrderStatus.rejected;
      default:
        return CustomerOrderStatus.pending;
    }
  }
}

class CustomerOrder {
  final int id;
  final CustomerOrderSource source;
  final int sourceRefId;

  final int partnerId;
  final int partnerUserId;
  final String? partnerName;
  final String? partnerPhotoUrl;

  final int buyerUserId;
  final String? buyerName;
  final String? buyerPhotoUrl;
  final String? buyerPhone;

  final String itemTitle;
  final String? skillCategoryRaw;
  final SkillCategory? skillCategory;
  final String? itemPhotoUrl;
  final int quantity;
  final int? unitPriceTzs;
  final int totalPriceTzs;

  final CustomerOrderStatus status;
  final String deliveryMode;
  final String? deliveryAddress;
  final int? deliveryFeeTzs;

  final DateTime? requestedFor;
  final DateTime createdAt;
  final String? notes;
  final String? rejectionReason;

  /// Spec line 251 — 4-digit handoff PIN displayed on customer order page;
  /// courier types it on arrival. Null until generated.
  final String? handoffPin;
  /// Spec line 252 — partner-uploaded photo proof of delivery / completion.
  final String? deliveryProofPhoto;
  /// Spec line 254 — post-delivery tip in TZS (default 0).
  final int tipTzs;
  final DateTime? tipAddedAt;
  /// Spec line 257 — 3-day window for self-reporting issues; auto-credit before this expires.
  final bool customerSelfReportedIssue;
  final DateTime? selfReportDeadline;

  /// F3 #17 — lead-expiring countdown for quote-bid sources.
  final int? minutesLeft;
  final int? competitorCount;

  CustomerOrder({
    required this.id,
    required this.source,
    required this.sourceRefId,
    required this.partnerId,
    required this.partnerUserId,
    required this.partnerName,
    required this.partnerPhotoUrl,
    required this.buyerUserId,
    required this.buyerName,
    required this.buyerPhotoUrl,
    required this.buyerPhone,
    required this.itemTitle,
    required this.skillCategoryRaw,
    required this.skillCategory,
    required this.itemPhotoUrl,
    required this.quantity,
    required this.unitPriceTzs,
    required this.totalPriceTzs,
    required this.status,
    required this.deliveryMode,
    required this.deliveryAddress,
    required this.deliveryFeeTzs,
    required this.requestedFor,
    required this.createdAt,
    required this.notes,
    required this.rejectionReason,
    this.handoffPin,
    this.deliveryProofPhoto,
    this.tipTzs = 0,
    this.tipAddedAt,
    this.customerSelfReportedIssue = false,
    this.selfReportDeadline,
    this.minutesLeft,
    this.competitorCount,
  });

  bool get isDelivery => deliveryMode == 'delivery';

  String get resolvedItemPhoto {
    final p = itemPhotoUrl ?? '';
    if (p.isEmpty) return '';
    if (p.startsWith('http')) return ApiConfig.sanitizeUrl(p) ?? '';
    return ApiConfig.sanitizeUrl('${ApiConfig.storageUrl}/$p') ?? '';
  }

  String get resolvedBuyerPhoto {
    final p = buyerPhotoUrl ?? '';
    if (p.isEmpty) return '';
    if (p.startsWith('http')) return ApiConfig.sanitizeUrl(p) ?? '';
    return ApiConfig.sanitizeUrl('${ApiConfig.storageUrl}/$p') ?? '';
  }

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    return CustomerOrder(
      id: _parseInt(json['id']) ?? 0,
      source: CustomerOrderSourceX.fromString(json['source']?.toString()),
      sourceRefId: _parseInt(json['source_ref_id']) ?? 0,
      partnerId: _parseInt(json['partner_id']) ?? 0,
      partnerUserId: _parseInt(json['partner_user_id']) ?? 0,
      partnerName: json['partner_name']?.toString(),
      partnerPhotoUrl: json['partner_photo_url']?.toString(),
      buyerUserId: _parseInt(json['buyer_user_id']) ?? 0,
      buyerName: json['buyer_name']?.toString(),
      buyerPhotoUrl: json['buyer_photo_url']?.toString(),
      buyerPhone: json['buyer_phone']?.toString(),
      itemTitle: json['item_title']?.toString() ?? '',
      skillCategoryRaw: json['skill_category']?.toString(),
      skillCategory: _resolveSkillCategory(json['skill_category']?.toString()),
      itemPhotoUrl: json['item_photo_url']?.toString(),
      quantity: _parseInt(json['quantity']) ?? 1,
      unitPriceTzs: _parseInt(json['unit_price_tzs']),
      totalPriceTzs: _parseInt(json['total_price_tzs']) ?? 0,
      status: CustomerOrderStatusX.fromString(json['status']?.toString()),
      deliveryMode: json['delivery_mode']?.toString() ?? 'pickup',
      deliveryAddress: json['delivery_address']?.toString(),
      deliveryFeeTzs: _parseInt(json['delivery_fee_tzs']),
      requestedFor: _parseDate(json['requested_for']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      notes: json['notes']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      handoffPin: json['handoff_pin']?.toString(),
      deliveryProofPhoto: json['delivery_proof_photo']?.toString(),
      tipTzs: _parseInt(json['tip_tzs']) ?? 0,
      tipAddedAt: _parseDate(json['tip_added_at']),
      customerSelfReportedIssue: json['customer_self_reported_issue'] == true ||
          json['customer_self_reported_issue'] == 1 ||
          json['customer_self_reported_issue']?.toString() == '1' ||
          json['customer_self_reported_issue']?.toString() == 'true',
      selfReportDeadline: _parseDate(json['self_report_deadline']),
      minutesLeft: _parseInt(json['minutes_left']),
      competitorCount: _parseInt(json['competitor_count']),
    );
  }
}

SkillCategory? _resolveSkillCategory(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  // Legacy partner_products values use snake_case aliases that pre-date the
  // current SkillCategory enum names. Map them so the icon/label render right.
  const aliases = <String, String>{
    'cook_chef': 'cooking',
    'chef': 'cooking',
    'baker': 'baking',
    'caterer': 'catering',
  };
  final canonical = aliases[raw] ?? raw;
  return SkillCategory.fromString(canonical);
}

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
