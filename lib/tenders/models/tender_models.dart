// TAJIRI Tenders (Zabuni) Models
// Supports tender browsing, applications, and institution tracking

import 'package:flutter/material.dart';

// ============================================================================
// ENUMS
// ============================================================================

enum TenderStatus {
  active('active'),
  closed('closed'),
  archive('archive');

  final String value;
  const TenderStatus(this.value);

  static TenderStatus fromString(String? value) {
    switch (value) {
      case 'closed':
        return TenderStatus.closed;
      case 'archive':
        return TenderStatus.archive;
      default:
        return TenderStatus.active;
    }
  }

  String get label {
    switch (this) {
      case TenderStatus.active:
        return 'Hai';
      case TenderStatus.closed:
        return 'Imefungwa';
      case TenderStatus.archive:
        return 'Kumbukumbu';
    }
  }

  Color get color {
    switch (this) {
      case TenderStatus.active:
        return const Color(0xFF2E7D32);
      case TenderStatus.closed:
        return const Color(0xFF999999);
      case TenderStatus.archive:
        return const Color(0xFF666666);
    }
  }
}

enum ApplicationStatus {
  interested('interested'),
  preparing('preparing'),
  submitted('submitted'),
  won('won'),
  lost('lost');

  final String value;
  const ApplicationStatus(this.value);

  static ApplicationStatus fromString(String? value) {
    switch (value) {
      case 'preparing':
        return ApplicationStatus.preparing;
      case 'submitted':
        return ApplicationStatus.submitted;
      case 'won':
        return ApplicationStatus.won;
      case 'lost':
        return ApplicationStatus.lost;
      default:
        return ApplicationStatus.interested;
    }
  }

  String get label {
    switch (this) {
      case ApplicationStatus.interested:
        return 'Ninapendezwa';
      case ApplicationStatus.preparing:
        return 'Ninaandaa';
      case ApplicationStatus.submitted:
        return 'Imewasilishwa';
      case ApplicationStatus.won:
        return 'Imeshinda';
      case ApplicationStatus.lost:
        return 'Haijashinda';
    }
  }

  Color get color {
    switch (this) {
      case ApplicationStatus.interested:
        return const Color(0xFF1976D2);
      case ApplicationStatus.preparing:
        return const Color(0xFFE65100);
      case ApplicationStatus.submitted:
        return const Color(0xFF2E7D32);
      case ApplicationStatus.won:
        return const Color(0xFFFF8F00);
      case ApplicationStatus.lost:
        return const Color(0xFF999999);
    }
  }

  IconData get icon {
    switch (this) {
      case ApplicationStatus.interested:
        return Icons.bookmark_outline_rounded;
      case ApplicationStatus.preparing:
        return Icons.edit_note_rounded;
      case ApplicationStatus.submitted:
        return Icons.send_rounded;
      case ApplicationStatus.won:
        return Icons.emoji_events_rounded;
      case ApplicationStatus.lost:
        return Icons.cancel_outlined;
    }
  }
}

enum TenderCategory {
  ict('ICT', 'Teknolojia'),
  construction('Construction', 'Ujenzi'),
  consultancy('Consultancy', 'Ushauri'),
  supplies('Supplies', 'Vifaa'),
  services('Services', 'Huduma'),
  insurance('Insurance', 'Bima'),
  audit('Audit', 'Ukaguzi'),
  legal('Legal', 'Sheria'),
  other('Other', 'Nyingine');

  final String valueEn;
  final String label;
  const TenderCategory(this.valueEn, this.label);

  static TenderCategory fromString(String? value) {
    if (value == null) return TenderCategory.other;
    final lower = value.toLowerCase();
    for (final cat in TenderCategory.values) {
      if (cat.valueEn.toLowerCase() == lower || cat.label.toLowerCase() == lower) {
        return cat;
      }
    }
    return TenderCategory.other;
  }
}

enum InstitutionCategory {
  bank('Bank', 'Benki'),
  saccos('SACCOS', 'SACCOS'),
  mfi('MFI', 'MFI'),
  government('Government', 'Serikali'),
  ngo('NGO', 'Mashirika'),
  other('Other', 'Nyingine');

  final String valueEn;
  final String label;
  const InstitutionCategory(this.valueEn, this.label);

  static InstitutionCategory fromString(String? value) {
    if (value == null) return InstitutionCategory.other;
    final lower = value.toLowerCase();
    for (final cat in InstitutionCategory.values) {
      if (cat.valueEn.toLowerCase() == lower || cat.label.toLowerCase() == lower) {
        return cat;
      }
    }
    return InstitutionCategory.other;
  }
}

