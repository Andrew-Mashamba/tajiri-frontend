/// Campaign/Contribution models for Michango (GoFundMe-like) feature

/// Campaign status enum
enum CampaignStatus {
  draft,
  pending,    // Awaiting verification
  active,
  paused,
  completed,
  cancelled,
  rejected,
}

/// Campaign category
enum CampaignCategory {
  medical,
  education,
  emergency,
  funeral,
  wedding,
  business,
  community,
  religious,
  sports,
  arts,
  environment,
  other,
}

/// Withdrawal status
enum WithdrawalStatus {
  pending,
  approved,
  processing,
  completed,
  rejected,
  failed,
}

/// KYC verification status
enum KycStatus {
  notStarted,
  pending,
  verified,
  rejected,
}

/// Campaign model
class Campaign {
  final int id;
  final int userId;
  final String title;
  final String story;
  final String? shortDescription;
  final double goalAmount;
  final double raisedAmount;
  final String currency;
  final CampaignStatus status;
  final CampaignCategory category;
  final bool isVerified;
  final DateTime? deadline;
  final String? coverImageUrl;
  final List<String> mediaUrls;
  final int donorsCount;
  final int sharesCount;
  final int viewsCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final CampaignUser? organizer;
  final CampaignUser? beneficiary;
  final List<CampaignUpdate> updates;
  final bool allowAnonymousDonations;
  final double minimumDonation;
  final bool isUrgent;
  final String? bankName;
  final String? accountNumber;
  final String? mobileMoneyNumber;

  Campaign({
    required this.id,
    required this.userId,
    required this.title,
    required this.story,
    this.shortDescription,
    required this.goalAmount,
    this.raisedAmount = 0,
    this.currency = 'TZS',
    this.status = CampaignStatus.draft,
    this.category = CampaignCategory.other,
    this.isVerified = false,
    this.deadline,
    this.coverImageUrl,
    this.mediaUrls = const [],
    this.donorsCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.organizer,
    this.beneficiary,
    this.updates = const [],
    this.allowAnonymousDonations = true,
    this.minimumDonation = 1000,
    this.isUrgent = false,
    this.bankName,
    this.accountNumber,
    this.mobileMoneyNumber,
  });

