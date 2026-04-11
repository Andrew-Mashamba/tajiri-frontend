// lib/skincare/models/skincare_models.dart
import 'package:flutter/material.dart';

// ─── Skin Type ──────────────────────────────────────────────────

enum SkinType {
  oily,
  dry,
  combination,
  sensitive,
  normal;

  String get displayName {
    switch (this) {
      case SkinType.oily: return 'Mafuta';
      case SkinType.dry: return 'Kavu';
      case SkinType.combination: return 'Mseto';
      case SkinType.sensitive: return 'Nyeti';
      case SkinType.normal: return 'Kawaida';
    }
  }

  String get description {
    switch (this) {
      case SkinType.oily: return 'Ngozi yako ina mafuta mengi, hasa usoni';
      case SkinType.dry: return 'Ngozi yako ni kavu na inaweza kupasuka';
      case SkinType.combination: return 'Sehemu fulani ni mafuta, nyingine ni kavu';
      case SkinType.sensitive: return 'Ngozi yako inawashika haraka';
      case SkinType.normal: return 'Ngozi yako ni ya kawaida, inalingana vizuri';
    }
  }

  IconData get icon {
    switch (this) {
      case SkinType.oily: return Icons.water_drop_rounded;
      case SkinType.dry: return Icons.grain_rounded;
      case SkinType.combination: return Icons.contrast_rounded;
      case SkinType.sensitive: return Icons.warning_amber_rounded;
      case SkinType.normal: return Icons.check_circle_outline_rounded;
    }
  }

  static SkinType fromString(String? s) {
    return SkinType.values.firstWhere((v) => v.name == s, orElse: () => SkinType.normal);
  }
}

// ─── Skin Concern ───────────────────────────────────────────────

enum SkinConcern {
  acne,
  darkSpots,
  wrinkles,
  unevenTone,
  dryness,
  oiliness,
  largePores,
  darkCircles,
  keloids;

  String get displayName {
    switch (this) {
      case SkinConcern.acne: return 'Chunusi';
      case SkinConcern.darkSpots: return 'Madoa Meusi';
      case SkinConcern.wrinkles: return 'Mikunjo';
      case SkinConcern.unevenTone: return 'Rangi Isiyolingana';
      case SkinConcern.dryness: return 'Ukavu';
      case SkinConcern.oiliness: return 'Mafuta Kupita Kiasi';
      case SkinConcern.largePores: return 'Matundu Makubwa';
      case SkinConcern.darkCircles: return 'Weusi Chini ya Macho';
      case SkinConcern.keloids: return 'Keloid';
    }
  }

  IconData get icon {
    switch (this) {
      case SkinConcern.acne: return Icons.bubble_chart_rounded;
      case SkinConcern.darkSpots: return Icons.circle_rounded;
      case SkinConcern.wrinkles: return Icons.timeline_rounded;
      case SkinConcern.unevenTone: return Icons.palette_rounded;
      case SkinConcern.dryness: return Icons.grain_rounded;
      case SkinConcern.oiliness: return Icons.water_drop_rounded;
      case SkinConcern.largePores: return Icons.blur_on_rounded;
      case SkinConcern.darkCircles: return Icons.visibility_rounded;
      case SkinConcern.keloids: return Icons.healing_rounded;
    }
  }

  static SkinConcern fromString(String? s) {
    return SkinConcern.values.firstWhere((v) => v.name == s, orElse: () => SkinConcern.acne);
  }
}

// ─── Climate Zone ───────────────────────────────────────────────

enum ClimateZone {
  pwani,
  bara,
  ziwa;

  String get displayName {
    switch (this) {
      case ClimateZone.pwani: return 'Pwani (Humid)';
      case ClimateZone.bara: return 'Bara (Dry)';
      case ClimateZone.ziwa: return 'Ziwa (Temperate)';
    }
  }

  static ClimateZone fromString(String? s) {
    return ClimateZone.values.firstWhere((v) => v.name == s, orElse: () => ClimateZone.bara);
  }
}

// ─── Routine Type ───────────────────────────────────────────────

enum RoutineType {
  morning,
  evening;

  String get displayName {
    switch (this) {
      case RoutineType.morning: return 'Asubuhi';
      case RoutineType.evening: return 'Jioni';
    }
  }

  IconData get icon {
    switch (this) {
      case RoutineType.morning: return Icons.wb_sunny_rounded;
      case RoutineType.evening: return Icons.nights_stay_rounded;
    }
  }

