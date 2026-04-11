// lib/barozi_wangu/models/barozi_wangu_models.dart
import '../../config/api_config.dart';

// ─── Parse helpers ──────────────────────────────────────────────
int _parseInt(dynamic v, [int fallback = 0]) =>
    (v is num) ? v.toInt() : int.tryParse('$v') ?? fallback;

double _parseDouble(dynamic v, [double fallback = 0.0]) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? fallback;

bool _parseBool(dynamic v, [bool fallback = false]) =>
    v is bool ? v : (v == 1 || v == '1' || v == 'true' || fallback);

String _buildUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return ApiConfig.sanitizeUrl(path) ?? path;
  return '${ApiConfig.storageUrl}/$path';
}

// ─── Result wrappers ────────────────────────────────────────────
class SingleResult<T> {
  final bool success;
  final T? data;
  final String message;
  SingleResult({this.success = false, this.data, this.message = ''});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final int total;
  final int page;
  final String message;
  PaginatedResult({
    this.success = false,
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.message = '',
  });
}

// ─── Councillor ─────────────────────────────────────────────────
class Councillor {
  final int id;
  final int userId;
  final int wardId;
  final String name;
  final String photo;
  final String party;
  final String phone;
  final String email;
  final String bio;
  final String officeLocation;
  final String termStart;
  final String termEnd;
  final List<String> committees;
  final double rating;

  Councillor({
    required this.id,
    this.userId = 0,
    required this.wardId,
    required this.name,
    this.photo = '',
    this.party = '',
    this.phone = '',
    this.email = '',
    this.bio = '',
    this.officeLocation = '',
    this.termStart = '',
    this.termEnd = '',
    this.committees = const [],
    this.rating = 0.0,
  });

