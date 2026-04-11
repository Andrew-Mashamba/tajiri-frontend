// lib/dua/models/dua_models.dart

// ─── Dua Category ─────────────────────────────────────────────
class DuaCategory {
  final int id;
  final String name;
  final String nameSwahili;
  final String icon; // material icon name
  final int duaCount;

  DuaCategory({
    required this.id,
    required this.name,
    required this.nameSwahili,
    required this.icon,
    required this.duaCount,
  });

  factory DuaCategory.fromJson(Map<String, dynamic> json) {
    return DuaCategory(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      nameSwahili: json['name_sw']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'auto_awesome',
      duaCount: _parseInt(json['dua_count']),
    );
  }
}

// ─── Dua ──────────────────────────────────────────────────────
class Dua {
  final int id;
  final String titleArabic;
  final String titleSwahili;
  final String titleEnglish;
  final String textArabic;
  final String? transliteration;
  final String translationSwahili;
  final String? translationEnglish;
  final String source; // Quran, Hadith, etc.
  final String? sourceRef;
  final String? audioUrl;
  final int? repeatCount;
  final int categoryId;
  final bool isFavorite;

  Dua({
    required this.id,
    required this.titleArabic,
    required this.titleSwahili,
    required this.titleEnglish,
    required this.textArabic,
    this.transliteration,
    required this.translationSwahili,
    this.translationEnglish,
    required this.source,
    this.sourceRef,
    this.audioUrl,
    this.repeatCount,
    required this.categoryId,
    this.isFavorite = false,
  });

  factory Dua.fromJson(Map<String, dynamic> json) {
    return Dua(
      id: _parseInt(json['id']),
      titleArabic: json['title_ar']?.toString() ?? '',
      titleSwahili: json['title_sw']?.toString() ?? '',
      titleEnglish: json['title_en']?.toString() ?? '',
      textArabic: json['text_arabic']?.toString() ?? '',
      transliteration: json['transliteration']?.toString(),
      translationSwahili: json['translation_sw']?.toString() ?? '',
      translationEnglish: json['translation_en']?.toString(),
      source: json['source']?.toString() ?? '',
      sourceRef: json['source_ref']?.toString(),
      audioUrl: json['audio_url']?.toString(),
      repeatCount: json['repeat_count'] != null
          ? _parseInt(json['repeat_count'])
          : null,
      categoryId: _parseInt(json['category_id']),
      isFavorite: _parseBool(json['is_favorite']),
    );
  }
}

// ─── Adhkar Item ──────────────────────────────────────────────
class AdhkarItem {
  final int id;
  final String textArabic;
  final String translationSwahili;
  final String? transliteration;
  final int repeatTarget;
  final int repeatDone;
  final String type; // morning, evening

  AdhkarItem({
    required this.id,
    required this.textArabic,
    required this.translationSwahili,
    this.transliteration,
    required this.repeatTarget,
    this.repeatDone = 0,
    required this.type,
  });

  factory AdhkarItem.fromJson(Map<String, dynamic> json) {
    return AdhkarItem(
      id: _parseInt(json['id']),
      textArabic: json['text_arabic']?.toString() ?? '',
      translationSwahili: json['translation_sw']?.toString() ?? '',
      transliteration: json['transliteration']?.toString(),
      repeatTarget: _parseInt(json['repeat_target']),
      repeatDone: _parseInt(json['repeat_done']),
      type: json['type']?.toString() ?? 'morning',
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
