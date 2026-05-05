/// Friend and user models
import '../config/api_config.dart';

class UserProfile {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? bio;
  final String? profilePhotoPath;
  final String? coverPhotoPath;
  final String? regionName;
  final String? districtName;
  final int friendsCount;
  final int postsCount;
  final int photosCount;
  final DateTime? lastActiveAt;
  final int? mutualFriendsCount;
  // Rich people search fields (from backend profile)
  final String? locationString;
  final String? primarySchool;
  final String? secondarySchool;
  final String? university;
  final String? employer;
  final bool isOnline;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.bio,
    this.profilePhotoPath,
    this.coverPhotoPath,
    this.regionName,
    this.districtName,
    this.friendsCount = 0,
    this.postsCount = 0,
    this.photosCount = 0,
    this.lastActiveAt,
    this.mutualFriendsCount,
    this.locationString,
    this.primarySchool,
    this.secondarySchool,
    this.university,
    this.employer,
    this.isOnline = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime? lastActive = json['last_active_at'] != null
        ? DateTime.tryParse(json['last_active_at'].toString())
        : null;
    if (lastActive == null && json['last_seen_at'] != null) {
      lastActive = DateTime.tryParse(json['last_seen_at'].toString());
    }
    return UserProfile(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'],
      bio: json['bio'],
      profilePhotoPath: json['profile_photo_path'],
      coverPhotoPath: json['cover_photo_path'],
      regionName: json['region_name'],
      districtName: json['district_name'],
      friendsCount: json['friends_count'] ?? 0,
      postsCount: json['posts_count'] ?? 0,
      photosCount: json['photos_count'] ?? 0,
      lastActiveAt: lastActive,
      mutualFriendsCount: json['mutual_friends_count'],
      locationString: json['location_string'],
      primarySchool: json['primary_school'],
      secondarySchool: json['secondary_school'],
      university: json['university'],
      employer: json['employer'],
      isOnline: json['is_online'] == true,
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  String? get profilePhotoUrl => profilePhotoPath != null
      ? (profilePhotoPath!.startsWith('http')
          ? profilePhotoPath
          : '${ApiConfig.storageUrl}/$profilePhotoPath')
      : null;

  String? get coverPhotoUrl => coverPhotoPath != null
      ? (coverPhotoPath!.startsWith('http')
          ? coverPhotoPath
          : '${ApiConfig.storageUrl}/$coverPhotoPath')
      : null;

  String get location {
    if (locationString != null && locationString!.isNotEmpty) {
      return locationString!;
    }
    final parts = <String>[];
    if (districtName != null) parts.add(districtName!);
    if (regionName != null) parts.add(regionName!);
    return parts.join(', ');
  }

  /// One-line context for search cards: employer or education (university > secondary > primary).
  String? get contextLine {
    if (employer != null && employer!.isNotEmpty) return employer;
    if (university != null && university!.isNotEmpty) return university;
    if (secondarySchool != null && secondarySchool!.isNotEmpty) return secondarySchool;
    if (primarySchool != null && primarySchool!.isNotEmpty) return primarySchool;
    return null;
  }
}

class Friendship {
  final int id;
  final int userId;
  final int friendId;
  final FriendshipStatus status;
  final DateTime? acceptedAt;
  final DateTime createdAt;
  final UserProfile? user;
  final UserProfile? friend;

  Friendship({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    this.acceptedAt,
    required this.createdAt,
    this.user,
    this.friend,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'],
      userId: json['user_id'],
      friendId: json['friend_id'],
      status: FriendshipStatus.fromString(json['status'] ?? 'pending'),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      user: json['user'] != null ? UserProfile.fromJson(json['user']) : null,
      friend:
          json['friend'] != null ? UserProfile.fromJson(json['friend']) : null,
    );
  }
}

enum FriendshipStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  blocked('blocked');

  final String value;
  const FriendshipStatus(this.value);

  static FriendshipStatus fromString(String value) {
    return FriendshipStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FriendshipStatus.pending,
    );
  }
}

