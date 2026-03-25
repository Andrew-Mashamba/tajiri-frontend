import '../config/api_config.dart';

/// File type categories for documents
enum FileCategory {
  all,
  document,
  archive,
  other,
}

/// User file model for cloud storage (Dropbox-like)
class UserFile {
  final int id;
  final int userId;
  final String name;
  final String? displayName;
  final String path;
  final String? parentPath;
  final int? folderId;
  final String mimeType;
  final int size; // bytes
  final String? thumbnailUrl;
  final String? previewUrl;
  final String downloadUrl;
  final bool isFolder;
  final bool isStarred;
  final bool isOffline;
  final bool isShared;
  final int? sharedWithCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAccessedAt;

  UserFile({
    required this.id,
    required this.userId,
    required this.name,
    this.displayName,
    required this.path,
    this.parentPath,
    this.folderId,
    required this.mimeType,
    required this.size,
    this.thumbnailUrl,
    this.previewUrl,
    required this.downloadUrl,
    this.isFolder = false,
    this.isStarred = false,
    this.isOffline = false,
    this.isShared = false,
    this.sharedWithCount,
    required this.createdAt,
    required this.updatedAt,
    this.lastAccessedAt,
  });

  factory UserFile.fromJson(Map<String, dynamic> json) {
    return UserFile(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      displayName: json['display_name']?.toString(),
      path: json['path']?.toString() ?? '/',
      parentPath: json['parent_path']?.toString(),
      folderId: json['folder_id'] is int ? json['folder_id'] : int.tryParse(json['folder_id']?.toString() ?? ''),
      mimeType: json['mime_type']?.toString() ?? 'application/octet-stream',
      size: json['size'] is int ? json['size'] : int.tryParse(json['size']?.toString() ?? '0') ?? 0,
      thumbnailUrl: ApiConfig.sanitizeUrl(json['thumbnail_url']?.toString()),
      previewUrl: ApiConfig.sanitizeUrl(json['preview_url']?.toString()),
      downloadUrl: ApiConfig.sanitizeUrl(json['download_url']?.toString()) ?? '',
      isFolder: json['is_folder'] == true || json['type'] == 'folder',
      isStarred: json['is_starred'] == true,
      isOffline: json['is_offline'] == true,
      isShared: json['is_shared'] == true,
      sharedWithCount: json['shared_with_count'] is int ? json['shared_with_count'] : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastAccessedAt: json['last_accessed_at'] != null
          ? DateTime.tryParse(json['last_accessed_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'display_name': displayName,
      'path': path,
      'parent_path': parentPath,
      'folder_id': folderId,
      'mime_type': mimeType,
      'size': size,
      'thumbnail_url': thumbnailUrl,
      'preview_url': previewUrl,
      'download_url': downloadUrl,
      'is_folder': isFolder,
      'is_starred': isStarred,
      'is_offline': isOffline,
      'is_shared': isShared,
      'shared_with_count': sharedWithCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_accessed_at': lastAccessedAt?.toIso8601String(),
    };
  }

  UserFile copyWith({
    int? id,
    int? userId,
    String? name,
    String? displayName,
    String? path,
    String? parentPath,
    int? folderId,
    String? mimeType,
    int? size,
    String? thumbnailUrl,
    String? previewUrl,
    String? downloadUrl,
    bool? isFolder,
    bool? isStarred,
    bool? isOffline,
    bool? isShared,
    int? sharedWithCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
  }) {
    return UserFile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      path: path ?? this.path,
      parentPath: parentPath ?? this.parentPath,
      folderId: folderId ?? this.folderId,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      previewUrl: previewUrl ?? this.previewUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      isFolder: isFolder ?? this.isFolder,
      isStarred: isStarred ?? this.isStarred,
      isOffline: isOffline ?? this.isOffline,
      isShared: isShared ?? this.isShared,
      sharedWithCount: sharedWithCount ?? this.sharedWithCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }

  /// Get the file category based on MIME type
  FileCategory get category {
    if (isFolder) return FileCategory.other;

    final mime = mimeType.toLowerCase();
    if (mime.contains('zip') || mime.contains('rar') || mime.contains('tar') || mime.contains('7z')) {
      return FileCategory.archive;
    }
    if (mime.contains('pdf') ||
        mime.contains('document') ||
        mime.contains('text') ||
        mime.contains('sheet') ||
        mime.contains('presentation') ||
        mime.contains('msword') ||
        mime.contains('officedocument')) {
      return FileCategory.document;
    }
    return FileCategory.other;
  }

  /// Get file extension
  String get extension {
    final lastDot = name.lastIndexOf('.');
    if (lastDot == -1 || lastDot == name.length - 1) return '';
    return name.substring(lastDot + 1).toLowerCase();
  }

  /// Get human-readable file size
  String get formattedSize {
    if (isFolder) return '';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Get display name (uses displayName if set, otherwise name)
  String get title => displayName ?? name;
}

/// Folder model (extends UserFile concept)
class UserFolder extends UserFile {
  final int itemCount;
  final int totalSize;

  UserFolder({
    required super.id,
    required super.userId,
    required super.name,
    super.displayName,
    required super.path,
    super.parentPath,
    super.folderId,
    required super.createdAt,
    required super.updatedAt,
    this.itemCount = 0,
    this.totalSize = 0,
  }) : super(
          mimeType: 'folder',
          size: totalSize,
          downloadUrl: '',
          isFolder: true,
        );

  factory UserFolder.fromJson(Map<String, dynamic> json) {
    return UserFolder(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      displayName: json['display_name']?.toString(),
      path: json['path']?.toString() ?? '/',
      parentPath: json['parent_path']?.toString(),
      folderId: json['folder_id'] is int ? json['folder_id'] : int.tryParse(json['folder_id']?.toString() ?? ''),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      itemCount: json['item_count'] is int ? json['item_count'] : int.tryParse(json['item_count']?.toString() ?? '0') ?? 0,
      totalSize: json['total_size'] is int ? json['total_size'] : int.tryParse(json['total_size']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Storage quota info
class StorageQuota {
  final int used;
  final int total;
  final int fileCount;
  final int folderCount;

  StorageQuota({
    required this.used,
    required this.total,
    required this.fileCount,
    required this.folderCount,
  });

  factory StorageQuota.fromJson(Map<String, dynamic> json) {
    return StorageQuota(
      used: json['used'] is int ? json['used'] : int.tryParse(json['used']?.toString() ?? '0') ?? 0,
      total: json['total'] is int ? json['total'] : int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      fileCount: json['file_count'] is int ? json['file_count'] : int.tryParse(json['file_count']?.toString() ?? '0') ?? 0,
      folderCount: json['folder_count'] is int ? json['folder_count'] : int.tryParse(json['folder_count']?.toString() ?? '0') ?? 0,
    );
  }

  double get usagePercent => total > 0 ? (used / total) * 100 : 0;

  String get formattedUsed {
    if (used < 1024) return '$used B';
    if (used < 1024 * 1024) return '${(used / 1024).toStringAsFixed(1)} KB';
    if (used < 1024 * 1024 * 1024) return '${(used / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(used / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get formattedTotal {
    if (total < 1024) return '$total B';
    if (total < 1024 * 1024) return '${(total / 1024).toStringAsFixed(1)} KB';
    if (total < 1024 * 1024 * 1024) return '${(total / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(total / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

// Result classes
class FileListResult {
  final bool success;
  final List<UserFile> files;
  final String? message;
  final StorageQuota? quota;

  FileListResult({
    required this.success,
    this.files = const [],
    this.message,
    this.quota,
  });
}

class FileResult {
  final bool success;
  final UserFile? file;
  final String? message;

  FileResult({
    required this.success,
    this.file,
    this.message,
  });
}

class FolderResult {
  final bool success;
  final UserFolder? folder;
  final String? message;

  FolderResult({
    required this.success,
    this.folder,
    this.message,
  });
}
