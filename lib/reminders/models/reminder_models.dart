// lib/reminders/models/reminder_models.dart
import 'package:flutter/material.dart';

// ── Parse helpers ─────────────────────────────────────────────────────────

bool _parseBool(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v == 'true';
  return fallback;
}

const Object _kSentinel = Object();

// ── ReminderCategory ──────────────────────────────────────────────────────

enum ReminderCategory {
  calendar,
  appointment,
  quote,
  invoice,
  transaction,
  revenue,
  recurring,
  debt,
  document,
  expense,
  tax,
  credit,
  employee,
  payroll,
  purchaseOrder,
  tender,
  general;

  String get displayName {
    switch (this) {
      case ReminderCategory.calendar: return 'Kalenda';
      case ReminderCategory.appointment: return 'Miadi';
      case ReminderCategory.quote: return 'Nukuu';
      case ReminderCategory.invoice: return 'Ankara';
      case ReminderCategory.transaction: return 'Muamala';
      case ReminderCategory.revenue: return 'Mapato';
      case ReminderCategory.recurring: return 'Ya Mara kwa Mara';
      case ReminderCategory.debt: return 'Deni';
      case ReminderCategory.document: return 'Hati';
      case ReminderCategory.expense: return 'Gharama';
      case ReminderCategory.tax: return 'Kodi';
      case ReminderCategory.credit: return 'CRB';
      case ReminderCategory.employee: return 'Mfanyakazi';
      case ReminderCategory.payroll: return 'Mishahara';
      case ReminderCategory.purchaseOrder: return 'Oda ya Ununuzi';
      case ReminderCategory.tender: return 'Zabuni';
      case ReminderCategory.general: return 'Jumla';
    }
  }

  String get subtitle {
    switch (this) {
      case ReminderCategory.calendar: return 'Calendar';
      case ReminderCategory.appointment: return 'Appointment';
      case ReminderCategory.quote: return 'Quote';
      case ReminderCategory.invoice: return 'Invoice';
      case ReminderCategory.transaction: return 'Transaction';
      case ReminderCategory.revenue: return 'Revenue';
      case ReminderCategory.recurring: return 'Recurring';
      case ReminderCategory.debt: return 'Debt';
      case ReminderCategory.document: return 'Document';
      case ReminderCategory.expense: return 'Expense';
      case ReminderCategory.tax: return 'Tax';
      case ReminderCategory.credit: return 'Credit / CRB';
      case ReminderCategory.employee: return 'Employee';
      case ReminderCategory.payroll: return 'Payroll';
      case ReminderCategory.purchaseOrder: return 'Purchase Order';
      case ReminderCategory.tender: return 'Tender';
      case ReminderCategory.general: return 'General';
    }
  }

  IconData get icon {
    switch (this) {
      case ReminderCategory.calendar: return Icons.calendar_month_rounded;
      case ReminderCategory.appointment: return Icons.event_available_rounded;
      case ReminderCategory.quote: return Icons.request_quote_rounded;
      case ReminderCategory.invoice: return Icons.receipt_long_rounded;
      case ReminderCategory.transaction: return Icons.swap_horiz_rounded;
      case ReminderCategory.revenue: return Icons.trending_up_rounded;
      case ReminderCategory.recurring: return Icons.repeat_rounded;
      case ReminderCategory.debt: return Icons.account_balance_wallet_rounded;
      case ReminderCategory.document: return Icons.folder_rounded;
      case ReminderCategory.expense: return Icons.money_off_rounded;
      case ReminderCategory.tax: return Icons.calculate_rounded;
      case ReminderCategory.credit: return Icons.credit_score_rounded;
      case ReminderCategory.employee: return Icons.badge_rounded;
      case ReminderCategory.payroll: return Icons.payments_rounded;
      case ReminderCategory.purchaseOrder: return Icons.shopping_cart_rounded;
      case ReminderCategory.tender: return Icons.gavel_rounded;
      case ReminderCategory.general: return Icons.notifications_rounded;
    }
  }

  static ReminderCategory fromString(String? s) {
    if (s == null) return ReminderCategory.general;
    return ReminderCategory.values.firstWhere(
      (v) => v.name == s,
      orElse: () => ReminderCategory.general,
    );
  }
}

