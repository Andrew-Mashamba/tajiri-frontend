// lib/events/models/recurrence_rule.dart
import 'event_enums.dart';

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class RecurrenceRule {
  final RecurrenceFrequency frequency;
  final int interval;
  final List<int>? daysOfWeek;
  final int? dayOfMonth;
  final DateTime? until;
  final int? count;

  RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.daysOfWeek,
    this.dayOfMonth,
    this.until,
    this.count,
  });

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.fromApi(json['frequency']?.toString()),
      interval: json['interval'] != null ? _parseInt(json['interval']) : 1,
      daysOfWeek: (json['days_of_week'] as List?)?.map((e) => _parseInt(e)).toList(),
      dayOfMonth: json['day_of_month'] != null ? _parseInt(json['day_of_month']) : null,
      until: json['until'] != null ? DateTime.tryParse(json['until'].toString()) : null,
      count: json['count'] != null ? _parseInt(json['count']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'frequency': frequency.name,
    'interval': interval,
    if (daysOfWeek != null) 'days_of_week': daysOfWeek,
    if (dayOfMonth != null) 'day_of_month': dayOfMonth,
    if (until != null) 'until': until!.toIso8601String().split('T').first,
    if (count != null) 'count': count,
  };
}
