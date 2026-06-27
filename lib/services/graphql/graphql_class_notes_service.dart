import 'dart:io';

import '../../class_notes/models/class_notes_models.dart';
import 'graphql_media_service.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL class notes (Phase 84 — backend rev 214).
/// Week-number list filter stays REST-only when supplied.
class GraphqlClassNotesService {
  static const _noteFields = r'''
    id
    title
    description
    subject
    courseCode
    topic
    weekNumber
    semester
    year
    institution
    format
    fileUrl
    fileSize
    uploaderId
    uploaderName
    rating
    ratingCount
    downloadCount
    viewCount
    isBookmarked
    createdAt
  ''';

  static String? _notesCursor;
  static String? _notesKey;

  static Map<String, dynamic> _noteToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'title': row['title'],
      'description': row['description'],
      'subject': row['subject'],
      'course_code': row['courseCode'],
      'topic': row['topic'],
      'week_number': row['weekNumber'],
      'semester': row['semester'],
      'year': row['year'],
      'institution': row['institution'],
      'format': row['format'],
      'file_url': row['fileUrl'],
      'file_size': row['fileSize'],
      'uploader_id': row['uploaderId'],
      'uploader_name': row['uploaderName'],
      'rating': row['rating'],
      'rating_count': row['ratingCount'],
      'download_count': row['downloadCount'],
      'view_count': row['viewCount'],
      'is_bookmarked': row['isBookmarked'],
      'created_at': row['createdAt'],
    };
  }

  static Map<String, dynamic> _requestToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'subject': row['subject'],
      'course_code': row['courseCode'],
      'topic': row['topic'],
      'week_number': row['weekNumber'],
      'requester_id': row['requesterId'],
      'requester_name': '',
      'is_fulfilled': row['isFulfilled'],
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> _contributorToLegacy(Map<String, dynamic> row) {
    return {
      'user_id': row['userId'],
      'name': row['name'],
      'upload_count': row['uploadCount'],
      'average_rating': row['averageRating'],
      'total_downloads': 0,
    };
  }

  static String _formatFromPath(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    if (ext == 'pdf') return 'pdf';
    if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) return 'image';
    if (['ppt', 'pptx', 'key'].contains(ext)) return 'slides';
    return 'document';
  }

  static Future<NotesListResult<ClassNote>> getNotes({
    String? subject,
    String? courseCode,
    String? search,
    int page = 1,
  }) async {
    try {
      final key = '${subject ?? ''}|${courseCode ?? ''}|${search ?? ''}';
      if (page == 1 || _notesKey != key) {
        _notesCursor = null;
        _notesKey = key;
      }
      final cursor = page > 1 ? _notesCursor : null;
      if (page > 1 && cursor == null) {
        return NotesListResult(success: true, items: const []);
      }

      final data = await TajiriGraphqlClient.instance.query(
        '''
        query ClassNotes(
          \$subject: String
          \$courseCode: String
          \$search: String
          \$cursor: String
        ) {
          classNotes(
            subject: \$subject
            courseCode: \$courseCode
            search: \$search
            cursor: \$cursor
          ) {
            items { $_noteFields }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          if (subject != null && subject.isNotEmpty) 'subject': subject,
          if (courseCode != null && courseCode.isNotEmpty) 'courseCode': courseCode,
          if (search != null && search.isNotEmpty) 'search': search,
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final conn = data['classNotes'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => ClassNote.fromJson(_noteToLegacy(row)))
          .toList();
      if (conn['hasMore'] == true && conn['nextCursor'] != null) {
        _notesCursor = conn['nextCursor'].toString();
      }
      return NotesListResult(success: true, items: items);
    } catch (e) {
      return NotesListResult(
        success: false,
        message: 'Imeshindwa kupakia: $e',
      );
    }
  }

  static Future<NotesResult<ClassNote>> uploadNote({
    required String filePath,
    required String title,
    required String subject,
    String? courseCode,
    String? topic,
    int? weekNumber,
    required String semester,
    required int year,
    String? description,
  }) async {
    try {
      final file = File(filePath);
      final uploaded = await GraphqlMediaService.uploadFile(
        file,
        mediaType: 'document',
      );
      final path = uploaded?['file_path']?.toString();
      if (path == null) {
        return NotesResult(success: false, message: 'Imeshindwa kupakia faili');
      }
      final fileSize = uploaded?['file_size'] is num
          ? (uploaded!['file_size'] as num).toInt()
          : await file.length();

      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateClassNote(\$input: CreateClassNoteInput!) {
          createClassNote(input: \$input) {
            $_noteFields
          }
        }
        ''',
        variables: {
          'input': {
            'title': title,
            'subject': subject,
            'fileUrl': path,
            'fileSize': fileSize,
            if (description != null && description.isNotEmpty)
              'description': description,
            if (courseCode != null && courseCode.isNotEmpty)
              'courseCode': courseCode,
            if (topic != null && topic.isNotEmpty) 'topic': topic,
            'weekNumber': weekNumber ?? 0,
            'semester': semester,
            'year': year,
            'format': _formatFromPath(filePath),
          },
        },
        auth: true,
      );
      final row = data['createClassNote'] as Map<String, dynamic>?;
      if (row == null) {
        return NotesResult(success: false, message: 'Imeshindwa kupakia');
      }
      return NotesResult(
        success: true,
        data: ClassNote.fromJson(_noteToLegacy(row)),
      );
    } catch (e) {
      return NotesResult(success: false, message: '$e');
    }
  }

  static Future<NotesResult<void>> rateNote({
    required int noteId,
    required int rating,
  }) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RateClassNote(\$noteId: ID!, \$rating: Int!) {
          rateClassNote(noteId: \$noteId, rating: \$rating) {
            id
          }
        }
        ''',
        variables: {
          'noteId': noteId.toString(),
          'rating': rating,
        },
        auth: true,
      );
      return NotesResult(success: true);
    } catch (e) {
      return NotesResult(success: false, message: '$e');
    }
  }

  static Future<NotesResult<void>> bookmarkNote(int noteId) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ToggleNoteBookmark(\$noteId: ID!) {
          toggleNoteBookmark(noteId: \$noteId) {
            noteId
            isBookmarked
          }
        }
        ''',
        variables: {'noteId': noteId.toString()},
        auth: true,
      );
      return NotesResult(success: true);
    } catch (e) {
      return NotesResult(success: false, message: '$e');
    }
  }

  static Future<NotesListResult<NoteRequest>> getNoteRequests() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query NoteRequests {
          noteRequests {
            id
            requesterId
            subject
            courseCode
            topic
            weekNumber
            isFulfilled
          }
        }
        ''',
        auth: true,
      );
      final rows = data['noteRequests'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => NoteRequest.fromJson(_requestToLegacy(row)))
          .toList();
      return NotesListResult(success: true, items: items);
    } catch (e) {
      return NotesListResult(success: false, message: '$e');
    }
  }

  static Future<NotesListResult<NoteContributor>> getLeaderboard() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query NoteLeaderboard {
          noteLeaderboard {
            userId
            name
            uploadCount
            averageRating
          }
        }
        ''',
        auth: true,
      );
      final rows = data['noteLeaderboard'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => NoteContributor.fromJson(_contributorToLegacy(row)))
          .toList();
      return NotesListResult(success: true, items: items);
    } catch (e) {
      return NotesListResult(success: false, message: '$e');
    }
  }
}
