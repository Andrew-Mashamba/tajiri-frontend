/// Photo and album models

import '../config/api_config.dart';
import 'post_models.dart';

class Photo {
  final int id;
  final int userId;
  final int? albumId;
  final String filePath;
  final String? thumbnailPath;
  final int? width;
  final int? height;
  final int? fileSize;
  final String? caption;
  final String? locationName;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PostUser? user;
  final PhotoAlbum? album;

  Photo({
    required this.id,
    required this.userId,
    this.albumId,
    required this.filePath,
    this.thumbnailPath,
    this.width,
    this.height,
    this.fileSize,
    this.caption,
    this.locationName,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.album,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      userId: json['user_id'],
      albumId: json['album_id'],
      filePath: json['file_path'],
      thumbnailPath: json['thumbnail_path'],
      width: json['width'],
      height: json['height'],
      fileSize: json['file_size'],
      caption: json['caption'],
      locationName: json['location_name'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'] != null ? PostUser.fromJson(json['user']) : null,
      album: json['album'] != null ? PhotoAlbum.fromJson(json['album']) : null,
    );
  }

  String get fileUrl => filePath.startsWith('http')
      ? filePath
      : '${ApiConfig.storageUrl}/$filePath';

  String? get thumbnailUrl => thumbnailPath != null
      ? (thumbnailPath!.startsWith('http')
          ? thumbnailPath
          : '${ApiConfig.storageUrl}/$thumbnailPath')
      : null;

  double? get aspectRatio {
    if (width != null && height != null && height! > 0) {
      return width! / height!;
    }
    return null;
  }
}

class PhotoAlbum {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final AlbumPrivacy privacy;
  final int? coverPhotoId;
  final int photosCount;
  final bool isSystemAlbum;
  final String? systemAlbumType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PostUser? user;
  final Photo? coverPhoto;
  final List<Photo> photos;

  PhotoAlbum({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.privacy = AlbumPrivacy.public,
    this.coverPhotoId,
    this.photosCount = 0,
    this.isSystemAlbum = false,
    this.systemAlbumType,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.coverPhoto,
    this.photos = const [],
  });

  factory PhotoAlbum.fromJson(Map<String, dynamic> json) {
    return PhotoAlbum(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      privacy: AlbumPrivacy.fromString(json['privacy'] ?? 'public'),
      coverPhotoId: json['cover_photo_id'],
      photosCount: json['photos_count'] ?? 0,
      isSystemAlbum: json['is_system_album'] ?? false,
      systemAlbumType: json['system_album_type'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'] != null ? PostUser.fromJson(json['user']) : null,
      coverPhoto:
          json['cover_photo'] != null ? Photo.fromJson(json['cover_photo']) : null,
      photos: json['photos'] != null
          ? (json['photos'] as List).map((p) => Photo.fromJson(p)).toList()
          : [],
    );
  }

  String? get coverUrl {
    if (coverPhoto != null) {
      return coverPhoto!.thumbnailUrl ?? coverPhoto!.fileUrl;
    }
    return null;
  }

  String? get coverPhotoUrl => coverUrl;
}

enum AlbumPrivacy {
  public('public'),
  friends('friends'),
  private('private');

  final String value;
  const AlbumPrivacy(this.value);

  String get label {
    switch (this) {
      case AlbumPrivacy.public:
        return 'Wote';
      case AlbumPrivacy.friends:
        return 'Marafiki';
      case AlbumPrivacy.private:
        return 'Binafsi';
    }
  }

  static AlbumPrivacy fromString(String value) {
    return AlbumPrivacy.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AlbumPrivacy.public,
    );
  }
}
