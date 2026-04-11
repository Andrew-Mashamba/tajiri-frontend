// lib/events/models/event_ticket.dart
import 'event_enums.dart';
import 'event.dart';

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

class TicketTier {
  final int id;
  final int eventId;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final int totalQuantity;
  final int soldQuantity;
  final int maxPerOrder;
  final int minPerOrder;
  final DateTime? saleStartDate;
  final DateTime? saleEndDate;
  final bool isHidden;
  final String? accessCode;
  final List<TicketAddon> addons;
  final bool isTransferable;
  final bool isRefundable;

  TicketTier({
    required this.id,
    required this.eventId,
    required this.name,
    this.description,
    this.price = 0,
    this.currency = 'TZS',
    this.totalQuantity = 0,
    this.soldQuantity = 0,
    this.maxPerOrder = 10,
    this.minPerOrder = 1,
    this.saleStartDate,
    this.saleEndDate,
    this.isHidden = false,
    this.accessCode,
    this.addons = const [],
    this.isTransferable = true,
    this.isRefundable = true,
  });

  bool get isOnSale {
    final now = DateTime.now();
    if (saleStartDate != null && now.isBefore(saleStartDate!)) return false;
    if (saleEndDate != null && now.isAfter(saleEndDate!)) return false;
    return true;
  }

  bool get isSoldOut => totalQuantity > 0 && soldQuantity >= totalQuantity;
  int get available => totalQuantity > 0 ? totalQuantity - soldQuantity : -1;
  bool get isFree => price <= 0;

