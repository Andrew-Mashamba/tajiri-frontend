/// User privacy settings (Story 70).
/// Used for Profile visibility, Who can message, Who can see posts, Last seen.
/// Extended for MESSAGES.md: read receipts, online status, profile photo, about, status, who can resend status.

class PrivacySettings {
  final String profileVisibility;
  final String whoCanMessage;
  final String whoCanSeePosts;
  final String lastSeenVisibility;
  final String readReceiptsVisibility;
  final String onlineStatusVisibility;
  final String profilePhotoVisibility;
  final String aboutVisibility;
  final String statusVisibility;
  final String whoCanResendStatus;
  final String whoCanAddToGroups;

  const PrivacySettings({
    this.profileVisibility = 'everyone',
    this.whoCanMessage = 'everyone',
    this.whoCanSeePosts = 'everyone',
    this.lastSeenVisibility = 'everyone',
    this.readReceiptsVisibility = 'everyone',
    this.onlineStatusVisibility = 'everyone',
    this.profilePhotoVisibility = 'everyone',
    this.aboutVisibility = 'everyone',
    this.statusVisibility = 'everyone',
    this.whoCanResendStatus = 'everyone',
    this.whoCanAddToGroups = 'everyone',
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      profileVisibility: json['profile_visibility'] as String? ?? 'everyone',
      whoCanMessage: json['who_can_message'] as String? ?? 'everyone',
      whoCanSeePosts: json['who_can_see_posts'] as String? ?? 'everyone',
      lastSeenVisibility: json['last_seen_visibility'] as String? ?? 'everyone',
      readReceiptsVisibility: json['read_receipts_visibility'] as String? ?? 'everyone',
      onlineStatusVisibility: json['online_status_visibility'] as String? ?? 'everyone',
      profilePhotoVisibility: json['profile_photo_visibility'] as String? ?? 'everyone',
      aboutVisibility: json['about_visibility'] as String? ?? 'everyone',
      statusVisibility: json['status_visibility'] as String? ?? 'everyone',
      whoCanResendStatus: json['who_can_resend_status'] as String? ?? 'everyone',
      whoCanAddToGroups: json['who_can_add_to_groups'] as String? ?? 'everyone',
    );
  }

  Map<String, dynamic> toJson() => {
        'profile_visibility': profileVisibility,
        'who_can_message': whoCanMessage,
        'who_can_see_posts': whoCanSeePosts,
        'last_seen_visibility': lastSeenVisibility,
        'read_receipts_visibility': readReceiptsVisibility,
        'online_status_visibility': onlineStatusVisibility,
        'profile_photo_visibility': profilePhotoVisibility,
        'about_visibility': aboutVisibility,
        'status_visibility': statusVisibility,
        'who_can_resend_status': whoCanResendStatus,
        'who_can_add_to_groups': whoCanAddToGroups,
      };

  PrivacySettings copyWith({
    String? profileVisibility,
    String? whoCanMessage,
    String? whoCanSeePosts,
    String? lastSeenVisibility,
    String? readReceiptsVisibility,
    String? onlineStatusVisibility,
    String? profilePhotoVisibility,
    String? aboutVisibility,
    String? statusVisibility,
    String? whoCanResendStatus,
    String? whoCanAddToGroups,
  }) {
    return PrivacySettings(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      whoCanMessage: whoCanMessage ?? this.whoCanMessage,
      whoCanSeePosts: whoCanSeePosts ?? this.whoCanSeePosts,
      lastSeenVisibility: lastSeenVisibility ?? this.lastSeenVisibility,
      readReceiptsVisibility: readReceiptsVisibility ?? this.readReceiptsVisibility,
      onlineStatusVisibility: onlineStatusVisibility ?? this.onlineStatusVisibility,
      profilePhotoVisibility: profilePhotoVisibility ?? this.profilePhotoVisibility,
      aboutVisibility: aboutVisibility ?? this.aboutVisibility,
      statusVisibility: statusVisibility ?? this.statusVisibility,
      whoCanResendStatus: whoCanResendStatus ?? this.whoCanResendStatus,
      whoCanAddToGroups: whoCanAddToGroups ?? this.whoCanAddToGroups,
    );
  }
}

/// Labels for profile visibility (Kiswahili)
String privacyProfileVisibilityLabel(String value) {
  switch (value) {
    case 'everyone':
      return 'Kila mtu';
    case 'friends':
      return 'Marafiki tu';
    case 'only_me':
      return 'Mimi tu';
    default:
      return 'Kila mtu';
  }
}

/// Labels for who can message
String privacyWhoCanMessageLabel(String value) {
  switch (value) {
    case 'everyone':
      return 'Kila mtu';
    case 'friends':
      return 'Marafiki tu';
    case 'nobody':
      return 'Hakuna mtu';
    default:
      return 'Kila mtu';
  }
}

/// Labels for who can see posts
String privacyWhoCanSeePostsLabel(String value) {
  switch (value) {
    case 'everyone':
      return 'Kila mtu';
    case 'friends':
      return 'Marafiki tu';
    case 'only_me':
      return 'Mimi tu';
    default:
      return 'Kila mtu';
  }
}

/// Labels for last seen visibility
String privacyLastSeenLabel(String value) {
  switch (value) {
    case 'everyone':
      return 'Kila mtu';
    case 'friends':
      return 'Marafiki tu';
    case 'nobody':
      return 'Usionyeshe';
    default:
      return 'Kila mtu';
  }
}

/// Labels for who can add to groups
String privacyWhoCanAddToGroupsLabel(String value) {
  switch (value) {
    case 'everyone':
      return 'Kila mtu';
    case 'friends':
      return 'Marafiki tu';
    case 'nobody':
      return 'Hakuna mtu';
    default:
      return 'Kila mtu';
  }
}

/// Labels for presence controls (read receipts, online, profile photo, about, status, who can resend)
String privacyPresenceLabel(String value) {
  switch (value) {
    case 'everyone':
      return 'Kila mtu';
    case 'friends':
      return 'Marafiki tu';
    case 'nobody':
      return 'Usionyeshe';
    case 'only_me':
      return 'Mimi tu';
    default:
      return 'Kila mtu';
  }
}
