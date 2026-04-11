// lib/events/services/event_organizer_service.dart
import 'package:dio/dio.dart';
import '../models/event.dart';
import '../models/event_enums.dart';
import '../models/event_analytics.dart';
import '../models/event_rsvp.dart';
import '../models/signup_list.dart';
import '../../services/authenticated_dio.dart';

class EventOrganizerService {
  Dio get _dio => AuthenticatedDio.instance;

  // ── Analytics ──

  Future<SingleResult<EventAnalytics>> getAnalytics({required int eventId}) async {
    try {
      final response = await _dio.get('/events/$eventId/analytics');
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: EventAnalytics.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<SalesReport>> getSalesReport({required int eventId, String? dateFrom, String? dateTo}) async {
    try {
      final params = <String, dynamic>{};
      if (dateFrom != null) params['date_from'] = dateFrom;
      if (dateTo != null) params['date_to'] = dateTo;
      final response = await _dio.get('/events/$eventId/sales-report', queryParameters: params);
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: SalesReport.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Attendees ──

  Future<PaginatedResult<EventAttendee>> getAttendeeList({
    required int eventId,
    RSVPStatus? filter,
    String? search,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (filter != null) params['status'] = filter.apiValue;
      if (search != null && search.isNotEmpty) params['search'] = search;
      final response = await _dio.get('/events/$eventId/attendees', queryParameters: params);
      if (response.data['success'] == true) {
        final items = (response.data['data'] as List? ?? []).map((e) => EventAttendee.fromJson(e)).toList();
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

  // ── Team ──

  Future<SingleResult<void>> addTeamMember({required int eventId, required int userId, required TeamRole role}) async {
    try {
      final response = await _dio.post('/events/$eventId/team', data: {
        'user_id': userId,
        'role': role.apiValue,
      });
      return SingleResult(success: response.data['success'] == true, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> removeTeamMember({required int eventId, required int userId}) async {
    try {
      final response = await _dio.delete('/events/$eventId/team/$userId');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<List<TeamMember>> getTeam({required int eventId}) async {
    try {
      final response = await _dio.get('/events/$eventId/team');
      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? []).map((e) => TeamMember.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── Announcements ──

  Future<SingleResult<void>> sendAnnouncement({
    required int eventId,
    required String message,
    AnnouncementChannel channel = AnnouncementChannel.push,
  }) async {
    try {
      final response = await _dio.post('/events/$eventId/announcement', data: {
        'message': message,
        'channel': channel.apiValue,
      });
      return SingleResult(success: response.data['success'] == true, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Surveys ──

  Future<SingleResult<void>> createSurvey({required int eventId, required List<SurveyQuestion> questions}) async {
    try {
      final response = await _dio.post('/events/$eventId/survey', data: {
        'questions': questions.map((q) => q.toJson()).toList(),
      });
      return SingleResult(success: response.data['success'] == true, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<List<SurveyResponse>> getSurveyResponses({required int eventId}) async {
    try {
      final response = await _dio.get('/events/$eventId/survey/responses');
      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? []).map((e) => SurveyResponse.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── Signup Lists (Potluck) ──

  Future<SingleResult<SignupList>> createSignupList({required int eventId, required String title, required List<String> items}) async {
    try {
      final response = await _dio.post('/events/$eventId/signup-lists', data: {
        'title': title,
        'items': items,
      });
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: SignupList.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<List<SignupList>> getSignupLists({required int eventId}) async {
    try {
      final response = await _dio.get('/events/$eventId/signup-lists');
      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? []).map((e) => SignupList.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<SingleResult<void>> claimSignupItem({required int itemId}) async {
    try {
      final response = await _dio.post('/signup-items/$itemId/claim');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> unclaimSignupItem({required int itemId}) async {
    try {
      final response = await _dio.delete('/signup-items/$itemId/claim');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Payout ──

  Future<SingleResult<void>> requestPayout({required int eventId, required PaymentMethod method, String? phoneNumber}) async {
    try {
      final response = await _dio.post('/events/$eventId/payout', data: {
        'payment_method': method.apiValue,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      });
      return SingleResult(success: response.data['success'] == true, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Sessions / Agenda ──

  Future<SingleResult<void>> addSession({required int eventId, required Map<String, dynamic> sessionData}) async {
    try {
      final response = await _dio.post('/events/$eventId/sessions', data: sessionData);
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> updateSession({required int sessionId, required Map<String, dynamic> fields}) async {
    try {
      final response = await _dio.put('/sessions/$sessionId', data: fields);
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> deleteSession({required int sessionId}) async {
    try {
      final response = await _dio.delete('/sessions/$sessionId');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Speakers ──

  Future<SingleResult<void>> addSpeaker({required int eventId, required Map<String, dynamic> speakerData}) async {
    try {
      final response = await _dio.post('/events/$eventId/speakers', data: speakerData);
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Sponsors ──

  Future<SingleResult<void>> addSponsor({required int eventId, required Map<String, dynamic> sponsorData}) async {
    try {
      final response = await _dio.post('/events/$eventId/sponsors', data: sponsorData);
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
