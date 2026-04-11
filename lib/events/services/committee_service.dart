// lib/events/services/committee_service.dart
import 'package:dio/dio.dart';
import '../models/event.dart';
import '../models/committee.dart';
import '../models/event_template.dart';
import '../../services/authenticated_dio.dart';

class CommitteeService {
  Dio get _dio => AuthenticatedDio.instance;

  // ── Create Committee ──

  Future<SingleResult<EventCommittee>> createCommittee({
    required int eventId,
    required String name,
    bool isMainCommittee = true,
    int? parentCommitteeId,
  }) async {
    try {
      final response = await _dio.post('/events/$eventId/committees', data: {
        'name': name,
        'is_main_committee': isMainCommittee,
        if (parentCommitteeId != null) 'parent_committee_id': parentCommitteeId,
      });
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: EventCommittee.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  /// Create full committee structure from template config
  Future<SingleResult<EventCommittee>> createFromTemplate({
    required int eventId,
    required String eventName,
    required KamatiConfig config,
  }) async {
    try {
      final response = await _dio.post('/events/$eventId/committees/from-template', data: {
        'event_name': eventName,
        'has_sub_committees': config.hasSubCommittees,
        'sub_committees': config.defaultSubCommittees,
        'roles': config.defaultRoles,
        'has_meetings': config.hasMeetings,
        'has_task_tracking': config.hasTaskTracking,
      });
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: EventCommittee.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Get Committees ──

  Future<List<EventCommittee>> getCommittees({required int eventId}) async {
    try {
      final response = await _dio.get('/events/$eventId/committees');
      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? []).map((e) => EventCommittee.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<SingleResult<EventCommittee>> getCommittee({required int committeeId}) async {
    try {
      final response = await _dio.get('/committees/$committeeId');
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: EventCommittee.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Members ──

  Future<SingleResult<void>> addMember({
    required int committeeId,
    required int userId,
    CommitteeRole role = CommitteeRole.mjumbe,
  }) async {
    try {
      final response = await _dio.post('/committees/$committeeId/members', data: {
        'user_id': userId,
        'role': role.name,
      });
      return SingleResult(success: response.data['success'] == true, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> removeMember({required int committeeId, required int userId}) async {
    try {
      final response = await _dio.delete('/committees/$committeeId/members/$userId');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> updateMemberRole({
    required int committeeId,
    required int userId,
    required CommitteeRole role,
  }) async {
    try {
      final response = await _dio.put('/committees/$committeeId/members/$userId', data: {'role': role.name});
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<List<CommitteeMember>> getMembers({required int committeeId}) async {
    try {
      final response = await _dio.get('/committees/$committeeId/members');
      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? []).map((e) => CommitteeMember.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── Meetings ──

  Future<SingleResult<Meeting>> createMeeting({
    required int committeeId,
    required String title,
    required DateTime date,
    String? location,
    String? agenda,
  }) async {
    try {
      final response = await _dio.post('/committees/$committeeId/meetings', data: {
        'title': title,
        'date': date.toIso8601String(),
        if (location != null) 'location': location,
        if (agenda != null) 'agenda': agenda,
      });
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: Meeting.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<List<Meeting>> getMeetings({required int committeeId}) async {
    try {
      final response = await _dio.get('/committees/$committeeId/meetings');
      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? []).map((e) => Meeting.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<SingleResult<void>> saveMeetingMinutes({
    required int meetingId,
    required String minutes,
  }) async {
    try {
      final response = await _dio.put('/meetings/$meetingId', data: {'minutes': minutes});
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> recordAttendance({
    required int meetingId,
    required List<int> attendeeIds,
  }) async {
    try {
      final response = await _dio.post('/meetings/$meetingId/attendance', data: {'attendee_ids': attendeeIds});
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Budget Allocation for Sub-Committees ──

  Future<SingleResult<void>> setBudgetAllocation({
    required int committeeId,
    required double amount,
  }) async {
    try {
      final response = await _dio.put('/committees/$committeeId/budget', data: {'budget_allocation': amount});
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
