int? _parseIntN(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

bool _parseBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    return s == 'true' || s == '1';
  }
  return false;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

class TrainingPlan {
  final int id;
  final int partnerUserId;
  final int customerUserId;
  final String title;
  final List<dynamic> weeklyBlocks;
  final DateTime? startsOn;
  final DateTime? endsOn;
  final bool isActive;

  TrainingPlan({
    required this.id,
    required this.partnerUserId,
    required this.customerUserId,
    required this.title,
    required this.weeklyBlocks,
    required this.startsOn,
    required this.endsOn,
    required this.isActive,
  });

  factory TrainingPlan.fromJson(Map<String, dynamic> json) {
    final raw = json['weekly_blocks'];
    final blocks = raw is List
        ? raw
        : (raw is String && raw.isNotEmpty
            ? (() {
                try {
                  final decoded = raw.startsWith('[') ? raw : '[]';
                  return decoded as dynamic;
                } catch (_) {
                  return const <dynamic>[];
                }
              }())
            : const <dynamic>[]);
    return TrainingPlan(
      id: _parseIntN(json['id']) ?? 0,
      partnerUserId: _parseIntN(json['partner_user_id']) ?? 0,
      customerUserId: _parseIntN(json['customer_user_id']) ?? 0,
      title: json['title']?.toString() ?? '',
      weeklyBlocks: blocks is List ? blocks : const [],
      startsOn: _parseDate(json['starts_on']),
      endsOn: _parseDate(json['ends_on']),
      isActive: _parseBool(json['is_active']),
    );
  }
}

class TrainingPlanCheckin {
  final int id;
  final int trainingPlanId;
  final DateTime date;
  final List<dynamic>? setsRepsWeight;
  final int? hrAvg;
  final int? hrMax;
  final bool isPr;
  final String? prLabel;
  final String? notes;

  TrainingPlanCheckin({
    required this.id,
    required this.trainingPlanId,
    required this.date,
    required this.setsRepsWeight,
    required this.hrAvg,
    required this.hrMax,
    required this.isPr,
    required this.prLabel,
    required this.notes,
  });

  factory TrainingPlanCheckin.fromJson(Map<String, dynamic> json) {
    return TrainingPlanCheckin(
      id: _parseIntN(json['id']) ?? 0,
      trainingPlanId: _parseIntN(json['training_plan_id']) ?? 0,
      date: _parseDate(json['date']) ?? DateTime.now(),
      setsRepsWeight: json['sets_reps_weight'] is List ? json['sets_reps_weight'] : null,
      hrAvg: _parseIntN(json['hr_avg']),
      hrMax: _parseIntN(json['hr_max']),
      isPr: _parseBool(json['is_pr']),
      prLabel: json['pr_label']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}
