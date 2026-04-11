// lib/events/services/events_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/events_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class EventsService {
  // ─── Browse Events ─────────────────────────────────────────────

  Future<EventListResult<Event>> getEvents({
    EventCategory? category,
    String? search,
    String? dateFrom,
    String? dateTo,
    double? latitude,
    double? longitude,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
      };
      if (category != null) params['category'] = category.name;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (dateFrom != null) params['date_from'] = dateFrom;
      if (dateTo != null) params['date_to'] = dateTo;
      if (latitude != null) params['latitude'] = '$latitude';
      if (longitude != null) params['longitude'] = '$longitude';

      final uri = Uri.parse('$_baseUrl/events')
          .replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => Event.fromJson(j))
              .toList();
          return EventListResult(success: true, items: items);
        }
      }
      return EventListResult(
        success: false,
        message: 'Imeshindwa kupakia matukio',
      );
    } catch (e) {
      return EventListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<EventResult<Event>> getEvent(int eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/events/$eventId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return EventResult(
            success: true,
            data: Event.fromJson(data['data']),
          );
        }
      }
      return EventResult(success: false, message: 'Imeshindwa kupakia tukio');
    } catch (e) {
      return EventResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Create Event ──────────────────────────────────────────────

  Future<EventResult<Event>> createEvent({
    required int userId,
    required String title,
    required String description,
    required EventCategory category,
    required String date,
    String? startTime,
    String? endTime,
    String? location,
    String? address,
    double? ticketPrice,
    bool isFree = true,
    int totalTickets = 0,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/events'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'user_id': userId,
          'title': title,
          'description': description,
          'category': category.name,
          'date': date,
          if (startTime != null) 'start_time': startTime,
          if (endTime != null) 'end_time': endTime,
          if (location != null) 'location': location,
          if (address != null) 'address': address,
          'ticket_price': ticketPrice ?? 0,
          'is_free': isFree,
          'total_tickets': totalTickets,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return EventResult(
            success: true,
            data: Event.fromJson(data['data']),
          );
        }
      }
      return EventResult(success: false, message: 'Imeshindwa kuunda tukio');
    } catch (e) {
      return EventResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Tickets ───────────────────────────────────────────────────

  Future<EventResult<EventTicket>> purchaseTicket({
    required int eventId,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/events/$eventId/tickets'),
        headers: ApiConfig.headers,
        body: jsonEncode({'user_id': userId}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return EventResult(
            success: true,
            data: EventTicket.fromJson(data['data']),
          );
        }
      }
      return EventResult(success: false, message: 'Imeshindwa kununua tiketi');
    } catch (e) {
      return EventResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<EventListResult<EventTicket>> getMyTickets({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, String>{
        'user_id': '$userId',
        'page': '$page',
        'per_page': '$perPage',
      };
      final uri = Uri.parse('$_baseUrl/events/tickets')
          .replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => EventTicket.fromJson(j))
              .toList();
          return EventListResult(success: true, items: items);
        }
      }
      return EventListResult(
        success: false,
        message: 'Imeshindwa kupakia tiketi',
      );
    } catch (e) {
      return EventListResult(success: false, message: 'Kosa: $e');
    }
  }
}
