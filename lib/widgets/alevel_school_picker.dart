// A-Level School & Combination Picker widget.
// STORY-007: Select A-Level school and combination (PCB, HGL, etc.).
// Design: DOCS/DESIGN.md (monochrome, touch targets 48dp min).
// APIs: GET /api/alevel-schools/*, GET /api/alevel-schools/combinations,
// GET /api/alevel-schools/{id}/combinations (combination per school).

import 'package:flutter/material.dart';
import '../models/secondary_models.dart';
import '../services/secondary_service.dart';

// Design tokens per DOCS/DESIGN.md
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kAccent = Color(0xFF999999);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const double _kMinTouchTarget = 48.0;

/// Result of A-Level selection for use by registration or profile.
class AlevelSelection {
  const AlevelSelection({
    this.school,
    this.combination,
    this.startYear,
    this.graduationYear,
  });

  final AlevelSchool? school;
  final AlevelCombination? combination;
  final int? startYear;
  final int? graduationYear;

  bool get isComplete =>
      school != null && combination != null && graduationYear != null;
}

class AlevelSchoolPicker extends StatefulWidget {
  final AlevelSchoolService alevelService;
  final ValueChanged<AlevelSelection>? onSelectionChanged;
  final AlevelSchool? initialSchool;
  final AlevelCombination? initialCombination;
  final int? initialStartYear;
  final int? initialGraduationYear;

  const AlevelSchoolPicker({
    super.key,
    required this.alevelService,
    this.onSelectionChanged,
    this.initialSchool,
    this.initialCombination,
    this.initialStartYear,
    this.initialGraduationYear,
  });

  @override
  State<AlevelSchoolPicker> createState() => _AlevelSchoolPickerState();
}

class _AlevelSchoolPickerState extends State<AlevelSchoolPicker> {
  final TextEditingController _searchController = TextEditingController();

  List<SecondaryRegion> _regions = [];
  List<SecondaryDistrict> _districts = [];
  List<AlevelSchool> _schools = [];
  List<AlevelSchool> _searchResults = [];
  List<AlevelCombination> _allCombinations = [];
  List<AlevelCombination> _schoolCombinations = [];

  SecondaryRegion? _selectedRegion;
  SecondaryDistrict? _selectedDistrict;
  AlevelSchool? _selectedSchool;
  AlevelCombination? _selectedCombination;
  int? _startYear;
  int? _graduationYear;

  bool _isLoadingRegions = true;
  bool _isLoadingDistricts = false;
  bool _isLoadingSchools = false;
  bool _isLoadingCombinations = false;
  bool _isSearching = false;
  bool _useSearch = false;
  String? _loadError;

  static final List<int> _graduationYears = List.generate(
    50,
    (i) => DateTime.now().year - i,
  );

