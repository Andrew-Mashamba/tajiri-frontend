import '../config/api_config.dart';

class SubscriptionTier {
  final int id;
  final int creatorId;
  final String name;
  final String? description;
  final double price;
  final String billingPeriod;
  final List<String>? benefits;
  final bool isActive;
  final int subscriberCount;

  SubscriptionTier({
    required this.id,
    required this.creatorId,
    required this.name,
    this.description,
    required this.price,
    this.billingPeriod = 'monthly',
    this.benefits,
    this.isActive = true,
    this.subscriberCount = 0,
  });

  factory SubscriptionTier.fromJson(Map<String, dynamic> json) {
    return SubscriptionTier(
      id: json['id'],
      creatorId: json['creator_id'],
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      billingPeriod: json['billing_period'] ?? 'monthly',
      benefits: json['benefits'] != null ? List<String>.from(json['benefits']) : null,
      isActive: json['is_active'] ?? true,
      subscriberCount: json['subscriber_count'] ?? 0,
    );
  }

  String get priceFormatted => 'TZS ${price.toStringAsFixed(0)}';
  String get periodLabel => billingPeriod == 'yearly' ? 'kwa mwaka' : 'kwa mwezi';
}

class Subscription {
  final int id;
  final int subscriberId;
  final int creatorId;
  final int tierId;
  final String status;
  final double amountPaid;
  final DateTime startedAt;
  final DateTime expiresAt;
  final DateTime? cancelledAt;
  final bool autoRenew;
  final SubscriptionTier? tier;
  final SubscriptionUser? creator;
  final SubscriptionUser? subscriber;

  Subscription({
    required this.id,
    required this.subscriberId,
    required this.creatorId,
    required this.tierId,
    required this.status,
    required this.amountPaid,
    required this.startedAt,
    required this.expiresAt,
    this.cancelledAt,
    this.autoRenew = true,
    this.tier,
    this.creator,
    this.subscriber,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      subscriberId: json['subscriber_id'],
      creatorId: json['creator_id'],
      tierId: json['tier_id'],
      status: json['status'] ?? 'active',
      amountPaid: (json['amount_paid'] ?? 0).toDouble(),
      startedAt: DateTime.parse(json['started_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at']) : null,
      autoRenew: json['auto_renew'] ?? true,
      tier: json['tier'] != null ? SubscriptionTier.fromJson(json['tier']) : null,
      creator: json['creator'] != null ? SubscriptionUser.fromJson(json['creator']) : null,
      subscriber: json['subscriber'] != null ? SubscriptionUser.fromJson(json['subscriber']) : null,
    );
  }

  bool get isActive => status == 'active' && expiresAt.isAfter(DateTime.now());
  int get daysRemaining => expiresAt.difference(DateTime.now()).inDays;
}

class SubscriptionUser {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePhotoPath;

  SubscriptionUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.profilePhotoPath,
  });

  factory SubscriptionUser.fromJson(Map<String, dynamic> json) {
    return SubscriptionUser(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'],
      profilePhotoPath: json['profile_photo_path'],
    );
  }

  String get fullName => '$firstName $lastName';
  String get displayName => username ?? fullName;
  String get avatarUrl => profilePhotoPath != null
      ? '${ApiConfig.storageUrl}/$profilePhotoPath'
      : '';
}

class CreatorEarning {
  final int id;
  final int creatorId;
  final String type;
  final double grossAmount;
  final double platformFee;
  final double netAmount;
  final String status;
  final DateTime? paidAt;
  final DateTime createdAt;

  CreatorEarning({
    required this.id,
    required this.creatorId,
    required this.type,
    required this.grossAmount,
    required this.platformFee,
    required this.netAmount,
    required this.status,
    this.paidAt,
    required this.createdAt,
  });

  factory CreatorEarning.fromJson(Map<String, dynamic> json) {
    return CreatorEarning(
      id: json['id'],
      creatorId: json['creator_id'],
      type: json['type'] ?? 'subscription',
      grossAmount: (json['gross_amount'] ?? 0).toDouble(),
      platformFee: (json['platform_fee'] ?? 0).toDouble(),
      netAmount: (json['net_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get typeName {
    switch (type) {
      case 'subscription': return 'Usajili';
      case 'tip': return 'Tuzo';
      case 'gift': return 'Zawadi';
      default: return type;
    }
  }
}

class EarningsSummary {
  final double totalGross;
  final double totalNet;
  final double pending;
  final double thisMonth;

  EarningsSummary({
    required this.totalGross,
    required this.totalNet,
    required this.pending,
    required this.thisMonth,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      totalGross: (json['total_gross'] ?? 0).toDouble(),
      totalNet: (json['total_net'] ?? 0).toDouble(),
      pending: (json['pending'] ?? 0).toDouble(),
      thisMonth: (json['this_month'] ?? 0).toDouble(),
    );
  }
}

class CreatorPayout {
  final int id;
  final int creatorId;
  final double amount;
  final String paymentMethod;
  final String accountNumber;
  final String accountName;
  final String? provider;
  final String status;
  final String? transactionId;
  final String? failureReason;
  final DateTime? processedAt;
  final DateTime createdAt;

  CreatorPayout({
    required this.id,
    required this.creatorId,
    required this.amount,
    required this.paymentMethod,
    required this.accountNumber,
    required this.accountName,
    this.provider,
    required this.status,
    this.transactionId,
    this.failureReason,
    this.processedAt,
    required this.createdAt,
  });

  factory CreatorPayout.fromJson(Map<String, dynamic> json) {
    return CreatorPayout(
      id: json['id'],
      creatorId: json['creator_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      accountNumber: json['account_number'] ?? '',
      accountName: json['account_name'] ?? '',
      provider: json['provider'],
      status: json['status'] ?? 'pending',
      transactionId: json['transaction_id'],
      failureReason: json['failure_reason'],
      processedAt: json['processed_at'] != null ? DateTime.parse(json['processed_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Inasubiri';
      case 'processing': return 'Inashughulikiwa';
      case 'completed': return 'Imekamilika';
      case 'failed': return 'Imeshindwa';
      default: return status;
    }
  }
}
