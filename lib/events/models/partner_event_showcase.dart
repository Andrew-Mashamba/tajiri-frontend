/// Spec F10 #88 — partner-uploaded "real event" photo entry. Shown on the
/// customer-facing partner profile rail once `moderation_status='approved'`.
class PartnerEventShowcase {
  final int id;
  final int partnerId;
  final int partnerUserId;
  final int? eventBookingId;
  final List<String> photoUrls;
  final String? caption;
  final String moderationStatus;
  final DateTime? moderatedAt;
  final DateTime? createdAt;

  PartnerEventShowcase({
    required this.id,
    required this.partnerId,
    required this.partnerUserId,
    this.eventBookingId,
    required this.photoUrls,
    this.caption,
    this.moderationStatus = 'approved',
    this.moderatedAt,
    this.createdAt,
  });

  factory PartnerEventShowcase.fromJson(Map<String, dynamic> json) {
    int? p(dynamic v) =>
        v == null ? null : (v is int ? v : int.tryParse(v.toString()));
    DateTime? d(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    final photos = (json['photo_urls'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    return PartnerEventShowcase(
      id: p(json['id']) ?? 0,
      partnerId: p(json['partner_id']) ?? 0,
      partnerUserId: p(json['partner_user_id']) ?? 0,
      eventBookingId: p(json['event_booking_id']),
      photoUrls: photos,
      caption: json['caption']?.toString(),
      moderationStatus: json['moderation_status']?.toString() ?? 'approved',
      moderatedAt: d(json['moderated_at']),
      createdAt: d(json['created_at']),
    );
  }
}
