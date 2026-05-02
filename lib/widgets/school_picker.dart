import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_strings_scope.dart';
import '../models/school_models.dart';
import '../services/school_service.dart';

/// Design: DOCS/DESIGN.md — monochrome palette, touch targets 48dp min.
/// Primary school picker with search and region/district filters.
/// STORY-005: Select primary school from Tanzania database (16,000+ schools).
class SchoolPicker extends StatefulWidget {
  final SchoolService schoolService;
  final ValueChanged<SelectedSchool> onSchoolChanged;
  /// Optional initial selection (e.g. when returning to registration step).
  final SelectedSchool? initialSelection;

  const SchoolPicker({
    super.key,
    required this.schoolService,
    required this.onSchoolChanged,
    this.initialSelection,
  });

  @override
  State<SchoolPicker> createState() => _SchoolPickerState();
}

class _SchoolPickerState extends State<SchoolPicker> {
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _accent = Color(0xFF999999);
  static const Color _background = Color(0xFFFAFAFA);

  bool _isLoading = false;
  bool _loadFailed = false;
  bool _useSearch = false;

  List<SchoolRegion> _regions = [];
  List<SchoolDistrict> _districts = [];
  List<School> _schools = [];
  List<School> _searchResults = [];

  SchoolRegion? _selectedRegion;
  SchoolDistrict? _selectedDistrict;
  School? _selectedSchool;

