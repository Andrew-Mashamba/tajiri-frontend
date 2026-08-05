import 'package:intl/intl.dart';

enum EscrowStatus {
  pending,
  held,
  released,
  refunded,
  autoReleased,
  disputed;

  static EscrowStatus fromString(String value) {
    switch (value) {
      case 'held':
        return EscrowStatus.held;
      case 'released':
        return EscrowStatus.released;
      case 'refunded':
        return EscrowStatus.refunded;
      case 'auto_released':
        return EscrowStatus.autoReleased;
      case 'disputed':
        return EscrowStatus.disputed;
      default:
        return EscrowStatus.pending;
    }
  }
}

class EscrowInfo {
  final EscrowStatus status;
  final DateTime? heldAt;
  final DateTime? autoReleaseAt;
  final DateTime? releasedAt;
  final EscrowDispute? dispute;

  const EscrowInfo({
    required this.status,
    this.heldAt,
    this.autoReleaseAt,
    this.releasedAt,
    this.dispute,
  });

  factory EscrowInfo.fromJson(Map<String, dynamic> json) {
    return EscrowInfo(
      status: EscrowStatus.fromString(json['escrow_status'] as String? ?? ''),
      heldAt: _parseDate(json['escrow_held_at']),
      autoReleaseAt: _parseDate(json['escrow_auto_release_at']),
      releasedAt: _parseDate(json['escrow_released_at']),
      dispute: json['dispute'] != null
          ? EscrowDispute.fromJson(json['dispute'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isHeld => status == EscrowStatus.held;
  bool get isReleased =>
      status == EscrowStatus.released || status == EscrowStatus.autoReleased;
  bool get isDisputed => status == EscrowStatus.disputed;

  int? get autoReleaseDaysLeft {
    if (autoReleaseAt == null) return null;
    final diff = autoReleaseAt!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value as String);
    } catch (_) {
      return null;
    }
  }
}

class EscrowDispute {
  final int id;
  final int? orderId;
  final int? raisedById;
  final String reason;
  final String? description;
  final List<String> evidenceUrls;
  final String status;
  final String? resolutionNotes;
  final String? sellerResponse;
  final DateTime? sellerRespondedAt;
  final String? adminNotes;
  final String priority;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const EscrowDispute({
    required this.id,
    this.orderId,
    this.raisedById,
    required this.reason,
    this.description,
    this.evidenceUrls = const [],
    required this.status,
    this.resolutionNotes,
    this.sellerResponse,
    this.sellerRespondedAt,
    this.adminNotes,
    this.priority = 'normal',
    required this.createdAt,
    this.resolvedAt,
  });

  factory EscrowDispute.fromJson(Map<String, dynamic> json) {
    List<String> parseUrls(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

    return EscrowDispute(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderId: (json['order_id'] as num?)?.toInt(),
      raisedById: (json['raised_by'] as num?)?.toInt(),
      reason: json['reason'] as String? ?? '',
      description: json['description'] as String?,
      evidenceUrls: parseUrls(json['evidence_urls']),
      status: json['status'] as String? ?? 'open',
      resolutionNotes: json['resolution_notes'] as String?,
      sellerResponse: json['seller_response'] as String?,
      sellerRespondedAt:
          _parseDate(json['seller_responded_at']),
      adminNotes: json['admin_notes'] as String?,
      priority: json['priority'] as String? ?? 'normal',
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      resolvedAt: _parseDate(json['resolved_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value as String);
    } catch (_) {
      return null;
    }
  }

  bool get isOpen => status == 'open';
  bool get isUnderReview => status == 'under_review';
  bool get isResolved =>
      status == 'resolved_seller' || status == 'resolved_buyer';
  bool get resolvedInBuyerFavour => status == 'resolved_buyer';
  bool get resolvedInSellerFavour => status == 'resolved_seller';

  String get reasonLabel {
    switch (reason) {
      case 'not_received':
        return 'Item not received';
      case 'not_as_described':
        return 'Item not as described';
      case 'damaged':
        return 'Item arrived damaged';
      default:
        return 'Other';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'under_review':
        return 'Under Review';
      case 'resolved_seller':
        return 'Resolved — Seller';
      case 'resolved_buyer':
        return 'Resolved — Buyer';
      case 'closed':
        return 'Closed';
      default:
        return 'Open';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'high':
        return 'High';
      case 'urgent':
        return 'Urgent';
      default:
        return 'Normal';
    }
  }
}

class EscrowWalletSummary {
  final double heldAmount;
  final int pendingReleaseCount;

  const EscrowWalletSummary({
    required this.heldAmount,
    required this.pendingReleaseCount,
  });

  factory EscrowWalletSummary.fromJson(Map<String, dynamic> json) {
    return EscrowWalletSummary(
      heldAmount: (json['held_amount'] as num?)?.toDouble() ?? 0.0,
      pendingReleaseCount:
          (json['pending_release_count'] as num?)?.toInt() ?? 0,
    );
  }

  String get heldAmountFormatted {
    final formatter = NumberFormat('#,###', 'en_US');
    return 'TZS ${formatter.format(heldAmount.toInt())}';
  }
}
