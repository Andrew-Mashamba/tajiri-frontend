import '../config/api_config.dart';

class LiveStream {
  final int id;
  final String streamKey;
  final int userId;
  final String title;
  final String? description;
  final String? thumbnailPath;
  final String? category;
  final List<String>? tags;
  final String status;
  final String privacy;
  final String? streamUrl;
  final String? playbackUrl;
  final String? recordingPath;
  final bool isRecorded;
  final bool allowComments;
  final bool allowGifts;
  final int viewersCount;
  final int peakViewers;
  final int totalViewers;
  final int likesCount;
  final int commentsCount;
  final int giftsCount;
  final int sharesCount;
  final double giftsValue;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? duration;
  final DateTime createdAt;
  final StreamUser? user;
  final List<StreamCohost>? cohosts;
  final bool? isLiked;

  LiveStream({
    required this.id,
    required this.streamKey,
    required this.userId,
    required this.title,
    this.description,
    this.thumbnailPath,
    this.category,
    this.tags,
    this.status = 'scheduled',
    this.privacy = 'public',
    this.streamUrl,
    this.playbackUrl,
    this.recordingPath,
    this.isRecorded = true,
    this.allowComments = true,
    this.allowGifts = true,
    this.viewersCount = 0,
    this.peakViewers = 0,
    this.totalViewers = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.giftsCount = 0,
    this.sharesCount = 0,
    this.giftsValue = 0,
    this.scheduledAt,
    this.startedAt,
    this.endedAt,
    this.duration,
    required this.createdAt,
    this.user,
    this.cohosts,
    this.isLiked,
  });

