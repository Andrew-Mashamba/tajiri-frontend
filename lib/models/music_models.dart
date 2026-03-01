import '../config/api_config.dart';

class MusicTrack {
  final int id;
  final String title;
  final String slug;
  final int artistId;
  final String? album;
  final String audioPath;
  final String? coverPath;
  final int duration;
  final String? genre;
  final int? bpm;
  final bool isExplicit;
  final int usesCount;
  final int playsCount;
  final bool isFeatured;
  final bool isTrending;
  final DateTime createdAt;
  final MusicArtistModel? artist;
  final List<MusicCategoryModel>? categories;
  final bool? isSaved;
  /// Privacy setting for the track
  final String privacy;
  /// Whether current user is subscribed to the artist (for subscribers-only content)
  final bool isSubscribedToArtist;

  MusicTrack({
    required this.id,
    required this.title,
    required this.slug,
    required this.artistId,
    this.album,
    required this.audioPath,
    this.coverPath,
    required this.duration,
    this.genre,
    this.bpm,
    this.isExplicit = false,
    this.usesCount = 0,
    this.playsCount = 0,
    this.isFeatured = false,
    this.isTrending = false,
    required this.createdAt,
    this.artist,
    this.categories,
    this.isSaved,
    this.privacy = 'public',
    this.isSubscribedToArtist = false,
  });

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      id: json['id'],
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      artistId: json['artist_id'],
      album: json['album'],
      audioPath: json['audio_path'] ?? '',
      coverPath: json['cover_path'],
      duration: json['duration'] ?? 0,
      genre: json['genre'],
      bpm: json['bpm'],
      isExplicit: json['is_explicit'] ?? false,
      usesCount: json['uses_count'] ?? 0,
      playsCount: json['plays_count'] ?? 0,
      isFeatured: json['is_featured'] ?? false,
      isTrending: json['is_trending'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      artist: json['artist'] != null ? MusicArtistModel.fromJson(json['artist']) : null,
      categories: json['categories'] != null
          ? (json['categories'] as List).map((c) => MusicCategoryModel.fromJson(c)).toList()
          : null,
      isSaved: json['is_saved'],
      privacy: json['privacy'] ?? 'public',
      isSubscribedToArtist: json['is_subscribed_to_artist'] == true,
    );
  }

  String get audioUrl => '${ApiConfig.storageUrl}/$audioPath';
  String get coverUrl => coverPath != null
      ? '${ApiConfig.storageUrl}/$coverPath'
      : '';
  String get displayTitle => artist != null ? '${artist!.name} - $title' : title;
  String get durationFormatted {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  // Convenience getters
  int? get playCount => playsCount;
  MusicCategoryModel? get category => categories?.isNotEmpty == true ? categories!.first : null;
}

class MusicArtistModel {
  final int id;
  final String name;
  final String slug;
  final String? imagePath;
  final String? bio;
  final bool isVerified;
  final int followersCount;
  final int? monthlyListeners;
  final int? tracksCount;
  final bool? isFollowing;
  final List<MusicTrack>? tracks;

  MusicArtistModel({
    required this.id,
    required this.name,
    required this.slug,
    this.imagePath,
    this.bio,
    this.isVerified = false,
    this.followersCount = 0,
    this.monthlyListeners,
    this.tracksCount,
    this.isFollowing,
    this.tracks,
  });

  factory MusicArtistModel.fromJson(Map<String, dynamic> json) {
    return MusicArtistModel(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      imagePath: json['image_path'],
      bio: json['bio'],
      isVerified: json['is_verified'] ?? false,
      followersCount: json['followers_count'] ?? 0,
      monthlyListeners: json['monthly_listeners'],
      tracksCount: json['tracks_count'],
      isFollowing: json['is_following'],
      tracks: json['tracks'] != null
          ? (json['tracks'] as List).map((t) => MusicTrack.fromJson(t)).toList()
          : null,
    );
  }

  String get imageUrl => imagePath != null
      ? '${ApiConfig.storageUrl}/$imagePath'
      : '';

  String? get photoUrl => imageUrl.isNotEmpty ? imageUrl : null;
}

class MusicCategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final int order;

  MusicCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.order = 0,
  });

  factory MusicCategoryModel.fromJson(Map<String, dynamic> json) {
    return MusicCategoryModel(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      icon: json['icon'],
      order: json['order'] ?? 0,
    );
  }
}
