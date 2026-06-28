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

  static Map<String, dynamic> _amendmentToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'number': int.tryParse(row['number']?.toString() ?? '') ?? 0,
      'year': int.tryParse(row['year']?.toString() ?? '') ?? 0,
      'description': row['description'] ?? '',
      'changed_articles': (row['changedArticles'] as List<dynamic>? ?? [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .toList(),
    };
  }

  static Map<String, dynamic> _quizQuestionToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'question_sw': row['questionSw'] ?? '',
      'question_en': row['questionEn'] ?? '',
      'options': (row['options'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      'correct_index': int.tryParse(row['correctIndex']?.toString() ?? '') ?? 0,
      'explanation': row['explanation'] ?? '',
    };
  }

  static Map<String, dynamic> _glossaryToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'term_sw': row['termSw'] ?? '',
      'term_en': row['termEn'] ?? '',
      'definition_sw': row['definitionSw'] ?? '',
      'definition_en': row['definitionEn'] ?? '',
    };
  }

  static Future<PaginatedResult<Amendment>> getAmendments() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query KatibaAmendments {
          katibaAmendments {
            id
            number
            year
            description
            changedArticles
          }
        }
        ''',
        auth: false,
      );
      final rows = data['katibaAmendments'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => Amendment.fromJson(_amendmentToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, total: items.length);
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  static Future<PaginatedResult<QuizQuestion>> getQuiz({int? chapterId}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query KatibaQuiz(\$chapterId: ID) {
          katibaQuiz(chapterId: \$chapterId) {
            id
            chapterId
            questionSw
            questionEn
            options
            correctIndex
            explanation
          }
        }
        ''',
        variables: {
          if (chapterId != null) 'chapterId': chapterId.toString(),
        },
        auth: false,
      );
      final rows = data['katibaQuiz'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => QuizQuestion.fromJson(_quizQuestionToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, total: items.length);
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  static Future<SingleResult<QuizResult>> submitQuizScore(
    Map<String, dynamic> data,
  ) async {
    try {
      final total = int.tryParse(data['total_questions']?.toString() ?? '') ??
          int.tryParse(data['totalQuestions']?.toString() ?? '') ??
          0;
      final correct = int.tryParse(data['correct_answers']?.toString() ?? '') ??
          int.tryParse(data['correctAnswers']?.toString() ?? '') ??
          0;
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SubmitKatibaQuizScore(\$totalQuestions: Int!, \$correctAnswers: Int!) {
          submitKatibaQuizScore(
            totalQuestions: \$totalQuestions
            correctAnswers: \$correctAnswers
          ) {
            totalQuestions
            correctAnswers
            scorePercent
            badge
          }
        }
        ''',
        variables: {
          'totalQuestions': total,
          'correctAnswers': correct,
        },
        auth: false,
      );
      final row = result['submitKatibaQuizScore'] as Map<String, dynamic>?;
      if (row == null) {
        return SingleResult(message: 'Failed');
      }
      return SingleResult(
        success: true,
        data: QuizResult.fromJson({
          'total_questions': row['totalQuestions'],
          'correct_answers': row['correctAnswers'],
          'score_percent': row['scorePercent'],
          'badge': row['badge'],
        }),
      );
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  static Future<PaginatedResult<GlossaryTerm>> getGlossary() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query KatibaGlossary {
          katibaGlossary {
            id
            termSw
            termEn
            definitionSw
            definitionEn
          }
        }
        ''',
        auth: false,
      );
      final rows = data['katibaGlossary'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => GlossaryTerm.fromJson(_glossaryToLegacy(row)))
          .toList();
      return PaginatedResult(success: true, items: items, total: items.length);
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }
}
