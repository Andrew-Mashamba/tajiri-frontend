/// VICOBA Voting System - Data Models
///
/// Models for the unified voting system supporting all 10 voteable types.

/// Voteable types supported by the system
class VoteableType {
  static const String membershipRequest = 'membership_request';
  static const String membershipRemoval = 'membership_removal';
  static const String loanApplication = 'loan_application';
  static const String akibaWithdrawal = 'akiba_withdrawal';
  static const String expenseRequest = 'expense_request';
  static const String fineApproval = 'fine_approval';
  static const String mchango = 'mchango';
  static const String proxyMchango = 'proxy_mchango';
  static const String katibaChange = 'katiba_change';
  static const String votingCase = 'voting_case';

  /// Get display name in Swahili
  static String getDisplayName(String type) {
    switch (type) {
      case membershipRequest:
        return 'Ombi la Uanachama';
      case membershipRemoval:
        return 'Kufuta Uanachama';
      case loanApplication:
        return 'Ombi la Mkopo';
      case akibaWithdrawal:
        return 'Kutoa Akiba';
      case expenseRequest:
        return 'Ombi la Matumizi';
      case fineApproval:
        return 'Idhini ya Faini';
      case mchango:
        return 'Mchango';
      case proxyMchango:
        return 'Mchango Kwa Niaba';
      case katibaChange:
        return 'Mabadiliko ya Katiba';
      case votingCase:
        return 'Kura ya Kawaida';
      default:
        return type;
    }
  }

  /// Get icon name for the voteable type
  static String getIconName(String type) {
    switch (type) {
      case membershipRequest:
        return 'person_add';
      case membershipRemoval:
        return 'person_remove';
      case loanApplication:
        return 'account_balance';
      case akibaWithdrawal:
        return 'savings';
      case expenseRequest:
        return 'receipt_long';
      case fineApproval:
        return 'gavel';
      case mchango:
        return 'volunteer_activism';
      case proxyMchango:
        return 'group_add';
      case katibaChange:
        return 'description';
      case votingCase:
        return 'how_to_vote';
      default:
        return 'how_to_vote';
    }
  }
}

/// Vote values
class VoteValue {
  static const String yes = 'yes';
  static const String no = 'no';
  static const String abstain = 'abstain';

  /// Get display name in Swahili
  static String getDisplayName(String vote) {
    switch (vote) {
      case yes:
        return 'Nakubali';
      case no:
        return 'Nakataa';
      case abstain:
        return 'Sitaki Kujua';
      default:
        return vote;
    }
  }
}

/// Status values for voteable items
class VotingStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String cancelled = 'cancelled';
  static const String expired = 'expired';

  /// Get display name in Swahili
  static String getDisplayName(String status) {
    switch (status) {
      case pending:
        return 'Inasubiri';
      case approved:
        return 'Imekubaliwa';
      case rejected:
        return 'Imekataliwa';
      case cancelled:
        return 'Imefutwa';
      case expired:
        return 'Imekwisha Muda';
      default:
        return status;
    }
  }
}

/// Standard API response wrapper
class VotingResponse {
  final bool success;
  final bool error;
  final String code;
  final String message;
  final dynamic data;
  final PaginationInfo? pagination;

  VotingResponse({
    required this.success,
    required this.error,
    required this.code,
    required this.message,
    this.data,
    this.pagination,
  });

  factory VotingResponse.fromJson(Map<String, dynamic> json) {
    return VotingResponse(
      success: json['success'] ?? false,
      error: json['error'] ?? true,
      code: json['code']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: json['data'],
      pagination: json['pagination'] != null
          ? PaginationInfo.fromJson(json['pagination'])
          : null,
    );
  }

  bool get isSuccess => success && !error;
}

/// Pagination info for list responses
class PaginationInfo {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationInfo({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      total: json['total'] ?? 0,
    );
  }

  bool get hasMorePages => currentPage < lastPage;
}

/// Voting summary for a voteable item
class VotingSummary {
  final int yesCount;
  final int noCount;
  final int abstainCount;
  final int totalVotes;
  final double weightedYes;
  final double weightedNo;
  final double approvalPercentage;
  final double rejectionPercentage;
  final bool hasMinimumVotes;
  final bool hasReachedApproval;
  final bool hasReachedRejection;

