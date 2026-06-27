// lib/calendar/services/calendar_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/http_retry.dart';
import '../../config/api_config.dart';
import '../../reminders/models/reminder_models.dart' show ReminderItem;
import '../../services/graphql/graphql_calendar_service.dart';
import '../models/calendar_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class CalendarService {
  // ─── Get events for a month ────────────────────────────────────

  Future<CalendarListResult<CalendarEvent>> getEvents(
    int userId, {
    required int year,
    required int month,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlCalendarService.getEvents(
        userId,
        year: year,
        month: month,
      );
    }
    try {
      final uri = Uri.parse('$_baseUrl/calendar/events').replace(
        queryParameters: {
          'user_id': userId.toString(),
          'year': year.toString(),
          'month': month.toString(),
        },
      );
      final response = await httpGetWithRetry(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => CalendarEvent.fromJson(j))
              .toList();
          return CalendarListResult(success: true, items: items);
        }
      }
      return CalendarListResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return CalendarListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Get events for a specific day ─────────────────────────────

  Future<CalendarListResult<CalendarEvent>> getEventsForDay(
    int userId, {
    required DateTime date,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlCalendarService.getEventsForDay(userId, date: date);
    }
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final uri = Uri.parse('$_baseUrl/calendar/events/day').replace(
        queryParameters: {
          'user_id': userId.toString(),
          'date': dateStr,
        },
      );
      final response = await httpGetWithRetry(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => CalendarEvent.fromJson(j))
              .toList();
          return CalendarListResult(success: true, items: items);
        }
      }
      return CalendarListResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return CalendarListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Create event ──────────────────────────────────────────────

  Future<CalendarResult<CalendarEvent>> createEvent(
      CalendarEvent event) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlCalendarService.createEvent(event);
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calendar/events'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(event.toJson()),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return CalendarResult(
            success: true, data: CalendarEvent.fromJson(data['data']));
      }
      return CalendarResult(
          success: false, message: data['message'] ?? 'Imeshindwa kuunda');
    } catch (e) {
      return CalendarResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Update event ──────────────────────────────────────────────

  Future<CalendarResult<CalendarEvent>> updateEvent(
      int eventId, CalendarEvent event) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlCalendarService.updateEvent(eventId, event);
    }
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/calendar/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(event.toJson()),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return CalendarResult(
            success: true, data: CalendarEvent.fromJson(data['data']));
      }
      return CalendarResult(
          success: false, message: data['message'] ?? 'Imeshindwa kubadilisha');
    } catch (e) {
      return CalendarResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Delete event ──────────────────────────────────────────────

  Future<CalendarResult<void>> deleteEvent(int eventId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlCalendarService.deleteEvent(eventId);
    }
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/calendar/events/$eventId'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return CalendarResult(success: true);
      }
      return CalendarResult(
          success: false, message: data['message'] ?? 'Imeshindwa kufuta');
    } catch (e) {
      return CalendarResult(success: false, message: 'Kosa: $e');
    }
  }

  // STUB — calendar reminders aggregator. Returns empty until backend wires
  // /calendar/upcoming-with-reminders.
  Future<List<ReminderItem>> getUpcomingWithReminders({
    required int userId,
    required String token,
    bool strict = false,
  }) async => const [];
}
