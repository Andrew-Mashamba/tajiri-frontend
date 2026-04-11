// lib/owners_club/services/owners_club_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/owners_club_models.dart';

class OwnersClubService {
  Dio get _dio => AuthenticatedDio.instance;

  // ─── Communities ──────────────────────────────────────────────

  Future<PaginatedResult<Community>> getCommunities({
    String? brand,
    bool? joined,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (brand != null) params['brand'] = brand;
      if (joined != null) params['joined'] = joined ? 1 : 0;

      final resp = await _dio.get('/owners-club/communities', queryParameters: params);
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => Community.fromJson(j))
            .toList();
        return PaginatedResult(
          success: true,
          items: list,
          currentPage: data['current_page'] ?? page,
          lastPage: data['last_page'] ?? 1,
        );
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<Community>> getCommunity(int id) async {
    try {
      final resp = await _dio.get('/owners-club/communities/$id');
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: Community.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<bool>> joinCommunity(int id) async {
    try {
      final resp = await _dio.post('/owners-club/communities/$id/join');
      final data = resp.data;
      return SingleResult(success: data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Feed ─────────────────────────────────────────────────────

  Future<PaginatedResult<KnowledgePost>> getCommunityFeed(
    int communityId, {
    int page = 1,
  }) async {
    try {
      final resp = await _dio.get(
        '/owners-club/communities/$communityId/feed',
        queryParameters: {'page': page},
      );
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => KnowledgePost.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: list);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Knowledge Base ───────────────────────────────────────────

  Future<PaginatedResult<KnowledgePost>> getKnowledgeBase(
    int communityId, {
    String? search,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (search != null && search.isNotEmpty) params['search'] = search;

      final resp = await _dio.get(
        '/owners-club/communities/$communityId/knowledge',
        queryParameters: params,
      );
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => KnowledgePost.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: list);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ─── Showcases ────────────────────────────────────────────────

  Future<PaginatedResult<VehicleShowcase>> getShowcases(
    int communityId, {
    int page = 1,
  }) async {
    try {
      final resp = await _dio.get(
        '/owners-club/communities/$communityId/showcases',
        queryParameters: {'page': page},
      );
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => VehicleShowcase.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: list);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<VehicleShowcase>> createShowcase(Map<String, dynamic> data_) async {
    try {
      final resp = await _dio.post('/owners-club/showcases', data: data_);
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: VehicleShowcase.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Events ───────────────────────────────────────────────────

  Future<PaginatedResult<CommunityEvent>> getCommunityEvents(
    int communityId, {
    int page = 1,
  }) async {
    try {
      final resp = await _dio.get(
        '/owners-club/communities/$communityId/events',
        queryParameters: {'page': page},
      );
      final data = resp.data;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((j) => CommunityEvent.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: list);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<bool>> rsvpEvent(int eventId) async {
    try {
      final resp = await _dio.post('/owners-club/events/$eventId/rsvp');
      final data = resp.data;
      return SingleResult(success: data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ─── Questions ────────────────────────────────────────────────

  Future<SingleResult<KnowledgePost>> askQuestion(
    int communityId,
    Map<String, dynamic> questionData,
  ) async {
    try {
      final resp = await _dio.post(
        '/owners-club/communities/$communityId/questions',
        data: questionData,
      );
      final data = resp.data;
      if (data['success'] == true) {
        return SingleResult(success: true, data: KnowledgePost.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
