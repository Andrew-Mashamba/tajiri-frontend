import '../../study_groups/models/study_groups_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL study groups (Phase 72 — backend rev 207).
class GraphqlStudyGroupsService {
  static const _groupFields = r'''
    id
    name
    subject
    description
    courseCode
    memberCount
    maxMembers
    isPublic
    groupId
    createdBy
    streak
    totalSessions
    isMember
    createdAt
  ''';

  static const _memberFields = r'''
    id
    userId
    name
    avatarUrl
    role
    attendanceCount
    contributionScore
    joinedAt
  ''';

  static const _sessionFields = r'''
    id
    groupId
    topic
    scheduledAt
    durationMinutes
    location
    isVirtual
    attendeeCount
    hasCheckedIn
  ''';

  static Map<String, dynamic> _groupToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'name': row['name'],
      'subject': row['subject'],
      'description': row['description'],
      'course_code': row['courseCode'],
      'member_count': row['memberCount'],
      'max_members': row['maxMembers'],
      'is_public': row['isPublic'],
      'group_id': row['groupId'] != null
          ? int.tryParse(row['groupId'].toString())
          : null,
      'created_by': int.tryParse(row['createdBy']?.toString() ?? '') ?? 0,
      'streak': row['streak'],
      'total_sessions': row['totalSessions'],
      'created_at': row['createdAt'],
    };
  }

  static Map<String, dynamic> _memberToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'user_id': row['userId'],
      'name': row['name'],
      'avatar_url': row['avatarUrl'],
      'role': row['role'],
      'attendance_count': row['attendanceCount'],
      'contribution_score': row['contributionScore'],
      'joined_at': row['joinedAt'],
    };
  }

  static Map<String, dynamic> _sessionToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'group_id': row['groupId'],
      'topic': row['topic'],
      'scheduled_at': row['scheduledAt'],
      'duration_minutes': row['durationMinutes'],
      'location': row['location'],
      'is_virtual': row['isVirtual'],
      'attendee_count': row['attendeeCount'],
      'has_checked_in': row['hasCheckedIn'],
    };
  }

  static Future<StudyListResult<StudyGroup>> getMyGroups() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyStudyGroups {
          myStudyGroups {
            $_groupFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myStudyGroups'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => StudyGroup.fromJson(_groupToLegacy(row)))
          .toList();
      return StudyListResult(success: true, items: items);
    } catch (e) {
      return StudyListResult(success: false, message: '$e');
    }
  }

  static Future<StudyListResult<StudyGroup>> discoverGroups({
    String? subject,
    String? search,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query DiscoverStudyGroups {
          discoverStudyGroups {
            $_groupFields
          }
        }
        ''',
        auth: true,
      );
      var rows = (data['discoverStudyGroups'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((row) => StudyGroup.fromJson(_groupToLegacy(row)))
          .toList();
      if (subject != null && subject.isNotEmpty) {
        rows = rows.where((g) => g.subject == subject).toList();
      }
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        rows = rows
            .where((g) =>
                g.name.toLowerCase().contains(q) ||
                g.subject.toLowerCase().contains(q))
            .toList();
      }
      return StudyListResult(success: true, items: rows);
    } catch (e) {
      return StudyListResult(success: false, message: '$e');
    }
  }

  static Future<StudyResult<StudyGroup>> createGroup({
    required String name,
    required String subject,
    String? description,
    String? courseCode,
    int maxMembers = 8,
    bool isPublic = true,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateStudyGroup(\$input: CreateStudyGroupInput!) {
          createStudyGroup(input: \$input) {
            $_groupFields
          }
        }
        ''',
        variables: {
          'input': {
            'name': name,
            'subject': subject,
            if (description != null) 'description': description,
            if (courseCode != null) 'courseCode': courseCode,
            'maxMembers': maxMembers,
            'isPublic': isPublic,
          },
        },
        auth: true,
      );
      final row = result['createStudyGroup'] as Map<String, dynamic>?;
      if (row == null) {
        return StudyResult(success: false, message: 'Imeshindwa kuunda');
      }
      return StudyResult(
        success: true,
        data: StudyGroup.fromJson(_groupToLegacy(row)),
      );
    } catch (e) {
      return StudyResult(success: false, message: '$e');
    }
  }

  static Future<StudyResult<void>> joinGroup(int groupId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation JoinStudyGroup(\$groupId: ID!) {
          joinStudyGroup(groupId: \$groupId) {
            id
          }
        }
        ''',
        variables: {'groupId': groupId.toString()},
        auth: true,
      );
      return StudyResult(success: result['joinStudyGroup'] != null);
    } catch (e) {
      return StudyResult(success: false, message: '$e');
    }
  }

  static Future<StudyListResult<StudyGroupMember>> getMembers(int groupId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query StudyGroupMembers(\$groupId: ID!) {
          studyGroupMembers(groupId: \$groupId) {
            $_memberFields
          }
        }
        ''',
        variables: {'groupId': groupId.toString()},
        auth: true,
      );
      final rows = data['studyGroupMembers'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => StudyGroupMember.fromJson(_memberToLegacy(row)))
          .toList();
      return StudyListResult(success: true, items: items);
    } catch (e) {
      return StudyListResult(success: false, message: '$e');
    }
  }

  static Future<StudyListResult<GroupStudySession>> getSessions(int groupId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query StudyGroupSessions(\$groupId: ID!) {
          studyGroupSessions(groupId: \$groupId) {
            $_sessionFields
          }
        }
        ''',
        variables: {'groupId': groupId.toString()},
        auth: true,
      );
      final rows = data['studyGroupSessions'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => GroupStudySession.fromJson(_sessionToLegacy(row)))
          .toList();
      return StudyListResult(success: true, items: items);
    } catch (e) {
      return StudyListResult(success: false, message: '$e');
    }
  }

  static Future<StudyResult<GroupStudySession>> scheduleSession({
    required int groupId,
    required String topic,
    required DateTime scheduledAt,
    int durationMinutes = 60,
    String? location,
    bool isVirtual = false,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateStudyGroupSession(\$groupId: ID!, \$input: CreateStudySessionInput!) {
          createStudyGroupSession(groupId: \$groupId, input: \$input) {
            $_sessionFields
          }
        }
        ''',
        variables: {
          'groupId': groupId.toString(),
          'input': {
            'topic': topic,
            'scheduledAt': scheduledAt.toIso8601String(),
            'durationMinutes': durationMinutes,
            if (location != null) 'location': location,
            'isVirtual': isVirtual,
          },
        },
        auth: true,
      );
      final row = result['createStudyGroupSession'] as Map<String, dynamic>?;
      if (row == null) return StudyResult(success: false);
      return StudyResult(
        success: true,
        data: GroupStudySession.fromJson(_sessionToLegacy(row)),
      );
    } catch (e) {
      return StudyResult(success: false, message: '$e');
    }
  }

  static Future<StudyResult<void>> checkIn(int sessionId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CheckInStudySession(\$sessionId: ID!) {
          checkInStudySession(sessionId: \$sessionId) {
            id
          }
        }
        ''',
        variables: {'sessionId': sessionId.toString()},
        auth: true,
      );
      return StudyResult(success: result['checkInStudySession'] != null);
    } catch (e) {
      return StudyResult(success: false, message: '$e');
    }
  }
}
