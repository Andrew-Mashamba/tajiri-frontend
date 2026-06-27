import '../../hadith/models/hadith_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL hadith library (Phase 71 — backend rev 203).
class GraphqlHadithService {
  static const _collectionFields = r'''
    id
    name
    nameArabic
    nameSwahili
    author
    hadithCount
    bookCount
    imageUrl
  ''';

  static const _bookFields = r'''
    id
    collectionId
    name
    nameArabic
    hadithCount
  ''';

  static const _hadithFields = r'''
    id
    collectionId
    bookId
    hadithNumber
    textArabic
    translationSwahili
    translationEnglish
    narrator
    grade
    gradeScholar
    isnad
    topic
    isFavorite
  ''';

  static Map<String, dynamic> _collectionToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'name': row['name'],
      'name_arabic': row['nameArabic'],
      'name_sw': row['nameSwahili'],
      'author': row['author'],
      'hadith_count': row['hadithCount'],
      'book_count': row['bookCount'],
      'image_url': row['imageUrl'],
    };
  }

  static Map<String, dynamic> _bookToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'collection_id': int.tryParse(row['collectionId']?.toString() ?? '') ?? 0,
      'name': row['name'],
      'name_arabic': row['nameArabic'],
      'hadith_count': row['hadithCount'],
    };
  }

  static Map<String, dynamic> _hadithToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'collection_id': int.tryParse(row['collectionId']?.toString() ?? '') ?? 0,
      'book_id': int.tryParse(row['bookId']?.toString() ?? '') ?? 0,
      'hadith_number': row['hadithNumber'],
      'text_arabic': row['textArabic'],
      'translation_sw': row['translationSwahili'],
      'translation_en': row['translationEnglish'],
      'narrator': row['narrator'],
      'grade': row['grade'],
      'grade_scholar': row['gradeScholar'],
      'isnad': row['isnad'],
      'topic': row['topic'],
      'is_favorite': row['isFavorite'],
    };
  }

  static Future<PaginatedResult<HadithCollection>> getCollections() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query HadithCollections {
          hadithCollections {
            $_collectionFields
          }
        }
        ''',
        auth: false,
      );
      final rows = data['hadithCollections'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => HadithCollection.fromJson(_collectionToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, total: items.length);
    } catch (e) {
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia');
    }
  }

  static Future<PaginatedResult<HadithBook>> getBooks({
    required int collectionId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query HadithBooks(\$collectionId: ID!) {
          hadithBooks(collectionId: \$collectionId) {
            $_bookFields
          }
        }
        ''',
        variables: {'collectionId': collectionId.toString()},
        auth: false,
      );
      final rows = data['hadithBooks'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => HadithBook.fromJson(_bookToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, total: items.length);
    } catch (e) {
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia vitabu');
    }
  }

  static Future<PaginatedResult<Hadith>> getHadiths({
    required int bookId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query HadithsByBook(\$bookId: ID!, \$page: Int!, \$perPage: Int!) {
          hadithsByBook(bookId: \$bookId, page: \$page, perPage: \$perPage) {
            items {
              $_hadithFields
            }
            currentPage
            lastPage
            total
          }
        }
        ''',
        variables: {
          'bookId': bookId.toString(),
          'page': page,
          'perPage': perPage,
        },
        auth: false,
      );
      final conn = data['hadithsByBook'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => Hadith.fromJson(_hadithToLegacy(row)))
          .toList();
      return PaginatedResult(
        success: true,
        items: items,
        currentPage: (conn['currentPage'] as num?)?.toInt() ?? page,
        lastPage: (conn['lastPage'] as num?)?.toInt() ?? 1,
        total: (conn['total'] as num?)?.toInt() ?? items.length,
      );
    } catch (e) {
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia hadith');
    }
  }

  static Future<SingleResult<Hadith>> getDailyHadith() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query DailyHadith {
          dailyHadith {
            $_hadithFields
          }
        }
        ''',
        auth: false,
      );
      final row = data['dailyHadith'] as Map<String, dynamic>?;
      if (row == null) {
        return SingleResult(success: false, message: 'Imeshindwa kupakia');
      }
      return SingleResult(
        success: true,
        data: Hadith.fromJson(_hadithToLegacy(row)),
      );
    } catch (e) {
      return SingleResult(success: false, message: 'Imeshindwa kupakia');
    }
  }

  static Future<PaginatedResult<Hadith>> search({required String query}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query HadithSearch(\$query: String!) {
          hadithSearch(query: \$query) {
            $_hadithFields
          }
        }
        ''',
        variables: {'query': query},
        auth: false,
      );
      final rows = data['hadithSearch'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => Hadith.fromJson(_hadithToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, total: items.length);
    } catch (e) {
      return PaginatedResult(success: false, message: 'Hakuna matokeo');
    }
  }

  static Future<SingleResult<bool>> toggleFavorite({
    required int hadithId,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ToggleHadithFavorite(\$hadithId: ID!) {
          toggleHadithFavorite(hadithId: \$hadithId) {
            isFavorite
          }
        }
        ''',
        variables: {'hadithId': hadithId.toString()},
        auth: true,
      );
      final row = result['toggleHadithFavorite'] as Map<String, dynamic>?;
      return SingleResult(
        success: row != null,
        data: row?['isFavorite'] == true,
      );
    } catch (e) {
      return SingleResult(success: false, message: 'Imeshindwa');
    }
  }
}