  // Search filters (for filter-by-region/district in search mode)
  SchoolRegion? _filterRegion;
  SchoolDistrict? _filterDistrict;
  List<SchoolDistrict> _filterDistricts = [];

  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  Timer? _searchDebounce;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    if (widget.initialSelection != null) {
      _selectedRegion = widget.initialSelection!.region;
      _selectedDistrict = widget.initialSelection!.district;
      _selectedSchool = widget.initialSelection!.school;
    }
    _loadRegions();
  }

  @override
  void didUpdateWidget(SchoolPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelection != widget.initialSelection &&
        widget.initialSelection != null) {
      _selectedRegion = widget.initialSelection!.region;
      _selectedDistrict = widget.initialSelection!.district;
      _selectedSchool = widget.initialSelection!.school;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final regions = await widget.schoolService.getRegions();
      if (mounted) {
        setState(() {
          _regions = regions;
          _isLoading = false;
          _loadFailed = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadFailed = true;
        });
      }
    }
  }

  Future<void> _loadDistricts(String regionCode) async {
    setState(() {
      _isLoading = true;
      _districts = [];
      _schools = [];
      _selectedDistrict = null;
      _selectedSchool = null;
    });
    try {
      final districts = await widget.schoolService.getDistricts(regionCode);
      if (mounted) {
        setState(() {
          _districts = districts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadFilterDistricts(String regionCode) async {
    setState(() {
      _filterDistricts = [];
      _filterDistrict = null;
    });
    try {
      final districts = await widget.schoolService.getDistricts(regionCode);
      if (mounted) {
        setState(() {
          _filterDistricts = districts;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadSchools(String districtCode) async {
    setState(() {
      _isLoading = true;
      _schools = [];
      _selectedSchool = null;
    });
    try {
      final schools =
          await widget.schoolService.getSchoolsInDistrict(districtCode);
      if (mounted) {
        setState(() {
          _schools = schools;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _searchSchools(String query) {
    setState(() => _searchQuery = query);
    _searchDebounce?.cancel();
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    _searchDebounce = Timer(_searchDebounceDuration, () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() => _isSearching = true);
    try {
      final results = await widget.schoolService.searchSchools(
        query,
        regionCode: _filterRegion?.regionCode,
        districtCode: _filterDistrict?.districtCode,
        limit: 30,
      );
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _notifyChange() {
    widget.onSchoolChanged(SelectedSchool(
      region: _selectedRegion,
      district: _selectedDistrict,
      school: _selectedSchool,
    ));
  }

  void _selectSchoolFromSearch(School school) {
    setState(() {
      _selectedSchool = school;
      _searchResults = [];
      _searchController.clear();
      _searchQuery = '';
    });
    widget.onSchoolChanged(SelectedSchool(
      region: null,
      district: null,
      school: school,
    ));
  }

  void _clearSelection() {
    setState(() {
      _selectedRegion = null;
      _selectedDistrict = null;
      _selectedSchool = null;
      _districts = [];
      _schools = [];
      _searchResults = [];
      _searchController.clear();
    });
    _notifyChange();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    // Once a school is picked, collapse all the input UI and show only
    // the selected card. Tapping its X clears the selection and reopens
    // the inputs (the close button calls _clearSelection() which nulls
    // _selectedSchool, flipping the conditional below).
    if (_selectedSchool != null) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [_buildSelectedSchoolChip()],
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Browse / Search toggle — min 48dp height
          SizedBox(
            height: 48,
            child: Row(
              children: [
                Expanded(
                  child: _SegmentTap(
                    label: s?.pickerBrowse ?? 'Browse',
                    icon: Icons.list_rounded,
                    selected: !_useSearch,
                    onTap: () {
                      setState(() {
                        _useSearch = false;
                        _clearSelection();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _SegmentTap(
                    label: s?.pickerSearch ?? 'Search',
                    icon: Icons.search_rounded,
                    selected: _useSearch,
                    onTap: () {
                      setState(() {
                        _useSearch = true;
                        _clearSelection();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_useSearch) ...[
            _buildSearchField(),
            _buildSearchFilters(),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            if (_searchResults.isNotEmpty) _buildSearchResultsList(),
          ] else ...[
            if (_loadFailed) _buildRetryMessage(),
            _buildRegionDropdown(),
            const SizedBox(height: 12),
            _buildDistrictDropdown(),
            const SizedBox(height: 12),
            _buildSchoolDropdown(),
          ],

          if (_isLoading && !_useSearch)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final s = AppStringsScope.of(context);
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: s?.pickerSearchSchoolField ?? 'Search schools',
        hintText: s?.pickerSearchSchoolHint ?? 'Type school name or code',
        hintStyle: const TextStyle(color: _secondaryText, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: _primaryText, size: 24),
        suffixIcon: _searchQuery.isNotEmpty
            ? Semantics(
                label: s?.pickerClearText ?? 'Clear text',
                child: IconButton(
                  icon: const Icon(Icons.clear, color: _primaryText),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                      _searchQuery = '';
                    });
                  },
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                ),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: const TextStyle(color: _primaryText, fontSize: 14),
      onChanged: _searchSchools,
    );
  }

  Widget _buildSearchFilters() {
    final s = AppStringsScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterDropdown<SchoolRegion>(
              label: s?.regionLabel ?? 'Region',
              value: _filterRegion,
              items: _regions,
              itemLabel: (r) => r.region,
              onChanged: (v) {
                setState(() {
                  _filterRegion = v;
                  _filterDistrict = null;
                  _filterDistricts = [];
                  if (v != null) _loadFilterDistricts(v.regionCode);
                  if (_searchController.text.length >= 2) {
                    _performSearch(_searchController.text);
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFilterDropdown<SchoolDistrict>(
              label: s?.districtLabel ?? 'District',
              value: _filterDistrict,
              items: _filterDistricts,
              itemLabel: (d) => d.district,
              onChanged: _filterRegion == null
                  ? (_) {}
                  : (v) {
                      setState(() {
                        _filterDistrict = v;
                        if (_searchController.text.length >= 2) {
                          _performSearch(_searchController.text);
                        }
                      });
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _secondaryText, fontSize: 12),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      hint: Text(label, style: const TextStyle(color: _secondaryText)),
      isExpanded: true,
      borderRadius: BorderRadius.circular(12),
      menuMaxHeight: 300,
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemLabel(item),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(color: _primaryText, fontSize: 14),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSearchResultsList() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final school = _searchResults[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectSchoolFromSearch(school),
              borderRadius: BorderRadius.circular(0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              school.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: _primaryText,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              '${school.code} · ${school.district ?? ''}, ${school.region ?? ''}',
                              style: const TextStyle(
                                color: _secondaryText,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTypeChip(school.type),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRetryMessage() {
    final s = AppStringsScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: _loadRegions,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                const Icon(Icons.cloud_off_outlined, color: _secondaryText),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s?.pickerErrLoadRegionsTap ??
                        'Could not load regions. Tap to try again.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _secondaryText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Semantics(
                  label: s?.pickerTryAgain ?? 'Try again',
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: _primaryText),
                    onPressed: _loadRegions,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegionDropdown() {
    final s = AppStringsScope.of(context);
    return _buildDropdown<SchoolRegion>(
      label: s?.regionLabel ?? 'Region',
      hint: s?.pickerSelectRegion ?? 'Select region',
      icon: Icons.map_outlined,
      value: _selectedRegion,
      items: _regions,
      itemLabel: (r) => '${r.region} (${r.schoolCount})',
      onChanged: (value) {
        setState(() {
          _selectedRegion = value;
          _selectedDistrict = null;
          _selectedSchool = null;
          _districts = [];
          _schools = [];
        });
        if (value != null) _loadDistricts(value.regionCode);
        _notifyChange();
      },
    );
  }

  Widget _buildDistrictDropdown() {
    final s = AppStringsScope.of(context);
    return _buildDropdown<SchoolDistrict>(
      label: s?.districtLabel ?? 'District',
      hint: s?.pickerSelectDistrict ?? 'Select district',
      icon: Icons.location_city_outlined,
      value: _selectedDistrict,
      items: _districts,
      enabled: _selectedRegion != null,
      itemLabel: (d) => '${d.district} (${d.schoolCount})',
      onChanged: (value) {
        setState(() {
          _selectedDistrict = value;
          _selectedSchool = null;
          _schools = [];
        });
        if (value != null) _loadSchools(value.districtCode);
        _notifyChange();
      },
    );
  }

  Widget _buildSchoolDropdown() {
    final s = AppStringsScope.of(context);
    return _buildDropdown<School>(
      label: s?.pickerSchool ?? 'School',
      hint: s?.pickerSelectSchool ?? 'Select school',
      icon: Icons.school_outlined,
      value: _selectedSchool,
      items: _schools,
      enabled: _selectedDistrict != null,
      itemLabel: (s) => s.name,
      onChanged: (value) {
        setState(() => _selectedSchool = value);
        _notifyChange();
      },
      menuMaxHeight: 300,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required IconData icon,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    bool enabled = true,
    double? menuMaxHeight,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _secondaryText, fontSize: 12),
        prefixIcon: Icon(icon, color: _primaryText, size: 24),
        filled: true,
        fillColor: enabled ? Colors.white : _background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      hint: Text(hint, style: const TextStyle(color: _secondaryText)),
      isExpanded: true,
      borderRadius: BorderRadius.circular(12),
      menuMaxHeight: menuMaxHeight ?? 300,
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemLabel(item),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(color: _primaryText, fontSize: 14),
                ),
              ))
          .toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _buildSelectedSchoolChip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: _primaryText, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedSchool!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _primaryText,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  'Code: ${_selectedSchool!.code}',
                  style: const TextStyle(color: _secondaryText, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Semantics(
            label: AppStringsScope.of(context)?.pickerClearSelection ?? 'Clear selection',
            child: IconButton(
              icon: const Icon(Icons.close, color: _primaryText),
              onPressed: _clearSelection,
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    final s = AppStringsScope.of(context);
    final isGovernment = type == 'government';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isGovernment
            ? _accent.withValues(alpha: 0.2)
            : _primaryText.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isGovernment
            ? (s?.pickerOwnershipGovernment ?? 'Government')
            : (s?.pickerOwnershipPrivate ?? 'Private'),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isGovernment ? _secondaryText : _primaryText,
        ),
      ),
    );
  }
}

class _SegmentTap extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentTap({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : const Color(0xFFFAFAFA),
      borderRadius: BorderRadius.circular(12),
      elevation: selected ? 2 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? const Color(0xFF1A1A1A) : const Color(0xFF666666),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? const Color(0xFF1A1A1A) : const Color(0xFF666666),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
