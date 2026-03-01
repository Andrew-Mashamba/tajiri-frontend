import 'package:flutter/material.dart';

/// Post draft status
enum DraftStatus {
  local,     // Only on device, not synced
  synced,    // Synced with server
  syncing,   // Currently syncing
  error,     // Sync failed
}

/// Post type for drafts
enum DraftPostType {
  text('text', 'Text', Icons.text_fields),
  photo('photo', 'Photo', Icons.photo),
  video('video', 'Video', Icons.videocam),
  shortVideo('short_video', 'Short Video', Icons.movie),
  audio('audio', 'Audio', Icons.mic);

  final String value;
  final String label;
  final IconData icon;

  const DraftPostType(this.value, this.label, this.icon);

  static DraftPostType fromString(String value) {
    return DraftPostType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DraftPostType.text,
    );
  }
}

/// Media file stored in draft
class DraftMediaFile {
  final String path;
  final String? originalName;
  final String? mimeType;
  final int? size;
  final String type; // 'image' or 'video'
  final String? thumbnailPath;
  final int? width;
  final int? height;

  DraftMediaFile({
    required this.path,
    this.originalName,
    this.mimeType,
    this.size,
    required this.type,
    this.thumbnailPath,
    this.width,
    this.height,
  });

  factory DraftMediaFile.fromJson(Map<String, dynamic> json) {
    return DraftMediaFile(
      path: json['path'] ?? '',
      originalName: json['original_name'],
      mimeType: json['mime_type'],
      size: json['size'],
      type: json['type'] ?? 'image',
      thumbnailPath: json['thumbnail'],
      width: json['width'],
      height: json['height'],
    );
  }

  Map<String, dynamic> toJson() => {
    'path': path,
    'original_name': originalName,
    'mime_type': mimeType,
    'size': size,
    'type': type,
    'thumbnail': thumbnailPath,
    'width': width,
    'height': height,
  };

  bool get isImage => type == 'image';
  bool get isVideo => type == 'video';
}

/// Post draft model
class PostDraft {
  final int? id;
  final int userId;
  final DraftPostType postType;
  final String? content;
  final String? backgroundColor;
  final List<DraftMediaFile> mediaFiles;
  final String? audioPath;
  final int? audioDuration;
  final List<double>? audioWaveform;
  final String? coverImagePath;
  final int? musicTrackId;
  final int? musicStartTime;
  final double originalAudioVolume;
  final double musicVolume;
  final double videoSpeed;
  final List<Map<String, dynamic>>? textOverlays;
  final String? videoFilter;
  final String privacy;
  final String? locationName;
  final double? locationLat;
  final double? locationLng;
  final List<int>? taggedUsers;
  final DateTime? scheduledAt;
  final String? title;
  final DateTime? lastEditedAt;
  final int autoSaveVersion;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DraftStatus syncStatus;

  PostDraft({
    this.id,
    required this.userId,
    required this.postType,
    this.content,
    this.backgroundColor,
    this.mediaFiles = const [],
    this.audioPath,
    this.audioDuration,
    this.audioWaveform,
    this.coverImagePath,
    this.musicTrackId,
    this.musicStartTime,
    this.originalAudioVolume = 1.0,
    this.musicVolume = 0.5,
    this.videoSpeed = 1.0,
    this.textOverlays,
    this.videoFilter,
    this.privacy = 'public',
    this.locationName,
    this.locationLat,
    this.locationLng,
    this.taggedUsers,
    this.scheduledAt,
    this.title,
    this.lastEditedAt,
    this.autoSaveVersion = 1,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = DraftStatus.local,
  });

