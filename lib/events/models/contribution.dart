// lib/events/models/contribution.dart
import '../../config/api_config.dart';

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _parseDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

enum ContributorCategory {
  nduguKaribu,     // Close family
  nduguMbali,      // Extended family
  marafiki,        // Friends
  wafanyakazi,     // Work colleagues
  waumini,         // Church/mosque community
  majirani,        // Neighbors
  wengine;         // Others

  String get displayName {
    switch (this) {
      case ContributorCategory.nduguKaribu: return 'Ndugu wa Karibu';
      case ContributorCategory.nduguMbali: return 'Ndugu wa Mbali';
      case ContributorCategory.marafiki: return 'Marafiki';
      case ContributorCategory.wafanyakazi: return 'Wafanyakazi';
      case ContributorCategory.waumini: return 'Waumini';
      case ContributorCategory.majirani: return 'Majirani';
      case ContributorCategory.wengine: return 'Wengine';
    }
  }

  String get subtitle {
    switch (this) {
      case ContributorCategory.nduguKaribu: return 'Close Family';
      case ContributorCategory.nduguMbali: return 'Extended Family';
      case ContributorCategory.marafiki: return 'Friends';
      case ContributorCategory.wafanyakazi: return 'Colleagues';
      case ContributorCategory.waumini: return 'Faith Community';
      case ContributorCategory.majirani: return 'Neighbors';
      case ContributorCategory.wengine: return 'Others';
    }
  }

  static ContributorCategory fromApi(String? value) {
    if (value == null) return ContributorCategory.wengine;
    for (final c in ContributorCategory.values) {
      if (c.name == value) return c;
    }
    return ContributorCategory.wengine;
  }
}

enum ContributionStatus {
  pledged,
  partiallyPaid,
  paid,
  overdue;

  String get displayName {
    switch (this) {
      case ContributionStatus.pledged: return 'Imeahidiwa';
      case ContributionStatus.partiallyPaid: return 'Sehemu Imelipwa';
      case ContributionStatus.paid: return 'Imelipwa';
      case ContributionStatus.overdue: return 'Imechelewa';
    }
  }

  String get subtitle {
    switch (this) {
      case ContributionStatus.pledged: return 'Pledged';
      case ContributionStatus.partiallyPaid: return 'Partially Paid';
      case ContributionStatus.paid: return 'Paid';
      case ContributionStatus.overdue: return 'Overdue';
    }
  }

  static ContributionStatus fromApi(String? value) {
    switch (value) {
      case 'pledged': return ContributionStatus.pledged;
      case 'partially_paid': return ContributionStatus.partiallyPaid;
      case 'paid': return ContributionStatus.paid;
      case 'overdue': return ContributionStatus.overdue;
      default: return ContributionStatus.pledged;
    }
  }
}

class Contribution {
  final int id;
  final int eventId;
  final int? userId;
  final String contributorName;
  final String? contributorPhone;
  final String? avatarUrl;
  final ContributorCategory category;
  final double amountPledged;
  final double amountPaid;
  final ContributionStatus status;
  final String? paymentMethod;     // mpesa, tigo_pesa, cash, etc.
  final String? paymentReference;  // M-Pesa transaction ID
  final bool isAnonymous;
  final String? message;
  final int? followUpAssignedTo;   // mjumbe user_id for follow-up
  final DateTime createdAt;
  final DateTime? lastPaymentAt;

  Contribution({
    required this.id,
    required this.eventId,
    this.userId,
    required this.contributorName,
    this.contributorPhone,
    this.avatarUrl,
    this.category = ContributorCategory.wengine,
    this.amountPledged = 0,
    this.amountPaid = 0,
    this.status = ContributionStatus.pledged,
    this.paymentMethod,
    this.paymentReference,
    this.isAnonymous = false,
    this.message,
    this.followUpAssignedTo,
    required this.createdAt,
    this.lastPaymentAt,
  });

