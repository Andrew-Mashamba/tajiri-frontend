enum InquiryKind {
  viewing,
  offer,
  question;

  String get apiValue {
    switch (this) {
      case InquiryKind.viewing: return 'viewing';
      case InquiryKind.offer: return 'offer';
      case InquiryKind.question: return 'question';
    }
  }

  String get label {
    switch (this) {
      case InquiryKind.viewing: return 'Viewing';
      case InquiryKind.offer: return 'Make offer';
      case InquiryKind.question: return 'Ask question';
    }
  }

  String get labelSwahili {
    switch (this) {
      case InquiryKind.viewing: return 'Ona';
      case InquiryKind.offer: return 'Toa bei';
      case InquiryKind.question: return 'Uliza swali';
    }
  }

  static InquiryKind fromString(String? raw) {
    switch (raw) {
      case 'viewing': return InquiryKind.viewing;
      case 'offer': return InquiryKind.offer;
      case 'question': return InquiryKind.question;
      default: return InquiryKind.question;
    }
  }
}

enum InquiryStatus {
  pending,
  acknowledged,
  scheduled,
  viewed,
  offerMade,
  accepted,
  rejected,
  cancelled;

  String get apiValue {
    switch (this) {
      case InquiryStatus.pending: return 'pending';
      case InquiryStatus.acknowledged: return 'acknowledged';
      case InquiryStatus.scheduled: return 'scheduled';
      case InquiryStatus.viewed: return 'viewed';
      case InquiryStatus.offerMade: return 'offer_made';
      case InquiryStatus.accepted: return 'accepted';
      case InquiryStatus.rejected: return 'rejected';
      case InquiryStatus.cancelled: return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case InquiryStatus.pending: return 'Pending';
      case InquiryStatus.acknowledged: return 'Acknowledged';
      case InquiryStatus.scheduled: return 'Viewing scheduled';
      case InquiryStatus.viewed: return 'Viewed';
      case InquiryStatus.offerMade: return 'Offer made';
      case InquiryStatus.accepted: return 'Accepted';
      case InquiryStatus.rejected: return 'Rejected';
      case InquiryStatus.cancelled: return 'Cancelled';
    }
  }

  String get labelSwahili {
    switch (this) {
      case InquiryStatus.pending: return 'Inasubiri';
      case InquiryStatus.acknowledged: return 'Imepokelewa';
      case InquiryStatus.scheduled: return 'Kuonana kumepangwa';
      case InquiryStatus.viewed: return 'Imeonwa';
      case InquiryStatus.offerMade: return 'Bei imetolewa';
      case InquiryStatus.accepted: return 'Imekubaliwa';
      case InquiryStatus.rejected: return 'Imekataliwa';
      case InquiryStatus.cancelled: return 'Imeghairiwa';
    }
  }

  static InquiryStatus fromString(String? raw) {
    switch (raw) {
      case 'pending': return InquiryStatus.pending;
      case 'acknowledged': return InquiryStatus.acknowledged;
      case 'scheduled': return InquiryStatus.scheduled;
      case 'viewed': return InquiryStatus.viewed;
      case 'offer_made': return InquiryStatus.offerMade;
      case 'accepted': return InquiryStatus.accepted;
      case 'rejected': return InquiryStatus.rejected;
      case 'cancelled': return InquiryStatus.cancelled;
      default: return InquiryStatus.pending;
    }
  }
}

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

class ListingInquiry {
  final int id;
  final int listingId;
  final String? listingTitle;
  final int? listingPriceTzs;
  final String? listingKind;

  final int customerUserId;
  final String? customerName;
  final int partnerUserId;
  final String? partnerName;

  final InquiryKind kind;
  final String? message;
  final DateTime? preferredViewingAt;
  final int? offerPriceTzs;
  final int? parentInquiryId;

  final InquiryStatus status;
  final DateTime? acknowledgedAt;
  final DateTime? scheduledAt;
  final DateTime? viewedAt;
  final DateTime? offerMadeAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? cancelledAt;
  final String? rejectionReason;
  final String? cancellationReason;
  final DateTime? commissionRecordedAt;

