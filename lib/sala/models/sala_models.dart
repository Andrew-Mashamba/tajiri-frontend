// lib/sala/models/sala_models.dart

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
bool _parseBool(dynamic v) =>
    v == true || v == 1 || v == '1' || v == 'true';

// ─── Result wrappers ───────────────────────────────────────────

class SingleResult<T> {
  final bool success;
  final T? data;
  final String? message;
  SingleResult({required this.success, this.data, this.message});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  final int currentPage;
  final int lastPage;
  PaginatedResult({
    required this.success,
    this.items = const [],
    this.message,
    this.currentPage = 1,
    this.lastPage = 1,
  });
  bool get hasMore => currentPage < lastPage;
}

// ─── Enums ────────────────────────────────────────────────────

enum PrayerCategory {
  personal,
  family,
  church,
  nation,
  health,
  finances,
  relationships;

  String get label {
    switch (this) {
      case personal: return 'Binafsi / Personal';
      case family: return 'Familia / Family';
      case church: return 'Kanisa / Church';
      case nation: return 'Taifa / Nation';
      case health: return 'Afya / Health';
      case finances: return 'Fedha / Finances';
      case relationships: return 'Mahusiano / Relationships';
    }
  }
}

enum PrayerUrgency { low, medium, high }

enum PrayerStatus { active, answered, archived }

// ─── Prayer Request ───────────────────────────────────────────

class PrayerRequest {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final PrayerCategory category;
  final PrayerUrgency urgency;
  final PrayerStatus status;
  final int prayerCount;
  final String? answerTestimony;
  final String? scriptureRef;
  final bool isShared;
  final String createdAt;

  PrayerRequest({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.urgency,
    required this.status,
    required this.prayerCount,
    this.answerTestimony,
    this.scriptureRef,
    required this.isShared,
    required this.createdAt,
  });

  factory PrayerRequest.fromJson(Map<String, dynamic> json) {
    return PrayerRequest(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      category: _parseCategory(json['category']),
      urgency: _parseUrgency(json['urgency']),
      status: _parseStatus(json['status']),
      prayerCount: _parseInt(json['prayer_count']),
      answerTestimony: json['answer_testimony']?.toString(),
      scriptureRef: json['scripture_ref']?.toString(),
      isShared: _parseBool(json['is_shared']),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

// ─── Journal Entry ────────────────────────────────────────────

class PrayerJournalEntry {
  final int id;
  final String content;
  final String? scriptureRef;
  final String? reflection;
  final String date;

  PrayerJournalEntry({
    required this.id,
    required this.content,
    this.scriptureRef,
    this.reflection,
    required this.date,
  });

  factory PrayerJournalEntry.fromJson(Map<String, dynamic> json) {
    return PrayerJournalEntry(
      id: _parseInt(json['id']),
      content: json['content']?.toString() ?? '',
      scriptureRef: json['scripture_ref']?.toString(),
      reflection: json['reflection']?.toString(),
      date: json['date']?.toString() ?? '',
    );
  }
}

// ─── Prayer Stats ─────────────────────────────────────────────

class PrayerStats {
  final int totalRequests;
  final int answeredCount;
  final int streak;
  final int prayingForOthers;

  PrayerStats({
    required this.totalRequests,
    required this.answeredCount,
    required this.streak,
    required this.prayingForOthers,
  });

  factory PrayerStats.fromJson(Map<String, dynamic> json) {
    return PrayerStats(
      totalRequests: _parseInt(json['total_requests']),
      answeredCount: _parseInt(json['answered_count']),
      streak: _parseInt(json['streak']),
      prayingForOthers: _parseInt(json['praying_for_others']),
    );
  }
}

// ─── Parse helpers ────────────────────────────────────────────

PrayerCategory _parseCategory(dynamic v) {
  switch (v?.toString()) {
    case 'family': return PrayerCategory.family;
    case 'church': return PrayerCategory.church;
    case 'nation': return PrayerCategory.nation;
    case 'health': return PrayerCategory.health;
    case 'finances': return PrayerCategory.finances;
    case 'relationships': return PrayerCategory.relationships;
    default: return PrayerCategory.personal;
  }
}

PrayerUrgency _parseUrgency(dynamic v) {
  switch (v?.toString()) {
    case 'high': return PrayerUrgency.high;
    case 'medium': return PrayerUrgency.medium;
    default: return PrayerUrgency.low;
  }
}

PrayerStatus _parseStatus(dynamic v) {
  switch (v?.toString()) {
    case 'answered': return PrayerStatus.answered;
    case 'archived': return PrayerStatus.archived;
    default: return PrayerStatus.active;
  }
}
