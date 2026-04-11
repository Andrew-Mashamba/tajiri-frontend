// lib/class_notes/models/class_notes_models.dart

// ─── Note Format ─────────────────────────────────────────────

enum NoteFormat {
  pdf,
  image,
  document,
  slides;

  String get displayName {
    switch (this) {
      case NoteFormat.pdf:
        return 'PDF';
      case NoteFormat.image:
        return 'Picha';
      case NoteFormat.document:
        return 'Hati';
      case NoteFormat.slides:
        return 'Slaidi';
    }
  }

  static NoteFormat fromString(String? s) {
    return NoteFormat.values.firstWhere(
      (v) => v.name == s,
      orElse: () => NoteFormat.pdf,
    );
  }
}

// ─── ClassNote ───────────────────────────────────────────────

class ClassNote {
  final int id;
  final String title;
  final String? description;
  final String subject;
  final String? courseCode;
  final String? topic;
  final int weekNumber;
  final String semester;
  final int year;
  final String? institution;
  final NoteFormat format;
  final String fileUrl;
  final int fileSize;
  final int uploaderId;
  final String uploaderName;
  final String? uploaderAvatar;
  final double rating;
  final int ratingCount;
  final int downloadCount;
  final int viewCount;
  final bool isBookmarked;
  final DateTime createdAt;

  ClassNote({
    required this.id,
    required this.title,
    this.description,
    required this.subject,
    this.courseCode,
    this.topic,
    this.weekNumber = 0,
    required this.semester,
    required this.year,
    this.institution,
    required this.format,
    required this.fileUrl,
    this.fileSize = 0,
    required this.uploaderId,
    required this.uploaderName,
    this.uploaderAvatar,
    this.rating = 0,
    this.ratingCount = 0,
    this.downloadCount = 0,
    this.viewCount = 0,
    this.isBookmarked = false,
    required this.createdAt,
  });

  factory ClassNote.fromJson(Map<String, dynamic> json) {
    return ClassNote(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      subject: json['subject']?.toString() ?? '',
      courseCode: json['course_code']?.toString(),
      topic: json['topic']?.toString(),
      weekNumber: _parseInt(json['week_number']),
      semester: json['semester']?.toString() ?? '',
      year: _parseInt(json['year']),
      institution: json['institution']?.toString(),
      format: NoteFormat.fromString(json['format']?.toString()),
      fileUrl: json['file_url']?.toString() ?? '',
      fileSize: _parseInt(json['file_size']),
      uploaderId: _parseInt(json['uploader_id']),
      uploaderName: json['uploader_name']?.toString() ?? '',
      uploaderAvatar: json['uploader_avatar']?.toString(),
      rating: _parseDouble(json['rating']) ?? 0,
      ratingCount: _parseInt(json['rating_count']),
      downloadCount: _parseInt(json['download_count']),
      viewCount: _parseInt(json['view_count']),
      isBookmarked: _parseBool(json['is_bookmarked']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ─── NoteRequest ─────────────────────────────────────────────

class NoteRequest {
  final int id;
  final String subject;
  final String? courseCode;
  final String topic;
  final int weekNumber;
  final String requesterName;
  final int requesterId;
  final bool isFulfilled;
  final DateTime createdAt;

  NoteRequest({
    required this.id,
    required this.subject,
    this.courseCode,
    required this.topic,
    this.weekNumber = 0,
    required this.requesterName,
    required this.requesterId,
    this.isFulfilled = false,
    required this.createdAt,
  });

  factory NoteRequest.fromJson(Map<String, dynamic> json) {
    return NoteRequest(
      id: _parseInt(json['id']),
      subject: json['subject']?.toString() ?? '',
      courseCode: json['course_code']?.toString(),
      topic: json['topic']?.toString() ?? '',
      weekNumber: _parseInt(json['week_number']),
      requesterName: json['requester_name']?.toString() ?? '',
      requesterId: _parseInt(json['requester_id']),
      isFulfilled: _parseBool(json['is_fulfilled']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ─── NoteContributor ─────────────────────────────────────────

class NoteContributor {
  final int userId;
  final String name;
  final String? avatarUrl;
  final int uploadCount;
  final double averageRating;
  final int totalDownloads;

  NoteContributor({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.uploadCount = 0,
    this.averageRating = 0,
    this.totalDownloads = 0,
  });

  factory NoteContributor.fromJson(Map<String, dynamic> json) {
    return NoteContributor(
      userId: _parseInt(json['user_id']),
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      uploadCount: _parseInt(json['upload_count']),
      averageRating: _parseDouble(json['average_rating']) ?? 0,
      totalDownloads: _parseInt(json['total_downloads']),
    );
  }
}

// ─── Result wrappers ─────────────────────────────────────────

class NotesResult<T> {
  final bool success;
  final T? data;
  final String? message;

  NotesResult({required this.success, this.data, this.message});
}

class NotesListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  NotesListResult({required this.success, this.items = const [], this.message});
}

// ─── Parse helpers ───────────────────────────────────────────

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}
