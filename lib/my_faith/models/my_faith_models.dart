// lib/my_faith/models/my_faith_models.dart

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

enum FaithSelection { christianity, islam }

enum ChristianDenomination {
  catholic,
  lutheran,
  anglican,
  pentecostal,
  sda,
  baptist,
  moravian,
  evangelical,
  other;

  String get label {
    switch (this) {
      case catholic: return 'Katoliki / Catholic';
      case lutheran: return 'Kilutheri (KKKT) / Lutheran';
      case anglican: return 'Anglikana / Anglican';
      case pentecostal: return 'Pentekoste / Pentecostal';
      case sda: return 'Wasabato (SDA)';
      case baptist: return 'Wabaptisti / Baptist';
      case moravian: return 'Wamoravia / Moravian';
      case evangelical: return 'Kiinjili / Evangelical';
      case other: return 'Nyingine / Other';
    }
  }
}

enum IslamicTradition {
  sunni,
  shia,
  ibadhi,
  other;

  String get label {
    switch (this) {
      case sunni: return 'Sunni';
      case shia: return 'Shia';
      case ibadhi: return 'Ibadhi';
      case other: return 'Nyingine / Other';
    }
  }
}

enum PrivacyLevel { publicLevel, friendsOnly, privateLevel }

// ─── Faith Profile ────────────────────────────────────────────

class FaithProfile {
  final int id;
  final int userId;
  final FaithSelection faith;
  final String? denomination;
  final int? homeChurchId;
  final String? homeChurchName;
  final String? faithBio;
  final String? baptismDate;
  final String? confirmationDate;
  final bool isLeader;
  final String? leaderRole;
  final PrivacyLevel privacy;
  final bool notificationsEnabled;

  FaithProfile({
    required this.id,
    required this.userId,
    required this.faith,
    this.denomination,
    this.homeChurchId,
    this.homeChurchName,
    this.faithBio,
    this.baptismDate,
    this.confirmationDate,
    this.isLeader = false,
    this.leaderRole,
    this.privacy = PrivacyLevel.friendsOnly,
    this.notificationsEnabled = true,
  });

  factory FaithProfile.fromJson(Map<String, dynamic> json) {
    return FaithProfile(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      faith: json['faith']?.toString() == 'islam'
          ? FaithSelection.islam
          : FaithSelection.christianity,
      denomination: json['denomination']?.toString(),
      homeChurchId:
          json['home_church_id'] != null ? _parseInt(json['home_church_id']) : null,
      homeChurchName: json['home_church_name']?.toString(),
      faithBio: json['faith_bio']?.toString(),
      baptismDate: json['baptism_date']?.toString(),
      confirmationDate: json['confirmation_date']?.toString(),
      isLeader: _parseBool(json['is_leader']),
      leaderRole: json['leader_role']?.toString(),
      privacy: _parsePrivacy(json['privacy']),
      notificationsEnabled: _parseBool(json['notifications_enabled']),
    );
  }

  Map<String, dynamic> toJson() => {
        'faith': faith == FaithSelection.islam ? 'islam' : 'christianity',
        'denomination': denomination,
        'home_church_id': homeChurchId,
        'faith_bio': faithBio,
        'baptism_date': baptismDate,
        'confirmation_date': confirmationDate,
        'is_leader': isLeader,
        'leader_role': leaderRole,
        'privacy': privacy.name,
        'notifications_enabled': notificationsEnabled,
      };
}

// ─── Spiritual Goal ───────────────────────────────────────────

class SpiritualGoal {
  final int id;
  final String title;
  final String? description;
  final int targetDays;
  final int completedDays;
  final String? startDate;

  SpiritualGoal({
    required this.id,
    required this.title,
    this.description,
    required this.targetDays,
    required this.completedDays,
    this.startDate,
  });

  factory SpiritualGoal.fromJson(Map<String, dynamic> json) {
    return SpiritualGoal(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      targetDays: _parseInt(json['target_days']),
      completedDays: _parseInt(json['completed_days']),
      startDate: json['start_date']?.toString(),
    );
  }

  double get progress =>
      targetDays > 0 ? (completedDays / targetDays).clamp(0.0, 1.0) : 0.0;
}

// ─── Parse helpers ────────────────────────────────────────────

PrivacyLevel _parsePrivacy(dynamic v) {
  switch (v?.toString()) {
    case 'public':
      return PrivacyLevel.publicLevel;
    case 'private':
      return PrivacyLevel.privateLevel;
    default:
      return PrivacyLevel.friendsOnly;
  }
}
