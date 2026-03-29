import 'package:flutter/material.dart';

import '../../../config/api_config.dart';
import '../../../models/location_models.dart';
import '../../../models/registration_models.dart';
import '../../../services/location_service.dart';

/// Chapter 2, Screen 2: Cascading location search.
///
/// Unaishi wapi? — Region → District → Ward (optional) → Street (optional)
/// Each level uses a type-ahead text field that filters the loaded list.
/// "Endelea →" enabled once region + district are selected.
/// "Sitaki kusema" skip clears location and calls [onSkip] or [onNext].
class LocationStep extends StatefulWidget {
  final RegistrationState state;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  const LocationStep({
    super.key,
    required this.state,
    required this.onNext,
    this.onBack,
    this.onSkip,
  });

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const Color _fieldBg = Colors.white;
  static const Color _border = Color(0xFFE0E0E0);
  static const Color _divider = Color(0xFFEEEEEE);

  late final LocationService _service;

  // ── Data lists ──────────────────────────────────────────────────────────────
  List<Region> _regions = [];
  List<District> _districts = [];
  List<Ward> _wards = [];
  List<Street> _streets = [];

  // ── Selected values ──────────────────────────────────────────────────────────
  Region? _region;
  District? _district;
  Ward? _ward;
  Street? _street;

  // ── Text controllers ─────────────────────────────────────────────────────────
  late final TextEditingController _regionCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _wardCtrl;
  late final TextEditingController _streetCtrl;

  // ── Focus nodes ──────────────────────────────────────────────────────────────
  final FocusNode _regionFocus = FocusNode();
  final FocusNode _districtFocus = FocusNode();
  final FocusNode _wardFocus = FocusNode();
  final FocusNode _streetFocus = FocusNode();

  // ── Filtered lists ───────────────────────────────────────────────────────────
  List<Region> _filteredRegions = [];
  List<District> _filteredDistricts = [];
  List<Ward> _filteredWards = [];
  List<Street> _filteredStreets = [];

  // ── Loading states ────────────────────────────────────────────────────────────
  bool _loadingRegions = false;
  bool _loadingDistricts = false;
  bool _loadingWards = false;
  bool _loadingStreets = false;

  String? _error;

  // ── Layer link for each dropdown anchor ──────────────────────────────────────
  final LayerLink _regionLink = LayerLink();
  final LayerLink _districtLink = LayerLink();
  final LayerLink _wardLink = LayerLink();
  final LayerLink _streetLink = LayerLink();

  // ── Overlay entries ───────────────────────────────────────────────────────────
  OverlayEntry? _regionOverlay;
  OverlayEntry? _districtOverlay;
  OverlayEntry? _wardOverlay;
  OverlayEntry? _streetOverlay;

  @override
  void initState() {
    super.initState();
    _service = LocationService(baseUrl: ApiConfig.baseUrl);

    // Pre-fill from state (user navigated back)
    final loc = widget.state.location;
    _regionCtrl = TextEditingController(text: loc?.regionName ?? '');
    _districtCtrl = TextEditingController(text: loc?.districtName ?? '');
    _wardCtrl = TextEditingController(text: loc?.wardName ?? '');
    _streetCtrl = TextEditingController(text: loc?.streetName ?? '');

    _regionFocus.addListener(_onRegionFocusChange);
    _districtFocus.addListener(_onDistrictFocusChange);
    _wardFocus.addListener(_onWardFocusChange);
    _streetFocus.addListener(_onStreetFocusChange);

    _loadRegions();
  }

  @override
  void dispose() {
    _removeAllOverlays();
    _regionCtrl.dispose();
    _districtCtrl.dispose();
    _wardCtrl.dispose();
    _streetCtrl.dispose();
    _regionFocus.removeListener(_onRegionFocusChange);
    _districtFocus.removeListener(_onDistrictFocusChange);
    _wardFocus.removeListener(_onWardFocusChange);
    _streetFocus.removeListener(_onStreetFocusChange);
    _regionFocus.dispose();
    _districtFocus.dispose();
    _wardFocus.dispose();
    _streetFocus.dispose();
    super.dispose();
  }

  // ── Focus listeners ──────────────────────────────────────────────────────────