  double get outstanding => amountPledged - amountPaid;
  bool get isFullyPaid => amountPaid >= amountPledged && amountPledged > 0;
  bool get hasOutstanding => outstanding > 0;

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: _parseInt(json['id']),
      eventId: _parseInt(json['event_id']),
      userId: json['user_id'] != null ? _parseInt(json['user_id']) : null,
      contributorName: json['contributor_name']?.toString() ?? json['donor_name']?.toString() ?? '',
      contributorPhone: json['contributor_phone']?.toString(),
      avatarUrl: ApiConfig.sanitizeUrl(json['avatar_url']?.toString()),
      category: ContributorCategory.fromApi(json['category']?.toString()),
      amountPledged: _parseDouble(json['amount_pledged']),
      amountPaid: _parseDouble(json['amount_paid'] ?? json['amount']),
      status: ContributionStatus.fromApi(json['status']?.toString()),
      paymentMethod: json['payment_method']?.toString(),
      paymentReference: json['payment_reference']?.toString(),
      isAnonymous: _parseBool(json['is_anonymous']),
      message: json['message']?.toString(),
      followUpAssignedTo: json['follow_up_assigned_to'] != null ? _parseInt(json['follow_up_assigned_to']) : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      lastPaymentAt: json['last_payment_at'] != null ? DateTime.tryParse(json['last_payment_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'event_id': eventId,
    'user_id': userId,
    'contributor_name': contributorName,
    'contributor_phone': contributorPhone,
    'category': category.name,
    'amount_pledged': amountPledged,
    'amount_paid': amountPaid,
    'status': status.name,
    'payment_method': paymentMethod,
    'payment_reference': paymentReference,
    'is_anonymous': isAnonymous,
    'message': message,
    'follow_up_assigned_to': followUpAssignedTo,
    'created_at': createdAt.toIso8601String(),
    'last_payment_at': lastPaymentAt?.toIso8601String(),
  };
}

class ContributionSummary {
  final int eventId;
  final double totalPledged;
  final double totalCollected;
  final double goalAmount;
  final int totalContributors;
  final int paidCount;
  final int pendingCount;
  final int overdueCount;
  final String currency;
  final Map<String, double> byCategory;
  final List<DailyCollection> dailyTrend;

  ContributionSummary({
    required this.eventId,
    this.totalPledged = 0,
    this.totalCollected = 0,
    this.goalAmount = 0,
    this.totalContributors = 0,
    this.paidCount = 0,
    this.pendingCount = 0,
    this.overdueCount = 0,
    this.currency = 'TZS',
    this.byCategory = const {},
    this.dailyTrend = const [],
  });

  double get progressPercent => goalAmount > 0 ? (totalCollected / goalAmount).clamp(0, 1) : 0;
  double get pledgeToPaymentRatio => totalPledged > 0 ? totalCollected / totalPledged : 0;
  double get outstanding => totalPledged - totalCollected;

  factory ContributionSummary.fromJson(Map<String, dynamic> json) {
    return ContributionSummary(
      eventId: _parseInt(json['event_id']),
      totalPledged: _parseDouble(json['total_pledged']),
      totalCollected: _parseDouble(json['total_collected']),
      goalAmount: _parseDouble(json['goal_amount']),
      totalContributors: _parseInt(json['total_contributors']),
      paidCount: _parseInt(json['paid_count']),
      pendingCount: _parseInt(json['pending_count']),
      overdueCount: _parseInt(json['overdue_count']),
      currency: json['currency']?.toString() ?? 'TZS',
      byCategory: (json['by_category'] as Map?)?.map((k, v) => MapEntry(k.toString(), _parseDouble(v))) ?? {},
      dailyTrend: (json['daily_trend'] as List?)?.map((e) => DailyCollection.fromJson(e)).toList() ?? [],
    );
  }
}

class DailyCollection {
  final DateTime date;
  final double amount;
  final int count;

  DailyCollection({required this.date, required this.amount, this.count = 0});

  factory DailyCollection.fromJson(Map<String, dynamic> json) {
    return DailyCollection(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      amount: _parseDouble(json['amount']),
      count: _parseInt(json['count']),
    );
  }
}
