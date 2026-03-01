import 'package:flutter/material.dart';
import '../models/secondary_models.dart';
import '../services/secondary_service.dart';

/// Design: DOCS/DESIGN.md — monochrome, 48dp touch targets, overflow prevention.
/// Supports search by region, district, and name (GET /api/secondary-schools/*).
class SecondarySchoolPicker extends StatefulWidget {
  final SecondarySchoolService secondaryService;
  final ValueChanged<SecondarySchoolSelection?> onSelectionChanged;
  final SecondarySchool? initialSchool;

  const SecondarySchoolPicker({
    super.key,
    required this.secondaryService,
    required this.onSelectionChanged,
    this.initialSchool,
  });

  @override
  State<SecondarySchoolPicker> createState() => _SecondarySchoolPickerState();
}

class SecondarySchoolSelection {
  final SecondarySchool school;
  final SecondaryRegion? region;
  final SecondaryDistrict? district;

  SecondarySchoolSelection({
    required this.school,
    this.region,
    this.district,
  });
}

class _SecondarySchoolPickerState extends State<SecondarySchoolPicker> {
  final _searchController = TextEditingController();

  List<SecondaryRegion> _regions = [];
  List<SecondaryDistrict> _districts = [];
  List<SecondarySchool> _schools = [];
  List<SecondarySchool> _searchResults = [];

  SecondaryRegion? _selectedRegion;
  SecondaryDistrict? _selectedDistrict;
  SecondarySchool? _selectedSchool;

