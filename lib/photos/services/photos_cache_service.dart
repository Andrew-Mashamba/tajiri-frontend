// lib/photos/services/photos_cache_service.dart
//
// Layered cache for a user's photos grid and albums.
//   • In-memory (Map<int, List<Photo>> / Map<int, List<PhotoAlbum>>)
//   • Hive-backed disk (Box<String>) — capped at 100 per key.
//
// Cleared by AuthService._performLocalLogout() on sign-out.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/photo_models.dart';

class PhotosCacheService {
  PhotosCacheService._();
  static final PhotosCacheService instance = PhotosCacheService._();

  static const String _boxName = 'photos_cache';
  static const int _maxItemsPerKey = 100;

  Box<String>? _box;
  final Map<int, List<Photo>> _hotPhotos = {};
  final Map<int, List<PhotoAlbum>> _hotAlbums = {};

  Future<Box<String>> _getBox() async {
    _box ??= await Hive.openBox<String>(_boxName);
    return _box!;
  }

  String _photosKey(int userId) => 'photos_$userId';
  String _albumsKey(int userId) => 'albums_$userId';

  // ── Photos ───────────────────────────────────────────────────────────

  List<Photo>? getPhotosSync(int userId) => _hotPhotos[userId];

  Future<List<Photo>?> getPhotosCached(int userId) async {
    final hot = _hotPhotos[userId];
    if (hot != null) return hot;
    try {
      final box = await _getBox();
      final raw = box.get(_photosKey(userId));
      if (raw == null) return null;
      final list = jsonDecode(raw) as List;
      final photos = list
          .whereType<Map<String, dynamic>>()
          .map(Photo.fromJson)
          .toList();
      _hotPhotos[userId] = photos;
      return photos;
    } catch (e) {
      if (kDebugMode) debugPrint('[PhotosCache] getPhotosCached failed: $e');
      return null;
    }
  }

  Future<void> savePhotos(int userId, List<Photo> photos) async {
    _hotPhotos[userId] = photos;
    final capped = photos.length > _maxItemsPerKey
        ? photos.sublist(0, _maxItemsPerKey)
        : photos;
    try {
      final box = await _getBox();
      await box.put(
          _photosKey(userId), jsonEncode(capped.map((p) => p.toJson()).toList()));
    } catch (e) {
      if (kDebugMode) debugPrint('[PhotosCache] savePhotos failed: $e');
    }
  }

  Future<void> invalidatePhotos(int userId) async {
    _hotPhotos.remove(userId);
    try {
      final box = await _getBox();
      await box.delete(_photosKey(userId));
    } catch (_) {}
  }

  // ── Albums ───────────────────────────────────────────────────────────

  List<PhotoAlbum>? getAlbumsSync(int userId) => _hotAlbums[userId];

  Future<List<PhotoAlbum>?> getAlbumsCached(int userId) async {
    final hot = _hotAlbums[userId];
    if (hot != null) return hot;
    try {
      final box = await _getBox();
      final raw = box.get(_albumsKey(userId));
      if (raw == null) return null;
      final list = jsonDecode(raw) as List;
      final albums = list
          .whereType<Map<String, dynamic>>()
          .map(PhotoAlbum.fromJson)
          .toList();
      _hotAlbums[userId] = albums;
      return albums;
    } catch (e) {
      if (kDebugMode) debugPrint('[PhotosCache] getAlbumsCached failed: $e');
      return null;
    }
  }

  Future<void> saveAlbums(int userId, List<PhotoAlbum> albums) async {
    _hotAlbums[userId] = albums;
    final capped = albums.length > _maxItemsPerKey
        ? albums.sublist(0, _maxItemsPerKey)
        : albums;
    try {
      final box = await _getBox();
      await box.put(
          _albumsKey(userId), jsonEncode(capped.map((a) => a.toJson()).toList()));
    } catch (e) {
      if (kDebugMode) debugPrint('[PhotosCache] saveAlbums failed: $e');
    }
  }

  Future<void> invalidateAlbums(int userId) async {
    _hotAlbums.remove(userId);
    try {
      final box = await _getBox();
      await box.delete(_albumsKey(userId));
    } catch (_) {}
  }

  // ── Global ───────────────────────────────────────────────────────────

  Future<void> clear() async {
    _hotPhotos.clear();
    _hotAlbums.clear();
    try {
      final box = await _getBox();
      await box.clear();
    } catch (_) {}
  }
}
