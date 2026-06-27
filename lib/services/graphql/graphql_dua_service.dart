import '../../dua/models/dua_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL duas & adhkar (Phase 71 — backend rev 202).
class GraphqlDuaService {
  static const _categoryFields = r'''
    id
    name
    nameSwahili
    icon
    duaCount
  ''';

  static const _duaFields = r'''
    id
    categoryId
    titleArabic
    titleSwahili
    titleEnglish
    textArabic
    transliteration
    translationSwahili
    translationEnglish
    source
    sourceRef
    audioUrl
    repeatCount
    isFavorite
  ''';

  static const _adhkarFields = r'''
    id
    textArabic
    translationSwahili
    transliteration
    repeatTarget
    type
  ''';

  static final Map<int, Map<int, String?>> _categoryCursors = {};

  static Map<String, dynamic> _categoryToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'name': row['name'],
      'name_sw': row['nameSwahili'],
      'icon': row['icon'],
      'dua_count': row['duaCount'],
    };
  }

  static Map<String, dynamic> _duaToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'category_id': int.tryParse(row['categoryId']?.toString() ?? '') ?? 0,
      'title_ar': row['titleArabic'],
      'title_sw': row['titleSwahili'],
      'title_en': row['titleEnglish'],
      'text_arabic': row['textArabic'],
      'transliteration': row['transliteration'],
      'translation_sw': row['translationSwahili'],
      'translation_en': row['translationEnglish'],
      'source': row['source'],
      'source_ref': row['sourceRef'],
      'audio_url': row['audioUrl'],
      'repeat_count': row['repeatCount'],
      'is_favorite': row['isFavorite'],
    };
  }

  static Map<String, dynamic> _adhkarToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'text_arabic': row['textArabic'],
      'translation_sw': row['translationSwahili'],
      'transliteration': row['transliteration'],
      'repeat_target': row['repeatTarget'],
      'type': row['type'],
    };
  }

  static Future<PaginatedResult<DuaCategory>> getCategories() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query DuaCategories {
          duaCategories {
            $_categoryFields
          }
        }
        ''',
        auth: false,
      );
      final rows = data['duaCategories'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => DuaCategory.fromJson(_categoryToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, total: items.length);
    } catch (e) {
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia makundi');
    }
  }

  static Future<PaginatedResult<Dua>> getDuasByCategory({
    required int categoryId,
    int page = 1,
  }) async {
    try {
      if (page == 1) {
        _categoryCursors[categoryId] = {};
      }
      final cursor = page > 1 ? _categoryCursors[categoryId]?[page] : null;
      if (page > 1 && cursor == null) {
        return PaginatedResult(success: true, items: const []);
      }

      final data = await TajiriGraphqlClient.instance.query(
        '''
        query DuasByCategory(\$categoryId: ID!, \$cursor: String) {
          duasByCategory(categoryId: \$categoryId, cursor: \$cursor) {
            $_duaFields
          }
        }
        ''',
        variables: {
          'categoryId': categoryId.toString(),
          if (cursor != null) 'cursor': cursor,
        },
        auth: false,
      );
      final rows = data['duasByCategory'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => Dua.fromJson(_duaToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, total: items.length);
    } catch (e) {
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia dua');
    }
  }

  static Future<PaginatedResult<AdhkarItem>> getAdhkar({
    required String type,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query Adhkar(\$type: String!) {
          adhkar(type: \$type) {
            $_adhkarFields
          }
        }
        ''',
        variables: {'type': type},
        auth: false,
      );
      final rows = data['adhkar'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => AdhkarItem.fromJson(_adhkarToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, total: items.length);
    } catch (e) {
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia adhkar');
    }
  }

  static Future<PaginatedResult<Dua>> getFavorites() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyFavoriteDuas {
          myFavoriteDuas {
            $_duaFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myFavoriteDuas'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => Dua.fromJson(_duaToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, total: items.length);
    } catch (e) {
      return PaginatedResult(success: false, message: 'Imeshindwa kupakia');
    }
  }

  static Future<SingleResult<bool>> toggleFavorite({required int duaId}) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ToggleDuaFavorite(\$duaId: ID!) {
          toggleDuaFavorite(duaId: \$duaId) {
            isFavorite
          }
        }
        ''',
        variables: {'duaId': duaId.toString()},
        auth: true,
      );
      final row = result['toggleDuaFavorite'] as Map<String, dynamic>?;
      return SingleResult(
        success: row != null,
        data: row?['isFavorite'] == true,
      );
    } catch (e) {
      return SingleResult(success: false, message: 'Imeshindwa');
    }
  }

  static Future<PaginatedResult<Dua>> search({required String query}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query DuaSearch(\$query: String!) {
          duaSearch(query: \$query) {
            $_duaFields
          }
        }
        ''',
        variables: {'query': query},
        auth: false,
      );
      final rows = data['duaSearch'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => Dua.fromJson(_duaToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, total: items.length);
    } catch (e) {
      return PaginatedResult(success: false, message: 'Hakuna matokeo');
    }
  }
}
