// lib/ibada/services/ibada_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/ibada_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class IbadaService {
  // ─── Hymns ──────────────────────────────────────────────────

  static Future<PaginatedResult<Hymn>> getHymns({
    String? book,
    String? search,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (book != null) params['book'] = book;
      if (search != null) params['q'] = search;
      final r = await _dio.get('/ibada/hymns', queryParameters: params);
      final data = r.data;
      if (data['success'] == true) {
        final items =
            (data['data'] as List).map((j) => Hymn.fromJson(j)).toList();
        return PaginatedResult(
          success: true,
          items: items,
          currentPage: data['meta']?['current_page'] ?? page,
          lastPage: data['meta']?['last_page'] ?? 1,
        );
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<Hymn>> getHymn(int hymnId) async {
    try {
      final r = await _dio.get('/ibada/hymns/$hymnId');
      final data = r.data;
      if (data['success'] == true && data['data'] != null) {
        return SingleResult(success: true, data: Hymn.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Gospel Songs ───────────────────────────────────────────

  static Future<PaginatedResult<WorshipSong>> getSongs({
    String? search,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (search != null) params['q'] = search;
      final r = await _dio.get('/ibada/songs', queryParameters: params);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => WorshipSong.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Playlists ──────────────────────────────────────────────

  static Future<PaginatedResult<WorshipPlaylist>> getPlaylists() async {
    try {
      final r = await _dio.get('/ibada/playlists');
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => WorshipPlaylist.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Favorites ──────────────────────────────────────────────

  static Future<SingleResult<void>> toggleFavorite(int hymnId) async {
    try {
      final r = await _dio.post('/ibada/hymns/$hymnId/favorite');
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
