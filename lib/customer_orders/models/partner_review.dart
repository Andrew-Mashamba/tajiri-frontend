import 'customer_order.dart';

/// Standard tag set per spec line 1063 (positive + negative).
/// Per-source domain-specific tags can be passed as raw strings; this enum
/// covers the cross-cutting set used by every vertical.
enum ReviewTag {
  // Positive
  onTime,
  friendly,
  qualityWork,
  priceFair,
  cleanliness,
  communication,
  goodValue,
  professional,
  // Negative
  late,
  poorQuality,
  overpriced,
  rude,
  miscommunication;

  String get apiValue {
    switch (this) {
      case ReviewTag.onTime: return 'on_time';
      case ReviewTag.friendly: return 'friendly';
      case ReviewTag.qualityWork: return 'quality_work';
      case ReviewTag.priceFair: return 'price_fair';
      case ReviewTag.cleanliness: return 'cleanliness';
      case ReviewTag.communication: return 'communication';
      case ReviewTag.goodValue: return 'good_value';
      case ReviewTag.professional: return 'professional';
      case ReviewTag.late: return 'late';
      case ReviewTag.poorQuality: return 'poor_quality';
      case ReviewTag.overpriced: return 'overpriced';
      case ReviewTag.rude: return 'rude';
      case ReviewTag.miscommunication: return 'miscommunication';
    }
  }

  String get label {
    switch (this) {
      case ReviewTag.onTime: return 'On time';
      case ReviewTag.friendly: return 'Friendly';
      case ReviewTag.qualityWork: return 'Quality work';
      case ReviewTag.priceFair: return 'Price fair';
      case ReviewTag.cleanliness: return 'Cleanliness';
      case ReviewTag.communication: return 'Good communication';
      case ReviewTag.goodValue: return 'Good value';
      case ReviewTag.professional: return 'Professional';
      case ReviewTag.late: return 'Late';
      case ReviewTag.poorQuality: return 'Poor quality';
      case ReviewTag.overpriced: return 'Overpriced';
      case ReviewTag.rude: return 'Rude';
      case ReviewTag.miscommunication: return 'Miscommunication';
    }
  }

  String get labelSwahili {
    switch (this) {
      case ReviewTag.onTime: return 'Kwa wakati';
      case ReviewTag.friendly: return 'Mwenye urafiki';
      case ReviewTag.qualityWork: return 'Kazi nzuri';
      case ReviewTag.priceFair: return 'Bei nzuri';
      case ReviewTag.cleanliness: return 'Usafi';
      case ReviewTag.communication: return 'Mawasiliano mema';
      case ReviewTag.goodValue: return 'Thamani nzuri';
      case ReviewTag.professional: return 'Kitaalamu';
      case ReviewTag.late: return 'Kuchelewa';
      case ReviewTag.poorQuality: return 'Ubora hafifu';
      case ReviewTag.overpriced: return 'Bei juu';
      case ReviewTag.rude: return 'Kutokuwa na heshima';
      case ReviewTag.miscommunication: return 'Mawasiliano mabaya';
    }
  }

  bool get isPositive {
    switch (this) {
      case ReviewTag.late:
      case ReviewTag.poorQuality:
      case ReviewTag.overpriced:
      case ReviewTag.rude:
      case ReviewTag.miscommunication:
        return false;
      case ReviewTag.onTime:
      case ReviewTag.friendly:
      case ReviewTag.qualityWork:
      case ReviewTag.priceFair:
      case ReviewTag.cleanliness:
      case ReviewTag.communication:
      case ReviewTag.goodValue:
      case ReviewTag.professional:
        return true;
    }
  }

