// lib/my_pregnancy/models/my_pregnancy_models.dart

// ─── Pregnancy ─────────────────────────────────────────────────

class Pregnancy {
  final int id;
  final int userId;
  final DateTime? dueDate;
  final DateTime? lastPeriodDate;
  final int currentWeek;
  final int trimester;
  final String status; // active, delivered, lost
  final String? babyName;
  final String? deliveryType; // normal, caesarean
  final DateTime? deliveryDate;
  final int? babyWeightGrams;
  final String? babyGender; // male, female, unknown
  final double? prePregnancyWeightKg;
  final DateTime? createdAt;

  Pregnancy({
    required this.id,
    required this.userId,
    this.dueDate,
    this.lastPeriodDate,
    this.currentWeek = 1,
    this.trimester = 1,
    this.status = 'active',
    this.babyName,
    this.deliveryType,
    this.deliveryDate,
    this.babyWeightGrams,
    this.babyGender,
    this.prePregnancyWeightKg,
    this.createdAt,
  });

  factory Pregnancy.fromJson(Map<String, dynamic> json) {
    return Pregnancy(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      dueDate: _parseDate(json['due_date']),
      lastPeriodDate: _parseDate(json['last_period_date']),
      currentWeek: _parseInt(json['current_week'], fallback: 1),
      trimester: _parseInt(json['trimester'], fallback: 1),
      status: json['status'] as String? ?? 'active',
      babyName: json['baby_name'] as String?,
      deliveryType: json['delivery_type'] as String?,
      deliveryDate: _parseDate(json['delivery_date']),
      babyWeightGrams: json['baby_weight_grams'] != null
          ? _parseInt(json['baby_weight_grams'])
          : null,
      babyGender: json['baby_gender'] as String?,
      prePregnancyWeightKg: json['pre_pregnancy_weight_kg'] != null
          ? _parseDouble(json['pre_pregnancy_weight_kg'])
          : null,
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
        if (lastPeriodDate != null)
          'last_period_date': lastPeriodDate!.toIso8601String(),
        if (babyName != null) 'baby_name': babyName,
        if (babyGender != null) 'baby_gender': babyGender,
        if (prePregnancyWeightKg != null)
          'pre_pregnancy_weight_kg': prePregnancyWeightKg,
      };

  bool get isActive => status == 'active';
  bool get isDelivered => status == 'delivered';

  int get daysRemaining {
    if (dueDate == null) return 0;
    final diff = dueDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  String trimesterLabel({bool isSwahili = true}) {
    if (isSwahili) {
      switch (trimester) {
        case 1:
          return 'Trimesta ya Kwanza';
        case 2:
          return 'Trimesta ya Pili';
        case 3:
          return 'Trimesta ya Tatu';
        default:
          return 'Trimesta ya $trimester';
      }
    } else {
      switch (trimester) {
        case 1:
          return 'First Trimester';
        case 2:
          return 'Second Trimester';
        case 3:
          return 'Third Trimester';
        default:
          return 'Trimester $trimester';
      }
    }
  }
}

// ─── Week Info ─────────────────────────────────────────────────

class WeekInfo {
  final int weekNumber;
  final String babySizeComparison;
  final double babyLengthCm;
  final double babyWeightGrams;
  final String developmentSummary;
  final String motherTips;
  final List<String> checklist;

  WeekInfo({
    required this.weekNumber,
    required this.babySizeComparison,
    this.babyLengthCm = 0,
    this.babyWeightGrams = 0,
    this.developmentSummary = '',
    this.motherTips = '',
    this.checklist = const [],
  });

  factory WeekInfo.fromJson(Map<String, dynamic> json) {
    return WeekInfo(
      weekNumber: _parseInt(json['week_number']),
      babySizeComparison: json['baby_size_comparison'] as String? ?? '',
      babyLengthCm: _parseDouble(json['baby_length_cm']),
      babyWeightGrams: _parseDouble(json['baby_weight_grams']),
      developmentSummary: json['development_summary'] as String? ?? '',
      motherTips: json['mother_tips'] as String? ?? '',
      checklist: (json['checklist'] as List?)?.cast<String>() ?? [],
    );
  }
}

// ─── Pregnancy Symptoms ────────────────────────────────────────

enum PregnancySymptom {
  nausea,
  fatigue,
  backPain,
  swelling,
  heartburn,
  headache,
  cramps,
  bleeding,
  highFever;

  String get swahiliName {
    switch (this) {
      case PregnancySymptom.nausea:
        return 'Kichefuchefu';
      case PregnancySymptom.fatigue:
        return 'Uchovu';
      case PregnancySymptom.backPain:
        return 'Maumivu ya Mgongo';
      case PregnancySymptom.swelling:
        return 'Kuvimba';
      case PregnancySymptom.heartburn:
        return 'Kiungulia';
      case PregnancySymptom.headache:
        return 'Maumivu ya Kichwa';
      case PregnancySymptom.cramps:
        return 'Maumivu ya Tumbo';
      case PregnancySymptom.bleeding:
        return 'Kutoka Damu';
      case PregnancySymptom.highFever:
        return 'Homa Kali';
    }
  }

  String get englishName {
    switch (this) {
      case PregnancySymptom.nausea:
        return 'Nausea';
      case PregnancySymptom.fatigue:
        return 'Fatigue';
      case PregnancySymptom.backPain:
        return 'Back Pain';
      case PregnancySymptom.swelling:
        return 'Swelling';
      case PregnancySymptom.heartburn:
        return 'Heartburn';
      case PregnancySymptom.headache:
        return 'Headache';
      case PregnancySymptom.cramps:
        return 'Cramps';
      case PregnancySymptom.bleeding:
        return 'Bleeding';
      case PregnancySymptom.highFever:
        return 'High Fever';
    }
  }

  String displayName({bool isSwahili = true}) =>
      isSwahili ? swahiliName : englishName;

  bool get isDanger {
    switch (this) {
      case PregnancySymptom.bleeding:
      case PregnancySymptom.headache:
      case PregnancySymptom.highFever:
        return true;
      default:
        return false;
    }
  }

  String get icon {
    switch (this) {
      case PregnancySymptom.nausea:
        return '🤢';
      case PregnancySymptom.fatigue:
        return '😴';
      case PregnancySymptom.backPain:
        return '🔙';
      case PregnancySymptom.swelling:
        return '🦶';
      case PregnancySymptom.heartburn:
        return '🔥';
      case PregnancySymptom.headache:
        return '🤕';
      case PregnancySymptom.cramps:
        return '⚡';
      case PregnancySymptom.bleeding:
        return '🚨';
      case PregnancySymptom.highFever:
        return '🌡️';
    }
  }
}

// ─── ANC Visit ─────────────────────────────────────────────────

class AncVisit {
  final int id;
  final int pregnancyId;
  final int visitNumber;
  final DateTime? scheduledDate;
  final DateTime? completedDate;
  final String? notes;
  final String? facility;
  final bool isDone;

  AncVisit({
    required this.id,
    this.pregnancyId = 0,
    required this.visitNumber,
    this.scheduledDate,
    this.completedDate,
    this.notes,
    this.facility,
    this.isDone = false,
  });

  factory AncVisit.fromJson(Map<String, dynamic> json) {
    return AncVisit(
      id: _parseInt(json['id']),
      pregnancyId: _parseInt(json['pregnancy_id']),
      visitNumber: _parseInt(json['visit_number']),
      scheduledDate: _parseDate(json['scheduled_date']),
      completedDate: _parseDate(json['completed_date']),
      notes: json['notes'] as String?,
      facility: json['facility'] as String?,
      isDone: _parseBool(json['is_done']),
    );
  }

  bool get isOverdue =>
      !isDone &&
      scheduledDate != null &&
      scheduledDate!.isBefore(DateTime.now());
}

// ─── Kick Count ────────────────────────────────────────────────

class KickCount {
  final int id;
  final int pregnancyId;
  final DateTime date;
  final int count;
  final int durationMinutes;
  final DateTime? startTime;

  KickCount({
    required this.id,
    this.pregnancyId = 0,
    required this.date,
    required this.count,
    this.durationMinutes = 0,
    this.startTime,
  });

  factory KickCount.fromJson(Map<String, dynamic> json) {
    return KickCount(
      id: _parseInt(json['id']),
      pregnancyId: _parseInt(json['pregnancy_id']),
      date: _parseDate(json['date']) ?? DateTime.now(),
      count: _parseInt(json['count']),
      durationMinutes: _parseInt(json['duration_minutes']),
      startTime: _parseDate(json['start_time']),
    );
  }

  Map<String, dynamic> toJson() => {
        'pregnancy_id': pregnancyId,
        'date': date.toIso8601String(),
        'count': count,
        'duration_minutes': durationMinutes,
        if (startTime != null) 'start_time': startTime!.toIso8601String(),
      };

  bool get reachedGoal => count >= 10;
}

// ─── Danger Sign ───────────────────────────────────────────────

class DangerSign {
  final String title;
  final String description;
  final String action;
  final String titleEn;
  final String descriptionEn;
  final String actionEn;
  final bool isEmergency;

  const DangerSign({
    required this.title,
    required this.description,
    required this.action,
    required this.titleEn,
    required this.descriptionEn,
    required this.actionEn,
    this.isEmergency = true,
  });

  String displayTitle({bool isSwahili = true}) => isSwahili ? title : titleEn;
  String displayDescription({bool isSwahili = true}) =>
      isSwahili ? description : descriptionEn;
  String displayAction({bool isSwahili = true}) =>
      isSwahili ? action : actionEn;

  static List<DangerSign> all() => const [
        DangerSign(
          title: 'Kutoka Damu Ukeni',
          titleEn: 'Vaginal Bleeding',
          description:
              'Damu yoyote inayotoka ukeni wakati wa ujauzito ni dalili ya hatari.',
          descriptionEn:
              'Any vaginal bleeding during pregnancy is a danger sign.',
          action:
              'Nenda hospitali MARA MOJA. Usichelewe. Piga simu 112 kama huna usafiri.',
          actionEn:
              'Go to the hospital IMMEDIATELY. Do not delay. Call 112 if you have no transport.',
        ),
        DangerSign(
          title: 'Maumivu Makali ya Kichwa',
          titleEn: 'Severe Headache',
          description:
              'Maumivu makali ya kichwa ambayo hayapunguzi na dawa, hasa yakiambatana na macho kuona giza.',
          descriptionEn:
              'Severe headache that does not respond to medication, especially with blurred vision.',
          action:
              'Nenda hospitali haraka. Hii inaweza kuwa dalili ya shinikizo la damu kubwa (eclampsia).',
          actionEn:
              'Go to the hospital quickly. This could be a sign of high blood pressure (eclampsia).',
        ),
        DangerSign(
          title: 'Degedege / Kifafa',
          titleEn: 'Convulsions / Seizures',
          description:
              'Kupoteza fahamu au kushtuka mwili. Hii ni dharura kubwa.',
          descriptionEn:
              'Loss of consciousness or body convulsions. This is a major emergency.',
          action:
              'Piga 112 mara moja. Mlaze kwa ubavu. Usimweke kitu mdomoni.',
          actionEn:
              'Call 112 immediately. Lay her on her side. Do not put anything in her mouth.',
        ),
        DangerSign(
          title: 'Homa Kali',
          titleEn: 'High Fever',
          description:
              'Joto la mwili zaidi ya 38°C, hasa likifuatana na baridi na kutetemeka.',
          descriptionEn:
              'Body temperature above 38°C, especially with chills and shivering.',
          action:
              'Nenda hospitali. Unaweza kuwa na maambukizi ya malaria au mengine.',
          actionEn:
              'Go to the hospital. You may have malaria or another infection.',
        ),
        DangerSign(
          title: 'Mtoto Kutosogea',
          titleEn: 'Baby Not Moving',
          description:
              'Mtoto kutopiga teke au kusogea kwa masaa mengi (chini ya mateke 10 kwa masaa 2).',
          descriptionEn:
              'Baby not kicking or moving for many hours (less than 10 kicks in 2 hours).',
          action:
              'Lala ubavuni wa kushoto, kunywa maji baridi, na hesabu mateke. Kama bado chini ya 10 kwa masaa 2, nenda hospitali.',
          actionEn:
              'Lie on your left side, drink cold water, and count kicks. If still below 10 in 2 hours, go to the hospital.',
        ),
        DangerSign(
          title: 'Kuvimba Uso na Mikono',
          titleEn: 'Swelling of Face and Hands',
          description:
              'Kuvimba kwa ghafla uso, mikono, na miguu hasa asubuhi.',
          descriptionEn:
              'Sudden swelling of face, hands, and feet especially in the morning.',
          action:
              'Hii inaweza kuwa dalili ya preeclampsia. Nenda hospitali kwa uchunguzi.',
          actionEn:
              'This could be a sign of preeclampsia. Go to the hospital for examination.',
        ),
        DangerSign(
          title: 'Kutoka Maji Ukeni',
          titleEn: 'Leaking Fluid',
          description:
              'Maji yanayotoka ukeni kabla ya wakati (kabla ya wiki 37). Inaweza kuwa maji ya mtoto.',
          descriptionEn:
              'Fluid leaking from the vagina before term (before week 37). This could be amniotic fluid.',
          action:
              'Nenda hospitali MARA MOJA. Usilale chini muda mrefu bila msaada.',
          actionEn:
              'Go to the hospital IMMEDIATELY. Do not lie down for long without help.',
        ),
        DangerSign(
          title: 'Maumivu Makali Tumboni',
          titleEn: 'Severe Abdominal Pain',
          description:
              'Maumivu ya tumbo la chini ambayo ni makali na hayapungui.',
          descriptionEn:
              'Severe lower abdominal pain that does not subside.',
          action:
              'Inaweza kuwa mimba ya nje ya kizazi au placenta kutoka. Nenda hospitali haraka.',
          actionEn:
              'Could be an ectopic pregnancy or placental abruption. Go to the hospital quickly.',
        ),
      ];
}

// ─── Result Wrappers ───────────────────────────────────────────

class MyPregnancyResult<T> {
  final bool success;
  final T? data;
  final String? message;
  MyPregnancyResult({required this.success, this.data, this.message});
}

class MyPregnancyListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  MyPregnancyListResult({required this.success, this.items = const [], this.message});
}

// ─── Parsing Helpers ───────────────────────────────────────────

int _parseInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double _parseDouble(dynamic v, {double fallback = 0}) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

bool _parseBool(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v == 'true';
  return fallback;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) {
    return DateTime.tryParse(v);
  }
  return null;
}