  factory TicketTier.fromJson(Map<String, dynamic> json) {
    return TicketTier(
      id: _parseInt(json['id']),
      eventId: _parseInt(json['event_id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: _parseDouble(json['price']),
      currency: json['currency']?.toString() ?? 'TZS',
      totalQuantity: _parseInt(json['total_quantity']),
      soldQuantity: _parseInt(json['sold_quantity']),
      maxPerOrder: json['max_per_order'] != null ? _parseInt(json['max_per_order']) : 10,
      minPerOrder: json['min_per_order'] != null ? _parseInt(json['min_per_order']) : 1,
      saleStartDate: json['sale_start_date'] != null ? DateTime.tryParse(json['sale_start_date'].toString()) : null,
      saleEndDate: json['sale_end_date'] != null ? DateTime.tryParse(json['sale_end_date'].toString()) : null,
      isHidden: _parseBool(json['is_hidden']),
      accessCode: json['access_code']?.toString(),
      addons: (json['addons'] as List?)?.map((e) => TicketAddon.fromJson(e)).toList() ?? [],
      isTransferable: json['is_transferable'] != null ? _parseBool(json['is_transferable']) : true,
      isRefundable: json['is_refundable'] != null ? _parseBool(json['is_refundable']) : true,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'price': price,
    'currency': currency,
    'total_quantity': totalQuantity,
    'max_per_order': maxPerOrder,
    'min_per_order': minPerOrder,
    'sale_start_date': saleStartDate?.toIso8601String().split('T').first,
    'sale_end_date': saleEndDate?.toIso8601String().split('T').first,
    'is_hidden': isHidden,
    'access_code': accessCode,
    'is_transferable': isTransferable,
    'is_refundable': isRefundable,
  };
}

class TicketAddon {
  final int id;
  final String name;
  final double price;
  final String currency;
  final int? maxQuantity;

  TicketAddon({
    required this.id,
    required this.name,
    this.price = 0,
    this.currency = 'TZS',
    this.maxQuantity,
  });

  factory TicketAddon.fromJson(Map<String, dynamic> json) {
    return TicketAddon(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      price: _parseDouble(json['price']),
      currency: json['currency']?.toString() ?? 'TZS',
      maxQuantity: json['max_quantity'] != null ? _parseInt(json['max_quantity']) : null,
    );
  }
}

class EventTicket {
  final int id;
  final int eventId;
  final int userId;
  final int? ticketTierId;
  final String ticketNumber;
  final String? qrCodeData;
  final TicketStatus status;
  final DateTime purchaseDate;
  final double pricePaid;
  final String currency;
  final String paymentMethod;
  final String? paymentReference;
  final List<TicketAddon> addons;
  final int? transferredFromUserId;
  final int? transferredToUserId;
  final DateTime? checkedInAt;
  final Event? event;
  final TicketTier? tier;
  final String? guestName;
  final String? guestPhone;

  EventTicket({
    required this.id,
    required this.eventId,
    required this.userId,
    this.ticketTierId,
    required this.ticketNumber,
    this.qrCodeData,
    this.status = TicketStatus.active,
    required this.purchaseDate,
    this.pricePaid = 0,
    this.currency = 'TZS',
    this.paymentMethod = 'mpesa',
    this.paymentReference,
    this.addons = const [],
    this.transferredFromUserId,
    this.transferredToUserId,
    this.checkedInAt,
    this.event,
    this.tier,
    this.guestName,
    this.guestPhone,
  });

  bool get isValid => status == TicketStatus.active;
  bool get isCheckedIn => checkedInAt != null;
  bool get isTransferred => transferredToUserId != null;

  factory EventTicket.fromJson(Map<String, dynamic> json) {
    return EventTicket(
      id: _parseInt(json['id']),
      eventId: _parseInt(json['event_id']),
      userId: _parseInt(json['user_id']),
      ticketTierId: json['ticket_tier_id'] != null ? _parseInt(json['ticket_tier_id']) : null,
      ticketNumber: json['ticket_number']?.toString() ?? '',
      qrCodeData: json['qr_code_data']?.toString() ?? json['qr_code']?.toString(),
      status: TicketStatus.fromApi(json['status']?.toString()),
      purchaseDate: DateTime.tryParse(json['purchase_date']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
      pricePaid: _parseDouble(json['price_paid']),
      currency: json['currency']?.toString() ?? 'TZS',
      paymentMethod: json['payment_method']?.toString() ?? 'mpesa',
      paymentReference: json['payment_reference']?.toString(),
      addons: (json['addons'] as List?)?.map((e) => TicketAddon.fromJson(e)).toList() ?? [],
      transferredFromUserId: json['transferred_from_user_id'] != null ? _parseInt(json['transferred_from_user_id']) : null,
      transferredToUserId: json['transferred_to_user_id'] != null ? _parseInt(json['transferred_to_user_id']) : null,
      checkedInAt: json['checked_in_at'] != null ? DateTime.tryParse(json['checked_in_at'].toString()) : null,
      event: json['event'] != null ? Event.fromJson(json['event']) : null,
      tier: json['tier'] != null ? TicketTier.fromJson(json['tier']) : null,
      guestName: json['guest_name']?.toString(),
      guestPhone: json['guest_phone']?.toString(),
    );
  }
}

class TicketPurchaseResult {
  final bool success;
  final String? orderId;
  final List<EventTicket> tickets;
  final double totalPaid;
  final double? discountApplied;
  final String? promoCodeUsed;
  final String? message;

  TicketPurchaseResult({
    required this.success,
    this.orderId,
    this.tickets = const [],
    this.totalPaid = 0,
    this.discountApplied,
    this.promoCodeUsed,
    this.message,
  });

  factory TicketPurchaseResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return TicketPurchaseResult(
      success: json['success'] == true,
      orderId: data['order_id']?.toString(),
      tickets: (data['tickets'] as List?)?.map((e) => EventTicket.fromJson(e)).toList() ?? [],
      totalPaid: _parseDouble(data['total_paid']),
      discountApplied: data['discount_applied'] != null ? _parseDouble(data['discount_applied']) : null,
      promoCodeUsed: data['promo_code_used']?.toString(),
      message: json['message']?.toString(),
    );
  }
}

class CheckInResult {
  final bool success;
  final String? attendeeName;
  final String? tierName;
  final int? guestCount;
  final String? message;
  final bool alreadyCheckedIn;

  CheckInResult({
    required this.success,
    this.attendeeName,
    this.tierName,
    this.guestCount,
    this.message,
    this.alreadyCheckedIn = false,
  });

  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return CheckInResult(
      success: json['success'] == true,
      attendeeName: data['attendee_name']?.toString(),
      tierName: data['tier_name']?.toString(),
      guestCount: data['guest_count'] != null ? _parseInt(data['guest_count']) : null,
      message: json['message']?.toString(),
      alreadyCheckedIn: _parseBool(data['already_checked_in']),
    );
  }
}

class GuestInfo {
  final String name;
  final String? phone;

  GuestInfo({required this.name, this.phone});

  Map<String, dynamic> toJson() => {'name': name, if (phone != null) 'phone': phone};
}
