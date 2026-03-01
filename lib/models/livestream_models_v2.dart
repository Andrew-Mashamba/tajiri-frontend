/// Military-grade livestream models with enhanced status flow
/// Status Flow: scheduled → pre_live → live → ending → ended
import '../config/api_config.dart';

/// Enhanced LiveStream Status
enum StreamStatus {
  /// Stream is scheduled for future
  scheduled,

  /// 15-30min before: Standby phase, countdown active, notifications sent
  preLive,

  /// Stream is live and broadcasting
  live,

  /// Stream is ending, showing outro/thank you screen
  ending,

  /// Stream has ended
  ended,

  /// Stream was cancelled
  cancelled,
}

extension StreamStatusExtension on StreamStatus {
  String get value => toString().split('.').last;

  bool get canGoLive => this == StreamStatus.preLive;
  bool get isActive => this == StreamStatus.live;
  bool get isScheduled => this == StreamStatus.scheduled;
  bool get isPreLive => this == StreamStatus.preLive;
  bool get hasEnded => this == StreamStatus.ended || this == StreamStatus.cancelled;

  String get swahiliLabel {
    switch (this) {
      case StreamStatus.scheduled:
        return 'Imepangwa';
      case StreamStatus.preLive:
        return 'Inaanza Hivi Karibuni';
      case StreamStatus.live:
        return 'Moja kwa Moja';
      case StreamStatus.ending:
        return 'Inamalizika';
      case StreamStatus.ended:
        return 'Imeisha';
      case StreamStatus.cancelled:
        return 'Imesitishwa';
    }
  }
}

/// Enhanced LiveStream Model
class LiveStreamV2 {
  final int id;
  final String streamKey;
  final int userId;
  final String title;
  final String? description;
  final String? thumbnailPath;
  final String? category;
  final List<String> tags;

  // Status and timing
  final StreamStatus status;
  final DateTime? scheduledAt;
  final DateTime? preLiveStartedAt;  // When standby phase started
  final DateTime? liveStartedAt;     // When actually went live
  final DateTime? endedAt;
  final int? duration;               // In seconds

  // Settings
  final String privacy;              // public, friends, private
  final bool isRecorded;
  final bool allowComments;
  final bool allowGifts;
  final bool allowCoHosts;

  // URLs
  final String? streamUrl;           // RTMP ingest URL
  final String? playbackUrl;         // HLS/DASH playback URL
  final String? recordingPath;

  // Analytics
  final int currentViewers;
  final int peakViewers;
  final int totalViewers;
  final int uniqueViewers;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;

  // Engagement
  final int giftsCount;
  final double giftsValue;
  final Map<String, int> reactionCounts;  // like, love, fire, clap, etc.

  // Metadata
  final StreamUser? user;
  final List<StreamCoHost> coHosts;
  final List<String> viewerIds;      // Currently watching
  final DateTime createdAt;
  final DateTime updatedAt;

  // User interaction
  final bool? isLiked;
  final bool? isFollowingHost;
  final String? userReaction;

  const LiveStreamV2({
    required this.id,
    required this.streamKey,
    required this.userId,
    required this.title,
    this.description,
    this.thumbnailPath,
    this.category,
    this.tags = const [],
    this.status = StreamStatus.scheduled,
    this.scheduledAt,
    this.preLiveStartedAt,
    this.liveStartedAt,
    this.endedAt,
    this.duration,
    this.privacy = 'public',
    this.isRecorded = true,
    this.allowComments = true,
    this.allowGifts = true,
    this.allowCoHosts = false,
    this.streamUrl,
    this.playbackUrl,
    this.recordingPath,
    this.currentViewers = 0,
    this.peakViewers = 0,
    this.totalViewers = 0,
    this.uniqueViewers = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.giftsCount = 0,
    this.giftsValue = 0.0,
    this.reactionCounts = const {},
    this.user,
    this.coHosts = const [],
    this.viewerIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isLiked,
    this.isFollowingHost,
    this.userReaction,
  });

