// lib/budget/models/budget_models.dart
// Budget module models — all API-backed with fromJson/toJson

/// Helper to safely parse int from String or int
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Helper to safely parse double from String, int, or double
double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Helper to safely parse bool from dynamic
bool _parseBool(dynamic value, [bool defaultValue = false]) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return defaultValue;
}

/// Helper to safely parse DateTime
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Helper to safely parse Map from dynamic
Map<String, dynamic>? _parseMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

// ---------------------------------------------------------------------------
// Core Records
// ---------------------------------------------------------------------------

/// An income record — money coming in from any source
class IncomeRecord {
  final int id;
  final int userId;
  final double amount;
  final String source;
  final String? sourceModule;
  final String description;
  final String? referenceId;
  final Map<String, dynamic>? metadata;
  final DateTime date;
  final bool isRecurring;
  final DateTime createdAt;

  IncomeRecord({
    required this.id,
    required this.userId,
    required this.amount,
    required this.source,
    this.sourceModule,
    this.description = '',
    this.referenceId,
    this.metadata,
    required this.date,
    this.isRecurring = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory IncomeRecord.fromJson(Map<String, dynamic> json) {
    return IncomeRecord(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      amount: _parseDouble(json['amount']),
      source: json['source'] as String? ?? 'manual',
      sourceModule: json['source_module'] as String?,
      description: json['description'] as String? ?? '',
      referenceId: json['reference_id'] as String?,
      metadata: _parseMap(json['metadata']),
      date: _parseDateTime(json['date']) ?? DateTime.now(),
      isRecurring: _parseBool(json['is_recurring']),
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'amount': amount,
    'source': source,
    'source_module': sourceModule,
    'description': description,
    'reference_id': referenceId,
    'metadata': metadata,
    'date': date.toIso8601String(),
    'is_recurring': isRecurring,
    'created_at': createdAt.toIso8601String(),
  };
}

/// An expenditure record — money going out
class ExpenditureRecord {
  final int id;
  final int userId;
  final double amount;
  final String category;
  final String? sourceModule;
  final String description;
  final String? referenceId;
  final String? envelopeTag;
  final Map<String, dynamic>? metadata;
  final DateTime date;
  final bool isRecurring;
  final DateTime createdAt;

  ExpenditureRecord({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    this.sourceModule,
    this.description = '',
    this.referenceId,
    this.envelopeTag,
    this.metadata,
    required this.date,
    this.isRecurring = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ExpenditureRecord.fromJson(Map<String, dynamic> json) {
    return ExpenditureRecord(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      amount: _parseDouble(json['amount']),
      category: json['category'] as String? ?? 'other',
      sourceModule: json['source_module'] as String?,
      description: json['description'] as String? ?? '',
      referenceId: json['reference_id'] as String?,
      envelopeTag: json['envelope_tag'] as String?,
      metadata: _parseMap(json['metadata']),
      date: _parseDateTime(json['date']) ?? DateTime.now(),
      isRecurring: _parseBool(json['is_recurring']),
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'amount': amount,
    'category': category,
    'source_module': sourceModule,
    'description': description,
    'reference_id': referenceId,
    'envelope_tag': envelopeTag,
    'metadata': metadata,
    'date': date.toIso8601String(),
    'is_recurring': isRecurring,
    'created_at': createdAt.toIso8601String(),
  };
}

// ---------------------------------------------------------------------------
// Budget Envelopes
// ---------------------------------------------------------------------------

/// A budget envelope — a spending category with allocated amount
class BudgetEnvelope {
  final int? id;
  final int userId;
  final int? defaultId;
  final String nameEn;
  final String nameSw;
  final String icon;
  final String color;
  final int sortOrder;
  final String? moduleTag;
  final double allocatedAmount;
  final double spentAmount;
  final bool isVisible;
  final bool rollover;
  final double rolledOverAmount;
  final int year;
  final int month;

  BudgetEnvelope({
    this.id,
    required this.userId,
    this.defaultId,
    required this.nameEn,
    required this.nameSw,
    required this.icon,
    this.color = '1A1A1A',
    this.sortOrder = 0,
    this.moduleTag,
    this.allocatedAmount = 0,
    this.spentAmount = 0,
    this.isVisible = true,
    this.rollover = false,
    this.rolledOverAmount = 0,
    int? year,
    int? month,
  })  : year = year ?? DateTime.now().year,
        month = month ?? DateTime.now().month;

  /// Remaining budget for this envelope
  double get remainingAmount => allocatedAmount + rolledOverAmount - spentAmount;

  /// Percentage of allocation used (0–100+)
  double get percentUsed {
    final total = allocatedAmount + rolledOverAmount;
    return total > 0 ? (spentAmount / total * 100) : 0;
  }

  /// Whether spending has exceeded the allocation
  bool get isOverBudget => spentAmount > (allocatedAmount + rolledOverAmount);

  /// Display name based on language
  String displayName(bool isSwahili) => isSwahili ? nameSw : nameEn;

  factory BudgetEnvelope.fromJson(Map<String, dynamic> json) {
    return BudgetEnvelope(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      userId: _parseInt(json['user_id']),
      defaultId: json['default_id'] != null ? _parseInt(json['default_id']) : (json['default_envelope_id'] != null ? _parseInt(json['default_envelope_id']) : null),
      nameEn: json['name_en'] as String? ?? json['name'] as String? ?? '',
      nameSw: json['name_sw'] as String? ?? json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? 'category',
      color: json['color'] as String? ?? '1A1A1A',
      sortOrder: _parseInt(json['sort_order']),
      moduleTag: json['module_tag'] as String?,
      allocatedAmount: _parseDouble(json['allocated_amount']),
      spentAmount: _parseDouble(json['spent_amount']),
      isVisible: json.containsKey('is_hidden') ? !_parseBool(json['is_hidden']) : _parseBool(json['is_visible'], true),
      rollover: _parseBool(json['rollover']),
      rolledOverAmount: _parseDouble(json['rolled_over_amount']),
      year: _parseInt(json['year'] ?? json['budget_year']),
      month: _parseInt(json['month'] ?? json['budget_month']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'default_id': defaultId,
    'name_en': nameEn,
    'name_sw': nameSw,
    'icon': icon,
    'color': color,
    'sort_order': sortOrder,
    'module_tag': moduleTag,
    'allocated_amount': allocatedAmount,
    'is_visible': isVisible,
    'rollover': rollover,
    'rolled_over_amount': rolledOverAmount,
    'year': year,
    'month': month,
  };

  BudgetEnvelope copyWith({
    int? id,
    int? userId,
    int? defaultId,
    String? nameEn,
    String? nameSw,
    String? icon,
    String? color,
    int? sortOrder,
    String? moduleTag,
    double? allocatedAmount,
    double? spentAmount,
    bool? isVisible,
    bool? rollover,
    double? rolledOverAmount,
    int? year,
    int? month,
  }) {
    return BudgetEnvelope(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      defaultId: defaultId ?? this.defaultId,
      nameEn: nameEn ?? this.nameEn,
      nameSw: nameSw ?? this.nameSw,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      moduleTag: moduleTag ?? this.moduleTag,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      isVisible: isVisible ?? this.isVisible,
      rollover: rollover ?? this.rollover,
      rolledOverAmount: rolledOverAmount ?? this.rolledOverAmount,
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }
}

/// Default envelope template from the API
class EnvelopeDefault {
  final int id;
  final String nameEn;
  final String nameSw;
  final String icon;
  final String color;
  final int sortOrder;
  final String? groupName;
  final String? moduleTag;
  final bool isActive;

  EnvelopeDefault({
    required this.id,
    required this.nameEn,
    required this.nameSw,
    required this.icon,
    this.color = '1A1A1A',
    this.sortOrder = 0,
    this.groupName,
    this.moduleTag,
    this.isActive = true,
  });

  /// Display name based on language
  String displayName(bool isSwahili) => isSwahili ? nameSw : nameEn;

  factory EnvelopeDefault.fromJson(Map<String, dynamic> json) {
    return EnvelopeDefault(
      id: _parseInt(json['id']),
      nameEn: json['name_en'] as String? ?? '',
      nameSw: json['name_sw'] as String? ?? '',
      icon: json['icon'] as String? ?? 'category',
      color: json['color'] as String? ?? '1A1A1A',
      sortOrder: _parseInt(json['sort_order']),
      groupName: json['group_name'] as String?,
      moduleTag: json['module_tag'] as String?,
      isActive: _parseBool(json['is_active'], true),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name_en': nameEn,
    'name_sw': nameSw,
    'icon': icon,
    'color': color,
    'sort_order': sortOrder,
    'group_name': groupName,
    'module_tag': moduleTag,
    'is_active': isActive,
  };
}

// ---------------------------------------------------------------------------
// Goals
// ---------------------------------------------------------------------------

/// A savings goal with target and progress
class BudgetGoal {
  final int? id;
  final int userId;
  final String name;
  final String icon;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;
  final DateTime createdAt;

  BudgetGoal({
    this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.targetAmount,
    this.savedAmount = 0,
    this.deadline,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get percentComplete =>
      targetAmount > 0 ? (savedAmount / targetAmount * 100).clamp(0, 100) : 0;

  double get remainingAmount =>
      (targetAmount - savedAmount).clamp(0, double.infinity);

  bool get isComplete => savedAmount >= targetAmount;

  /// Months remaining until deadline (null if no deadline)
  int? get monthsRemaining {
    if (deadline == null) return null;
    final now = DateTime.now();
    return (deadline!.year - now.year) * 12 + deadline!.month - now.month;
  }

  /// Monthly contribution needed to reach goal by deadline
  double? get monthlyTarget {
    final months = monthsRemaining;
    if (months == null || months <= 0) return null;
    return remainingAmount / months;
  }

  factory BudgetGoal.fromJson(Map<String, dynamic> json) {
    return BudgetGoal(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      userId: _parseInt(json['user_id']),
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? 'flag',
      targetAmount: _parseDouble(json['target_amount']),
      savedAmount: _parseDouble(json['saved_amount']),
      deadline: _parseDateTime(json['deadline']),
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'name': name,
    'icon': icon,
    'target_amount': targetAmount,
    'saved_amount': savedAmount,
    'deadline': deadline?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  BudgetGoal copyWith({
    int? id,
    int? userId,
    String? name,
    String? icon,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
  }) {
    return BudgetGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt,
    );
  }
}

// ---------------------------------------------------------------------------
// Period Summary
// ---------------------------------------------------------------------------

/// Monthly budget period summary
class BudgetPeriod {
  final int? id;
  final int userId;
  final int year;
  final int month;
  final double totalIncome;
  final double totalAllocated;
  final double totalSpent;
  final double walletBalance;
  final double savingsRate;

  BudgetPeriod({
    this.id,
    required this.userId,
    required this.year,
    required this.month,
    this.totalIncome = 0,
    this.totalAllocated = 0,
    this.totalSpent = 0,
    this.walletBalance = 0,
    this.savingsRate = 0,
  });

  /// Income not yet allocated to envelopes
  double get unallocated => totalIncome - totalAllocated;

  /// Budget remaining (allocated minus spent)
  double get remaining => totalAllocated - totalSpent;

  factory BudgetPeriod.fromJson(Map<String, dynamic> json) {
    return BudgetPeriod(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      userId: _parseInt(json['user_id']),
      year: _parseInt(json['year']),
      month: _parseInt(json['month']),
      totalIncome: _parseDouble(json['total_income']),
      totalAllocated: _parseDouble(json['total_allocated']),
      totalSpent: _parseDouble(json['total_spent']),
      walletBalance: _parseDouble(json['wallet_balance']),
      savingsRate: _parseDouble(json['savings_rate']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'year': year,
    'month': month,
    'total_income': totalIncome,
    'total_allocated': totalAllocated,
    'total_spent': totalSpent,
    'wallet_balance': walletBalance,
    'savings_rate': savingsRate,
  };
}

// ---------------------------------------------------------------------------
// Summaries & Analytics
// ---------------------------------------------------------------------------

/// Summary of income for a period
class IncomeSummary {
  final double totalIncome;
  final Map<String, double> bySource;
  final Map<String, double> byModule;
  final int transactionCount;
  final double trend;

  IncomeSummary({
    this.totalIncome = 0,
    this.bySource = const {},
    this.byModule = const {},
    this.transactionCount = 0,
    this.trend = 0,
  });

  factory IncomeSummary.fromJson(Map<String, dynamic> json) {
    return IncomeSummary(
      totalIncome: _parseDouble(json['total_income']),
      bySource: _parseDoubleMap(json['by_source']),
      byModule: _parseDoubleMap(json['by_module']),
      transactionCount: _parseInt(json['transaction_count']),
      trend: _parseDouble(json['trend']),
    );
  }

  Map<String, dynamic> toJson() => {
    'total_income': totalIncome,
    'by_source': bySource,
    'by_module': byModule,
    'transaction_count': transactionCount,
    'trend': trend,
  };
}

/// Summary of expenditures for a period
class ExpenditureSummary {
  final double totalSpent;
  final Map<String, double> byCategory;
  final Map<String, double> byModule;
  final int transactionCount;
  final double trend;

  ExpenditureSummary({
    this.totalSpent = 0,
    this.byCategory = const {},
    this.byModule = const {},
    this.transactionCount = 0,
    this.trend = 0,
  });

  factory ExpenditureSummary.fromJson(Map<String, dynamic> json) {
    return ExpenditureSummary(
      totalSpent: _parseDouble(json['total_spent']),
      byCategory: _parseDoubleMap(json['by_category']),
      byModule: _parseDoubleMap(json['by_module']),
      transactionCount: _parseInt(json['transaction_count']),
      trend: _parseDouble(json['trend']),
    );
  }

  Map<String, dynamic> toJson() => {
    'total_spent': totalSpent,
    'by_category': byCategory,
    'by_module': byModule,
    'transaction_count': transactionCount,
    'trend': trend,
  };
}

/// Spending pace for a category/envelope — are we on track?
class SpendingPace {
  final String category;
  final double allocated;
  final double spent;
  final double remaining;
  final int daysRemaining;
  final double dailyAllowance;
  final double projectedTotal;
  final String status; // on_track, caution, over_budget

  SpendingPace({
    required this.category,
    this.allocated = 0,
    this.spent = 0,
    this.remaining = 0,
    this.daysRemaining = 0,
    this.dailyAllowance = 0,
    this.projectedTotal = 0,
    this.status = 'on_track',
  });

  bool get isOnTrack => status == 'on_track';
  bool get isCaution => status == 'caution';
  bool get isOverBudget => status == 'over_budget';

  factory SpendingPace.fromJson(Map<String, dynamic> json) {
    return SpendingPace(
      category: json['category'] as String? ?? '',
      allocated: _parseDouble(json['allocated']),
      spent: _parseDouble(json['spent']),
      remaining: _parseDouble(json['remaining']),
      daysRemaining: _parseInt(json['days_remaining']),
      dailyAllowance: _parseDouble(json['daily_allowance']),
      projectedTotal: _parseDouble(json['projected_total']),
      status: json['status'] as String? ?? 'on_track',
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'allocated': allocated,
    'spent': spent,
    'remaining': remaining,
    'days_remaining': daysRemaining,
    'daily_allowance': dailyAllowance,
    'projected_total': projectedTotal,
    'status': status,
  };
}

// ---------------------------------------------------------------------------
// Recurring & Upcoming
// ---------------------------------------------------------------------------

/// A recurring expense pattern detected or confirmed
class RecurringExpense {
  final int? id;
  final String description;
  final double amount;
  final int? envelopeId;
  final String category;
  final String frequency; // monthly, weekly, yearly
  final DateTime? lastOccurrence;
  final DateTime? nextExpected;
  final bool isConfirmed;

  RecurringExpense({
    this.id,
    required this.description,
    required this.amount,
    this.envelopeId,
    this.category = '',
    this.frequency = 'monthly',
    this.lastOccurrence,
    this.nextExpected,
    this.isConfirmed = false,
  });

  factory RecurringExpense.fromJson(Map<String, dynamic> json) {
    return RecurringExpense(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      description: json['description'] as String? ?? '',
      amount: _parseDouble(json['amount']),
      envelopeId: json['envelope_id'] != null ? _parseInt(json['envelope_id']) : null,
      category: json['category'] as String? ?? '',
      frequency: json['frequency'] as String? ?? 'monthly',
      lastOccurrence: _parseDateTime(json['last_occurrence']),
      nextExpected: _parseDateTime(json['next_expected']),
      isConfirmed: _parseBool(json['is_confirmed']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'description': description,
    'amount': amount,
    'envelope_id': envelopeId,
    'category': category,
    'frequency': frequency,
    'last_occurrence': lastOccurrence?.toIso8601String(),
    'next_expected': nextExpected?.toIso8601String(),
    'is_confirmed': isConfirmed,
  };
}

/// A recurring income pattern
class RecurringIncome {
  final int? id;
  final String description;
  final double amount;
  final String source;
  final String frequency; // monthly, weekly, yearly
  final DateTime? lastOccurrence;
  final DateTime? nextExpected;

  RecurringIncome({
    this.id,
    required this.description,
    required this.amount,
    this.source = 'manual',
    this.frequency = 'monthly',
    this.lastOccurrence,
    this.nextExpected,
  });

  factory RecurringIncome.fromJson(Map<String, dynamic> json) {
    return RecurringIncome(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      description: json['description'] as String? ?? '',
      amount: _parseDouble(json['amount']),
      source: json['source'] as String? ?? 'manual',
      frequency: json['frequency'] as String? ?? 'monthly',
      lastOccurrence: _parseDateTime(json['last_occurrence']),
      nextExpected: _parseDateTime(json['next_expected']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'description': description,
    'amount': amount,
    'source': source,
    'frequency': frequency,
    'last_occurrence': lastOccurrence?.toIso8601String(),
    'next_expected': nextExpected?.toIso8601String(),
  };
}

/// An upcoming expected expense
class UpcomingExpense {
  final String description;
  final double amount;
  final String category;
  final DateTime? expectedDate;
  final bool isRecurring;

  UpcomingExpense({
    required this.description,
    required this.amount,
    this.category = '',
    this.expectedDate,
    this.isRecurring = false,
  });

  factory UpcomingExpense.fromJson(Map<String, dynamic> json) {
    return UpcomingExpense(
      description: json['description'] as String? ?? '',
      amount: _parseDouble(json['amount']),
      category: json['category'] as String? ?? '',
      expectedDate: _parseDateTime(json['expected_date']),
      isRecurring: _parseBool(json['is_recurring']),
    );
  }

  Map<String, dynamic> toJson() => {
    'description': description,
    'amount': amount,
    'category': category,
    'expected_date': expectedDate?.toIso8601String(),
    'is_recurring': isRecurring,
  };
}

// ---------------------------------------------------------------------------
// Result Classes (API response wrappers)
// ---------------------------------------------------------------------------

/// Result wrapper for income list API responses
class IncomeListResult {
  final bool success;
  final List<IncomeRecord> records;
  final String? message;

  IncomeListResult({
    required this.success,
    this.records = const [],
    this.message,
  });

  factory IncomeListResult.fromJson(Map<String, dynamic> json) {
    return IncomeListResult(
      success: _parseBool(json['success']),
      records: (json['records'] as List<dynamic>?)
              ?.map((e) => IncomeRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      message: json['message'] as String?,
    );
  }
}

/// Result wrapper for expenditure list API responses
class ExpenditureListResult {
  final bool success;
  final List<ExpenditureRecord> records;
  final String? message;

  ExpenditureListResult({
    required this.success,
    this.records = const [],
    this.message,
  });

  factory ExpenditureListResult.fromJson(Map<String, dynamic> json) {
    return ExpenditureListResult(
      success: _parseBool(json['success']),
      records: (json['records'] as List<dynamic>?)
              ?.map((e) => ExpenditureRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      message: json['message'] as String?,
    );
  }
}

/// Result wrapper for envelope list API responses
class EnvelopeListResult {
  final bool success;
  final List<BudgetEnvelope> envelopes;
  final String? message;

  EnvelopeListResult({
    required this.success,
    this.envelopes = const [],
    this.message,
  });

  factory EnvelopeListResult.fromJson(Map<String, dynamic> json) {
    return EnvelopeListResult(
      success: _parseBool(json['success']),
      envelopes: (json['envelopes'] as List<dynamic>?)
              ?.map((e) => BudgetEnvelope.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      message: json['message'] as String?,
    );
  }
}

/// Result wrapper for goal list API responses
class GoalListResult {
  final bool success;
  final List<BudgetGoal> goals;
  final String? message;

  GoalListResult({
    required this.success,
    this.goals = const [],
    this.message,
  });

  factory GoalListResult.fromJson(Map<String, dynamic> json) {
    return GoalListResult(
      success: _parseBool(json['success']),
      goals: (json['goals'] as List<dynamic>?)
              ?.map((e) => BudgetGoal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      message: json['message'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// Streak & Gamification
// ---------------------------------------------------------------------------

/// Budget streak — tracks consecutive days within budget + achievement badges.
class BudgetStreak {
  final int currentStreak;
  final int longestStreak;
  final String? lastCheckDate;
  final bool freezeUsed;
  final List<String> badges;

  BudgetStreak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCheckDate,
    this.freezeUsed = false,
    this.badges = const [],
  });

  factory BudgetStreak.fromJson(Map<String, dynamic> json) {
    return BudgetStreak(
      currentStreak: _parseInt(json['current_streak']),
      longestStreak: _parseInt(json['longest_streak']),
      lastCheckDate: json['last_check_date'] as String?,
      freezeUsed: _parseBool(json['freeze_used']),
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

// ---------------------------------------------------------------------------
// Private Helpers
// ---------------------------------------------------------------------------

// Parse a map of string keys to double values
Map<String, double> _parseDoubleMap(dynamic value) {
  if (value == null) return {};
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), _parseDouble(val)));
  }
  return {};
}
