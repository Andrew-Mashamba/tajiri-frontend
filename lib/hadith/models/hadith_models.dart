// lib/hadith/models/hadith_models.dart

// ─── Hadith Collection ────────────────────────────────────────
class HadithCollection {
  final int id;
  final String name;
  final String nameArabic;
  final String nameSwahili;
  final String author;
  final int hadithCount;
  final int bookCount;
  final String? imageUrl;

  HadithCollection({
    required this.id,
    required this.name,
    required this.nameArabic,
    required this.nameSwahili,
    required this.author,
    required this.hadithCount,
    required this.bookCount,
    this.imageUrl,
  });

  factory HadithCollection.fromJson(Map<String, dynamic> json) {
    return HadithCollection(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      nameArabic: json['name_arabic']?.toString() ?? '',
      nameSwahili: json['name_sw']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      hadithCount: _parseInt(json['hadith_count']),
      bookCount: _parseInt(json['book_count']),
      imageUrl: json['image_url']?.toString(),
    );
  }
}

// ─── Hadith Book ──────────────────────────────────────────────
class HadithBook {
  final int id;
  final int collectionId;
  final String name;
  final String nameArabic;
  final int hadithCount;

  HadithBook({
    required this.id,
    required this.collectionId,
    required this.name,
    required this.nameArabic,
    required this.hadithCount,
  });

  factory HadithBook.fromJson(Map<String, dynamic> json) {
    return HadithBook(
      id: _parseInt(json['id']),
      collectionId: _parseInt(json['collection_id']),
      name: json['name']?.toString() ?? '',
      nameArabic: json['name_arabic']?.toString() ?? '',
      hadithCount: _parseInt(json['hadith_count']),
    );
  }
}

// ─── Hadith ───────────────────────────────────────────────────
class Hadith {
  final int id;
  final int collectionId;
  final int bookId;
  final String hadithNumber;
  final String textArabic;
  final String? translationSwahili;
  final String? translationEnglish;
  final String narrator;
  final String grade; // sahih, hasan, daif
  final String? gradeScholar;
  final String? isnad;
  final bool isFavorite;
  final String? topic;

  Hadith({
    required this.id,
    required this.collectionId,
    required this.bookId,
    required this.hadithNumber,
    required this.textArabic,
    this.translationSwahili,
    this.translationEnglish,
    required this.narrator,
    required this.grade,
    this.gradeScholar,
    this.isnad,
    this.isFavorite = false,
    this.topic,
  });

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      id: _parseInt(json['id']),
      collectionId: _parseInt(json['collection_id']),
      bookId: _parseInt(json['book_id']),
      hadithNumber: json['hadith_number']?.toString() ?? '',
      textArabic: json['text_arabic']?.toString() ?? '',
      translationSwahili: json['translation_sw']?.toString(),
      translationEnglish: json['translation_en']?.toString(),
      narrator: json['narrator']?.toString() ?? '',
      grade: json['grade']?.toString() ?? 'sahih',
      gradeScholar: json['grade_scholar']?.toString(),
      isnad: json['isnad']?.toString(),
      isFavorite: _parseBool(json['is_favorite']),
      topic: json['topic']?.toString(),
    );
  }
}

// ─── Hadith Topic ─────────────────────────────────────────────
class HadithTopic {
  final int id;
  final String name;
  final String nameSwahili;
  final int hadithCount;

  HadithTopic({
    required this.id,
    required this.name,
    required this.nameSwahili,
    required this.hadithCount,
  });

  factory HadithTopic.fromJson(Map<String, dynamic> json) {
    return HadithTopic(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      nameSwahili: json['name_sw']?.toString() ?? '',
      hadithCount: _parseInt(json['hadith_count']),
    );
  }
}

// ─── Result Wrappers ──────────────────────────────────────────
class SingleResult<T> {
  final bool success;
  final T? data;
  final String? message;
  SingleResult({required this.success, this.data, this.message});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? message;
  PaginatedResult({
    required this.success,
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.message,
  });
}

// ─── Parse Helpers ────────────────────────────────────────────
int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}