  bool _isLoadingRegions = true;
  bool _isLoadingDistricts = false;
  bool _isLoadingSchools = false;
  bool _isSearching = false;
  bool _useSearch = false;
  String? _error;

  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _accent = Color(0xFF999999);
  static const Color _white = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _selectedSchool = widget.initialSchool;
    _loadRegions();
  }

  @override
  void didUpdateWidget(SecondarySchoolPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSchool != widget.initialSchool) {
      _selectedSchool = widget.initialSchool;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    if (!mounted) return;
    try {
      final regions = await widget.secondaryService.getRegions();
      if (!mounted) return;
      setState(() {
        _regions = regions;
        _isLoadingRegions = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingRegions = false;
        _error = 'Imeshindwa kupakia mikoa. Jaribu tena.';
      });
    }
  }

  Future<void> _loadDistricts(String regionCode) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _schools = [];
      _selectedDistrict = null;
      _selectedSchool = null;
      _error = null;
    });

    try {
      final districts =
          await widget.secondaryService.getDistricts(regionCode);
      if (!mounted) return;
      setState(() {
        _districts = districts;
        _isLoadingDistricts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingDistricts = false;
        _error = 'Imeshindwa kupakia wilaya. Jaribu tena.';
      });
    }
  }

  Future<void> _loadSchools(String districtCode, String? regionCode) async {
    setState(() {
      _isLoadingSchools = true;
      _schools = [];
      _selectedSchool = null;
      _error = null;
    });

    try {
      final schools = await widget.secondaryService.getSchoolsInDistrict(
        districtCode,
        regionCode: regionCode,
      );
      if (!mounted) return;
      setState(() {
        _schools = schools;
        _isLoadingSchools = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSchools = false;
        _error = 'Imeshindwa kupakia shule. Jaribu tena.';
      });
    }
  }

  Future<void> _searchSchools(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await widget.secondaryService.searchSchools(
        query.trim(),
        limit: 50,
        regionCode: _selectedRegion?.regionCode,
        districtCode: _selectedDistrict?.districtCode,
      );
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _notifySelection() {
    if (_selectedSchool == null) {
      widget.onSelectionChanged(null);
      return;
    }
    widget.onSelectionChanged(SecondarySchoolSelection(
      school: _selectedSchool!,
      region: _selectedRegion,
      district: _selectedDistrict,
    ));
  }

  void _selectSchool(SecondarySchool school,
      {SecondaryRegion? region, SecondaryDistrict? district}) {
    setState(() {
      _selectedSchool = school;
      _selectedRegion = region;
      _selectedDistrict = district;
      _searchResults = [];
      _searchController.clear();
    });
    _notifySelection();
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
    _notifySelection();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildModeToggle(),
        const SizedBox(height: 16),
        if (_error != null) ...[
          _buildErrorBanner(),
          const SizedBox(height: 12),
        ],
        if (_useSearch) _buildSearchSection() else _buildBrowseSection(),
        if (_selectedSchool != null) ...[
          const SizedBox(height: 16),
          _buildSelectedCard(),
        ],
      ],
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TapTarget(
              minHeight: 48,
              onTap: () => setState(() {
                _useSearch = false;
                _clearSelection();
              }),
              isSelected: !_useSearch,
              child: Text(
                'Chagua',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _useSearch ? FontWeight.normal : FontWeight.w600,
                  color: _useSearch ? _secondaryText : _primaryText,
                ),
              ),
            ),
          ),
          Expanded(
            child: _TapTarget(
              minHeight: 48,
              onTap: () => setState(() {
                _useSearch = true;
                _clearSelection();
              }),
              isSelected: _useSearch,
              child: Text(
                'Tafuta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _useSearch ? FontWeight.w600 : FontWeight.normal,
                  color: _useSearch ? _primaryText : _secondaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
            color: _primaryText.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: _primaryText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                fontSize: 12,
                color: _primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Andika jina la shule, mkoa au wilaya',
            hintStyle: const TextStyle(color: _secondaryText, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: _primaryText),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (_searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: _primaryText),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null),
            filled: true,
            fillColor: _white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accent),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: _searchSchools,
        ),
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent),
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
              padding: EdgeInsets.zero,
              itemCount: _searchResults.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: _accent.withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final school = _searchResults[index];
                final isSelected = _selectedSchool?.id == school.id;
                return _TapTarget(
                  minHeight: 48,
                  onTap: () => _selectSchool(school),
                  child: Padding(
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
                                  color: _primaryText,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${school.district ?? ''}${school.region != null ? ', ${school.region}' : ''}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _secondaryText,
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
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBrowseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              _selectedDistrict = null;
              _selectedSchool = null;
              _districts = [];
              _schools = [];
            });
            if (region != null) {
              _loadDistricts(region.regionCode);
            }
            _notifySelection();
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
              _schools = [];
            });
            if (district != null) {
              _loadSchools(
                district.districtCode,
                _selectedRegion?.regionCode,
              );
            }
            _notifySelection();
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown<SecondarySchool>(
          label: 'Shule',
          hint: 'Chagua shule',
          value: _selectedSchool,
          items: _schools,
          isLoading: _isLoadingSchools,
          enabled: _selectedDistrict != null,
          itemLabel: (s) => s.name,
          onChanged: (school) {
            setState(() => _selectedSchool = school);
            _notifySelection();
          },
        ),
      ],
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
    Widget content;

    if (isLoading) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (!enabled || items.isEmpty) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Text(
          items.isEmpty && enabled ? 'Hakuna data' : hint,
          style: const TextStyle(color: _secondaryText, fontSize: 14),
        ),
      );
    } else {
      content = DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              hint,
              style: const TextStyle(color: _secondaryText, fontSize: 14),
            ),
          ),
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          menuMaxHeight: 300,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      itemLabel(item),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: enabled && items.isNotEmpty ? _white : _accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accent),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: content,
        ),
      ],
    );
  }

  Widget _buildSelectedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primaryText,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check,
              color: _white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedSchool!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _primaryText,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  _selectedSchool!.code,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildTypeChip(_selectedSchool!.type),
          const SizedBox(width: 8),
          _TapTarget(
            minHeight: 48,
            minWidth: 48,
            onTap: _clearSelection,
            child: const Icon(Icons.close, color: _primaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    final isGovernment = type == 'government';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _primaryText.withValues(alpha: isGovernment ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isGovernment ? 'Serikali' : 'Binafsi',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _primaryText,
        ),
      ),
    );
  }
}

class _TapTarget extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final double minHeight;
  final double minWidth;
  final bool isSelected;

  const _TapTarget({
    required this.onTap,
    required this.child,
    this.minHeight = 48,
    this.minWidth = 48,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? _TapTargetColors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      elevation: isSelected ? 2 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: minHeight,
            minWidth: minWidth,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _TapTargetColors {
  static const white = Color(0xFFFFFFFF);
}
