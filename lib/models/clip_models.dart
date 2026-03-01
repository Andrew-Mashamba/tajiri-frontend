import '../config/api_config.dart';

class Clip {
  final int id;
  final int userId;
  final String videoPath;
  final String? thumbnailPath;
  final String? caption;
  final int duration;
  final int? musicId;
  final int? musicStart;
  final List<String>? hashtags;
  final List<int>? mentions;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String privacy;
  final bool allowComments;
  final bool allowDuet;
  final bool allowStitch;
  final bool allowDownload;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int savesCount;
  final int duetsCount;
  final bool isFeatured;
  final String status;
  final int? originalClipId;
  final String clipType;
  final DateTime createdAt;
  final ClipUser? user;
  final ClipMusic? music;
  final Clip? originalClip;
  final bool? isLiked;
  final bool? isSaved;
  /// Whether current user is subscribed to the clip author (for subscribers-only content)
  final bool isSubscribedToAuthor;

  Clip({
    required this.id,
    required this.userId,
    required this.videoPath,
    this.thumbnailPath,
    this.caption,
    required this.duration,
    this.musicId,
    this.musicStart,
    this.hashtags,
    this.mentions,
    this.locationName,
    this.latitude,
    this.longitude,
    this.privacy = 'public',
    this.allowComments = true,
    this.allowDuet = true,
    this.allowStitch = true,
    this.allowDownload = true,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.savesCount = 0,
    this.duetsCount = 0,
    this.isFeatured = false,
    this.status = 'published',
    this.originalClipId,
    this.clipType = 'original',
    required this.createdAt,
    this.user,
    this.music,
    this.originalClip,
    this.isLiked,
    this.isSaved,
    this.isSubscribedToAuthor = false,
  });

  factory Clip.fromJson(Map<String, dynamic> json) {
    return Clip(
      id: json['id'],
      userId: json['user_id'],
      videoPath: json['video_path'] ?? '',
      thumbnailPath: json['thumbnail_path'],
      caption: json['caption'],
      duration: json['duration'] ?? 0,
      musicId: json['music_id'],
      musicStart: json['music_start'],
      hashtags: json['hashtags'] != null ? List<String>.from(json['hashtags']) : null,
      mentions: json['mentions'] != null ? List<int>.from(json['mentions']) : null,
      locationName: json['location_name'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      privacy: json['privacy'] ?? 'public',
      allowComments: json['allow_comments'] ?? true,
      allowDuet: json['allow_duet'] ?? true,
      allowStitch: json['allow_stitch'] ?? true,
      allowDownload: json['allow_download'] ?? true,
      viewsCount: json['views_count'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      sharesCount: json['shares_count'] ?? 0,
      savesCount: json['saves_count'] ?? 0,
      duetsCount: json['duets_count'] ?? 0,
      isFeatured: json['is_featured'] ?? false,
      status: json['status'] ?? 'published',
      originalClipId: json['original_clip_id'],
      clipType: json['clip_type'] ?? 'original',
      createdAt: DateTime.parse(json['created_at']),
      user: json['user'] != null ? ClipUser.fromJson(json['user']) : null,
      music: json['music'] != null ? ClipMusic.fromJson(json['music']) : null,
      originalClip: json['original_clip'] != null ? Clip.fromJson(json['original_clip']) : null,
      isLiked: json['is_liked'],
      isSaved: json['is_saved'],
      isSubscribedToAuthor: json['is_subscribed_to_author'] == true,
    );
  }

  String get videoUrl => '${ApiConfig.storageUrl}/$videoPath';
  String get thumbnailUrl => thumbnailPath != null
      ? '${ApiConfig.storageUrl}/$thumbnailPath'
      : '';
  bool get isDuet => clipType == 'duet';
  bool get isStitch => clipType == 'stitch';
}

class ClipUser {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePhotoPath;

  ClipUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.profilePhotoPath,
  });

  factory ClipUser.fromJson(Map<String, dynamic> json) {
    return ClipUser(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'],
      profilePhotoPath: json['profile_photo_path'],
    );
  }

  String get fullName => '$firstName $lastName';
  String get displayName => username ?? fullName;
  String get avatarUrl => profilePhotoPath != null
      ? '${ApiConfig.storageUrl}/$profilePhotoPath'
      : '';
}

class ClipMusic {
  final int id;
  final String title;
  final String? coverPath;
  final int duration;
  final ClipArtist? artist;

  ClipMusic({
    required this.id,
    required this.title,
    this.coverPath,
    this.duration = 0,
    this.artist,
  });

  factory ClipMusic.fromJson(Map<String, dynamic> json) {
    return ClipMusic(
      id: json['id'],
      title: json['title'] ?? '',
      coverPath: json['cover_path'],
      duration: json['duration'] ?? 0,
      artist: json['artist'] != null ? ClipArtist.fromJson(json['artist']) : null,
    );
  }

