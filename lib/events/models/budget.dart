// lib/events/models/budget.dart
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

class EventBudget {
  final int id;
  final int eventId;
  final double totalBudget;
  final double totalSpent;
  final double totalContributed;
  final String currency;
  final List<BudgetCategory> categories;

  EventBudget({
    required this.id,
    required this.eventId,
    this.totalBudget = 0,
    this.totalSpent = 0,
    this.totalContributed = 0,
    this.currency = 'TZS',
    this.categories = const [],
  });

  double get available => totalContributed - totalSpent;
  double get budgetUtilization => totalBudget > 0 ? totalSpent / totalBudget : 0;
  bool get isOverBudget => totalSpent > totalBudget;
  double get surplus => totalContributed - totalSpent;

  factory EventBudget.fromJson(Map<String, dynamic> json) {
    return EventBudget(
      id: _parseInt(json['id']),
      eventId: _parseInt(json['event_id']),
      totalBudget: _parseDouble(json['total_budget']),
      totalSpent: _parseDouble(json['total_spent']),
      totalContributed: _parseDouble(json['total_contributed']),
      currency: json['currency']?.toString() ?? 'TZS',
      categories: (json['categories'] as List?)?.map((e) => BudgetCategory.fromJson(e)).toList() ?? [],
    );
  }
}

class BudgetCategory {
  final int id;
  final int budgetId;
  final String name;
  final double allocated;
  final double spent;
  final int? subCommitteeId;

  BudgetCategory({
    required this.id,
    required this.budgetId,
    required this.name,
    this.allocated = 0,
    this.spent = 0,
    this.subCommitteeId,
  });

  double get remaining => allocated - spent;
  bool get isOverspent => spent > allocated;
  double get utilization => allocated > 0 ? spent / allocated : 0;

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      id: _parseInt(json['id']),
      budgetId: _parseInt(json['budget_id']),
      name: json['name']?.toString() ?? '',
      allocated: _parseDouble(json['allocated']),
      spent: _parseDouble(json['spent']),
      subCommitteeId: json['sub_committee_id'] != null ? _parseInt(json['sub_committee_id']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'allocated': allocated,
    if (subCommitteeId != null) 'sub_committee_id': subCommitteeId,
  };
}

class Expense {
  final int id;
  final int eventId;
  final int? budgetCategoryId;
  final String categoryName;
  final double amount;
  final String currency;
  final String description;
  final String? receiptUrl;
  final String? receiptLocalPath;  // for offline-first receipt capture
  final int? subCommitteeId;
  final int loggedByUserId;
  final String? loggedByName;
  final int? approvedByUserId;
  final String? approvedByName;
  final String status;             // pending, approved, rejected
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.eventId,
    this.budgetCategoryId,
    required this.categoryName,
    required this.amount,
    this.currency = 'TZS',
    required this.description,
    this.receiptUrl,
    this.receiptLocalPath,
    this.subCommitteeId,
    required this.loggedByUserId,
    this.loggedByName,
    this.approvedByUserId,
    this.approvedByName,
    this.status = 'pending',
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get hasReceipt => receiptUrl != null || receiptLocalPath != null;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: _parseInt(json['id']),
      eventId: _parseInt(json['event_id']),
      budgetCategoryId: json['budget_category_id'] != null ? _parseInt(json['budget_category_id']) : null,
      categoryName: json['category_name']?.toString() ?? json['category']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'TZS',
      description: json['description']?.toString() ?? '',
      receiptUrl: ApiConfig.sanitizeUrl(json['receipt_url']?.toString()),
      receiptLocalPath: json['receipt_local_path']?.toString(),
      subCommitteeId: json['sub_committee_id'] != null ? _parseInt(json['sub_committee_id']) : null,
      loggedByUserId: _parseInt(json['logged_by_user_id']),
      loggedByName: json['logged_by_name']?.toString(),
      approvedByUserId: json['approved_by_user_id'] != null ? _parseInt(json['approved_by_user_id']) : null,
      approvedByName: json['approved_by_name']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'event_id': eventId,
    'budget_category_id': budgetCategoryId,
    'category_name': categoryName,
    'amount': amount,
    'currency': currency,
    'description': description,
    'receipt_url': receiptUrl,
    'receipt_local_path': receiptLocalPath,
    'sub_committee_id': subCommitteeId,
    'logged_by_user_id': loggedByUserId,
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };
}

class Disbursement {
  final int id;
  final int eventId;
  final int subCommitteeId;
  final String subCommitteeName;
  final double amount;
  final String currency;
  final String purpose;
  final String status;            // pending, approved, disbursed
  final int requestedByUserId;
  final int? approvedByUserId;
  final DateTime createdAt;
  final DateTime? disbursedAt;

  Disbursement({
    required this.id,
    required this.eventId,
    required this.subCommitteeId,
    required this.subCommitteeName,
    required this.amount,
    this.currency = 'TZS',
    required this.purpose,
    this.status = 'pending',
    required this.requestedByUserId,
    this.approvedByUserId,
    required this.createdAt,
    this.disbursedAt,
  });

  factory Disbursement.fromJson(Map<String, dynamic> json) {
    return Disbursement(
      id: _parseInt(json['id']),
      eventId: _parseInt(json['event_id']),
      subCommitteeId: _parseInt(json['sub_committee_id']),
      subCommitteeName: json['sub_committee_name']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'TZS',
      purpose: json['purpose']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      requestedByUserId: _parseInt(json['requested_by_user_id']),
      approvedByUserId: json['approved_by_user_id'] != null ? _parseInt(json['approved_by_user_id']) : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      disbursedAt: json['disbursed_at'] != null ? DateTime.tryParse(json['disbursed_at'].toString()) : null,
    );
  }
}

class FinancialReport {
  final int eventId;
  final String eventName;
  final double totalContributed;
  final double totalSpent;
  final double surplus;
  final String currency;
  final Map<String, double> incomeByCategory;
  final Map<String, double> expenseByCategory;
  final DateTime generatedAt;

  FinancialReport({
    required this.eventId,
    required this.eventName,
    this.totalContributed = 0,
    this.totalSpent = 0,
    this.surplus = 0,
    this.currency = 'TZS',
    this.incomeByCategory = const {},
    this.expenseByCategory = const {},
    required this.generatedAt,
  });

  factory FinancialReport.fromJson(Map<String, dynamic> json) {
    return FinancialReport(
      eventId: _parseInt(json['event_id']),
      eventName: json['event_name']?.toString() ?? '',
      totalContributed: _parseDouble(json['total_contributed']),
      totalSpent: _parseDouble(json['total_spent']),
      surplus: _parseDouble(json['surplus']),
      currency: json['currency']?.toString() ?? 'TZS',
      incomeByCategory: (json['income_by_category'] as Map?)?.map((k, v) => MapEntry(k.toString(), _parseDouble(v))) ?? {},
      expenseByCategory: (json['expense_by_category'] as Map?)?.map((k, v) => MapEntry(k.toString(), _parseDouble(v))) ?? {},
      generatedAt: DateTime.tryParse(json['generated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
