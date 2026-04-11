// lib/my_circle/models/my_circle_models.dart
import 'package:flutter/material.dart';

// ─── Flow Intensity ────────────────────────────────────────────

enum FlowIntensity {
  none,
  spotting,
  light,
  medium,
  heavy;

  String displayName(bool isSwahili) {
    switch (this) {
      case FlowIntensity.none: return isSwahili ? 'Hakuna' : 'None';
      case FlowIntensity.spotting: return isSwahili ? 'Matone' : 'Spotting';
      case FlowIntensity.light: return isSwahili ? 'Kidogo' : 'Light';
      case FlowIntensity.medium: return isSwahili ? 'Wastani' : 'Medium';
      case FlowIntensity.heavy: return isSwahili ? 'Nyingi' : 'Heavy';
    }
  }

  Color get color {
    switch (this) {
      case FlowIntensity.none: return const Color(0xFFE0E0E0);
      case FlowIntensity.spotting: return const Color(0xFFEF9A9A);
      case FlowIntensity.light: return const Color(0xFFE57373);
      case FlowIntensity.medium: return const Color(0xFFEF5350);
      case FlowIntensity.heavy: return const Color(0xFFC62828);
    }
  }

  static FlowIntensity fromString(String? s) {
    return FlowIntensity.values.firstWhere((v) => v.name == s, orElse: () => FlowIntensity.none);
  }
}

// ─── Symptom ───────────────────────────────────────────────────

enum Symptom {
  cramps,
  headache,
  backache,
  breastTenderness,
  bloating,
  nausea,
  fatigue,
  moodSwings,
  acne,
  cravings;

  String displayName([bool isSwahili = true]) {
    switch (this) {
      case Symptom.cramps: return isSwahili ? 'Maumivu ya tumbo' : 'Cramps';
      case Symptom.headache: return isSwahili ? 'Maumivu ya kichwa' : 'Headache';
      case Symptom.backache: return isSwahili ? 'Maumivu ya mgongo' : 'Backache';
      case Symptom.breastTenderness: return isSwahili ? 'Maumivu ya matiti' : 'Breast tenderness';
      case Symptom.bloating: return isSwahili ? 'Kuvimba tumbo' : 'Bloating';
      case Symptom.nausea: return isSwahili ? 'Kichefuchefu' : 'Nausea';
      case Symptom.fatigue: return isSwahili ? 'Uchovu' : 'Fatigue';
      case Symptom.moodSwings: return isSwahili ? 'Mabadiliko ya hisia' : 'Mood swings';
      case Symptom.acne: return isSwahili ? 'Chunusi' : 'Acne';
      case Symptom.cravings: return isSwahili ? 'Hamu ya chakula' : 'Cravings';
    }
  }

  IconData get icon {
    switch (this) {
      case Symptom.cramps: return Icons.whatshot_rounded;
      case Symptom.headache: return Icons.psychology_rounded;
      case Symptom.backache: return Icons.accessibility_new_rounded;
      case Symptom.breastTenderness: return Icons.favorite_rounded;
      case Symptom.bloating: return Icons.circle_rounded;
      case Symptom.nausea: return Icons.sick_rounded;
      case Symptom.fatigue: return Icons.battery_1_bar_rounded;
      case Symptom.moodSwings: return Icons.mood_rounded;
      case Symptom.acne: return Icons.face_rounded;
      case Symptom.cravings: return Icons.restaurant_rounded;
    }
  }

  static Symptom? fromString(String? s) {
    if (s == null) return null;
    return Symptom.values.cast<Symptom?>().firstWhere((v) => v!.name == s, orElse: () => null);
  }
}

// ─── Mood ──────────────────────────────────────────────────────

enum Mood {
  happy,
  calm,
  sad,
  anxious,
  irritable,
  energetic;

  String displayName([bool isSwahili = true]) {
    switch (this) {
      case Mood.happy: return isSwahili ? 'Furaha' : 'Happy';
      case Mood.calm: return isSwahili ? 'Utulivu' : 'Calm';
      case Mood.sad: return isSwahili ? 'Huzuni' : 'Sad';
      case Mood.anxious: return isSwahili ? 'Wasiwasi' : 'Anxious';
      case Mood.irritable: return isSwahili ? 'Hasira' : 'Irritable';
      case Mood.energetic: return isSwahili ? 'Nguvu' : 'Energetic';
    }
  }