  factory Councillor.fromJson(Map<String, dynamic> json) => Councillor(
        id: _parseInt(json['id']),
        userId: _parseInt(json['user_id']),
        wardId: _parseInt(json['ward_id']),
        name: json['name'] as String? ?? '',
        photo: _buildUrl(json['photo'] as String?),
        party: json['party'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        officeLocation: json['office_location'] as String? ?? '',
        termStart: json['term_start'] as String? ?? '',
        termEnd: json['term_end'] as String? ?? '',
        committees: (json['committees'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        rating: _parseDouble(json['rating']),
      );
}

// ─── Issue Category ─────────────────────────────────────────────
enum IssueCategory { roads, water, sanitation, electricity, security, other }

IssueCategory _parseCategory(dynamic v) {
  switch ('$v') {
    case 'roads':
      return IssueCategory.roads;
    case 'water':
      return IssueCategory.water;
    case 'sanitation':
      return IssueCategory.sanitation;
    case 'electricity':
      return IssueCategory.electricity;
    case 'security':
      return IssueCategory.security;
    default:
      return IssueCategory.other;
  }
}

// ─── Issue Status ───────────────────────────────────────────────
enum IssueStatus { submitted, acknowledged, inProgress, resolved }

IssueStatus _parseIssueStatus(dynamic v) {
  switch ('$v') {
    case 'acknowledged':
      return IssueStatus.acknowledged;
    case 'in_progress':
      return IssueStatus.inProgress;
    case 'resolved':
      return IssueStatus.resolved;
    default:
      return IssueStatus.submitted;
  }
}

// ─── Ward Issue ─────────────────────────────────────────────────
class WardIssue {
  final int id;
  final int reporterId;
  final int wardId;
  final IssueCategory category;
  final String description;
  final List<String> photoUrls;
  final double gpsLat;
  final double gpsLng;
  final IssueStatus status;
  final String priority;
  final String createdAt;
  final String updatedAt;

  WardIssue({
    required this.id,
    this.reporterId = 0,
    this.wardId = 0,
    this.category = IssueCategory.other,
    this.description = '',
    this.photoUrls = const [],
    this.gpsLat = 0.0,
    this.gpsLng = 0.0,
    this.status = IssueStatus.submitted,
    this.priority = 'medium',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory WardIssue.fromJson(Map<String, dynamic> json) => WardIssue(
        id: _parseInt(json['id']),
        reporterId: _parseInt(json['reporter_id']),
        wardId: _parseInt(json['ward_id']),
        category: _parseCategory(json['category']),
        description: json['description'] as String? ?? '',
        photoUrls: (json['photo_urls'] as List?)
                ?.map((e) => _buildUrl(e as String?))
                .toList() ??
            [],
        gpsLat: _parseDouble(json['gps_lat']),
        gpsLng: _parseDouble(json['gps_lng']),
        status: _parseIssueStatus(json['status']),
        priority: json['priority'] as String? ?? 'medium',
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );

  String get statusLabel {
    switch (status) {
      case IssueStatus.submitted:
        return 'Imewasilishwa';
      case IssueStatus.acknowledged:
        return 'Imepokewa';
      case IssueStatus.inProgress:
        return 'Inafanyiwa kazi';
      case IssueStatus.resolved:
        return 'Imekamilika';
    }
  }
}

// ─── Campaign Promise ───────────────────────────────────────────
enum PromiseStatus { kept, inProgress, broken, notStarted }

PromiseStatus _parsePromiseStatus(dynamic v) {
  switch ('$v') {
    case 'kept':
      return PromiseStatus.kept;
    case 'in_progress':
      return PromiseStatus.inProgress;
    case 'broken':
      return PromiseStatus.broken;
    default:
      return PromiseStatus.notStarted;
  }
}

class CampaignPromise {
  final int id;
  final int councillorId;
  final String description;
  final PromiseStatus status;
  final List<String> evidenceLinks;
  final int communityVotes;
  final String createdAt;

  CampaignPromise({
    required this.id,
    this.councillorId = 0,
    this.description = '',
    this.status = PromiseStatus.notStarted,
    this.evidenceLinks = const [],
    this.communityVotes = 0,
    this.createdAt = '',
  });

  factory CampaignPromise.fromJson(Map<String, dynamic> json) =>
      CampaignPromise(
        id: _parseInt(json['id']),
        councillorId: _parseInt(json['councillor_id']),
        description: json['description'] as String? ?? '',
        status: _parsePromiseStatus(json['status']),
        evidenceLinks: (json['evidence_links'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        communityVotes: _parseInt(json['community_votes']),
        createdAt: json['created_at'] as String? ?? '',
      );
}

// ─── Performance Score ──────────────────────────────────────────
class PerformanceScore {
  final double responsiveness;
  final double presence;
  final double development;
  final double aggregate;

  PerformanceScore({
    this.responsiveness = 0,
    this.presence = 0,
    this.development = 0,
    this.aggregate = 0,
  });

  factory PerformanceScore.fromJson(Map<String, dynamic> json) =>
      PerformanceScore(
        responsiveness: _parseDouble(json['responsiveness']),
        presence: _parseDouble(json['presence']),
        development: _parseDouble(json['development']),
        aggregate: _parseDouble(json['aggregate']),
      );
}

// ─── Development Project ────────────────────────────────────────
class DevelopmentProject {
  final int id;
  final int wardId;
  final String name;
  final double budget;
  final String contractor;
  final String startDate;
  final String endDate;
  final int progressPercent;
  final List<String> photos;
  final String sector;

  DevelopmentProject({
    required this.id,
    this.wardId = 0,
    this.name = '',
    this.budget = 0,
    this.contractor = '',
    this.startDate = '',
    this.endDate = '',
    this.progressPercent = 0,
    this.photos = const [],
    this.sector = '',
  });

  factory DevelopmentProject.fromJson(Map<String, dynamic> json) =>
      DevelopmentProject(
        id: _parseInt(json['id']),
        wardId: _parseInt(json['ward_id']),
        name: json['name'] as String? ?? '',
        budget: _parseDouble(json['budget']),
        contractor: json['contractor'] as String? ?? '',
        startDate: json['start_date'] as String? ?? '',
        endDate: json['end_date'] as String? ?? '',
        progressPercent: _parseInt(json['progress_percent']),
        photos: (json['photos'] as List?)
                ?.map((e) => _buildUrl(e as String?))
                .toList() ??
            [],
        sector: json['sector'] as String? ?? '',
      );
}
