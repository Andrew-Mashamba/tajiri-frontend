// lib/library/models/library_models.dart

// ─── Book Category ───────────────────────────────────────────

enum BookCategory {
  sciences,
  arts,
  engineering,
  medicine,
  law,
  business,
  education,
  agriculture;

  String get displayName {
    switch (this) {
      case BookCategory.sciences:
        return 'Sayansi';
      case BookCategory.arts:
        return 'Sanaa';
      case BookCategory.engineering:
        return 'Uhandisi';
      case BookCategory.medicine:
        return 'Tiba';
      case BookCategory.law:
        return 'Sheria';
      case BookCategory.business:
        return 'Biashara';
      case BookCategory.education:
        return 'Elimu';
      case BookCategory.agriculture:
        return 'Kilimo';
    }
  }

  static BookCategory fromString(String? s) {
    return BookCategory.values.firstWhere(
      (v) => v.name == s,
      orElse: () => BookCategory.sciences,
    );
  }
}

// ─── LibraryBook ─────────────────────────────────────────────

class LibraryBook {
  final int id;
  final String title;
  final String author;
  final String? isbn;
  final String? description;
  final String? coverUrl;
  final BookCategory category;
  final String? fileUrl;
  final int pageCount;
  final double rating;
  final int ratingCount;
  final int readCount;
  final bool isBorrowed;
  final bool isBookmarked;
  final bool isAvailablePhysical;
  final DateTime? returnDate;
  final DateTime createdAt;

  LibraryBook({
    required this.id,
    required this.title,
    required this.author,
    this.isbn,
    this.description,
    this.coverUrl,
    required this.category,
    this.fileUrl,
    this.pageCount = 0,
    this.rating = 0,
    this.ratingCount = 0,
    this.readCount = 0,
    this.isBorrowed = false,
    this.isBookmarked = false,
    this.isAvailablePhysical = true,
    this.returnDate,
    required this.createdAt,
  });

  factory LibraryBook.fromJson(Map<String, dynamic> json) {
    return LibraryBook(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      isbn: json['isbn']?.toString(),
      description: json['description']?.toString(),
      coverUrl: json['cover_url']?.toString(),
      category: BookCategory.fromString(json['category']?.toString()),
      fileUrl: json['file_url']?.toString(),
      pageCount: _parseInt(json['page_count']),
      rating: _parseDouble(json['rating']) ?? 0,
      ratingCount: _parseInt(json['rating_count']),
      readCount: _parseInt(json['read_count']),
      isBorrowed: _parseBool(json['is_borrowed']),
      isBookmarked: _parseBool(json['is_bookmarked']),
      isAvailablePhysical: _parseBool(json['is_available_physical']),
      returnDate: DateTime.tryParse(json['return_date']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  bool get hasEbook => fileUrl != null && fileUrl!.isNotEmpty;
}

// ─── ReadingList ─────────────────────────────────────────────

class ReadingList {
  final int id;
  final String name;
  final String? courseCode;
  final int bookCount;
  final int completedCount;
  final DateTime createdAt;

  ReadingList({
    required this.id,
    required this.name,
    this.courseCode,
    this.bookCount = 0,
    this.completedCount = 0,
    required this.createdAt,
  });

  factory ReadingList.fromJson(Map<String, dynamic> json) {
    return ReadingList(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      courseCode: json['course_code']?.toString(),
      bookCount: _parseInt(json['book_count']),
      completedCount: _parseInt(json['completed_count']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ─── Citation ────────────────────────────────────────────────

class Citation {
  final int bookId;
  final String formatted;
  final String style; // apa, mla, harvard, chicago

  Citation({
    required this.bookId,
    required this.formatted,
    required this.style,
  });

  factory Citation.fromJson(Map<String, dynamic> json) {
    return Citation(
      bookId: _parseInt(json['book_id']),
      formatted: json['formatted']?.toString() ?? '',
      style: json['style']?.toString() ?? 'apa',
    );
  }
}

// ─── Result wrappers ─────────────────────────────────────────

class LibraryResult<T> {
  final bool success;
  final T? data;
  final String? message;

  LibraryResult({required this.success, this.data, this.message});
}

class LibraryListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  LibraryListResult({
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

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}
