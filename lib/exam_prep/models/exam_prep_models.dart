// lib/exam_prep/models/exam_prep_models.dart

// ─── Flashcard ───────────────────────────────────────────────

class Flashcard {
  final int id;
  final int deckId;
  final String front;
  final String back;
  final String? imageUrl;
  final int confidence; // 0=unknown, 1=learning, 2=known
  final DateTime? nextReview;
  final DateTime createdAt;

  Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    this.imageUrl,
    this.confidence = 0,
    this.nextReview,
    required this.createdAt,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: _parseInt(json['id']),
      deckId: _parseInt(json['deck_id']),
      front: json['front']?.toString() ?? '',
      back: json['back']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      confidence: _parseInt(json['confidence']),
      nextReview: DateTime.tryParse(json['next_review']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ─── FlashcardDeck ───────────────────────────────────────────

class FlashcardDeck {
  final int id;
  final String name;
  final String subject;
  final String? courseCode;
  final int cardCount;
  final int masteredCount;
  final int ownerId;
  final bool isPublic;
  final DateTime createdAt;

  FlashcardDeck({
    required this.id,
    required this.name,
    required this.subject,
    this.courseCode,
    this.cardCount = 0,
    this.masteredCount = 0,
    required this.ownerId,
    this.isPublic = false,
    required this.createdAt,
  });

  factory FlashcardDeck.fromJson(Map<String, dynamic> json) {
    return FlashcardDeck(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      courseCode: json['course_code']?.toString(),
      cardCount: _parseInt(json['card_count']),
      masteredCount: _parseInt(json['mastered_count']),
      ownerId: _parseInt(json['owner_id']),
      isPublic: _parseBool(json['is_public']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  double get progressPercent =>
      cardCount > 0 ? masteredCount / cardCount : 0;
}

// ─── QuizQuestion ────────────────────────────────────────────

class QuizQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
  final String subject;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
    required this.subject,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: _parseInt(json['id']),
      question: json['question']?.toString() ?? '',
      options: _parseStringList(json['options']),
      correctIndex: _parseInt(json['correct_index']),
      explanation: json['explanation']?.toString(),
      subject: json['subject']?.toString() ?? '',
    );
  }
}

// ─── ExamCountdown ───────────────────────────────────────────

class ExamCountdown {
  final int id;
  final String subject;
  final String? courseCode;
  final DateTime examDate;
  final String? venue;
  final String? notes;

  ExamCountdown({
    required this.id,
    required this.subject,
    this.courseCode,
    required this.examDate,
    this.venue,
    this.notes,
  });

  factory ExamCountdown.fromJson(Map<String, dynamic> json) {
    return ExamCountdown(
      id: _parseInt(json['id']),
      subject: json['subject']?.toString() ?? '',
      courseCode: json['course_code']?.toString(),
      examDate: DateTime.tryParse(json['exam_date']?.toString() ?? '') ??
          DateTime.now(),
      venue: json['venue']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  int get daysRemaining => examDate.difference(DateTime.now()).inDays;
  bool get isPast => DateTime.now().isAfter(examDate);
}

// ─── StudySession ────────────────────────────────────────────

class StudySession {
  final int id;
  final String subject;
  final int durationMinutes;
  final DateTime date;

  StudySession({
    required this.id,
    required this.subject,
    required this.durationMinutes,
    required this.date,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: _parseInt(json['id']),
      subject: json['subject']?.toString() ?? '',
      durationMinutes: _parseInt(json['duration_minutes']),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

// ─── Result wrappers ─────────────────────────────────────────

class PrepResult<T> {
  final bool success;
  final T? data;
  final String? message;

  PrepResult({required this.success, this.data, this.message});
}

class PrepListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  PrepListResult({required this.success, this.items = const [], this.message});
}

// ─── Parse helpers ───────────────────────────────────────────

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

List<String> _parseStringList(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  return [];
}
