/// Models for GET /api/people/search response.
import '../config/api_config.dart';

/// Single person in people search results (matches backend field names).
class PersonSearchResult {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? gender;
  final int? age;
  final String? profilePhotoPath;
  final String? coverPhotoPath;
  final String? bio;
  final String? regionName;
  final String? districtName;
  final String? locationString;
  final String? relationshipStatus;
  final int friendsCount;
  final int postsCount;
  final int photosCount;
  final int mutualFriendsCount;
  final String friendshipStatus; // "none" | "friends" | "pending_sent" | "pending_received"
  final List<String> inCommon;
  final String? primarySchool;
  final String? secondarySchool;
  final String? university;
  final String? employer;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final DateTime? lastActiveAt;
  final DateTime? createdAt;

  PersonSearchResult({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.gender,
    this.age,
    this.profilePhotoPath,
    this.coverPhotoPath,
    this.bio,
    this.regionName,
    this.districtName,
    this.locationString,
    this.relationshipStatus,
    required this.friendsCount,
    required this.postsCount,
    required this.photosCount,
    required this.mutualFriendsCount,
    required this.friendshipStatus,
    required this.inCommon,
    this.primarySchool,
    this.secondarySchool,
    this.university,
    this.employer,
    required this.isOnline,
    this.lastSeenAt,
    this.lastActiveAt,
    this.createdAt,
  });

  factory PersonSearchResult.fromJson(Map<String, dynamic> json) {
    return PersonSearchResult(
      id: json['id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      username: json['username'] as String?,
      gender: json['gender'] as String?,
      age: json['age'] as int?,
      profilePhotoPath: json['profile_photo_path'] as String?,
      coverPhotoPath: json['cover_photo_path'] as String?,
      bio: json['bio'] as String?,
      regionName: json['region_name'] as String?,
      districtName: json['district_name'] as String?,
      locationString: json['location_string'] as String?,
      relationshipStatus: json['relationship_status'] as String?,
      friendsCount: json['friends_count'] as int? ?? 0,
      postsCount: json['posts_count'] as int? ?? 0,
      photosCount: json['photos_count'] as int? ?? 0,
      mutualFriendsCount: json['mutual_friends_count'] as int? ?? 0,
      friendshipStatus: json['friendship_status'] as String? ?? 'none',
      inCommon: List<String>.from(json['in_common'] as List<dynamic>? ?? []),
      primarySchool: json['primary_school'] as String?,
      secondarySchool: json['secondary_school'] as String?,
      university: json['university'] as String?,
      employer: json['employer'] as String?,
      isOnline: json['is_online'] == true,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'].toString())
          : null,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.tryParse(json['last_active_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
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

  /// One-line context for card: employer or education.
  String? get contextLine {
    if (employer != null && employer!.isNotEmpty) return employer;
    if (university != null && university!.isNotEmpty) return university;
    if (secondarySchool != null && secondarySchool!.isNotEmpty) return secondarySchool;
    if (primarySchool != null && primarySchool!.isNotEmpty) return primarySchool;
    return null;
  }

  /// "Male, 18" or "Female, 25" — hide if both null.
  String? get genderAgeLine {
    final g = gender;
    final a = age;
    if (g == null && a == null) return null;
    if (g != null && a != null) return '${_capitalize(g)}, $a';
    if (g != null) return _capitalize(g);
    return '$a';
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  bool get isNone => friendshipStatus == 'none';
  bool get isFriends => friendshipStatus == 'friends';
  bool get isPendingSent => friendshipStatus == 'pending_sent';
  bool get isPendingReceived => friendshipStatus == 'pending_received';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      if (username != null) 'username': username,
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (profilePhotoPath != null) 'profile_photo_path': profilePhotoPath,
      if (coverPhotoPath != null) 'cover_photo_path': coverPhotoPath,
      if (bio != null) 'bio': bio,
      if (regionName != null) 'region_name': regionName,
      if (districtName != null) 'district_name': districtName,
      if (locationString != null) 'location_string': locationString,
      if (relationshipStatus != null) 'relationship_status': relationshipStatus,
      'friends_count': friendsCount,
      'posts_count': postsCount,
      'photos_count': photosCount,
      'mutual_friends_count': mutualFriendsCount,
      'friendship_status': friendshipStatus,
      'in_common': inCommon,
      if (primarySchool != null) 'primary_school': primarySchool,
      if (secondarySchool != null) 'secondary_school': secondarySchool,
      if (university != null) 'university': university,
      if (employer != null) 'employer': employer,
      'is_online': isOnline,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt!.toIso8601String(),
      if (lastActiveAt != null) 'last_active_at': lastActiveAt!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  PersonSearchResult copyWith({String? friendshipStatus}) {
    return PersonSearchResult(
      id: id,
      firstName: firstName,
      lastName: lastName,
      username: username,
      gender: gender,
      age: age,
      profilePhotoPath: profilePhotoPath,
      coverPhotoPath: coverPhotoPath,
      bio: bio,
      regionName: regionName,
      districtName: districtName,
      locationString: locationString,
      relationshipStatus: relationshipStatus,
      friendsCount: friendsCount,
      postsCount: postsCount,
      photosCount: photosCount,
      mutualFriendsCount: mutualFriendsCount,
      friendshipStatus: friendshipStatus ?? this.friendshipStatus,
      inCommon: inCommon,
      primarySchool: primarySchool,
      secondarySchool: secondarySchool,
      university: university,
      employer: employer,
      isOnline: isOnline,
      lastSeenAt: lastSeenAt,
      lastActiveAt: lastActiveAt,
      createdAt: createdAt,
    );
  }
}

/// Response wrapper for people search.
class PeopleSearchResponse {
  final List<PersonSearchResult> people;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  bool get hasMore => currentPage < lastPage;

  PeopleSearchResponse({
    required this.people,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });
}
