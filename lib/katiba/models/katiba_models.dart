// lib/katiba/models/katiba_models.dart
import '../../config/api_config.dart';

// ─── Parse helpers ──────────────────────────────────────────────
int _parseInt(dynamic v, [int fallback = 0]) =>
    (v is num) ? v.toInt() : int.tryParse('$v') ?? fallback;

String _buildUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return ApiConfig.sanitizeUrl(path) ?? path;
  return '${ApiConfig.storageUrl}/$path';
}

// ─── Result wrappers ────────────────────────────────────────────
class SingleResult<T> {
  final bool success;
  final T? data;
  final String message;
  SingleResult({this.success = false, this.data, this.message = ''});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final int total;
  final int page;
  final String message;
  PaginatedResult({
    this.success = false,
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.message = '',
  });
}

// ─── Chapter ────────────────────────────────────────────────────
class Chapter {
  final int id;
  final int number;
  final String titleSw;
  final String titleEn;
  final int articleCount;
  final List<Article> articles;

  Chapter({
    required this.id,
    this.number = 0,
    this.titleSw = '',
    this.titleEn = '',
    this.articleCount = 0,
    this.articles = const [],
  });

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        id: _parseInt(json['id']),
        number: _parseInt(json['number']),
        titleSw: json['title_sw'] as String? ?? '',
        titleEn: json['title_en'] as String? ?? '',
        articleCount: _parseInt(json['article_count']),
        articles: (json['articles'] as List?)
                ?.map((e) => Article.fromJson(e))
                .toList() ??
            [],
      );
}

// ─── Article ────────────────────────────────────────────────────
class Article {
  final int id;
  final int number;
  final int chapterId;
  final String textSw;
  final String textEn;
  final String summarySw;
  final String summaryEn;
  final String audioUrl;

  Article({
    required this.id,
    this.number = 0,
    this.chapterId = 0,
    this.textSw = '',
    this.textEn = '',
    this.summarySw = '',
    this.summaryEn = '',
    this.audioUrl = '',
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: _parseInt(json['id']),
        number: _parseInt(json['number']),
        chapterId: _parseInt(json['chapter_id']),
        textSw: json['text_sw'] as String? ?? '',
        textEn: json['text_en'] as String? ?? '',
        summarySw: json['summary_sw'] as String? ?? '',
        summaryEn: json['summary_en'] as String? ?? '',
        audioUrl: _buildUrl(json['audio_url'] as String?),
      );
}

// ─── Bookmark ───────────────────────────────────────────────────
class Bookmark {
  final int id;
  final int articleId;
  final String note;
  final String createdAt;

  Bookmark({
    required this.id,
    this.articleId = 0,
    this.note = '',
    this.createdAt = '',
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        id: _parseInt(json['id']),
        articleId: _parseInt(json['article_id']),
        note: json['note'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );
}

// ─── Amendment ──────────────────────────────────────────────────
class Amendment {
  final int id;
  final int number;
  final int year;
  final String description;
  final List<int> changedArticles;

  Amendment({
    required this.id,
    this.number = 0,
    this.year = 0,
    this.description = '',
    this.changedArticles = const [],
  });

  factory Amendment.fromJson(Map<String, dynamic> json) => Amendment(
        id: _parseInt(json['id']),
        number: _parseInt(json['number']),
        year: _parseInt(json['year']),
        description: json['description'] as String? ?? '',
        changedArticles: (json['changed_articles'] as List?)
                ?.map((e) => _parseInt(e))
                .toList() ??
            [],
      );
}

// ─── Quiz Question ──────────────────────────────────────────────
class QuizQuestion {
  final int id;
  final String questionSw;
  final String questionEn;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  QuizQuestion({
    required this.id,
    this.questionSw = '',
    this.questionEn = '',
    this.options = const [],
    this.correctIndex = 0,
    this.explanation = '',
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        id: _parseInt(json['id']),
        questionSw: json['question_sw'] as String? ?? '',
        questionEn: json['question_en'] as String? ?? '',
        options: (json['options'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        correctIndex: _parseInt(json['correct_index']),
        explanation: json['explanation'] as String? ?? '',
      );
}

// ─── Quiz Result ────────────────────────────────────────────────
class QuizResult {
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercent;
  final String badge;

  QuizResult({
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    this.scorePercent = 0,
    this.badge = '',
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
        totalQuestions: _parseInt(json['total_questions']),
        correctAnswers: _parseInt(json['correct_answers']),
        scorePercent:
            ((json['score_percent'] as num?)?.toDouble() ?? 0),
        badge: json['badge'] as String? ?? '',
      );
}

// ─── Glossary Term ──────────────────────────────────────────────
class GlossaryTerm {
  final int id;
  final String termSw;
  final String termEn;
  final String definitionSw;
  final String definitionEn;

  GlossaryTerm({
    required this.id,
    this.termSw = '',
    this.termEn = '',
    this.definitionSw = '',
    this.definitionEn = '',
  });

  factory GlossaryTerm.fromJson(Map<String, dynamic> json) => GlossaryTerm(
        id: _parseInt(json['id']),
        termSw: json['term_sw'] as String? ?? '',
        termEn: json['term_en'] as String? ?? '',
        definitionSw: json['definition_sw'] as String? ?? '',
        definitionEn: json['definition_en'] as String? ?? '',
      );
}
