import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/ar_filter_models.dart';
import '../models/color_filter_presets.dart';
import '../models/wig_asset.dart';
import '../services/filter_engine.dart';

// ---------------------------------------------------------------------------
// Private tab definition helper
// ---------------------------------------------------------------------------

class _TabDef {
  final FilterCategory category;
  final IconData icon;
  final String labelEn;
  final String labelSw;

  const _TabDef({
    required this.category,
    required this.icon,
    required this.labelEn,
    required this.labelSw,
  });
}

const List<_TabDef> _kTabs = [
  _TabDef(
    category: FilterCategory.colorFilter,
    icon: Icons.palette_rounded,
    labelEn: 'Filters',
    labelSw: 'Filters',
  ),
  _TabDef(
    category: FilterCategory.beautyFilter,
    icon: Icons.face_retouching_natural_rounded,
    labelEn: 'Beauty',
    labelSw: 'Urembo',
  ),
  _TabDef(
    category: FilterCategory.wigFilter,
    icon: Icons.content_cut_rounded,
    labelEn: 'Wigs',
    labelSw: 'Wigi',
  ),
  _TabDef(
    category: FilterCategory.hairColor,
    icon: Icons.color_lens_rounded,
    labelEn: 'Hair',
    labelSw: 'Nywele',
  ),
  _TabDef(
    category: FilterCategory.lipColor,
    icon: Icons.brush_rounded,
    labelEn: 'Lips',
    labelSw: 'Midomo',
  ),
  _TabDef(
    category: FilterCategory.accessories,
    icon: Icons.auto_awesome_rounded,
    labelEn: 'Acc.',
    labelSw: 'Mapambo',
  ),
  _TabDef(
    category: FilterCategory.faceEffect,
    icon: Icons.blur_on_rounded,
    labelEn: 'Effects',
    labelSw: 'Efekti',
  ),
  _TabDef(
    category: FilterCategory.backgroundEffect,
    icon: Icons.wallpaper_rounded,
    labelEn: 'BG',
    labelSw: 'Mandhari',
  ),
];

// ---------------------------------------------------------------------------
// FilterEngine extension: "is this category fully cleared?"
// ---------------------------------------------------------------------------

extension _FilterEngineExt on FilterEngine {
  bool isCategoryClear(FilterCategory cat) {
    switch (cat) {
      case FilterCategory.hairColor:
        return activeHairColor == null;
      case FilterCategory.hairStyle:
        return activeHairStyle == null;
      case FilterCategory.wigFilter:
        return activeWig == null;
      case FilterCategory.beautyFilter:
        return !isBeautyActive(FilterType.beautySmoothSkin) &&
            !isBeautyActive(FilterType.beautySlimFace) &&
            !isBeautyActive(FilterType.beautyBigEyes) &&
            !isBeautyActive(FilterType.beautyWhiteTeeth);
      case FilterCategory.backgroundEffect:
        return activeBackground == null;
      default:
        return !activeOverlays.any((f) => f.category == cat);
    }
  }
}

// ---------------------------------------------------------------------------
// FilterCarousel
// ---------------------------------------------------------------------------

/// Bottom-pinned filter carousel with 8 category tabs and horizontal scrolling
/// presets, driven by [FilterEngine].
class FilterCarousel extends StatefulWidget {
  final FilterEngine engine;
  final bool isSwahili;
  final Map<String, ui.Image>? wigPreviews;

  const FilterCarousel({
    super.key,
    required this.engine,
    required this.isSwahili,
    this.wigPreviews,
  });

  @override
  State<FilterCarousel> createState() => _FilterCarouselState();
}

class _FilterCarouselState extends State<FilterCarousel> {
  FilterCategory _selectedCategory = FilterCategory.colorFilter;

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool _isFilterActive(ARFilter filter) {
    final engine = widget.engine;
    switch (filter.category) {
      case FilterCategory.hairColor:
        return engine.activeHairColor == filter;
      case FilterCategory.hairStyle:
        return engine.activeHairStyle == filter;
      case FilterCategory.beautyFilter:
        return engine.isBeautyActive(filter.type);
      case FilterCategory.backgroundEffect:
        return engine.activeBackground == filter;
      default:
        return engine.isOverlayActive(filter);
    }
  }

