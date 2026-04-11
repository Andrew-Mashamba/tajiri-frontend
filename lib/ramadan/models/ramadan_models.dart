// lib/ramadan/models/ramadan_models.dart

// ─── Ramadan Day ──────────────────────────────────────────────
class RamadanDay {
  final int dayNumber;
  final String date;
  final String hijriDate;
  final String suhoorTime;
  final String iftarTime;
  final bool isFasted;
  final String? dailyDua;
  final String? dailyDuaSwahili;

  RamadanDay({
    required this.dayNumber,
    required this.date,
    required this.hijriDate,
    required this.suhoorTime,
    required this.iftarTime,
    this.isFasted = false,
    this.dailyDua,
    this.dailyDuaSwahili,
  });

  factory RamadanDay.fromJson(Map<String, dynamic> json) {
    return RamadanDay(
      dayNumber: _parseInt(json['day_number']),
      date: json['date']?.toString() ?? '',
      hijriDate: json['hijri_date']?.toString() ?? '',
      suhoorTime: json['suhoor_time']?.toString() ?? '--:--',
      iftarTime: json['iftar_time']?.toString() ?? '--:--',
      isFasted: _parseBool(json['is_fasted']),
      dailyDua: json['daily_dua']?.toString(),
      dailyDuaSwahili: json['daily_dua_sw']?.toString(),
    );
  }
}

// ─── Ramadan Overview ─────────────────────────────────────────
class RamadanOverview {
  final int currentDay;
  final int totalDays;
  final int daysRemaining;
  final int fastedDays;
  final String suhoorToday;
  final String iftarToday;
  final String? todayDua;
  final String? todayDuaSwahili;
  final double quranProgress; // 0-1

  RamadanOverview({
    required this.currentDay,
    required this.totalDays,
    required this.daysRemaining,
    required this.fastedDays,
    required this.suhoorToday,
    required this.iftarToday,
    this.todayDua,
    this.todayDuaSwahili,
    this.quranProgress = 0,
  });

  factory RamadanOverview.fromJson(Map<String, dynamic> json) {
    return RamadanOverview(
      currentDay: _parseInt(json['current_day']),
      totalDays: _parseInt(json['total_days']),
      daysRemaining: _parseInt(json['days_remaining']),
      fastedDays: _parseInt(json['fasted_days']),
      suhoorToday: json['suhoor_today']?.toString() ?? '--:--',
      iftarToday: json['iftar_today']?.toString() ?? '--:--',
      todayDua: json['today_dua']?.toString(),
      todayDuaSwahili: json['today_dua_sw']?.toString(),
      quranProgress: _parseDouble(json['quran_progress']),
    );
  }
}

// ─── Taraweeh Log ─────────────────────────────────────────────
class TaraweehLog {
  final int id;
  final String date;
  final int rakaat;
  final String? mosqueName;

  TaraweehLog({
    required this.id,
    required this.date,
    required this.rakaat,
    this.mosqueName,
  });

  factory TaraweehLog.fromJson(Map<String, dynamic> json) {
    return TaraweehLog(
      id: _parseInt(json['id']),
      date: json['date']?.toString() ?? '',
      rakaat: _parseInt(json['rakaat']),
      mosqueName: json['mosque_name']?.toString(),
    );
  }
}

// ─── Ramadan Goal ─────────────────────────────────────────────
class RamadanGoal {
  final int id;
  final String title;
  final String titleSwahili;
  final String category; // prayer, quran, charity, fasting
  final int target;
  final int progress;
  final bool completed;

  RamadanGoal({
    required this.id,
    required this.title,
    required this.titleSwahili,
    required this.category,
    required this.target,
    required this.progress,
    this.completed = false,
  });

  factory RamadanGoal.fromJson(Map<String, dynamic> json) {
    return RamadanGoal(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      titleSwahili: json['title_sw']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      target: _parseInt(json['target']),
      progress: _parseInt(json['progress']),
      completed: _parseBool(json['completed']),
    );
  }

  double get progressRate =>
      target > 0 ? (progress / target).clamp(0.0, 1.0) : 0;
}

// ─── Result Wrappers ──────────────────────────────────────────
class SingleResult<T> {
  final bool success;
  final T? data;
  final String? message;
  SingleResult({required this.success, this.data, this.message});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? message;
  PaginatedResult({
    required this.success,
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.message,
  });
}

// ─── Parse Helpers ────────────────────────────────────────────
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
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}
