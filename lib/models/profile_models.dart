/// Full profile models for comprehensive user profile display

import 'dart:convert';

import 'post_models.dart';
import 'photo_models.dart';
import '../config/api_config.dart';

class FullProfile {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bio;
  final List<String>? interests;
  final String? relationshipStatus;
  final String? profilePhotoUrl;
  final String? coverPhotoUrl;
  final ProfileStats stats;
  final ProfileLocation? location;
  final ProfileEducation? primarySchool;
  final ProfileEducation? secondarySchool;
  final ProfileEducation? alevelEducation;
  final ProfileEducation? postsecondaryEducation;
  final ProfileUniversityEducation? universityEducation;
  final ProfileEmployer? currentEmployer;
  final FriendshipStatus? friendshipStatus;
  final int? mutualFriendsCount;
  final List<Post> recentPosts;
  final List<Photo> recentPhotos;
  final DateTime createdAt;

  FullProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.bio,
    this.interests,
    this.relationshipStatus,
    this.profilePhotoUrl,
    this.coverPhotoUrl,
    required this.stats,
    this.location,
    this.primarySchool,
    this.secondarySchool,
    this.alevelEducation,
    this.postsecondaryEducation,
    this.universityEducation,
    this.currentEmployer,
    this.friendshipStatus,
    this.mutualFriendsCount,
    this.recentPosts = const [],
    this.recentPhotos = const [],
    required this.createdAt,
  });

  factory FullProfile.fromJson(Map<String, dynamic> json) {
    // Handle nested education object from backend
    final education = json['education'] as Map<String, dynamic>?;

    // Handle stats - they may be at root level or in a stats object
    final statsJson = json['stats'] != null && json['stats'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['stats'] as Map<String, dynamic>)
        : null;
    final root = json;
    ProfileStats stats;
    if (statsJson != null) {
      stats = ProfileStats.fromJson(statsJson);
      // Merge root-level counts in case backend sends some only at root
      stats = ProfileStats(
        postsCount: stats.postsCount,
        friendsCount: stats.friendsCount,
        photosCount: stats.photosCount,
        followersCount: root['followers_count'] ?? stats.followersCount,
        followingCount: root['following_count'] ?? stats.followingCount,
        subscribersCount: root['subscribers_count'] ?? stats.subscribersCount,
      );
    } else {
      stats = ProfileStats(
        postsCount: root['posts_count'] ?? 0,
        friendsCount: root['friends_count'] ?? 0,
        photosCount: root['photos_count'] ?? 0,
        followersCount: root['followers_count'] ?? 0,
        followingCount: root['following_count'] ?? 0,
        subscribersCount: root['subscribers_count'] ?? 0,
      );
    }

    // Parse friendship status
    FriendshipStatus? friendshipStatus;
    final statusValue = json['friendship_status'];
    if (statusValue != null) {
      if (statusValue == 'self') {
        friendshipStatus = FriendshipStatus.self;
      } else if (statusValue == 'request_sent') {
        friendshipStatus = FriendshipStatus.requested;
      } else if (statusValue == 'request_received') {
        friendshipStatus = FriendshipStatus.pending;
      } else if (statusValue == 'accepted' || json['is_friend'] == true) {
        friendshipStatus = FriendshipStatus.friends;
      } else {
        friendshipStatus = FriendshipStatus.fromString(statusValue);
      }
    }

    return FullProfile(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'],
      phoneNumber: json['phone_number'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'])
          : null,
      gender: json['gender'],
      bio: json['bio'],
      interests: _parseStringList(json['interests']),
      relationshipStatus: json['relationship_status'],
      profilePhotoUrl: ApiConfig.sanitizeUrl(json['profile_photo_url']),
      coverPhotoUrl: ApiConfig.sanitizeUrl(json['cover_photo_url']),
      stats: stats,
      location: json['location'] != null && _hasLocationData(json['location'])
          ? ProfileLocation.fromJson(json['location'])
          : null,
      primarySchool: education?['primary_school'] != null
          ? ProfileEducation.fromJson(education!['primary_school'])
          : null,
      secondarySchool: education?['secondary_school'] != null
          ? ProfileEducation.fromJson(education!['secondary_school'])
          : null,
      alevelEducation: education?['alevel'] != null
          ? ProfileEducation.fromJson(education!['alevel'])
          : null,
      postsecondaryEducation: education?['postsecondary'] != null
          ? ProfileEducation.fromJson(education!['postsecondary'])
          : null,
      universityEducation: education?['university'] != null
          ? ProfileUniversityEducation.fromJson(education!['university'])
          : null,
      currentEmployer: json['employer'] != null
          ? ProfileEmployer.fromJson(json['employer'])
          : null,
      friendshipStatus: friendshipStatus,
      mutualFriendsCount: json['mutual_friends_count'],
      recentPosts: _parsePostList(json['recent_posts']),
      recentPhotos: _parsePhotoList(json['recent_photos']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static bool _hasLocationData(Map<String, dynamic>? location) {
    if (location == null) return false;
    return location['region_name'] != null ||
        location['district_name'] != null ||
        location['ward_name'] != null;
  }

  /// API may send interests as List<String>, a JSON array string (e.g. "[\"education\", \"church\"]"), or comma-separated.
  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) return List<String>.from(value.map((e) => e?.toString().trim() ?? '').where((e) => e.isNotEmpty));
    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return null;
      // Backend may send a JSON array string: "[\"education\", \"sports\", \"church\"]"
      if (s.startsWith('[') && s.endsWith(']')) {
        try {
          final decoded = jsonDecode(s);
          if (decoded is List) {
            return List<String>.from(decoded.map((e) => e?.toString().trim() ?? '').where((e) => e.isNotEmpty));
          }
        } catch (_) {
          // Fall through to comma-split
        }
      }
      return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return null;
  }

  /// API may send recent_posts as List or occasionally as non-List (e.g. empty string).
  static List<Post> _parsePostList(dynamic value) {
    if (value == null || value is! List) return [];
    return value
        .whereType<Map<String, dynamic>>()
        .map((p) => Post.fromJson(p))
        .toList();
  }

  /// API may send recent_photos as List or occasionally as non-List.
  static List<Photo> _parsePhotoList(dynamic value) {
    if (value == null || value is! List) return [];
    return value
        .whereType<Map<String, dynamic>>()
        .map((p) => Photo.fromJson(p))
        .toList();
  }

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  bool get hasEducation =>
      primarySchool != null ||
      secondarySchool != null ||
      alevelEducation != null ||
      postsecondaryEducation != null ||
      universityEducation != null;

  String? get genderLabel {
    if (gender == 'male') return 'Mwanaume';
    if (gender == 'female') return 'Mwanamke';
    return gender;
  }

  String? get relationshipStatusLabel {
    switch (relationshipStatus) {
      case 'single':
        return 'Sijaoa/Sijaolewa';
      case 'married':
        return 'Nimeoa/Nimeolewa';
      case 'engaged':
        return 'Nimechumbiwa';
      case 'complicated':
        return 'Ni ngumu';
      default:
        return relationshipStatus;
    }
  }
}

class ProfileStats {
  final int postsCount;
  final int friendsCount;
  final int photosCount;
  final int followersCount;
  final int followingCount;
  final int subscribersCount;

  ProfileStats({
    this.postsCount = 0,
    this.friendsCount = 0,
    this.photosCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.subscribersCount = 0,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      postsCount: json['posts_count'] ?? 0,
      friendsCount: json['friends_count'] ?? 0,
      photosCount: json['photos_count'] ?? 0,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      subscribersCount: json['subscribers_count'] ?? 0,
    );
  }
}

class ProfileLocation {
  final String? regionName;
  final String? districtName;
  final String? wardName;

  ProfileLocation({
    this.regionName,
    this.districtName,
    this.wardName,
  });

  factory ProfileLocation.fromJson(Map<String, dynamic> json) {
    return ProfileLocation(
      regionName: json['region_name'],
      districtName: json['district_name'],
      wardName: json['ward_name'],
    );
  }

  String get displayText {
    final parts = <String>[];
    if (wardName != null) parts.add(wardName!);
    if (districtName != null) parts.add(districtName!);
    if (regionName != null) parts.add(regionName!);
    return parts.join(', ');
  }
}

class ProfileEducation {
  final String? schoolName;
  final int? graduationYear;
  final String? combinationCode;

  ProfileEducation({
    this.schoolName,
    this.graduationYear,
    this.combinationCode,
  });

  factory ProfileEducation.fromJson(Map<String, dynamic> json) {
    return ProfileEducation(
      // Handle different field names: school_name or institution_name
      schoolName: json['school_name'] ?? json['institution_name'],
      graduationYear: json['graduation_year'],
      combinationCode: json['combination_code'],
    );
  }
}

class ProfileUniversityEducation {
  final String? universityName;
  final String? programmeName;
  final String? degreeLevel;
  final int? graduationYear;

  ProfileUniversityEducation({
    this.universityName,
    this.programmeName,
    this.degreeLevel,
    this.graduationYear,
  });

  factory ProfileUniversityEducation.fromJson(Map<String, dynamic> json) {
    return ProfileUniversityEducation(
      universityName: json['university_name'],
      programmeName: json['programme_name'],
      degreeLevel: json['degree_level'],
      graduationYear: json['graduation_year'],
    );
  }
}

class ProfileEmployer {
  final String? employerName;
  final String? sector;
  final String? jobTitle;
  final String? ownership;

  ProfileEmployer({
    this.employerName,
    this.sector,
    this.jobTitle,
    this.ownership,
  });

  factory ProfileEmployer.fromJson(Map<String, dynamic> json) {
    return ProfileEmployer(
      employerName: json['employer_name'],
      sector: json['sector'],
      jobTitle: json['job_title'],
      ownership: json['ownership'],
    );
  }
}

enum FriendshipStatus {
  none('none'),
  pending('pending'),
  requested('requested'),
  friends('friends'),
  self('self');

  final String value;
  const FriendshipStatus(this.value);

  static FriendshipStatus fromString(String value) {
    return FriendshipStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FriendshipStatus.none,
    );
  }

  String get actionLabel {
    switch (this) {
      case FriendshipStatus.none:
        return 'Ongeza Rafiki';
      case FriendshipStatus.pending:
        return 'Kubali Ombi';
      case FriendshipStatus.requested:
        return 'Ombi Limetumwa';
      case FriendshipStatus.friends:
        return 'Marafiki';
      case FriendshipStatus.self:
        return 'Hariri Wasifu';
    }
  }
}
