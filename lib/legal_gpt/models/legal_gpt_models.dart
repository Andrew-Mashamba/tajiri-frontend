// lib/legal_gpt/models/legal_gpt_models.dart
import '../../config/api_config.dart';

// ─── Parse helpers ──────────────────────────────────────────────
int _parseInt(dynamic v, [int fallback = 0]) =>
    (v is num) ? v.toInt() : int.tryParse('$v') ?? fallback;

double _parseDouble(dynamic v, [double fallback = 0.0]) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? fallback;

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

// ─── Law Citation ───────────────────────────────────────────────
class LawCitation {
  final String lawName;
  final String section;
  final String summary;
  final String fullText;

  LawCitation({
    this.lawName = '',
    this.section = '',
    this.summary = '',
    this.fullText = '',
  });

  factory LawCitation.fromJson(Map<String, dynamic> json) => LawCitation(
        lawName: json['law_name'] as String? ?? '',
        section: json['section'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        fullText: json['full_text'] as String? ?? '',
      );
}

// ─── Legal Message ──────────────────────────────────────────────
class LegalMessage {
  final int id;
  final String role; // user, assistant
  final String content;
  final List<LawCitation> citations;
  final String timestamp;

  LegalMessage({
    required this.id,
    this.role = 'user',
    this.content = '',
    this.citations = const [],
    this.timestamp = '',
  });

  factory LegalMessage.fromJson(Map<String, dynamic> json) => LegalMessage(
        id: _parseInt(json['id']),
        role: json['role'] as String? ?? 'user',
        content: json['content'] as String? ?? '',
        citations: (json['citations'] as List?)
                ?.map((e) => LawCitation.fromJson(e))
                .toList() ??
            [],
        timestamp: json['timestamp'] as String? ?? '',
      );
}

// ─── Document Template ──────────────────────────────────────────
class TemplateField {
  final String key;
  final String label;
  final String type; // text, date, number, select
  final bool required;

  TemplateField({
    this.key = '',
    this.label = '',
    this.type = 'text',
    this.required = false,
  });

  factory TemplateField.fromJson(Map<String, dynamic> json) => TemplateField(
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
        type: json['type'] as String? ?? 'text',
        required: json['required'] as bool? ?? false,
      );
}

class DocumentTemplate {
  final int id;
  final String name;
  final String category;
  final String description;
  final List<TemplateField> fields;
  final String templateContent;

  DocumentTemplate({
    required this.id,
    this.name = '',
    this.category = '',
    this.description = '',
    this.fields = const [],
    this.templateContent = '',
  });

  factory DocumentTemplate.fromJson(Map<String, dynamic> json) =>
      DocumentTemplate(
        id: _parseInt(json['id']),
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? '',
        description: json['description'] as String? ?? '',
        fields: (json['fields'] as List?)
                ?.map((e) => TemplateField.fromJson(e))
                .toList() ??
            [],
        templateContent: json['template_content'] as String? ?? '',
      );
}

// ─── Lawyer ─────────────────────────────────────────────────────
class Lawyer {
  final int id;
  final int userId;
  final String name;
  final List<String> specializations;
  final String location;
  final double rating;
  final String feeRange;
  final String phone;
  final String photo;
  final bool verified;

  Lawyer({
    required this.id,
    this.userId = 0,
    this.name = '',
    this.specializations = const [],
    this.location = '',
    this.rating = 0,
    this.feeRange = '',
    this.phone = '',
    this.photo = '',
    this.verified = false,
  });

