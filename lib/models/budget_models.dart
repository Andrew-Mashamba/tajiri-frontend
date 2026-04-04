// lib/models/budget_models.dart

/// Envelope — a budget category with allocated amount
class BudgetEnvelope {
  final int? id;
  final String name;
  final String icon;
  final double allocatedAmount;
  final double spentAmount;
  final String color;
  final int order;
  final bool isDefault;
  final DateTime createdAt;

  BudgetEnvelope({
    this.id,
    required this.name,
    required this.icon,
    required this.allocatedAmount,
    this.spentAmount = 0,
    required this.color,
    required this.order,
    this.isDefault = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get remainingAmount => allocatedAmount - spentAmount;
  double get percentUsed => allocatedAmount > 0 ? (spentAmount / allocatedAmount * 100) : 0;
  bool get isOverBudget => spentAmount > allocatedAmount;

  factory BudgetEnvelope.fromJson(Map<String, dynamic> json) {
    return BudgetEnvelope(
      id: json['id'] as int?,
      name: json['name'] as String,
      icon: json['icon'] as String,
      allocatedAmount: (json['allocated_amount'] ?? 0).toDouble(),
      spentAmount: (json['spent_amount'] ?? 0).toDouble(),
      color: json['color'] as String? ?? '1A1A1A',
      order: json['sort_order'] as int? ?? 0,
      isDefault: json['is_default'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'icon': icon,
    'allocated_amount': allocatedAmount,
    'color': color,
    'sort_order': order,
    'is_default': isDefault ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };

  BudgetEnvelope copyWith({
    int? id,
    String? name,
    String? icon,
    double? allocatedAmount,
    double? spentAmount,
    String? color,
    int? order,
    bool? isDefault,
  }) {
    return BudgetEnvelope(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      color: color ?? this.color,
      order: order ?? this.order,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
    );
  }
}

/// Transaction type
enum BudgetTransactionType { income, expense }

/// Source of the transaction — manual or auto-tracked from TAJIRI
enum BudgetSource {
  manual,
  wallet,
  shop,
  subscription,
  tip,
  michango,
  creatorFund,
  ad,
  salary;

  String get label {
    switch (this) {
      case BudgetSource.manual: return 'Binafsi';
      case BudgetSource.wallet: return 'Wallet';
      case BudgetSource.shop: return 'Duka';
      case BudgetSource.subscription: return 'Usajili';
      case BudgetSource.tip: return 'Tuzo';
      case BudgetSource.michango: return 'Michango';
      case BudgetSource.creatorFund: return 'Mfuko wa Ubunifu';
      case BudgetSource.ad: return 'Matangazo';
      case BudgetSource.salary: return 'Mshahara';
    }
  }
}

/// A single budget transaction (income or expense)
class BudgetTransaction {
  final int? id;
  final int? envelopeId;
  final double amount;
  final BudgetTransactionType type;
  final BudgetSource source;
  final String description;
  final DateTime date;
  final String? tajiriRefId;
  final DateTime createdAt;

  BudgetTransaction({
    this.id,
    this.envelopeId,
    required this.amount,
    required this.type,
    required this.source,
    required this.description,
    required this.date,
    this.tajiriRefId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isIncome => type == BudgetTransactionType.income;
  bool get isExpense => type == BudgetTransactionType.expense;

  factory BudgetTransaction.fromJson(Map<String, dynamic> json) {
    return BudgetTransaction(
      id: json['id'] as int?,
      envelopeId: json['envelope_id'] as int?,
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] == 'income'
          ? BudgetTransactionType.income
          : BudgetTransactionType.expense,
      source: BudgetSource.values.firstWhere(
        (s) => s.name == json['source'],
        orElse: () => BudgetSource.manual,
      ),
      description: json['description'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      tajiriRefId: json['tajiri_ref_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'envelope_id': envelopeId,
    'amount': amount,
    'type': type.name,
    'source': source.name,
    'description': description,
    'date': date.toIso8601String(),
    'tajiri_ref_id': tajiriRefId,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Savings goal with target and progress
class BudgetGoal {
  final int? id;
  final String name;
  final String icon;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;
  final DateTime createdAt;

  BudgetGoal({
    this.id,
    required this.name,
    required this.icon,
    required this.targetAmount,
    this.savedAmount = 0,
    this.deadline,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get percentComplete =>
      targetAmount > 0 ? (savedAmount / targetAmount * 100).clamp(0, 100) : 0;
  double get remainingAmount => (targetAmount - savedAmount).clamp(0, double.infinity);
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
      id: json['id'] as int?,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'flag',
      targetAmount: (json['target_amount'] ?? 0).toDouble(),
      savedAmount: (json['saved_amount'] ?? 0).toDouble(),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'icon': icon,
    'target_amount': targetAmount,
    'saved_amount': savedAmount,
    'deadline': deadline?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  BudgetGoal copyWith({
    int? id,
    String? name,
    String? icon,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
  }) {
    return BudgetGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt,
    );
  }
}

/// Monthly budget period summary
class BudgetPeriod {
  final int year;
  final int month;
  final double totalIncome;
  final double totalAllocated;
  final double totalSpent;

  BudgetPeriod({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalAllocated,
    required this.totalSpent,
  });

  double get unallocated => totalIncome - totalAllocated;
  double get remaining => totalAllocated - totalSpent;

  factory BudgetPeriod.fromJson(Map<String, dynamic> json) {
    return BudgetPeriod(
      year: json['year'] as int,
      month: json['month'] as int,
      totalIncome: (json['total_income'] ?? 0).toDouble(),
      totalAllocated: (json['total_allocated'] ?? 0).toDouble(),
      totalSpent: (json['total_spent'] ?? 0).toDouble(),
    );
  }
}

/// Default envelope templates for new users
class BudgetDefaults {
  static const List<Map<String, dynamic>> defaultEnvelopes = [
    {'name': 'Kodi', 'icon': 'home', 'color': '1A1A1A', 'order': 0},
    {'name': 'Chakula', 'icon': 'restaurant', 'color': '4CAF50', 'order': 1},
    {'name': 'Usafiri', 'icon': 'directions_car', 'color': '2196F3', 'order': 2},
    {'name': 'Ada/Shule', 'icon': 'school', 'color': 'FF9800', 'order': 3},
    {'name': 'Bili', 'icon': 'receipt_long', 'color': '9C27B0', 'order': 4},
    {'name': 'Akiba', 'icon': 'savings', 'color': '009688', 'order': 5},
    {'name': 'Simu', 'icon': 'phone_android', 'color': '607D8B', 'order': 6},
    {'name': 'Afya', 'icon': 'medical_services', 'color': 'E53935', 'order': 7},
    {'name': 'Dharura', 'icon': 'warning', 'color': 'FF5722', 'order': 8},
    {'name': 'Burudani', 'icon': 'sports_esports', 'color': '795548', 'order': 9},
  ];
}
