// lib/services/post_tagged_product_service.dart
//
// UN-012 — strategy posts.md §X. Talks to /posts/{id}/tagged-products
// (PostTaggedProductController on backend).

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_retry.dart';
import '../config/api_config.dart';

class PostTaggedProduct {
  final int id;
  final int postId;
  final int productId;
  final double? positionX;
  final double? positionY;
  final int mediaIndex;
  final String? productName;
  final double? productPrice;

  PostTaggedProduct({
    required this.id,
    required this.postId,
    required this.productId,
    this.positionX,
    this.positionY,
    required this.mediaIndex,
    this.productName,
    this.productPrice,
  });

  factory PostTaggedProduct.fromJson(Map<String, dynamic> j) => PostTaggedProduct(
        id: _i(j['id']),
        postId: _i(j['post_id']),
        productId: _i(j['product_id']),
        positionX: _d(j['position_x']),
        positionY: _d(j['position_y']),
        mediaIndex: _i(j['media_index']),
        productName: j['product_name'] as String?,
        productPrice: _d(j['product_price']),
      );
}

int _i(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double? _d(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

class TaggedProductDraft {
  final int productId;
  final double? positionX;
  final double? positionY;
  final int mediaIndex;
  TaggedProductDraft({
    required this.productId,
    this.positionX,
    this.positionY,
    this.mediaIndex = 0,
  });
}

class PostTaggedProductService {
  String get _base => ApiConfig.baseUrl;

  Future<List<PostTaggedProduct>> list(int postId) async {
    try {
      final resp = await httpGetWithRetry(Uri.parse('$_base/posts/$postId/tagged-products'));
      if (resp.statusCode != 200) return const [];
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      if (body['success'] != true) return const [];
      final raw = body['data'] as List<dynamic>? ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(PostTaggedProduct.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<bool> attach({
    required int postId,
    required int ownerUserId,
    required List<TaggedProductDraft> tags,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/posts/$postId/tagged-products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'owner_user_id': ownerUserId,
          'tags': tags
              .map((t) => {
                    'product_id': t.productId,
                    if (t.positionX != null) 'position_x': t.positionX,
                    if (t.positionY != null) 'position_y': t.positionY,
                    'media_index': t.mediaIndex,
                  })
              .toList(),
        }),
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> detach({
    required int postId,
    required int productId,
    required int ownerUserId,
  }) async {
    try {
      final resp = await http.delete(
        Uri.parse('$_base/posts/$postId/tagged-products/$productId?owner_user_id=$ownerUserId'),
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
