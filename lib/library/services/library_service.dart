// lib/library/services/library_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/library_models.dart';

class LibraryService {
  Dio get _dio => AuthenticatedDio.instance;

  Future<LibraryListResult<LibraryBook>> searchBooks({
    String? query,
    String? category,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (query != null && query.isNotEmpty) params['search'] = query;
      if (category != null) params['category'] = category;
      final res =
          await _dio.get('/education/library/books', queryParameters: params);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => LibraryBook.fromJson(j))
            .toList();
        return LibraryListResult(success: true, items: items);
      }
      return LibraryListResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return LibraryListResult(success: false, message: '$e');
    }
  }

  Future<LibraryResult<LibraryBook>> getBook(int bookId) async {
    try {
      final res = await _dio.get('/education/library/books/$bookId');
      if (res.statusCode == 200 && res.data['success'] == true) {
        return LibraryResult(
          success: true,
          data: LibraryBook.fromJson(res.data['data']),
        );
      }
      return LibraryResult(success: false, message: 'Kitabu hakipatikani');
    } catch (e) {
      return LibraryResult(success: false, message: '$e');
    }
  }

  Future<LibraryResult<void>> borrowBook(int bookId) async {
    try {
      final res =
          await _dio.post('/education/library/books/$bookId/borrow');
      return LibraryResult(success: res.statusCode == 200);
    } catch (e) {
      return LibraryResult(success: false, message: '$e');
    }
  }

  Future<LibraryResult<void>> bookmarkBook(int bookId) async {
    try {
      final res =
          await _dio.post('/education/library/books/$bookId/bookmark');
      return LibraryResult(success: res.statusCode == 200);
    } catch (e) {
      return LibraryResult(success: false, message: '$e');
    }
  }

  Future<LibraryListResult<LibraryBook>> getMyBookshelf() async {
    try {
      final res = await _dio.get('/education/library/bookshelf');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => LibraryBook.fromJson(j))
            .toList();
        return LibraryListResult(success: true, items: items);
      }
      return LibraryListResult(success: false);
    } catch (e) {
      return LibraryListResult(success: false, message: '$e');
    }
  }

  Future<LibraryListResult<ReadingList>> getReadingLists() async {
    try {
      final res = await _dio.get('/education/library/reading-lists');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => ReadingList.fromJson(j))
            .toList();
        return LibraryListResult(success: true, items: items);
      }
      return LibraryListResult(success: false);
    } catch (e) {
      return LibraryListResult(success: false, message: '$e');
    }
  }

  Future<LibraryResult<Citation>> getCitation({
    required int bookId,
    required String style,
  }) async {
    try {
      final res = await _dio.get(
        '/education/library/books/$bookId/cite',
        queryParameters: {'style': style},
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        return LibraryResult(
          success: true,
          data: Citation.fromJson(res.data['data']),
        );
      }
      return LibraryResult(success: false);
    } catch (e) {
      return LibraryResult(success: false, message: '$e');
    }
  }
}