  String get emoji {
    switch (this) {
      case Mood.happy: return '\u{1F60A}';
      case Mood.calm: return '\u{1F60C}';
      case Mood.sad: return '\u{1F622}';
      case Mood.anxious: return '\u{1F630}';
      case Mood.irritable: return '\u{1F620}';
      case Mood.energetic: return '\u{1F4AA}';
    }
  }

  static Mood? fromString(String? s) {
    if (s == null) return null;
    return Mood.values.cast<Mood?>().firstWhere((v) => v!.name == s, orElse: () => null);
  }
}

// ─── Contraception Type ────────────────────────────────────────

enum ContraceptionType {
  pill,
  injectable,
  iud,
  condom,
  natural,
  implant;

  String displayName([bool isSwahili = true]) {
    switch (this) {
      case ContraceptionType.pill: return isSwahili ? 'Vidonge' : 'Pill';
      case ContraceptionType.injectable: return isSwahili ? 'Sindano (Depo)' : 'Injectable (Depo)';
      case ContraceptionType.iud: return isSwahili ? 'Kitanzi (IUD)' : 'IUD';
      case ContraceptionType.condom: return isSwahili ? 'Kondomu' : 'Condom';
      case ContraceptionType.natural: return isSwahili ? 'Njia ya asili' : 'Natural method';
      case ContraceptionType.implant: return isSwahili ? 'Kipandikizi' : 'Implant';
    }
  }

  IconData get icon {
    switch (this) {
      case ContraceptionType.pill: return Icons.medication_rounded;
      case ContraceptionType.injectable: return Icons.vaccines_rounded;
      case ContraceptionType.iud: return Icons.shield_rounded;
      case ContraceptionType.condom: return Icons.health_and_safety_rounded;
      case ContraceptionType.natural: return Icons.calendar_month_rounded;
      case ContraceptionType.implant: return Icons.back_hand_rounded;
    }
  }

  int get defaultIntervalDays {
    switch (this) {
      case ContraceptionType.pill: return 1;
      case ContraceptionType.injectable: return 84;
      case ContraceptionType.iud: return 1825;
      case ContraceptionType.condom: return 0;
      case ContraceptionType.natural: return 0;
      case ContraceptionType.implant: return 1095;
    }
  }

  static ContraceptionType fromString(String? s) {
    return ContraceptionType.values.firstWhere((v) => v.name == s, orElse: () => ContraceptionType.pill);
  }
}

// ─── CycleDay ──────────────────────────────────────────────────

class CycleDay {
  final int? id;
  final int userId;
  final DateTime date;
  final FlowIntensity flowIntensity;
  final List<Symptom> symptoms;
  final Mood? mood;
  final String? notes;

  CycleDay({
    this.id,
    required this.userId,
    required this.date,
    this.flowIntensity = FlowIntensity.none,
    this.symptoms = const [],
    this.mood,
    this.notes,
  });

