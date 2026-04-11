// lib/events/models/guest.dart
import '../../config/api_config.dart';

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

double _parseDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

enum GuestCategory {
  vip,
  family,
  regular,
  custom;

  String get displayName {
    switch (this) {
      case GuestCategory.vip: return 'Wageni wa Heshima';
      case GuestCategory.family: return 'Ndugu';
      case GuestCategory.regular: return 'Wageni wa Kawaida';
      case GuestCategory.custom: return 'Maalum';
    }
  }

  String get subtitle {
    switch (this) {
      case GuestCategory.vip: return 'VIP';
      case GuestCategory.family: return 'Family';
      case GuestCategory.regular: return 'Regular';
      case GuestCategory.custom: return 'Custom';
    }
  }

  static GuestCategory fromApi(String? value) {
    switch (value) {
      case 'vip': return GuestCategory.vip;
      case 'family': return GuestCategory.family;
      case 'regular': return GuestCategory.regular;
      case 'custom': return GuestCategory.custom;
      default: return GuestCategory.regular;
    }
  }
}

enum InvitationStatus {
  notSent,
  printed,
  assigned,
  delivered,
  confirmed;

  String get displayName {
    switch (this) {
      case InvitationStatus.notSent: return 'Haijatumwa';
      case InvitationStatus.printed: return 'Imechapishwa';
      case InvitationStatus.assigned: return 'Imepewa Mjumbe';
      case InvitationStatus.delivered: return 'Imefikishwa';
      case InvitationStatus.confirmed: return 'Imethibitishwa';
    }
  }

  String get subtitle {
    switch (this) {
      case InvitationStatus.notSent: return 'Not Sent';
      case InvitationStatus.printed: return 'Printed';
      case InvitationStatus.assigned: return 'Assigned';
      case InvitationStatus.delivered: return 'Delivered';
      case InvitationStatus.confirmed: return 'Confirmed';
    }
  }

  static InvitationStatus fromApi(String? value) {
    switch (value) {
      case 'not_sent': return InvitationStatus.notSent;
      case 'printed': return InvitationStatus.printed;
      case 'assigned': return InvitationStatus.assigned;
      case 'delivered': return InvitationStatus.delivered;
      case 'confirmed': return InvitationStatus.confirmed;
      default: return InvitationStatus.notSent;
    }
  }
}

class EventGuest {
  final int id;
  final int eventId;
  final int? userId;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final GuestCategory category;
  final String? customCategory;
  final String? rsvpStatus;           // going, interested, not_going, null
  final int guestCount;               // +1, +2 etc.
  final InvitationStatus cardStatus;
  final int? cardDeliveredByUserId;   // who delivered the card
  final String? cardDeliveredByName;
  final bool isDigitalInvite;         // WhatsApp/SMS invite instead of physical
  final bool isCheckedIn;
  final DateTime? checkedInAt;
  final String? seatAssignment;       // table/section
  final Gift? gift;                   // bahasha/gift received
  final bool thankYouSent;
  final DateTime createdAt;

  EventGuest({
    required this.id,
    required this.eventId,
    this.userId,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.category = GuestCategory.regular,
    this.customCategory,
    this.rsvpStatus,
    this.guestCount = 0,
    this.cardStatus = InvitationStatus.notSent,
    this.cardDeliveredByUserId,
    this.cardDeliveredByName,
    this.isDigitalInvite = false,
    this.isCheckedIn = false,
    this.checkedInAt,
    this.seatAssignment,
    this.gift,
    this.thankYouSent = false,
    required this.createdAt,
  });

  bool get isGoing => rsvpStatus == 'going';
  bool get hasCard => cardStatus != InvitationStatus.notSent;
  int get totalAttending => 1 + guestCount;

