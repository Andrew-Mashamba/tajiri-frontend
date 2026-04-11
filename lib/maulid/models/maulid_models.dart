// lib/maulid/models/maulid_models.dart

// ─── Maulid Event ─────────────────────────────────────────────
class MaulidEvent {
  final int id;
  final String title;
  final String titleSwahili;
  final String description;
  final String venue;
  final String address;
  final double? latitude;
  final double? longitude;
  final DateTime startTime;
  final DateTime? endTime;
  final String organizerName;
  final List<String> qaswidaGroups;
  final int? attendeeCount;
  final bool isLiveStreamable;
  final String? imageUrl;
  final String? liveStreamUrl;

  MaulidEvent({
    required this.id,
    required this.title,
    required this.titleSwahili,
    required this.description,
    required this.venue,
    required this.address,
    this.latitude,
    this.longitude,
    required this.startTime,
    this.endTime,
    required this.organizerName,
    this.qaswidaGroups = const [],
    this.attendeeCount,
    this.isLiveStreamable = false,
    this.imageUrl,
    this.liveStreamUrl,
  });

  factory MaulidEvent.fromJson(Map<String, dynamic> json) {
    return MaulidEvent(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      titleSwahili: json['title_sw']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      venue: json['venue']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: json['latitude'] != null
          ? _parseDouble(json['latitude']) : null,
      longitude: json['longitude'] != null
          ? _parseDouble(json['longitude']) : null,
      startTime: DateTime.tryParse(json['start_time']?.toString() ?? '') ??
          DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.tryParse(json['end_time'].toString()) : null,
      organizerName: json['organizer_name']?.toString() ?? '',
      qaswidaGroups: (json['qaswida_groups'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      attendeeCount: json['attendee_count'] != null
          ? _parseInt(json['attendee_count']) : null,
      isLiveStreamable: _parseBool(json['is_live_streamable']),
      imageUrl: json['image_url']?.toString(),
      liveStreamUrl: json['live_stream_url']?.toString(),
    );
  }
}

// ─── Qaswida Recording ────────────────────────────────────────
class QaswidaRecording {
  final int id;
  final String title;
  final String groupName;
  final String? audioUrl;
  final String? videoUrl;
  final int durationSeconds;
  final int? year;
  final String? thumbnailUrl;
  final int playCount;

  QaswidaRecording({
    required this.id,
    required this.title,
    required this.groupName,
    this.audioUrl,
    this.videoUrl,
    required this.durationSeconds,
    this.year,
    this.thumbnailUrl,
    this.playCount = 0,
  });

  factory QaswidaRecording.fromJson(Map<String, dynamic> json) {
    return QaswidaRecording(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      groupName: json['group_name']?.toString() ?? '',
      audioUrl: json['audio_url']?.toString(),
      videoUrl: json['video_url']?.toString(),
      durationSeconds: _parseInt(json['duration_seconds']),
      year: json['year'] != null ? _parseInt(json['year']) : null,
      thumbnailUrl: json['thumbnail_url']?.toString(),
      playCount: _parseInt(json['play_count']),
    );
  }

  String get durationFormatted {
    final m = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─── Qaswida Group ────────────────────────────────────────────
class QaswidaGroup {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int recordingCount;
  final String? location;

  QaswidaGroup({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.recordingCount,
    this.location,
  });

  factory QaswidaGroup.fromJson(Map<String, dynamic> json) {
    return QaswidaGroup(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      recordingCount: _parseInt(json['recording_count']),
      location: json['location']?.toString(),
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

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}