  VotingSummary({
    required this.yesCount,
    required this.noCount,
    required this.abstainCount,
    required this.totalVotes,
    required this.weightedYes,
    required this.weightedNo,
    required this.approvalPercentage,
    required this.rejectionPercentage,
    required this.hasMinimumVotes,
    required this.hasReachedApproval,
    required this.hasReachedRejection,
  });

  factory VotingSummary.fromJson(Map<String, dynamic> json) {
    return VotingSummary(
      yesCount: json['yes_count'] ?? 0,
      noCount: json['no_count'] ?? 0,
      abstainCount: json['abstain_count'] ?? 0,
      totalVotes: json['total_votes'] ?? 0,
      weightedYes: (json['weighted_yes'] ?? 0).toDouble(),
      weightedNo: (json['weighted_no'] ?? 0).toDouble(),
      approvalPercentage: (json['approval_percentage'] ?? 0).toDouble(),
      rejectionPercentage: (json['rejection_percentage'] ?? 0).toDouble(),
      hasMinimumVotes: json['has_minimum_votes'] ?? false,
      hasReachedApproval: json['has_reached_approval'] ?? false,
      hasReachedRejection: json['has_reached_rejection'] ?? false,
    );
  }

  factory VotingSummary.empty() {
    return VotingSummary(
      yesCount: 0,
      noCount: 0,
      abstainCount: 0,
      totalVotes: 0,
      weightedYes: 0,
      weightedNo: 0,
      approvalPercentage: 0,
      rejectionPercentage: 0,
      hasMinimumVotes: false,
      hasReachedApproval: false,
      hasReachedRejection: false,
    );
  }
}

/// A pending voteable item
class PendingItem {
  final int id;
  final String voteableType;
  final String title;
  final String description;
  final String status;
  final String requesterId;
  final String requesterName;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final VotingSummary votingSummary;
  final String? userVote;
  final Map<String, dynamic> details;

  PendingItem({
    required this.id,
    required this.voteableType,
    required this.title,
    required this.description,
    required this.status,
    required this.requesterId,
    required this.requesterName,
    required this.createdAt,
    this.expiresAt,
    required this.votingSummary,
    this.userVote,
    required this.details,
  });

  factory PendingItem.fromJson(Map<String, dynamic> json) {
    return PendingItem(
      id: json['id'] ?? 0,
      voteableType: json['voteable_type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? VotingStatus.pending,
      requesterId: json['requester_id']?.toString() ?? json['requested_by']?.toString() ?? '',
      requesterName: json['requester_name']?.toString() ?? json['requester']?['name']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      votingSummary: json['voting_summary'] != null
          ? VotingSummary.fromJson(json['voting_summary'])
          : VotingSummary.empty(),
      userVote: json['user_vote']?.toString(),
      details: json['details'] ?? json,
    );
  }

  bool get isPending => status == VotingStatus.pending;
  bool get isApproved => status == VotingStatus.approved;
  bool get isRejected => status == VotingStatus.rejected;
  bool get hasUserVoted => userVote != null;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  String get displayType => VoteableType.getDisplayName(voteableType);
}

/// Individual vote record
class VoteRecord {
  final int id;
  final String visitorId;
  final String voterName;
  final String vote;
  final double weight;
  final String? comment;
  final DateTime votedAt;

  VoteRecord({
    required this.id,
    required this.visitorId,
    required this.voterName,
    required this.vote,
    required this.weight,
    this.comment,
    required this.votedAt,
  });

