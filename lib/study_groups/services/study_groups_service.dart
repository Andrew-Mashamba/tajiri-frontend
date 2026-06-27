// lib/study_groups/services/study_groups_service.dart
import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../services/authenticated_dio.dart';
import '../../services/graphql/graphql_study_groups_service.dart';
import '../models/study_groups_models.dart';

class StudyGroupsService {
  Dio get _dio => AuthenticatedDio.instance;

  Future<StudyListResult<StudyGroup>> getMyGroups() async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlStudyGroupsService.getMyGroups();
    }
    try {
      final res = await _dio.get('/education/study-groups');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => StudyGroup.fromJson(j))
            .toList();
        return StudyListResult(success: true, items: items);
      }
      return StudyListResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return StudyListResult(success: false, message: '$e');
    }
  }

  Future<StudyListResult<StudyGroup>> discoverGroups({
    String? subject,
    String? search,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlStudyGroupsService.discoverGroups(
        subject: subject,
        search: search,
      );
    }
    try {
      final params = <String, dynamic>{};
      if (subject != null) params['subject'] = subject;
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _dio.get('/education/study-groups/discover',
          queryParameters: params);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => StudyGroup.fromJson(j))
            .toList();
        return StudyListResult(success: true, items: items);
      }
      return StudyListResult(success: false);
    } catch (e) {
      return StudyListResult(success: false, message: '$e');
    }
  }

  Future<StudyResult<StudyGroup>> createGroup({
    required String name,
    required String subject,
    String? description,
    String? courseCode,
    int maxMembers = 8,
    bool isPublic = true,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlStudyGroupsService.createGroup(
        name: name,
        subject: subject,
        description: description,
        courseCode: courseCode,
        maxMembers: maxMembers,
        isPublic: isPublic,
      );
    }
    try {
      final res = await _dio.post('/education/study-groups', data: {
        'name': name,
        'subject': subject,
        if (description != null) 'description': description,
        if (courseCode != null) 'course_code': courseCode,
        'max_members': maxMembers,
        'is_public': isPublic,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        return StudyResult(
          success: true,
          data: StudyGroup.fromJson(res.data['data']),
        );
      }
      return StudyResult(success: false, message: 'Imeshindwa kuunda');
    } catch (e) {
      return StudyResult(success: false, message: '$e');
    }
  }

  Future<StudyResult<void>> joinGroup(int groupId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlStudyGroupsService.joinGroup(groupId);
    }
    try {
      final res =
          await _dio.post('/education/study-groups/$groupId/join');
      return StudyResult(success: res.statusCode == 200);
    } catch (e) {
      return StudyResult(success: false, message: '$e');
    }
  }

  Future<StudyListResult<StudyGroupMember>> getMembers(int groupId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlStudyGroupsService.getMembers(groupId);
    }
    try {
      final res =
          await _dio.get('/education/study-groups/$groupId/members');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => StudyGroupMember.fromJson(j))
            .toList();
        return StudyListResult(success: true, items: items);
      }
      return StudyListResult(success: false);
    } catch (e) {
      return StudyListResult(success: false, message: '$e');
    }
  }

  Future<StudyListResult<GroupStudySession>> getSessions(int groupId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlStudyGroupsService.getSessions(groupId);
    }
    try {
      final res =
          await _dio.get('/education/study-groups/$groupId/sessions');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => GroupStudySession.fromJson(j))
            .toList();
        return StudyListResult(success: true, items: items);
      }
      return StudyListResult(success: false);
    } catch (e) {
      return StudyListResult(success: false, message: '$e');
    }
  }

  Future<StudyResult<GroupStudySession>> scheduleSession({
    required int groupId,
    required String topic,
    required DateTime scheduledAt,
    int durationMinutes = 60,
    String? location,
    bool isVirtual = false,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlStudyGroupsService.scheduleSession(
        groupId: groupId,
        topic: topic,
        scheduledAt: scheduledAt,
        durationMinutes: durationMinutes,
        location: location,
        isVirtual: isVirtual,
      );
    }
    try {
      final res = await _dio.post(
        '/education/study-groups/$groupId/sessions',
        data: {
          'topic': topic,
          'scheduled_at': scheduledAt.toIso8601String(),
          'duration_minutes': durationMinutes,
          if (location != null) 'location': location,
          'is_virtual': isVirtual,
        },
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        return StudyResult(
          success: true,
          data: GroupStudySession.fromJson(res.data['data']),
        );
      }
      return StudyResult(success: false);
    } catch (e) {
      return StudyResult(success: false, message: '$e');
    }
  }

  Future<StudyResult<void>> checkIn(int sessionId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlStudyGroupsService.checkIn(sessionId);
    }
    try {
      final res = await _dio
          .post('/education/study-sessions/$sessionId/check-in');
      return StudyResult(success: res.statusCode == 200);
    } catch (e) {
      return StudyResult(success: false, message: '$e');
    }
  }
}