  void _onRegionFocusChange() {
    if (_regionFocus.hasFocus) {
      _filter(_regionCtrl.text, level: 0);
      _showDropdown(level: 0);
    } else {
      _hideDropdown(level: 0);
      // If user typed something but didn't select, restore committed value
      if (_region != null && _regionCtrl.text != _region!.name) {
        _regionCtrl.text = _region!.name;
      }
    }
  }

  void _onDistrictFocusChange() {
    if (_districtFocus.hasFocus) {
      _filter(_districtCtrl.text, level: 1);
      _showDropdown(level: 1);
    } else {
      _hideDropdown(level: 1);
      if (_district != null && _districtCtrl.text != _district!.name) {
        _districtCtrl.text = _district!.name;
      }
    }
  }

  void _onWardFocusChange() {
    if (_wardFocus.hasFocus) {
      _filter(_wardCtrl.text, level: 2);
      _showDropdown(level: 2);
    } else {
      _hideDropdown(level: 2);
      if (_ward != null && _wardCtrl.text != _ward!.name) {
        _wardCtrl.text = _ward!.name;
      }
    }
  }

  void _onStreetFocusChange() {
    if (_streetFocus.hasFocus) {
      _filter(_streetCtrl.text, level: 3);
      _showDropdown(level: 3);
    } else {
      _hideDropdown(level: 3);
      if (_street != null && _streetCtrl.text != _street!.name) {
        _streetCtrl.text = _street!.name;
      }
    }
  }

  // ── Data loading ──────────────────────────────────────────────────────────────

  Future<void> _loadRegions() async {
    setState(() {
      _loadingRegions = true;
      _error = null;
    });
    try {
      final regions = await _service.getRegions();
      if (!mounted) return;
      setState(() {
        _regions = regions;
        _filteredRegions = regions;
        _loadingRegions = false;
      });
      // Pre-select if navigating back
      final loc = widget.state.location;
      if (loc?.regionId != null) {
        final match = regions.where((r) => r.id == loc!.regionId).toList();
        if (match.isNotEmpty) {
          _selectRegion(match.first, loadNext: true);
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Imeshindwa kupakia mikoa. Gonga kurudia.';
        _loadingRegions = false;
      });
    }
  }

  Future<void> _loadDistricts(int regionId) async {
    setState(() {
      _loadingDistricts = true;
      _error = null;
    });
    try {
      final districts = await _service.getDistricts(regionId);
      if (!mounted) return;
      setState(() {
        _districts = districts;
        _filteredDistricts = districts;
        _loadingDistricts = false;
      });
      // Pre-select if navigating back
      final loc = widget.state.location;
      if (loc?.districtId != null) {
        final match =
            districts.where((d) => d.id == loc!.districtId).toList();
        if (match.isNotEmpty) {
          _selectDistrict(match.first, loadNext: true);
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Imeshindwa kupakia wilaya. Gonga kurudia.';
        _loadingDistricts = false;
      });
    }
  }

  Future<void> _loadWards(int districtId) async {
    setState(() {
      _loadingWards = true;
      _error = null;
    });
    try {
      final wards = await _service.getWards(districtId);
      if (!mounted) return;
      setState(() {
        _wards = wards;
        _filteredWards = wards;
        _loadingWards = false;
      });
      final loc = widget.state.location;
      if (loc?.wardId != null) {
        final match = wards.where((w) => w.id == loc!.wardId).toList();
        if (match.isNotEmpty) {
          _selectWard(match.first, loadNext: true);
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Imeshindwa kupakia kata. Gonga kurudia.';
        _loadingWards = false;
      });
    }
  }

  Future<void> _loadStreets(int wardId) async {
    setState(() {
      _loadingStreets = true;
      _error = null;
    });
    try {
      final streets = await _service.getStreets(wardId);
      if (!mounted) return;
      setState(() {
        _streets = streets;
        _filteredStreets = streets;
        _loadingStreets = false;
      });
      final loc = widget.state.location;
      if (loc?.streetId != null) {
        final match = streets.where((s) => s.id == loc!.streetId).toList();
        if (match.isNotEmpty) {
          _selectStreet(match.first);
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Imeshindwa kupakia mitaa. Gonga kurudia.';
        _loadingStreets = false;
      });
    }
  }

  // ── Selection handlers ────────────────────────────────────────────────────────

