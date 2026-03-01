import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/group_models.dart';
import '../models/post_models.dart';
import '../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

class GroupService {
  /// Get list of groups
  Future<GroupListResult> getGroups({
    int page = 1,
    int perPage = 20,
    String? search,
    int? currentUserId,
  }) async {
    try {
      String url = '$_baseUrl/groups?page=$page&per_page=$perPage';
      if (search != null) url += '&search=$search';
      if (currentUserId != null) url += '&current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final groups = (data['data'] as List)
              .map((g) => Group.fromJson(g))
              .toList();
          return GroupListResult(success: true, groups: groups);
        }
      }
      return GroupListResult(success: false, message: 'Failed to load groups');
    } catch (e) {
      return GroupListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get user's groups (community + system groups e.g. Primary School, Location, Employer).
  /// Pass [includeSystemGroups] true so backend includes system groups in the response
  /// (e.g. GET /groups/user?user_id=4&include_system_groups=1).
  /// If the API returns a separate [system_groups] array, it is merged with [data].
  Future<GroupListResult> getUserGroups(int userId, {bool includeSystemGroups = true}) async {
    try {
      var url = '$_baseUrl/groups/user?user_id=$userId';
      if (includeSystemGroups) {
        url += '&include_system_groups=1';
      }
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<Group> groups = [];
          // Main list (community / user-created groups)
          final main = data['data'];
          if (main is List) {
            for (final g in main) {
              try {
                groups.add(Group.fromJson(g is Map<String, dynamic> ? g : Map<String, dynamic>.from(g)));
              } catch (_) {
                // skip malformed item
              }
            }
          }
          // Optional separate system_groups array (Primary School, Secondary, A-Level, University, Location, Employer)
          final systemGroups = data['system_groups'];
          if (systemGroups is List) {
            for (final g in systemGroups) {
              try {
                groups.add(Group.fromJson(g is Map<String, dynamic> ? g : Map<String, dynamic>.from(g)));
              } catch (_) {
                // skip malformed item
              }
            }
          }
          return GroupListResult(success: true, groups: groups);
        }
      }
      return GroupListResult(success: false, message: 'Failed to load groups');
    } catch (e) {
      return GroupListResult(success: false, message: 'Error: $e');
    }
  }

  /// Create a new group
  Future<GroupResult> createGroup({
    required int creatorId,
    required String name,
    String? description,
    String privacy = 'public',
    bool requiresApproval = false,
    List<String>? rules,
    File? coverPhoto,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/groups'));
      request.fields['creator_id'] = creatorId.toString();
      request.fields['name'] = name;
      if (description != null) request.fields['description'] = description;
      request.fields['privacy'] = privacy;
      request.fields['requires_approval'] = requiresApproval.toString();

      if (coverPhoto != null) {
        request.files.add(await http.MultipartFile.fromPath('cover_photo', coverPhoto.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return GroupResult(
          success: true,
          group: Group.fromJson(data['data']),
          message: data['message'],
        );
      }
      return GroupResult(success: false, message: data['message'] ?? 'Failed to create group');
    } catch (e) {
      return GroupResult(success: false, message: 'Error: $e');
    }
  }

  /// Get a single group
  Future<GroupResult> getGroup(String identifier, {int? currentUserId}) async {
    try {
      String url = '$_baseUrl/groups/$identifier';
      if (currentUserId != null) url += '?current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return GroupResult(success: true, group: Group.fromJson(data['data']));
        }
      }
      return GroupResult(success: false, message: 'Group not found');
    } catch (e) {
      return GroupResult(success: false, message: 'Error: $e');
    }
  }

  /// Join a group
  Future<JoinResult> joinGroup(int groupId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/groups/$groupId/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return JoinResult(
          success: true,
          status: data['data']?['status'] ?? 'approved',
          message: data['message'],
        );
      }
      return JoinResult(success: false, message: data['message'] ?? 'Failed to join');
    } catch (e) {
      return JoinResult(success: false, message: 'Error: $e');
    }
  }

  /// Leave a group
  Future<bool> leaveGroup(int groupId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/groups/$groupId/leave'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get group members
  Future<MemberListResult> getMembers(int groupId, {String status = 'approved', String? role}) async {
    try {
      String url = '$_baseUrl/groups/$groupId/members?status=$status';
      if (role != null) url += '&role=$role';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final members = (data['data'] as List)
              .map((m) => GroupMember.fromJson(m))
              .toList();
          return MemberListResult(success: true, members: members);
        }
      }
      return MemberListResult(success: false, message: 'Failed to load members');
    } catch (e) {
      return MemberListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get group posts
  Future<PostListResult> getGroupPosts(int groupId, {int page = 1, int perPage = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/groups/$groupId/posts?page=$page&per_page=$perPage'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final posts = (data['data'] as List)
              .map((p) => Post.fromJson(p))
              .toList();
          return PostListResult(success: true, posts: posts);
        }
      }
      return PostListResult(success: false, message: 'Failed to load posts');
    } catch (e) {
      return PostListResult(success: false, message: 'Error: $e');
    }
  }

  /// Create a post in a group
  Future<PostResult> createGroupPost({
    required int groupId,
    required int userId,
    String? content,
    List<File>? media,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/groups/$groupId/posts'));
      request.fields['user_id'] = userId.toString();
      if (content != null) request.fields['content'] = content;

      if (media != null) {
        for (var file in media) {
          request.files.add(await http.MultipartFile.fromPath('media[]', file.path));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return PostResult(success: true, post: Post.fromJson(data['data']));
      }
      return PostResult(success: false, message: data['message'] ?? 'Failed to create post');
    } catch (e) {
      return PostResult(success: false, message: 'Error: $e');
    }
  }

  /// Invite users to group
  Future<bool> inviteUsers(int groupId, int inviterId, List<int> inviteeIds) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/groups/$groupId/invite'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'inviter_id': inviterId,
          'invitee_ids': inviteeIds,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get user's pending invitations
  Future<InvitationListResult> getUserInvitations(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/groups/invitations?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final invitations = (data['data'] as List)
              .map((i) => GroupInvitation.fromJson(i))
              .toList();
          return InvitationListResult(success: true, invitations: invitations);
        }
      }
      return InvitationListResult(success: false, message: 'Failed to load invitations');
    } catch (e) {
      return InvitationListResult(success: false, message: 'Error: $e');
    }
  }

  /// Respond to invitation
  Future<bool> respondToInvitation(int invitationId, String response) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/groups/invitations/$invitationId/respond'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'response': response}),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Search groups
  Future<GroupListResult> searchGroups(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/groups/search?q=$query'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final groups = (data['data'] as List)
              .map((g) => Group.fromJson(g))
              .toList();
          return GroupListResult(success: true, groups: groups);
        }
      }
      return GroupListResult(success: false, message: 'Search failed');
    } catch (e) {
      return GroupListResult(success: false, message: 'Error: $e');
    }
  }

  /// Handle member request (approve/reject)
  Future<bool> handleMemberRequest(int groupId, int userId, String action) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/groups/$groupId/members/$userId/handle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': action}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Update member role
  Future<bool> updateMemberRole(int groupId, int userId, String role) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/groups/$groupId/members/$userId/role'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'role': role}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Remove member
  Future<bool> removeMember(int groupId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/groups/$groupId/members/$userId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// Result classes
class GroupListResult {
  final bool success;
  final List<Group> groups;
  final String? message;

  GroupListResult({required this.success, this.groups = const [], this.message});
}

class GroupResult {
  final bool success;
  final Group? group;
  final String? message;

  GroupResult({required this.success, this.group, this.message});
}

class JoinResult {
  final bool success;
  final String? status;
  final String? message;

  JoinResult({required this.success, this.status, this.message});
}

class MemberListResult {
  final bool success;
  final List<GroupMember> members;
  final String? message;

  MemberListResult({required this.success, this.members = const [], this.message});
}

class InvitationListResult {
  final bool success;
  final List<GroupInvitation> invitations;
  final String? message;

  InvitationListResult({required this.success, this.invitations = const [], this.message});
}

class PostListResult {
  final bool success;
  final List<Post> posts;
  final String? message;

  PostListResult({required this.success, this.posts = const [], this.message});
}

class PostResult {
  final bool success;
  final Post? post;
  final String? message;

  PostResult({required this.success, this.post, this.message});
}
