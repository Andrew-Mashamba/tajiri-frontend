import 'tajiri_graphql_client.dart';

/// GraphQL flywheel event batch ingest (Phase 41).
class GraphqlTrackingService {
  static Future<bool> postEvents(List<Map<String, dynamic>> events) async {
    if (events.isEmpty) return true;
    try {
      final payload = events.map((event) {
        return {
          'eventType': event['event_type'],
          if (event['post_id'] != null) 'postId': event['post_id'].toString(),
          if (event['creator_id'] != null)
            'creatorId': event['creator_id'].toString(),
          'timestamp': event['timestamp'],
          'durationMs': event['duration_ms'] ?? 0,
          'sessionId': event['session_id'],
          if (event['metadata'] != null) 'metadata': event['metadata'],
        };
      }).toList();

      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation TrackEvents(\$input: TrackEventsInput!) {
          trackEvents(input: \$input) {
            accepted
            rejected
          }
        }
        ''',
        variables: {'input': {'events': payload}},
        auth: true,
      );
      final row = result['trackEvents'] as Map<String, dynamic>?;
      if (row == null) return false;
      return (row['accepted'] as num? ?? 0) > 0 || (row['rejected'] as num? ?? 0) >= 0;
    } catch (_) {
      return false;
    }
  }
}
