// lib/exam_prep/services/exam_prep_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/exam_prep_models.dart';

class ExamPrepService {
  Dio get _dio => AuthenticatedDio.instance;

  // ─── Flashcard Decks ──────────────────────────────────────

  Future<PrepListResult<FlashcardDeck>> getDecks() async {
    try {
      final res = await _dio.get('/education/flashcards/decks');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => FlashcardDeck.fromJson(j))
            .toList();
        return PrepListResult(success: true, items: items);
      }
      return PrepListResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return PrepListResult(success: false, message: '$e');
    }
  }

  Future<PrepResult<FlashcardDeck>> createDeck({
    required String name,
    required String subject,
    String? courseCode,
    bool isPublic = false,
  }) async {
    try {
      final res = await _dio.post('/education/flashcards/decks', data: {
        'name': name,
        'subject': subject,
        if (courseCode != null) 'course_code': courseCode,
        'is_public': isPublic,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        return PrepResult(
          success: true,
          data: FlashcardDeck.fromJson(res.data['data']),
        );
      }
      return PrepResult(success: false, message: 'Imeshindwa kuunda');
    } catch (e) {
      return PrepResult(success: false, message: '$e');
    }
  }

  // ─── Flashcards ───────────────────────────────────────────

  Future<PrepListResult<Flashcard>> getCards(int deckId) async {
    try {
      final res = await _dio.get('/education/flashcards/decks/$deckId/cards');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => Flashcard.fromJson(j))
            .toList();
        return PrepListResult(success: true, items: items);
      }
      return PrepListResult(success: false);
    } catch (e) {
      return PrepListResult(success: false, message: '$e');
    }
  }

  Future<PrepResult<Flashcard>> addCard({
    required int deckId,
    required String front,
    required String back,
  }) async {
    try {
      final res = await _dio.post(
        '/education/flashcards/decks/$deckId/cards',
        data: {'front': front, 'back': back},
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        return PrepResult(
          success: true,
          data: Flashcard.fromJson(res.data['data']),
        );
      }
      return PrepResult(success: false);
    } catch (e) {
      return PrepResult(success: false, message: '$e');
    }
  }

  Future<PrepResult<void>> updateCardConfidence({
    required int cardId,
    required int confidence,
  }) async {
    try {
      final res = await _dio.put(
        '/education/flashcards/cards/$cardId/confidence',
        data: {'confidence': confidence},
      );
      return PrepResult(success: res.statusCode == 200);
    } catch (e) {
      return PrepResult(success: false, message: '$e');
    }
  }

  // ─── Quiz ─────────────────────────────────────────────────

  Future<PrepListResult<QuizQuestion>> generateQuiz({
    required String subject,
    int count = 10,
  }) async {
    try {
      final res = await _dio.post('/education/quiz/generate', data: {
        'subject': subject,
        'count': count,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => QuizQuestion.fromJson(j))
            .toList();
        return PrepListResult(success: true, items: items);
      }
      return PrepListResult(success: false);
    } catch (e) {
      return PrepListResult(success: false, message: '$e');
    }
  }

  // ─── Exam Countdown ──────────────────────────────────────

  Future<PrepListResult<ExamCountdown>> getExamCountdowns() async {
    try {
      final res = await _dio.get('/education/exams/countdown');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => ExamCountdown.fromJson(j))
            .toList();
        return PrepListResult(success: true, items: items);
      }
      return PrepListResult(success: false);
    } catch (e) {
      return PrepListResult(success: false, message: '$e');
    }
  }

  Future<PrepResult<ExamCountdown>> addExamCountdown({
    required String subject,
    String? courseCode,
    required DateTime examDate,
    String? venue,
  }) async {
    try {
      final res = await _dio.post('/education/exams/countdown', data: {
        'subject': subject,
        if (courseCode != null) 'course_code': courseCode,
        'exam_date': examDate.toIso8601String(),
        if (venue != null) 'venue': venue,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        return PrepResult(
          success: true,
          data: ExamCountdown.fromJson(res.data['data']),
        );
      }
      return PrepResult(success: false);
    } catch (e) {
      return PrepResult(success: false, message: '$e');
    }
  }

  // ─── Study Sessions ──────────────────────────────────────

  Future<PrepResult<void>> logStudySession({
    required String subject,
    required int durationMinutes,
  }) async {
    try {
      final res = await _dio.post('/education/study-sessions', data: {
        'subject': subject,
        'duration_minutes': durationMinutes,
      });
      return PrepResult(success: res.statusCode == 200);
    } catch (e) {
      return PrepResult(success: false, message: '$e');
    }
  }
}