  void _selectRegion(Region region, {bool loadNext = false}) {
    _hideDropdown(level: 0);
    setState(() {
      _region = region;
      _regionCtrl.text = region.name;
      // Reset downstream
      _district = null;
      _ward = null;
      _street = null;
      _districtCtrl.text = '';
      _wardCtrl.text = '';
      _streetCtrl.text = '';
      _districts = [];
      _wards = [];
      _streets = [];
      _filteredDistricts = [];
      _filteredWards = [];
      _filteredStreets = [];
    });
    _persistState();
    if (loadNext || true) {
      _loadDistricts(region.id);
    }
  }

  void _selectDistrict(District district, {bool loadNext = false}) {
    _hideDropdown(level: 1);
    setState(() {
      _district = district;
      _districtCtrl.text = district.name;
      // Reset downstream
      _ward = null;
      _street = null;
      _wardCtrl.text = '';
      _streetCtrl.text = '';
      _wards = [];
      _streets = [];
      _filteredWards = [];
      _filteredStreets = [];
    });
    _persistState();
    if (loadNext || true) {
      _loadWards(district.id);
    }
  }

  void _selectWard(Ward ward, {bool loadNext = false}) {
    _hideDropdown(level: 2);
    setState(() {
      _ward = ward;
      _wardCtrl.text = ward.name;
      // Reset downstream
      _street = null;
      _streetCtrl.text = '';
      _streets = [];
      _filteredStreets = [];
    });
    _persistState();
    if (loadNext || true) {
      _loadStreets(ward.id);
    }
  }

  void _selectStreet(Street street) {
    _hideDropdown(level: 3);
    setState(() {
      _street = street;
      _streetCtrl.text = street.name;
    });
    _persistState();
  }

  void _persistState() {
    if (_region != null && _district != null) {
      widget.state.location = LocationSelection(
        regionId: _region!.id,
        regionName: _region!.name,
        districtId: _district!.id,
        districtName: _district!.name,
        wardId: _ward?.id,
        wardName: _ward?.name,
        streetId: _street?.id,
        streetName: _street?.name,
      );
    } else {
      widget.state.location = null;
    }
  }

  // ── Filtering ─────────────────────────────────────────────────────────────────

  void _filter(String query, {required int level}) {
    final q = query.toLowerCase().trim();
    setState(() {
      switch (level) {
        case 0:
          _filteredRegions = q.isEmpty
              ? _regions
              : _regions
                  .where((r) => r.name.toLowerCase().contains(q))
                  .toList();
        case 1:
          _filteredDistricts = q.isEmpty
              ? _districts
              : _districts
                  .where((d) => d.name.toLowerCase().contains(q))
                  .toList();
        case 2:
          _filteredWards = q.isEmpty
              ? _wards
              : _wards
                  .where((w) => w.name.toLowerCase().contains(q))
                  .toList();
        case 3:
          _filteredStreets = q.isEmpty
              ? _streets
              : _streets
                  .where((s) => s.name.toLowerCase().contains(q))
                  .toList();
      }
    });
    _updateOverlay(level: level);
  }

  // ── Overlay management ────────────────────────────────────────────────────────

  void _showDropdown({required int level}) {
    _updateOverlay(level: level);
  }

  void _hideDropdown({required int level}) {
    switch (level) {
      case 0:
        _regionOverlay?.remove();
        _regionOverlay = null;
      case 1:
        _districtOverlay?.remove();
        _districtOverlay = null;
      case 2:
        _wardOverlay?.remove();
        _wardOverlay = null;
      case 3:
        _streetOverlay?.remove();
        _streetOverlay = null;
    }
  }

  void _removeAllOverlays() {
    _regionOverlay?.remove();
    _districtOverlay?.remove();
    _wardOverlay?.remove();
    _streetOverlay?.remove();
    _regionOverlay = null;
    _districtOverlay = null;
    _wardOverlay = null;
    _streetOverlay = null;
  }

