import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/event_models.dart';
import '../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

class EventService {
  /// Get events for a group (in-group events/RSVPs). Uses group_id filter when API supports it.
  Future<EventListResult> getEventsByGroup({
    required int groupId,
    int? currentUserId,
    int page = 1,
    int perPage = 20,
    String type = 'upcoming',
  }) async {
    try {
      String url = '$_baseUrl/events?page=$page&per_page=$perPage&type=$type&group_id=$groupId';
      if (currentUserId != null) url += '&current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final raw = data['data'] as List? ?? [];
          final events = raw.map((e) => EventModel.fromJson(e)).toList();
          return EventListResult(success: true, events: events);
        }
      }
      return EventListResult(success: false, message: 'Failed to load group events');
    } catch (e) {
      return EventListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get list of events
  Future<EventListResult> getEvents({
    int page = 1,
    int perPage = 20,
    String type = 'upcoming', // upcoming, past, all
    String? category,
    int? currentUserId,
  }) async {
    try {
      String url = '$_baseUrl/events?page=$page&per_page=$perPage&type=$type';
      if (category != null) url += '&category=$category';
      if (currentUserId != null) url += '&current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final events = (data['data'] as List)
              .map((e) => EventModel.fromJson(e))
              .toList();
          return EventListResult(success: true, events: events);
        }
      }
      return EventListResult(success: false, message: 'Failed to load events');
    } catch (e) {
      return EventListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get event categories
  Future<List<EventCategory>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/events/categories'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((c) => EventCategory.fromJson(c))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get user's events
  Future<EventListResult> getUserEvents(int userId, {String filter = 'going'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/events/user?user_id=$userId&filter=$filter'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final events = (data['data'] as List)
              .map((e) => EventModel.fromJson(e))
              .toList();
          return EventListResult(success: true, events: events);
        }
      }
      return EventListResult(success: false, message: 'Failed to load events');
    } catch (e) {
      return EventListResult(success: false, message: 'Error: $e');
    }
  }

  /// Create a new event
  Future<EventResult> createEvent({
    required int creatorId,
    required String name,
    required DateTime startDate,
    String? description,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    bool isAllDay = false,
    String? locationName,
    String? locationAddress,
    double? latitude,
    double? longitude,
    bool isOnline = false,
    String? onlineLink,
    String privacy = 'public',
    String? category,
    int? groupId,
    int? pageId,
    double? ticketPrice,
    String? ticketCurrency,
    String? ticketLink,
    File? coverPhoto,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/events'));
      request.fields['creator_id'] = creatorId.toString();
      request.fields['name'] = name;
      request.fields['start_date'] = startDate.toIso8601String().split('T')[0];
      if (description != null) request.fields['description'] = description;
      if (endDate != null) request.fields['end_date'] = endDate.toIso8601String().split('T')[0];
      if (startTime != null) request.fields['start_time'] = startTime;
      if (endTime != null) request.fields['end_time'] = endTime;
      request.fields['is_all_day'] = isAllDay.toString();
      if (locationName != null) request.fields['location_name'] = locationName;
      if (locationAddress != null) request.fields['location_address'] = locationAddress;
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();
      request.fields['is_online'] = isOnline.toString();
      if (onlineLink != null) request.fields['online_link'] = onlineLink;
      request.fields['privacy'] = privacy;
      if (category != null) request.fields['category'] = category;
      if (groupId != null) request.fields['group_id'] = groupId.toString();
      if (pageId != null) request.fields['page_id'] = pageId.toString();
      if (ticketPrice != null) request.fields['ticket_price'] = ticketPrice.toString();
      if (ticketCurrency != null) request.fields['ticket_currency'] = ticketCurrency;
      if (ticketLink != null) request.fields['ticket_link'] = ticketLink;

      if (coverPhoto != null) {
        request.files.add(await http.MultipartFile.fromPath('cover_photo', coverPhoto.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return EventResult(
          success: true,
          event: EventModel.fromJson(data['data']),
          message: data['message'],
        );
      }
      return EventResult(success: false, message: data['message'] ?? 'Failed to create event');
    } catch (e) {
      return EventResult(success: false, message: 'Error: $e');
    }
  }

  /// Get a single event
  Future<EventResult> getEvent(String identifier, {int? currentUserId}) async {
    try {
      String url = '$_baseUrl/events/$identifier';
      if (currentUserId != null) url += '?current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return EventResult(success: true, event: EventModel.fromJson(data['data']));
        }
      }
      return EventResult(success: false, message: 'Event not found');
    } catch (e) {
      return EventResult(success: false, message: 'Error: $e');
    }
  }

  /// Respond to an event (going, interested, not_going)
  Future<ResponseResult> respondToEvent(int eventId, int userId, String response) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/events/$eventId/respond'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'response': response,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        return ResponseResult(
          success: true,
          goingCount: data['data']?['going_count'],
          interestedCount: data['data']?['interested_count'],
          notGoingCount: data['data']?['not_going_count'],
        );
      }
      return ResponseResult(success: false, message: data['message']);
    } catch (e) {
      return ResponseResult(success: false, message: 'Error: $e');
    }
  }

  /// Remove response to an event
  Future<bool> removeResponse(int eventId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/events/$eventId/respond'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get event attendees
  Future<AttendeeListResult> getAttendees(int eventId, {String type = 'going'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/events/$eventId/attendees?type=$type'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final attendees = (data['data'] as List)
              .map((a) => EventCreator.fromJson(a))
              .toList();
          return AttendeeListResult(success: true, attendees: attendees);
        }
      }
      return AttendeeListResult(success: false, message: 'Failed to load attendees');
    } catch (e) {
      return AttendeeListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get nearby events
  Future<EventListResult> getNearbyEvents(double latitude, double longitude, {double radius = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/events/nearby?latitude=$latitude&longitude=$longitude&radius=$radius'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final events = (data['data'] as List)
              .map((e) => EventModel.fromJson(e))
              .toList();
          return EventListResult(success: true, events: events);
        }
      }
      return EventListResult(success: false, message: 'Failed to load events');
    } catch (e) {
      return EventListResult(success: false, message: 'Error: $e');
    }
  }

  /// Search events
  Future<EventListResult> searchEvents(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/events/search?q=$query'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final events = (data['data'] as List)
              .map((e) => EventModel.fromJson(e))
              .toList();
          return EventListResult(success: true, events: events);
        }
      }
      return EventListResult(success: false, message: 'Search failed');
    } catch (e) {
      return EventListResult(success: false, message: 'Error: $e');
    }
  }
}

// Result classes
class EventListResult {
  final bool success;
  final List<EventModel> events;
  final String? message;

  EventListResult({required this.success, this.events = const [], this.message});
}

class EventResult {
  final bool success;
  final EventModel? event;
  final String? message;

  EventResult({required this.success, this.event, this.message});
}

class ResponseResult {
  final bool success;
  final int? goingCount;
  final int? interestedCount;
  final int? notGoingCount;
  final String? message;

  ResponseResult({
    required this.success,
    this.goingCount,
    this.interestedCount,
    this.notGoingCount,
    this.message,
  });
}

class AttendeeListResult {
  final bool success;
  final List<EventCreator> attendees;
  final String? message;

  AttendeeListResult({required this.success, this.attendees = const [], this.message});
}