  factory PostDraft.fromJson(Map<String, dynamic> json) {
    return PostDraft(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      postType: DraftPostType.fromString(json['post_type'] ?? 'text'),
      content: json['content'],
      backgroundColor: json['background_color'],
      mediaFiles: (json['media_files'] as List<dynamic>?)
          ?.map((m) => DraftMediaFile.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
      audioPath: json['audio_path'],
      audioDuration: json['audio_duration'],
      audioWaveform: (json['audio_waveform'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      coverImagePath: json['cover_image_path'],
      musicTrackId: json['music_track_id'],
      musicStartTime: json['music_start_time'],
      originalAudioVolume: (json['original_audio_volume'] as num?)?.toDouble() ?? 1.0,
      musicVolume: (json['music_volume'] as num?)?.toDouble() ?? 0.5,
      videoSpeed: (json['video_speed'] as num?)?.toDouble() ?? 1.0,
      textOverlays: (json['text_overlays'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      videoFilter: json['video_filter'],
      privacy: json['privacy'] ?? 'public',
      locationName: json['location_name'],
      locationLat: (json['location_lat'] as num?)?.toDouble(),
      locationLng: (json['location_lng'] as num?)?.toDouble(),
      taggedUsers: (json['tagged_users'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'])
          : null,
      title: json['title'],
      lastEditedAt: json['last_edited_at'] != null
          ? DateTime.parse(json['last_edited_at'])
          : null,
      autoSaveVersion: json['auto_save_version'] ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      syncStatus: DraftStatus.synced,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'post_type': postType.value,
    'content': content,
    'background_color': backgroundColor,
    'media_files': mediaFiles.map((m) => m.toJson()).toList(),
    'audio_path': audioPath,
    'audio_duration': audioDuration,
    'audio_waveform': audioWaveform,
    'cover_image_path': coverImagePath,
    'music_track_id': musicTrackId,
    'music_start_time': musicStartTime,
    'original_audio_volume': originalAudioVolume,
    'music_volume': musicVolume,
    'video_speed': videoSpeed,
    'text_overlays': textOverlays,
    'video_filter': videoFilter,
    'privacy': privacy,
    'location_name': locationName,
    'location_lat': locationLat,
    'location_lng': locationLng,
    'tagged_users': taggedUsers,
    'scheduled_at': scheduledAt?.toIso8601String(),
    'title': title,
    'last_edited_at': lastEditedAt?.toIso8601String(),
    'auto_save_version': autoSaveVersion,
  };

  /// Create a copy with updated fields
  PostDraft copyWith({
    int? id,
    int? userId,
    DraftPostType? postType,
    String? content,
    String? backgroundColor,
    List<DraftMediaFile>? mediaFiles,
    String? audioPath,
    int? audioDuration,
    List<double>? audioWaveform,
    String? coverImagePath,
    int? musicTrackId,
    int? musicStartTime,
    double? originalAudioVolume,
    double? musicVolume,
    double? videoSpeed,
    List<Map<String, dynamic>>? textOverlays,
    String? videoFilter,
    String? privacy,
    String? locationName,
    double? locationLat,
    double? locationLng,
    List<int>? taggedUsers,
    DateTime? scheduledAt,
    String? title,
    DateTime? lastEditedAt,
    int? autoSaveVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
    DraftStatus? syncStatus,
  }) {
    return PostDraft(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      postType: postType ?? this.postType,
      content: content ?? this.content,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      mediaFiles: mediaFiles ?? this.mediaFiles,
      audioPath: audioPath ?? this.audioPath,
      audioDuration: audioDuration ?? this.audioDuration,
      audioWaveform: audioWaveform ?? this.audioWaveform,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      musicTrackId: musicTrackId ?? this.musicTrackId,
      musicStartTime: musicStartTime ?? this.musicStartTime,
      originalAudioVolume: originalAudioVolume ?? this.originalAudioVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      videoSpeed: videoSpeed ?? this.videoSpeed,
      textOverlays: textOverlays ?? this.textOverlays,
      videoFilter: videoFilter ?? this.videoFilter,
      privacy: privacy ?? this.privacy,
      locationName: locationName ?? this.locationName,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      taggedUsers: taggedUsers ?? this.taggedUsers,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      title: title ?? this.title,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      autoSaveVersion: autoSaveVersion ?? this.autoSaveVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  /// Get display title
  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    if (content != null && content!.isNotEmpty) {
      return content!.length > 50 ? '${content!.substring(0, 50)}...' : content!;
    }
    return '${postType.label} Draft';
  }

  /// Get type icon
  IconData get typeIcon => postType.icon;

  /// Check if draft has media
  bool get hasMedia => mediaFiles.isNotEmpty || audioPath != null;

  /// Check if draft is scheduled
  bool get isScheduled => scheduledAt != null;

  /// Check if draft can be published
  bool get canPublish {
    switch (postType) {
      case DraftPostType.text:
        return content != null && content!.isNotEmpty;
      case DraftPostType.photo:
      case DraftPostType.video:
      case DraftPostType.shortVideo:
        return mediaFiles.isNotEmpty;
      case DraftPostType.audio:
        return audioPath != null;
    }
  }

  /// Get thumbnail URL for preview
  String? get thumbnailUrl {
    if (mediaFiles.isNotEmpty) {
      return mediaFiles.first.thumbnailPath ?? mediaFiles.first.path;
    }
    if (coverImagePath != null) return coverImagePath;
    return null;
  }

  /// Format audio duration
  String get formattedAudioDuration {
    if (audioDuration == null) return '0:00';
    final minutes = audioDuration! ~/ 60;
    final seconds = audioDuration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get relative time since last edit
  String get lastEditedAgo {
    final editTime = lastEditedAt ?? updatedAt ?? createdAt;
    if (editTime == null) return 'Never';

    final diff = DateTime.now().difference(editTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${editTime.day}/${editTime.month}/${editTime.year}';
  }
}

/// Draft counts response
class DraftCounts {
  final int total;
  final Map<String, int> byType;
  final int scheduled;

  DraftCounts({
    required this.total,
    required this.byType,
    required this.scheduled,
  });

  factory DraftCounts.fromJson(Map<String, dynamic> json) {
    return DraftCounts(
      total: json['total'] ?? 0,
      byType: Map<String, int>.from(json['by_type'] ?? {}),
      scheduled: json['scheduled'] ?? 0,
    );
  }

  int getCountForType(DraftPostType type) => byType[type.value] ?? 0;
}
