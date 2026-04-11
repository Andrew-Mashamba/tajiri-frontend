// lib/notes/services/notes_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/notes_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class NotesService {
  // ─── Get all notes ─────────────────────────────────────────────

  Future<NotesListResult<Note>> getNotes(int userId,
      {String? search}) async {
    try {
      final params = <String, String>{'user_id': userId.toString()};
      if (search != null && search.isNotEmpty) params['search'] = search;
      final uri = Uri.parse('$_baseUrl/notes')
          .replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => Note.fromJson(j))
              .toList();
          return NotesListResult(success: true, items: items);
        }
      }
      return NotesListResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return NotesListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Get single note ──────────────────────────────────────────

  Future<NotesResult<Note>> getNote(int noteId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notes/$noteId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return NotesResult(
              success: true, data: Note.fromJson(data['data']));
        }
      }
      return NotesResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return NotesResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Create note ──────────────────────────────────────────────

  Future<NotesResult<Note>> createNote(Note note) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(note.toJson()),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return NotesResult(
            success: true, data: Note.fromJson(data['data']));
      }
      return NotesResult(
          success: false, message: data['message'] ?? 'Imeshindwa kuunda');
    } catch (e) {
      return NotesResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Update note ──────────────────────────────────────────────

  Future<NotesResult<Note>> updateNote(int noteId, Note note) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/notes/$noteId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(note.toJson()),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return NotesResult(
            success: true, data: Note.fromJson(data['data']));
      }
      return NotesResult(
          success: false, message: data['message'] ?? 'Imeshindwa kubadilisha');
    } catch (e) {
      return NotesResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Delete note ──────────────────────────────────────────────

  Future<NotesResult<void>> deleteNote(int noteId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/notes/$noteId'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return NotesResult(success: true);
      }
      return NotesResult(
          success: false, message: data['message'] ?? 'Imeshindwa kufuta');
    } catch (e) {
      return NotesResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Toggle pin ───────────────────────────────────────────────

  Future<NotesResult<Note>> togglePin(int noteId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notes/$noteId/toggle-pin'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return NotesResult(
            success: true, data: Note.fromJson(data['data']));
      }
      return NotesResult(success: false);
    } catch (e) {
      return NotesResult(success: false, message: 'Kosa: $e');
    }
  }
}
