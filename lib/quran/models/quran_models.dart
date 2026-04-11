// lib/quran/models/quran_models.dart

// ─── Surah ────────────────────────────────────────────────────
class Surah {
  final int number;
  final String nameArabic;
  final String nameSwahili;
  final String nameEnglish;
  final String revelationType; // Makki / Madani
  final int ayahCount;
  final int juzStart;

  Surah({
    required this.number,
    required this.nameArabic,
    required this.nameSwahili,
    required this.nameEnglish,
    required this.revelationType,
    required this.ayahCount,
    required this.juzStart,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: _parseInt(json['number']),
      nameArabic: json['name_arabic']?.toString() ?? '',
      nameSwahili: json['name_sw']?.toString() ?? '',
      nameEnglish: json['name_en']?.toString() ?? '',
      revelationType: json['revelation_type']?.toString() ?? 'Makki',
      ayahCount: _parseInt(json['ayah_count']),
      juzStart: _parseInt(json['juz_start']),
    );
  }
}

// ─── Ayah ─────────────────────────────────────────────────────
class Ayah {
  final int id;
  final int surahNumber;
  final int ayahNumber;
  final String textArabic;
  final String? translationSwahili;
  final String? translationEnglish;
  final String? transliteration;
  final int juz;
  final int page;
  final String? audioUrl;

  Ayah({
    required this.id,
    required this.surahNumber,
    required this.ayahNumber,
    required this.textArabic,
    this.translationSwahili,
    this.translationEnglish,
    this.transliteration,
    required this.juz,
    required this.page,
    this.audioUrl,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      id: _parseInt(json['id']),
      surahNumber: _parseInt(json['surah_number']),
      ayahNumber: _parseInt(json['ayah_number']),
      textArabic: json['text_arabic']?.toString() ?? '',
      translationSwahili: json['translation_sw']?.toString(),
      translationEnglish: json['translation_en']?.toString(),
      transliteration: json['transliteration']?.toString(),
      juz: _parseInt(json['juz']),
      page: _parseInt(json['page']),
      audioUrl: json['audio_url']?.toString(),
    );
  }
}

// ─── Juz ──────────────────────────────────────────────────────
class Juz {
  final int number;
  final String nameArabic;
  final int startSurah;
  final int startAyah;
  final int endSurah;
  final int endAyah;

  Juz({
    required this.number,
    required this.nameArabic,
    required this.startSurah,
    required this.startAyah,
    required this.endSurah,
    required this.endAyah,
  });

  factory Juz.fromJson(Map<String, dynamic> json) {
    return Juz(
      number: _parseInt(json['number']),
      nameArabic: json['name_arabic']?.toString() ?? '',
      startSurah: _parseInt(json['start_surah']),
      startAyah: _parseInt(json['start_ayah']),
      endSurah: _parseInt(json['end_surah']),
      endAyah: _parseInt(json['end_ayah']),
    );
  }
}

// ─── Bookmark ─────────────────────────────────────────────────
class QuranBookmark {
  final int id;
  final int surahNumber;
  final int ayahNumber;
  final String? label;
  final DateTime createdAt;

  QuranBookmark({
    required this.id,
    required this.surahNumber,
    required this.ayahNumber,
    this.label,
    required this.createdAt,
  });

  factory QuranBookmark.fromJson(Map<String, dynamic> json) {
    return QuranBookmark(
      id: _parseInt(json['id']),
      surahNumber: _parseInt(json['surah_number']),
      ayahNumber: _parseInt(json['ayah_number']),
      label: json['label']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'surah_number': surahNumber,
        'ayah_number': ayahNumber,
        if (label != null) 'label': label,
      };
}

// ─── Reciter ──────────────────────────────────────────────────
class Reciter {
  final int id;
  final String name;
  final String style;
  final String? imageUrl;

  Reciter({
    required this.id,
    required this.name,
    required this.style,
    this.imageUrl,
  });

  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      style: json['style']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
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
