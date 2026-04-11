// lib/events/models/event_analytics.dart

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

class EventAnalytics {
  final int eventId;
  final int totalViews;
  final int uniqueViews;
  final int totalRSVPs;
  final int goingCount;
  final int interestedCount;
  final int ticketsSold;
  final double totalRevenue;
  final String currency;
  final int checkedInCount;
  final double checkInRate;
  final int commentsCount;
  final int sharesCount;
  final List<DailyMetric> dailyViews;
  final List<DailyMetric> dailySales;
  final Map<String, int> trafficSources;
  final Map<String, int> tierBreakdown;

  EventAnalytics({
    required this.eventId,
    this.totalViews = 0,
    this.uniqueViews = 0,
    this.totalRSVPs = 0,
    this.goingCount = 0,
    this.interestedCount = 0,
    this.ticketsSold = 0,
    this.totalRevenue = 0,
    this.currency = 'TZS',
    this.checkedInCount = 0,
    this.checkInRate = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.dailyViews = const [],
    this.dailySales = const [],
    this.trafficSources = const {},
    this.tierBreakdown = const {},
  });

  factory EventAnalytics.fromJson(Map<String, dynamic> json) {
    return EventAnalytics(
      eventId: _parseInt(json['event_id']),
      totalViews: _parseInt(json['total_views']),
      uniqueViews: _parseInt(json['unique_views']),
      totalRSVPs: _parseInt(json['total_rsvps']),
      goingCount: _parseInt(json['going_count']),
      interestedCount: _parseInt(json['interested_count']),
      ticketsSold: _parseInt(json['tickets_sold']),
      totalRevenue: _parseDouble(json['total_revenue']),
      currency: json['currency']?.toString() ?? 'TZS',
      checkedInCount: _parseInt(json['checked_in_count']),
      checkInRate: _parseDouble(json['check_in_rate']),
      commentsCount: _parseInt(json['comments_count']),
      sharesCount: _parseInt(json['shares_count']),
      dailyViews: (json['daily_views'] as List?)?.map((e) => DailyMetric.fromJson(e)).toList() ?? [],
      dailySales: (json['daily_sales'] as List?)?.map((e) => DailyMetric.fromJson(e)).toList() ?? [],
      trafficSources: (json['traffic_sources'] as Map?)?.map((k, v) => MapEntry(k.toString(), _parseInt(v))) ?? {},
      tierBreakdown: (json['tier_breakdown'] as Map?)?.map((k, v) => MapEntry(k.toString(), _parseInt(v))) ?? {},
    );
  }
}

class DailyMetric {
  final DateTime date;
  final int value;

  DailyMetric({required this.date, required this.value});

  factory DailyMetric.fromJson(Map<String, dynamic> json) {
    return DailyMetric(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      value: _parseInt(json['value']),
    );
  }
}

class SalesReport {
  final double grossRevenue;
  final double platformFees;
  final double netRevenue;
  final double pendingPayout;
  final double paidOut;
  final String currency;
  final List<TicketSale> recentSales;

  SalesReport({
    this.grossRevenue = 0,
    this.platformFees = 0,
    this.netRevenue = 0,
    this.pendingPayout = 0,
    this.paidOut = 0,
    this.currency = 'TZS',
    this.recentSales = const [],
  });

  factory SalesReport.fromJson(Map<String, dynamic> json) {
    return SalesReport(
      grossRevenue: _parseDouble(json['gross_revenue']),
      platformFees: _parseDouble(json['platform_fees']),
      netRevenue: _parseDouble(json['net_revenue']),
      pendingPayout: _parseDouble(json['pending_payout']),
      paidOut: _parseDouble(json['paid_out']),
      currency: json['currency']?.toString() ?? 'TZS',
      recentSales: (json['recent_sales'] as List?)?.map((e) => TicketSale.fromJson(e)).toList() ?? [],
    );
  }
}

class TicketSale {
  final int ticketId;
  final String buyerName;
  final String tierName;
  final double amount;
  final String paymentMethod;
  final DateTime purchasedAt;

  TicketSale({
    required this.ticketId,
    required this.buyerName,
    required this.tierName,
    required this.amount,
    required this.paymentMethod,
    required this.purchasedAt,
  });

  factory TicketSale.fromJson(Map<String, dynamic> json) {
    return TicketSale(
      ticketId: _parseInt(json['ticket_id']),
      buyerName: json['buyer_name']?.toString() ?? '',
      tierName: json['tier_name']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      paymentMethod: json['payment_method']?.toString() ?? '',
      purchasedAt: DateTime.tryParse(json['purchased_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class TeamMember {
  final int userId;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String role;
  final DateTime addedAt;

  TeamMember({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    required this.role,
    required this.addedAt,
  });

  String get fullName => '$firstName $lastName';

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: _parseInt(json['user_id'] ?? json['id']),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      role: json['role']?.toString() ?? 'volunteer',
      addedAt: DateTime.tryParse(json['added_at']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class SurveyQuestion {
  final String question;
  final String type;
  final List<String>? options;

  SurveyQuestion({required this.question, this.type = 'text', this.options});

  Map<String, dynamic> toJson() => {
    'question': question,
    'type': type,
    if (options != null) 'options': options,
  };
}

class SurveyResponse {
  final int userId;
  final String userName;
  final Map<String, String> answers;
  final DateTime submittedAt;

  SurveyResponse({required this.userId, required this.userName, required this.answers, required this.submittedAt});

  factory SurveyResponse.fromJson(Map<String, dynamic> json) {
    return SurveyResponse(
      userId: _parseInt(json['user_id']),
      userName: json['user_name']?.toString() ?? '',
      answers: (json['answers'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {},
      submittedAt: DateTime.tryParse(json['submitted_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class CheckInRecord {
  final int ticketId;
  final String attendeeName;
  final String tierName;
  final DateTime checkedInAt;
  final String checkedInBy;

  CheckInRecord({required this.ticketId, required this.attendeeName, required this.tierName, required this.checkedInAt, required this.checkedInBy});

  factory CheckInRecord.fromJson(Map<String, dynamic> json) {
    return CheckInRecord(
      ticketId: _parseInt(json['ticket_id']),
      attendeeName: json['attendee_name']?.toString() ?? '',
      tierName: json['tier_name']?.toString() ?? '',
      checkedInAt: DateTime.tryParse(json['checked_in_at']?.toString() ?? '') ?? DateTime.now(),
      checkedInBy: json['checked_in_by']?.toString() ?? '',
    );
  }
}
