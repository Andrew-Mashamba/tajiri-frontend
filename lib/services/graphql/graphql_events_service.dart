import '../../events/models/event.dart';
import '../../events/models/event_enums.dart';
import '../../events/models/event_rsvp.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL events feed and RSVP (Phase 92). Filtered browse stays REST-only.
class GraphqlEventsService {
  static String? _feedCursor;
  static int _feedLastPage = 1;
  static String? _feedKey;
  static String? _myCreatedCursor;
  static int _myCreatedLastPage = 1;
  static String? _myAttendingCursor;
  static int _myAttendingLastPage = 1;
  static String? _searchCursor;
  static int _searchLastPage = 1;
  static String? _searchQueryKey;
  static String? _nearMeCursor;
  static int _nearMeLastPage = 1;
  static String? _nearMeKey;

  static const _eventFields = r'''
    id
    creatorId
    title
    description
    locationName
    latitude
    longitude
    startsAt
    endsAt
    coverUrl
    status
    goingCount
    interestedCount
    viewerRsvpStatus
    createdAt
  ''';

  static Map<String, dynamic> _eventToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'name': row['title'],
      'title': row['title'],
      'description': row['description'],
      'start_date': row['startsAt'],
      'end_date': row['endsAt'],
      'location_name': row['locationName'],
      'latitude': row['latitude'],
      'longitude': row['longitude'],
      'cover_photo_url': row['coverUrl'],
      'creator_id': int.tryParse(row['creatorId']?.toString() ?? '') ?? 0,
      'going_count': row['goingCount'] ?? 0,
      'interested_count': row['interestedCount'] ?? 0,
      'user_response': row['viewerRsvpStatus'],
      'status': row['status'],
      'created_at': row['createdAt'],
    };
  }

  static Event _parseEvent(Map<String, dynamic> row) {
    return Event.fromJson(_eventToLegacy(row));
  }

  static Future<PaginatedResult<Event>> getEventsFeed({
    int page = 1,
    int perPage = 20,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final key = '${dateFrom ?? ''}|${dateTo ?? ''}';
      if (page == 1 || _feedKey != key) {
        _feedCursor = null;
        _feedLastPage = 1;
        _feedKey = key;
      } else if (page > _feedLastPage + 1) {
        return PaginatedResult(success: false, message: 'Invalid page');
      } else if (page > 1 && _feedCursor == null) {
        return PaginatedResult(
          success: true,
          items: const [],
          currentPage: page,
          lastPage: page,
          total: 0,
          perPage: perPage,
        );
      }

      final data = await TajiriGraphqlClient.instance.query(
        '''
        query EventsFeed(\$cursor: String, \$dateFrom: String, \$dateTo: String) {
          eventsFeed(cursor: \$cursor, dateFrom: \$dateFrom, dateTo: \$dateTo) {
            items { $_eventFields }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          if (_feedCursor != null) 'cursor': _feedCursor,
          if (dateFrom != null && dateFrom.isNotEmpty) 'dateFrom': dateFrom,
          if (dateTo != null && dateTo.isNotEmpty) 'dateTo': dateTo,
        },
        auth: true,
      );
      final conn = data['eventsFeed'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final items = rows.whereType<Map<String, dynamic>>().map(_parseEvent).toList();
      final hasMore = conn['hasMore'] == true;
      final nextCursor = conn['nextCursor']?.toString();
      if (hasMore && nextCursor != null) {
        _feedCursor = nextCursor;
        _feedLastPage = page + 1;
      } else {
        _feedLastPage = page;
      }

      return PaginatedResult(
        success: true,
        items: items,
        currentPage: page,
        lastPage: hasMore ? page + 1 : page,
        total: items.length,
        perPage: perPage,
      );
    } catch (e) {
      return PaginatedResult(
        success: false,
        message: 'Imeshindwa kupakia matukio: $e',
      );
    }
  }

  static Future<SingleResult<Event>> getEvent({required int eventId}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query EventDetail(\$eventId: ID!) {
          eventDetail(eventId: \$eventId) {
            $_eventFields
          }
        }
        ''',
        variables: {'eventId': eventId.toString()},
        auth: true,
      );
      final row = data['eventDetail'] as Map<String, dynamic>?;
      if (row == null) {
        return SingleResult(success: false, message: 'Event not found');
      }
      return SingleResult(success: true, data: _parseEvent(row));
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<Event>> createEvent({
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
      String startsAt = startDate;
      if (startTime != null && startTime.isNotEmpty) {
        final base = DateTime.tryParse(startDate);
        if (base != null) {
          final parts = startTime.split(':');
          if (parts.length >= 2) {
            startsAt = DateTime(
              base.year,
              base.month,
              base.day,
              int.tryParse(parts[0]) ?? 0,
              int.tryParse(parts[1]) ?? 0,
            ).toIso8601String();
          }
        }
      }

      String? coverUrl;
      if (coverPhotoPath != null &&
          (coverPhotoPath.startsWith('http://') ||
              coverPhotoPath.startsWith('https://'))) {
        coverUrl = coverPhotoPath;
      }

      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateEvent(\$input: CreateEventInput!) {
          createEvent(input: \$input) {
            $_eventFields
          }
        }
        ''',
        variables: {
          'input': {
            'title': name,
            'description': description,
            'startsAt': startsAt,
            if (endDate != null) 'endsAt': endDate,
            if (locationName != null) 'locationName': locationName,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
            if (coverUrl != null) 'coverUrl': coverUrl,
            'isPublic': privacy == EventPrivacy.public,
            'status': 'published',
          },
        },
        auth: true,
      );
      final row = data['createEvent'] as Map<String, dynamic>?;
      if (row == null) {
        return SingleResult(
          success: false,
          message: 'Imeshindwa kuunda tukio',
        );
      }
      return SingleResult(success: true, data: _parseEvent(row));
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<Event>> getUserEvents({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      if (page == 1) {
        _myCreatedCursor = null;
        _myCreatedLastPage = 1;
      } else if (page > _myCreatedLastPage + 1) {
        return PaginatedResult(success: false, message: 'Invalid page');
      } else if (page > 1 && _myCreatedCursor == null) {
        return PaginatedResult(
          success: true,
          items: const [],
          currentPage: page,
          lastPage: page,
          total: 0,
          perPage: perPage,
        );
      }

      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyCreatedEvents(\$cursor: String) {
          myCreatedEvents(cursor: \$cursor) {
            items { $_eventFields }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          if (_myCreatedCursor != null) 'cursor': _myCreatedCursor,
        },
        auth: true,
      );
      final conn = data['myCreatedEvents'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final items = rows.whereType<Map<String, dynamic>>().map(_parseEvent).toList();
      final hasMore = conn['hasMore'] == true;
      final nextCursor = conn['nextCursor']?.toString();
      if (hasMore && nextCursor != null) {
        _myCreatedCursor = nextCursor;
        _myCreatedLastPage = page + 1;
      } else {
        _myCreatedLastPage = page;
      }
      return PaginatedResult(
        success: true,
        items: items,
        currentPage: page,
        lastPage: hasMore ? page + 1 : page,
        total: items.length,
        perPage: perPage,
      );
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<Event>> getUserAttendingEvents({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      if (page == 1) {
        _myAttendingCursor = null;
        _myAttendingLastPage = 1;
      } else if (page > _myAttendingLastPage + 1) {
        return PaginatedResult(success: false, message: 'Invalid page');
      } else if (page > 1 && _myAttendingCursor == null) {
        return PaginatedResult(
          success: true,
          items: const [],
          currentPage: page,
          lastPage: page,
          total: 0,
          perPage: perPage,
        );
      }

      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyAttendingEvents(\$cursor: String) {
          myAttendingEvents(cursor: \$cursor) {
            items { $_eventFields }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          if (_myAttendingCursor != null) 'cursor': _myAttendingCursor,
        },
        auth: true,
      );
      final conn = data['myAttendingEvents'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final items = rows.whereType<Map<String, dynamic>>().map(_parseEvent).toList();
      final hasMore = conn['hasMore'] == true;
      final nextCursor = conn['nextCursor']?.toString();
      if (hasMore && nextCursor != null) {
        _myAttendingCursor = nextCursor;
        _myAttendingLastPage = page + 1;
      } else {
        _myAttendingLastPage = page;
      }
      return PaginatedResult(
        success: true,
        items: items,
        currentPage: page,
        lastPage: hasMore ? page + 1 : page,
        total: items.length,
        perPage: perPage,
      );
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<Event>> searchEvents({
    required String query,
    int page = 1,
    int perPage = 20,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final q = query.trim();
      if (q.length < 2) {
        return PaginatedResult(
          success: false,
          message: 'Search query must be at least 2 characters',
        );
      }
      final key = '${q.toLowerCase()}|${dateFrom ?? ''}|${dateTo ?? ''}';
      if (page == 1 || _searchQueryKey != key) {
        _searchCursor = null;
        _searchLastPage = 1;
        _searchQueryKey = key;
      } else if (page > _searchLastPage + 1) {
        return PaginatedResult(success: false, message: 'Invalid page');
      } else if (page > 1 && _searchCursor == null) {
        return PaginatedResult(
          success: true,
          items: const [],
          currentPage: page,
          lastPage: page,
          total: 0,
          perPage: perPage,
        );
      }

      final data = await TajiriGraphqlClient.instance.query(
        '''
        query EventsSearch(
          \$q: String!
          \$cursor: String
          \$dateFrom: String
          \$dateTo: String
        ) {
          eventsSearch(
            q: \$q
            cursor: \$cursor
            dateFrom: \$dateFrom
            dateTo: \$dateTo
          ) {
            items { $_eventFields }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          'q': q,
          if (_searchCursor != null) 'cursor': _searchCursor,
          if (dateFrom != null && dateFrom.isNotEmpty) 'dateFrom': dateFrom,
          if (dateTo != null && dateTo.isNotEmpty) 'dateTo': dateTo,
        },
        auth: true,
      );
      final conn = data['eventsSearch'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final items = rows.whereType<Map<String, dynamic>>().map(_parseEvent).toList();
      final hasMore = conn['hasMore'] == true;
      final nextCursor = conn['nextCursor']?.toString();
      if (hasMore && nextCursor != null) {
        _searchCursor = nextCursor;
        _searchLastPage = page + 1;
      } else {
        _searchLastPage = page;
      }
      return PaginatedResult(
        success: true,
        items: items,
        currentPage: page,
        lastPage: hasMore ? page + 1 : page,
        total: items.length,
        perPage: perPage,
      );
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<Event>> getEventsNearMe({
    required double lat,
    required double lng,
    double radiusKm = 50,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final key = '$lat|$lng|$radiusKm';
      if (page == 1) {
        _nearMeCursor = null;
        _nearMeLastPage = 1;
        _nearMeKey = key;
      } else if (_nearMeKey != key) {
        return PaginatedResult(success: false, message: 'Location changed — restart from page 1');
      } else if (page > _nearMeLastPage + 1) {
        return PaginatedResult(success: false, message: 'Invalid page');
      } else if (page > 1 && _nearMeCursor == null) {
        return PaginatedResult(
          success: true,
          items: const [],
          currentPage: page,
          lastPage: page,
          total: 0,
          perPage: perPage,
        );
      }

      final data = await TajiriGraphqlClient.instance.query(
        '''
        query EventsNearMe(
          \$latitude: Float!
          \$longitude: Float!
          \$radiusKm: Float!
          \$cursor: String
        ) {
          eventsNearMe(
            latitude: \$latitude
            longitude: \$longitude
            radiusKm: \$radiusKm
            cursor: \$cursor
          ) {
            items { $_eventFields }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          'latitude': lat,
          'longitude': lng,
          'radiusKm': radiusKm,
          if (_nearMeCursor != null) 'cursor': _nearMeCursor,
        },
        auth: true,
      );
      final conn = data['eventsNearMe'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final items = rows.whereType<Map<String, dynamic>>().map(_parseEvent).toList();
      final hasMore = conn['hasMore'] == true;
      final nextCursor = conn['nextCursor']?.toString();
      if (hasMore && nextCursor != null) {
        _nearMeCursor = nextCursor;
        _nearMeLastPage = page + 1;
      } else {
        _nearMeLastPage = page;
      }
      return PaginatedResult(
        success: true,
        items: items,
        currentPage: page,
        lastPage: hasMore ? page + 1 : page,
        total: items.length,
        perPage: perPage,
      );
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<EventRSVP>> respondToEvent({
    required int eventId,
    required RSVPStatus status,
    int guestCount = 0,
    List<String>? guestNames,
  }) async {
    try {
      if (status == RSVPStatus.notGoing) {
        return cancelRsvp(eventId: eventId);
      }
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RsvpEvent(\$eventId: ID!, \$status: String!) {
          rsvpEvent(eventId: \$eventId, status: \$status) {
            $_eventFields
          }
        }
        ''',
        variables: {
          'eventId': eventId.toString(),
          'status': status.apiValue,
        },
        auth: true,
      );
      final row = data['rsvpEvent'] as Map<String, dynamic>?;
      if (row == null) {
        return SingleResult(success: false, message: 'RSVP failed');
      }
      return SingleResult(
        success: true,
        data: EventRSVP(
          id: 0,
          eventId: eventId,
          userId: 0,
          status: status,
          guestCount: guestCount,
          guestNames: guestNames ?? const [],
          respondedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<EventRSVP>> cancelRsvp({
    required int eventId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CancelRsvpEvent(\$eventId: ID!) {
          cancelRsvpEvent(eventId: \$eventId) {
            id
            viewerRsvpStatus
          }
        }
        ''',
        variables: {'eventId': eventId.toString()},
        auth: true,
      );
      final row = data['cancelRsvpEvent'] as Map<String, dynamic>?;
      if (row == null) {
        return SingleResult(success: false, message: 'Cancel RSVP failed');
      }
      return SingleResult(
        success: true,
        data: EventRSVP(
          id: 0,
          eventId: eventId,
          userId: 0,
          status: RSVPStatus.notGoing,
          guestCount: 0,
          guestNames: const [],
          respondedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
