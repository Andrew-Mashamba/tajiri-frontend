import '../config/api_config.dart';

class Group {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? coverPhotoPath;
  final String? coverPhotoUrl;
  final String privacy; // public, private, secret
  final int creatorId;
  final int membersCount;
  final int postsCount;
  final List<String>? rules;
  final bool requiresApproval;
  final DateTime createdAt;
  final GroupCreator? creator;
  final String? membershipStatus; // null, pending, approved, banned
  final String? userRole; // admin, moderator, member
  final bool? isMember;
  final bool? isAdmin;
  /// System groups (school, location, employer, etc.) are not editable; hide leave/edit/delete.
  final bool isSystem;
  /// When backend creates the linked conversation for this group (MESSAGES_BACKEND_IMPLEMENTATION_DIRECTIVE), it may return conversation_id in create/list response.
  final int? conversationId;

  Group({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.coverPhotoPath,
    this.coverPhotoUrl,
    required this.privacy,
    required this.creatorId,
    this.membersCount = 0,
    this.postsCount = 0,
    this.rules,
    this.requiresApproval = false,
    required this.createdAt,
    this.creator,
    this.membershipStatus,
    this.userRole,
    this.isMember,
    this.isAdmin,
    this.isSystem = false,
    this.conversationId,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    final convId = json['conversation_id'];
    final createdAt = json['created_at'];
    return Group(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      coverPhotoPath: json['cover_photo_path']?.toString(),
      coverPhotoUrl: ApiConfig.sanitizeUrl(json['cover_photo_url']?.toString()),
      privacy: json['privacy']?.toString() ?? 'public',
      creatorId: json['creator_id'] is int ? json['creator_id'] as int : (int.tryParse(json['creator_id']?.toString() ?? '') ?? 0),
      membersCount: json['members_count'] ?? json['approved_members_count'] ?? 0,
      postsCount: json['posts_count'] ?? 0,
      rules: json['rules'] != null ? List<String>.from(json['rules']) : null,
      requiresApproval: json['requires_approval'] == true,
      createdAt: createdAt != null
          ? (createdAt is DateTime ? createdAt : DateTime.tryParse(createdAt.toString()) ?? DateTime.now())
          : DateTime.now(),
      creator: json['creator'] != null && json['creator'] is Map
          ? GroupCreator.fromJson(Map<String, dynamic>.from(json['creator']))
          : null,
      membershipStatus: json['membership_status']?.toString(),
      userRole: json['user_role']?.toString(),
      isMember: json['is_member'] is bool ? json['is_member'] as bool : null,
      isAdmin: json['is_admin'] is bool ? json['is_admin'] as bool : null,
      isSystem: json['is_system'] == true,
      conversationId: convId is int ? convId : (convId != null ? int.tryParse(convId.toString()) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'cover_photo_path': coverPhotoPath,
      'privacy': privacy,
      'creator_id': creatorId,
      'members_count': membersCount,
      'posts_count': postsCount,
      'rules': rules,
      'requires_approval': requiresApproval,
    };
  }

  Group copyWith({
    int? id,
    String? name,
    String? slug,
    String? description,
    String? coverPhotoPath,
    String? coverPhotoUrl,
    String? privacy,
    int? creatorId,
    int? membersCount,
    int? postsCount,
    List<String>? rules,
    bool? requiresApproval,
    DateTime? createdAt,
    GroupCreator? creator,
    String? membershipStatus,
    String? userRole,
    bool? isMember,
    bool? isAdmin,
    bool? isSystem,
    int? conversationId,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      coverPhotoPath: coverPhotoPath ?? this.coverPhotoPath,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      privacy: privacy ?? this.privacy,
      creatorId: creatorId ?? this.creatorId,
      membersCount: membersCount ?? this.membersCount,
      postsCount: postsCount ?? this.postsCount,
      rules: rules ?? this.rules,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      createdAt: createdAt ?? this.createdAt,
      creator: creator ?? this.creator,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      userRole: userRole ?? this.userRole,
      isMember: isMember ?? this.isMember,
      isAdmin: isAdmin ?? this.isAdmin,
      isSystem: isSystem ?? this.isSystem,
      conversationId: conversationId ?? this.conversationId,
    );
  }

  bool get isPublic => privacy == 'public';
  bool get isPrivate => privacy == 'private';
  bool get isSecret => privacy == 'secret';
}

class GroupCreator {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePhotoPath;

  GroupCreator({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.profilePhotoPath,
  });

  factory GroupCreator.fromJson(Map<String, dynamic> json) {
    return GroupCreator(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'],
      profilePhotoPath: json['profile_photo_path'],
    );
  }

  String get fullName => '$firstName $lastName';
}

class GroupMember {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePhotoPath;
  final String role;
  final String status;
  final DateTime? joinedAt;

  GroupMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.profilePhotoPath,
    required this.role,
    required this.status,
    this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'],
      profilePhotoPath: json['profile_photo_path'],
      role: json['pivot']?['role'] ?? 'member',
      status: json['pivot']?['status'] ?? 'approved',
      joinedAt: json['pivot']?['joined_at'] != null
          ? DateTime.parse(json['pivot']['joined_at'])
          : null,
    );
  }

  String get fullName => '$firstName $lastName';
  bool get isAdmin => role == 'admin';
  bool get isModerator => role == 'moderator';
}

class GroupInvitation {
  final int id;
  final int groupId;
  final Group? group;
  final int inviterId;
  final GroupCreator? inviter;
  final int inviteeId;
  final String status;
  final DateTime createdAt;

  GroupInvitation({
    required this.id,
    required this.groupId,
    this.group,
    required this.inviterId,
    this.inviter,
    required this.inviteeId,
    required this.status,
    required this.createdAt,
  });

  factory GroupInvitation.fromJson(Map<String, dynamic> json) {
    return GroupInvitation(
      id: json['id'],
      groupId: json['group_id'],
      group: json['group'] != null ? Group.fromJson(json['group']) : null,
      inviterId: json['inviter_id'],
      inviter: json['inviter'] != null
          ? GroupCreator.fromJson(json['inviter'])
          : null,
      inviteeId: json['invitee_id'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
