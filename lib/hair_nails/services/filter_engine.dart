import 'package:flutter/material.dart';
import '../models/ar_filter_models.dart';
import '../models/color_filter_presets.dart';
import '../models/wig_asset.dart';
// ignore: unused_import — kept for downstream filter computation context
import 'color_matrix_utils.dart';

/// ChangeNotifier that manages all active filter state for the AR try-on
/// experience. UI layers observe this notifier and rebuild when any filter
/// changes.
class FilterEngine extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  ColorFilterPreset _colorPreset = ColorFilterPresets.none;
  double _colorIntensity = 1.0;
  final Map<FilterType, double> _beautyIntensities = {};
  final Set<ARFilter> _activeOverlays = {};
  ARFilter? _activeHairColor;
  ARFilter? _activeHairStyle;
  WigAsset? _activeWig;
  ARFilter? _activeBackground;
  bool _showBeforeAfter = false;

  // ---------------------------------------------------------------------------
  // Getters — color
  // ---------------------------------------------------------------------------

  ColorFilterPreset get colorPreset => _colorPreset;
  double get colorIntensity => _colorIntensity;
  bool get hasColorFilter => _colorPreset.id != 'none';

  /// Returns a [ColorFilter] built from the current color preset and intensity,
  /// or null when no color filter is active or before/after preview is showing.
  ColorFilter? get composedColorFilter {
    if (_showBeforeAfter || !hasColorFilter) return null;
    return ColorFilter.matrix(_colorPreset.matrixAt(_colorIntensity));
  }

  // ---------------------------------------------------------------------------
  // Getters — beauty
  // ---------------------------------------------------------------------------

  double beautyIntensity(FilterType type) => _beautyIntensities[type] ?? 0.0;
  bool isBeautyActive(FilterType type) =>
      (_beautyIntensities[type] ?? 0.0) > 0.0;

  // ---------------------------------------------------------------------------
  // Getters — overlays / hair / wig / background
  // ---------------------------------------------------------------------------

  Set<ARFilter> get activeOverlays => _activeOverlays;
  ARFilter? get activeHairColor => _activeHairColor;
  ARFilter? get activeHairStyle => _activeHairStyle;
  WigAsset? get activeWig => _activeWig;
  ARFilter? get activeBackground => _activeBackground;

  bool isOverlayActive(ARFilter filter) => _activeOverlays.contains(filter);

  // ---------------------------------------------------------------------------
  // Getters — before/after & aggregates
  // ---------------------------------------------------------------------------

  bool get showBeforeAfter => _showBeforeAfter;

  /// Returns true when any filter is active (non-default state).
  bool get hasAnyFilter {
    return hasColorFilter ||
        _beautyIntensities.isNotEmpty ||
        _activeOverlays.isNotEmpty ||
        _activeHairColor != null ||
        _activeHairStyle != null ||
        _activeWig != null ||
        _activeBackground != null;
  }

  /// All active AR overlay filters (hair color + overlays). Returns empty list
  /// when before/after preview is active.
  List<ARFilter> get allActiveARFilters {
    if (_showBeforeAfter) return const [];
    return [
      if (_activeHairColor != null) _activeHairColor!,
      ..._activeOverlays,
    ];
  }

  // ---------------------------------------------------------------------------
  // Setters — color
  // ---------------------------------------------------------------------------

  void setColorPreset(ColorFilterPreset preset) {
    _colorPreset = preset;
    notifyListeners();
  }

  void setColorIntensity(double v) {
    _colorIntensity = v.clamp(0.0, 1.0);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Setters — beauty
  // ---------------------------------------------------------------------------

  void setBeautyIntensity(FilterType type, double v) {
    if (v <= 0) {
      _beautyIntensities.remove(type);
    } else {
      _beautyIntensities[type] = v.clamp(0.0, 1.0);
    }
    notifyListeners();
  }

  /// Toggle a beauty filter on/off. When turning on, uses [intensity] as the
  /// initial value (defaults to 0.6).
  void toggleBeauty(FilterType type, {double intensity = 0.6}) {
    if (isBeautyActive(type)) {
      _beautyIntensities.remove(type);
    } else {
      _beautyIntensities[type] = intensity.clamp(0.0, 1.0);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Setters — hair color / style
  // ---------------------------------------------------------------------------

  void setHairColor(ARFilter? filter) {
    _activeHairColor = filter;
    notifyListeners();
  }

  void setHairStyle(ARFilter? filter) {
    _activeHairStyle = filter;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Setters — wig
  // ---------------------------------------------------------------------------

  /// Sets the active wig. Clears [activeHairStyle] when a wig is selected
  /// because wigs and hair style overlays conflict.
  void setWig(WigAsset? wig) {
    _activeWig = wig;
    if (wig != null) {
      _activeHairStyle = null;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Setters — overlays
  // ---------------------------------------------------------------------------

  /// Toggles an overlay filter.
  ///
  /// For [FilterCategory.lipColor]: single-select — selecting a new lip color
  /// replaces the existing one; tapping the active lip color deselects it.
  ///
  /// For all other categories: multi-toggle — each filter is independent.
  void toggleOverlay(ARFilter filter) {
    if (filter.category == FilterCategory.lipColor) {
      // Single-select behaviour
      final bool wasActive = _activeOverlays.contains(filter);
      _activeOverlays.removeWhere(
          (f) => f.category == FilterCategory.lipColor);
      if (!wasActive) {
        _activeOverlays.add(filter);
      }
    } else {
      if (_activeOverlays.contains(filter)) {
        _activeOverlays.remove(filter);
      } else {
        _activeOverlays.add(filter);
      }
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Setters — background
  // ---------------------------------------------------------------------------

  void setBackground(ARFilter? filter) {
    _activeBackground = filter;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Before/after toggle
  // ---------------------------------------------------------------------------

  void toggleBeforeAfter(bool show) {
    _showBeforeAfter = show;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Reset helpers
  // ---------------------------------------------------------------------------

  /// Clears all active filters and resets to defaults.
  void clearAll() {
    _colorPreset = ColorFilterPresets.none;
    _colorIntensity = 1.0;
    _beautyIntensities.clear();
    _activeOverlays.clear();
    _activeHairColor = null;
    _activeHairStyle = null;
    _activeWig = null;
    _activeBackground = null;
    _showBeforeAfter = false;
    notifyListeners();
  }

  /// Clears only the filters belonging to [category].
  void clearCategory(FilterCategory category) {
    switch (category) {
      case FilterCategory.colorFilter:
        _colorPreset = ColorFilterPresets.none;
        _colorIntensity = 1.0;
        break;
      case FilterCategory.beautyFilter:
        _beautyIntensities.clear();
        break;
      case FilterCategory.hairColor:
        _activeHairColor = null;
        break;
      case FilterCategory.hairStyle:
        _activeHairStyle = null;
        break;
      case FilterCategory.wigFilter:
        _activeWig = null;
        break;
      case FilterCategory.lipColor:
        _activeOverlays.removeWhere(
            (f) => f.category == FilterCategory.lipColor);
        break;
      case FilterCategory.accessories:
        _activeOverlays.removeWhere(
            (f) => f.category == FilterCategory.accessories);
        break;
      case FilterCategory.faceEffect:
        _activeOverlays.removeWhere(
            (f) => f.category == FilterCategory.faceEffect);
        break;
      case FilterCategory.backgroundEffect:
        _activeBackground = null;
        break;
    }
    notifyListeners();
  }
}