  factory VoteRecord.fromJson(Map<String, dynamic> json) {
    return VoteRecord(
      id: json['id'] ?? 0,
      visitorId: json['voter_id']?.toString() ?? '',
      voterName: json['voter_name']?.toString() ?? json['voter']?['name']?.toString() ?? '',
      vote: json['vote']?.toString() ?? '',
      weight: (json['weight'] ?? 1.0).toDouble(),
      comment: json['comment']?.toString(),
      votedAt: json['voted_at'] != null
          ? DateTime.tryParse(json['voted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get displayVote => VoteValue.getDisplayName(vote);
}

/// Voting configuration for a kikoba
class VotingConfig {
  final String kikobaId;
  final double approvalThreshold;
  final double rejectionThreshold;
  final int minimumVotes;
  final int leadershipWeight;
  final bool autoProcess;
  final Map<String, VoteableConfig> voteableConfigs;

  VotingConfig({
    required this.kikobaId,
    required this.approvalThreshold,
    required this.rejectionThreshold,
    required this.minimumVotes,
    required this.leadershipWeight,
    required this.autoProcess,
    required this.voteableConfigs,
  });

  factory VotingConfig.fromJson(Map<String, dynamic> json) {
    Map<String, VoteableConfig> configs = {};
    if (json['voteable_configs'] != null && json['voteable_configs'] is Map) {
      (json['voteable_configs'] as Map).forEach((key, value) {
        if (value is Map<String, dynamic>) {
          configs[key.toString()] = VoteableConfig.fromJson(value);
        }
      });
    }

    return VotingConfig(
      kikobaId: json['kikoba_id']?.toString() ?? '',
      approvalThreshold: (json['approval_threshold'] ?? 50).toDouble(),
      rejectionThreshold: (json['rejection_threshold'] ?? 50).toDouble(),
      minimumVotes: json['minimum_votes'] ?? 3,
      leadershipWeight: json['leadership_weight'] ?? 2,
      autoProcess: json['auto_process'] ?? true,
      voteableConfigs: configs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kikoba_id': kikobaId,
      'approval_threshold': approvalThreshold,
      'rejection_threshold': rejectionThreshold,
      'minimum_votes': minimumVotes,
      'leadership_weight': leadershipWeight,
      'auto_process': autoProcess,
    };
  }
}

/// Configuration for a specific voteable type
class VoteableConfig {
  final bool enabled;
  final double? approvalThreshold;
  final int? minimumVotes;
  final int? expirationDays;

  VoteableConfig({
    required this.enabled,
    this.approvalThreshold,
    this.minimumVotes,
    this.expirationDays,
  });

  factory VoteableConfig.fromJson(Map<String, dynamic> json) {
    return VoteableConfig(
      enabled: json['enabled'] ?? true,
      approvalThreshold: json['approval_threshold']?.toDouble(),
      minimumVotes: json['minimum_votes'],
      expirationDays: json['expiration_days'],
    );
  }
}

/// Katiba change request model
class KatibaChangeRequest {
  final String id;
  final String kikobaId;
  final String requestedBy;
  final String requesterName;
  final String changeType;
  final Map<String, dynamic> currentValue;
  final Map<String, dynamic> proposedValue;
  final String reason;
  final String status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final VotingSummary? votingSummary;

  KatibaChangeRequest({
    required this.id,
    required this.kikobaId,
    required this.requestedBy,
    required this.requesterName,
    required this.changeType,
    required this.currentValue,
    required this.proposedValue,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.rejectedAt,
    this.votingSummary,
  });

  factory KatibaChangeRequest.fromJson(Map<String, dynamic> json) {
    return KatibaChangeRequest(
      id: json['id']?.toString() ?? json['request_id']?.toString() ?? '',
      kikobaId: json['kikoba_id']?.toString() ?? '',
      requestedBy: json['requested_by']?.toString() ?? '',
      requesterName: json['requester_name']?.toString() ?? json['requester']?['name']?.toString() ?? '',
      changeType: json['change_type']?.toString() ?? '',
      currentValue: json['current_value'] is Map ? Map<String, dynamic>.from(json['current_value']) : {},
      proposedValue: json['proposed_value'] is Map ? Map<String, dynamic>.from(json['proposed_value']) : {},
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? VotingStatus.pending,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'].toString())
          : null,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.tryParse(json['rejected_at'].toString())
          : null,
      votingSummary: json['voting_summary'] != null
          ? VotingSummary.fromJson(json['voting_summary'])
          : null,
    );
  }

  bool get isPending => status == VotingStatus.pending;
  bool get isApproved => status == VotingStatus.approved;
  bool get isRejected => status == VotingStatus.rejected;

  String get changeTypeDisplay {
    switch (changeType) {
      case 'kiingilio':
        return 'Kiingilio';
      case 'ada':
        return 'Ada';
      case 'hisa':
        return 'Hisa';
      case 'akiba':
        return 'Akiba';
      case 'riba':
        return 'Riba';
      case 'faini_vikao':
        return 'Faini ya Vikao';
      case 'faini_ada':
        return 'Faini ya Ada';
      case 'faini_hisa':
        return 'Faini ya Hisa';
      case 'faini_michango':
        return 'Faini ya Michango';
      case 'loan_product_create':
        return 'Bidhaa Mpya ya Mkopo';
      case 'loan_product_update':
        return 'Kubadili Bidhaa ya Mkopo';
      case 'loan_limits':
        return 'Mipaka ya Mkopo';
      case 'meeting_config':
        return 'Usanidi wa Vikao';
      default:
        return changeType;
    }
  }
}

/// Membership removal request model
class MembershipRemovalRequest {
  final String id;
  final String kikobaId;
  final String requesterId;
  final String requesterName;
  final String targetMemberId;
  final String targetMemberName;
  final String removalType;
  final String reason;
  final String status;
  final DateTime createdAt;
  final VotingSummary? votingSummary;

  MembershipRemovalRequest({
    required this.id,
    required this.kikobaId,
    required this.requesterId,
    required this.requesterName,
    required this.targetMemberId,
    required this.targetMemberName,
    required this.removalType,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.votingSummary,
  });

  factory MembershipRemovalRequest.fromJson(Map<String, dynamic> json) {
    return MembershipRemovalRequest(
      id: json['id']?.toString() ?? json['request_id']?.toString() ?? '',
      kikobaId: json['kikoba_id']?.toString() ?? '',
      requesterId: json['requester_id']?.toString() ?? '',
      requesterName: json['requester_name']?.toString() ?? '',
      targetMemberId: json['target_member_id']?.toString() ?? '',
      targetMemberName: json['target_member_name']?.toString() ?? json['target_member']?['name']?.toString() ?? '',
      removalType: json['removal_type']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? VotingStatus.pending,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      votingSummary: json['voting_summary'] != null
          ? VotingSummary.fromJson(json['voting_summary'])
          : null,
    );
  }

  String get removalTypeDisplay {
    switch (removalType) {
      case 'voluntary':
        return 'Kujiondoa';
      case 'disciplinary':
        return 'Kinidhamu';
      case 'inactivity':
        return 'Kutoshiriki';
      case 'death':
        return 'Msiba';
      default:
        return removalType;
    }
  }
}

/// Expense request model
class ExpenseRequest {
  final String id;
  final String kikobaId;
  final String requesterId;
  final String requesterName;
  final double amount;
  final String category;
  final String description;
  final String status;
  final bool isPaid;
  final DateTime createdAt;
  final DateTime? paidAt;
  final VotingSummary? votingSummary;

  ExpenseRequest({
    required this.id,
    required this.kikobaId,
    required this.requesterId,
    required this.requesterName,
    required this.amount,
    required this.category,
    required this.description,
    required this.status,
    required this.isPaid,
    required this.createdAt,
    this.paidAt,
    this.votingSummary,
  });

  factory ExpenseRequest.fromJson(Map<String, dynamic> json) {
    return ExpenseRequest(
      id: json['id']?.toString() ?? json['request_id']?.toString() ?? '',
      kikobaId: json['kikoba_id']?.toString() ?? '',
      requesterId: json['requester_id']?.toString() ?? '',
      requesterName: json['requester_name']?.toString() ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? VotingStatus.pending,
      isPaid: json['is_paid'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'].toString())
          : null,
      votingSummary: json['voting_summary'] != null
          ? VotingSummary.fromJson(json['voting_summary'])
          : null,
    );
  }
}

/// Fine approval request model
class FineApprovalRequest {
  final String id;
  final String kikobaId;
  final String requesterId;
  final String memberId;
  final String memberName;
  final String fineType;
  final double amount;
  final String reason;
  final String status;
  final bool isPaid;
  final bool isWaived;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? waivedAt;
  final VotingSummary? votingSummary;

  FineApprovalRequest({
    required this.id,
    required this.kikobaId,
    required this.requesterId,
    required this.memberId,
    required this.memberName,
    required this.fineType,
    required this.amount,
    required this.reason,
    required this.status,
    required this.isPaid,
    required this.isWaived,
    required this.createdAt,
    this.paidAt,
    this.waivedAt,
    this.votingSummary,
  });

  factory FineApprovalRequest.fromJson(Map<String, dynamic> json) {
    return FineApprovalRequest(
      id: json['id']?.toString() ?? json['request_id']?.toString() ?? '',
      kikobaId: json['kikoba_id']?.toString() ?? '',
      requesterId: json['requester_id']?.toString() ?? '',
      memberId: json['member_id']?.toString() ?? '',
      memberName: json['member_name']?.toString() ?? json['member']?['name']?.toString() ?? '',
      fineType: json['fine_type']?.toString() ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? VotingStatus.pending,
      isPaid: json['is_paid'] ?? false,
      isWaived: json['is_waived'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'].toString())
          : null,
      waivedAt: json['waived_at'] != null
          ? DateTime.tryParse(json['waived_at'].toString())
          : null,
      votingSummary: json['voting_summary'] != null
          ? VotingSummary.fromJson(json['voting_summary'])
          : null,
    );
  }

  String get fineTypeDisplay {
    switch (fineType) {
      case 'vikao':
        return 'Faini ya Vikao';
      case 'ada':
        return 'Faini ya Ada';
      case 'hisa':
        return 'Faini ya Hisa';
      case 'michango':
        return 'Faini ya Michango';
      default:
        return fineType;
    }
  }
}

/// Proxy mchango request model
class ProxyMchangoRequest {
  final String id;
  final String kikobaId;
  final String requesterId;
  final String requesterName;
  final String beneficiaryId;
  final String beneficiaryName;
  final double amount;
  final String mchangoType;
  final String reason;
  final String status;
  final DateTime createdAt;
  final VotingSummary? votingSummary;

  ProxyMchangoRequest({
    required this.id,
    required this.kikobaId,
    required this.requesterId,
    required this.requesterName,
    required this.beneficiaryId,
    required this.beneficiaryName,
    required this.amount,
    required this.mchangoType,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.votingSummary,
  });

  factory ProxyMchangoRequest.fromJson(Map<String, dynamic> json) {
    return ProxyMchangoRequest(
      id: json['id']?.toString() ?? json['request_id']?.toString() ?? '',
      kikobaId: json['kikoba_id']?.toString() ?? '',
      requesterId: json['requester_id']?.toString() ?? '',
      requesterName: json['requester_name']?.toString() ?? '',
      beneficiaryId: json['beneficiary_id']?.toString() ?? '',
      beneficiaryName: json['beneficiary_name']?.toString() ?? json['beneficiary']?['name']?.toString() ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      mchangoType: json['mchango_type']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? VotingStatus.pending,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      votingSummary: json['voting_summary'] != null
          ? VotingSummary.fromJson(json['voting_summary'])
          : null,
    );
  }
}

/// Cast vote result
class CastVoteResult {
  final int voteId;
  final String vote;
  final double weight;
  final VotingSummary votingSummary;
  final bool autoProcessed;
  final String? autoResult;

  CastVoteResult({
    required this.voteId,
    required this.vote,
    required this.weight,
    required this.votingSummary,
    required this.autoProcessed,
    this.autoResult,
  });

  factory CastVoteResult.fromJson(Map<String, dynamic> json) {
    return CastVoteResult(
      voteId: json['vote_id'] ?? 0,
      vote: json['vote']?.toString() ?? '',
      weight: (json['weight'] ?? 1.0).toDouble(),
      votingSummary: json['voting_summary'] != null
          ? VotingSummary.fromJson(json['voting_summary'])
          : VotingSummary.empty(),
      autoProcessed: json['auto_processed'] ?? false,
      autoResult: json['auto_result']?.toString(),
    );
  }

  bool get wasApproved => autoProcessed && autoResult == 'approved';
  bool get wasRejected => autoProcessed && autoResult == 'rejected';
}
