// lib/newton/models/newton_models.dart

// ─── Subject Mode ────────────────────────────────────────────

enum SubjectMode {
  general,
  mathematics,
  physics,
  chemistry,
  biology,
  history,
  geography,
  english,
  kiswahili,
  commerce,
  accounting,
  computerScience;

  String get displayName {
    switch (this) {
      case SubjectMode.general:
        return 'General';
      case SubjectMode.mathematics:
        return 'Mathematics';
      case SubjectMode.physics:
        return 'Physics';
      case SubjectMode.chemistry:
        return 'Chemistry';
      case SubjectMode.biology:
        return 'Biology';
      case SubjectMode.history:
        return 'History';
      case SubjectMode.geography:
        return 'Geography';
      case SubjectMode.english:
        return 'English';
      case SubjectMode.kiswahili:
        return 'Kiswahili';
      case SubjectMode.commerce:
        return 'Commerce';
      case SubjectMode.accounting:
        return 'Accounting';
      case SubjectMode.computerScience:
        return 'Computer Science';
    }
  }

  String get displayNameSw {
    switch (this) {
      case SubjectMode.general:
        return 'Jumla';
      case SubjectMode.mathematics:
        return 'Hisabati';
      case SubjectMode.physics:
        return 'Fizikia';
      case SubjectMode.chemistry:
        return 'Kemia';
      case SubjectMode.biology:
        return 'Biolojia';
      case SubjectMode.history:
        return 'Historia';
      case SubjectMode.geography:
        return 'Jiografia';
      case SubjectMode.english:
        return 'Kiingereza';
      case SubjectMode.kiswahili:
        return 'Kiswahili';
      case SubjectMode.commerce:
        return 'Biashara';
      case SubjectMode.accounting:
        return 'Uhasibu';
      case SubjectMode.computerScience:
        return 'Kompyuta';
    }
  }

  String get iconName {
    switch (this) {
      case SubjectMode.general:
        return 'auto_awesome';
      case SubjectMode.mathematics:
        return 'calculate';
      case SubjectMode.physics:
        return 'speed';
      case SubjectMode.chemistry:
        return 'science';
      case SubjectMode.biology:
        return 'biotech';
      case SubjectMode.history:
        return 'history_edu';
      case SubjectMode.geography:
        return 'public';
      case SubjectMode.english:
        return 'menu_book';
      case SubjectMode.kiswahili:
        return 'translate';
      case SubjectMode.commerce:
        return 'store';
      case SubjectMode.accounting:
        return 'account_balance';
      case SubjectMode.computerScience:
        return 'computer';
    }
  }

  static SubjectMode fromString(String? s) {
    return SubjectMode.values.firstWhere(
      (v) => v.name == s,
      orElse: () => SubjectMode.general,
    );
  }
}

// ─── Difficulty Level ───────────────────────────────────────

enum DifficultyLevel {
  form1_4,
  form5_6,
  university;

  String get displayName {
    switch (this) {
      case DifficultyLevel.form1_4:
        return 'Form 1-4';
      case DifficultyLevel.form5_6:
        return 'Form 5-6';
      case DifficultyLevel.university:
        return 'University';
    }
  }

  String get displayNameSw {
    switch (this) {
      case DifficultyLevel.form1_4:
        return 'Kidato 1-4';
      case DifficultyLevel.form5_6:
        return 'Kidato 5-6';
      case DifficultyLevel.university:
        return 'Chuo Kikuu';
    }
  }

  String get apiValue {
    switch (this) {
      case DifficultyLevel.form1_4:
        return 'form_1_4';
      case DifficultyLevel.form5_6:
        return 'form_5_6';
      case DifficultyLevel.university:
        return 'university';
    }
  }

  static DifficultyLevel fromString(String? s) {
    return DifficultyLevel.values.firstWhere(
      (v) => v.name == s || v.apiValue == s,
      orElse: () => DifficultyLevel.form1_4,
    );
  }
}

// ─── ChatMessage ─────────────────────────────────────────────

class NewtonMessage {
  final int id;
  final String content;
  final bool isUser;
  final String? imageUrl;
  final SubjectMode? subject;
  final bool isBookmarked;
  final bool isFlagged;
  final DateTime createdAt;

  NewtonMessage({
    required this.id,
    required this.content,
    required this.isUser,
    this.imageUrl,
    this.subject,
    this.isBookmarked = false,
    this.isFlagged = false,
    required this.createdAt,
  });