  double get progressPercent => goalAmount > 0 ? (raisedAmount / goalAmount * 100).clamp(0, 100) : 0;
  bool get isActive => status == CampaignStatus.active;
  bool get isCompleted => status == CampaignStatus.completed || raisedAmount >= goalAmount;
  bool get hasDeadline => deadline != null;
  bool get isExpired => deadline != null && DateTime.now().isAfter(deadline!);
  int get daysLeft => deadline != null ? deadline!.difference(DateTime.now()).inDays : -1;

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      story: json['story'] as String,
      shortDescription: json['short_description'] as String?,
      goalAmount: (json['goal_amount'] as num).toDouble(),
      raisedAmount: (json['raised_amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'TZS',
      status: _parseStatus(json['status'] as String?),
      category: _parseCategory(json['category'] as String?),
      isVerified: json['is_verified'] as bool? ?? false,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      coverImageUrl: json['cover_image_url'] as String?,
      mediaUrls: (json['media_urls'] as List?)?.cast<String>() ?? [],
      donorsCount: json['donors_count'] as int? ?? 0,
      sharesCount: json['shares_count'] as int? ?? 0,
      viewsCount: json['views_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      organizer: json['organizer'] != null ? CampaignUser.fromJson(json['organizer']) : null,
      beneficiary: json['beneficiary'] != null ? CampaignUser.fromJson(json['beneficiary']) : null,
      updates: (json['updates'] as List?)?.map((u) => CampaignUpdate.fromJson(u)).toList() ?? [],
      allowAnonymousDonations: json['allow_anonymous_donations'] as bool? ?? true,
      minimumDonation: (json['minimum_donation'] as num?)?.toDouble() ?? 1000,
      isUrgent: json['is_urgent'] as bool? ?? false,
      bankName: json['bank_name'] as String?,
      accountNumber: json['account_number'] as String?,
      mobileMoneyNumber: json['mobile_money_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'story': story,
      'short_description': shortDescription,
      'goal_amount': goalAmount,
      'raised_amount': raisedAmount,
      'currency': currency,
      'status': status.name,
      'category': category.name,
      'is_verified': isVerified,
      'deadline': deadline?.toIso8601String(),
      'cover_image_url': coverImageUrl,
      'media_urls': mediaUrls,
      'donors_count': donorsCount,
      'shares_count': sharesCount,
      'views_count': viewsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'allow_anonymous_donations': allowAnonymousDonations,
      'minimum_donation': minimumDonation,
      'is_urgent': isUrgent,
      'bank_name': bankName,
      'account_number': accountNumber,
      'mobile_money_number': mobileMoneyNumber,
    };
  }

  static CampaignStatus _parseStatus(String? status) {
    switch (status) {
      case 'draft': return CampaignStatus.draft;
      case 'pending': return CampaignStatus.pending;
      case 'active': return CampaignStatus.active;
      case 'paused': return CampaignStatus.paused;
      case 'completed': return CampaignStatus.completed;
      case 'cancelled': return CampaignStatus.cancelled;
      case 'rejected': return CampaignStatus.rejected;
      default: return CampaignStatus.draft;
    }
  }

  static CampaignCategory _parseCategory(String? category) {
    switch (category) {
      case 'medical': return CampaignCategory.medical;
      case 'education': return CampaignCategory.education;
      case 'emergency': return CampaignCategory.emergency;
      case 'funeral': return CampaignCategory.funeral;
      case 'wedding': return CampaignCategory.wedding;
      case 'business': return CampaignCategory.business;
      case 'community': return CampaignCategory.community;
      case 'religious': return CampaignCategory.religious;
      case 'sports': return CampaignCategory.sports;
      case 'arts': return CampaignCategory.arts;
      case 'environment': return CampaignCategory.environment;
      default: return CampaignCategory.other;
    }
  }
}

/// Campaign user (organizer or beneficiary)
class CampaignUser {
  final int id;
  final String fullName;
  final String? avatarUrl;
  final bool isVerified;
  final KycStatus kycStatus;

  CampaignUser({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.isVerified = false,
    this.kycStatus = KycStatus.notStarted,
  });

  factory CampaignUser.fromJson(Map<String, dynamic> json) {
    return CampaignUser(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      kycStatus: _parseKycStatus(json['kyc_status'] as String?),
    );
  }

  static KycStatus _parseKycStatus(String? status) {
    switch (status) {
      case 'pending': return KycStatus.pending;
      case 'verified': return KycStatus.verified;
      case 'rejected': return KycStatus.rejected;
      default: return KycStatus.notStarted;
    }
  }
}

/// Campaign update/post
class CampaignUpdate {
  final int id;
  final int campaignId;
  final String content;
  final List<String> mediaUrls;
  final DateTime createdAt;

  CampaignUpdate({
    required this.id,
    required this.campaignId,
    required this.content,
    this.mediaUrls = const [],
    required this.createdAt,
  });

  factory CampaignUpdate.fromJson(Map<String, dynamic> json) {
    return CampaignUpdate(
      id: json['id'] as int,
      campaignId: json['campaign_id'] as int,
      content: json['content'] as String,
      mediaUrls: (json['media_urls'] as List?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Donation model
class Donation {
  final int id;
  final int campaignId;
  final int? donorId;
  final double amount;
  final String currency;
  final bool isAnonymous;
  final String? message;
  final String? donorName;
  final String? donorAvatarUrl;
  final String paymentRef;
  final String status;
  final DateTime createdAt;

  Donation({
    required this.id,
    required this.campaignId,
    this.donorId,
    required this.amount,
    this.currency = 'TZS',
    this.isAnonymous = false,
    this.message,
    this.donorName,
    this.donorAvatarUrl,
    required this.paymentRef,
    this.status = 'completed',
    required this.createdAt,
  });

  String get displayName => isAnonymous ? 'Mfadhili Asiyejulikana' : (donorName ?? 'Mfadhili');

  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['id'] as int,
      campaignId: json['campaign_id'] as int,
      donorId: json['donor_id'] as int?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'TZS',
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      message: json['message'] as String?,
      donorName: json['donor_name'] as String?,
      donorAvatarUrl: json['donor_avatar_url'] as String?,
      paymentRef: json['payment_ref'] as String,
      status: json['status'] as String? ?? 'completed',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Withdrawal request model
class Withdrawal {
  final int id;
  final int campaignId;
  final double amount;
  final String currency;
  final WithdrawalStatus status;
  final String destinationType; // 'bank' or 'mobile_money'
  final String destinationDetails;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? processedAt;

  Withdrawal({
    required this.id,
    required this.campaignId,
    required this.amount,
    this.currency = 'TZS',
    this.status = WithdrawalStatus.pending,
    required this.destinationType,
    required this.destinationDetails,
    this.rejectionReason,
    required this.createdAt,
    this.processedAt,
  });

  bool get isPending => status == WithdrawalStatus.pending;
  bool get isCompleted => status == WithdrawalStatus.completed;

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    return Withdrawal(
      id: json['id'] as int,
      campaignId: json['campaign_id'] as int,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'TZS',
      status: _parseWithdrawalStatus(json['status'] as String?),
      destinationType: json['destination_type'] as String,
      destinationDetails: json['destination_details'] as String,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      processedAt: json['processed_at'] != null ? DateTime.parse(json['processed_at']) : null,
    );
  }

  static WithdrawalStatus _parseWithdrawalStatus(String? status) {
    switch (status) {
      case 'pending': return WithdrawalStatus.pending;
      case 'approved': return WithdrawalStatus.approved;
      case 'processing': return WithdrawalStatus.processing;
      case 'completed': return WithdrawalStatus.completed;
      case 'rejected': return WithdrawalStatus.rejected;
      case 'failed': return WithdrawalStatus.failed;
      default: return WithdrawalStatus.pending;
    }
  }
}

/// Campaign statistics
class CampaignStats {
  final int totalCampaigns;
  final int activeCampaigns;
  final int completedCampaigns;
  final double totalRaised;
  final double totalWithdrawn;
  final double availableBalance;
  final int totalDonors;
  final int totalDonations;

  CampaignStats({
    this.totalCampaigns = 0,
    this.activeCampaigns = 0,
    this.completedCampaigns = 0,
    this.totalRaised = 0,
    this.totalWithdrawn = 0,
    this.availableBalance = 0,
    this.totalDonors = 0,
    this.totalDonations = 0,
  });

  factory CampaignStats.fromJson(Map<String, dynamic> json) {
    return CampaignStats(
      totalCampaigns: json['total_campaigns'] as int? ?? 0,
      activeCampaigns: json['active_campaigns'] as int? ?? 0,
      completedCampaigns: json['completed_campaigns'] as int? ?? 0,
      totalRaised: (json['total_raised'] as num?)?.toDouble() ?? 0,
      totalWithdrawn: (json['total_withdrawn'] as num?)?.toDouble() ?? 0,
      availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0,
      totalDonors: json['total_donors'] as int? ?? 0,
      totalDonations: json['total_donations'] as int? ?? 0,
    );
  }
}

/// Helper to get category display names in Swahili
extension CampaignCategoryExtension on CampaignCategory {
  String get displayName {
    switch (this) {
      case CampaignCategory.medical: return 'Afya';
      case CampaignCategory.education: return 'Elimu';
      case CampaignCategory.emergency: return 'Dharura';
      case CampaignCategory.funeral: return 'Msiba';
      case CampaignCategory.wedding: return 'Harusi';
      case CampaignCategory.business: return 'Biashara';
      case CampaignCategory.community: return 'Jamii';
      case CampaignCategory.religious: return 'Dini';
      case CampaignCategory.sports: return 'Michezo';
      case CampaignCategory.arts: return 'Sanaa';
      case CampaignCategory.environment: return 'Mazingira';
      case CampaignCategory.other: return 'Nyingine';
    }
  }

  String get icon {
    switch (this) {
      case CampaignCategory.medical: return 'medical_services';
      case CampaignCategory.education: return 'school';
      case CampaignCategory.emergency: return 'warning';
      case CampaignCategory.funeral: return 'sentiment_very_dissatisfied';
      case CampaignCategory.wedding: return 'favorite';
      case CampaignCategory.business: return 'business';
      case CampaignCategory.community: return 'groups';
      case CampaignCategory.religious: return 'church';
      case CampaignCategory.sports: return 'sports_soccer';
      case CampaignCategory.arts: return 'palette';
      case CampaignCategory.environment: return 'eco';
      case CampaignCategory.other: return 'category';
    }
  }
}

/// Helper to get status display names
extension CampaignStatusExtension on CampaignStatus {
  String get displayName {
    switch (this) {
      case CampaignStatus.draft: return 'Rasimu';
      case CampaignStatus.pending: return 'Inasubiri';
      case CampaignStatus.active: return 'Inaendelea';
      case CampaignStatus.paused: return 'Imesimamishwa';
      case CampaignStatus.completed: return 'Imekamilika';
      case CampaignStatus.cancelled: return 'Imefutwa';
      case CampaignStatus.rejected: return 'Imekataliwa';
    }
  }
}
