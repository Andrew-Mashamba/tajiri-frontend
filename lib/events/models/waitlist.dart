// lib/events/models/waitlist.dart
import 'event_enums.dart';

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class WaitlistEntry {
  final int id;
  final int eventId;
  final int userId;
  final int? ticketTierId;
  final int position;
  final DateTime joinedAt;
  final WaitlistStatus status;
  final DateTime? offerExpiresAt;

  WaitlistEntry({
    required this.id,
    required this.eventId,
    required this.userId,
    this.ticketTierId,
    this.position = 0,
    required this.joinedAt,
    this.status = WaitlistStatus.waiting,
    this.offerExpiresAt,
  });

  bool get hasOffer => status == WaitlistStatus.offered && offerExpiresAt != null;
  bool get isOfferExpired => offerExpiresAt != null && DateTime.now().isAfter(offerExpiresAt!);

  factory WaitlistEntry.fromJson(Map<String, dynamic> json) {
    return WaitlistEntry(
      id: _parseInt(json['id']),
      eventId: _parseInt(json['event_id']),
      userId: _parseInt(json['user_id']),
      ticketTierId: json['ticket_tier_id'] != null ? _parseInt(json['ticket_tier_id']) : null,
      position: _parseInt(json['position']),
      joinedAt: DateTime.tryParse(json['joined_at']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
      status: WaitlistStatus.fromApi(json['status']?.toString()),
      offerExpiresAt: json['offer_expires_at'] != null ? DateTime.tryParse(json['offer_expires_at'].toString()) : null,
    );
  }
}