  factory EventGuest.fromJson(Map<String, dynamic> json) {
    final String name;
    if (json['name'] != null) {
      name = json['name'].toString();
    } else if (json['first_name'] != null) {
      name = '${json['first_name']} ${json['last_name'] ?? ''}'.trim();
    } else {
      name = '';
    }

    return EventGuest(
      id: _parseInt(json['id']),
      eventId: _parseInt(json['event_id']),
      userId: json['user_id'] != null ? _parseInt(json['user_id']) : null,
      name: name,
      phone: json['phone']?.toString(),
      avatarUrl: ApiConfig.sanitizeUrl(json['avatar_url']?.toString()),
      category: GuestCategory.fromApi(json['category']?.toString()),
      customCategory: json['custom_category']?.toString(),
      rsvpStatus: json['rsvp_status']?.toString(),
      guestCount: _parseInt(json['guest_count']),
      cardStatus: InvitationStatus.fromApi(json['card_status']?.toString()),
      cardDeliveredByUserId: json['card_delivered_by'] != null ? _parseInt(json['card_delivered_by']) : null,
      cardDeliveredByName: json['card_delivered_by_name']?.toString(),
      isDigitalInvite: _parseBool(json['is_digital_invite']),
      isCheckedIn: _parseBool(json['is_checked_in']),
      checkedInAt: json['checked_in_at'] != null ? DateTime.tryParse(json['checked_in_at'].toString()) : null,
      seatAssignment: json['seat_assignment']?.toString(),
      gift: json['gift'] != null ? Gift.fromJson(json['gift']) : null,
      thankYouSent: _parseBool(json['thank_you_sent']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'event_id': eventId,
    'user_id': userId,
    'name': name,
    'phone': phone,
    'category': category.name,
    'rsvp_status': rsvpStatus,
    'guest_count': guestCount,
    'card_status': cardStatus.name,
    'is_digital_invite': isDigitalInvite,
    'is_checked_in': isCheckedIn,
    'seat_assignment': seatAssignment,
    'thank_you_sent': thankYouSent,
    'created_at': createdAt.toIso8601String(),
  };
}

class Gift {
  final int id;
  final int guestId;
  final String type;          // cash, item
  final double? cashAmount;
  final String? currency;
  final String? itemDescription;
  final DateTime receivedAt;

  Gift({
    required this.id,
    required this.guestId,
    required this.type,
    this.cashAmount,
    this.currency = 'TZS',
    this.itemDescription,
    required this.receivedAt,
  });

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      id: _parseInt(json['id']),
      guestId: _parseInt(json['guest_id']),
      type: json['type']?.toString() ?? 'cash',
      cashAmount: json['cash_amount'] != null ? _parseDouble(json['cash_amount']) : null,
      currency: json['currency']?.toString() ?? 'TZS',
      itemDescription: json['item_description']?.toString(),
      receivedAt: DateTime.tryParse(json['received_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class GuestSummary {
  final int totalInvited;
  final int totalGoing;
  final int totalInterested;
  final int totalNotGoing;
  final int totalNoResponse;
  final int totalCheckedIn;
  final int cardsDelivered;
  final int cardsPending;
  final Map<String, int> byCategory;

  GuestSummary({
    this.totalInvited = 0,
    this.totalGoing = 0,
    this.totalInterested = 0,
    this.totalNotGoing = 0,
    this.totalNoResponse = 0,
    this.totalCheckedIn = 0,
    this.cardsDelivered = 0,
    this.cardsPending = 0,
    this.byCategory = const {},
  });

  int get estimatedAttendance => (totalGoing * 1.3).round(); // 30% buffer for walk-ins

  factory GuestSummary.fromJson(Map<String, dynamic> json) {
    return GuestSummary(
      totalInvited: _parseInt(json['total_invited']),
      totalGoing: _parseInt(json['total_going']),
      totalInterested: _parseInt(json['total_interested']),
      totalNotGoing: _parseInt(json['total_not_going']),
      totalNoResponse: _parseInt(json['total_no_response']),
      totalCheckedIn: _parseInt(json['total_checked_in']),
      cardsDelivered: _parseInt(json['cards_delivered']),
      cardsPending: _parseInt(json['cards_pending']),
      byCategory: (json['by_category'] as Map?)?.map((k, v) => MapEntry(k.toString(), _parseInt(v))) ?? {},
    );
  }
}
