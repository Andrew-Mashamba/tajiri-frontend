// lib/events/services/event_service.dart
import 'package:dio/dio.dart';
import '../models/event.dart';
import '../models/event_enums.dart';
import '../models/event_rsvp.dart';
import '../../services/authenticated_dio.dart';

class EventService {
  Dio get _dio => AuthenticatedDio.instance;

  // ── Discovery & Feed ──

  Future<PaginatedResult<Event>> getEventsFeed({int page = 1, int perPage = 20}) async {
    try {
      final response = await _dio.get('/events/feed', queryParameters: {
        'page': page,
        'per_page': perPage,
      });
      return _parsePaginatedEvents(response.data);
    } catch (e) {
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia matukio: $e');
    }
  }

  Future<PaginatedResult<Event>> getEventsNearMe({
    required double lat,
    required double lng,
    double radiusKm = 50,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get('/events/nearby', queryParameters: {
        'latitude': lat,
        'longitude': lng,
        'radius': radiusKm,
        'page': page,
      });
      return _parsePaginatedEvents(response.data);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<PaginatedResult<Event>> browseEvents({
    EventCategory? category,
    String? search,
    String? dateFrom,
    String? dateTo,
    EventPriceFilter? price,
    EventSortBy? sort,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (category != null) params['category'] = category.apiValue;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (dateFrom != null) params['date_from'] = dateFrom;
      if (dateTo != null) params['date_to'] = dateTo;
      if (price != null && price != EventPriceFilter.all) params['price'] = price.name;
      if (sort != null) params['sort'] = sort.apiValue;

      final response = await _dio.get('/events', queryParameters: params);
      return _parsePaginatedEvents(response.data);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<PaginatedResult<Event>> getTrendingEvents({int page = 1}) async {
    try {
      final response = await _dio.get('/events/trending', queryParameters: {'page': page});
      return _parsePaginatedEvents(response.data);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<PaginatedResult<Event>> getGroupEvents({required int groupId, int page = 1}) async {
    try {
      final response = await _dio.get('/events', queryParameters: {
        'group_id': groupId,
        'page': page,
      });
      return _parsePaginatedEvents(response.data);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<PaginatedResult<Event>> getUserEvents({required int userId, int page = 1}) async {
    try {
      final response = await _dio.get('/events', queryParameters: {
        'creator_id': userId,
        'page': page,
      });
      return _parsePaginatedEvents(response.data);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<PaginatedResult<Event>> getUserAttendingEvents({required int userId, int page = 1}) async {
    try {
      final response = await _dio.get('/events', queryParameters: {
        'attending_user_id': userId,
        'page': page,
      });
      return _parsePaginatedEvents(response.data);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<List<Event>> getHappeningNow() async {
    try {
      final response = await _dio.get('/events/happening-now');
      if (response.data['success'] == true) {
        final items = response.data['data'] as List? ?? [];
        return items.map((e) => Event.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Event>> getFriendsEvents() async {
    try {
      final response = await _dio.get('/events/friends');
      if (response.data['success'] == true) {
        final items = response.data['data'] as List? ?? [];
        return items.map((e) => Event.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Event>> getSimilarEvents({required int eventId}) async {
    try {
      final response = await _dio.get('/events/$eventId/similar');
      if (response.data['success'] == true) {
        final items = response.data['data'] as List? ?? [];
        return items.map((e) => Event.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<PaginatedResult<Event>> getSavedEvents({int page = 1}) async {
    try {
      final response = await _dio.get('/events/saved', queryParameters: {'page': page});
      return _parsePaginatedEvents(response.data);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  // ── CRUD ──

  Future<SingleResult<Event>> getEvent({required int eventId}) async {
    try {
      final response = await _dio.get('/events/$eventId');
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: Event.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<Event>> createEvent({
    required String name,
    required String description,
    required EventCategory category,
    required EventType type,
    required String startDate,
    String? endDate,
    String? startTime,
    String? endTime,
    String timezone = 'Africa/Dar_es_Salaam',
    bool isAllDay = false,
    EventPrivacy privacy = EventPrivacy.public,
    String? locationName,
    String? locationAddress,
    double? latitude,
    double? longitude,
    int? regionId,
    int? districtId,
    bool isOnline = false,
    String? onlineLink,
    String? onlinePlatform,
    bool isFree = true,
    String ticketCurrency = 'TZS',
    bool hasWaitlist = false,
    String? refundPolicy,
    int? groupId,
    List<int>? coHostIds,
    List<String>? tags,
    String? coverPhotoPath,
    List<String>? galleryPaths,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'description': description,
        'category': category.apiValue,
        'type': type.apiValue,
        'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        'timezone': timezone,
        'is_all_day': isAllDay ? 1 : 0,
        'privacy': privacy.apiValue,
        if (locationName != null) 'location_name': locationName,
        if (locationAddress != null) 'location_address': locationAddress,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (regionId != null) 'region_id': regionId,
        if (districtId != null) 'district_id': districtId,
        'is_online': isOnline ? 1 : 0,
        if (onlineLink != null) 'online_link': onlineLink,
        if (onlinePlatform != null) 'online_platform': onlinePlatform,
        'is_free': isFree ? 1 : 0,
        'ticket_currency': ticketCurrency,
        'has_waitlist': hasWaitlist ? 1 : 0,
        if (refundPolicy != null) 'refund_policy': refundPolicy,
        if (groupId != null) 'group_id': groupId,
        if (coHostIds != null) 'co_host_ids': coHostIds,
        if (tags != null) 'tags': tags,
      });

      if (coverPhotoPath != null) {
        formData.files.add(MapEntry('cover', await MultipartFile.fromFile(coverPhotoPath, filename: 'cover.jpg')));
      }
      if (galleryPaths != null) {
        for (int i = 0; i < galleryPaths.length; i++) {
          formData.files.add(MapEntry('gallery[$i]', await MultipartFile.fromFile(galleryPaths[i])));
        }
      }

      final response = await _dio.post('/events', data: formData);
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: Event.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString() ?? 'Imeshindwa kuunda tukio');
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<Event>> updateEvent({
    required int eventId,
    Map<String, dynamic>? fields,
    String? coverPhotoPath,
  }) async {
    try {
      final Response response;
      if (coverPhotoPath != null) {
        final formData = FormData.fromMap({
          ...?fields,
          '_method': 'PUT',
          'cover': await MultipartFile.fromFile(coverPhotoPath, filename: 'cover.jpg'),
        });
        response = await _dio.post('/events/$eventId', data: formData);
      } else {
        response = await _dio.put('/events/$eventId', data: fields);
      }
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: Event.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> deleteEvent({required int eventId}) async {
    try {
      final response = await _dio.delete('/events/$eventId');
      return SingleResult(success: response.data['success'] == true, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<Event>> duplicateEvent({required int eventId}) async {
    try {
      final response = await _dio.post('/events/$eventId/duplicate');
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: Event.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<Event>> publishEvent({required int eventId}) async {
    try {
      final response = await _dio.post('/events/$eventId/publish');
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: Event.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<Event>> cancelEvent({required int eventId, String? reason}) async {
    try {
      final response = await _dio.post('/events/$eventId/cancel', data: {
        if (reason != null) 'reason': reason,
      });
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: Event.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── RSVP ──

  Future<SingleResult<EventRSVP>> respondToEvent({
    required int eventId,
    required RSVPStatus status,
    int guestCount = 0,
    List<String>? guestNames,
  }) async {
    try {
      final response = await _dio.post('/events/$eventId/rsvp', data: {
        'status': status.apiValue,
        'guest_count': guestCount,
        if (guestNames != null) 'guest_names': guestNames,
      });
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: EventRSVP.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<PaginatedResult<EventAttendee>> getAttendees({
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
        final items = (response.data['data'] as List? ?? [])
            .map((e) => EventAttendee.fromJson(e))
            .toList();
        final meta = response.data['meta'] as Map<String, dynamic>?;
        return PaginatedResult(
          success: true,
          items: items,
          currentPage: meta?['current_page'] ?? page,
          lastPage: meta?['last_page'] ?? 1,
          total: meta?['total'] ?? items.length,
          perPage: meta?['per_page'] ?? 20,
        );
      }
      return PaginatedResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<List<EventAttendee>> getFriendsAttending({required int eventId}) async {
    try {
      final response = await _dio.get('/events/$eventId/friends-attending');
      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? [])
            .map((e) => EventAttendee.fromJson(e))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── Social ──

  Future<SingleResult<void>> saveEvent({required int eventId}) async {
    try {
      final response = await _dio.post('/events/$eventId/save');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> unsaveEvent({required int eventId}) async {
    try {
      final response = await _dio.delete('/events/$eventId/save');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> shareEvent({required int eventId, required ShareTarget target}) async {
    try {
      final response = await _dio.post('/events/$eventId/share', data: {'target': target.name});
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> reportEvent({required int eventId, required String reason}) async {
    try {
      final response = await _dio.post('/events/$eventId/report', data: {'reason': reason});
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Invite ──

  Future<SingleResult<void>> inviteFriends({required int eventId, required List<int> userIds}) async {
    try {
      final response = await _dio.post('/events/$eventId/invite', data: {'user_ids': userIds});
      return SingleResult(success: response.data['success'] == true, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> inviteByPhone({required int eventId, required List<String> phoneNumbers}) async {
    try {
      final response = await _dio.post('/events/$eventId/invite-sms', data: {'phone_numbers': phoneNumbers});
      return SingleResult(success: response.data['success'] == true, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<String?> getShareLink({required int eventId}) async {
    try {
      final response = await _dio.get('/events/$eventId/share-link');
      if (response.data['success'] == true) {
        return response.data['data']?['url']?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Co-Hosting ──

  Future<SingleResult<void>> addCoHost({required int eventId, required int userId}) async {
    try {
      final response = await _dio.post('/events/$eventId/co-hosts', data: {'user_id': userId});
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> removeCoHost({required int eventId, required int userId}) async {
    try {
      final response = await _dio.delete('/events/$eventId/co-hosts/$userId');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Helpers ──

  PaginatedResult<Event> _parsePaginatedEvents(Map<String, dynamic> json) {
    if (json['success'] == true) {
      final data = json['data'];
      List rawItems;
      if (data is List) {
        rawItems = data;
      } else if (data is Map && data['data'] is List) {
        rawItems = data['data'];
      } else {
        rawItems = [];
      }
      final items = rawItems.map((e) => Event.fromJson(e)).toList();
      final meta = json['meta'] as Map<String, dynamic>? ?? (data is Map ? data['meta'] as Map<String, dynamic>? : null);
      return PaginatedResult(
        success: true,
        items: items,
        currentPage: meta?['current_page'] ?? 1,
        lastPage: meta?['last_page'] ?? 1,
        total: meta?['total'] ?? items.length,
        perPage: meta?['per_page'] ?? 20,
      );
    }
    return PaginatedResult(success: false, message: json['message']?.toString());
  }
}
