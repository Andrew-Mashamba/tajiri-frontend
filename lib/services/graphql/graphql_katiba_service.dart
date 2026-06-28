import '../../katiba/models/katiba_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL Tanzania Constitution reference (Phase 94 — backend rev 216).
/// Quiz, amendments, and glossary remain REST-only.
class GraphqlKatibaService {
  static Map<String, dynamic> _chapterToLegacy(Map<String, dynamic> row) {
    final title = row['title']?.toString() ?? '';
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'number': int.tryParse(row['number']?.toString() ?? '') ?? 0,
      'title_sw': title,
      'title_en': title,
      'article_count': int.tryParse(row['articleCount']?.toString() ?? '') ?? 0,
    };
  }

  static Map<String, dynamic> _articleToLegacy(Map<String, dynamic> row) {
    final title = row['title']?.toString() ?? '';
    final body = row['body']?.toString() ?? '';
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'number': int.tryParse(row['number']?.toString() ?? '') ?? 0,
      'chapter_id': int.tryParse(row['chapterId']?.toString() ?? '') ?? 0,
      'text_sw': body,
      'text_en': body,
      'summary_sw': title,
      'summary_en': title,
    };
  }

  static Map<String, dynamic> _searchHitToLegacy(Map<String, dynamic> row) {
    if (row['hitType']?.toString() == 'chapter') {
      return _chapterToLegacy({
        'id': row['id'],
        'number': row['number'],
        'title': row['title'],
        'articleCount': 0,
      });
    }
    return _articleToLegacy({
      'id': row['id'],
      'number': row['number'],
      'chapterId': row['chapterId'],
      'title': row['title'],
      'body': row['snippet'],
    });
  }

  static Future<PaginatedResult<Chapter>> getChapters() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query KatibaChapters {
          katibaChapters {
            id
            number
            title
            summary
            articleCount
          }
        }
        ''',
        auth: false,
      );
      final rows = data['katibaChapters'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => Chapter.fromJson(_chapterToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, total: items.length);
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  static Future<SingleResult<Article>> getArticle(int id) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query KatibaArticle(\$articleId: ID!) {
          katibaArticle(articleId: \$articleId) {
            id
            chapterId
            number
            title
            body
          }
        }
        ''',
        variables: {'articleId': id.toString()},
        auth: false,
      );
      final row = data['katibaArticle'] as Map<String, dynamic>?;
      if (row == null) {
        return SingleResult(message: 'Not found');
      }
      return SingleResult(
        success: true,
        data: Article.fromJson(_articleToLegacy(row)),
      );
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  static Future<PaginatedResult<Article>> searchArticles(
    String query, {
    int page = 1,
  }) async {
    if (page > 1) {
      return PaginatedResult(
        success: true,
        items: const [],
        page: page,
      );
    }
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query KatibaSearch(\$query: String!) {
          katibaSearch(query: \$query) {
            hitType
            id
            chapterId
            number
            title
            snippet
          }
        }
        ''',
        variables: {'query': query},
        auth: false,
      );
      final rows = data['katibaSearch'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .where((row) => row['hitType']?.toString() == 'article')
          .map((row) => Article.fromJson(_searchHitToLegacy(row)))
          .toList();
      return PaginatedResult(
        success: true,
        items: items,
        total: items.length,
        page: page,
      );
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  static Future<SingleResult<Chapter>> getChapter(int chapterId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query KatibaChapter(\$chapterId: ID!) {
          katibaChapter(chapterId: \$chapterId) {
            id
            number
            title
            summary
            articleCount
          }
        }
        ''',
        variables: {'chapterId': chapterId.toString()},
        auth: false,
      );
      final row = data['katibaChapter'] as Map<String, dynamic>?;
      if (row == null) {
        return SingleResult(message: 'Not found');
      }
      return SingleResult(
        success: true,
        data: Chapter.fromJson(_chapterToLegacy(row)),
      );
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  static Future<PaginatedResult<Article>> getChapterArticles(int chapterId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query KatibaArticles(\$chapterId: ID!) {
          katibaArticles(chapterId: \$chapterId) {
            id
            chapterId
            number
            title
            body
          }
        }
        ''',
        variables: {'chapterId': chapterId.toString()},
        auth: false,
      );
      final rows = data['katibaArticles'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => Article.fromJson(_articleToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, total: items.length);
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  static Future<SingleResult<Article>> getDailyArticle() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query KatibaDailyArticle {
          katibaDailyArticle {
            id
            chapterId
            number
            title
            body
          }
        }
        ''',
        auth: false,
      );
      final row = data['katibaDailyArticle'] as Map<String, dynamic>?;
      if (row == null) {
        return SingleResult(message: 'Not found');
      }
      return SingleResult(
        success: true,
        data: Article.fromJson(_articleToLegacy(row)),
      );
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }
}
