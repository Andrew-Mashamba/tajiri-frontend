import 'package:flutter/material.dart';

enum FilterCategory {
  colorFilter,        // Tier 1: color grading
  beautyFilter,       // Tier 2: skin smooth, face reshape
  hairColor,
  hairStyle,
  wigFilter,          // Tier 3: real wig PNG overlays
  lipColor,
  accessories,
  faceEffect,
  backgroundEffect,   // Tier 4: background blur/replace
}

enum FilterType {
  // Hair Color (8)
  hairColorBlack, hairColorBrown, hairColorRed, hairColorBlonde,
  hairColorBlue, hairColorPink, hairColorBurgundy, hairColorGrey,
  // Lip Color (6)
  lipRed, lipPink, lipNude, lipBerry, lipCoral, lipBrown,
  // Accessories (5)
  accSunglasses, accRoundGlasses, accCrown, accFlowerCrown, accHeadband,
  // Hair Style (8 — maps to existing kHairTryOnStyleCount indices)
  styleAfro, styleBraids, styleBob, styleBun, styleCornrows, styleLocs, styleBantuKnots, styleTwistOut,
  // Face Effects (4)
  fxSmooth, fxBlush, fxFreckles, fxContour,
  // Color Filter (generic — actual preset stored in colorPresetId)
  colorPreset,
  // Beauty Filters (4)
  beautySmoothSkin, beautySlimFace, beautyBigEyes, beautyWhiteTeeth,
  // Wig Overlay (generic — actual wig stored in wigAssetId)
  wigOverlay,
  // Background Effects (3)
  bgBlurLight, bgBlurHeavy, bgReplace,
}

class ARFilter {
  final FilterType type;
  final FilterCategory category;
  final String nameEn;
  final String nameSw;
  final Color? color;
  final int? styleIndex; // For hair styles
  final IconData icon;
  final String? colorPresetId; // For colorFilter type
  final String? wigAssetId;    // For wigFilter type
  final double defaultIntensity;

  const ARFilter({
    required this.type,
    required this.category,
    required this.nameEn,
    required this.nameSw,
    this.color,
    this.styleIndex,
    this.icon = Icons.auto_awesome_rounded,
    this.colorPresetId,
    this.wigAssetId,
    this.defaultIntensity = 1.0,
  });

  String name(bool isSwahili) => isSwahili ? nameSw : nameEn;
}

class ARFilterPresets {
  static const List<ARFilter> hairColors = [
    ARFilter(type: FilterType.hairColorBlack, category: FilterCategory.hairColor, nameEn: 'Jet Black', nameSw: 'Nyeusi', color: Color(0xFF0A0A0A), icon: Icons.circle),
    ARFilter(type: FilterType.hairColorBrown, category: FilterCategory.hairColor, nameEn: 'Brown', nameSw: 'Kahawia', color: Color(0xFF5D4037), icon: Icons.circle),
    ARFilter(type: FilterType.hairColorRed, category: FilterCategory.hairColor, nameEn: 'Red', nameSw: 'Nyekundu', color: Color(0xFFB71C1C), icon: Icons.circle),
    ARFilter(type: FilterType.hairColorBlonde, category: FilterCategory.hairColor, nameEn: 'Blonde', nameSw: 'Blonde', color: Color(0xFFC8A951), icon: Icons.circle),
    ARFilter(type: FilterType.hairColorBlue, category: FilterCategory.hairColor, nameEn: 'Blue', nameSw: 'Bluu', color: Color(0xFF1565C0), icon: Icons.circle),
    ARFilter(type: FilterType.hairColorPink, category: FilterCategory.hairColor, nameEn: 'Pink', nameSw: 'Waridi', color: Color(0xFFE91E63), icon: Icons.circle),
    ARFilter(type: FilterType.hairColorBurgundy, category: FilterCategory.hairColor, nameEn: 'Burgundy', nameSw: 'Burgundy', color: Color(0xFF800020), icon: Icons.circle),
    ARFilter(type: FilterType.hairColorGrey, category: FilterCategory.hairColor, nameEn: 'Grey', nameSw: 'Kijivu', color: Color(0xFF9E9E9E), icon: Icons.circle),
  ];