class FriendRequest {
  final int id;
  final String type; // 'received' or 'sent'
  final UserProfile user;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.type,
    required this.user,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'],
      type: json['type'],
      user: UserProfile.fromJson(json['user']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isReceived => type == 'received';
  bool get isSent => type == 'sent';
}

class FriendshipStatusResult {
  final String status;
  final bool isRequester;
  final bool canSendRequest;
  final bool canAccept;
  final bool canCancel;

  FriendshipStatusResult({
    required this.status,
    this.isRequester = false,
    this.canSendRequest = true,
    this.canAccept = false,
    this.canCancel = false,
  });

  factory FriendshipStatusResult.fromJson(Map<String, dynamic> json) {
    return FriendshipStatusResult(
      status: json['status'] ?? 'none',
      isRequester: json['is_requester'] ?? false,
      canSendRequest: json['can_send_request'] ?? true,
      canAccept: json['can_accept'] ?? false,
      canCancel: json['can_cancel'] ?? false,
    );
  }

  bool get isNone => status == 'none';
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isBlocked => status == 'blocked';
  bool get areFriends => isAccepted;
}

/// User model for followers/following/subscribers lists
class FollowUser {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePhotoPath;
  final String? profilePhotoUrlOverride; // explicit URL from backend
  final String? bio;
  final String? locationString;
  final bool isOnline;
  final bool isFollowing;      // Current user is following this user
  final bool isFollowedBy;     // This user is following current user
  final bool isSubscribed;     // Current user is subscribed to this user
  final bool isFriend;         // Current user is friends with this user
  final String? friendshipStatus; // none, pending_sent, pending_received, friends
  final int? mutualFriendsCount;

  // Followers manager fields (owner mode)
  final DateTime? followedAt;
  final DateTime? lastInteractionAt;
  final bool isMutual;
  final bool isMuted;

  FollowUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.profilePhotoPath,
    this.profilePhotoUrlOverride,
    this.bio,
    this.locationString,
    this.isOnline = false,
    this.isFollowing = false,
    this.isFollowedBy = false,
    this.isSubscribed = false,
    this.isFriend = false,
    this.friendshipStatus,
    this.mutualFriendsCount,
    this.followedAt,
    this.lastInteractionAt,
    this.isMutual = false,
    this.isMuted = false,
  });

  factory FollowUser.fromJson(Map<String, dynamic> json) {
    return FollowUser(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'],
      profilePhotoPath: json['profile_photo_path'],
      profilePhotoUrlOverride: json['profile_photo_url'] is String
          ? json['profile_photo_url'] as String
          : null,
      bio: json['bio'],
      locationString: json['location_string'],
      isOnline: json['is_online'] == true,
      isFollowing: json['is_following'] == true,
      isFollowedBy: json['is_followed_by'] == true,
      isSubscribed: json['is_subscribed'] == true,
      isFriend: json['is_friend'] == true,
      friendshipStatus: json['friendship_status'],
      mutualFriendsCount: json['mutual_friends_count'],
      followedAt: json['followed_at'] != null
          ? DateTime.tryParse(json['followed_at'].toString())
          : null,
      lastInteractionAt: json['last_interaction_at'] != null
          ? DateTime.tryParse(json['last_interaction_at'].toString())
          : null,
      isMutual: json['is_mutual'] == true,
      isMuted: json['is_muted'] == true,
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  String? get profilePhotoUrl {
    if (profilePhotoUrlOverride != null && profilePhotoUrlOverride!.isNotEmpty) {
      return profilePhotoUrlOverride;
    }
    if (profilePhotoPath == null) return null;
    return profilePhotoPath!.startsWith('http')
        ? profilePhotoPath
        : '${ApiConfig.storageUrl}/$profilePhotoPath';
  }

  FollowUser copyWith({
    bool? isFollowing,
    bool? isFollowedBy,
    bool? isSubscribed,
    bool? isFriend,
    String? friendshipStatus,
    bool? isMuted,
  }) {
    return FollowUser(
      id: id,
      firstName: firstName,
      lastName: lastName,
      username: username,
      profilePhotoPath: profilePhotoPath,
      profilePhotoUrlOverride: profilePhotoUrlOverride,
      bio: bio,
      locationString: locationString,
      isOnline: isOnline,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollowedBy: isFollowedBy ?? this.isFollowedBy,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      isFriend: isFriend ?? this.isFriend,
      friendshipStatus: friendshipStatus ?? this.friendshipStatus,
      mutualFriendsCount: mutualFriendsCount,
      followedAt: followedAt,
      lastInteractionAt: lastInteractionAt,
      isMutual: isMutual,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

class FollowerInsights {
  final int total;
  final int newThisWeek;
  final int inactive60d;
  final int mutualGap;

  const FollowerInsights({
    required this.total,
    required this.newThisWeek,
    required this.inactive60d,
    required this.mutualGap,
  });

  factory FollowerInsights.fromJson(Map<String, dynamic> json) => FollowerInsights(
        total: (json['total'] as num?)?.toInt() ?? 0,
        newThisWeek: (json['new_this_week'] as num?)?.toInt() ?? 0,
        inactive60d: (json['inactive_60d'] as num?)?.toInt() ?? 0,
        mutualGap: (json['mutual_gap'] as num?)?.toInt() ?? 0,
      );
}

class SubscriberInsights {
  final int totalActive;
  final int newThisMonth;
  final int expiringSoon;
  final int churned;
  final double mrrTzs;

  const SubscriberInsights({
    required this.totalActive,
    required this.newThisMonth,
    required this.expiringSoon,
    required this.churned,
    required this.mrrTzs,
  });

  factory SubscriberInsights.fromJson(Map<String, dynamic> json) =>
      SubscriberInsights(
        totalActive: (json['total_active'] as num?)?.toInt() ?? 0,
        newThisMonth: (json['new_this_month'] as num?)?.toInt() ?? 0,
        expiringSoon: (json['expiring_soon'] as num?)?.toInt() ?? 0,
        churned: (json['churned'] as num?)?.toInt() ?? 0,
        mrrTzs: (json['mrr_tzs'] as num?)?.toDouble() ?? 0.0,
      );
}

/// One row in the creator's subscribers list.
class SubscriberEntry {
  final int subscriptionId;
  final int subscriberId;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePhotoUrl;
  final String status; // active | cancelled | expired | paused
  final double amountPaid;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final bool autoRenew;
  final String? tierName;
  final double? tierPrice;
  final String? tierPeriod;

  const SubscriberEntry({
    required this.subscriptionId,
    required this.subscriberId,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.profilePhotoUrl,
    required this.status,
    required this.amountPaid,
    required this.startedAt,
    required this.expiresAt,
    required this.autoRenew,
    required this.tierName,
    required this.tierPrice,
    required this.tierPeriod,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory SubscriberEntry.fromJson(Map<String, dynamic> json) => SubscriberEntry(
        subscriptionId: (json['subscription_id'] as num?)?.toInt() ?? 0,
        subscriberId: (json['id'] as num?)?.toInt() ?? 0,
        firstName: (json['first_name'] as String?) ?? '',
        lastName: (json['last_name'] as String?) ?? '',
        username: json['username'] as String?,
        profilePhotoUrl: json['profile_photo_url'] as String?,
        status: (json['status'] as String?) ?? 'active',
        amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
        startedAt: json['started_at'] != null
            ? DateTime.tryParse(json['started_at'].toString())
            : null,
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'].toString())
            : null,
        autoRenew: json['auto_renew'] == true,
        tierName: json['tier_name'] as String?,
        tierPrice: (json['tier_price'] as num?)?.toDouble(),
        tierPeriod: json['tier_period'] as String?,
      );
}

class SubscriberListResult {
  final bool success;
  final List<SubscriberEntry> entries;
  final int totalCount;
  final String? message;

  const SubscriberListResult({
    required this.success,
    this.entries = const [],
    this.totalCount = 0,
    this.message,
  });
}
