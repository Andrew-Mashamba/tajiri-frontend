// lib/campus_news/services/campus_news_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/campus_news_models.dart';

class CampusNewsService {
  Dio get _dio => AuthenticatedDio.instance;

  Future<CampusListResult<CampusAnnouncement>> getAnnouncements({
    String? category,
    String? search,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (category != null) params['category'] = category;
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _dio.get('/education/campus-news',
          queryParameters: params);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => CampusAnnouncement.fromJson(j))
            .toList();
        return CampusListResult(success: true, items: items);
      }
      return CampusListResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return CampusListResult(success: false, message: '$e');
    }
  }

  Future<CampusResult<CampusAnnouncement>> getAnnouncement(int id) async {
    try {
      final res = await _dio.get('/education/campus-news/$id');
      if (res.statusCode == 200 && res.data['success'] == true) {
        return CampusResult(
          success: true,
          data: CampusAnnouncement.fromJson(res.data['data']),
        );
      }
      return CampusResult(success: false, message: 'Haipatikani');
    } catch (e) {
      return CampusResult(success: false, message: '$e');
    }
  }

  Future<CampusResult<void>> saveAnnouncement(int id) async {
    try {
      final res = await _dio.post('/education/campus-news/$id/save');
      return CampusResult(success: res.statusCode == 200);
    } catch (e) {
      return CampusResult(success: false, message: '$e');
    }
  }

  Future<CampusListResult<CampusEvent>> getEvents({int page = 1}) async {
    try {
      final res = await _dio.get('/education/campus-events',
          queryParameters: {'page': page});
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => CampusEvent.fromJson(j))
            .toList();
        return CampusListResult(success: true, items: items);
      }
      return CampusListResult(success: false);
    } catch (e) {
      return CampusListResult(success: false, message: '$e');
    }
  }

  Future<CampusResult<void>> rsvpEvent(int eventId) async {
    try {
      final res =
          await _dio.post('/education/campus-events/$eventId/rsvp');
      return CampusResult(success: res.statusCode == 200);
    } catch (e) {
      return CampusResult(success: false, message: '$e');
    }
  }

  Future<CampusListResult<CampusAnnouncement>> getSaved() async {
    try {
      final res = await _dio.get('/education/campus-news/saved');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => CampusAnnouncement.fromJson(j))
            .toList();
        return CampusListResult(success: true, items: items);
      }
      return CampusListResult(success: false);
    } catch (e) {
      return CampusListResult(success: false, message: '$e');
    }
  }
}