  static const List<ARFilter> lipColors = [
    ARFilter(type: FilterType.lipRed, category: FilterCategory.lipColor, nameEn: 'Classic Red', nameSw: 'Nyekundu', color: Color(0xFFD32F2F), icon: Icons.circle),
    ARFilter(type: FilterType.lipPink, category: FilterCategory.lipColor, nameEn: 'Pink', nameSw: 'Waridi', color: Color(0xFFEC407A), icon: Icons.circle),
    ARFilter(type: FilterType.lipNude, category: FilterCategory.lipColor, nameEn: 'Nude', nameSw: 'Nude', color: Color(0xFFBCAAA4), icon: Icons.circle),
    ARFilter(type: FilterType.lipBerry, category: FilterCategory.lipColor, nameEn: 'Berry', nameSw: 'Berry', color: Color(0xFF880E4F), icon: Icons.circle),
    ARFilter(type: FilterType.lipCoral, category: FilterCategory.lipColor, nameEn: 'Coral', nameSw: 'Coral', color: Color(0xFFFF7043), icon: Icons.circle),
    ARFilter(type: FilterType.lipBrown, category: FilterCategory.lipColor, nameEn: 'Brown', nameSw: 'Kahawia', color: Color(0xFF6D4C41), icon: Icons.circle),
  ];

  static const List<ARFilter> accessories = [
    ARFilter(type: FilterType.accSunglasses, category: FilterCategory.accessories, nameEn: 'Sunglasses', nameSw: 'Miwani ya jua', icon: Icons.wb_sunny_rounded),
    ARFilter(type: FilterType.accRoundGlasses, category: FilterCategory.accessories, nameEn: 'Round Glasses', nameSw: 'Miwani', icon: Icons.visibility_rounded),
    ARFilter(type: FilterType.accCrown, category: FilterCategory.accessories, nameEn: 'Crown', nameSw: 'Taji', icon: Icons.star_rounded),
    ARFilter(type: FilterType.accFlowerCrown, category: FilterCategory.accessories, nameEn: 'Flower Crown', nameSw: 'Taji la Maua', icon: Icons.local_florist_rounded),
    ARFilter(type: FilterType.accHeadband, category: FilterCategory.accessories, nameEn: 'Headband', nameSw: 'Bendi ya kichwa', icon: Icons.horizontal_rule_rounded),
  ];

  static const List<ARFilter> hairStyles = [
    ARFilter(type: FilterType.styleAfro, category: FilterCategory.hairStyle, nameEn: 'Short Afro', nameSw: 'Afro Fupi', styleIndex: 0, icon: Icons.face_rounded),
    ARFilter(type: FilterType.styleBraids, category: FilterCategory.hairStyle, nameEn: 'Long Braids', nameSw: 'Misuko Mirefu', styleIndex: 1, icon: Icons.face_rounded),
    ARFilter(type: FilterType.styleBob, category: FilterCategory.hairStyle, nameEn: 'Bob Cut', nameSw: 'Bob', styleIndex: 2, icon: Icons.face_rounded),
    ARFilter(type: FilterType.styleBun, category: FilterCategory.hairStyle, nameEn: 'High Bun', nameSw: 'Bun ya Juu', styleIndex: 3, icon: Icons.face_rounded),
    ARFilter(type: FilterType.styleCornrows, category: FilterCategory.hairStyle, nameEn: 'Cornrows', nameSw: 'Cornrows', styleIndex: 4, icon: Icons.face_rounded),
    ARFilter(type: FilterType.styleLocs, category: FilterCategory.hairStyle, nameEn: 'Locs', nameSw: 'Locs/Dread', styleIndex: 5, icon: Icons.face_rounded),
    ARFilter(type: FilterType.styleBantuKnots, category: FilterCategory.hairStyle, nameEn: 'Bantu Knots', nameSw: 'Bantu Knots', styleIndex: 6, icon: Icons.face_rounded),
    ARFilter(type: FilterType.styleTwistOut, category: FilterCategory.hairStyle, nameEn: 'Twist Out', nameSw: 'Twist Out', styleIndex: 7, icon: Icons.face_rounded),
  ];

