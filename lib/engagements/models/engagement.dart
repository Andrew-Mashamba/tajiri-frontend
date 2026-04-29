import 'dart:convert';

import 'package:flutter/material.dart';

/// Three contract types per spec line 835. `productized` reuses a partner_product
/// SKU as the engagement deliverable.
enum EngagementContractType {
  hourly,
  retainer,
  fixedPrice,
  productized;

  String get apiValue {
    switch (this) {
      case EngagementContractType.hourly: return 'hourly';
      case EngagementContractType.retainer: return 'retainer';
      case EngagementContractType.fixedPrice: return 'fixed_price';
      case EngagementContractType.productized: return 'productized';
    }
  }

  String get label {
    switch (this) {
      case EngagementContractType.hourly: return 'Hourly';
      case EngagementContractType.retainer: return 'Monthly retainer';
      case EngagementContractType.fixedPrice: return 'Fixed price';
      case EngagementContractType.productized: return 'Productized';
    }
  }

  String get labelSwahili {
    switch (this) {
      case EngagementContractType.hourly: return 'Kwa saa';
      case EngagementContractType.retainer: return 'Mkataba wa mwezi';
      case EngagementContractType.fixedPrice: return 'Bei thabiti';
      case EngagementContractType.productized: return 'Bidhaa';
    }
  }

  IconData get icon {
    switch (this) {
      case EngagementContractType.hourly: return Icons.schedule_rounded;
      case EngagementContractType.retainer: return Icons.repeat_rounded;
      case EngagementContractType.fixedPrice: return Icons.attach_money_rounded;
      case EngagementContractType.productized: return Icons.inventory_2_rounded;
    }
  }

  static EngagementContractType fromString(String? raw) {
    switch (raw) {
      case 'hourly': return EngagementContractType.hourly;
      case 'retainer': return EngagementContractType.retainer;
      case 'fixed_price': return EngagementContractType.fixedPrice;
      case 'productized': return EngagementContractType.productized;
      default: return EngagementContractType.fixedPrice;
    }
  }
}

enum EngagementStatus {
  proposed,
  accepted,
  active,
  paused,
  ended,
  cancelled,
  rejected;

  String get apiValue {
    switch (this) {
      case EngagementStatus.proposed: return 'proposed';
      case EngagementStatus.accepted: return 'accepted';
      case EngagementStatus.active: return 'active';
      case EngagementStatus.paused: return 'paused';
      case EngagementStatus.ended: return 'ended';
      case EngagementStatus.cancelled: return 'cancelled';
      case EngagementStatus.rejected: return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case EngagementStatus.proposed: return 'Proposed';
      case EngagementStatus.accepted: return 'Accepted';
      case EngagementStatus.active: return 'Active';
      case EngagementStatus.paused: return 'Paused';
      case EngagementStatus.ended: return 'Ended';
      case EngagementStatus.cancelled: return 'Cancelled';
      case EngagementStatus.rejected: return 'Rejected';
    }
  }

  String get labelSwahili {
    switch (this) {
      case EngagementStatus.proposed: return 'Imependekezwa';
      case EngagementStatus.accepted: return 'Imekubaliwa';
      case EngagementStatus.active: return 'Inafanyika';
      case EngagementStatus.paused: return 'Imesimama';
      case EngagementStatus.ended: return 'Imeisha';
      case EngagementStatus.cancelled: return 'Imeghairiwa';
      case EngagementStatus.rejected: return 'Imekataliwa';
    }
  }

  static EngagementStatus fromString(String? raw) {
    switch (raw) {
      case 'proposed': return EngagementStatus.proposed;
      case 'accepted': return EngagementStatus.accepted;
      case 'active': return EngagementStatus.active;
      case 'paused': return EngagementStatus.paused;
      case 'ended': return EngagementStatus.ended;
      case 'cancelled': return EngagementStatus.cancelled;
      case 'rejected': return EngagementStatus.rejected;
      default: return EngagementStatus.proposed;
    }
  }
}

enum MilestoneStatus {
  pending,
  funded,
  submitted,
  approved,
  released,
  disputed;

  String get apiValue {
    switch (this) {
      case MilestoneStatus.pending: return 'pending';
      case MilestoneStatus.funded: return 'funded';
      case MilestoneStatus.submitted: return 'submitted';
      case MilestoneStatus.approved: return 'approved';
      case MilestoneStatus.released: return 'released';
      case MilestoneStatus.disputed: return 'disputed';
    }
  }

