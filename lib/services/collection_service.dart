// lib/services/collection_service.dart
//
// Curation feature service — closes G-F-001 frontend wiring.
// Talks to /api/collections (CollectionController on backend).

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_retry.dart';
import '../config/api_config.dart';

class Collection {
  final int id;
  final int curatorUserId;
  final String name;
  final String? description;
  final String? coverImagePath;
  final bool isPublic;
  final int itemsCount;
  final int followsCount;

  Collection({
    required this.id,
    required this.curatorUserId,
    required this.name,
    this.description,
    this.coverImagePath,
    required this.isPublic,
    required this.itemsCount,
    required this.followsCount,
  });

  factory Collection.fromJson(Map<String, dynamic> j) => Collection(
        id: _parseInt(j['id']),
        curatorUserId: _parseInt(j['curator_user_id']),
        name: j['name'] as String? ?? '',
        description: j['description'] as String?,
        coverImagePath: j['cover_image_path'] as String?,
        isPublic: _parseBool(j['is_public']),
        itemsCount: _parseInt(j['items_count']),
        followsCount: _parseInt(j['follows_count']),
      );
}

int _parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

bool _parseBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == 'true' || v == '1';
  return false;
}

class CollectionService {
  String get _base => ApiConfig.baseUrl;

  Future<List<Collection>> list({int? curatorUserId, String? token}) async {
    final params = <String, String>{
      if (curatorUserId != null) 'curator_user_id': '$curatorUserId',
    };
    final uri = Uri.parse('$_base/collections').replace(queryParameters: params);
    final resp = await httpGetWithRetry(uri,
        headers: token != null ? ApiConfig.authHeaders(token) : <String, String>{});
    if (resp.statusCode != 200) return [];
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (body['success'] != true) return [];
    final raw = body['data'] as List<dynamic>? ?? [];
    return raw.map((e) => Collection.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// UW-004 / row 75: pass `category='learning'` so adding posts to this
  /// collection also fires save_to_learning_collection·curator.
  /// Other categories: general | gallery | inspiration | reference.
  Future<int?> create({
    required int curatorUserId,
    required String name,
    String? description,
    bool isPublic = true,
    String? category,
    String? token,
  }) async {
    final resp = await http.post(
      Uri.parse('$_base/collections'),
      headers: token != null
          ? {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'}
          : {'Content-Type': 'application/json'},
      body: jsonEncode({
        'curator_user_id': curatorUserId,
        'name': name,
        if (description != null) 'description': description,
        'is_public': isPublic,
        if (category != null) 'category': category,
      }),
    );
    if (resp.statusCode != 201 && resp.statusCode != 200) return null;
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (body['success'] != true) return null;
    return _parseInt(body['data']?['id']);
  }

  Future<bool> addItem({
    required int collectionId,
    required int curatorUserId,
    required int postId,
    String? token,
  }) async {
    final resp = await http.post(
      Uri.parse('$_base/collections/$collectionId/items'),
      headers: token != null
          ? {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'}
          : {'Content-Type': 'application/json'},
      body: jsonEncode({'curator_user_id': curatorUserId, 'post_id': postId}),
    );
    return resp.statusCode == 200;
  }

  Future<bool> follow({
    required int collectionId,
    required int userId,
    String? token,
  }) async {
    final resp = await http.post(
      Uri.parse('$_base/collections/$collectionId/follow'),
      headers: token != null
          ? {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'}
          : {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );
    return resp.statusCode == 200;
  }

  /// UN-011 / posts.md row 60 — collection_view·curator.
  /// Fire when a user opens the collection detail page.
  Future<bool> recordView({
    required int collectionId,
    required int userId,
    String? token,
  }) async {
    final resp = await http.post(
      Uri.parse('$_base/collections/$collectionId/view'),
      headers: token != null
          ? {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'}
          : {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );
    return resp.statusCode == 200;
  }

  /// Fetch a single collection (post_ui_gaps UN-011 prerequisite).
  Future<Collection?> get(int collectionId, {String? token}) async {
    final resp = await httpGetWithRetry(
      Uri.parse('$_base/collections/$collectionId'),
      headers: token != null ? ApiConfig.authHeaders(token) : <String, String>{},
    );
    if (resp.statusCode != 200) return null;
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (body['success'] != true) return null;
    final data = body['data'];
    if (data is! Map<String, dynamic>) return null;
    return Collection.fromJson(data);
  }

  /// List the post IDs in a collection. Caller can fetch the post objects
  /// via PostService if needed.
  Future<List<int>> listItems(int collectionId, {String? token}) async {
    final resp = await httpGetWithRetry(
      Uri.parse('$_base/collections/$collectionId/items'),
      headers: token != null ? ApiConfig.authHeaders(token) : <String, String>{},
    );
    if (resp.statusCode != 200) return [];
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (body['success'] != true) return [];
    final raw = body['data'] as List<dynamic>? ?? [];
    return raw
        .map((e) => _parseInt((e as Map)['post_id']))
        .where((id) => id > 0)
        .toList(growable: false);
  }
}