  static const List<ARFilter> faceEffects = [
    ARFilter(type: FilterType.fxSmooth, category: FilterCategory.faceEffect, nameEn: 'Smooth Skin', nameSw: 'Ngozi Laini', icon: Icons.blur_on_rounded),
    ARFilter(type: FilterType.fxBlush, category: FilterCategory.faceEffect, nameEn: 'Blush', nameSw: 'Blush', color: Color(0xFFE57373), icon: Icons.favorite_rounded),
    ARFilter(type: FilterType.fxFreckles, category: FilterCategory.faceEffect, nameEn: 'Freckles', nameSw: 'Freckles', icon: Icons.scatter_plot_rounded),
    ARFilter(type: FilterType.fxContour, category: FilterCategory.faceEffect, nameEn: 'Contour', nameSw: 'Contour', icon: Icons.contrast_rounded),
  ];

  static const List<ARFilter> beautyFilters = [
    ARFilter(
      type: FilterType.beautySmoothSkin,
      category: FilterCategory.beautyFilter,
      nameEn: 'Smooth Skin',
      nameSw: 'Ngozi Laini',
      icon: Icons.blur_on_rounded,
      defaultIntensity: 0.6,
    ),
    ARFilter(
      type: FilterType.beautySlimFace,
      category: FilterCategory.beautyFilter,
      nameEn: 'Slim Face',
      nameSw: 'Uso Mwembamba',
      icon: Icons.face_retouching_natural_rounded,
      defaultIntensity: 0.4,
    ),
    ARFilter(
      type: FilterType.beautyBigEyes,
      category: FilterCategory.beautyFilter,
      nameEn: 'Big Eyes',
      nameSw: 'Macho Makubwa',
      icon: Icons.visibility_rounded,
      defaultIntensity: 0.5,
    ),
    ARFilter(
      type: FilterType.beautyWhiteTeeth,
      category: FilterCategory.beautyFilter,
      nameEn: 'White Teeth',
      nameSw: 'Meno Meupe',
      icon: Icons.sentiment_satisfied_alt_rounded,
      defaultIntensity: 0.7,
    ),
  ];

  static const List<ARFilter> backgroundEffects = [
    ARFilter(
      type: FilterType.bgBlurLight,
      category: FilterCategory.backgroundEffect,
      nameEn: 'Blur Light',
      nameSw: 'Ukungu Kidogo',
      icon: Icons.blur_linear_rounded,
      defaultIntensity: 0.5,
    ),
    ARFilter(
      type: FilterType.bgBlurHeavy,
      category: FilterCategory.backgroundEffect,
      nameEn: 'Blur Heavy',
      nameSw: 'Ukungu Mzito',
      icon: Icons.blur_on_rounded,
      defaultIntensity: 0.8,
    ),
    ARFilter(
      type: FilterType.bgReplace,
      category: FilterCategory.backgroundEffect,
      nameEn: 'Replace BG',
      nameSw: 'Badilisha Mandhari',
      icon: Icons.wallpaper_rounded,
      defaultIntensity: 1.0,
    ),
  ];

  static List<ARFilter> byCategory(FilterCategory cat) {
    switch (cat) {
      case FilterCategory.hairColor:
        return hairColors;
      case FilterCategory.hairStyle:
        return hairStyles;
      case FilterCategory.lipColor:
        return lipColors;
      case FilterCategory.accessories:
        return accessories;
      case FilterCategory.faceEffect:
        return faceEffects;
      case FilterCategory.beautyFilter:
        return beautyFilters;
      case FilterCategory.backgroundEffect:
        return backgroundEffects;
      // colorFilter and wigFilter are handled by separate preset classes
      case FilterCategory.colorFilter:
        return [];
      case FilterCategory.wigFilter:
        return [];
    }
  }
}
