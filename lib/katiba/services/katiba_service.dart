// lib/katiba/services/katiba_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/katiba_models.dart';

class KatibaService {
  Dio get _dio => AuthenticatedDio.instance;

  // ─── Chapters ─────────────────────────────────────────────────
  Future<PaginatedResult<Chapter>> getChapters() async {
    try {
      final r = await _dio.get('/katiba/chapters');
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => Chapter.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  // ─── Article ──────────────────────────────────────────────────
  Future<SingleResult<Article>> getArticle(int id) async {
    try {
      final r = await _dio.get('/katiba/articles/$id');
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(success: true, data: Article.fromJson(d['data']));
      }
      return SingleResult(message: d['message'] ?? 'Not found');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  // ─── Search ───────────────────────────────────────────────────
  Future<PaginatedResult<Article>> searchArticles(
    String query, {
    int page = 1,
  }) async {
    try {
      final r = await _dio.get('/katiba/search', queryParameters: {
        'q': query,
        'page': page,
      });
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => Article.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items, page: page);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  // ─── Amendments ───────────────────────────────────────────────
  Future<PaginatedResult<Amendment>> getAmendments() async {
    try {
      final r = await _dio.get('/katiba/amendments');
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => Amendment.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  // ─── Quiz ─────────────────────────────────────────────────────
  Future<PaginatedResult<QuizQuestion>> getQuiz({int? chapterId}) async {
    try {
      final r = await _dio.get('/katiba/quiz', queryParameters: {
        if (chapterId != null) 'chapter_id': chapterId,
      });
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => QuizQuestion.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  Future<SingleResult<QuizResult>> submitQuizScore(
    Map<String, dynamic> data,
  ) async {
    try {
      final r = await _dio.post('/katiba/quiz/score', data: data);
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(
          success: true,
          data: QuizResult.fromJson(d['data']),
        );
      }
      return SingleResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  // ─── Daily Article ────────────────────────────────────────────
  Future<SingleResult<Article>> getDailyArticle() async {
    try {
      final r = await _dio.get('/katiba/daily');
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(success: true, data: Article.fromJson(d['data']));
      }
      return SingleResult(message: d['message'] ?? 'Not found');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  // ─── Glossary ─────────────────────────────────────────────────
  Future<PaginatedResult<GlossaryTerm>> getGlossary() async {
    try {
      final r = await _dio.get('/katiba/glossary');
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => GlossaryTerm.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }
}
