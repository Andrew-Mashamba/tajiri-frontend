import '../config/api_config.dart';

class Story {
  final int id;
  final int userId;
  final String mediaType;
  final String? mediaPath;
  final String? thumbnailPath;
  final String? caption;
  final int duration;
  final List<dynamic>? textOverlays;
  final List<dynamic>? stickers;
  final String? filter;
  final int? musicId;
  final int? musicStart;
  final String? backgroundColor;
  final String? linkUrl;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final bool allowReplies;
  final bool allowSharing;
  final String privacy;
  final int viewsCount;
  final int reactionsCount;
  final DateTime expiresAt;
  final DateTime createdAt;
  final StoryUser? user;
  final StoryMusic? music;
  final bool? hasViewed;
  /// Whether current user is subscribed to the story author (for subscribers-only content)
  final bool isSubscribedToAuthor;

  Story({
    required this.id,
    required this.userId,
    required this.mediaType,
    this.mediaPath,
    this.thumbnailPath,
    this.caption,
    this.duration = 5,
    this.textOverlays,
    this.stickers,
    this.filter,
    this.musicId,
    this.musicStart,
    this.backgroundColor,
    this.linkUrl,
    this.locationName,
    this.latitude,
    this.longitude,
    this.allowReplies = true,
    this.allowSharing = true,
    this.privacy = 'everyone',
    this.viewsCount = 0,
    this.reactionsCount = 0,
    required this.expiresAt,
    required this.createdAt,
    this.user,
    this.music,
    this.hasViewed,
    this.isSubscribedToAuthor = false,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      userId: json['user_id'],
      mediaType: json['media_type'] ?? 'image',
      mediaPath: json['media_path'],
      thumbnailPath: json['thumbnail_path'],
      caption: json['caption'],
      duration: json['duration'] ?? 5,
      textOverlays: json['text_overlays'],
      stickers: json['stickers'],
      filter: json['filter'],
      musicId: json['music_id'],
      musicStart: json['music_start'],
      backgroundColor: json['background_color'],
      linkUrl: json['link_url'],
      locationName: json['location_name'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      allowReplies: json['allow_replies'] ?? true,
      allowSharing: json['allow_sharing'] ?? true,
      privacy: json['privacy'] ?? 'everyone',
      viewsCount: json['views_count'] ?? 0,
      reactionsCount: json['reactions_count'] ?? 0,
      expiresAt: DateTime.parse(json['expires_at']),
      createdAt: DateTime.parse(json['created_at']),
      user: json['user'] != null ? StoryUser.fromJson(json['user']) : null,
      music: json['music'] != null ? StoryMusic.fromJson(json['music']) : null,
      hasViewed: json['has_viewed'],
      isSubscribedToAuthor: json['is_subscribed_to_author'] == true,
    );
  }

  bool get isExpired => expiresAt.isBefore(DateTime.now());
  bool get isVideo => mediaType == 'video';
  bool get isText => mediaType == 'text';
  bool get isViewed => hasViewed ?? false;

  String get mediaUrl => mediaPath != null ? '${ApiConfig.storageUrl}/$mediaPath' : '';
}

class StoryUser {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePhotoPath;

  StoryUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.profilePhotoPath,
  });

  factory StoryUser.fromJson(Map<String, dynamic> json) {
    return StoryUser(
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

class StoryMusic {
  final int id;
  final String title;
  final String? coverPath;
  final MusicArtist? artist;

  StoryMusic({
    required this.id,
    required this.title,
    this.coverPath,
    this.artist,
  });

  factory StoryMusic.fromJson(Map<String, dynamic> json) {
    return StoryMusic(
      id: json['id'],
      title: json['title'] ?? '',
      coverPath: json['cover_path'],
      artist: json['artist'] != null ? MusicArtist.fromJson(json['artist']) : null,
    );
  }
}

class MusicArtist {
  final int id;
  final String name;

  MusicArtist({required this.id, required this.name});

  factory MusicArtist.fromJson(Map<String, dynamic> json) {
    return MusicArtist(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }
}

class StoryGroup {
  final StoryUser user;
  final List<Story> stories;
  final bool hasUnviewed;

  StoryGroup({
    required this.user,
    required this.stories,
    this.hasUnviewed = true,
  });

  factory StoryGroup.fromJson(Map<String, dynamic> json) {
    return StoryGroup(
      user: StoryUser.fromJson(json['user']),
      stories: (json['stories'] as List).map((s) => Story.fromJson(s)).toList(),
      hasUnviewed: json['has_unviewed'] ?? true,
    );
  }
}

class StoryHighlight {
  final int id;
  final int userId;
  final String title;
  final String? coverPath;
  final int order;
  final List<Story>? stories;

  StoryHighlight({
    required this.id,
    required this.userId,
    required this.title,
    this.coverPath,
    this.order = 0,
    this.stories,
  });

  factory StoryHighlight.fromJson(Map<String, dynamic> json) {
    return StoryHighlight(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'] ?? '',
      coverPath: json['cover_path'],
      order: json['order'] ?? 0,
      stories: json['stories'] != null
          ? (json['stories'] as List).map((s) => Story.fromJson(s)).toList()
          : null,
    );
  }

  String get coverUrl => coverPath != null
      ? '${ApiConfig.storageUrl}/$coverPath'
      : '';
}

class StoryViewer {
  final int id;
  final int viewerId;
  final DateTime viewedAt;
  final StoryUser? viewer;

  StoryViewer({
    required this.id,
    required this.viewerId,
    required this.viewedAt,
    this.viewer,
  });

  factory StoryViewer.fromJson(Map<String, dynamic> json) {
    return StoryViewer(
      id: json['id'],
      viewerId: json['viewer_id'],
      viewedAt: DateTime.parse(json['viewed_at']),
      viewer: json['viewer'] != null ? StoryUser.fromJson(json['viewer']) : null,
    );
  }
}
