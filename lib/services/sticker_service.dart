import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// A single sticker within a pack.
class Sticker {
  final int id;
  final String imageUrl;
  final String? emoji;

  const Sticker({required this.id, required this.imageUrl, this.emoji});

  factory Sticker.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['image_url'] as String? ?? json['url'] as String? ?? '';
    final imageUrl = rawUrl.startsWith('http') ? rawUrl : '${ApiConfig.storageUrl}/$rawUrl';
    return Sticker(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      imageUrl: imageUrl,
      emoji: json['emoji'] as String?,
    );
  }
}

/// A collection of stickers grouped into a pack.
class StickerPack {
  final int id;
  final String name;
  final String? thumbnailUrl;
  final List<Sticker> stickers;

  const StickerPack({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.stickers = const [],
  });

  factory StickerPack.fromJson(Map<String, dynamic> json) {
    final rawThumb = json['thumbnail_url'] as String? ?? json['thumbnail'] as String?;
    final thumbnailUrl = rawThumb != null
        ? (rawThumb.startsWith('http') ? rawThumb : '${ApiConfig.storageUrl}/$rawThumb')
        : null;
    final stickersJson = json['stickers'] as List? ?? [];
    return StickerPack(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? 'Stickers',
      thumbnailUrl: thumbnailUrl,
      stickers: stickersJson
          .map((s) => Sticker.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Service for fetching sticker packs from the backend.
class StickerService {
  static Future<List<StickerPack>> getPacks() async {
    try {
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/stickers/packs'),
        headers: ApiConfig.headers,
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final packs = data['packs'] ?? data['data'] ?? data;
        if (packs is List) {
          return packs
              .map((p) => StickerPack.fromJson(p as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('[StickerService] getPacks error: $e');
      return [];
    }
  }
}
