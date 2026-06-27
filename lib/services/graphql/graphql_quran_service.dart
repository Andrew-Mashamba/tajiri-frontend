import '../../quran/models/quran_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL Quran reader (Phase 71 — backend rev 201).
class GraphqlQuranService {
  static const _surahFields = r'''
    number
    nameArabic
    nameSwahili
    nameEnglish
    revelationType
    ayahCount
    juzStart
  ''';

  static const _ayahFields = r'''
    id
    surahNumber
    ayahNumber
    textArabic
    translationSwahili
    translationEnglish
    transliteration
    juz
    page
    audioUrl
  ''';

  static const _juzFields = r'''
    number
    nameArabic
    startSurah
    startAyah
    endSurah
    endAyah
  ''';

  static const _bookmarkFields = r'''
    id
    surahNumber
    ayahNumber
    label
    createdAt
  ''';

  static const _reciterFields = r'''
    id
    name
    style
    imageUrl
  ''';

  static Map<String, dynamic> _surahToLegacy(Map<String, dynamic> row) {
    return {
      'number': row['number'],
      'name_arabic': row['nameArabic'],
      'name_sw': row['nameSwahili'],
      'name_en': row['nameEnglish'],
      'revelation_type': row['revelationType'],
      'ayah_count': row['ayahCount'],
      'juz_start': row['juzStart'],
    };
  }

  static Map<String, dynamic> _ayahToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'surah_number': row['surahNumber'],
      'ayah_number': row['ayahNumber'],
      'text_arabic': row['textArabic'],
      'translation_sw': row['translationSwahili'],
      'translation_en': row['translationEnglish'],
      'transliteration': row['transliteration'],
      'juz': row['juz'],
      'page': row['page'],
      'audio_url': row['audioUrl'],
    };
  }

  static Map<String, dynamic> _juzToLegacy(Map<String, dynamic> row) {
    return {
      'number': row['number'],
      'name_arabic': row['nameArabic'],
      'start_surah': row['startSurah'],
      'start_ayah': row['startAyah'],
      'end_surah': row['endSurah'],
      'end_ayah': row['endAyah'],
    };
  }

  static Map<String, dynamic> _bookmarkToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'surah_number': row['surahNumber'],
      'ayah_number': row['ayahNumber'],
      'label': row['label'],
      'created_at': row['createdAt'],
    };
  }

  static Map<String, dynamic> _reciterToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'name': row['name'],
      'style': row['style'],
      'image_url': row['imageUrl'],
    };
  }

  static Future<PaginatedResult<Surah>> getSurahs() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query QuranSurahs {
          quranSurahs {
            $_surahFields
          }
        }
        ''',
        auth: false,
      );
      final rows = data['quranSurahs'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => Surah.fromJson(_surahToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, total: items.length);
    } catch (e) {
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia sura');
    }
  }

  static Future<PaginatedResult<Ayah>> getAyahs({
    required int surahNumber,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query QuranAyahs(\$surahNumber: Int!, \$page: Int!, \$perPage: Int!) {
          quranAyahs(surahNumber: \$surahNumber, page: \$page, perPage: \$perPage) {
            items {
              $_ayahFields
            }
            currentPage
            lastPage
            total
          }
        }
        ''',
        variables: {
          'surahNumber': surahNumber,
          'page': page,
          'perPage': perPage,
        },
        auth: false,
      );
      final conn = data['quranAyahs'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => Ayah.fromJson(_ayahToLegacy(row)))
          .toList();
      return PaginatedResult(
        success: true,
        items: items,
        currentPage: (conn['currentPage'] as num?)?.toInt() ?? page,
        lastPage: (conn['lastPage'] as num?)?.toInt() ?? 1,
        total: (conn['total'] as num?)?.toInt() ?? items.length,
      );
    } catch (e) {
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia aya');
    }
  }

  static Future<PaginatedResult<Juz>> getJuzList() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query QuranJuz {
          quranJuz {
            $_juzFields
          }
        }
        ''',
        auth: false,
      );
      final rows = data['quranJuz'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => Juz.fromJson(_juzToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, total: items.length);
    } catch (e) {
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia juz');
    }
  }

  static Future<PaginatedResult<Ayah>> search({
    required String query,
    String language = 'sw',
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query QuranSearch(\$query: String!, \$language: String!) {
          quranSearch(query: \$query, language: \$language) {
            $_ayahFields
          }
        }
        ''',
        variables: {'query': query, 'language': language},
        auth: false,
      );
      final rows = data['quranSearch'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => Ayah.fromJson(_ayahToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, total: items.length);
    } catch (e) {
      return PaginatedResult(success: false, message: 'Hakuna matokeo');
    }
  }

  static Future<PaginatedResult<QuranBookmark>> getBookmarks() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyQuranBookmarks {
          myQuranBookmarks {
            $_bookmarkFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myQuranBookmarks'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => QuranBookmark.fromJson(_bookmarkToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, total: items.length);
    } catch (e) {
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia alama');
    }
  }

  static Future<SingleResult<QuranBookmark>> addBookmark(
    QuranBookmark bookmark,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation AddQuranBookmark(\$input: AddQuranBookmarkInput!) {
          addQuranBookmark(input: \$input) {
            $_bookmarkFields
          }
        }
        ''',
        variables: {
          'input': {
            'surahNumber': bookmark.surahNumber,
            'ayahNumber': bookmark.ayahNumber,
            if (bookmark.label != null) 'label': bookmark.label,
          },
        },
        auth: true,
      );
      final row = result['addQuranBookmark'] as Map<String, dynamic>?;
      if (row == null) {
        return SingleResult(success: false, message: 'Imeshindwa kuhifadhi');
      }
      return SingleResult(
        success: true,
        data: QuranBookmark.fromJson(_bookmarkToLegacy(row)),
      );
    } catch (e) {
      return SingleResult(success: false, message: 'Imeshindwa kuhifadhi');
    }
  }

  static Future<PaginatedResult<Reciter>> getReciters() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query QuranReciters {
          quranReciters {
            $_reciterFields
          }
        }
        ''',
        auth: false,
      );
      final rows = data['quranReciters'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => Reciter.fromJson(_reciterToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, total: items.length);
    } catch (e) {
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia wasomaji');
    }
  }
}
