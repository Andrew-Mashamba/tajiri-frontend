import '../../news/models/news_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL news articles (Phase 70 — backend rev 034).
class GraphqlNewsService {
  static const _articleFields = r'''
    id
    title
    summary
    content
    imageUrl
    source
    sourceUrl
    author
    category
    readTimeMinutes
    isTopStory
    isSaved
    publishedAt
  ''';

  static final Map<String, Map<int, String?>> _articleCursors = {};
  static final Map<String, String?> _savedCursors = {};

  static String _articlesKey({NewsCategory? category, String? search}) =>
      'articles:${category?.name ?? 'all'}:${search ?? ''}';

  static Map<String, dynamic> _articleToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'title': row['title'],
      'summary': row['summary'],
      'content': row['content'],
      'image_url': row['imageUrl'],
      'source': row['source'],
      'source_url': row['sourceUrl'],
      'author': row['author'],
      'category': row['category'],
      'read_time_minutes': row['readTimeMinutes'],
      'is_saved': row['isSaved'],
      'published_at': row['publishedAt'],
    };
  }

  static NewsArticle _parseArticle(Map<String, dynamic> row) {
    return NewsArticle.fromJson(_articleToLegacy(row));
  }

  static Future<NewsListResult<NewsArticle>> getArticles({
    NewsCategory? category,
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final key = _articlesKey(category: category, search: search);
      if (page == 1) {
        _articleCursors[key] = {};
      }
      final cursor = page > 1 ? _articleCursors[key]?[page] : null;
      if (page > 1 && cursor == null) {
        return NewsListResult(success: true, items: const []);
      }

      final data = await TajiriGraphqlClient.instance.query(
        '''
        query NewsArticles(\$cursor: String, \$category: String, \$search: String) {
          newsArticles(cursor: \$cursor, category: \$category, search: \$search) {
            items {
              $_articleFields
            }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          if (cursor != null) 'cursor': cursor,
          if (category != null) 'category': category.name,
          if (search != null && search.isNotEmpty) 'search': search,
        },
        auth: false,
      );
      final conn = data['newsArticles'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map(_parseArticle)
          .toList();
      final hasMore = conn['hasMore'] == true;
      final nextCursor = conn['nextCursor']?.toString();
      _articleCursors.putIfAbsent(key, () => {});
      if (hasMore && nextCursor != null) {
        _articleCursors[key]![page + 1] = nextCursor;
      }
      return NewsListResult(success: true, items: items);
    } catch (e) {
      return NewsListResult(
        success: false,
        message: 'Imeshindwa kupakia habari',
      );
    }
  }

  static Future<NewsResult<NewsArticle>> getArticle(int articleId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query NewsArticle(\$id: ID!) {
          newsArticle(id: \$id) {
            $_articleFields
          }
        }
        ''',
        variables: {'id': articleId.toString()},
        auth: false,
      );
      final row = data['newsArticle'] as Map<String, dynamic>?;
      if (row == null) {
        return NewsResult(success: false, message: 'Imeshindwa kupakia makala');
      }
      return NewsResult(success: true, data: _parseArticle(row));
    } catch (e) {
      return NewsResult(success: false, message: 'Imeshindwa kupakia makala');
    }
  }

  static Future<NewsListResult<NewsArticle>> getTopStories() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query NewsTopStories {
          newsTopStories {
            $_articleFields
          }
        }
        ''',
        auth: false,
      );
      final rows = data['newsTopStories'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map(_parseArticle)
          .toList();
      return NewsListResult(success: true, items: items);
    } catch (_) {
      return NewsListResult(success: false);
    }
  }

  static Future<NewsResult<void>> saveArticle({required int articleId}) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SaveNewsArticle(\$articleId: ID!) {
          saveNewsArticle(articleId: \$articleId) {
            id
          }
        }
        ''',
        variables: {'articleId': articleId.toString()},
        auth: true,
      );
      if (result['saveNewsArticle'] != null) {
        return NewsResult(success: true);
      }
      return NewsResult(success: false, message: 'Imeshindwa kuhifadhi');
    } catch (e) {
      return NewsResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<NewsListResult<NewsArticle>> getSavedArticles({
    int page = 1,
  }) async {
    try {
      if (page == 1) {
        _savedCursors.clear();
      }
      final cursor = page > 1 ? _savedCursors['page_$page'] : null;
      if (page > 1 && cursor == null) {
        return NewsListResult(success: true, items: const []);
      }

      final data = await TajiriGraphqlClient.instance.query(
        '''
        query SavedNewsArticles(\$cursor: String) {
          savedNewsArticles(cursor: \$cursor) {
            items {
              $_articleFields
            }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {if (cursor != null) 'cursor': cursor},
        auth: true,
      );
      final conn = data['savedNewsArticles'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map(_parseArticle)
          .toList();
      final hasMore = conn['hasMore'] == true;
      final nextCursor = conn['nextCursor']?.toString();
      if (hasMore && nextCursor != null) {
        _savedCursors['page_${page + 1}'] = nextCursor;
      }
      return NewsListResult(success: true, items: items);
    } catch (_) {
      return NewsListResult(success: false);
    }
  }
}
