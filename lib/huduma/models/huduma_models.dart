// lib/huduma/models/huduma_models.dart

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

// ─── Sermon ───────────────────────────────────────────────────

class Sermon {
  final int id;
  final String title;
  final String? description;
  final String speakerName;
  final int? speakerId;
  final String? speakerPhoto;
  final String? audioUrl;
  final String? videoUrl;
  final String? thumbnailUrl;
  final int durationSeconds;
  final String? topic;
  final String? scriptureRef;
  final String? seriesName;
  final String date;
  final int playCount;
  final bool isDownloaded;

  Sermon({
    required this.id,
    required this.title,
    this.description,
    required this.speakerName,
    this.speakerId,
    this.speakerPhoto,
    this.audioUrl,
    this.videoUrl,
    this.thumbnailUrl,
    required this.durationSeconds,
    this.topic,
    this.scriptureRef,
    this.seriesName,
    required this.date,
    required this.playCount,
    this.isDownloaded = false,
  });

  factory Sermon.fromJson(Map<String, dynamic> json) {
    return Sermon(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      speakerName: json['speaker_name']?.toString() ?? '',
      speakerId: json['speaker_id'] != null ? _parseInt(json['speaker_id']) : null,
      speakerPhoto: json['speaker_photo']?.toString(),
      audioUrl: json['audio_url']?.toString(),
      videoUrl: json['video_url']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      durationSeconds: _parseInt(json['duration_seconds']),
      topic: json['topic']?.toString(),
      scriptureRef: json['scripture_ref']?.toString(),
      seriesName: json['series_name']?.toString(),
      date: json['date']?.toString() ?? '',
      playCount: _parseInt(json['play_count']),
      isDownloaded: _parseBool(json['is_downloaded']),
    );
  }

  String get durationFormatted {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }
}

// ─── Speaker ──────────────────────────────────────────────────

class Speaker {
  final int id;
  final String name;
  final String? bio;
  final String? churchName;
  final String? photoUrl;
  final int sermonCount;
  final bool isFollowing;

  Speaker({
    required this.id,
    required this.name,
    this.bio,
    this.churchName,
    this.photoUrl,
    required this.sermonCount,
    this.isFollowing = false,
  });

  factory Speaker.fromJson(Map<String, dynamic> json) {
    return Speaker(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      bio: json['bio']?.toString(),
      churchName: json['church_name']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      sermonCount: _parseInt(json['sermon_count']),
      isFollowing: _parseBool(json['is_following']),
    );
  }
}
