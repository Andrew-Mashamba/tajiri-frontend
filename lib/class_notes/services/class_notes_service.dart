// lib/class_notes/services/class_notes_service.dart
import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../services/authenticated_dio.dart';
import '../../services/graphql/graphql_class_notes_service.dart';
import '../models/class_notes_models.dart';

class ClassNotesService {
  Dio get _dio => AuthenticatedDio.instance;

  Future<NotesListResult<ClassNote>> getNotes({
    String? subject,
    String? courseCode,
    int? weekNumber,
    String? search,
    int page = 1,
  }) async {
    if (ApiConfig.useGraphqlBackend && weekNumber == null) {
      return GraphqlClassNotesService.getNotes(
        subject: subject,
        courseCode: courseCode,
        search: search,
        page: page,
      );
    }
    try {
      final params = <String, dynamic>{'page': page};
      if (subject != null) params['subject'] = subject;
      if (courseCode != null) params['course_code'] = courseCode;
      if (weekNumber != null) params['week_number'] = weekNumber;
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res =
          await _dio.get('/education/notes', queryParameters: params);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => ClassNote.fromJson(j))
            .toList();
        return NotesListResult(success: true, items: items);
      }
      return NotesListResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return NotesListResult(success: false, message: '$e');
    }
  }

  Future<NotesResult<ClassNote>> uploadNote({
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
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlClassNotesService.uploadNote(
        filePath: filePath,
        title: title,
        subject: subject,
        courseCode: courseCode,
        topic: topic,
        weekNumber: weekNumber,
        semester: semester,
        year: year,
        description: description,
      );
    }
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'title': title,
        'subject': subject,
        if (courseCode != null) 'course_code': courseCode,
        if (topic != null) 'topic': topic,
        if (weekNumber != null) 'week_number': weekNumber,
        'semester': semester,
        'year': year,
        if (description != null) 'description': description,
      });
      final res = await _dio.post('/education/notes', data: formData);
      if (res.statusCode == 200 && res.data['success'] == true) {
        return NotesResult(
          success: true,
          data: ClassNote.fromJson(res.data['data']),
        );
      }
      return NotesResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return NotesResult(success: false, message: '$e');
    }
  }

  Future<NotesResult<void>> rateNote({
    required int noteId,
    required int rating,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlClassNotesService.rateNote(noteId: noteId, rating: rating);
    }
    try {
      final res = await _dio.post('/education/notes/$noteId/rate', data: {
        'rating': rating,
      });
      return NotesResult(success: res.statusCode == 200);
    } catch (e) {
      return NotesResult(success: false, message: '$e');
    }
  }

  Future<NotesResult<void>> bookmarkNote(int noteId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlClassNotesService.bookmarkNote(noteId);
    }
    try {
      final res = await _dio.post('/education/notes/$noteId/bookmark');
      return NotesResult(success: res.statusCode == 200);
    } catch (e) {
      return NotesResult(success: false, message: '$e');
    }
  }

  Future<NotesListResult<NoteRequest>> getNoteRequests() async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlClassNotesService.getNoteRequests();
    }
    try {
      final res = await _dio.get('/education/note-requests');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => NoteRequest.fromJson(j))
            .toList();
        return NotesListResult(success: true, items: items);
      }
      return NotesListResult(success: false);
    } catch (e) {
      return NotesListResult(success: false, message: '$e');
    }
  }

  Future<NotesListResult<NoteContributor>> getLeaderboard() async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlClassNotesService.getLeaderboard();
    }
    try {
      final res = await _dio.get('/education/notes/leaderboard');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => NoteContributor.fromJson(j))
            .toList();
        return NotesListResult(success: true, items: items);
      }
      return NotesListResult(success: false);
    } catch (e) {
      return NotesListResult(success: false, message: '$e');
    }
  }
}