  factory LiveStreamV2.fromJson(Map<String, dynamic> json) {
    return LiveStreamV2(
      id: json['id'],
      streamKey: json['stream_key'] ?? '',
      userId: json['user_id'],
      title: json['title'] ?? '',
      description: json['description'],
      thumbnailPath: json['thumbnail_path'],
      category: json['category'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      status: _parseStatus(json['status']),
      scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at']) : null,
      preLiveStartedAt: json['pre_live_started_at'] != null ? DateTime.parse(json['pre_live_started_at']) : null,
      liveStartedAt: json['live_started_at'] != null ? DateTime.parse(json['live_started_at']) : null,
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      duration: json['duration'],
      privacy: json['privacy'] ?? 'public',
      isRecorded: json['is_recorded'] ?? true,
      allowComments: json['allow_comments'] ?? true,
      allowGifts: json['allow_gifts'] ?? true,
      allowCoHosts: json['allow_co_hosts'] ?? false,
      streamUrl: json['stream_url'],
      playbackUrl: json['playback_url'],
      recordingPath: json['recording_path'],
      currentViewers: json['current_viewers'] ?? 0,
      peakViewers: json['peak_viewers'] ?? 0,
      totalViewers: json['total_viewers'] ?? 0,
      uniqueViewers: json['unique_viewers'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      sharesCount: json['shares_count'] ?? 0,
      giftsCount: json['gifts_count'] ?? 0,
      giftsValue: (json['gifts_value'] ?? 0).toDouble(),
      reactionCounts: json['reaction_counts'] != null
          ? Map<String, int>.from(json['reaction_counts'])
          : {},
      user: json['user'] != null ? StreamUser.fromJson(json['user']) : null,
      coHosts: json['co_hosts'] != null
          ? (json['co_hosts'] as List).map((c) => StreamCoHost.fromJson(c)).toList()
          : [],
      viewerIds: json['viewer_ids'] != null ? List<String>.from(json['viewer_ids']) : [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isLiked: json['is_liked'],
      isFollowingHost: json['is_following_host'],
      userReaction: json['user_reaction'],
    );
  }

  static StreamStatus _parseStatus(String? status) {
    switch (status) {
      case 'pre_live':
        return StreamStatus.preLive;
      case 'live':
        return StreamStatus.live;
      case 'ending':
        return StreamStatus.ending;
      case 'ended':
        return StreamStatus.ended;
      case 'cancelled':
        return StreamStatus.cancelled;
      default:
        return StreamStatus.scheduled;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stream_key': streamKey,
      'user_id': userId,
      'title': title,
      'description': description,
      'thumbnail_path': thumbnailPath,
      'category': category,
      'tags': tags,
      'status': status.value,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'pre_live_started_at': preLiveStartedAt?.toIso8601String(),
      'live_started_at': liveStartedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration': duration,
      'privacy': privacy,
      'is_recorded': isRecorded,
      'allow_comments': allowComments,
      'allow_gifts': allowGifts,
      'allow_co_hosts': allowCoHosts,
      'stream_url': streamUrl,
      'playback_url': playbackUrl,
      'recording_path': recordingPath,
    };
  }

  LiveStreamV2 copyWith({
    int? id,
    String? streamKey,
    int? userId,
    String? title,
    String? description,
    String? thumbnailPath,
    String? category,
    List<String>? tags,
    StreamStatus? status,
    DateTime? scheduledAt,
    DateTime? preLiveStartedAt,
    DateTime? liveStartedAt,
    DateTime? endedAt,
    int? duration,
    String? privacy,
    bool? isRecorded,
    bool? allowComments,
    bool? allowGifts,
    bool? allowCoHosts,
    String? streamUrl,
    String? playbackUrl,
    String? recordingPath,
    int? currentViewers,
    int? peakViewers,
    int? totalViewers,
    int? uniqueViewers,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? giftsCount,
    double? giftsValue,
    Map<String, int>? reactionCounts,
    StreamUser? user,
    List<StreamCoHost>? coHosts,
    List<String>? viewerIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLiked,
    bool? isFollowingHost,
    String? userReaction,
  }) {
    return LiveStreamV2(
      id: id ?? this.id,
      streamKey: streamKey ?? this.streamKey,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      preLiveStartedAt: preLiveStartedAt ?? this.preLiveStartedAt,
      liveStartedAt: liveStartedAt ?? this.liveStartedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      privacy: privacy ?? this.privacy,
      isRecorded: isRecorded ?? this.isRecorded,
      allowComments: allowComments ?? this.allowComments,
      allowGifts: allowGifts ?? this.allowGifts,
      allowCoHosts: allowCoHosts ?? this.allowCoHosts,
      streamUrl: streamUrl ?? this.streamUrl,
      playbackUrl: playbackUrl ?? this.playbackUrl,
      recordingPath: recordingPath ?? this.recordingPath,
      currentViewers: currentViewers ?? this.currentViewers,
      peakViewers: peakViewers ?? this.peakViewers,
      totalViewers: totalViewers ?? this.totalViewers,
      uniqueViewers: uniqueViewers ?? this.uniqueViewers,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      giftsCount: giftsCount ?? this.giftsCount,
      giftsValue: giftsValue ?? this.giftsValue,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      user: user ?? this.user,
      coHosts: coHosts ?? this.coHosts,
      viewerIds: viewerIds ?? this.viewerIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLiked: isLiked ?? this.isLiked,
      isFollowingHost: isFollowingHost ?? this.isFollowingHost,
      userReaction: userReaction ?? this.userReaction,
    );
  }

  String get thumbnailUrl => thumbnailPath != null
      ? '${ApiConfig.storageUrl}/$thumbnailPath'
      : '';

  String get durationFormatted {
    if (duration == null) return '0:00';
    final hours = duration! ~/ 3600;
    final minutes = (duration! % 3600) ~/ 60;
    final seconds = duration! % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Time remaining until stream starts (for scheduled/pre-live streams)
  Duration? get timeUntilStart {
    if (scheduledAt == null) return null;
    final now = DateTime.now();
    if (scheduledAt!.isBefore(now)) return Duration.zero;
    return scheduledAt!.difference(now);
  }

  /// Is stream starting soon (within 30 minutes)?
  bool get isStartingSoon {
    final remaining = timeUntilStart;
    if (remaining == null) return false;
    return remaining.inMinutes <= 30 && remaining.inMinutes > 0;
  }

  /// Should automatically transition to pre-live?
  bool get shouldGoToPreLive {
    return status == StreamStatus.scheduled && isStartingSoon;
  }
}

/// Stream User Model
class StreamUser {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePhotoPath;
  final bool? isVerified;
  final int? followersCount;

  const StreamUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.profilePhotoPath,
    this.isVerified,
    this.followersCount,
  });

  factory StreamUser.fromJson(Map<String, dynamic> json) {
    return StreamUser(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'],
      profilePhotoPath: json['profile_photo_path'],
      isVerified: json['is_verified'],
      followersCount: json['followers_count'],
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  String get displayName => username ?? fullName;

  String get profilePhotoUrl => profilePhotoPath != null
      ? '${ApiConfig.storageUrl}/$profilePhotoPath'
      : '';
}

/// Stream Co-Host Model
class StreamCoHost {
  final int id;
  final int userId;
  final String firstName;
  final String lastName;
  final String? profilePhotoPath;
  final bool isActive;
  final DateTime joinedAt;

  const StreamCoHost({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.profilePhotoPath,
    this.isActive = false,
    required this.joinedAt,
  });

  factory StreamCoHost.fromJson(Map<String, dynamic> json) {
    return StreamCoHost(
      id: json['id'],
      userId: json['user_id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profilePhotoPath: json['profile_photo_path'],
      isActive: json['is_active'] ?? false,
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}

/// Stream Comment Model (for real-time chat)
class StreamComment {
  final int id;
  final int streamId;
  final int userId;
  final String userName;
  final String? userPhotoPath;
  final String message;
  final bool isPinned;
  final bool isHighlighted;
  final DateTime createdAt;

  const StreamComment({
    required this.id,
    required this.streamId,
    required this.userId,
    required this.userName,
    this.userPhotoPath,
    required this.message,
    this.isPinned = false,
    this.isHighlighted = false,
    required this.createdAt,
  });

  factory StreamComment.fromJson(Map<String, dynamic> json) {
    return StreamComment(
      id: json['id'],
      streamId: json['stream_id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? '',
      userPhotoPath: json['user_photo_path'],
      message: json['message'] ?? '',
      isPinned: json['is_pinned'] ?? false,
      isHighlighted: json['is_highlighted'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Virtual Gift Model
class VirtualGift {
  final int id;
  final String name;
  final String iconPath;
  final double value;  // TZS
  final String? animation;

  const VirtualGift({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.value,
    this.animation,
  });

  factory VirtualGift.fromJson(Map<String, dynamic> json) {
    return VirtualGift(
      id: json['id'],
      name: json['name'] ?? '',
      iconPath: json['icon_path'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      animation: json['animation'],
    );
  }

  String get iconUrl => '${ApiConfig.storageUrl}/$iconPath';
}

/// Stream Analytics Model
class StreamAnalytics {
  final int streamId;
  final int totalViewers;
  final int uniqueViewers;
  final int peakViewers;
  final double averageWatchTime;  // seconds
  final int totalLikes;
  final int totalComments;
  final int totalShares;
  final int totalGifts;
  final double totalRevenue;  // TZS
  final Map<String, int> viewersByRegion;
  final List<ViewerRetention> retentionData;

  const StreamAnalytics({
    required this.streamId,
    required this.totalViewers,
    required this.uniqueViewers,
    required this.peakViewers,
    required this.averageWatchTime,
    required this.totalLikes,
    required this.totalComments,
    required this.totalShares,
    required this.totalGifts,
    required this.totalRevenue,
    this.viewersByRegion = const {},
    this.retentionData = const [],
  });

  factory StreamAnalytics.fromJson(Map<String, dynamic> json) {
    return StreamAnalytics(
      streamId: json['stream_id'],
      totalViewers: json['total_viewers'] ?? 0,
      uniqueViewers: json['unique_viewers'] ?? 0,
      peakViewers: json['peak_viewers'] ?? 0,
      averageWatchTime: (json['average_watch_time'] ?? 0).toDouble(),
      totalLikes: json['total_likes'] ?? 0,
      totalComments: json['total_comments'] ?? 0,
      totalShares: json['total_shares'] ?? 0,
      totalGifts: json['total_gifts'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      viewersByRegion: json['viewers_by_region'] != null
          ? Map<String, int>.from(json['viewers_by_region'])
          : {},
      retentionData: json['retention_data'] != null
          ? (json['retention_data'] as List)
              .map((r) => ViewerRetention.fromJson(r))
              .toList()
          : [],
    );
  }
}

/// Viewer Retention Data Point
class ViewerRetention {
  final int timestamp;  // seconds from start
  final int viewers;

  const ViewerRetention({
    required this.timestamp,
    required this.viewers,
  });

  factory ViewerRetention.fromJson(Map<String, dynamic> json) {
    return ViewerRetention(
      timestamp: json['timestamp'],
      viewers: json['viewers'],
    );
  }
}
