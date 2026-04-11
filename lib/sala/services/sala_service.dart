// lib/sala/services/sala_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/sala_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class SalaService {
  // ─── Prayer Requests ────────────────────────────────────────

  static Future<PaginatedResult<PrayerRequest>> getRequests({
    String? status,
    String? category,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (status != null) params['status'] = status;
      if (category != null) params['category'] = category;
      final r = await _dio.get('/sala/requests', queryParameters: params);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => PrayerRequest.fromJson(j))
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

  static Future<SingleResult<PrayerRequest>> createRequest(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/sala/requests', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: PrayerRequest.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> markAnswered(
      int id, String testimony) async {
    try {
      final r = await _dio
          .put('/sala/requests/$id/answer', data: {'testimony': testimony});
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> prayForRequest(int id) async {
    try {
      final r = await _dio.post('/sala/requests/$id/pray');
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Shared Feed ────────────────────────────────────────────

  static Future<PaginatedResult<PrayerRequest>> getSharedFeed(
      {int page = 1}) async {
    try {
      final r =
          await _dio.get('/sala/feed', queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => PrayerRequest.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Journal ────────────────────────────────────────────────

  static Future<PaginatedResult<PrayerJournalEntry>> getJournal(
      {int page = 1}) async {
    try {
      final r =
          await _dio.get('/sala/journal', queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => PrayerJournalEntry.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<PrayerJournalEntry>> addJournalEntry(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/sala/journal', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: PrayerJournalEntry.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Stats ──────────────────────────────────────────────────

  static Future<SingleResult<PrayerStats>> getStats() async {
    try {
      final r = await _dio.get('/sala/stats');
      final data = r.data;
      if (data['success'] == true && data['data'] != null) {
        return SingleResult(
            success: true, data: PrayerStats.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