  factory Lawyer.fromJson(Map<String, dynamic> json) => Lawyer(
        id: _parseInt(json['id']),
        userId: _parseInt(json['user_id']),
        name: json['name'] as String? ?? '',
        specializations: (json['specializations'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        location: json['location'] as String? ?? '',
        rating: _parseDouble(json['rating']),
        feeRange: json['fee_range'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        photo: _buildUrl(json['photo'] as String?),
        verified: json['verified'] as bool? ?? false,
      );
}

// ─── Legal Aid Center ───────────────────────────────────────────
class LegalAidCenter {
  final int id;
  final String name;
  final String organization;
  final List<String> services;
  final String location;
  final String phone;
  final String hours;

  LegalAidCenter({
    required this.id,
    this.name = '',
    this.organization = '',
    this.services = const [],
    this.location = '',
    this.phone = '',
    this.hours = '',
  });

  factory LegalAidCenter.fromJson(Map<String, dynamic> json) => LegalAidCenter(
        id: _parseInt(json['id']),
        name: json['name'] as String? ?? '',
        organization: json['organization'] as String? ?? '',
        services: (json['services'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        location: json['location'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        hours: json['hours'] as String? ?? '',
      );
}

// ─── Court Case ─────────────────────────────────────────────────
class CourtCase {
  final int id;
  final String caseNumber;
  final String court;
  final String parties;
  final String status;
  final String nextHearing;
  final List<CaseEvent> history;

  CourtCase({
    required this.id,
    this.caseNumber = '',
    this.court = '',
    this.parties = '',
    this.status = '',
    this.nextHearing = '',
    this.history = const [],
  });

  factory CourtCase.fromJson(Map<String, dynamic> json) => CourtCase(
        id: _parseInt(json['id']),
        caseNumber: json['case_number'] as String? ?? '',
        court: json['court'] as String? ?? '',
        parties: json['parties'] as String? ?? '',
        status: json['status'] as String? ?? '',
        nextHearing: json['next_hearing'] as String? ?? '',
        history: (json['history'] as List?)
                ?.map((e) => CaseEvent.fromJson(e))
                .toList() ??
            [],
      );
}

class CaseEvent {
  final String date;
  final String event;
  final String details;

  CaseEvent({this.date = '', this.event = '', this.details = ''});

  factory CaseEvent.fromJson(Map<String, dynamic> json) => CaseEvent(
        date: json['date'] as String? ?? '',
        event: json['event'] as String? ?? '',
        details: json['details'] as String? ?? '',
      );
}

// ─── Rights Card ────────────────────────────────────────────────
class RightsCard {
  final int id;
  final String category;
  final String titleSw;
  final String titleEn;
  final String descriptionSw;
  final String descriptionEn;
  final String icon;
  final List<String> keyPointsSw;
  final List<String> keyPointsEn;
  final String whatToDo;

  RightsCard({
    required this.id,
    this.category = '',
    this.titleSw = '',
    this.titleEn = '',
    this.descriptionSw = '',
    this.descriptionEn = '',
    this.icon = '',
    this.keyPointsSw = const [],
    this.keyPointsEn = const [],
    this.whatToDo = '',
  });

  factory RightsCard.fromJson(Map<String, dynamic> json) => RightsCard(
        id: _parseInt(json['id']),
        category: json['category'] as String? ?? '',
        titleSw: json['title_sw'] as String? ?? '',
        titleEn: json['title_en'] as String? ?? '',
        descriptionSw: json['description_sw'] as String? ?? '',
        descriptionEn: json['description_en'] as String? ?? '',
        icon: json['icon'] as String? ?? '',
        keyPointsSw: (json['key_points_sw'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        keyPointsEn: (json['key_points_en'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        whatToDo: json['what_to_do'] as String? ?? '',
      );
}

// ─── Document Review ────────────────────────────────────────────
class DocumentReview {
  final String summary;
  final List<ReviewFlag> flags;
  final String riskLevel; // low, medium, high

  DocumentReview({
    this.summary = '',
    this.flags = const [],
    this.riskLevel = 'low',
  });

  factory DocumentReview.fromJson(Map<String, dynamic> json) => DocumentReview(
        summary: json['summary'] as String? ?? '',
        flags: (json['flags'] as List?)
                ?.map((e) => ReviewFlag.fromJson(e))
                .toList() ??
            [],
        riskLevel: json['risk_level'] as String? ?? 'low',
      );
}

class ReviewFlag {
  final String clause;
  final String issue;
  final String suggestion;
  final String severity;

  ReviewFlag({
    this.clause = '',
    this.issue = '',
    this.suggestion = '',
    this.severity = 'info',
  });

  factory ReviewFlag.fromJson(Map<String, dynamic> json) => ReviewFlag(
        clause: json['clause'] as String? ?? '',
        issue: json['issue'] as String? ?? '',
        suggestion: json['suggestion'] as String? ?? '',
        severity: json['severity'] as String? ?? 'info',
      );
}

// ─── Legal Term ─────────────────────────────────────────────────
class LegalTerm {
  final int id;
  final String termSw;
  final String termEn;
  final String definitionSw;
  final String definitionEn;

  LegalTerm({
    required this.id,
    this.termSw = '',
    this.termEn = '',
    this.definitionSw = '',
    this.definitionEn = '',
  });

  factory LegalTerm.fromJson(Map<String, dynamic> json) => LegalTerm(
        id: _parseInt(json['id']),
        termSw: json['term_sw'] as String? ?? '',
        termEn: json['term_en'] as String? ?? '',
        definitionSw: json['definition_sw'] as String? ?? '',
        definitionEn: json['definition_en'] as String? ?? '',
      );
}

// ─── Court Guide ────────────────────────────────────────────────
class CourtGuide {
  final String courtType;
  final List<CourtStep> steps;
  final String estimatedDuration;
  final String fees;

  CourtGuide({
    this.courtType = '',
    this.steps = const [],
    this.estimatedDuration = '',
    this.fees = '',
  });

  factory CourtGuide.fromJson(Map<String, dynamic> json) => CourtGuide(
        courtType: json['court_type'] as String? ?? '',
        steps: (json['steps'] as List?)
                ?.map((e) => CourtStep.fromJson(e))
                .toList() ??
            [],
        estimatedDuration: json['estimated_duration'] as String? ?? '',
        fees: json['fees'] as String? ?? '',
      );
}

class CourtStep {
  final int number;
  final String title;
  final String description;

  CourtStep({this.number = 0, this.title = '', this.description = ''});

  factory CourtStep.fromJson(Map<String, dynamic> json) => CourtStep(
        number: _parseInt(json['number']),
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );
}