// ============================================================================
// PARSING HELPERS
// ============================================================================

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String _parseString(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  return v.toString();
}

DateTime? _parseDateTime(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

bool _parseBool(dynamic v, [bool fallback = false]) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v.toLowerCase() == 'true' || v == '1';
  return fallback;
}

// ============================================================================
// MODELS
// ============================================================================

class TenderDocument {
  final String filename;
  final String? originalUrl;
  final String? contentType;

  const TenderDocument({
    required this.filename,
    this.originalUrl,
    this.contentType,
  });

  factory TenderDocument.fromJson(Map<String, dynamic> json) {
    return TenderDocument(
      filename: _parseString(json['filename'], 'document'),
      originalUrl: json['original_url'] as String?,
      contentType: json['content_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'filename': filename,
    'original_url': originalUrl,
    'content_type': contentType,
  };

  bool get isPdf => (contentType ?? '').contains('pdf') || filename.toLowerCase().endsWith('.pdf');
  bool get isDoc => filename.toLowerCase().endsWith('.doc') || filename.toLowerCase().endsWith('.docx');

  IconData get icon {
    if (isPdf) return Icons.picture_as_pdf_rounded;
    if (isDoc) return Icons.description_rounded;
    return Icons.insert_drive_file_rounded;
  }
}

class TenderContact {
  final String? name;
  final String? email;
  final String? phone;
  final String? address;

  const TenderContact({this.name, this.email, this.phone, this.address});

  factory TenderContact.fromJson(Map<String, dynamic> json) {
    return TenderContact(
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
  };

  bool get hasAnyInfo => name != null || email != null || phone != null || address != null;
}

class Tender {
  final String tenderId;
  final String institution;
  final String title;
  final String? description;
  final String? referenceNumber;
  final DateTime? publishedDate;
  final DateTime? closingDate;
  final String? closingTime;
  final TenderCategory category;
  final TenderStatus status;
  final String? sourceUrl;
  final List<TenderDocument> documents;
  final TenderContact? contact;
  final String? eligibility;
  final DateTime? scrapedAt;

  const Tender({
    required this.tenderId,
    required this.institution,
    required this.title,
    this.description,
    this.referenceNumber,
    this.publishedDate,
    this.closingDate,
    this.closingTime,
    this.category = TenderCategory.other,
    this.status = TenderStatus.active,
    this.sourceUrl,
    this.documents = const [],
    this.contact,
    this.eligibility,
    this.scrapedAt,
  });

  factory Tender.fromJson(Map<String, dynamic> json) {
    final docs = (json['documents'] as List<dynamic>?)
        ?.map((d) => TenderDocument.fromJson(d as Map<String, dynamic>))
        .toList() ?? [];

    final contactMap = json['contact'] as Map<String, dynamic>?;

    return Tender(
      tenderId: _parseString(json['tender_id'], ''),
      institution: _parseString(json['institution'], ''),
      title: _parseString(json['title'], 'Zabuni'),
      description: json['description'] as String?,
      referenceNumber: json['reference_number'] as String?,
      publishedDate: _parseDateTime(json['published_date']),
      closingDate: _parseDateTime(json['closing_date']),
      closingTime: json['closing_time'] as String?,
      category: TenderCategory.fromString(json['category'] as String?),
      status: TenderStatus.fromString(json['status'] as String?),
      sourceUrl: json['source_url'] as String?,
      documents: docs,
      contact: contactMap != null ? TenderContact.fromJson(contactMap) : null,
      eligibility: json['eligibility'] as String?,
      scrapedAt: _parseDateTime(json['scraped_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'tender_id': tenderId,
    'institution': institution,
    'title': title,
    'description': description,
    'reference_number': referenceNumber,
    'published_date': publishedDate?.toIso8601String(),
    'closing_date': closingDate?.toIso8601String(),
    'closing_time': closingTime,
    'category': category.valueEn,
    'status': status.value,
    'source_url': sourceUrl,
    'documents': documents.map((d) => d.toJson()).toList(),
    'contact': contact?.toJson(),
    'eligibility': eligibility,
  };

  /// Days remaining until closing date. Negative = already closed.
  int get daysRemaining {
    if (closingDate == null) return -1;
    final now = DateTime.now();
    return closingDate!.difference(now).inDays;
  }

  bool get isClosingSoon => daysRemaining >= 0 && daysRemaining <= 7;
  bool get isUrgent => daysRemaining >= 0 && daysRemaining <= 3;
  bool get isClosed => status == TenderStatus.closed || (closingDate != null && daysRemaining < 0);

  String get institutionDisplay {
    return institution.replaceAll('-', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}

class TenderApplication {
  final int? id;
  final String tenderId;
  final String? tenderTitle;
  final String? institutionSlug;
  final ApplicationStatus status;
  final String? notes;
  final DateTime? deadline;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TenderApplication({
    this.id,
    required this.tenderId,
    this.tenderTitle,
    this.institutionSlug,
    this.status = ApplicationStatus.interested,
    this.notes,
    this.deadline,
    this.createdAt,
    this.updatedAt,
  });

  factory TenderApplication.fromJson(Map<String, dynamic> json) {
    return TenderApplication(
      id: _parseInt(json['id']),
      tenderId: _parseString(json['tender_id'], ''),
      tenderTitle: json['tender_title'] as String?,
      institutionSlug: json['institution_slug'] as String?,
      status: ApplicationStatus.fromString(json['status'] as String?),
      notes: json['notes'] as String?,
      deadline: _parseDateTime(json['deadline']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'tender_id': tenderId,
    'tender_title': tenderTitle,
    'institution_slug': institutionSlug,
    'status': status.value,
    'notes': notes,
    'deadline': deadline?.toIso8601String(),
  };

  int get daysToDeadline {
    if (deadline == null) return -1;
    return deadline!.difference(DateTime.now()).inDays;
  }

  bool get isDeadlineSoon => daysToDeadline >= 0 && daysToDeadline <= 7;

  String get institutionDisplay {
    if (institutionSlug == null) return '';
    return institutionSlug!.replaceAll('-', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}

class Institution {
  final String slug;
  final String name;
  final InstitutionCategory category;
  final String? domain;
  final String? tenderUrl;
  final int activeTenders;
  final DateTime? lastScraped;
  final bool isFollowed;

  const Institution({
    required this.slug,
    required this.name,
    this.category = InstitutionCategory.other,
    this.domain,
    this.tenderUrl,
    this.activeTenders = 0,
    this.lastScraped,
    this.isFollowed = false,
  });

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      slug: _parseString(json['slug'], ''),
      name: _parseString(json['name'], ''),
      category: InstitutionCategory.fromString(json['category'] as String?),
      domain: json['domain'] as String?,
      tenderUrl: json['tender_url'] as String?,
      activeTenders: _parseInt(json['active_tenders']) ?? 0,
      lastScraped: _parseDateTime(json['last_scraped']),
      isFollowed: _parseBool(json['is_followed']),
    );
  }

  Institution copyWith({bool? isFollowed}) {
    return Institution(
      slug: slug,
      name: name,
      category: category,
      domain: domain,
      tenderUrl: tenderUrl,
      activeTenders: activeTenders,
      lastScraped: lastScraped,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }
}

class TenderStats {
  final int totalActive;
  final int totalClosingSoon;
  final int totalInstitutions;
  final int totalApplications;

  const TenderStats({
    this.totalActive = 0,
    this.totalClosingSoon = 0,
    this.totalInstitutions = 0,
    this.totalApplications = 0,
  });

  factory TenderStats.fromJson(Map<String, dynamic> json) {
    return TenderStats(
      totalActive: _parseInt(json['total_active']) ?? _parseInt(json['active_tenders']) ?? 0,
      totalClosingSoon: _parseInt(json['total_closing_soon']) ?? _parseInt(json['closing_soon']) ?? 0,
      totalInstitutions: _parseInt(json['total_institutions']) ?? 0,
      totalApplications: _parseInt(json['total_applications']) ?? 0,
    );
  }
}

// ============================================================================
// RESULT WRAPPERS
// ============================================================================

class TenderResult<T> {
  final T? data;
  final String? error;
  final bool success;

  const TenderResult({this.data, this.error, this.success = true});

  factory TenderResult.ok(T data) => TenderResult(data: data, success: true);
  factory TenderResult.fail(String error) => TenderResult(error: error, success: false);
}

class TenderListResult {
  final List<Tender> tenders;
  final int total;
  final String? error;
  final bool success;

  const TenderListResult({
    this.tenders = const [],
    this.total = 0,
    this.error,
    this.success = true,
  });
}

class InstitutionListResult {
  final List<Institution> institutions;
  final String? error;
  final bool success;

  const InstitutionListResult({
    this.institutions = const [],
    this.error,
    this.success = true,
  });
}

class ApplicationListResult {
  final List<TenderApplication> applications;
  final String? error;
  final bool success;

  const ApplicationListResult({
    this.applications = const [],
    this.error,
    this.success = true,
  });
}
