import '../../library/models/library_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL digital library (Phase 82 — backend rev 213).
/// Citations remain REST-only.
class GraphqlLibraryService {
  static const _bookFields = r'''
    id
    title
    author
    isbn
    description
    coverUrl
    category
    fileUrl
    pageCount
    rating
    ratingCount
    readCount
    isAvailablePhysical
    isBookmarked
    isBorrowed
    returnDate
  ''';

  static String? _searchCursor;
  static String? _searchKey;

  static Map<String, dynamic> _bookToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'title': row['title'],
      'author': row['author'],
      'isbn': row['isbn'],
      'description': row['description'],
      'cover_url': row['coverUrl'],
      'category': row['category'],
      'file_url': row['fileUrl'],
      'page_count': row['pageCount'],
      'rating': row['rating'],
      'rating_count': row['ratingCount'],
      'read_count': row['readCount'],
      'is_available_physical': row['isAvailablePhysical'],
      'is_bookmarked': row['isBookmarked'],
      'is_borrowed': row['isBorrowed'],
      'return_date': row['returnDate'],
    };
  }

  static Future<LibraryListResult<LibraryBook>> searchBooks({
    String? query,
    String? category,
    int page = 1,
  }) async {
    try {
      final key = '${query ?? ''}|${category ?? ''}';
      if (page == 1 || _searchKey != key) {
        _searchCursor = null;
        _searchKey = key;
      }
      final cursor = page > 1 ? _searchCursor : null;
      if (page > 1 && cursor == null) {
        return LibraryListResult(success: true, items: const []);
      }

      final data = await TajiriGraphqlClient.instance.query(
        '''
        query LibraryBooks(\$category: String, \$search: String, \$cursor: String) {
          libraryBooks(category: \$category, search: \$search, cursor: \$cursor) {
            items { $_bookFields }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          if (category != null && category.isNotEmpty) 'category': category,
          if (query != null && query.isNotEmpty) 'search': query,
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final conn = data['libraryBooks'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => LibraryBook.fromJson(_bookToLegacy(row)))
          .toList();
      if (conn['hasMore'] == true && conn['nextCursor'] != null) {
        _searchCursor = conn['nextCursor'].toString();
      }
      return LibraryListResult(success: true, items: items);
    } catch (e) {
      return LibraryListResult(
        success: false,
        message: 'Imeshindwa kupakia: $e',
      );
    }
  }

  static Future<LibraryResult<LibraryBook>> getBook(int bookId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query LibraryBook(\$id: ID!) {
          libraryBook(id: \$id) {
            $_bookFields
          }
        }
        ''',
        variables: {'id': bookId.toString()},
        auth: true,
      );
      final row = data['libraryBook'] as Map<String, dynamic>?;
      if (row == null) {
        return LibraryResult(success: false, message: 'Kitabu hakipatikani');
      }
      return LibraryResult(
        success: true,
        data: LibraryBook.fromJson(_bookToLegacy(row)),
      );
    } catch (e) {
      return LibraryResult(success: false, message: '$e');
    }
  }

  static Future<LibraryResult<void>> borrowBook(int bookId) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ToggleBookBorrow(\$bookId: ID!) {
          toggleBookBorrow(bookId: \$bookId) {
            id
            isBorrowed
          }
        }
        ''',
        variables: {'bookId': bookId.toString()},
        auth: true,
      );
      return LibraryResult(success: true);
    } catch (e) {
      return LibraryResult(success: false, message: '$e');
    }
  }

  static Future<LibraryResult<void>> bookmarkBook(int bookId) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ToggleBookBookmark(\$bookId: ID!) {
          toggleBookBookmark(bookId: \$bookId) {
            id
            isBookmarked
          }
        }
        ''',
        variables: {'bookId': bookId.toString()},
        auth: true,
      );
      return LibraryResult(success: true);
    } catch (e) {
      return LibraryResult(success: false, message: '$e');
    }
  }

  static Future<LibraryListResult<LibraryBook>> getMyBookshelf() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyBookshelf {
          myBookshelf {
            $_bookFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myBookshelf'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => LibraryBook.fromJson(_bookToLegacy(row)))
          .toList();
      return LibraryListResult(success: true, items: items);
    } catch (e) {
      return LibraryListResult(success: false, message: '$e');
    }
  }

  static Map<String, dynamic> _readingListToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'name': row['name'],
      'course_code': row['courseCode'],
      'book_count': row['bookCount'] ?? 0,
      'completed_count': row['completedCount'] ?? 0,
      'created_at': row['createdAt'],
    };
  }

  static Future<LibraryListResult<ReadingList>> getReadingLists() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyReadingLists {
          myReadingLists {
            id
            name
            courseCode
            bookCount
            completedCount
            createdAt
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myReadingLists'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => ReadingList.fromJson(_readingListToLegacy(row)))
          .toList();
      return LibraryListResult(success: true, items: items);
    } catch (e) {
      return LibraryListResult(
        success: false,
        message: 'Imeshindwa kupakia orodha: $e',
      );
    }
  }
}