  void _onFilterTapped(ARFilter filter) {
    final engine = widget.engine;
    switch (filter.category) {
      case FilterCategory.hairColor:
        final alreadyActive = engine.activeHairColor == filter;
        engine.setHairColor(alreadyActive ? null : filter);
        break;
      case FilterCategory.hairStyle:
        final alreadyActive = engine.activeHairStyle == filter;
        engine.setHairStyle(alreadyActive ? null : filter);
        break;
      case FilterCategory.beautyFilter:
        engine.toggleBeauty(filter.type, intensity: filter.defaultIntensity);
        break;
      case FilterCategory.backgroundEffect:
        final alreadyActive = engine.activeBackground == filter;
        engine.setBackground(alreadyActive ? null : filter);
        break;
      default:
        engine.toggleOverlay(filter);
        break;
    }
    setState(() {});
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            _buildTabs(),
            const SizedBox(height: 8),
            SizedBox(height: 80, child: _buildPresets()),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Tab row ──────────────────────────────────────────────────────────────

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: _kTabs.map((tab) {
          final selected = tab.category == _selectedCategory;
          final label = widget.isSwahili ? tab.labelSw : tab.labelEn;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = tab.category),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.30)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab.icon,
                    size: 18,
                    color: selected ? Colors.white : Colors.white54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      color: selected ? Colors.white : Colors.white54,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Preset panel dispatcher ───────────────────────────────────────────────

  Widget _buildPresets() {
    switch (_selectedCategory) {
      case FilterCategory.colorFilter:
        return _buildColorPresets();
      case FilterCategory.wigFilter:
        return _buildWigPresets();
      default:
        return _buildARPresets(
            ARFilterPresets.byCategory(_selectedCategory));
    }
  }

  // ── Color filter presets ─────────────────────────────────────────────────

  Widget _buildColorPresets() {
    final presets = ColorFilterPresets.all;
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final preset = presets[index];
        final active = widget.engine.colorPreset.id == preset.id;
        final isNone = preset.id == 'none';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            onTap: () {
              widget.engine.setColorPreset(preset);
              setState(() {});
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isNone
                        ? null
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              preset.previewTint,
                              preset.previewTint.withValues(alpha: 0.6),
                            ],
                          ),
                    color: isNone
                        ? Colors.white.withValues(alpha: 0.12)
                        : null,
                    border: Border.all(
                      color: active ? Colors.white : Colors.transparent,
                      width: active ? 2.5 : 1,
                    ),
                  ),
                  child: isNone
                      ? const Center(
                          child: Icon(
                            Icons.block_rounded,
                            color: Colors.white70,
                            size: 22,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 56,
                  child: Text(
                    widget.isSwahili ? preset.nameSw : preset.nameEn,
                    style: TextStyle(
                      fontSize: 9,
                      color: active ? Colors.white : Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Wig presets ──────────────────────────────────────────────────────────

  Widget _buildWigPresets() {
    final wigs = WigAssets.all;
    // index 0 = "None", indices 1..n = wigs
    final itemCount = wigs.length + 1;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          // "None" chip
          final noneActive = widget.engine.activeWig == null;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () {
                widget.engine.setWig(null);
                setState(() {});
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                      border: noneActive
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.block_rounded,
                        color: Colors.white70,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isSwahili ? 'Hakuna' : 'None',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }

        final wig = wigs[index - 1];
        final active = widget.engine.activeWig?.id == wig.id;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            onTap: () {
              widget.engine.setWig(active ? null : wig);
              setState(() {});
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: active ? Colors.white : Colors.transparent,
                      width: active ? 2.5 : 1,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      wig.assetPath,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => const Center(
                        child: Icon(
                          Icons.content_cut_rounded,
                          color: Colors.white54,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 56,
                  child: Text(
                    widget.isSwahili ? wig.nameSw : wig.nameEn,
                    style: TextStyle(
                      fontSize: 9,
                      color: active ? Colors.white : Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Generic AR filter presets ─────────────────────────────────────────────

  Widget _buildARPresets(List<ARFilter> presets) {
    // index 0 = "None", indices 1..n = presets
    final itemCount = presets.length + 1;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          // "None" chip — active when category is fully cleared
          final noneActive = widget.engine.isCategoryClear(_selectedCategory);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () {
                widget.engine.clearCategory(_selectedCategory);
                setState(() {});
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                      border: noneActive
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.block_rounded,
                        color: Colors.white70,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isSwahili ? 'Hakuna' : 'None',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }

        final filter = presets[index - 1];
        final active = _isFilterActive(filter);
        final hasColor = filter.color != null;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            onTap: () => _onFilterTapped(filter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasColor
                        ? filter.color
                        : Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: active ? Colors.white : Colors.transparent,
                      width: active ? 2.5 : 1,
                    ),
                  ),
                  child: hasColor
                      ? null
                      : Center(
                          child: Icon(
                            filter.icon,
                            color: Colors.white70,
                            size: 22,
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 56,
                  child: Text(
                    filter.name(widget.isSwahili),
                    style: TextStyle(
                      fontSize: 9,
                      color: active ? Colors.white : Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
