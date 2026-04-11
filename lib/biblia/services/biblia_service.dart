// lib/biblia/services/biblia_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/biblia_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class BibliaService {
  // ─── Books ──────────────────────────────────────────────────

  static Future<PaginatedResult<BibleBook>> getBooks() async {
    try {
      final r = await _dio.get('/biblia/books');
      final data = r.data;
      if (data['success'] == true) {
        final items =
            (data['data'] as List).map((j) => BibleBook.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Chapter Verses ─────────────────────────────────────────

  static Future<PaginatedResult<BibleVerse>> getChapter({
    required int bookId,
    required int chapter,
    String translation = 'suv',
  }) async {
    try {
      final r = await _dio.get('/biblia/books/$bookId/chapters/$chapter',
          queryParameters: {'translation': translation});
      final data = r.data;
      if (data['success'] == true) {
        final items =
            (data['data'] as List).map((j) => BibleVerse.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Verse of the Day ───────────────────────────────────────

  static Future<SingleResult<VerseOfDay>> getVerseOfDay() async {
    try {
      final r = await _dio.get('/biblia/verse-of-day');
      final data = r.data;
      if (data['success'] == true && data['data'] != null) {
        return SingleResult(
            success: true, data: VerseOfDay.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Search ─────────────────────────────────────────────────

  static Future<PaginatedResult<BibleSearchResult>> search({
    required String query,
    String? testament,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{
        'q': query,
        'page': page,
      };
      if (testament != null) params['testament'] = testament;
      final r = await _dio.get('/biblia/search', queryParameters: params);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => BibleSearchResult.fromJson(j))
            .toList();
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

  // ─── Bookmarks ──────────────────────────────────────────────

  static Future<PaginatedResult<BibleBookmark>> getBookmarks(
      {int page = 1}) async {
    try {
      final r = await _dio
          .get('/biblia/bookmarks', queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => BibleBookmark.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<BibleBookmark>> addBookmark(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/biblia/bookmarks', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: BibleBookmark.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> removeBookmark(int id) async {
    try {
      final r = await _dio.delete('/biblia/bookmarks/$id');
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
