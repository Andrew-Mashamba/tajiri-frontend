// lib/wakati_wa_sala/models/wakati_wa_sala_models.dart

// ─── Calculation Methods ──────────────────────────────────────
enum CalculationMethod {
  egyptian,
  mwl,
  ummAlQura,
  isna;

  String get displayName {
    switch (this) {
      case CalculationMethod.egyptian:
        return 'Egyptian General Authority';
      case CalculationMethod.mwl:
        return 'Muslim World League';
      case CalculationMethod.ummAlQura:
        return 'Umm al-Qura (Makkah)';
      case CalculationMethod.isna:
        return 'ISNA (North America)';
    }
  }
}

// ─── Prayer Status ────────────────────────────────────────────
enum PrayerStatus {
  pending,
  onTime,
  late_,
  qada,
  missed;

  String get label {
    switch (this) {
      case PrayerStatus.pending:
        return 'Pending / Inasubiri';
      case PrayerStatus.onTime:
        return 'On time / Kwa wakati';
      case PrayerStatus.late_:
        return 'Late / Imechelewa';
      case PrayerStatus.qada:
        return 'Qadha';
      case PrayerStatus.missed:
        return 'Missed / Imekosa';
    }
  }
}

// ─── Single Prayer Time ───────────────────────────────────────
class PrayerTime {
  final String name;
  final String nameSwahili;
  final String time;
  final PrayerStatus status;
  final String? iqamahTime;

  PrayerTime({
    required this.name,
    required this.nameSwahili,
    required this.time,
    this.status = PrayerStatus.pending,
    this.iqamahTime,
  });

  factory PrayerTime.fromJson(Map<String, dynamic> json) {
    return PrayerTime(
      name: json['name']?.toString() ?? '',
      nameSwahili: json['name_sw']?.toString() ?? '',
      time: json['time']?.toString() ?? '--:--',
      status: _parsePrayerStatus(json['status']),
      iqamahTime: json['iqamah_time']?.toString(),
    );
  }
}

// ─── Daily Prayer Schedule ────────────────────────────────────
class DailyPrayerSchedule {
  final String date;
  final String hijriDate;
  final double latitude;
  final double longitude;
  final String location;
  final List<PrayerTime> prayers;
  final String? sunrise;
  final String? tahajjud;

  DailyPrayerSchedule({
    required this.date,
    required this.hijriDate,
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.prayers,
    this.sunrise,
    this.tahajjud,
  });

  factory DailyPrayerSchedule.fromJson(Map<String, dynamic> json) {
    return DailyPrayerSchedule(
      date: json['date']?.toString() ?? '',
      hijriDate: json['hijri_date']?.toString() ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      location: json['location']?.toString() ?? '',
      prayers: (json['prayers'] as List?)
              ?.map((p) => PrayerTime.fromJson(p))
              .toList() ??
          [],
      sunrise: json['sunrise']?.toString(),
      tahajjud: json['tahajjud']?.toString(),
    );
  }
}

// ─── Prayer Log Entry ─────────────────────────────────────────
class PrayerLogEntry {
  final int id;
  final String prayerName;
  final String date;
  final PrayerStatus status;
  final String? note;
  final DateTime? loggedAt;

  PrayerLogEntry({
    required this.id,
    required this.prayerName,
    required this.date,
    required this.status,
    this.note,
    this.loggedAt,
  });

  factory PrayerLogEntry.fromJson(Map<String, dynamic> json) {
    return PrayerLogEntry(
      id: _parseInt(json['id']),
      prayerName: json['prayer_name']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      status: _parsePrayerStatus(json['status']),
      note: json['note']?.toString(),
      loggedAt: json['logged_at'] != null
          ? DateTime.tryParse(json['logged_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'prayer_name': prayerName,
        'date': date,
        'status': status.name,
        if (note != null) 'note': note,
      };
}

// ─── Prayer Stats ─────────────────────────────────────────────
class PrayerStats {
  final int totalPrayers;
  final int onTimeCount;
  final int lateCount;
  final int missedCount;
  final int currentStreak;
  final int longestStreak;
  final double completionRate;

  PrayerStats({
    required this.totalPrayers,
    required this.onTimeCount,
    required this.lateCount,
    required this.missedCount,
    required this.currentStreak,
    required this.longestStreak,
    required this.completionRate,
  });

  factory PrayerStats.fromJson(Map<String, dynamic> json) {
    return PrayerStats(
      totalPrayers: _parseInt(json['total_prayers']),
      onTimeCount: _parseInt(json['on_time_count']),
      lateCount: _parseInt(json['late_count']),
      missedCount: _parseInt(json['missed_count']),
      currentStreak: _parseInt(json['current_streak']),
      longestStreak: _parseInt(json['longest_streak']),
      completionRate: _parseDouble(json['completion_rate']),
    );
  }
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

PrayerStatus _parsePrayerStatus(dynamic v) {
  final s = v?.toString().toLowerCase() ?? '';
  switch (s) {
    case 'on_time':
      return PrayerStatus.onTime;
    case 'late':
      return PrayerStatus.late_;
    case 'qada':
      return PrayerStatus.qada;
    case 'missed':
      return PrayerStatus.missed;
    default:
      return PrayerStatus.pending;
  }
}
