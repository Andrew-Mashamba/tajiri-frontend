/// Post and comment models for social features
/// Enhanced with TikTok/Instagram/Twitter-style engagement tracking

import 'package:flutter/material.dart';
import '../config/api_config.dart';

/// Helper to safely parse int from String or int
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Helper to safely parse double from String, int, or double
double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Helper to safely parse bool from dynamic
bool _parseBool(dynamic value, [bool defaultValue = false]) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return defaultValue;
}

/// Helper to build storage URL from path
/// Handles paths starting with / to avoid double slashes
String _buildStorageUrl(String path) {
  if (path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  // Remove leading slash to avoid double slashes
  final cleanPath = path.startsWith('/') ? path.substring(1) : path;
  return '${ApiConfig.storageUrl}/$cleanPath';
}

class Post {
  final int id;
  final int userId;
  final String? content;
  final PostType postType;
  final PostPrivacy privacy;
  final String? locationName;
  final List<int>? taggedUsers;

  // Core engagement counters
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;
  final int savesCount;
  final int repliesCount;
  final int impressionsCount;

  // Video engagement
  final int watchTimeSeconds;

  // Algorithmic scores
  final double engagementScore;
  final double trendingScore;

  // Post flags
  final bool isPinned;
  final bool isShortVideo;
  final bool isViral;
  final bool isFeatured;

  final int? originalPostId;
  final int? regionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PostUser? user;
  final List<PostMedia> media;
  final List<Hashtag> hashtags;
  final Post? originalPost;

  // User interaction state
  bool isLiked;
  bool isSaved;
  ReactionType? userReaction;
  /// Whether current user is subscribed to the post author (for subscribers-only content)
  bool isSubscribedToAuthor;

  // New fields for enhanced post types
  final String? backgroundColor; // Hex color for text-only posts
  final String? audioPath; // Direct audio file path
  final int? audioDuration; // Audio duration in seconds
  final List<double>? audioWaveform; // Waveform data points
  final String? coverImagePath; // Cover image for audio posts

  // Music track fields (for short videos with music)
  final int? musicTrackId;
  final int? musicStartTime; // Start position in music track
  final double originalAudioVolume; // 0.0 - 1.0
  final double musicVolume; // 0.0 - 1.0
  final MusicTrack? musicTrack;

  // Video processing fields
  final double videoSpeed; // 0.5 - 2.0
  final List<TextOverlay>? textOverlays;
  final String? videoFilter;

  // Poll (for post_type == poll)
  final int? pollId;

  /// Whether commenting is allowed on this post (post author can disable).
  final bool allowComments;

  Post({
    required this.id,
    required this.userId,
    this.content,
    this.postType = PostType.text,
    this.privacy = PostPrivacy.public,
    this.locationName,
    this.taggedUsers,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    this.savesCount = 0,
    this.repliesCount = 0,
    this.impressionsCount = 0,
    this.watchTimeSeconds = 0,
    this.engagementScore = 0.0,
    this.trendingScore = 0.0,
    this.isPinned = false,
    this.isShortVideo = false,
    this.isViral = false,
    this.isFeatured = false,
    this.originalPostId,
    this.regionId,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.media = const [],
    this.hashtags = const [],
    this.originalPost,
    this.isLiked = false,
    this.isSaved = false,
    this.userReaction,
    this.isSubscribedToAuthor = false,
    // New fields
    this.backgroundColor,
    this.audioPath,
    this.audioDuration,
    this.audioWaveform,
    this.coverImagePath,
    this.musicTrackId,
    this.musicStartTime,
    this.originalAudioVolume = 1.0,
    this.musicVolume = 1.0,
    this.musicTrack,
    this.videoSpeed = 1.0,
    this.textOverlays,
    this.videoFilter,
    this.pollId,
    this.allowComments = true,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      content: json['content'],
      postType: PostType.fromString((json['post_type'] ?? json['type'])?.toString() ?? 'text'),
      privacy: PostPrivacy.fromString((json['privacy'] ?? 'public').toString()),
      locationName: json['location_name'],
      taggedUsers: json['tagged_users'] != null
          ? (json['tagged_users'] as List).map((e) => _parseInt(e)).toList()
          : null,
      likesCount: _parseInt(json['likes_count']),
      commentsCount: _parseInt(json['comments_count']),
      sharesCount: _parseInt(json['shares_count']),
      viewsCount: _parseInt(json['views_count']),
      savesCount: _parseInt(json['saves_count']),
      repliesCount: _parseInt(json['replies_count']),
      impressionsCount: _parseInt(json['impressions_count']),
      watchTimeSeconds: _parseInt(json['watch_time_seconds']),
      engagementScore: _parseDouble(json['engagement_score']),
      trendingScore: _parseDouble(json['trending_score']),
      isPinned: _parseBool(json['is_pinned']),
      isShortVideo: _parseBool(json['is_short_video']),
      isViral: _parseBool(json['is_viral']),
      isFeatured: _parseBool(json['is_featured']),
      originalPostId: json['original_post_id'] != null ? _parseInt(json['original_post_id']) : null,
      regionId: json['region_id'] != null ? _parseInt(json['region_id']) : null,
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
      user: json['user'] != null
          ? (json['user'] is Map<String, dynamic>
              ? PostUser.fromJson(json['user'] as Map<String, dynamic>)
              : PostUser(id: _parseInt(json['user']), firstName: '', lastName: ''))
          : null,
      media: json['media'] != null
          ? (json['media'] as List).map((m) => PostMedia.fromJson(m)).toList()
          : [],
      hashtags: json['hashtags'] != null
          ? (json['hashtags'] as List).map((h) => Hashtag.fromJson(h)).toList()
          : [],
      originalPost: json['original_post'] != null
          ? Post.fromJson(json['original_post'])
          : null,
      isLiked: _parseBool(json['is_liked']),
      isSaved: _parseBool(json['is_saved']),
      userReaction: json['user_reaction'] != null
          ? ReactionType.fromString(json['user_reaction'].toString())
          : null,
      isSubscribedToAuthor: _parseBool(json['is_subscribed_to_author']),
      // New fields
      backgroundColor: json['background_color'],
      audioPath: json['audio_path'],
      audioDuration: json['audio_duration'] != null ? _parseInt(json['audio_duration']) : null,
      audioWaveform: json['audio_waveform'] != null
          ? List<double>.from((json['audio_waveform'] as List).map((e) => _parseDouble(e)))
          : null,
      coverImagePath: json['cover_image_path'],
      musicTrackId: json['music_track_id'] != null ? _parseInt(json['music_track_id']) : null,
      musicStartTime: json['music_start_time'] != null ? _parseInt(json['music_start_time']) : null,
      originalAudioVolume: _parseDouble(json['original_audio_volume'], 1.0),
      musicVolume: _parseDouble(json['music_volume'], 1.0),
      musicTrack: json['music_track'] != null ? MusicTrack.fromJson(json['music_track']) : null,
      videoSpeed: _parseDouble(json['video_speed'], 1.0),
      textOverlays: json['text_overlays'] != null
          ? (json['text_overlays'] as List).map((t) => TextOverlay.fromJson(t)).toList()
          : null,
      videoFilter: json['video_filter'],
      pollId: json['poll_id'] != null ? _parseInt(json['poll_id']) : null,
      allowComments: _parseBool(json['allow_comments'], true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'post_type': postType.value,
      'privacy': privacy.value,
      'location_name': locationName,
      'tagged_users': taggedUsers,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'shares_count': sharesCount,
      'views_count': viewsCount,
      'saves_count': savesCount,
      'is_pinned': isPinned,
      'is_short_video': isShortVideo,
      'original_post_id': originalPostId,
      'region_id': regionId,
      // New fields
      'background_color': backgroundColor,
      'audio_path': audioPath,
      'audio_duration': audioDuration,
      'audio_waveform': audioWaveform,
      'cover_image_path': coverImagePath,
      'music_track_id': musicTrackId,
      'music_start_time': musicStartTime,
      'original_audio_volume': originalAudioVolume,
      'music_volume': musicVolume,
      'video_speed': videoSpeed,
      'text_overlays': textOverlays?.map((t) => t.toJson()).toList(),
      'video_filter': videoFilter,
      if (pollId != null) 'poll_id': pollId,
    };
  }

  // Computed properties
  bool get hasMedia => media.isNotEmpty;
  bool get isShared => originalPostId != null;
  bool get hasVideo => media.any((m) => m.mediaType == MediaType.video);
  bool get hasImage => media.any((m) => m.mediaType == MediaType.image);
  bool get isMixedMedia => hasVideo && hasImage;
  bool get hasAudio => audioPath != null || media.any((m) => m.mediaType == MediaType.audio);
  bool get hasBackgroundColor => backgroundColor != null;
  bool get hasMusic => musicTrackId != null || musicTrack != null;

  /// Check if this is an audio-type post
  bool get isAudioPost => postType == PostType.audio || postType == PostType.audioText;

  /// Check if this is a text post with colored background
  bool get isColoredTextPost => postType == PostType.text && hasBackgroundColor;

  /// Get audio URL
  String? get audioUrl => audioPath != null ? _buildStorageUrl(audioPath!) : null;

  /// Get cover image URL
  String? get coverImageUrl => coverImagePath != null ? _buildStorageUrl(coverImagePath!) : null;

  /// Format audio duration as mm:ss
  String get formattedAudioDuration {
    if (audioDuration == null) return '00:00';
    final minutes = audioDuration! ~/ 60;
    final seconds = audioDuration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get primary video for shorts/reels display
  PostMedia? get primaryVideo =>
      media.where((m) => m.mediaType == MediaType.video).firstOrNull;

  /// Get primary image for thumbnail
  PostMedia? get primaryImage =>
      media.where((m) => m.mediaType == MediaType.image).firstOrNull;

  /// Get thumbnail URL (video thumbnail or first image)
  String? get thumbnailUrl {
    if (primaryVideo?.thumbnailUrl != null) return primaryVideo!.thumbnailUrl;
    if (primaryImage != null) return primaryImage!.fileUrl;
    return null;
  }

  /// Get video duration in seconds (from primary video)
  int get videoDuration => primaryVideo?.duration ?? 0;

  /// Format video duration as mm:ss
  String get formattedDuration {
    final duration = videoDuration;
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get engagement rate
  double get engagementRate {
    if (impressionsCount == 0) return 0.0;
    final engagements = likesCount + commentsCount + sharesCount + savesCount;
    return (engagements / impressionsCount) * 100;
  }

  /// Check if post is trending (based on score threshold)
  bool get isTrending => trendingScore > 50;

  /// True when the post was edited (updatedAt significantly after createdAt).
  /// Backend may alternatively send edited_at; if so, show indicator when edited_at != null.
  bool get isEdited =>
      updatedAt.difference(createdAt).inSeconds > 60;

  Post copyWith({
    int? id,
    int? userId,
    String? content,
    PostType? postType,
    PostPrivacy? privacy,
    String? locationName,
    List<int>? taggedUsers,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? viewsCount,
    int? savesCount,
    int? repliesCount,
    int? impressionsCount,
    int? watchTimeSeconds,
    double? engagementScore,
    double? trendingScore,
    bool? isPinned,
    bool? isShortVideo,
    bool? isViral,
    bool? isFeatured,
    int? originalPostId,
    int? regionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    PostUser? user,
    List<PostMedia>? media,
    List<Hashtag>? hashtags,
    Post? originalPost,
    bool? isLiked,
    bool? isSaved,
    ReactionType? userReaction,
    // New fields
    String? backgroundColor,
    String? audioPath,
    int? audioDuration,
    List<double>? audioWaveform,
    String? coverImagePath,
    int? musicTrackId,
    int? musicStartTime,
    double? originalAudioVolume,
    double? musicVolume,
    MusicTrack? musicTrack,
    double? videoSpeed,
    List<TextOverlay>? textOverlays,
    String? videoFilter,
    int? pollId,
    bool? allowComments,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      postType: postType ?? this.postType,
      privacy: privacy ?? this.privacy,
      locationName: locationName ?? this.locationName,
      taggedUsers: taggedUsers ?? this.taggedUsers,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      savesCount: savesCount ?? this.savesCount,
      repliesCount: repliesCount ?? this.repliesCount,
      impressionsCount: impressionsCount ?? this.impressionsCount,
      watchTimeSeconds: watchTimeSeconds ?? this.watchTimeSeconds,
      engagementScore: engagementScore ?? this.engagementScore,
      trendingScore: trendingScore ?? this.trendingScore,
      isPinned: isPinned ?? this.isPinned,
      isShortVideo: isShortVideo ?? this.isShortVideo,
      isViral: isViral ?? this.isViral,
      isFeatured: isFeatured ?? this.isFeatured,
      originalPostId: originalPostId ?? this.originalPostId,
      regionId: regionId ?? this.regionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
      media: media ?? this.media,
      hashtags: hashtags ?? this.hashtags,
      originalPost: originalPost ?? this.originalPost,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      userReaction: userReaction ?? this.userReaction,
      // New fields
      backgroundColor: backgroundColor ?? this.backgroundColor,
      audioPath: audioPath ?? this.audioPath,
      audioDuration: audioDuration ?? this.audioDuration,
      audioWaveform: audioWaveform ?? this.audioWaveform,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      musicTrackId: musicTrackId ?? this.musicTrackId,
      musicStartTime: musicStartTime ?? this.musicStartTime,
      originalAudioVolume: originalAudioVolume ?? this.originalAudioVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      musicTrack: musicTrack ?? this.musicTrack,
      videoSpeed: videoSpeed ?? this.videoSpeed,
      textOverlays: textOverlays ?? this.textOverlays,
      videoFilter: videoFilter ?? this.videoFilter,
      pollId: pollId ?? this.pollId,
      allowComments: allowComments ?? this.allowComments,
    );
  }
}

/// Reaction types (inspired by Facebook/Twitter reactions)
enum ReactionType {
  like('like'),
  love('love'),
  haha('haha'),
  wow('wow'),
  sad('sad'),
  angry('angry');

  final String value;
  const ReactionType(this.value);

  String get emoji {
    switch (this) {
      case ReactionType.like: return '👍';
      case ReactionType.love: return '❤️';
      case ReactionType.haha: return '😂';
      case ReactionType.wow: return '😮';
      case ReactionType.sad: return '😢';
      case ReactionType.angry: return '😠';
    }
  }

  String get label {
    switch (this) {
      case ReactionType.like: return 'Penda';
      case ReactionType.love: return 'Upendo';
      case ReactionType.haha: return 'Haha';
      case ReactionType.wow: return 'Wow';
      case ReactionType.sad: return 'Huzuni';
      case ReactionType.angry: return 'Hasira';
    }
  }

  static ReactionType fromString(String value) {
    return ReactionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReactionType.like,
    );
  }
}

/// Hashtag model for trending and discovery
class Hashtag {
  final int id;
  final String name;
  final int postsCount;
  final int usageCount24h;
  final int usageCount7d;
  final bool isTrending;
  final DateTime createdAt;

  Hashtag({
    required this.id,
    required this.name,
    this.postsCount = 0,
    this.usageCount24h = 0,
    this.usageCount7d = 0,
    this.isTrending = false,
    required this.createdAt,
  });

  factory Hashtag.fromJson(Map<String, dynamic> json) {
    return Hashtag(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      postsCount: _parseInt(json['posts_count']),
      usageCount24h: _parseInt(json['usage_count_24h']),
      usageCount7d: _parseInt(json['usage_count_7d']),
      isTrending: _parseBool(json['is_trending']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  /// Format posts count for display (e.g., 1.2K, 5.3M)
  String get formattedPostsCount {
    if (postsCount >= 1000000) {
      return '${(postsCount / 1000000).toStringAsFixed(1)}M';
    } else if (postsCount >= 1000) {
      return '${(postsCount / 1000).toStringAsFixed(1)}K';
    }
    return postsCount.toString();
  }
}

enum PostType {
  text('text'),
  photo('photo'),
  video('video'),
  shortVideo('short_video'),
  audio('audio'),
  audioText('audio_text'),
  imageText('image_text'),
  poll('poll'),
  shared('shared');

  final String value;
  const PostType(this.value);

  /// Get Swahili label for post type
  String get label {
    switch (this) {
      case PostType.text: return 'Maandishi';
      case PostType.photo: return 'Picha';
      case PostType.video: return 'Video';
      case PostType.shortVideo: return 'Video Fupi';
      case PostType.audio: return 'Sauti';
      case PostType.audioText: return 'Sauti + Maandishi';
      case PostType.imageText: return 'Picha + Maandishi';
      case PostType.poll: return 'Kura';
      case PostType.shared: return 'Imeshirikiwa';
    }
  }

  /// Check if this post type contains audio
  bool get hasAudio => this == PostType.audio || this == PostType.audioText;

  /// Check if this post type contains video
  bool get hasVideo => this == PostType.video || this == PostType.shortVideo;

  /// Check if this post type is a short-form video
  bool get isShortForm => this == PostType.shortVideo;

  static PostType fromString(String value) {
    return PostType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PostType.text,
    );
  }
}

enum PostPrivacy {
  public('public'),
  friends('friends'),
  subscribers('subscribers'),
  private('private');

  final String value;
  const PostPrivacy(this.value);

  String get label {
    switch (this) {
      case PostPrivacy.public:
        return 'Wote';
      case PostPrivacy.friends:
        return 'Marafiki';
      case PostPrivacy.subscribers:
        return 'Wasajili Pekee';
      case PostPrivacy.private:
        return 'Binafsi';
    }
  }

  IconData get icon {
    switch (this) {
      case PostPrivacy.public:
        return Icons.public;
      case PostPrivacy.friends:
        return Icons.group;
      case PostPrivacy.subscribers:
        return Icons.star;
      case PostPrivacy.private:
        return Icons.lock;
    }
  }

  String get description {
    switch (this) {
      case PostPrivacy.public:
        return 'Everyone can see';
      case PostPrivacy.friends:
        return 'Only friends can see';
      case PostPrivacy.subscribers:
        return 'Only your subscribers can see';
      case PostPrivacy.private:
        return 'Only you can see';
    }
  }

  static PostPrivacy fromString(String value) {
    return PostPrivacy.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PostPrivacy.public,
    );
  }
}

class PostMedia {
  final int id;
  final int postId;
  final MediaType mediaType;
  final String filePath;
  final String? thumbnailPath;
  final String? dominantColor;
  final String? gridThumbnailPath;
  final String? originalFilename;
  final int? fileSize;
  final int? width;
  final int? height;
  final int? duration;
  final int order;

  PostMedia({
    required this.id,
    required this.postId,
    required this.mediaType,
    required this.filePath,
    this.thumbnailPath,
    this.dominantColor,
    this.gridThumbnailPath,
    this.originalFilename,
    this.fileSize,
    this.width,
    this.height,
    this.duration,
    this.order = 0,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    return PostMedia(
      id: _parseInt(json['id']),
      postId: _parseInt(json['post_id']),
      mediaType: MediaType.fromString(json['media_type'] ?? 'image'),
      filePath: json['file_path'] ?? '',
      thumbnailPath: json['thumbnail_path'],
      dominantColor: json['dominant_color'],
      gridThumbnailPath: json['grid_thumbnail_path'],
      originalFilename: json['original_filename'],
      fileSize: json['file_size'] != null ? _parseInt(json['file_size']) : null,
      width: json['width'] != null ? _parseInt(json['width']) : null,
      height: json['height'] != null ? _parseInt(json['height']) : null,
      duration: json['duration'] != null ? _parseInt(json['duration']) : null,
      order: _parseInt(json['order']),
    );
  }

  String get fileUrl => _buildStorageUrl(filePath);

  String? get thumbnailUrl => thumbnailPath != null ? _buildStorageUrl(thumbnailPath!) : null;

  /// Small 300x300 grid thumbnail URL (for profile grid).
  String? get gridThumbnailUrl => gridThumbnailPath != null ? _buildStorageUrl(gridThumbnailPath!) : null;

  /// Check if this is a vertical/portrait video (for shorts/reels)
  bool get isVertical => (height ?? 0) > (width ?? 0);

  /// Check if this is a square video
  bool get isSquare => width != null && height != null && width == height;

  /// Get aspect ratio
  double get aspectRatio {
    if (width == null || height == null || height == 0) return 16 / 9;
    return width! / height!;
  }

  /// Check if this is a short video (<=60 seconds)
  bool get isShortVideo => mediaType.isVideo && (duration ?? 0) <= 60;

  /// Check if this media is a video
  bool get isVideo => mediaType.isVideo;

  /// Check if this media is an image
  bool get isImage => mediaType.isImage;

  /// Format duration as mm:ss
  String get formattedDuration {
    if (duration == null) return '00:00';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format file size for display
  String get formattedFileSize {
    if (fileSize == null) return '';
    if (fileSize! >= 1024 * 1024) {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (fileSize! >= 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    }
    return '$fileSize B';
  }
}

enum MediaType {
  image('image'),
  video('video'),
  audio('audio'),
  document('document');

  final String value;
  const MediaType(this.value);

  bool get isImage => this == MediaType.image;
  bool get isVideo => this == MediaType.video;
  bool get isAudio => this == MediaType.audio;
  bool get isDocument => this == MediaType.document;

  static MediaType fromString(String value) {
    return MediaType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MediaType.image,
    );
  }
}

class PostUser {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePhotoPath;

  PostUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.profilePhotoPath,
  });

  factory PostUser.fromJson(Map<String, dynamic> json) {
    return PostUser(
      id: _parseInt(json['id']),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      username: json['username'] != null ? json['username'].toString() : null,
      profilePhotoPath: json['profile_photo_path'] != null ? json['profile_photo_path'].toString() : null,
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  String? get profilePhotoUrl => profilePhotoPath != null ? _buildStorageUrl(profilePhotoPath!) : null;
}

class Comment {
  final int id;
  final int postId;
  final int userId;
  final int? parentId;
  final String content;
  final int likesCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PostUser? user;
  final List<Comment> replies;
  /// Whether this comment is pinned (post author only). Optional from API.
  final bool isPinned;
  /// Whether the current user has liked this comment. Optional from API.
  final bool isLiked;
  /// When the comment was last edited; null if never edited.
  final DateTime? editedAt;
  /// Total reply count from API (may exceed replies.length when paginated).
  final int replyCount;
  /// User IDs mentioned in content (@username). Optional from API.
  final List<int>? mentionedUserIds;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    this.parentId,
    required this.content,
    this.likesCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.replies = const [],
    this.isPinned = false,
    this.isLiked = false,
    this.editedAt,
    this.replyCount = 0,
    this.mentionedUserIds,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: _parseInt(json['id']),
      postId: _parseInt(json['post_id']),
      userId: _parseInt(json['user_id']),
      parentId: json['parent_id'] != null ? _parseInt(json['parent_id']) : null,
      content: json['content'] ?? '',
      likesCount: _parseInt(json['likes_count']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'] != null ? PostUser.fromJson(json['user']) : null,
      replies: json['replies'] != null
          ? (json['replies'] as List).map((r) => Comment.fromJson(r)).toList()
          : [],
      isPinned: _parseBool(json['is_pinned']),
      isLiked: _parseBool(json['is_liked']),
      editedAt: json['edited_at'] != null ? DateTime.tryParse(json['edited_at'].toString()) : null,
      replyCount: _parseInt(json['reply_count']),
      mentionedUserIds: json['mentioned_user_ids'] != null
          ? (json['mentioned_user_ids'] as List).map((e) => _parseInt(e)).toList()
          : null,
    );
  }

  bool get isReply => parentId != null;

  Comment copyWith({
    int? id,
    int? postId,
    int? userId,
    int? parentId,
    String? content,
    int? likesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    PostUser? user,
    List<Comment>? replies,
    bool? isPinned,
    bool? isLiked,
    DateTime? editedAt,
    int? replyCount,
    List<int>? mentionedUserIds,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      parentId: parentId ?? this.parentId,
      content: content ?? this.content,
      likesCount: likesCount ?? this.likesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
      replies: replies ?? this.replies,
      isPinned: isPinned ?? this.isPinned,
      isLiked: isLiked ?? this.isLiked,
      editedAt: editedAt ?? this.editedAt,
      replyCount: replyCount ?? this.replyCount,
      mentionedUserIds: mentionedUserIds ?? this.mentionedUserIds,
    );
  }
}

class PostLike {
  final int id;
  final int postId;
  final int userId;
  final String reactionType;
  final PostUser? user;

  PostLike({
    required this.id,
    required this.postId,
    required this.userId,
    this.reactionType = 'like',
    this.user,
  });

  factory PostLike.fromJson(Map<String, dynamic> json) {
    return PostLike(
      id: _parseInt(json['id']),
      postId: _parseInt(json['post_id']),
      userId: _parseInt(json['user_id']),
      reactionType: json['reaction_type'] ?? 'like',
      user: json['user'] != null ? PostUser.fromJson(json['user']) : null,
    );
  }
}

/// Music track model for posts with background music
class MusicTrack {
  final int id;
  final String title;
  final String? artist;
  final String? albumName;
  final String? coverArtPath;
  final String audioPath;
  final int duration; // in seconds
  final String? genre;
  final bool isFeatured;
  final int usageCount;

  MusicTrack({
    required this.id,
    required this.title,
    this.artist,
    this.albumName,
    this.coverArtPath,
    required this.audioPath,
    required this.duration,
    this.genre,
    this.isFeatured = false,
    this.usageCount = 0,
  });

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      id: _parseInt(json['id']),
      title: json['title'] ?? '',
      artist: json['artist'],
      albumName: json['album_name'],
      coverArtPath: json['cover_art_path'],
      audioPath: json['audio_path'] ?? '',
      duration: _parseInt(json['duration']),
      genre: json['genre'],
      isFeatured: _parseBool(json['is_featured']),
      usageCount: _parseInt(json['usage_count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album_name': albumName,
      'cover_art_path': coverArtPath,
      'audio_path': audioPath,
      'duration': duration,
      'genre': genre,
      'is_featured': isFeatured,
      'usage_count': usageCount,
    };
  }

  /// Get cover art URL
  String? get coverArtUrl => coverArtPath != null ? _buildStorageUrl(coverArtPath!) : null;

  /// Get audio URL
  String get audioUrl => _buildStorageUrl(audioPath);

  /// Format duration as mm:ss
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get display name (title - artist)
  String get displayName => artist != null ? '$title - $artist' : title;
}

/// Text overlay for video posts
class TextOverlay {
  final String text;
  final double x; // Position 0.0 - 1.0
  final double y; // Position 0.0 - 1.0
  final double fontSize;
  final String fontFamily;
  final String color; // Hex color
  final String? backgroundColor; // Hex color with alpha
  final double rotation; // Degrees
  final double startTime; // When to show (seconds)
  final double endTime; // When to hide (seconds)
  final TextOverlayAnimation animation;

  TextOverlay({
    required this.text,
    this.x = 0.5,
    this.y = 0.5,
    this.fontSize = 24.0,
    this.fontFamily = 'default',
    this.color = '#FFFFFF',
    this.backgroundColor,
    this.rotation = 0.0,
    this.startTime = 0.0,
    this.endTime = double.infinity,
    this.animation = TextOverlayAnimation.none,
  });

  factory TextOverlay.fromJson(Map<String, dynamic> json) {
    return TextOverlay(
      text: json['text'] ?? '',
      x: _parseDouble(json['x'], 0.5),
      y: _parseDouble(json['y'], 0.5),
      fontSize: _parseDouble(json['font_size'], 24.0),
      fontFamily: json['font_family'] ?? 'default',
      color: json['color'] ?? '#FFFFFF',
      backgroundColor: json['background_color'],
      rotation: _parseDouble(json['rotation'], 0.0),
      startTime: _parseDouble(json['start_time'], 0.0),
      endTime: _parseDouble(json['end_time'], double.infinity),
      animation: TextOverlayAnimation.fromString(json['animation'] ?? 'none'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'x': x,
      'y': y,
      'font_size': fontSize,
      'font_family': fontFamily,
      'color': color,
      'background_color': backgroundColor,
      'rotation': rotation,
      'start_time': startTime,
      'end_time': endTime.isFinite ? endTime : null,
      'animation': animation.value,
    };
  }
}

/// Text overlay animation types
enum TextOverlayAnimation {
  none('none'),
  fadeIn('fade_in'),
  fadeOut('fade_out'),
  slideIn('slide_in'),
  slideOut('slide_out'),
  bounce('bounce'),
  typewriter('typewriter');

  final String value;
  const TextOverlayAnimation(this.value);

  static TextOverlayAnimation fromString(String value) {
    return TextOverlayAnimation.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TextOverlayAnimation.none,
    );
  }
}

/// Video filter presets
class VideoFilter {
  static const String normal = 'normal';
  static const String vivid = 'vivid';
  static const String warm = 'warm';
  static const String cool = 'cool';
  static const String blackWhite = 'black_white';
  static const String vintage = 'vintage';
  static const String fade = 'fade';
  static const String chrome = 'chrome';
  static const String dramatic = 'dramatic';
  static const String mono = 'mono';
  static const String silvertone = 'silvertone';
  static const String noir = 'noir';
  static const String instant = 'instant';
  static const String process = 'process';
  static const String transfer = 'transfer';

  static const List<String> all = [
    normal, vivid, warm, cool, blackWhite, vintage, fade, chrome,
    dramatic, mono, silvertone, noir, instant, process, transfer,
  ];

  /// Get Swahili label for filter
  static String getLabel(String filter) {
    switch (filter) {
      case normal: return 'Kawaida';
      case vivid: return 'Angavu';
      case warm: return 'Joto';
      case cool: return 'Baridi';
      case blackWhite: return 'Nyeusi na Nyeupe';
      case vintage: return 'Zamani';
      case fade: return 'Fifia';
      case chrome: return 'Chrome';
      case dramatic: return 'Drama';
      case mono: return 'Mono';
      case silvertone: return 'Fedha';
      case noir: return 'Noir';
      case instant: return 'Papo';
      case process: return 'Process';
      case transfer: return 'Hamisha';
      default: return filter;
    }
  }
}
