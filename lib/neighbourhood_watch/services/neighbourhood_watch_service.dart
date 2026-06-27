// lib/neighbourhood_watch/services/neighbourhood_watch_service.dart
import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../services/authenticated_dio.dart';
import '../../services/graphql/graphql_neighbourhood_service.dart';
import '../models/neighbourhood_watch_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class NeighbourhoodWatchService {
  static Future<PaginatedResult<CommunityAlert>> getAlerts({
    int page = 1,
    String? type,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlNeighbourhoodService.getAlerts(page: page, type: type);
    }
    try {
      final q = <String, dynamic>{'page': page};
      if (type != null) q['type'] = type;
      final r = await _dio.get('/neighbourhood/alerts', queryParameters: q);
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => CommunityAlert.fromJson(j))
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

  static Future<SingleResult<CommunityAlert>> submitAlert(
      Map<String, dynamic> body) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlNeighbourhoodService.submitAlert(body);
    }
    try {
      final r = await _dio.post('/neighbourhood/alerts', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: CommunityAlert.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> confirmAlert(int alertId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlNeighbourhoodService.confirmAlert(alertId);
    }
    try {
      final r = await _dio.post('/neighbourhood/alerts/$alertId/confirm');
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<PatrolSchedule>> getPatrols() async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlNeighbourhoodService.getPatrols();
    }
    try {
      final r = await _dio.get('/neighbourhood/patrols');
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => PatrolSchedule.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> joinPatrol(int patrolId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlNeighbourhoodService.joinPatrol(patrolId);
    }
    try {
      final r = await _dio.post('/neighbourhood/patrols/$patrolId/join');
      return SingleResult(success: r.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
