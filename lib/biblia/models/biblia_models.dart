// lib/biblia/models/biblia_models.dart

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
bool _parseBool(dynamic v) =>
    v == true || v == 1 || v == '1' || v == 'true';

// ─── Result wrappers ───────────────────────────────────────────

class SingleResult<T> {
  final bool success;
  final T? data;
  final String? message;
  SingleResult({required this.success, this.data, this.message});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  final int currentPage;
  final int lastPage;
  PaginatedResult({
    required this.success,
    this.items = const [],
    this.message,
    this.currentPage = 1,
    this.lastPage = 1,
  });
  bool get hasMore => currentPage < lastPage;
}

// ─── Bible Book ───────────────────────────────────────────────

class BibleBook {
  final int id;
  final String name;
  final String nameEn;
  final String testament; // 'OT' | 'NT'
  final int chapters;

  BibleBook({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.testament,
    required this.chapters,
  });

  factory BibleBook.fromJson(Map<String, dynamic> json) {
    return BibleBook(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      testament: json['testament']?.toString() ?? 'OT',
      chapters: _parseInt(json['chapters']),
    );
  }
}

// ─── Bible Verse ──────────────────────────────────────────────

class BibleVerse {
  final int id;
  final int bookId;
  final int chapter;
  final int verse;
  final String text;
  final String? translation;

  BibleVerse({
    required this.id,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.text,
    this.translation,
  });

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      id: _parseInt(json['id']),
      bookId: _parseInt(json['book_id']),
      chapter: _parseInt(json['chapter']),
      verse: _parseInt(json['verse']),
      text: json['text']?.toString() ?? '',
      translation: json['translation']?.toString(),
    );
  }
}

// ─── Bookmark ─────────────────────────────────────────────────

class BibleBookmark {
  final int id;
  final int bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String verseText;
  final String? label;
  final String? color;
  final String createdAt;

  BibleBookmark({
    required this.id,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.verseText,
    this.label,
    this.color,
    required this.createdAt,
  });

  factory BibleBookmark.fromJson(Map<String, dynamic> json) {
    return BibleBookmark(
      id: _parseInt(json['id']),
      bookId: _parseInt(json['book_id']),
      bookName: json['book_name']?.toString() ?? '',
      chapter: _parseInt(json['chapter']),
      verse: _parseInt(json['verse']),
      verseText: json['verse_text']?.toString() ?? '',
      label: json['label']?.toString(),
      color: json['color']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

// ─── Verse of the Day ─────────────────────────────────────────

class VerseOfDay {
  final String bookName;
  final int chapter;
  final int verse;
  final String text;
  final String date;

  VerseOfDay({
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.date,
  });

  factory VerseOfDay.fromJson(Map<String, dynamic> json) {
    return VerseOfDay(
      bookName: json['book_name']?.toString() ?? '',
      chapter: _parseInt(json['chapter']),
      verse: _parseInt(json['verse']),
      text: json['text']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
    );
  }

  String get reference => '$bookName $chapter:$verse';
}

// ─── Search Result ────────────────────────────────────────────

class BibleSearchResult {
  final int bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String text;
  final String? snippet;

  BibleSearchResult({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
    this.snippet,
  });

  factory BibleSearchResult.fromJson(Map<String, dynamic> json) {
    return BibleSearchResult(
      bookId: _parseInt(json['book_id']),
      bookName: json['book_name']?.toString() ?? '',
      chapter: _parseInt(json['chapter']),
      verse: _parseInt(json['verse']),
      text: json['text']?.toString() ?? '',
      snippet: json['snippet']?.toString(),
    );
  }

  String get reference => '$bookName $chapter:$verse';
}