  factory LiveStream.fromJson(Map<String, dynamic> json) {
    return LiveStream(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      streamKey: json['stream_key'] ?? '',
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      title: json['title'] ?? '',
      description: json['description'],
      thumbnailPath: json['thumbnail_path'],
      category: json['category'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      status: json['status'] ?? 'scheduled',
      privacy: json['privacy'] ?? 'public',
      streamUrl: json['stream_url'],
      playbackUrl: json['playback_url'],
      recordingPath: json['recording_path'],
      isRecorded: json['is_recorded'] is bool ? json['is_recorded'] : json['is_recorded'] == true || json['is_recorded'] == 1 || json['is_recorded'] == '1',
      allowComments: json['allow_comments'] is bool ? json['allow_comments'] : json['allow_comments'] == true || json['allow_comments'] == 1 || json['allow_comments'] == '1',
      allowGifts: json['allow_gifts'] is bool ? json['allow_gifts'] : json['allow_gifts'] == true || json['allow_gifts'] == 1 || json['allow_gifts'] == '1',
      viewersCount: json['viewers_count'] is int ? json['viewers_count'] : int.tryParse(json['viewers_count']?.toString() ?? '0') ?? 0,
      peakViewers: json['peak_viewers'] is int ? json['peak_viewers'] : int.tryParse(json['peak_viewers']?.toString() ?? '0') ?? 0,
      totalViewers: json['total_viewers'] is int ? json['total_viewers'] : int.tryParse(json['total_viewers']?.toString() ?? '0') ?? 0,
      likesCount: json['likes_count'] is int ? json['likes_count'] : int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
      commentsCount: json['comments_count'] is int ? json['comments_count'] : int.tryParse(json['comments_count']?.toString() ?? '0') ?? 0,
      giftsCount: json['gifts_count'] is int ? json['gifts_count'] : int.tryParse(json['gifts_count']?.toString() ?? '0') ?? 0,
      sharesCount: json['shares_count'] is int ? json['shares_count'] : int.tryParse(json['shares_count']?.toString() ?? '0') ?? 0,
      giftsValue: json['gifts_value'] is num
          ? (json['gifts_value'] as num).toDouble()
          : double.tryParse(json['gifts_value']?.toString() ?? '0') ?? 0.0,
      scheduledAt: json['scheduled_at'] != null && json['scheduled_at'] != '' ? DateTime.parse(json['scheduled_at']) : null,
      startedAt: json['started_at'] != null && json['started_at'] != '' ? DateTime.parse(json['started_at']) : null,
      endedAt: json['ended_at'] != null && json['ended_at'] != '' ? DateTime.parse(json['ended_at']) : null,
      duration: json['duration'] is int ? json['duration'] : int.tryParse(json['duration']?.toString() ?? '0'),
      createdAt: DateTime.parse(json['created_at']),
      user: json['user'] != null ? StreamUser.fromJson(json['user']) : null,
      cohosts: json['cohosts'] != null
          ? (json['cohosts'] as List).map((c) => StreamCohost.fromJson(c)).toList()
          : null,
      isLiked: json['is_liked'],
    );
  }

  bool get isLive => status == 'live';
  bool get isScheduled => status == 'scheduled';
  bool get isEnded => status == 'ended';

  String get thumbnailUrl => thumbnailPath != null
      ? '${ApiConfig.storageUrl}/$thumbnailPath'
      : '';

  String get durationFormatted {
    if (duration == null) return '';
    final hours = duration! ~/ 3600;
    final minutes = (duration! % 3600) ~/ 60;
    final seconds = duration! % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }

  /// Copy with method for updating specific fields
  LiveStream copyWith({
    int? id,
    String? streamKey,
    int? userId,
    String? title,
    String? description,
    String? thumbnailPath,
    String? category,
    List<String>? tags,
    String? status,
    String? privacy,
    String? streamUrl,
    String? playbackUrl,
    String? recordingPath,
    bool? isRecorded,
    bool? allowComments,
    bool? allowGifts,
    int? viewersCount,
    int? peakViewers,
    int? totalViewers,
    int? likesCount,
    int? commentsCount,
    int? giftsCount,
    int? sharesCount,
    double? giftsValue,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? endedAt,
    int? duration,
    DateTime? createdAt,
    StreamUser? user,
    List<StreamCohost>? cohosts,
    bool? isLiked,
  }) {
    return LiveStream(
      id: id ?? this.id,
      streamKey: streamKey ?? this.streamKey,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      privacy: privacy ?? this.privacy,
      streamUrl: streamUrl ?? this.streamUrl,
      playbackUrl: playbackUrl ?? this.playbackUrl,
      recordingPath: recordingPath ?? this.recordingPath,
      isRecorded: isRecorded ?? this.isRecorded,
      allowComments: allowComments ?? this.allowComments,
      allowGifts: allowGifts ?? this.allowGifts,
      viewersCount: viewersCount ?? this.viewersCount,
      peakViewers: peakViewers ?? this.peakViewers,
      totalViewers: totalViewers ?? this.totalViewers,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      giftsCount: giftsCount ?? this.giftsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      giftsValue: giftsValue ?? this.giftsValue,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
      cohosts: cohosts ?? this.cohosts,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

/// WebSocket connection info from API (Pusher-compatible: use url + channel).
class StreamWebSocketInfo {
  final String url;
  final String channel;
  final String? globalChannel;
  final String? protocol;

  StreamWebSocketInfo({
    required this.url,
    required this.channel,
    this.globalChannel,
    this.protocol,
  });

  factory StreamWebSocketInfo.fromJson(Map<String, dynamic> json) {
    return StreamWebSocketInfo(
      url: json['url'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      globalChannel: json['global_channel'] as String?,
      protocol: json['protocol'] as String?,
    );
  }
}

/// GET /streams/{id}/check response — lightweight status for reconnection/polling.
class StreamCheckResponse {
  final bool success;
  final bool exists;
  final bool isActive;
  final bool streamEnded;
  final int? streamId;
  final String? status;
  final String? playbackUrl;
  final int? currentViewers;
  final StreamWebSocketInfo? websocket;
  final String? endedAt;
  final int? duration;
  final int? totalViewers;
  final int? peakViewers;
  final String? message;

  StreamCheckResponse({
    required this.success,
    required this.exists,
    required this.isActive,
    required this.streamEnded,
    this.streamId,
    this.status,
    this.playbackUrl,
    this.currentViewers,
    this.websocket,
    this.endedAt,
    this.duration,
    this.totalViewers,
    this.peakViewers,
    this.message,
  });

  factory StreamCheckResponse.fromJson(Map<String, dynamic> json) {
    return StreamCheckResponse(
      success: json['success'] == true,
      exists: json['exists'] == true,
      isActive: json['is_active'] == true,
      streamEnded: json['stream_ended'] == true,
      streamId: json['stream_id'] is int ? json['stream_id'] as int : int.tryParse(json['stream_id']?.toString() ?? ''),
      status: json['status'] as String?,
      playbackUrl: json['playback_url'] as String?,
      currentViewers: json['current_viewers'] is int ? json['current_viewers'] as int : int.tryParse(json['current_viewers']?.toString() ?? ''),
      websocket: json['websocket'] != null ? StreamWebSocketInfo.fromJson(json['websocket'] as Map<String, dynamic>) : null,
      endedAt: json['ended_at'] as String?,
      duration: json['duration'] is int ? json['duration'] as int : int.tryParse(json['duration']?.toString() ?? ''),
      totalViewers: json['total_viewers'] is int ? json['total_viewers'] as int : int.tryParse(json['total_viewers']?.toString() ?? ''),
      peakViewers: json['peak_viewers'] is int ? json['peak_viewers'] as int : int.tryParse(json['peak_viewers']?.toString() ?? ''),
      message: json['message'] as String?,
    );
  }
}

/// Stream status info from GET /streams/{id} (stream_status_info).
class StreamStatusInfo {
  final String status;
  final bool isActive;
  final bool isLive;
  final bool isEnded;
  final bool isScheduled;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool canJoin;

  StreamStatusInfo({
    required this.status,
    required this.isActive,
    required this.isLive,
    required this.isEnded,
    required this.isScheduled,
    this.startedAt,
    this.endedAt,
    required this.canJoin,
  });

  factory StreamStatusInfo.fromJson(Map<String, dynamic> json) {
    return StreamStatusInfo(
      status: json['status'] as String? ?? '',
      isActive: json['is_active'] == true,
      isLive: json['is_live'] == true,
      isEnded: json['is_ended'] == true,
      isScheduled: json['is_scheduled'] == true,
      startedAt: json['started_at'] != null && json['started_at'] != '' ? DateTime.tryParse(json['started_at'].toString()) : null,
      endedAt: json['ended_at'] != null && json['ended_at'] != '' ? DateTime.tryParse(json['ended_at'].toString()) : null,
      canJoin: json['can_join'] == true,
    );
  }
}

/// Ended summary when stream is ended (from GET /streams/{id} or join 410).
class StreamEndedSummary {
  final DateTime? endedAt;
  final int? duration;
  final int? totalViewers;
  final int? peakViewers;
  final int? likesCount;
  final int? commentsCount;

  StreamEndedSummary({
    this.endedAt,
    this.duration,
    this.totalViewers,
    this.peakViewers,
    this.likesCount,
    this.commentsCount,
  });

  factory StreamEndedSummary.fromJson(Map<String, dynamic> json) {
    return StreamEndedSummary(
      endedAt: json['ended_at'] != null && json['ended_at'] != '' ? DateTime.tryParse(json['ended_at'].toString()) : null,
      duration: json['duration'] is int ? json['duration'] as int : int.tryParse(json['duration']?.toString() ?? ''),
      totalViewers: json['total_viewers'] is int ? json['total_viewers'] as int : int.tryParse(json['total_viewers']?.toString() ?? ''),
      peakViewers: json['peak_viewers'] is int ? json['peak_viewers'] as int : int.tryParse(json['peak_viewers']?.toString() ?? ''),
      likesCount: json['likes_count'] is int ? json['likes_count'] as int : int.tryParse(json['likes_count']?.toString() ?? ''),
      commentsCount: json['comments_count'] is int ? json['comments_count'] as int : int.tryParse(json['comments_count']?.toString() ?? ''),
    );
  }
}

/// POST /streams/{id}/join result — use statusCode + payload per API guide.
class JoinStreamResult {
  final int statusCode; // 200, 404, 409, 410
  final bool success;
  final String? message;
  final String? streamStatus;
  final bool streamEnded;
  final String? playbackUrl;
  final int? currentViewers;
  final StreamWebSocketInfo? websocket;
  final DateTime? endedAt;
  final int? duration;
  final int? totalViewers;
  final int? peakViewers;
  final DateTime? scheduledAt;

  JoinStreamResult({
    required this.statusCode,
    required this.success,
    this.message,
    this.streamStatus,
    this.streamEnded = false,
    this.playbackUrl,
    this.currentViewers,
    this.websocket,
    this.endedAt,
    this.duration,
    this.totalViewers,
    this.peakViewers,
    this.scheduledAt,
  });

  bool get isNotFound => statusCode == 404;
  bool get isScheduled => statusCode == 409;
  bool get isGone => statusCode == 410; // ended, cancelled, ending
  bool get canPlay => statusCode == 200 && success && (playbackUrl != null && playbackUrl!.isNotEmpty || websocket != null);
}

class StreamUser {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePhotoPath;

  StreamUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.profilePhotoPath,
  });

  factory StreamUser.fromJson(Map<String, dynamic> json) {
    return StreamUser(
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

class StreamCohost {
  final int id;
  final int streamId;
  final int userId;
  final String status;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final StreamUser? user;

  StreamCohost({
    required this.id,
    required this.streamId,
    required this.userId,
    this.status = 'invited',
    this.joinedAt,
    this.leftAt,
    this.user,
  });

  factory StreamCohost.fromJson(Map<String, dynamic> json) {
    return StreamCohost(
      id: json['id'],
      streamId: json['stream_id'],
      userId: json['user_id'],
      status: json['status'] ?? 'invited',
      joinedAt: json['joined_at'] != null ? DateTime.parse(json['joined_at']) : null,
      leftAt: json['left_at'] != null ? DateTime.parse(json['left_at']) : null,
      user: json['user'] != null ? StreamUser.fromJson(json['user']) : null,
    );
  }
}

class StreamComment {
  final int id;
  final int streamId;
  final int userId;
  final String content;
  final bool isPinned;
  final bool isHighlighted;
  final DateTime createdAt;
  final StreamUser? user;

  StreamComment({
    required this.id,
    required this.streamId,
    required this.userId,
    required this.content,
    this.isPinned = false,
    this.isHighlighted = false,
    required this.createdAt,
    this.user,
  });

  factory StreamComment.fromJson(Map<String, dynamic> json) {
    return StreamComment(
      id: json['id'],
      streamId: json['stream_id'],
      userId: json['user_id'],
      content: json['content'] ?? '',
      isPinned: json['is_pinned'] ?? false,
      isHighlighted: json['is_highlighted'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      user: json['user'] != null ? StreamUser.fromJson(json['user']) : null,
    );
  }
}

class VirtualGift {
  final int id;
  final String name;
  final String slug;
  final String iconPath;
  final String? animationPath;
  final double price;
  final double creatorShare;
  final bool isActive;
  final int order;

  VirtualGift({
    required this.id,
    required this.name,
    required this.slug,
    required this.iconPath,
    this.animationPath,
    required this.price,
    this.creatorShare = 70,
    this.isActive = true,
    this.order = 0,
  });

  factory VirtualGift.fromJson(Map<String, dynamic> json) {
    return VirtualGift(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      iconPath: json['icon_path'] ?? '',
      animationPath: json['animation_path'],
      price: (json['price'] ?? 0).toDouble(),
      creatorShare: (json['creator_share'] ?? 70).toDouble(),
      isActive: json['is_active'] ?? true,
      order: json['order'] ?? 0,
    );
  }

  String get iconUrl => '${ApiConfig.storageUrl}/$iconPath';
}

class StreamGift {
  final int id;
  final int streamId;
  final int senderId;
  final int giftId;
  final int quantity;
  final double totalValue;
  final String? message;
  final DateTime createdAt;
  final StreamUser? sender;
  final VirtualGift? gift;

  StreamGift({
    required this.id,
    required this.streamId,
    required this.senderId,
    required this.giftId,
    this.quantity = 1,
    required this.totalValue,
    this.message,
    required this.createdAt,
    this.sender,
    this.gift,
  });

  factory StreamGift.fromJson(Map<String, dynamic> json) {
    return StreamGift(
      id: json['id'],
      streamId: json['stream_id'],
      senderId: json['sender_id'],
      giftId: json['gift_id'],
      quantity: json['quantity'] ?? 1,
      totalValue: (json['total_value'] ?? 0).toDouble(),
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
      sender: json['sender'] != null ? StreamUser.fromJson(json['sender']) : null,
      gift: json['gift'] != null ? VirtualGift.fromJson(json['gift']) : null,
    );
  }
}

class StreamViewer {
  final int id;
  final int streamId;
  final int userId;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final int watchDuration;
  final StreamUser? user;

  StreamViewer({
    required this.id,
    required this.streamId,
    required this.userId,
    required this.joinedAt,
    this.leftAt,
    this.watchDuration = 0,
    this.user,
  });

  factory StreamViewer.fromJson(Map<String, dynamic> json) {
    return StreamViewer(
      id: json['id'],
      streamId: json['stream_id'],
      userId: json['user_id'],
      joinedAt: DateTime.parse(json['joined_at']),
      leftAt: json['left_at'] != null ? DateTime.parse(json['left_at']) : null,
      watchDuration: json['watch_duration'] ?? 0,
      user: json['user'] != null ? StreamUser.fromJson(json['user']) : null,
    );
  }
}