  NewtonMessage copyWith({
    bool? isBookmarked,
    bool? isFlagged,
  }) {
    return NewtonMessage(
      id: id,
      content: content,
      isUser: isUser,
      imageUrl: imageUrl,
      subject: subject,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isFlagged: isFlagged ?? this.isFlagged,
      createdAt: createdAt,
    );
  }

  factory NewtonMessage.fromJson(Map<String, dynamic> json) {
    return NewtonMessage(
      id: _parseInt(json['id']),
      content: json['content']?.toString() ?? '',
      isUser: _parseBool(json['is_user']),
      imageUrl: json['image_url']?.toString(),
      subject: json['subject'] != null
          ? SubjectMode.fromString(json['subject']?.toString())
          : null,
      isBookmarked: _parseBool(json['is_bookmarked']),
      isFlagged: _parseBool(json['is_flagged']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ─── Conversation ────────────────────────────────────────────

class NewtonConversation {
  final int id;
  final String title;
  final SubjectMode subject;
  final int messageCount;
  final bool isBookmarked;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final List<NewtonMessage> messages;

  NewtonConversation({
    required this.id,
    required this.title,
    required this.subject,
    this.messageCount = 0,
    this.isBookmarked = false,
    required this.lastMessageAt,
    required this.createdAt,
    this.messages = const [],
  });

  NewtonConversation copyWith({
    bool? isBookmarked,
    List<NewtonMessage>? messages,
  }) {
    return NewtonConversation(
      id: id,
      title: title,
      subject: subject,
      messageCount: messageCount,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      lastMessageAt: lastMessageAt,
      createdAt: createdAt,
      messages: messages ?? this.messages,
    );
  }

  factory NewtonConversation.fromJson(Map<String, dynamic> json) {
    return NewtonConversation(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      subject: SubjectMode.fromString(json['subject']?.toString()),
      messageCount: _parseInt(json['message_count']),
      isBookmarked: _parseBool(json['is_bookmarked']),
      lastMessageAt:
          DateTime.tryParse(json['last_message_at']?.toString() ?? '') ??
              DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      messages: json['messages'] is List
          ? (json['messages'] as List)
              .map((m) => NewtonMessage.fromJson(m as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

// ─── Topic Suggestion ───────────────────────────────────────

class TopicSuggestion {
  final SubjectMode subject;
  final String topic;
  final String questionHint;
  final String questionHintSw;

  const TopicSuggestion({
    required this.subject,
    required this.topic,
    required this.questionHint,
    required this.questionHintSw,
  });

  factory TopicSuggestion.fromJson(Map<String, dynamic> json) {
    return TopicSuggestion(
      subject: SubjectMode.fromString(json['subject']?.toString()),
      topic: json['topic']?.toString() ?? '',
      questionHint: json['question_hint']?.toString() ?? '',
      questionHintSw: json['question_hint_sw']?.toString() ?? '',
    );
  }
}

// ─── Formula Sheet ──────────────────────────────────────────

class FormulaEntry {
  final String name;
  final String formula;
  final String description;

  const FormulaEntry({
    required this.name,
    required this.formula,
    required this.description,
  });
}

class FormulaSheet {
  final SubjectMode subject;
  final List<FormulaEntry> formulas;

  const FormulaSheet({required this.subject, required this.formulas});
}

// ─── Periodic Element ───────────────────────────────────────

class PeriodicElement {
  final String symbol;
  final String name;
  final int atomicNumber;
  final double atomicMass;
  final String category;
  final int group;
  final int period;

  const PeriodicElement({
    required this.symbol,
    required this.name,
    required this.atomicNumber,
    required this.atomicMass,
    required this.category,
    required this.group,
    required this.period,
  });
}

// ─── Usage Stats ────────────────────────────────────────────

class UsageStats {
  final int questionsToday;
  final int dailyLimit;
  final int questionsTotal;

  UsageStats({
    this.questionsToday = 0,
    this.dailyLimit = 20,
    this.questionsTotal = 0,
  });

  int get remaining => (dailyLimit - questionsToday).clamp(0, dailyLimit);
  bool get isLimitReached => questionsToday >= dailyLimit;

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    return UsageStats(
      questionsToday: _parseInt(json['questions_today']),
      dailyLimit: _parseInt(json['daily_limit']),
      questionsTotal: _parseInt(json['questions_total']),
    );
  }
}

// ─── Result wrappers ─────────────────────────────────────────

class NewtonResult<T> {
  final bool success;
  final T? data;
  final String? message;

  NewtonResult({required this.success, this.data, this.message});
}

class NewtonListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  NewtonListResult({
    required this.success,
    this.items = const [],
    this.message,
  });
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