  /// Spec line 932 — minutes between inquiry creation and the partner's
  /// first reply. Null until the partner responds. Used for "Replied in N min" chip.
  final int? partnerResponseMinutes;
  /// Spec line 941 — pre-qualification soft-asked at inquiry create.
  final String? prequalMoveIn;
  final String? prequalFinancing;
  final bool? prequalWorkingWithAgent;
  final DateTime? prequalCompletedAt;
  /// Spec line 945 — true when this inquiry is an open-house RSVP, not a private tour.
  final bool isOpenHouseRsvp;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  ListingInquiry({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingPriceTzs,
    required this.listingKind,
    required this.customerUserId,
    required this.customerName,
    required this.partnerUserId,
    required this.partnerName,
    required this.kind,
    required this.message,
    required this.preferredViewingAt,
    required this.offerPriceTzs,
    required this.parentInquiryId,
    required this.status,
    required this.acknowledgedAt,
    required this.scheduledAt,
    required this.viewedAt,
    required this.offerMadeAt,
    required this.acceptedAt,
    required this.rejectedAt,
    required this.cancelledAt,
    required this.rejectionReason,
    required this.cancellationReason,
    required this.commissionRecordedAt,
    this.partnerResponseMinutes,
    this.prequalMoveIn,
    this.prequalFinancing,
    this.prequalWorkingWithAgent,
    this.prequalCompletedAt,
    this.isOpenHouseRsvp = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ListingInquiry.fromJson(Map<String, dynamic> json) {
    return ListingInquiry(
      id: _parseIntN(json['id']) ?? 0,
      listingId: _parseIntN(json['listing_id']) ?? 0,
      listingTitle: json['listing_title']?.toString(),
      listingPriceTzs: _parseIntN(json['listing_price_tzs']),
      listingKind: json['listing_kind']?.toString(),
      customerUserId: _parseIntN(json['customer_user_id']) ?? 0,
      customerName: json['customer_name']?.toString(),
      partnerUserId: _parseIntN(json['partner_user_id']) ?? 0,
      partnerName: json['partner_name']?.toString(),
      kind: InquiryKind.fromString(json['kind']?.toString()),
      message: json['message']?.toString(),
      preferredViewingAt: _parseDate(json['preferred_viewing_at']),
      offerPriceTzs: _parseIntN(json['offer_price_tzs']),
      parentInquiryId: _parseIntN(json['parent_inquiry_id']),
      status: InquiryStatus.fromString(json['status']?.toString()),
      acknowledgedAt: _parseDate(json['acknowledged_at']),
      scheduledAt: _parseDate(json['scheduled_at']),
      viewedAt: _parseDate(json['viewed_at']),
      offerMadeAt: _parseDate(json['offer_made_at']),
      acceptedAt: _parseDate(json['accepted_at']),
      rejectedAt: _parseDate(json['rejected_at']),
      cancelledAt: _parseDate(json['cancelled_at']),
      rejectionReason: json['rejection_reason']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
      commissionRecordedAt: _parseDate(json['commission_recorded_at']),
      partnerResponseMinutes: _parseIntN(json['partner_response_minutes']),
      prequalMoveIn: json['prequal_move_in']?.toString(),
      prequalFinancing: json['prequal_financing']?.toString(),
      prequalWorkingWithAgent: json['prequal_working_with_agent'] == null
          ? null
          : (json['prequal_working_with_agent'] == true ||
              json['prequal_working_with_agent'] == 'true' ||
              json['prequal_working_with_agent'] == 1),
      prequalCompletedAt: _parseDate(json['prequal_completed_at']),
      isOpenHouseRsvp: json['is_open_house_rsvp'] == true ||
          json['is_open_house_rsvp'] == 1 ||
          json['is_open_house_rsvp']?.toString() == '1' ||
          json['is_open_house_rsvp']?.toString() == 'true',
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  bool get hasFinalised =>
      status == InquiryStatus.accepted ||
      status == InquiryStatus.rejected ||
      status == InquiryStatus.cancelled;
}

class ListingInquiryResult {
  final bool success;
  final ListingInquiry? inquiry;
  final String? message;
  final int? statusCode;
  ListingInquiryResult({required this.success, this.inquiry, this.message, this.statusCode});
}

class ListingInquiryListResult {
  final bool success;
  final List<ListingInquiry> items;
  final String? message;
  final int? statusCode;
  ListingInquiryListResult({required this.success, this.items = const [], this.message, this.statusCode});
}
