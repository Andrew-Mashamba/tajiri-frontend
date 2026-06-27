import '../../barozi_wangu/models/barozi_wangu_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL Barozi Wangu civic engagement (Phase 70 — backend rev 038).
class GraphqlBaroziService {
  static const _councillorFields = r'''
    id
    userId
    wardId
    name
    photo
    party
    phone
    email
    bio
    officeLocation
    termStart
    termEnd
    committees
    rating
  ''';

  static const _issueFields = r'''
    id
    reporterId
    wardId
    category
    description
    photoUrls
    gpsLat
    gpsLng
    status
    priority
    createdAt
  ''';

  static const _promiseFields = r'''
    id
    councillorId
    description
    status
    evidenceLinks
    communityVotes
  ''';

  static const _projectFields = r'''
    id
    wardId
    name
    budget
    contractor
    startDate
    endDate
    progressPercent
    photos
    sector
  ''';

  static final Map<String, Map<int, String?>> _issueCursors = {};

  static Map<String, dynamic> _councillorToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'user_id': int.tryParse(row['userId']?.toString() ?? '') ?? 0,
      'ward_id': int.tryParse(row['wardId']?.toString() ?? '') ?? 0,
      'name': row['name'],
      'photo': row['photo'],
      'party': row['party'],
      'phone': row['phone'],
      'email': row['email'],
      'bio': row['bio'],
      'office_location': row['officeLocation'],
      'term_start': row['termStart'],
      'term_end': row['termEnd'],
      'committees': row['committees'] ?? [],
      'rating': row['rating'],
    };
  }

  static Map<String, dynamic> _issueToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'reporter_id': int.tryParse(row['reporterId']?.toString() ?? '') ?? 0,
      'ward_id': int.tryParse(row['wardId']?.toString() ?? '') ?? 0,
      'category': row['category'],
      'description': row['description'],
      'photo_urls': row['photoUrls'] ?? [],
      'gps_lat': row['gpsLat'],
      'gps_lng': row['gpsLng'],
      'status': row['status'],
      'priority': row['priority'],
      'created_at': row['createdAt'],
    };
  }

  static Map<String, dynamic> _promiseToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'councillor_id': int.tryParse(row['councillorId']?.toString() ?? '') ?? 0,
      'description': row['description'],
      'status': row['status'],
      'evidence_links': row['evidenceLinks'] ?? [],
      'community_votes': row['communityVotes'],
    };
  }

  static Map<String, dynamic> _projectToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'ward_id': int.tryParse(row['wardId']?.toString() ?? '') ?? 0,
      'name': row['name'],
      'budget': row['budget'],
      'contractor': row['contractor'],
      'start_date': row['startDate'],
      'end_date': row['endDate'],
      'progress_percent': row['progressPercent'],
      'photos': row['photos'] ?? [],
      'sector': row['sector'],
    };
  }

  static Future<SingleResult<Councillor>> getCouncillor(int wardId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query WardCouncillor(\$wardId: ID!) {
          wardCouncillor(wardId: \$wardId) {
            $_councillorFields
          }
        }
        ''',
        variables: {'wardId': wardId.toString()},
        auth: false,
      );
      final row = data['wardCouncillor'] as Map<String, dynamic>?;
      if (row == null) {
        return SingleResult(message: 'Councillor not found');
      }
      return SingleResult(
        success: true,
        data: Councillor.fromJson(_councillorToLegacy(row)),
      );
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  static Future<SingleResult<WardIssue>> reportIssue(
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ReportWardIssue(\$input: ReportWardIssueInput!) {
          reportWardIssue(input: \$input) {
            $_issueFields
          }
        }
        ''',
        variables: {
          'input': {
            'wardId': data['ward_id'].toString(),
            'category': data['category'],
            'description': data['description'],
            'priority': data['priority'] ?? 'normal',
            if (data['photo_urls'] != null) 'photoUrls': data['photo_urls'],
            if (data['gps_lat'] != null) 'gpsLat': data['gps_lat'],
            if (data['gps_lng'] != null) 'gpsLng': data['gps_lng'],
          },
        },
        auth: true,
      );
      final row = result['reportWardIssue'] as Map<String, dynamic>?;
      if (row == null) {
        return SingleResult(message: 'Failed to report issue');
      }
      return SingleResult(
        success: true,
        data: WardIssue.fromJson(_issueToLegacy(row)),
      );
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  static Future<PaginatedResult<WardIssue>> getIssues(
    int wardId, {
    String? status,
    String? category,
    int page = 1,
  }) async {
    try {
      final key = 'issues:$wardId:${status ?? ''}:${category ?? ''}';
      if (page == 1) {
        _issueCursors[key] = {};
      }
      final cursor = page > 1 ? _issueCursors[key]?[page] : null;
      if (page > 1 && cursor == null) {
        return PaginatedResult(success: true, items: const [], page: page);
      }

      final data = await TajiriGraphqlClient.instance.query(
        '''
        query WardIssues(\$wardId: ID!, \$status: String, \$category: String, \$cursor: String) {
          wardIssues(wardId: \$wardId, status: \$status, category: \$category, cursor: \$cursor) {
            items {
              $_issueFields
            }
            nextCursor
            hasMore
            total
          }
        }
        ''',
        variables: {
          'wardId': wardId.toString(),
          if (status != null) 'status': status,
          if (category != null) 'category': category,
          if (cursor != null) 'cursor': cursor,
        },
        auth: false,
      );
      final conn = data['wardIssues'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => WardIssue.fromJson(_issueToLegacy(row)))
          .toList();
      final hasMore = conn['hasMore'] == true;
      final nextCursor = conn['nextCursor']?.toString();
      _issueCursors.putIfAbsent(key, () => {});
      if (hasMore && nextCursor != null) {
        _issueCursors[key]![page + 1] = nextCursor;
      }
      return PaginatedResult(
        success: true,
        items: items,
        total: (conn['total'] as num?)?.toInt() ?? items.length,
        page: page,
      );
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  static Future<PaginatedResult<CampaignPromise>> getPromises(
    int councillorId, {
    int page = 1,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query WardCouncillorPromises(\$councillorId: ID!) {
          wardCouncillorPromises(councillorId: \$councillorId) {
            $_promiseFields
          }
        }
        ''',
        variables: {'councillorId': councillorId.toString()},
        auth: false,
      );
      final rows = data['wardCouncillorPromises'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => CampaignPromise.fromJson(_promiseToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, page: page);
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  static Future<SingleResult<PerformanceScore>> rateCouncillor(
    int councillorId,
    Map<String, dynamic> scores,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RateWardCouncillor(\$councillorId: ID!, \$input: RateCouncillorInput!) {
          rateWardCouncillor(councillorId: \$councillorId, input: \$input) {
            responsiveness
            presence
            development
            aggregate
          }
        }
        ''',
        variables: {
          'councillorId': councillorId.toString(),
          'input': {
            'responsiveness': scores['responsiveness'],
            'presence': scores['presence'],
            'development': scores['development'],
          },
        },
        auth: true,
      );
      final row = result['rateWardCouncillor'] as Map<String, dynamic>?;
      if (row == null) {
        return SingleResult(message: 'Failed');
      }
      return SingleResult(
        success: true,
        data: PerformanceScore.fromJson({
          'responsiveness': row['responsiveness'],
          'presence': row['presence'],
          'development': row['development'],
          'aggregate': row['aggregate'],
        }),
      );
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  static Future<PaginatedResult<DevelopmentProject>> getProjects(
    int wardId, {
    int page = 1,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query WardProjects(\$wardId: ID!) {
          wardProjects(wardId: \$wardId) {
            $_projectFields
          }
        }
        ''',
        variables: {'wardId': wardId.toString()},
        auth: false,
      );
      final rows = data['wardProjects'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => DevelopmentProject.fromJson(_projectToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, page: page);
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }
}
