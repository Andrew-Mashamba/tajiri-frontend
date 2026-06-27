import '../../assignments/models/assignments_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL education assignments (Phase 72 — backend rev 205).
class GraphqlAssignmentsService {
  static const _assignmentFields = r'''
    id
    title
    description
    subject
    courseCode
    classId
    priority
    status
    dueDate
    grade
    maxGrade
    attachments
    submissions
    isGroupAssignment
    createdAt
  ''';

  static const _gradeFields = r'''
    subject
    average
    totalAssignments
    gradedCount
  ''';

  static final Map<String, Map<int, String?>> _cursors = {};

  static Map<String, dynamic> _assignmentToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'title': row['title'],
      'description': row['description'],
      'subject': row['subject'],
      'course_code': row['courseCode'],
      'class_id': row['classId'],
      'priority': row['priority'],
      'status': row['status'],
      'due_date': row['dueDate'],
      'grade': row['grade'],
      'max_grade': row['maxGrade'],
      'attachments': row['attachments'] ?? [],
      'submissions': row['submissions'] ?? [],
      'is_group_assignment': row['isGroupAssignment'],
      'created_at': row['createdAt'],
    };
  }

  static Map<String, dynamic> _gradeToLegacy(Map<String, dynamic> row) {
    return {
      'subject': row['subject'],
      'average': row['average'],
      'total_assignments': row['totalAssignments'],
      'graded_count': row['gradedCount'],
    };
  }

  static Future<AssignmentListResult<Assignment>> getAssignments({
    String? subject,
    String? status,
    int page = 1,
  }) async {
    try {
      final key = 'assignments:${subject ?? ''}:${status ?? ''}';
      if (page == 1) _cursors[key] = {};
      final cursor = page > 1 ? _cursors[key]?[page] : null;
      if (page > 1 && cursor == null) {
        return AssignmentListResult(success: true, items: const []);
      }

      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyAssignments(\$subject: String, \$status: String, \$cursor: String) {
          myAssignments(subject: \$subject, status: \$status, cursor: \$cursor) {
            items { $_assignmentFields }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          if (subject != null) 'subject': subject,
          if (status != null) 'status': status,
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final conn = data['myAssignments'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => Assignment.fromJson(_assignmentToLegacy(row)))
          .toList();
      final hasMore = conn['hasMore'] == true;
      final nextCursor = conn['nextCursor']?.toString();
      _cursors.putIfAbsent(key, () => {});
      if (hasMore && nextCursor != null) _cursors[key]![page + 1] = nextCursor;
      return AssignmentListResult(success: true, items: items);
    } catch (e) {
      return AssignmentListResult(success: false, message: '$e');
    }
  }

  static Future<AssignmentResult<Assignment>> createAssignment({
    required String title,
    required String description,
    required String subject,
    String? courseCode,
    int? classId,
    required String priority,
    required DateTime dueDate,
    double? maxGrade,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateAssignment(\$input: CreateAssignmentInput!) {
          createAssignment(input: \$input) {
            $_assignmentFields
          }
        }
        ''',
        variables: {
          'input': {
            'title': title,
            'description': description,
            'subject': subject,
            'priority': priority,
            'dueDate': dueDate.toIso8601String(),
            if (courseCode != null) 'courseCode': courseCode,
            if (classId != null) 'classId': classId.toString(),
            if (maxGrade != null) 'maxGrade': maxGrade,
          },
        },
        auth: true,
      );
      final row = result['createAssignment'] as Map<String, dynamic>?;
      if (row == null) {
        return AssignmentResult(success: false, message: 'Imeshindwa kuunda');
      }
      return AssignmentResult(
        success: true,
        data: Assignment.fromJson(_assignmentToLegacy(row)),
      );
    } catch (e) {
      return AssignmentResult(success: false, message: '$e');
    }
  }

  static Future<AssignmentResult<Assignment>> updateStatus({
    required int assignmentId,
    required String status,
    double? grade,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateAssignment(\$assignmentId: ID!, \$status: String, \$grade: Float) {
          updateAssignment(assignmentId: \$assignmentId, status: \$status, grade: \$grade) {
            $_assignmentFields
          }
        }
        ''',
        variables: {
          'assignmentId': assignmentId.toString(),
          'status': status,
          if (grade != null) 'grade': grade,
        },
        auth: true,
      );
      final row = result['updateAssignment'] as Map<String, dynamic>?;
      if (row == null) return AssignmentResult(success: false);
      return AssignmentResult(
        success: true,
        data: Assignment.fromJson(_assignmentToLegacy(row)),
      );
    } catch (e) {
      return AssignmentResult(success: false, message: '$e');
    }
  }

  static Future<AssignmentResult<void>> deleteAssignment(int id) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteAssignment(\$assignmentId: ID!) {
          deleteAssignment(assignmentId: \$assignmentId)
        }
        ''',
        variables: {'assignmentId': id.toString()},
        auth: true,
      );
      return AssignmentResult(success: result['deleteAssignment'] == true);
    } catch (e) {
      return AssignmentResult(success: false, message: '$e');
    }
  }

  static Future<AssignmentListResult<GradeSummary>> getGradesSummary() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyGradesSummary {
          myGradesSummary {
            $_gradeFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myGradesSummary'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => GradeSummary.fromJson(_gradeToLegacy(row)))
          .toList();
      return AssignmentListResult(success: true, items: items);
    } catch (e) {
      return AssignmentListResult(success: false, message: '$e');
    }
  }
}