// ── ReminderRepeat ────────────────────────────────────────────────────────

enum ReminderRepeat {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case ReminderRepeat.none: return 'Hakuna';
      case ReminderRepeat.daily: return 'Kila Siku';
      case ReminderRepeat.weekly: return 'Kila Wiki';
      case ReminderRepeat.monthly: return 'Kila Mwezi';
      case ReminderRepeat.yearly: return 'Kila Mwaka';
    }
  }

  String get subtitle {
    switch (this) {
      case ReminderRepeat.none: return 'None';
      case ReminderRepeat.daily: return 'Daily';
      case ReminderRepeat.weekly: return 'Weekly';
      case ReminderRepeat.monthly: return 'Monthly';
      case ReminderRepeat.yearly: return 'Yearly';
    }
  }

  static ReminderRepeat fromString(String? s) {
    if (s == null) return ReminderRepeat.none;
    return ReminderRepeat.values.firstWhere(
      (v) => v.name == s,
      orElse: () => ReminderRepeat.none,
    );
  }
}

// ── ReminderItem ──────────────────────────────────────────────────────────

class ReminderItem {
  final String id;
  final String title;
  final String? subtitle;
  final DateTime dueAt;
  final ReminderCategory category;
  final ReminderRepeat repeat;
  final bool isDone;
  final bool isStandalone;
  final String? sourceRoute;

  const ReminderItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.dueAt,
    required this.category,
    this.repeat = ReminderRepeat.none,
    this.isDone = false,
    required this.isStandalone,
    this.sourceRoute,
    // Stub-only — accepted by callers, not stored on the model yet.
    // ignore: unused_element_parameter
    Object? serverId,
    // ignore: unused_element_parameter
    Object? eventKind,
  });

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      dueAt: DateTime.tryParse(json['due_at']?.toString() ?? '') ?? DateTime.now(),
      category: ReminderCategory.fromString(json['category']?.toString()),
      repeat: ReminderRepeat.fromString(json['repeat']?.toString()),
      isDone: _parseBool(json['is_done']),
      isStandalone: _parseBool(json['is_standalone']),
      sourceRoute: json['source_route']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'due_at': dueAt.toIso8601String(),
    'category': category.name,
    'repeat': repeat.name,
    'is_done': isDone ? 1 : 0,
    'is_standalone': isStandalone ? 1 : 0,
    'source_route': sourceRoute,
  };

  ReminderItem copyWith({
    String? id,
    String? title,
    Object? subtitle = _kSentinel,
    DateTime? dueAt,
    ReminderCategory? category,
    ReminderRepeat? repeat,
    bool? isDone,
    bool? isStandalone,
    Object? sourceRoute = _kSentinel,
    // Stub-only — accepted by callers, not stored on the model yet.
    // ignore: unused_element_parameter
    Object? serverId,
    // ignore: unused_element_parameter
    Object? eventKind,
  }) {
    return ReminderItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle == _kSentinel ? this.subtitle : subtitle as String?,
      dueAt: dueAt ?? this.dueAt,
      category: category ?? this.category,
      repeat: repeat ?? this.repeat,
      isDone: isDone ?? this.isDone,
      isStandalone: isStandalone ?? this.isStandalone,
      sourceRoute: sourceRoute == _kSentinel ? this.sourceRoute : sourceRoute as String?,
    );
  }
}

// ── Result wrappers ───────────────────────────────────────────────────────

class ReminderResult<T> {
  final bool success;
  final T? data;
  final String? message;
  ReminderResult({required this.success, this.data, this.message});
}

class ReminderListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  ReminderListResult({required this.success, this.items = const [], this.message});
}

// Stub compat getters — referenced by reminder pages but not on the canonical
// model yet. Real fields land when the API exposes them.
extension ReminderItemCompat on ReminderItem {
  String? get eventKind => null;
  String? get serverId => null;
}

extension ReminderCategoryLocale on ReminderCategory {
  // Stub — until per-locale labels land, return the Swahili displayName for
  // both locales (existing behavior). Callers pass `swahili: true|false`.
  String labelForLocale({bool swahili = false}) => displayName;
}