  void _updateOverlay({required int level}) {
    switch (level) {
      case 0:
        _regionOverlay?.remove();
        _regionOverlay = null;
        if (_filteredRegions.isEmpty) return;
        _regionOverlay = _buildOverlayEntry(
          link: _regionLink,
          items: _filteredRegions,
          labelOf: (r) => r.name,
          onSelect: (r) => _selectRegion(r as Region),
        );
        Overlay.of(context).insert(_regionOverlay!);
      case 1:
        _districtOverlay?.remove();
        _districtOverlay = null;
        if (_filteredDistricts.isEmpty) return;
        _districtOverlay = _buildOverlayEntry(
          link: _districtLink,
          items: _filteredDistricts,
          labelOf: (d) => d.name,
          onSelect: (d) => _selectDistrict(d as District),
        );
        Overlay.of(context).insert(_districtOverlay!);
      case 2:
        _wardOverlay?.remove();
        _wardOverlay = null;
        if (_filteredWards.isEmpty) return;
        _wardOverlay = _buildOverlayEntry(
          link: _wardLink,
          items: _filteredWards,
          labelOf: (w) => w.name,
          onSelect: (w) => _selectWard(w as Ward),
        );
        Overlay.of(context).insert(_wardOverlay!);
      case 3:
        _streetOverlay?.remove();
        _streetOverlay = null;
        if (_filteredStreets.isEmpty) return;
        _streetOverlay = _buildOverlayEntry(
          link: _streetLink,
          items: _filteredStreets,
          labelOf: (s) => s.name,
          onSelect: (s) => _selectStreet(s as Street),
        );
        Overlay.of(context).insert(_streetOverlay!);
    }
  }

