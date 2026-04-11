// lib/calendar/models/calendar_models.dart
import 'package:flutter/material.dart';

// ─── Event Source ──────────────────────────────────────────────

enum EventSource {
  personal,
  family,
  business,
  doctor,
  vaccination;

  String get displayName {
    switch (this) {
      case EventSource.personal:
        return 'Binafsi';
      case EventSource.family:
        return 'Familia';
      case EventSource.business:
        return 'Biashara';
      case EventSource.doctor:
        return 'Daktari';
      case EventSource.vaccination:
        return 'Chanjo';
    }
  }

  String get subtitle {
    switch (this) {
      case EventSource.personal:
        return 'Personal';
      case EventSource.family:
        return 'Family';
      case EventSource.business:
        return 'Business';
      case EventSource.doctor:
        return 'Doctor';
      case EventSource.vaccination:
        return 'Vaccination';
    }
  }

  IconData get icon {
    switch (this) {
      case EventSource.personal:
        return Icons.person_rounded;
      case EventSource.family:
        return Icons.family_restroom_rounded;
      case EventSource.business:
        return Icons.business_center_rounded;
      case EventSource.doctor:
        return Icons.local_hospital_rounded;
      case EventSource.vaccination:
        return Icons.vaccines_rounded;
    }
  }

  Color get dotColor {
    switch (this) {
      case EventSource.personal:
        return const Color(0xFF1A1A1A);
      case EventSource.family:
        return const Color(0xFF5C6BC0);
      case EventSource.business:
        return const Color(0xFF00897B);
      case EventSource.doctor:
        return const Color(0xFFE53935);
      case EventSource.vaccination:
        return const Color(0xFFFFA726);
    }
  }

  static EventSource fromString(String? s) {
    return EventSource.values.firstWhere(
      (v) => v.name == s,
      orElse: () => EventSource.personal,
    );
  }
}

// ─── Event Repeat ─────────────────────────────────────────────

enum EventRepeat {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case EventRepeat.none:
        return 'Hakuna';
      case EventRepeat.daily:
        return 'Kila Siku';
      case EventRepeat.weekly:
        return 'Kila Wiki';
      case EventRepeat.monthly:
        return 'Kila Mwezi';
      case EventRepeat.yearly:
        return 'Kila Mwaka';
    }
  }

  String get subtitle {
    switch (this) {
      case EventRepeat.none:
        return 'None';
      case EventRepeat.daily:
        return 'Daily';
      case EventRepeat.weekly:
        return 'Weekly';
      case EventRepeat.monthly:
        return 'Monthly';
      case EventRepeat.yearly:
        return 'Yearly';
    }
  }

  static EventRepeat fromString(String? s) {
    return EventRepeat.values.firstWhere(
      (v) => v.name == s,
      orElse: () => EventRepeat.none,
    );
  }
}

// ─── Event Reminder ───────────────────────────────────────────

enum EventReminder {
  none,
  min5,
  min15,
  min30,
  hour1,
  day1;

  String get displayName {
    switch (this) {
      case EventReminder.none:
        return 'Hakuna';
      case EventReminder.min5:
        return 'Dakika 5 kabla';
      case EventReminder.min15:
        return 'Dakika 15 kabla';
      case EventReminder.min30:
        return 'Dakika 30 kabla';
      case EventReminder.hour1:
        return 'Saa 1 kabla';
      case EventReminder.day1:
        return 'Siku 1 kabla';
    }
  }

  String get subtitle {
    switch (this) {
      case EventReminder.none:
        return 'None';
      case EventReminder.min5:
        return '5 min before';
      case EventReminder.min15:
        return '15 min before';
      case EventReminder.min30:
        return '30 min before';
      case EventReminder.hour1:
        return '1 hour before';
      case EventReminder.day1:
        return '1 day before';
    }
  }

  static EventReminder fromString(String? s) {
    return EventReminder.values.firstWhere(
      (v) => v.name == s,
      orElse: () => EventReminder.none,
    );
  }
}

// ─── Calendar Event ───────────────────────────────────────────

class CalendarEvent {
  final int id;
  final int userId;
  final String title;
  final DateTime date;
  final String? startTime;
  final String? endTime;
  final bool isAllDay;
  final String? color;
  final EventRepeat repeat;
  final EventReminder reminder;
  final String? notes;
  final EventSource source;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CalendarEvent({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.color,
    this.repeat = EventRepeat.none,
    this.reminder = EventReminder.none,
    this.notes,
    this.source = EventSource.personal,
    this.createdAt,
    this.updatedAt,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      title: json['title'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      startTime: json['start_time'],
      endTime: json['end_time'],
      isAllDay: _parseBool(json['is_all_day']),
      color: json['color'],
      repeat: EventRepeat.fromString(json['repeat']),
      reminder: EventReminder.fromString(json['reminder']),
      notes: json['notes'],
      source: EventSource.fromString(json['source']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'title': title,
        'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'start_time': startTime,
        'end_time': endTime,
        'is_all_day': isAllDay,
        'color': color,
        'repeat': repeat.name,
        'reminder': reminder.name,
        'notes': notes,
        'source': source.name,
      };
}

// ─── Result wrappers ──────────────────────────────────────────

class CalendarResult<T> {
  final bool success;
  final T? data;
  final String? message;
  CalendarResult({required this.success, this.data, this.message});
}

class CalendarListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  CalendarListResult(
      {required this.success, this.items = const [], this.message});
}

// ─── Parse helpers ────────────────────────────────────────────

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v == 'true';
  return false;
}
