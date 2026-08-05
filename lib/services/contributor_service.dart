// lib/services/contributor_service.dart
//
// Talks to /api/posts/{id}/contributors (PostContributorController on backend).
// Backs the contributor picker widget — closes G-F-005 frontend wiring.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_retry.dart';
import '../config/api_config.dart';
import 'graphql/graphql_contributor_service.dart';

class PostContributor {
  final int id;
  final int postId;
  final int userId;
  final String role;
  final double sharePct;
  final String? userName;
  final String? userHandle;
  final String? userPhotoUrl;
  final bool accepted;

  PostContributor({
    required this.id,
    required this.postId,
    required this.userId,
    required this.role,
    required this.sharePct,
    this.userName,
    this.userHandle,
    this.userPhotoUrl,
    required this.accepted,
  });

  factory PostContributor.fromJson(Map<String, dynamic> j) => PostContributor(
        id: _i(j['id']),
        postId: _i(j['post_id']),
        userId: _i(j['user_id']),
        role: j['role'] as String? ?? 'collaborator',
        sharePct: _d(j['share_pct']),
        userName: j['user_name'] as String?,
        userHandle: j['user_handle'] as String?,
        userPhotoUrl: j['user_photo_url'] as String?,
        accepted: _b(j['accepted']),
      );
}

int _i(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _d(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

bool _b(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == 'true' || v == '1';
  return false;
}

/// Canonical contributor roles from posts.md §VIII rows 65-72.
/// Backend `PostContributorController::store` validates against this exact
/// enum. UW-006 (post_ui_gaps.md) — strings are aligned with posts.md spec.
const List<String> kContributorRoles = <String>[
  'photographer',
  'editor',
  'colorist',
  'thumbnail_designer',
  'caption_writer',
  'narrator',
  'composer',
  'creative_director',
];

class ContributorService {
  String get _base => ApiConfig.baseUrl;

  Future<List<PostContributor>> list(int postId, {String? token}) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlContributorService.list(postId);
    }
    final resp = await httpGetWithRetry(
      Uri.parse('$_base/posts/$postId/contributors'),
      headers: token != null ? ApiConfig.authHeaders(token) : <String, String>{},
    );
    if (resp.statusCode != 200) return [];
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (body['success'] != true) return [];
    final raw = body['data'] as List<dynamic>? ?? [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(PostContributor.fromJson)
        .toList(growable: false);
  }

  Future<bool> add({
    required int postId,
    required int ownerUserId,
    required int userId,
    required String role,
    required double sharePct,
    String? token,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlContributorService.add(
        postId: postId,
        userId: userId,
        role: role,
        sharePct: sharePct,
      );
    }
    final resp = await http.post(
      Uri.parse('$_base/posts/$postId/contributors'),
      headers: token != null
          ? {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'}
          : {'Content-Type': 'application/json'},
      body: jsonEncode({
        'owner_user_id': ownerUserId,
        'user_id': userId,
        'role': role,
        'share_pct': sharePct,
      }),
    );
    return resp.statusCode == 200 || resp.statusCode == 201;
  }

  Future<bool> remove({
    required int postId,
    required int contributorId,
    required int ownerUserId,
    String? token,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlContributorService.remove(
        postId: postId,
        contributorId: contributorId,
      );
    }
    final uri = Uri.parse('$_base/posts/$postId/contributors/$contributorId')
        .replace(queryParameters: {'owner_user_id': '$ownerUserId'});
    final resp = await http.delete(
      uri,
      headers: token != null ? ApiConfig.authHeaders(token) : <String, String>{},
    );
    return resp.statusCode == 200;
  }
}
