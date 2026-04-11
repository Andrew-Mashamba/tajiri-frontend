// lib/events/services/event_wall_service.dart
import 'package:dio/dio.dart';
import '../models/event.dart';
import '../models/event_wall.dart';
import '../models/event_review.dart';
import '../../services/authenticated_dio.dart';

class EventWallService {
  Dio get _dio => AuthenticatedDio.instance;

  // ── Wall Posts ──

  Future<PaginatedResult<EventWallPost>> getWallPosts({required int eventId, int page = 1}) async {
    try {
      final response = await _dio.get('/events/$eventId/wall', queryParameters: {'page': page});
      if (response.data['success'] == true) {
        final data = response.data['data'];
        List rawItems = data is List ? data : (data is Map && data['data'] is List ? data['data'] : []);
        final items = rawItems.map((e) => EventWallPost.fromJson(e)).toList();
        final meta = response.data['meta'] as Map<String, dynamic>?;
        return PaginatedResult(
          success: true,
          items: items,
          currentPage: meta?['current_page'] ?? page,
          lastPage: meta?['last_page'] ?? 1,
          total: meta?['total'] ?? items.length,
        );
      }
      return PaginatedResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<EventWallPost>> createWallPost({
    required int eventId,
    required String content,
    String? type,
    List<String>? mediaPaths,
    bool isAnnouncement = false,
  }) async {
    try {
      final formData = FormData.fromMap({
        'content': content,
        'type': type ?? 'text',
        'is_announcement': isAnnouncement ? 1 : 0,
      });
      if (mediaPaths != null) {
        for (int i = 0; i < mediaPaths.length; i++) {
          formData.files.add(MapEntry('media[$i]', await MultipartFile.fromFile(mediaPaths[i])));
        }
      }
      final response = await _dio.post('/events/$eventId/wall', data: formData);
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: EventWallPost.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> deleteWallPost({required int postId}) async {
    try {
      final response = await _dio.delete('/wall/$postId');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> likeWallPost({required int postId}) async {
    try {
      final response = await _dio.post('/wall/$postId/like');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> unlikeWallPost({required int postId}) async {
    try {
      final response = await _dio.delete('/wall/$postId/like');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> pinWallPost({required int postId}) async {
    try {
      final response = await _dio.post('/wall/$postId/pin');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Comments ──

  Future<PaginatedResult<EventComment>> getComments({required int eventId, int page = 1}) async {
    try {
      final response = await _dio.get('/events/$eventId/comments', queryParameters: {'page': page});
      if (response.data['success'] == true) {
        final data = response.data['data'];
        List rawItems = data is List ? data : (data is Map && data['data'] is List ? data['data'] : []);
        final items = rawItems.map((e) => EventComment.fromJson(e)).toList();
        final meta = response.data['meta'] as Map<String, dynamic>?;
        return PaginatedResult(
          success: true,
          items: items,
          currentPage: meta?['current_page'] ?? page,
          lastPage: meta?['last_page'] ?? 1,
          total: meta?['total'] ?? items.length,
        );
      }
      return PaginatedResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<EventComment>> addComment({
    required int eventId,
    required String content,
    List<String>? mediaPaths,
  }) async {
    try {
      final dynamic data;
      if (mediaPaths != null && mediaPaths.isNotEmpty) {
        final formData = FormData.fromMap({'content': content});
        for (int i = 0; i < mediaPaths.length; i++) {
          formData.files.add(MapEntry('media[$i]', await MultipartFile.fromFile(mediaPaths[i])));
        }
        data = formData;
      } else {
        data = {'content': content};
      }
      final response = await _dio.post('/events/$eventId/comments', data: data);
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: EventComment.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<EventComment>> replyToComment({required int commentId, required String content}) async {
    try {
      final response = await _dio.post('/comments/$commentId/reply', data: {'content': content});
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: EventComment.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> deleteComment({required int commentId}) async {
    try {
      final response = await _dio.delete('/comments/$commentId');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> likeComment({required int commentId}) async {
    try {
      final response = await _dio.post('/comments/$commentId/like');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> pinComment({required int commentId}) async {
    try {
      final response = await _dio.post('/comments/$commentId/pin');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Photos ──

  Future<PaginatedResult<EventPhoto>> getEventPhotos({required int eventId, int page = 1}) async {
    try {
      final response = await _dio.get('/events/$eventId/photos', queryParameters: {'page': page});
      if (response.data['success'] == true) {
        final data = response.data['data'];
        List rawItems = data is List ? data : (data is Map && data['data'] is List ? data['data'] : []);
        final items = rawItems.map((e) => EventPhoto.fromJson(e)).toList();
        final meta = response.data['meta'] as Map<String, dynamic>?;
        return PaginatedResult(
          success: true,
          items: items,
          currentPage: meta?['current_page'] ?? page,
          lastPage: meta?['last_page'] ?? 1,
          total: meta?['total'] ?? items.length,
        );
      }
      return PaginatedResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<EventPhoto>> uploadEventPhoto({
    required int eventId,
    required String filePath,
    String? caption,
  }) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(filePath),
        if (caption != null) 'caption': caption,
      });
      final response = await _dio.post('/events/$eventId/photos', data: formData);
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: EventPhoto.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Reviews (Post-Event) ──

  Future<PaginatedResult<EventReview>> getReviews({required int eventId, int page = 1}) async {
    try {
      final response = await _dio.get('/events/$eventId/reviews', queryParameters: {'page': page});
      if (response.data['success'] == true) {
        final data = response.data['data'];
        List rawItems = data is List ? data : (data is Map && data['data'] is List ? data['data'] : []);
        final items = rawItems.map((e) => EventReview.fromJson(e)).toList();
        final meta = response.data['meta'] as Map<String, dynamic>?;
        return PaginatedResult(
          success: true,
          items: items,
          currentPage: meta?['current_page'] ?? page,
          lastPage: meta?['last_page'] ?? 1,
          total: meta?['total'] ?? items.length,
        );
      }
      return PaginatedResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<EventReview>> submitReview({
    required int eventId,
    required int rating,
    String? content,
    List<String>? photoPaths,
  }) async {
    try {
      final formData = FormData.fromMap({
        'rating': rating,
        if (content != null) 'content': content,
      });
      if (photoPaths != null) {
        for (int i = 0; i < photoPaths.length; i++) {
          formData.files.add(MapEntry('photos[$i]', await MultipartFile.fromFile(photoPaths[i])));
        }
      }
      final response = await _dio.post('/events/$eventId/reviews', data: formData);
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: EventReview.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