  static RoutineType fromString(String? s) {
    return RoutineType.values.firstWhere((v) => v.name == s, orElse: () => RoutineType.morning);
  }
}

// ─── Step Type ──────────────────────────────────────────────────

enum StepType {
  cleanser,
  toner,
  serum,
  moisturizer,
  sunscreen,
  treatment,
  mask;

  String get displayName {
    switch (this) {
      case StepType.cleanser: return 'Sabuni/Cleanser';
      case StepType.toner: return 'Toner';
      case StepType.serum: return 'Serum';
      case StepType.moisturizer: return 'Moisturizer';
      case StepType.sunscreen: return 'Sunscreen';
      case StepType.treatment: return 'Tiba/Treatment';
      case StepType.mask: return 'Mask';
    }
  }

  IconData get icon {
    switch (this) {
      case StepType.cleanser: return Icons.wash_rounded;
      case StepType.toner: return Icons.water_drop_rounded;
      case StepType.serum: return Icons.science_rounded;
      case StepType.moisturizer: return Icons.opacity_rounded;
      case StepType.sunscreen: return Icons.wb_sunny_rounded;
      case StepType.treatment: return Icons.healing_rounded;
      case StepType.mask: return Icons.face_retouching_natural_rounded;
    }
  }

  int get defaultOrder {
    switch (this) {
      case StepType.cleanser: return 1;
      case StepType.toner: return 2;
      case StepType.serum: return 3;
      case StepType.moisturizer: return 4;
      case StepType.sunscreen: return 5;
      case StepType.treatment: return 6;
      case StepType.mask: return 7;
    }
  }

  static StepType fromString(String? s) {
    return StepType.values.firstWhere((v) => v.name == s, orElse: () => StepType.cleanser);
  }
}

// ─── Skin Profile ───────────────────────────────────────────────

class SkinProfile {
  final int id;
  final int userId;
  final SkinType skinType;
  final String? skinTone;
  final List<SkinConcern> concerns;
  final int score;
  final ClimateZone climateZone;
  final String? budget;
  final DateTime? lastAnalysisDate;

  SkinProfile({
    required this.id,
    required this.userId,
    required this.skinType,
    this.skinTone,
    this.concerns = const [],
    this.score = 0,
    this.climateZone = ClimateZone.bara,
    this.budget,
    this.lastAnalysisDate,
  });