  String get coverUrl => coverPath != null
      ? '${ApiConfig.storageUrl}/$coverPath'
      : '';
  String get displayTitle => artist != null ? '${artist!.name} - $title' : title;
}

class ClipArtist {
  final int id;
  final String name;

  ClipArtist({required this.id, required this.name});

  factory ClipArtist.fromJson(Map<String, dynamic> json) {
    return ClipArtist(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }
}

class ClipComment {
  final int id;
  final int clipId;
  final int userId;
  final int? parentId;
  final String content;
  final int likesCount;
  final int repliesCount;
  final bool isPinned;
  final DateTime createdAt;
  final ClipUser? user;
  final List<ClipComment>? replies;
  final bool? isLiked;

  ClipComment({
    required this.id,
    required this.clipId,
    required this.userId,
    this.parentId,
    required this.content,
    this.likesCount = 0,
    this.repliesCount = 0,
    this.isPinned = false,
    required this.createdAt,
    this.user,
    this.replies,
    this.isLiked,
  });

  factory ClipComment.fromJson(Map<String, dynamic> json) {
    return ClipComment(
      id: json['id'],
      clipId: json['clip_id'],
      userId: json['user_id'],
      parentId: json['parent_id'],
      content: json['content'] ?? '',
      likesCount: json['likes_count'] ?? 0,
      repliesCount: json['replies_count'] ?? 0,
      isPinned: json['is_pinned'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      user: json['user'] != null ? ClipUser.fromJson(json['user']) : null,
      replies: json['replies'] != null
          ? (json['replies'] as List).map((r) => ClipComment.fromJson(r)).toList()
          : null,
      isLiked: json['is_liked'],
    );
  }
}

class ClipHashtag {
  final int id;
  final String tag;
  final int clipsCount;
  final int viewsCount;
  final bool isTrending;

  ClipHashtag({
    required this.id,
    required this.tag,
    this.clipsCount = 0,
    this.viewsCount = 0,
    this.isTrending = false,
  });

  String get displayTag => '#$tag';

  factory ClipHashtag.fromJson(Map<String, dynamic> json) {
    return ClipHashtag(
      id: json['id'],
      tag: json['tag'] ?? '',
      clipsCount: json['clips_count'] ?? 0,
      viewsCount: json['views_count'] ?? 0,
      isTrending: json['is_trending'] ?? false,
    );
  }
}

// ============================================================================
// YouTube-style Video Performance Models
// Based on research: Adaptive bitrate, LRU caching, segment preloading
// ============================================================================

/// Video quality level for adaptive streaming
enum VideoQuality {
  auto('Auto', 0),
  low('360p', 360),
  medium('480p', 480),
  high('720p', 720),
  hd('1080p', 1080);

  final String label;
  final int height;
  const VideoQuality(this.label, this.height);

  /// Get recommended quality based on network speed (Mbps)
  static VideoQuality forBandwidth(double mbps) {
    if (mbps < 1) return VideoQuality.low;
    if (mbps < 2.5) return VideoQuality.medium;
    if (mbps < 5) return VideoQuality.high;
    return VideoQuality.hd;
  }
}

/// Network connection type for quality decisions
enum NetworkType {
  wifi,
  cellular4g,
  cellular3g,
  cellular2g,
  offline,
  unknown;

  VideoQuality get recommendedQuality {
    switch (this) {
      case NetworkType.wifi:
        return VideoQuality.hd;
      case NetworkType.cellular4g:
        return VideoQuality.high;
      case NetworkType.cellular3g:
        return VideoQuality.medium;
      case NetworkType.cellular2g:
        return VideoQuality.low;
      case NetworkType.offline:
      case NetworkType.unknown:
        return VideoQuality.auto;
    }
  }
}

/// Video cache entry for LRU cache management
class VideoCacheEntry {
  final String url;
  final String localPath;
  final int fileSize;
  final DateTime cachedAt;
  final DateTime lastAccessedAt;
  final VideoQuality quality;
  final int clipId;

  VideoCacheEntry({
    required this.url,
    required this.localPath,
    required this.fileSize,
    required this.cachedAt,
    required this.lastAccessedAt,
    this.quality = VideoQuality.auto,
    this.clipId = 0,
  });

  /// Update last accessed time (for LRU tracking)
  VideoCacheEntry touch() {
    return VideoCacheEntry(
      url: url,
      localPath: localPath,
      fileSize: fileSize,
      cachedAt: cachedAt,
      lastAccessedAt: DateTime.now(),
      quality: quality,
      clipId: clipId,
    );
  }

  /// File size in MB
  double get fileSizeMB => fileSize / (1024 * 1024);

  /// Age of cache entry
  Duration get age => DateTime.now().difference(cachedAt);