  OverlayEntry _buildOverlayEntry({
    required LayerLink link,
    required List<dynamic> items,
    required String Function(dynamic) labelOf,
    required void Function(dynamic) onSelect,
  }) {
    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 320,
          child: CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            offset: const Offset(0, 56),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: _fieldBg,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, sep) =>
                      const Divider(height: 1, color: _divider),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return InkWell(
                      onTap: () => onSelect(item),
                      borderRadius: i == 0
                          ? const BorderRadius.vertical(
                              top: Radius.circular(12))
                          : i == items.length - 1
                              ? const BorderRadius.vertical(
                                  bottom: Radius.circular(12))
                              : BorderRadius.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        child: Text(
                          labelOf(item),
                          style: const TextStyle(
                              fontSize: 15, color: _primary),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Readiness ────────────────────────────────────────────────────────────────

  bool get _canProceed => _region != null && _district != null;

  // ── Handlers ──────────────────────────────────────────────────────────────────

  void _handleNext() {
    if (!_canProceed) return;
    _persistState();
    widget.onNext();
  }

  void _handleSkip() {
    widget.state.location = null;
    final cb = widget.onSkip ?? widget.onNext;
    cb();
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Heading ───────────────────────────────────────────────────
              const Text(
                'Unaishi wapi?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hii husaidia kupata watu wa karibu nawe',
                style: TextStyle(
                  fontSize: 15,
                  color: _secondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // ── Error banner ──────────────────────────────────────────────
              if (_error != null) ...[
                _buildErrorBanner(),
                const SizedBox(height: 16),
              ],

              // ── Fields (scrollable) ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Region
                      _buildLabel('Mkoa'),
                      const SizedBox(height: 6),
                      CompositedTransformTarget(
                        link: _regionLink,
                        child: _buildSearchField(
                          controller: _regionCtrl,
                          focus: _regionFocus,
                          hint: 'Tafuta mkoa...',
                          isLoading: _loadingRegions,
                          isLocked: false,
                          selectedValue: _region?.name,
                          onChanged: (v) => _filter(v, level: 0),
                          onClear: () {
                            setState(() {
                              _region = null;
                              _regionCtrl.clear();
                              _district = null;
                              _districtCtrl.clear();
                              _ward = null;
                              _wardCtrl.clear();
                              _street = null;
                              _streetCtrl.clear();
                              _districts = [];
                              _wards = [];
                              _streets = [];
                              _filteredDistricts = [];
                              _filteredWards = [];
                              _filteredStreets = [];
                            });
                            _persistState();
                          },
                        ),
                      ),

                      // District — shown after region selected
                      if (_region != null) ...[
                        const SizedBox(height: 16),
                        _buildLabel('Wilaya'),
                        const SizedBox(height: 6),
                        CompositedTransformTarget(
                          link: _districtLink,
                          child: _buildSearchField(
                            controller: _districtCtrl,
                            focus: _districtFocus,
                            hint: 'Tafuta wilaya...',
                            isLoading: _loadingDistricts,
                            isLocked: false,
                            selectedValue: _district?.name,
                            onChanged: (v) => _filter(v, level: 1),
                            onClear: () {
                              setState(() {
                                _district = null;
                                _districtCtrl.clear();
                                _ward = null;
                                _wardCtrl.clear();
                                _street = null;
                                _streetCtrl.clear();
                                _wards = [];
                                _streets = [];
                                _filteredWards = [];
                                _filteredStreets = [];
                              });
                              _persistState();
                            },
                          ),
                        ),
                      ],

                      // Ward — shown after district selected (optional)
                      if (_district != null) ...[
                        const SizedBox(height: 16),
                        _buildOptionalLabel('Kata', 'hiari'),
                        const SizedBox(height: 6),
                        CompositedTransformTarget(
                          link: _wardLink,
                          child: _buildSearchField(
                            controller: _wardCtrl,
                            focus: _wardFocus,
                            hint: 'Tafuta kata...',
                            isLoading: _loadingWards,
                            isLocked: false,
                            selectedValue: _ward?.name,
                            onChanged: (v) => _filter(v, level: 2),
                            onClear: () {
                              setState(() {
                                _ward = null;
                                _wardCtrl.clear();
                                _street = null;
                                _streetCtrl.clear();
                                _streets = [];
                                _filteredStreets = [];
                              });
                              _persistState();
                            },
                          ),
                        ),
                      ],

                      // Street — shown after ward selected (optional)
                      if (_ward != null) ...[
                        const SizedBox(height: 16),
                        _buildOptionalLabel('Mtaa', 'hiari'),
                        const SizedBox(height: 6),
                        CompositedTransformTarget(
                          link: _streetLink,
                          child: _buildSearchField(
                            controller: _streetCtrl,
                            focus: _streetFocus,
                            hint: 'Tafuta mtaa...',
                            isLoading: _loadingStreets,
                            isLocked: false,
                            selectedValue: _street?.name,
                            onChanged: (v) => _filter(v, level: 3),
                            onClear: () {
                              setState(() {
                                _street = null;
                                _streetCtrl.clear();
                              });
                              _persistState();
                            },
                          ),
                        ),
                      ],

                      // Location summary chip
                      if (_canProceed) ...[
                        const SizedBox(height: 20),
                        _buildSummaryChip(),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // ── Buttons ───────────────────────────────────────────────────
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sub-builders ─────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _secondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildOptionalLabel(String text, String badge) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _secondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 10,
              color: _secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required FocusNode focus,
    required String hint,
    required bool isLoading,
    required bool isLocked,
    required String? selectedValue,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
  }) {
    final hasValue = selectedValue != null;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasValue ? _primary.withValues(alpha: 0.35) : _border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _secondary,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Inapakia...',
                    style: TextStyle(fontSize: 14, color: _secondary),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded, size: 18, color: _secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focus,
                    style: const TextStyle(fontSize: 15, color: _primary),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(
                        color: Color(0xFFBBBBBB),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: onChanged,
                  ),
                ),
                if (hasValue)
                  GestureDetector(
                    onTap: onClear,
                    child: Container(
                      width: 48,
                      height: 52,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: _secondary,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 12),
              ],
            ),
    );
  }

  Widget _buildSummaryChip() {
    final parts = <String>[];
    if (_street != null) parts.add(_street!.name);
    if (_ward != null) parts.add(_ward!.name);
    if (_district != null) parts.add(_district!.name);
    if (_region != null) parts.add(_region!.name);
    final address = parts.join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.location_on_outlined, size: 18, color: _primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              address,
              style: const TextStyle(fontSize: 14, color: _primary, height: 1.4),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: _primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(fontSize: 13, color: _primary),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _loadRegions,
            child: Container(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              alignment: Alignment.center,
              child: const Icon(Icons.refresh_rounded, size: 20, color: _primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // "Endelea →"
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _canProceed ? 1.0 : 0.45,
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _canProceed ? _handleNext : null,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                disabledBackgroundColor: _primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Endelea',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // "Sitaki kusema" skip
        SizedBox(
          height: 44,
          child: TextButton(
            onPressed: _handleSkip,
            style: TextButton.styleFrom(
              foregroundColor: _secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Sitaki kusema',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}