  @override
  void initState() {
    super.initState();
    _selectedSchool = widget.initialSchool;
    _selectedCombination = widget.initialCombination;
    _startYear = widget.initialStartYear;
    _graduationYear = widget.initialGraduationYear;
    _loadRegions();
    _loadAllCombinations();
    if (widget.initialSchool != null) {
      _loadSchoolCombinations(widget.initialSchool!.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _notifySelection() {
    widget.onSelectionChanged?.call(AlevelSelection(
      school: _selectedSchool,
      combination: _selectedCombination,
      startYear: _startYear,
      graduationYear: _graduationYear,
    ));
  }

  Future<void> _loadRegions() async {
    if (!mounted) return;
    setState(() {
      _isLoadingRegions = true;
      _loadError = null;
    });
    try {
      final regions = await widget.alevelService.getRegions();
      if (!mounted) return;
      setState(() {
        _regions = regions;
        _isLoadingRegions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingRegions = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _loadAllCombinations() async {
    try {
      final combinations = await widget.alevelService.getCombinations();
      if (!mounted) return;
      setState(() {
        _allCombinations = combinations;
      });
    } catch (_) {
      // Fallback: school-specific combinations only
    }
  }

  Future<void> _loadDistricts(String regionCode) async {
    if (!mounted) return;
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _schools = [];
      _selectedDistrict = null;
      _selectedSchool = null;
      _selectedCombination = null;
      _loadError = null;
    });
    try {
      final districts = await widget.alevelService.getDistricts(regionCode);
      if (!mounted) return;
      setState(() {
        _districts = districts;
        _isLoadingDistricts = false;
      });
      _notifySelection();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingDistricts = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _loadSchools(String districtCode, {String? regionCode}) async {
    if (!mounted) return;
    setState(() {
      _isLoadingSchools = true;
      _schools = [];
      _selectedSchool = null;
      _selectedCombination = null;
      _loadError = null;
    });
    try {
      final schools = await widget.alevelService.getSchoolsInDistrict(
        districtCode,
        regionCode: regionCode,
      );
      if (!mounted) return;
      setState(() {
        _schools = schools;
        _isLoadingSchools = false;
      });
      _notifySelection();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSchools = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _loadSchoolCombinations(int schoolId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingCombinations = true;
      _schoolCombinations = [];
      _selectedCombination = null;
    });
    try {
      final combinations =
          await widget.alevelService.getSchoolCombinations(schoolId);
      if (!mounted) return;
      setState(() {
        _schoolCombinations = combinations.isNotEmpty
            ? combinations
            : _allCombinations;
        _isLoadingCombinations = false;
      });
      _notifySelection();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _schoolCombinations = _allCombinations;
        _isLoadingCombinations = false;
      });
      _notifySelection();
    }
  }

  Future<void> _searchSchools(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() {
      _isSearching = true;
      _loadError = null;
    });
    try {
      final results =
          await widget.alevelService.searchSchools(query, limit: 50);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _loadError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_loadError != null) _buildErrorBanner(),
        // Chagua / Tafuta toggle — min 48dp height
        _buildModeToggle(),
        const SizedBox(height: 16),
        if (_useSearch) ..._buildSearchSection() else ..._buildBrowseSection(),
        if (_selectedSchool != null) ...[
          const SizedBox(height: 24),
          _buildCombinationSection(),
        ],
        const SizedBox(height: 24),
        _buildStartYearDropdown(),
        const SizedBox(height: 16),
        _buildGraduationYearDropdown(),
        if (_selectedSchool != null &&
            _selectedCombination != null &&
            _graduationYear != null) ...[
          const SizedBox(height: 16),
          _buildSummaryCard(),
        ],
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAccent),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: _kSecondaryText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _loadError!,
              style: const TextStyle(
                fontSize: 12,
                color: _kSecondaryText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            height: _kMinTouchTarget,
            width: _kMinTouchTarget,
            child: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => setState(() => _loadError = null),
              style: IconButton.styleFrom(
                foregroundColor: _kSecondaryText,
                padding: EdgeInsets.zero,
                minimumSize: const Size(_kMinTouchTarget, _kMinTouchTarget),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _useSearch = false),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(minHeight: _kMinTouchTarget),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_useSearch ? _kSurface : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: !_useSearch
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Chagua',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          !_useSearch ? FontWeight.w600 : FontWeight.normal,
                      color: !_useSearch ? _kPrimaryText : _kSecondaryText,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _useSearch = true),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(minHeight: _kMinTouchTarget),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _useSearch ? _kSurface : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _useSearch
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Tafuta',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          _useSearch ? FontWeight.w600 : FontWeight.normal,
                      color: _useSearch ? _kPrimaryText : _kSecondaryText,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSearchSection() {
    return [
      TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Andika jina la shule...',
          hintStyle: const TextStyle(color: _kSecondaryText),
          prefixIcon: const Icon(Icons.search, color: _kPrimaryText),
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
          filled: true,
          fillColor: _kSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kAccent),
          ),
        ),
        onChanged: _searchSchools,
      ),
      if (_searchResults.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 220),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kAccent),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _searchResults.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: _kAccent.withValues(alpha: 0.5)),
            itemBuilder: (context, index) {
              final school = _searchResults[index];
              final isSelected = _selectedSchool?.id == school.id;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSchool = school;
                      _searchController.text = school.name;
                      _searchResults = [];
                    });
                    _loadSchoolCombinations(school.id);
                    _notifySelection();
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: _kMinTouchTarget),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                school.name,
                                style: TextStyle(
                                  fontWeight:
                                      isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: _kPrimaryText,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${school.district ?? ""}, ${school.region ?? ""}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kSecondaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        _buildTypeChip(school.type),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildBrowseSection() {
    return [
      _buildDropdown<SecondaryRegion>(
        label: 'Mkoa',
        hint: 'Chagua mkoa',
        value: _selectedRegion,
        items: _regions,
        isLoading: _isLoadingRegions,
        itemLabel: (r) => '${r.region} (${r.schoolCount})',
        onChanged: (region) {
          setState(() {
            _selectedRegion = region;
            _selectedSchool = null;
            _selectedCombination = null;
          });
          if (region != null) _loadDistricts(region.regionCode);
        },
      ),
      const SizedBox(height: 16),
      _buildDropdown<SecondaryDistrict>(
        label: 'Wilaya',
        hint: 'Chagua wilaya',
        value: _selectedDistrict,
        items: _districts,
        isLoading: _isLoadingDistricts,
        enabled: _selectedRegion != null,
        itemLabel: (d) => '${d.district} (${d.schoolCount})',
        onChanged: (district) {
          setState(() {
            _selectedDistrict = district;
            _selectedSchool = null;
            _selectedCombination = null;
          });
          if (district != null) {
            _loadSchools(
              district.districtCode,
              regionCode: _selectedRegion?.regionCode,
            );
          }
        },
      ),
      const SizedBox(height: 16),
      _buildDropdown<AlevelSchool>(
        label: 'Shule',
        hint: 'Chagua shule',
        value: _selectedSchool,
        items: _schools,
        isLoading: _isLoadingSchools,
        enabled: _selectedDistrict != null,
        itemLabel: (s) => s.name,
        onChanged: (school) {
          setState(() {
            _selectedSchool = school;
            _selectedCombination = null;
          });
          if (school != null) {
            _loadSchoolCombinations(school.id);
          }
          _notifySelection();
        },
      ),
    ];
  }

  Widget _buildCombinationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Combination',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kPrimaryText,
          ),
        ),
        const SizedBox(height: 8),
        _isLoadingCombinations
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : _buildCombinationGrid(),
      ],
    );
  }

  Widget _buildCombinationGrid() {
    final combos = _schoolCombinations.isNotEmpty
        ? _schoolCombinations
        : _allCombinations;

    final grouped = <String, List<AlevelCombination>>{};
    for (final combo in combos) {
      grouped.putIfAbsent(combo.category, () => []).add(combo);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: grouped.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _categoryLabel(entry.key),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kSecondaryText,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value.map((combo) {
                  final isSelected = _selectedCombination?.code == combo.code;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedCombination = combo);
                        _notifySelection();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: _kMinTouchTarget,
                          minWidth: 80,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? _kPrimaryText : _kSurface,
                          border: Border.all(
                            color: isSelected ? _kPrimaryText : _kAccent,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              combo.code,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected ? _kSurface : _kPrimaryText,
                              ),
                            ),
                            Text(
                              combo.subjects.join(', '),
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? _kSurface.withValues(alpha: 0.9)
                                    : _kSecondaryText,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'science':
        return 'SAYANSI';
      case 'business':
        return 'BIASHARA';
      case 'arts':
        return 'SANAA';
      case 'language':
        return 'LUGHA';
      case 'religious':
        return 'DINI';
      default:
        return category.toUpperCase();
    }
  }

  Widget _buildStartYearDropdown() {
    return _buildDropdown<int>(
      label: 'Mwaka wa Kuanza Form 5',
      hint: 'Chagua mwaka',
      value: _startYear,
      items: _graduationYears,
      itemLabel: (y) => y.toString(),
      onChanged: (year) {
        setState(() => _startYear = year);
        _notifySelection();
      },
    );
  }

  Widget _buildGraduationYearDropdown() {
    return _buildDropdown<int>(
      label: 'Mwaka wa Kumaliza Form 6',
      hint: 'Chagua mwaka',
      value: _graduationYear,
      items: _graduationYears,
      itemLabel: (y) => y.toString(),
      onChanged: (year) {
        setState(() => _graduationYear = year);
        _notifySelection();
      },
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kAccent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: _kPrimaryText, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedSchool!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _kPrimaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildTypeChip(_selectedSchool!.type),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 36),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _kPrimaryText,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedCombination!.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: _kSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedCombination!.name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kSecondaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    bool isLoading = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kPrimaryText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: _kMinTouchTarget + 8),
          decoration: BoxDecoration(
            color: enabled ? _kSurface : _kBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kAccent),
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        hint,
                        style: const TextStyle(color: _kSecondaryText),
                      ),
                    ),
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    menuMaxHeight: 300,
                    items: items
                        .map((item) => DropdownMenuItem<T>(
                              value: item,
                              child: Text(
                                itemLabel(item),
                                style: const TextStyle(
                                  color: _kPrimaryText,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: enabled ? onChanged : null,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String type) {
    final isGovernment = type == 'government';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isGovernment
            ? _kAccent.withValues(alpha: 0.2)
            : _kPrimaryText.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isGovernment ? 'Serikali' : 'Binafsi',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isGovernment ? _kSecondaryText : _kPrimaryText,
        ),
      ),
    );
  }
}
