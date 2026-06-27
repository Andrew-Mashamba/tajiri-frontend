import '../../sala/models/sala_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL prayer requests & journal (Phase 71 — backend rev 204).
class GraphqlSalaService {
  static const _requestFields = r'''
    id
    userId
    title
    description
    category
    urgency
    status
    prayerCount
    answerTestimony
    scriptureRef
    isShared
    createdAt
  ''';

  static const _journalFields = r'''
    id
    content
    scriptureRef
    reflection
    date
  ''';

  static const _statsFields = r'''
    totalRequests
    answeredCount
    streak
    prayingForOthers
  ''';

  static final Map<String, Map<int, String?>> _cursors = {};

  static String _key(String prefix, {String? status, String? category}) =>
      '$prefix:${status ?? ''}:${category ?? ''}';

  static Map<String, dynamic> _requestToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'user_id': int.tryParse(row['userId']?.toString() ?? '') ?? 0,
      'title': row['title'],
      'description': row['description'],
      'category': row['category'],
      'urgency': row['urgency'],
      'status': row['status'],
      'prayer_count': row['prayerCount'],
      'answer_testimony': row['answerTestimony'],
      'scripture_ref': row['scriptureRef'],
      'is_shared': row['isShared'],
      'created_at': row['createdAt'],
    };
  }

  static Map<String, dynamic> _journalToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'content': row['content'],
      'scripture_ref': row['scriptureRef'],
      'reflection': row['reflection'],
      'date': row['date'],
    };
  }

  static Map<String, dynamic> _statsToLegacy(Map<String, dynamic> row) {
    return {
      'total_requests': row['totalRequests'],
      'answered_count': row['answeredCount'],
      'streak': row['streak'],
      'praying_for_others': row['prayingForOthers'],
    };
  }

  static PaginatedResult<PrayerRequest> _parseRequestConnection(
    Map<String, dynamic>? conn, {
    required int page,
  }) {
    if (conn == null) {
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia');
    }
    final rows = conn['items'] as List<dynamic>? ?? [];
    final items = rows
        .whereType<Map<String, dynamic>>()
        .map((row) => PrayerRequest.fromJson(_requestToLegacy(row)))
        .toList();
    final hasMore = conn['hasMore'] == true;
    return PaginatedResult(
      success: true,
      items: items,
      currentPage: page,
      lastPage: hasMore ? page + 1 : page,
    );
  }

  static Future<PaginatedResult<PrayerRequest>> getRequests({
    String? status,
    String? category,
    int page = 1,
  }) async {
    try {
      final key = _key('requests', status: status, category: category);
      if (page == 1) {
        _cursors[key] = {};
      }
      final cursor = page > 1 ? _cursors[key]?[page] : null;
      if (page > 1 && cursor == null) {
        return PaginatedResult(success: true, items: const [], currentPage: page, lastPage: page - 1);
      }

      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyPrayerRequests(\$status: String, \$category: String, \$cursor: String) {
          myPrayerRequests(status: \$status, category: \$category, cursor: \$cursor) {
            items {
              $_requestFields
            }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          if (status != null) 'status': status,
          if (category != null) 'category': category,
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final conn = data['myPrayerRequests'] as Map<String, dynamic>?;
      final hasMore = conn?['hasMore'] == true;
      final nextCursor = conn?['nextCursor']?.toString();
      _cursors.putIfAbsent(key, () => {});
      if (hasMore && nextCursor != null) {
        _cursors[key]![page + 1] = nextCursor;
      }
      return _parseRequestConnection(conn, page: page);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<PrayerRequest>> createRequest(
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreatePrayerRequest(\$input: CreatePrayerRequestInput!) {
          createPrayerRequest(input: \$input) {
            $_requestFields
          }
        }
        ''',
        variables: {
          'input': {
            'title': body['title'],
            if (body['description'] != null &&
                body['description'].toString().trim().isNotEmpty)
              'description': body['description'],
            'category': body['category'] ?? 'personal',
            'urgency': body['urgency'] ?? 'medium',
            if (body['scripture_ref'] != null &&
                body['scripture_ref'].toString().trim().isNotEmpty)
              'scriptureRef': body['scripture_ref'],
            'isShared': body['is_shared'] == true,
          },
        },
        auth: true,
      );
      final row = result['createPrayerRequest'] as Map<String, dynamic>?;
      if (row == null) {
        return SingleResult(success: false, message: 'Imeshindwa kuunda');
      }
      return SingleResult(
        success: true,
        data: PrayerRequest.fromJson(_requestToLegacy(row)),
      );
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> markAnswered(
    int id,
    String testimony,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation MarkPrayerAnswered(\$requestId: ID!, \$testimony: String!) {
          markPrayerAnswered(requestId: \$requestId, testimony: \$testimony) {
            id
          }
        }
        ''',
        variables: {
          'requestId': id.toString(),
          'testimony': testimony,
        },
        auth: true,
      );
      return SingleResult(success: result['markPrayerAnswered'] != null);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> prayForRequest(int id) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation PrayForRequest(\$requestId: ID!) {
          prayForRequest(requestId: \$requestId) {
            id
          }
        }
        ''',
        variables: {'requestId': id.toString()},
        auth: true,
      );
      return SingleResult(success: result['prayForRequest'] != null);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<PrayerRequest>> getSharedFeed({
    int page = 1,
  }) async {
    try {
      const key = 'feed';
      if (page == 1) {
        _cursors[key] = {};
      }
      final cursor = page > 1 ? _cursors[key]?[page] : null;
      if (page > 1 && cursor == null) {
        return PaginatedResult(success: true, items: const []);
      }

      final data = await TajiriGraphqlClient.instance.query(
        '''
        query PrayerFeed(\$cursor: String) {
          prayerFeed(cursor: \$cursor) {
            items {
              $_requestFields
            }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {if (cursor != null) 'cursor': cursor},
        auth: true,
      );
      final conn = data['prayerFeed'] as Map<String, dynamic>?;
      final hasMore = conn?['hasMore'] == true;
      final nextCursor = conn?['nextCursor']?.toString();
      _cursors.putIfAbsent(key, () => {});
      if (hasMore && nextCursor != null) {
        _cursors[key]![page + 1] = nextCursor;
      }
      return _parseRequestConnection(conn, page: page);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<PrayerJournalEntry>> getJournal({
    int page = 1,
  }) async {
    try {
      const key = 'journal';
      if (page == 1) {
        _cursors[key] = {};
      }
      final cursor = page > 1 ? _cursors[key]?[page] : null;
      if (page > 1 && cursor == null) {
        return PaginatedResult(success: true, items: const []);
      }

      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyPrayerJournal(\$cursor: String) {
          myPrayerJournal(cursor: \$cursor) {
            items {
              $_journalFields
            }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {if (cursor != null) 'cursor': cursor},
        auth: true,
      );
      final conn = data['myPrayerJournal'] as Map<String, dynamic>?;
      final rows = conn?['items'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => PrayerJournalEntry.fromJson(_journalToLegacy(row)))
          .toList();
      final hasMore = conn?['hasMore'] == true;
      final nextCursor = conn?['nextCursor']?.toString();
      _cursors.putIfAbsent(key, () => {});
      if (hasMore && nextCursor != null) {
        _cursors[key]![page + 1] = nextCursor;
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

  static Future<SingleResult<PrayerJournalEntry>> addJournalEntry(
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreatePrayerJournalEntry(\$input: CreatePrayerJournalInput!) {
          createPrayerJournalEntry(input: \$input) {
            $_journalFields
          }
        }
        ''',
        variables: {
          'input': {
            'content': body['content'],
            if (body['scripture_ref'] != null &&
                body['scripture_ref'].toString().trim().isNotEmpty)
              'scriptureRef': body['scripture_ref'],
            if (body['reflection'] != null &&
                body['reflection'].toString().trim().isNotEmpty)
              'reflection': body['reflection'],
            if (body['date'] != null) 'date': body['date'],
          },
        },
        auth: true,
      );
      final row = result['createPrayerJournalEntry'] as Map<String, dynamic>?;
      if (row == null) {
        return SingleResult(success: false, message: 'Imeshindwa kuhifadhi');
      }
      return SingleResult(
        success: true,
        data: PrayerJournalEntry.fromJson(_journalToLegacy(row)),
      );
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<PrayerStats>> getStats() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyPrayerStats {
          myPrayerStats {
            $_statsFields
          }
        }
        ''',
        auth: true,
      );
      final row = data['myPrayerStats'] as Map<String, dynamic>?;
      if (row == null) {
        return SingleResult(success: false, message: 'Imeshindwa kupakia');
      }
      return SingleResult(
        success: true,
        data: PrayerStats.fromJson(_statsToLegacy(row)),
      );
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