  String get label {
    switch (this) {
      case MilestoneStatus.pending: return 'Pending';
      case MilestoneStatus.funded: return 'Funded';
      case MilestoneStatus.submitted: return 'Submitted';
      case MilestoneStatus.approved: return 'Approved';
      case MilestoneStatus.released: return 'Released';
      case MilestoneStatus.disputed: return 'Disputed';
    }
  }

  String get labelSwahili {
    switch (this) {
      case MilestoneStatus.pending: return 'Inasubiri';
      case MilestoneStatus.funded: return 'Imefadhiliwa';
      case MilestoneStatus.submitted: return 'Imewasilishwa';
      case MilestoneStatus.approved: return 'Imekubaliwa';
      case MilestoneStatus.released: return 'Imelipwa';
      case MilestoneStatus.disputed: return 'Imepingwa';
    }
  }

  static MilestoneStatus fromString(String? raw) {
    switch (raw) {
      case 'pending': return MilestoneStatus.pending;
      case 'funded': return MilestoneStatus.funded;
      case 'submitted': return MilestoneStatus.submitted;
      case 'approved': return MilestoneStatus.approved;
      case 'released': return MilestoneStatus.released;
      case 'disputed': return MilestoneStatus.disputed;
      default: return MilestoneStatus.pending;
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

Map<String, dynamic>? _parseAmendment(dynamic v) {
  if (v == null) return null;
  if (v is Map) return v.cast<String, dynamic>();
  if (v is String && v.isNotEmpty) {
    try {
      final decoded = jsonDecode(v);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {}
  }
  return null;
}

class EngagementMilestone {
  final int id;
  final int engagementId;
  final String title;
  final DateTime? dueDate;
  final int amountTzs;
  final MilestoneStatus status;
  final String? deliverableNote;
  final String? deliverableUrl;
  final DateTime? fundedAt;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? releasedAt;
  final DateTime? disputedAt;
  final String? disputeReason;
  final int sortOrder;

  EngagementMilestone({
    required this.id,
    required this.engagementId,
    required this.title,
    required this.dueDate,
    required this.amountTzs,
    required this.status,
    required this.deliverableNote,
    required this.deliverableUrl,
    required this.fundedAt,
    required this.submittedAt,
    required this.approvedAt,
    required this.releasedAt,
    required this.disputedAt,
    required this.disputeReason,
    required this.sortOrder,
  });

  factory EngagementMilestone.fromJson(Map<String, dynamic> json) {
    return EngagementMilestone(
      id: _parseIntN(json['id']) ?? 0,
      engagementId: _parseIntN(json['engagement_id']) ?? 0,
      title: json['title']?.toString() ?? '',
      dueDate: _parseDate(json['due_date']),
      amountTzs: _parseIntN(json['amount_tzs']) ?? 0,
      status: MilestoneStatus.fromString(json['status']?.toString()),
      deliverableNote: json['deliverable_note']?.toString(),
      deliverableUrl: json['deliverable_url']?.toString(),
      fundedAt: _parseDate(json['funded_at']),
      submittedAt: _parseDate(json['submitted_at']),
      approvedAt: _parseDate(json['approved_at']),
      releasedAt: _parseDate(json['released_at']),
      disputedAt: _parseDate(json['disputed_at']),
      disputeReason: json['dispute_reason']?.toString(),
      sortOrder: _parseIntN(json['sort_order']) ?? 0,
    );
  }
}

class EngagementTimeEntry {
  final int id;
  final int engagementId;
  final int partnerUserId;
  final DateTime entryDate;
  final int minutes;
  final String? description;
  final bool billable;
  final int? billedInvoiceId;
  final DateTime? createdAt;

  EngagementTimeEntry({
    required this.id,
    required this.engagementId,
    required this.partnerUserId,
    required this.entryDate,
    required this.minutes,
    required this.description,
    required this.billable,
    required this.billedInvoiceId,
    required this.createdAt,
  });

  factory EngagementTimeEntry.fromJson(Map<String, dynamic> json) {
    return EngagementTimeEntry(
      id: _parseIntN(json['id']) ?? 0,
      engagementId: _parseIntN(json['engagement_id']) ?? 0,
      partnerUserId: _parseIntN(json['partner_user_id']) ?? 0,
      entryDate: _parseDate(json['entry_date']) ?? DateTime.now(),
      minutes: _parseIntN(json['minutes']) ?? 0,
      description: json['description']?.toString(),
      billable: _parseBool(json['billable']),
      billedInvoiceId: _parseIntN(json['billed_invoice_id']),
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class Engagement {
  final int id;
  final int customerUserId;
  final String? customerName;
  final String? customerPhotoUrl;
  final String? customerPhone;
  final int partnerUserId;
  final int? partnerId;
  final String? partnerName;
  final String? partnerPhotoUrl;

  final String? skillCategory;
  final String title;
  final String scopeBrief;
  final EngagementContractType contractType;
  final int? hourlyRateTzs;
  final int? retainerTzs;
  final int? fixedTotalTzs;
  final int? partnerProductId;

  final DateTime startDate;
  final DateTime? endDate;
  final bool ndaRequired;

  final EngagementStatus status;
  final DateTime? proposedAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final DateTime? endedAt;
  final DateTime? cancelledAt;
  final String? rejectionReason;
  final String? cancellationReason;
  final int counterRound;

  final List<EngagementMilestone> milestones;
  final int totalBilledMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Amendment workflow (spec line 791). Non-null when an amendment is awaiting
  /// the other party's approval. Both customer + partner must approve before it
  /// applies to the engagement row.
  final Map<String, dynamic>? pendingAmendment;
  final int? amendmentProposedBy;
  final DateTime? amendmentCustomerApprovedAt;
  final DateTime? amendmentPartnerApprovedAt;

  /// Spec line 798 — partner-side referral/lead-gen credit applied to this
  /// engagement. Reduces the customer's payable amount by this many TZS.
  final int? leadCreditTzs;
  /// Spec line 805 — flagged as retainer subscription with monthly hour bucket.
  final bool isRetainer;
  final int? retainerHoursPerMonth;
  final bool retainerRollsOver;
  /// Spec line 813 — dispute mediation window state.
  final DateTime? disputeWindowStartedAt;
  final DateTime? disputeEscalatedAt;

  Engagement({
    required this.id,
    required this.customerUserId,
    required this.customerName,
    required this.customerPhotoUrl,
    required this.customerPhone,
    required this.partnerUserId,
    required this.partnerId,
    required this.partnerName,
    required this.partnerPhotoUrl,
    required this.skillCategory,
    required this.title,
    required this.scopeBrief,
    required this.contractType,
    required this.hourlyRateTzs,
    required this.retainerTzs,
    required this.fixedTotalTzs,
    required this.partnerProductId,
    required this.startDate,
    required this.endDate,
    required this.ndaRequired,
    required this.status,
    required this.proposedAt,
    required this.acceptedAt,
    required this.rejectedAt,
    required this.startedAt,
    required this.pausedAt,
    required this.endedAt,
    required this.cancelledAt,
    required this.rejectionReason,
    required this.cancellationReason,
    required this.counterRound,
    required this.milestones,
    required this.totalBilledMinutes,
    required this.createdAt,
    required this.updatedAt,
    this.pendingAmendment,
    this.amendmentProposedBy,
    this.amendmentCustomerApprovedAt,
    this.amendmentPartnerApprovedAt,
    this.leadCreditTzs,
    this.isRetainer = false,
    this.retainerHoursPerMonth,
    this.retainerRollsOver = false,
    this.disputeWindowStartedAt,
    this.disputeEscalatedAt,
  });

  /// True when this engagement has an amendment awaiting both-party approval.
  bool get hasPendingAmendment => pendingAmendment != null;

  /// True when [userId] is the side that still needs to act on the pending
  /// amendment (proposer can't approve their own per backend contract).
  bool isAmendmentApprovableBy(int userId) {
    if (!hasPendingAmendment) return false;
    if (amendmentProposedBy == userId) return false;
    final isCustomer = customerUserId == userId;
    final isPartner  = partnerUserId == userId;
    if (!isCustomer && !isPartner) return false;
    return isCustomer
        ? amendmentCustomerApprovedAt == null
        : amendmentPartnerApprovedAt == null;
  }

  factory Engagement.fromJson(Map<String, dynamic> json) {
    final ms = (json['milestones'] as List?)
            ?.whereType<Map>()
            .map((m) => EngagementMilestone.fromJson(m.cast<String, dynamic>()))
            .toList() ??
        const <EngagementMilestone>[];
    return Engagement(
      id: _parseIntN(json['id']) ?? 0,
      customerUserId: _parseIntN(json['customer_user_id']) ?? 0,
      customerName: json['customer_name']?.toString(),
      customerPhotoUrl: json['customer_photo_url']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      partnerUserId: _parseIntN(json['partner_user_id']) ?? 0,
      partnerId: _parseIntN(json['partner_id']),
      partnerName: json['partner_name']?.toString(),
      partnerPhotoUrl: json['partner_photo_url']?.toString(),
      skillCategory: json['skill_category']?.toString(),
      title: json['title']?.toString() ?? '',
      scopeBrief: json['scope_brief']?.toString() ?? '',
      contractType: EngagementContractType.fromString(json['contract_type']?.toString()),
      hourlyRateTzs: _parseIntN(json['hourly_rate_tzs']),
      retainerTzs: _parseIntN(json['retainer_tzs']),
      fixedTotalTzs: _parseIntN(json['fixed_total_tzs']),
      partnerProductId: _parseIntN(json['partner_product_id']),
      startDate: _parseDate(json['start_date']) ?? DateTime.now(),
      endDate: _parseDate(json['end_date']),
      ndaRequired: _parseBool(json['nda_required']),
      status: EngagementStatus.fromString(json['status']?.toString()),
      proposedAt: _parseDate(json['proposed_at']),
      acceptedAt: _parseDate(json['accepted_at']),
      rejectedAt: _parseDate(json['rejected_at']),
      startedAt: _parseDate(json['started_at']),
      pausedAt: _parseDate(json['paused_at']),
      endedAt: _parseDate(json['ended_at']),
      cancelledAt: _parseDate(json['cancelled_at']),
      rejectionReason: json['rejection_reason']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
      counterRound: _parseIntN(json['counter_round']) ?? 0,
      milestones: ms,
      totalBilledMinutes: _parseIntN(json['total_billed_minutes']) ?? 0,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      pendingAmendment: _parseAmendment(json['pending_amendment']),
      amendmentProposedBy: _parseIntN(json['amendment_proposed_by']),
      amendmentCustomerApprovedAt: _parseDate(json['amendment_customer_approved_at']),
      amendmentPartnerApprovedAt: _parseDate(json['amendment_partner_approved_at']),
      leadCreditTzs: _parseIntN(json['lead_credit_tzs']),
      isRetainer: _parseBool(json['is_retainer']),
      retainerHoursPerMonth: _parseIntN(json['retainer_hours_per_month']),
      retainerRollsOver: _parseBool(json['retainer_rolls_over']),
      disputeWindowStartedAt: _parseDate(json['dispute_window_started_at']),
      disputeEscalatedAt: _parseDate(json['dispute_escalated_at']),
    );
  }

  /// Total fee snapshot for headline display:
  /// - hourly: rate × billable hours (current snapshot)
  /// - retainer: monthly amount
  /// - fixed_price: sum of milestone amounts (or fixed_total fallback)
  int get totalEffectiveTzs {
    switch (contractType) {
      case EngagementContractType.hourly:
        return ((hourlyRateTzs ?? 0) * totalBilledMinutes / 60).round();
      case EngagementContractType.retainer:
        return retainerTzs ?? 0;
      case EngagementContractType.fixedPrice:
        if (milestones.isNotEmpty) {
          return milestones.fold<int>(0, (s, m) => s + m.amountTzs);
        }
        return fixedTotalTzs ?? 0;
      case EngagementContractType.productized:
        return fixedTotalTzs ?? 0;
    }
  }

  bool get hasFinalised =>
      status == EngagementStatus.ended ||
      status == EngagementStatus.cancelled ||
      status == EngagementStatus.rejected;

  bool get isWorkspaceOpen =>
      status == EngagementStatus.active || status == EngagementStatus.paused;

  bool get isCancellableByEither =>
      status == EngagementStatus.proposed ||
      status == EngagementStatus.accepted ||
      status == EngagementStatus.active ||
      status == EngagementStatus.paused;
}

class EngagementResult {
  final bool success;
  final Engagement? engagement;
  final String? message;
  final int? statusCode;
  EngagementResult({required this.success, this.engagement, this.message, this.statusCode});
}

class EngagementListResult {
  final bool success;
  final List<Engagement> items;
  final String? message;
  final int? statusCode;
  EngagementListResult({required this.success, this.items = const [], this.message, this.statusCode});
}

class MilestoneResult {
  final bool success;
  final EngagementMilestone? milestone;
  final String? message;
  final int? statusCode;
  MilestoneResult({required this.success, this.milestone, this.message, this.statusCode});
}

class TimeEntryResult {
  final bool success;
  final EngagementTimeEntry? entry;
  final String? message;
  final int? statusCode;
  TimeEntryResult({required this.success, this.entry, this.message, this.statusCode});
}

class TimeEntryListResult {
  final bool success;
  final List<EngagementTimeEntry> items;
  final String? message;
  final int? statusCode;
  TimeEntryListResult({required this.success, this.items = const [], this.message, this.statusCode});
}
