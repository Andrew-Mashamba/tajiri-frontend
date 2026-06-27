import '../../neighbourhood_watch/models/neighbourhood_watch_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL neighbourhood watch (Phase 70 — backend rev 033).
class GraphqlNeighbourhoodService {
  static const _alertFields = r'''
    id
    userId
    userName
    type
    title
    description
    location
    lat
    lng
    urgency
    confirmations
    isActive
    viewerConfirmed
    createdAt
  ''';

  static const _patrolFields = r'''
    id
    zone
    dayOfWeek
    startTime
    endTime
    volunteers
    isActive
    viewerJoined
  ''';

  static final Map<String, Map<int, String?>> _alertCursors = {};

  static String _alertsKey(String? type) => 'alerts:${type ?? 'all'}';

  static Map<String, dynamic> _alertToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'user_id': int.tryParse(row['userId']?.toString() ?? '') ?? 0,
      'user_name': row['userName'],
      'type': row['type'],
      'title': row['title'],
      'description': row['description'],
      'location': row['location'],
      'lat': row['lat'],
      'lng': row['lng'],
      'urgency': row['urgency'],
      'confirmations': row['confirmations'],
      'is_active': row['isActive'],
      'created_at': row['createdAt'],
    };
  }

  static Map<String, dynamic> _patrolToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'zone': row['zone'],
      'day_of_week': row['dayOfWeek'],
      'start_time': row['startTime'],
      'end_time': row['endTime'],
      'volunteers': row['volunteers'] ?? [],
      'is_active': row['isActive'],
    };
  }

  static Future<PaginatedResult<CommunityAlert>> getAlerts({
    int page = 1,
    String? type,
  }) async {
    try {
      final key = _alertsKey(type);
      if (page == 1) {
        _alertCursors[key] = {};
      }
      final cursor = page > 1 ? _alertCursors[key]?[page] : null;
      if (page > 1 && cursor == null) {
        return PaginatedResult(
          success: true,
          items: const [],
          currentPage: page,
          lastPage: page - 1,
        );
      }

      final data = await TajiriGraphqlClient.instance.query(
        '''
        query NeighbourhoodAlerts(\$cursor: String, \$type: String) {
          neighbourhoodAlerts(cursor: \$cursor, type: \$type) {
            items {
              $_alertFields
            }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          if (cursor != null) 'cursor': cursor,
          if (type != null) 'type': type,
        },
        auth: true,
      );
      final conn = data['neighbourhoodAlerts'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => CommunityAlert.fromJson(_alertToLegacy(row)))
          .toList();
      final hasMore = conn['hasMore'] == true;
      final nextCursor = conn['nextCursor']?.toString();
      _alertCursors.putIfAbsent(key, () => {});
      if (hasMore && nextCursor != null) {
        _alertCursors[key]![page + 1] = nextCursor;
      }
      return PaginatedResult(
        success: true,
        items: items,
        currentPage: page,
        lastPage: hasMore ? page + 1 : page,
      );
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<CommunityAlert>> submitAlert(
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SubmitNeighbourhoodAlert(\$input: SubmitAlertInput!) {
          submitNeighbourhoodAlert(input: \$input) {
            $_alertFields
          }
        }
        ''',
        variables: {
          'input': {
            'type': body['type'],
            'title': body['title'],
            'description': body['description'],
            'urgency': body['urgency'] ?? 'medium',
            if (body['location'] != null &&
                body['location'].toString().trim().isNotEmpty)
              'location': body['location'],
            if (body['lat'] != null) 'lat': body['lat'],
            if (body['lng'] != null) 'lng': body['lng'],
          },
        },
        auth: true,
      );
      final row = result['submitNeighbourhoodAlert'] as Map<String, dynamic>?;
      if (row == null) {
        return SingleResult(success: false, message: 'Imeshindwa kuwasilisha');
      }
      return SingleResult(
        success: true,
        data: CommunityAlert.fromJson(_alertToLegacy(row)),
      );
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> confirmAlert(int alertId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ConfirmNeighbourhoodAlert(\$alertId: ID!) {
          confirmNeighbourhoodAlert(alertId: \$alertId) {
            id
          }
        }
        ''',
        variables: {'alertId': alertId.toString()},
        auth: true,
      );
      return SingleResult(
        success: result['confirmNeighbourhoodAlert'] != null,
      );
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<PatrolSchedule>> getPatrols() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query NeighbourhoodPatrols {
          neighbourhoodPatrols {
            $_patrolFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['neighbourhoodPatrols'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => PatrolSchedule.fromJson(_patrolToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> joinPatrol(int patrolId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation JoinNeighbourhoodPatrol(\$patrolId: ID!) {
          joinNeighbourhoodPatrol(patrolId: \$patrolId) {
            id
          }
        }
        ''',
        variables: {'patrolId': patrolId.toString()},
        auth: true,
      );
      return SingleResult(
        success: result['joinNeighbourhoodPatrol'] != null,
      );
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