  factory CycleDay.fromJson(Map<String, dynamic> json) {
    return CycleDay(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      flowIntensity: FlowIntensity.fromString(json['flow_intensity']),
      symptoms: (json['symptoms'] as List?)
              ?.map((s) => Symptom.fromString(s as String?))
              .whereType<Symptom>()
              .toList() ??
          [],
      mood: Mood.fromString(json['mood']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'flow_intensity': flowIntensity.name,
        'symptoms': symptoms.map((s) => s.name).toList(),
        if (mood != null) 'mood': mood!.name,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };

  bool get hasPeriod => flowIntensity != FlowIntensity.none;
}

// ─── CyclePrediction ───────────────────────────────────────────

class CyclePrediction {
  final DateTime? nextPeriodDate;
  final DateTime? fertileWindowStart;
  final DateTime? fertileWindowEnd;
  final DateTime? ovulationDate;
  final int cycleLength;
  final int periodLength;
  final int totalCyclesLogged;

  CyclePrediction({
    this.nextPeriodDate,
    this.fertileWindowStart,
    this.fertileWindowEnd,
    this.ovulationDate,
    this.cycleLength = 28,
    this.periodLength = 5,
    this.totalCyclesLogged = 0,
  });

  factory CyclePrediction.fromJson(Map<String, dynamic> json) {
    return CyclePrediction(
      nextPeriodDate: json['next_period_date'] != null ? DateTime.tryParse(json['next_period_date']) : null,
      fertileWindowStart: json['fertile_window_start'] != null ? DateTime.tryParse(json['fertile_window_start']) : null,
      fertileWindowEnd: json['fertile_window_end'] != null ? DateTime.tryParse(json['fertile_window_end']) : null,
      ovulationDate: json['ovulation_date'] != null ? DateTime.tryParse(json['ovulation_date']) : null,
      cycleLength: (json['cycle_length'] as num?)?.toInt() ?? 28,
      periodLength: (json['period_length'] as num?)?.toInt() ?? 5,
      totalCyclesLogged: (json['total_cycles_logged'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasData => nextPeriodDate != null;

  int get daysUntilNextPeriod {
    if (nextPeriodDate == null) return -1;
    return nextPeriodDate!.difference(DateTime.now()).inDays;
  }

  bool get isFertileToday {
    if (fertileWindowStart == null || fertileWindowEnd == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !today.isBefore(fertileWindowStart!) && !today.isAfter(fertileWindowEnd!);
  }
}

// ─── ContraceptionReminder ─────────────────────────────────────

class ContraceptionReminder {
  final int? id;
  final int userId;
  final ContraceptionType type;
  final DateTime startDate;
  final DateTime? nextDueDate;
  final int intervalDays;

  ContraceptionReminder({
    this.id,
    required this.userId,
    required this.type,
    required this.startDate,
    this.nextDueDate,
    required this.intervalDays,
  });

  factory ContraceptionReminder.fromJson(Map<String, dynamic> json) {
    return ContraceptionReminder(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      type: ContraceptionType.fromString(json['type']),
      startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
      nextDueDate: json['next_due_date'] != null ? DateTime.tryParse(json['next_due_date']) : null,
      intervalDays: (json['interval_days'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isDueToday {
    if (nextDueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate!.year, nextDueDate!.month, nextDueDate!.day);
    return today == due;
  }

  bool get isOverdue {
    if (nextDueDate == null) return false;
    return DateTime.now().isAfter(nextDueDate!);
  }

  int get daysUntilDue {
    if (nextDueDate == null) return -1;
    return nextDueDate!.difference(DateTime.now()).inDays;
  }
}

// ─── CycleStats ────────────────────────────────────────────────

class CycleStats {
  final double averageCycleLength;
  final double averagePeriodLength;
  final int longestCycle;
  final int shortestCycle;
  final int totalCyclesLogged;
  final List<int> cycleLengthHistory;
  final Map<String, int> symptomFrequency;
  final Map<String, int> moodFrequency;

  CycleStats({
    this.averageCycleLength = 28,
    this.averagePeriodLength = 5,
    this.longestCycle = 0,
    this.shortestCycle = 0,
    this.totalCyclesLogged = 0,
    this.cycleLengthHistory = const [],
    this.symptomFrequency = const {},
    this.moodFrequency = const {},
  });

  factory CycleStats.fromJson(Map<String, dynamic> json) {
    return CycleStats(
      averageCycleLength: (json['average_cycle_length'] as num?)?.toDouble() ?? 28,
      averagePeriodLength: (json['average_period_length'] as num?)?.toDouble() ?? 5,
      longestCycle: (json['longest_cycle'] as num?)?.toInt() ?? 0,
      shortestCycle: (json['shortest_cycle'] as num?)?.toInt() ?? 0,
      totalCyclesLogged: (json['total_cycles_logged'] as num?)?.toInt() ?? 0,
      cycleLengthHistory: (json['cycle_length_history'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [],
      symptomFrequency: (json['symptom_frequency'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num).toInt())) ?? {},
      moodFrequency: (json['mood_frequency'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num).toInt())) ?? {},
    );
  }

  bool get isAbnormal => longestCycle > 0 && shortestCycle > 0 && (longestCycle - shortestCycle) > 10;
}

// ─── Result wrappers ───────────────────────────────────────────

class CircleResult<T> {
  final bool success;
  final T? data;
  final String? message;
  CircleResult({required this.success, this.data, this.message});
}

class CircleListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  CircleListResult({required this.success, this.items = const [], this.message});
}