  factory SkinProfile.fromJson(Map<String, dynamic> json) {
    return SkinProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      skinType: SkinType.fromString(json['skin_type']),
      skinTone: json['skin_tone'],
      concerns: (json['concerns'] as List?)
              ?.map((c) => SkinConcern.fromString(c))
              .toList() ??
          [],
      score: (json['score'] as num?)?.toInt() ?? 0,
      climateZone: ClimateZone.fromString(json['climate_zone']),
      budget: json['budget'],
      lastAnalysisDate: json['last_analysis_date'] != null
          ? DateTime.tryParse(json['last_analysis_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'skin_type': skinType.name,
        'skin_tone': skinTone,
        'concerns': concerns.map((c) => c.name).toList(),
        'climate_zone': climateZone.name,
        'budget': budget,
      };
}

// ─── Skincare Routine ───────────────────────────────────────────

class SkincareRoutine {
  final int id;
  final int userId;
  final String name;
  final RoutineType type;
  final List<RoutineStep> steps;
  final bool isActive;

  SkincareRoutine({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.steps = const [],
    this.isActive = true,
  });

  factory SkincareRoutine.fromJson(Map<String, dynamic> json) {
    return SkincareRoutine(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '',
      type: RoutineType.fromString(json['type']),
      steps: (json['steps'] as List?)
              ?.map((s) => RoutineStep.fromJson(s))
              .toList() ??
          [],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'type': type.name,
        'steps': steps.map((s) => s.toJson()).toList(),
        'is_active': isActive,
      };
}

// ─── Routine Step ───────────────────────────────────────────────

class RoutineStep {
  final int order;
  final StepType stepType;
  final String? productName;
  final String? instructions;
  final int waitTimeSeconds;

  RoutineStep({
    required this.order,
    required this.stepType,
    this.productName,
    this.instructions,
    this.waitTimeSeconds = 0,
  });

  factory RoutineStep.fromJson(Map<String, dynamic> json) {
    return RoutineStep(
      order: (json['order'] as num?)?.toInt() ?? 0,
      stepType: StepType.fromString(json['step_type']),
      productName: json['product_name'],
      instructions: json['instructions'],
      waitTimeSeconds: (json['wait_time_seconds'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'order': order,
        'step_type': stepType.name,
        'product_name': productName,
        'instructions': instructions,
        'wait_time_seconds': waitTimeSeconds,
      };
}

// ─── Skin Diary Entry ───────────────────────────────────────────

class SkinDiaryEntry {
  final int id;
  final int userId;
  final DateTime date;
  final int mood;
  final List<String> tags;
  final List<String> productsUsed;
  final String? notes;
  final String? photoUrl;

  SkinDiaryEntry({
    required this.id,
    required this.userId,
    required this.date,
    this.mood = 3,
    this.tags = const [],
    this.productsUsed = const [],
    this.notes,
    this.photoUrl,
  });

  factory SkinDiaryEntry.fromJson(Map<String, dynamic> json) {
    return SkinDiaryEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      mood: (json['mood'] as num?)?.toInt() ?? 3,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      productsUsed: (json['products_used'] as List?)?.cast<String>() ?? [],
      notes: json['notes'],
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'date': date.toIso8601String().split('T').first,
        'mood': mood,
        'tags': tags,
        'products_used': productsUsed,
        'notes': notes,
      };

  String get moodEmoji {
    switch (mood) {
      case 1: return 'Mbaya sana';
      case 2: return 'Mbaya';
      case 3: return 'Kawaida';
      case 4: return 'Nzuri';
      case 5: return 'Nzuri sana';
      default: return 'Kawaida';
    }
  }

  IconData get moodIcon {
    switch (mood) {
      case 1: return Icons.sentiment_very_dissatisfied_rounded;
      case 2: return Icons.sentiment_dissatisfied_rounded;
      case 3: return Icons.sentiment_neutral_rounded;
      case 4: return Icons.sentiment_satisfied_rounded;
      case 5: return Icons.sentiment_very_satisfied_rounded;
      default: return Icons.sentiment_neutral_rounded;
    }
  }
}

// ─── Skin Product ───────────────────────────────────────────────

class SkinProduct {
  final int id;
  final String name;
  final String? brand;
  final String category;
  final List<SkinType> skinTypes;
  final List<SkinConcern> concerns;
  final double price;
  final double rating;
  final String? imageUrl;
  final List<String> ingredients;
  final bool isTmdaApproved;
  final String? description;

  SkinProduct({
    required this.id,
    required this.name,
    this.brand,
    required this.category,
    this.skinTypes = const [],
    this.concerns = const [],
    this.price = 0,
    this.rating = 0,
    this.imageUrl,
    this.ingredients = const [],
    this.isTmdaApproved = false,
    this.description,
  });

  factory SkinProduct.fromJson(Map<String, dynamic> json) {
    return SkinProduct(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '',
      brand: json['brand'],
      category: json['category'] ?? '',
      skinTypes: (json['skin_types'] as List?)
              ?.map((s) => SkinType.fromString(s))
              .toList() ??
          [],
      concerns: (json['concerns'] as List?)
              ?.map((c) => SkinConcern.fromString(c))
              .toList() ??
          [],
      price: (json['price'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      imageUrl: json['image_url'],
      ingredients: (json['ingredients'] as List?)?.cast<String>() ?? [],
      isTmdaApproved: json['is_tmda_approved'] ?? false,
      description: json['description'],
    );
  }
}

// ─── Dangerous Ingredient ───────────────────────────────────────

class DangerousIngredient {
  final String name;
  final String level; // danger, caution, safe
  final String reason;

  DangerousIngredient({
    required this.name,
    required this.level,
    required this.reason,
  });

  factory DangerousIngredient.fromJson(Map<String, dynamic> json) {
    return DangerousIngredient(
      name: json['name'] ?? '',
      level: json['level'] ?? 'safe',
      reason: json['reason'] ?? '',
    );
  }

  bool get isDanger => level == 'danger';
  bool get isCaution => level == 'caution';
  bool get isSafe => level == 'safe';
}

// ─── Result Wrappers ────────────────────────────────────────────

class SkincareResult<T> {
  final bool success;
  final T? data;
  final String? message;
  SkincareResult({required this.success, this.data, this.message});
}

class SkincareListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  SkincareListResult({required this.success, this.items = const [], this.message});
}
