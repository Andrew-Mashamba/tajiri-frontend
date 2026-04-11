// lib/huduma/services/huduma_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/huduma_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class HudumaService {
  // ─── Sermons ────────────────────────────────────────────────

  static Future<PaginatedResult<Sermon>> getSermons({
    String? topic,
    int? speakerId,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (topic != null) params['topic'] = topic;
      if (speakerId != null) params['speaker_id'] = speakerId;
      final r = await _dio.get('/huduma/sermons', queryParameters: params);
      final data = r.data;
      if (data['success'] == true) {
        final items =
            (data['data'] as List).map((j) => Sermon.fromJson(j)).toList();
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

  static Future<SingleResult<Sermon>> getSermon(int sermonId) async {
    try {
      final r = await _dio.get('/huduma/sermons/$sermonId');
      final data = r.data;
      if (data['success'] == true && data['data'] != null) {
        return SingleResult(
            success: true, data: Sermon.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Speakers ───────────────────────────────────────────────

  static Future<PaginatedResult<Speaker>> getSpeakers(
      {int page = 1}) async {
    try {
      final r =
          await _dio.get('/huduma/speakers', queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items =
            (data['data'] as List).map((j) => Speaker.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> followSpeaker(int speakerId) async {
    try {
      final r = await _dio.post('/huduma/speakers/$speakerId/follow');
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Search ─────────────────────────────────────────────────

  static Future<PaginatedResult<Sermon>> search({
    required String query,
    int page = 1,
  }) async {
    try {
      final r = await _dio.get('/huduma/search',
          queryParameters: {'q': query, 'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items =
            (data['data'] as List).map((j) => Sermon.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }
}