  static ReviewTag? fromString(String? raw) {
    if (raw == null) return null;
    for (final t in ReviewTag.values) {
      if (t.apiValue == raw) return t;
    }
    return null;
  }
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

class PartnerReview {
  final int id;
  final CustomerOrderSource source;
  final int sourceId;
  final int partnerUserId;
  final int reviewerUserId;
  final String? reviewerName;
  final int stars;
  final String? comment;
  /// Mix of [ReviewTag.apiValue] and free-form strings.
  final List<String> tags;
  final bool isAnonymous;
  /// Spec line 1099 — per-source aspect dimensions (e.g. quality/timeliness/value).
  /// Map of dimension key → 1-5 star rating. Null when none provided.
  final Map<String, int>? dimensions;
  /// Spec line 1102 — photo+video review attachments. Public URLs.
  final List<String> mediaUrls;
  /// Spec line 1108 — community helpfulness vote aggregates.
  final int helpfulnessYes;
  final int helpfulnessNo;
  /// Spec line 1093 — review came from a customer who actually completed
  /// a booking/order with this partner. Server enforces; UI surfaces a chip.
  final bool isVerifiedBooking;
  /// Spec line 1100 — true when this customer has prior orders with the same partner.
  final bool isReturningCustomer;
  /// Count of customer's prior orders with this partner (signal strength).
  final int priorOrdersCount;
  /// Spec line 1102 — when ≤2 stars, photo proof is required to publish.
  final bool requiresPhotoProof;
  final DateTime? replyWindowExpiresAt;
  final String? partnerReply;
  final DateTime? partnerReplyAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PartnerReview({
    required this.id,
    required this.source,
    required this.sourceId,
    required this.partnerUserId,
    required this.reviewerUserId,
    required this.reviewerName,
    required this.stars,
    required this.comment,
    required this.tags,
    required this.isAnonymous,
    this.dimensions,
    this.mediaUrls = const [],
    this.helpfulnessYes = 0,
    this.helpfulnessNo = 0,
    this.isVerifiedBooking = false,
    this.isReturningCustomer = false,
    this.priorOrdersCount = 0,
    this.requiresPhotoProof = false,
    this.replyWindowExpiresAt,
    required this.partnerReply,
    required this.partnerReplyAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PartnerReview.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    return PartnerReview(
      id: _parseIntN(json['id']) ?? 0,
      source: CustomerOrderSourceX.fromString(json['source']?.toString()),
      sourceId: _parseIntN(json['source_id']) ?? 0,
      partnerUserId: _parseIntN(json['partner_user_id']) ?? 0,
      reviewerUserId: _parseIntN(json['reviewer_user_id']) ?? 0,
      reviewerName: json['reviewer_name']?.toString(),
      stars: _parseIntN(json['stars']) ?? 0,
      comment: json['comment']?.toString(),
      tags: rawTags is List
          ? rawTags.map((e) => e.toString()).toList()
          : const <String>[],
      isAnonymous: _parseBool(json['is_anonymous']),
      dimensions: () {
        final raw = json['dimensions'];
        if (raw is Map) {
          final out = <String, int>{};
          raw.forEach((k, v) {
            final iv = v is int ? v : int.tryParse(v.toString());
            if (iv != null) out[k.toString()] = iv;
          });
          return out.isEmpty ? null : out;
        }
        return null;
      }(),
      mediaUrls: () {
        final raw = json['media_urls'];
        if (raw is List) return raw.map((e) => e.toString()).toList();
        return const <String>[];
      }(),
      helpfulnessYes: _parseIntN(json['helpfulness_yes']) ?? 0,
      helpfulnessNo: _parseIntN(json['helpfulness_no']) ?? 0,
      isVerifiedBooking: _parseBool(json['is_verified_booking']),
      isReturningCustomer: _parseBool(json['is_returning_customer']),
      priorOrdersCount: _parseIntN(json['prior_orders_count']) ?? 0,
      requiresPhotoProof: _parseBool(json['requires_photo_proof']),
      replyWindowExpiresAt: _parseDate(json['reply_window_expires_at']),
      partnerReply: json['partner_reply']?.toString(),
      partnerReplyAt: _parseDate(json['partner_reply_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  bool get canEdit {
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt!).inHours < 24;
  }

  bool get canPartnerReply {
    if (createdAt == null) return false;
    if ((partnerReply ?? '').isNotEmpty) return false;
    return DateTime.now().difference(createdAt!).inDays < 7;
  }

  String get displayedReviewerName {
    if (isAnonymous) return '';
    return reviewerName ?? '';
  }
}

class PartnerReviewAggregate {
  final int count;
  final double avgStars;
  /// Stars (1-5) → count
  final Map<int, int> distribution;

  PartnerReviewAggregate({
    required this.count,
    required this.avgStars,
    required this.distribution,
  });

  factory PartnerReviewAggregate.empty() => PartnerReviewAggregate(
        count: 0,
        avgStars: 0,
        distribution: const {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      );

  factory PartnerReviewAggregate.fromJson(Map<String, dynamic> json) {
    final dist = (json['distribution'] as Map?)?.cast<String, dynamic>() ?? const {};
    final out = <int, int>{};
    for (final k in [1, 2, 3, 4, 5]) {
      out[k] = _parseIntN(dist['$k']) ?? 0;
    }
    return PartnerReviewAggregate(
      count: _parseIntN(json['count']) ?? 0,
      avgStars: _parseDoubleN(json['avg_stars']) ?? 0.0,
      distribution: out,
    );
  }
}

class PartnerReviewResult {
  final bool success;
  final PartnerReview? review;
  final String? message;
  final int? statusCode;
  PartnerReviewResult({required this.success, this.review, this.message, this.statusCode});
}

class PartnerReviewListResult {
  final bool success;
  final List<PartnerReview> items;
  final PartnerReviewAggregate aggregate;
  final String? message;
  final int? statusCode;
  PartnerReviewListResult({
    required this.success,
    this.items = const [],
    required this.aggregate,
    this.message,
    this.statusCode,
  });
}
