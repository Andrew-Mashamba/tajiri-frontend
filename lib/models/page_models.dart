class PageModel {
  final int id;
  final String name;
  final String slug;
  final String category;
  final String? subcategory;
  final String? description;
  final String? profilePhotoPath;
  final String? profilePhotoUrl;
  final String? coverPhotoPath;
  final String? coverPhotoUrl;
  final String? website;
  final String? phone;
  final String? email;
  final String? address;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? hours;
  final Map<String, dynamic>? socialLinks;
  final int creatorId;
  final int likesCount;
  final int followersCount;
  final int postsCount;
  final bool isVerified;
  final DateTime createdAt;
  final PageCreator? creator;
  final bool? isFollowing;
  final bool? isLiked;
  final String? userRole;
  final bool? canManage;
  final double? averageRating;
  final int? reviewsCount;

  PageModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.category,
    this.subcategory,
    this.description,
    this.profilePhotoPath,
    this.profilePhotoUrl,
    this.coverPhotoPath,
    this.coverPhotoUrl,
    this.website,
    this.phone,
    this.email,
    this.address,
    this.latitude,
    this.longitude,
    this.hours,
    this.socialLinks,
    required this.creatorId,
    this.likesCount = 0,
    this.followersCount = 0,
    this.postsCount = 0,
    this.isVerified = false,
    required this.createdAt,
    this.creator,
    this.isFollowing,
    this.isLiked,
    this.userRole,
    this.canManage,
    this.averageRating,
    this.reviewsCount,
  });

  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      category: json['category'] ?? 'other',
      subcategory: json['subcategory'],
      description: json['description'],
      profilePhotoPath: json['profile_photo_path'],
      profilePhotoUrl: json['profile_photo_url'],
      coverPhotoPath: json['cover_photo_path'],
      coverPhotoUrl: json['cover_photo_url'],
      website: json['website'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      hours: json['hours'],
      socialLinks: json['social_links'],
      creatorId: json['creator_id'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      followersCount: json['followers_count'] ?? 0,
      postsCount: json['posts_count'] ?? 0,
      isVerified: json['is_verified'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      creator: json['creator'] != null
          ? PageCreator.fromJson(json['creator'])
          : null,
      isFollowing: json['is_following'],
      isLiked: json['is_liked'],
      userRole: json['user_role'],
      canManage: json['can_manage'],
      averageRating: json['average_rating']?.toDouble(),
      reviewsCount: json['reviews_count'],
    );
  }

  PageModel copyWith({
    int? id,
    String? name,
    String? slug,
    String? category,
    String? subcategory,
    String? description,
    String? profilePhotoPath,
    String? profilePhotoUrl,
    String? coverPhotoPath,
    String? coverPhotoUrl,
    String? website,
    String? phone,
    String? email,
    String? address,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? hours,
    Map<String, dynamic>? socialLinks,
    int? creatorId,
    int? likesCount,
    int? followersCount,
    int? postsCount,
    bool? isVerified,
    DateTime? createdAt,
    PageCreator? creator,
    bool? isFollowing,
    bool? isLiked,
    String? userRole,
    bool? canManage,
    double? averageRating,
    int? reviewsCount,
  }) {
    return PageModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      description: description ?? this.description,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      coverPhotoPath: coverPhotoPath ?? this.coverPhotoPath,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      website: website ?? this.website,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      hours: hours ?? this.hours,
      socialLinks: socialLinks ?? this.socialLinks,
      creatorId: creatorId ?? this.creatorId,
      likesCount: likesCount ?? this.likesCount,
      followersCount: followersCount ?? this.followersCount,
      postsCount: postsCount ?? this.postsCount,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      creator: creator ?? this.creator,
      isFollowing: isFollowing ?? this.isFollowing,
      isLiked: isLiked ?? this.isLiked,
      userRole: userRole ?? this.userRole,
      canManage: canManage ?? this.canManage,
      averageRating: averageRating ?? this.averageRating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
    );
  }
}

class PageCreator {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePhotoPath;

  PageCreator({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.profilePhotoPath,
  });

  factory PageCreator.fromJson(Map<String, dynamic> json) {
    return PageCreator(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'],
      profilePhotoPath: json['profile_photo_path'],
    );
  }

  String get fullName => '$firstName $lastName';
}

class PageReview {
  final int id;
  final int pageId;
  final int userId;
  final int rating;
  final String? content;
  final DateTime createdAt;
  final PageCreator? user;

  PageReview({
    required this.id,
    required this.pageId,
    required this.userId,
    required this.rating,
    this.content,
    required this.createdAt,
    this.user,
  });

  factory PageReview.fromJson(Map<String, dynamic> json) {
    return PageReview(
      id: json['id'],
      pageId: json['page_id'],
      userId: json['user_id'],
      rating: json['rating'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      user: json['user'] != null ? PageCreator.fromJson(json['user']) : null,
    );
  }
}

class PageCategory {
  final String value;
  final String label;

  PageCategory({required this.value, required this.label});

  factory PageCategory.fromJson(Map<String, dynamic> json) {
    return PageCategory(
      value: json['value'],
      label: json['label'],
    );
  }
}