  /// Time since last access
  Duration get idleTime => DateTime.now().difference(lastAccessedAt);

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'local_path': localPath,
      'file_size': fileSize,
      'cached_at': cachedAt.toIso8601String(),
      'last_accessed_at': lastAccessedAt.toIso8601String(),
      'quality': quality.name,
      'clip_id': clipId,
    };
  }

  factory VideoCacheEntry.fromJson(Map<String, dynamic> json) {
    return VideoCacheEntry(
      url: json['url'],
      localPath: json['local_path'],
      fileSize: json['file_size'],
      cachedAt: DateTime.parse(json['cached_at']),
      lastAccessedAt: DateTime.parse(json['last_accessed_at']),
      quality: VideoQuality.values.firstWhere(
        (q) => q.name == json['quality'],
        orElse: () => VideoQuality.auto,
      ),
      clipId: json['clip_id'] ?? 0,
    );
  }
}

/// Preload state for video (YouTube-style prefetching)
enum PreloadState {
  none,        // Not started
  queued,      // In preload queue
  loading,     // Currently downloading
  partial,     // First segment loaded (ready for instant play)
  complete,    // Fully cached
  failed,      // Download failed
}

/// Video preload info for tracking prefetch progress
class VideoPreloadInfo {
  final int clipId;
  final String url;
  final PreloadState state;
  final double progress;  // 0.0 to 1.0
  final int bytesLoaded;
  final int? totalBytes;
  final String? error;
  final DateTime? startedAt;
  final int priority;  // Higher = more important

  VideoPreloadInfo({
    required this.clipId,
    required this.url,
    this.state = PreloadState.none,
    this.progress = 0.0,
    this.bytesLoaded = 0,
    this.totalBytes,
    this.error,
    this.startedAt,
    this.priority = 0,
  });

  /// Check if ready for playback (at least partial load)
  bool get isPlayable => state == PreloadState.partial || state == PreloadState.complete;

  /// Bytes loaded in MB
  double get bytesLoadedMB => bytesLoaded / (1024 * 1024);

  VideoPreloadInfo copyWith({
    PreloadState? state,
    double? progress,
    int? bytesLoaded,
    int? totalBytes,
    String? error,
    DateTime? startedAt,
    int? priority,
  }) {
    return VideoPreloadInfo(
      clipId: clipId,
      url: url,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      bytesLoaded: bytesLoaded ?? this.bytesLoaded,
      totalBytes: totalBytes ?? this.totalBytes,
      error: error ?? this.error,
      startedAt: startedAt ?? this.startedAt,
      priority: priority ?? this.priority,
    );
  }
}

/// Buffer state for video playback
class VideoBufferState {
  final Duration bufferedPosition;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isBuffering;
  final double bufferHealth;  // Seconds of video buffered ahead

  VideoBufferState({
    this.bufferedPosition = Duration.zero,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.isBuffering = false,
    this.bufferHealth = 0.0,
  });

  /// Percentage of video buffered
  double get bufferPercent {
    if (totalDuration.inMilliseconds == 0) return 0.0;
    return bufferedPosition.inMilliseconds / totalDuration.inMilliseconds;
  }

  /// Percentage of video played
  double get playPercent {
    if (totalDuration.inMilliseconds == 0) return 0.0;
    return currentPosition.inMilliseconds / totalDuration.inMilliseconds;
  }

  /// Is buffer healthy (>3 seconds ahead)
  bool get isHealthy => bufferHealth >= 3.0;
}

/// Clip feed state for managing video feed
class ClipFeedState {
  final List<Clip> clips;
  final int currentIndex;
  final Map<int, VideoPreloadInfo> preloadStates;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  ClipFeedState({
    this.clips = const [],
    this.currentIndex = 0,
    this.preloadStates = const {},
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  Clip? get currentClip =>
      currentIndex >= 0 && currentIndex < clips.length ? clips[currentIndex] : null;

  Clip? get nextClip =>
      currentIndex + 1 < clips.length ? clips[currentIndex + 1] : null;

  Clip? get previousClip =>
      currentIndex > 0 ? clips[currentIndex - 1] : null;

  /// Get clips that should be preloaded (current ± 2)
  List<Clip> get clipsToPreload {
    final result = <Clip>[];
    for (var i = currentIndex - 1; i <= currentIndex + 2; i++) {
      if (i >= 0 && i < clips.length) {
        result.add(clips[i]);
      }
    }
    return result;
  }

  ClipFeedState copyWith({
    List<Clip>? clips,
    int? currentIndex,
    Map<int, VideoPreloadInfo>? preloadStates,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return ClipFeedState(
      clips: clips ?? this.clips,
      currentIndex: currentIndex ?? this.currentIndex,
      preloadStates: preloadStates ?? this.preloadStates,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

