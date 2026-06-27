import '../../calendar/models/calendar_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL personal calendar (Phase 69 — backend rev 036, verticals agent).
class GraphqlCalendarService {
  static const _eventFields = r'''
    id
    title
    date
    startTime
    endTime
    isAllDay
    color
    repeat
    reminder
    notes
    source
    createdAt
    updatedAt
  ''';

  static String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static Map<String, dynamic> _eventToLegacy(
    Map<String, dynamic> row, {
    required int userId,
  }) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'user_id': userId,
      'title': row['title'],
      'date': row['date'],
      'start_time': row['startTime'],
      'end_time': row['endTime'],
      'is_all_day': row['isAllDay'],
      'color': row['color'],
      'repeat': row['repeat'],
      'reminder': row['reminder'],
      'notes': row['notes'],
      'source': row['source'],
      'created_at': row['createdAt'],
      'updated_at': row['updatedAt'],
    };
  }

  static CalendarEvent _parseEvent(Map<String, dynamic> row, {required int userId}) {
    return CalendarEvent.fromJson(_eventToLegacy(row, userId: userId));
  }

  static Map<String, dynamic> _createInput(CalendarEvent event) {
    return {
      'title': event.title,
      'date': _formatDate(event.date),
      if (event.startTime != null) 'startTime': event.startTime,
      if (event.endTime != null) 'endTime': event.endTime,
      'isAllDay': event.isAllDay,
      if (event.color != null) 'color': event.color,
      'repeat': event.repeat.name,
      'reminder': event.reminder.name,
      if (event.notes != null) 'notes': event.notes,
      'source': event.source.name,
    };
  }

  static Map<String, dynamic> _updateInput(CalendarEvent event) {
    return {
      'title': event.title,
      'date': _formatDate(event.date),
      if (event.startTime != null) 'startTime': event.startTime,
      if (event.endTime != null) 'endTime': event.endTime,
      'isAllDay': event.isAllDay,
      if (event.color != null) 'color': event.color,
      'repeat': event.repeat.name,
      'reminder': event.reminder.name,
      if (event.notes != null) 'notes': event.notes,
      'source': event.source.name,
    };
  }

  static Future<CalendarListResult<CalendarEvent>> getEvents(
    int userId, {
    required int year,
    required int month,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CalendarEvents(\$year: Int!, \$month: Int!) {
          calendarEvents(year: \$year, month: \$month) {
            $_eventFields
          }
        }
        ''',
        variables: {'year': year, 'month': month},
        auth: true,
      );
      final rows = data['calendarEvents'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => _parseEvent(row, userId: userId))
          .toList();
      return CalendarListResult(success: true, items: items);
    } catch (_) {
      return CalendarListResult(success: false, message: 'Imeshindwa kupakia');
    }
  }

  static Future<CalendarListResult<CalendarEvent>> getEventsForDay(
    int userId, {
    required DateTime date,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CalendarEventsForDay(\$date: String!) {
          calendarEventsForDay(date: \$date) {
            $_eventFields
          }
        }
        ''',
        variables: {'date': _formatDate(date)},
        auth: true,
      );
      final rows = data['calendarEventsForDay'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => _parseEvent(row, userId: userId))
          .toList();
      return CalendarListResult(success: true, items: items);
    } catch (_) {
      return CalendarListResult(success: false, message: 'Imeshindwa kupakia');
    }
  }

  static Future<CalendarResult<CalendarEvent>> createEvent(
    CalendarEvent event,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateCalendarEvent(\$input: CreateCalendarEventInput!) {
          createCalendarEvent(input: \$input) {
            $_eventFields
          }
        }
        ''',
        variables: {'input': _createInput(event)},
        auth: true,
      );
      final row = result['createCalendarEvent'] as Map<String, dynamic>?;
      if (row == null) {
        return CalendarResult(success: false, message: 'Imeshindwa kuunda');
      }
      return CalendarResult(
        success: true,
        data: _parseEvent(row, userId: event.userId),
      );
    } catch (_) {
      return CalendarResult(success: false, message: 'Imeshindwa kuunda');
    }
  }

  static Future<CalendarResult<CalendarEvent>> updateEvent(
    int eventId,
    CalendarEvent event,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateCalendarEvent(\$eventId: ID!, \$input: UpdateCalendarEventInput!) {
          updateCalendarEvent(eventId: \$eventId, input: \$input) {
            $_eventFields
          }
        }
        ''',
        variables: {
          'eventId': eventId.toString(),
          'input': _updateInput(event),
        },
        auth: true,
      );
      final row = result['updateCalendarEvent'] as Map<String, dynamic>?;
      if (row == null) {
        return CalendarResult(success: false, message: 'Imeshindwa kubadilisha');
      }
      return CalendarResult(
        success: true,
        data: _parseEvent(row, userId: event.userId),
      );
    } catch (_) {
      return CalendarResult(success: false, message: 'Imeshindwa kubadilisha');
    }
  }

  static Future<CalendarResult<void>> deleteEvent(int eventId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteCalendarEvent(\$eventId: ID!) {
          deleteCalendarEvent(eventId: \$eventId)
        }
        ''',
        variables: {'eventId': eventId.toString()},
        auth: true,
      );
      if (result['deleteCalendarEvent'] == true) {
        return CalendarResult(success: true);
      }
      return CalendarResult(success: false, message: 'Imeshindwa kufuta');
    } catch (_) {
      return CalendarResult(success: false, message: 'Imeshindwa kufuta');
    }
  }
}
