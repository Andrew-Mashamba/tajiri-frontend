import 'dart:async';

import 'package:flutter/material.dart';

import '../../../config/api_config.dart';
import '../../../models/registration_models.dart';
import '../../../models/secondary_models.dart';
import '../../../services/education_service.dart';
import '../../../services/school_service.dart';
import '../../../services/secondary_service.dart';
import '../../../widgets/year_chip_selector.dart';

/// Reusable school search step for all education levels.
///
/// Supports four [schoolType] values:
///   - 'primary'       → queries [SchoolService] → stores [RegistrationState.primarySchool]
///   - 'secondary'     → queries [SecondarySchoolService] → stores [RegistrationState.secondarySchool]
///   - 'alevel'        → queries [AlevelSchoolService] → stores [RegistrationState.alevelEducation]
///   - 'postsecondary' → queries [SecondarySchoolService] → stores [RegistrationState.postsecondaryEducation]
///
/// Design: DOCS/DESIGN.md — monochrome #1A1A1A / #FAFAFA, 12 px radius, 48 dp targets.
class SchoolStep extends StatefulWidget {
  /// One of: 'primary', 'secondary', 'alevel', 'postsecondary'.
  final String schoolType;

  /// Conversational question displayed as the large heading.
  final String question;

  /// Label for the skip button, e.g. "Sijasoma msingi".
  final String skipText;

  /// Centre year for the [YearChipSelector] (calculated from DOB by the caller).
  final int defaultGradYear;

  /// How many years to show on each side of [defaultGradYear].
  final int yearRange;

  /// Show the combination picker after a school is selected (A-level only).
  final bool showCombination;

  final RegistrationState state;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  const SchoolStep({
    super.key,
    required this.schoolType,
    required this.question,
    required this.skipText,
    required this.defaultGradYear,
    this.yearRange = 3,
    this.showCombination = false,
    required this.state,
    required this.onNext,
    this.onBack,
    this.onSkip,
  });

  @override
  State<SchoolStep> createState() => _SchoolStepState();
}

class _SchoolStepState extends State<SchoolStep> {
  // -------------------------------------------------------------------------
  // Design tokens
  // -------------------------------------------------------------------------
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE0E0E0);

  // -------------------------------------------------------------------------
  // Services (lazy-constructed once from ApiConfig.baseUrl)
  // -------------------------------------------------------------------------
  late final SchoolService _primaryService;
  late final SecondarySchoolService _secondaryService;
  late final AlevelSchoolService _alevelService;
  final PostsecondaryService _postsecondaryService = PostsecondaryService();

  // -------------------------------------------------------------------------
  // Search state
  // -------------------------------------------------------------------------
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;

  bool _isSearching = false;
  List<_SchoolItem> _suggestions = [];
  bool _dropdownVisible = false;

  // -------------------------------------------------------------------------
  // Selection state
  // -------------------------------------------------------------------------
  _SchoolItem? _selectedSchool;
  int? _graduationYear;

  // A-level combination
  bool _isLoadingCombinations = false;
  List<AlevelCombination> _combinations = [];
  AlevelCombination? _selectedCombination;

  // Postsecondary programme/course (free text)
  final TextEditingController _programmeCtrl = TextEditingController();

  // -------------------------------------------------------------------------
  // Computed
  // -------------------------------------------------------------------------
  bool get _isPostsecondary => widget.schoolType == 'postsecondary';

  bool get _isComplete {
    if (_selectedSchool == null || _graduationYear == null) return false;
    if (widget.showCombination) return _selectedCombination != null;
    if (_isPostsecondary) return _programmeCtrl.text.trim().isNotEmpty;
    return true;
  }

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api$'), '');
    _primaryService = SchoolService(baseUrl: base);
    _secondaryService = SecondarySchoolService(baseUrl: base);
    _alevelService = AlevelSchoolService(baseUrl: base);

    _prefillFromState();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _programmeCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Pre-fill from saved state
  // -------------------------------------------------------------------------

  void _prefillFromState() {
    _SchoolItem? saved;

    switch (widget.schoolType) {
      case 'primary':
        final e = widget.state.primarySchool;
        if (e?.schoolId != null) saved = _schoolItemFromEntry(e!);
        _graduationYear = e?.graduationYear;
      case 'secondary':
        final e = widget.state.secondarySchool;
        if (e?.schoolId != null) saved = _schoolItemFromEntry(e!);
        _graduationYear = e?.graduationYear;
      case 'alevel':
        final a = widget.state.alevelEducation;
        if (a?.schoolId != null) {
          saved = _SchoolItem(
            id: a!.schoolId!,
            code: a.schoolCode ?? '',
            name: a.schoolName ?? '',
            type: a.schoolType ?? 'unknown',
            region: a.regionName,
            district: a.districtName,
          );
          _graduationYear = a.graduationYear;
          if (a.combinationCode != null && a.combinationName != null) {
            _selectedCombination = AlevelCombination(
              id: 0,
              code: a.combinationCode!,
              name: a.combinationName!,
              category: '',
              popularity: 'medium',
              subjects: a.subjects ?? [],
            );
          }
        }
      case 'postsecondary':
        final e = widget.state.postsecondaryEducation;
        if (e?.schoolId != null) saved = _schoolItemFromEntry(e!);
        _graduationYear = e?.graduationYear;
        if (e?.programmeName != null) _programmeCtrl.text = e!.programmeName!;
    }

    if (saved != null) {
      _selectedSchool = saved;
      _searchCtrl.text = saved.name;
    }
  }

  _SchoolItem _schoolItemFromEntry(EducationEntry e) {
    return _SchoolItem(
      id: e.schoolId!,
      code: e.schoolCode ?? '',
      name: e.schoolName ?? '',
      type: e.schoolType ?? 'unknown',
      region: e.regionName,
      district: e.districtName,
    );
  }

  // -------------------------------------------------------------------------
  // Search
  // -------------------------------------------------------------------------

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _dropdownVisible = false;
        _isSearching = false;
        // Clear selection if user clears the field
        if (query.trim().isEmpty) {
          _selectedSchool = null;
          _selectedCombination = null;
        }
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(query.trim()));
  }

  Future<void> _runSearch(String query) async {
    final results = await _fetchResults(query);
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _dropdownVisible = results.isNotEmpty;
      _isSearching = false;
    });
  }

  Future<List<_SchoolItem>> _fetchResults(String query) async {
    switch (widget.schoolType) {
      case 'primary':
        final list = await _primaryService.searchSchools(query);
        return list
            .map((s) => _SchoolItem(
                  id: s.id,
                  code: s.code,
                  name: s.name,
                  type: s.type,
                  region: s.region,
                  district: s.district,
                ))
            .toList();
      case 'secondary':
        final list = await _secondaryService.searchSchools(query);
        return list
            .map((s) => _SchoolItem(
                  id: s.id,
                  code: s.code,
                  name: s.name,
                  type: s.type,
                  region: s.region,
                  district: s.district,
                ))
            .toList();
      case 'postsecondary':
        final list = await _postsecondaryService.search(query);
        return list
            .map((s) => _SchoolItem(
                  id: s.id,
                  code: s.code,
                  name: s.name,
                  type: s.type,
                  region: s.region,
                ))
            .toList();
      case 'alevel':
        final list = await _alevelService.searchSchools(query);
        return list
            .map((s) => _SchoolItem(
                  id: s.id,
                  code: s.code,
                  name: s.name,
                  type: s.type,
                  region: s.region,
                  district: s.district,
                ))
            .toList();
      default:
        final list = await _secondaryService.searchSchools(query);
        return list
            .map((s) => _SchoolItem(
                  id: s.id,
                  code: s.code,
                  name: s.name,
                  type: s.type,
                  region: s.region,
                  district: s.district,
                ))
            .toList();
    }
  }

  void _selectSchool(_SchoolItem school) {
    setState(() {
      _selectedSchool = school;
      _searchCtrl.text = school.name;
      _dropdownVisible = false;
      _suggestions = [];
      _selectedCombination = null; // reset combination on school change
    });
    _searchFocus.unfocus();

    if (widget.showCombination) {
      _loadCombinations(school.id);
    }
  }

  // -------------------------------------------------------------------------
  // A-level combinations
  // -------------------------------------------------------------------------

  Future<void> _loadCombinations(int schoolId) async {
    setState(() => _isLoadingCombinations = true);
    final list = await _alevelService.getSchoolCombinations(schoolId);
    if (!mounted) return;
    final fallback = list.isEmpty ? await _alevelService.getCombinations() : list;
    setState(() {
      _combinations = fallback;
      _isLoadingCombinations = false;
    });
  }

  // -------------------------------------------------------------------------
  // Submit
  // -------------------------------------------------------------------------

  void _submit() {
    if (!_isComplete) return;
    final school = _selectedSchool!;

    switch (widget.schoolType) {
      case 'primary':
        widget.state.primarySchool = EducationEntry(
          schoolId: school.id,
          schoolCode: school.code,
          schoolName: school.name,
          schoolType: school.type,
          graduationYear: _graduationYear,
          regionName: school.region,
          districtName: school.district,
        );
      case 'secondary':
        widget.state.secondarySchool = EducationEntry(
          schoolId: school.id,
          schoolCode: school.code,
          schoolName: school.name,
          schoolType: school.type,
          graduationYear: _graduationYear,
          regionName: school.region,
          districtName: school.district,
        );
      case 'alevel':
        final combo = _selectedCombination;
        widget.state.alevelEducation = AlevelEducation(
          schoolId: school.id,
          schoolCode: school.code,
          schoolName: school.name,
          schoolType: school.type,
          graduationYear: _graduationYear,
          combinationCode: combo?.code,
          combinationName: combo?.name,
          subjects: combo?.subjects,
          regionName: school.region,
          districtName: school.district,
        );
      case 'postsecondary':
        widget.state.postsecondaryEducation = EducationEntry(
          schoolId: school.id,
          schoolCode: school.code,
          schoolName: school.name,
          schoolType: school.type,
          graduationYear: _graduationYear,
          regionName: school.region,
          districtName: school.district,
          programmeName: _programmeCtrl.text.trim(),
        );
    }

    widget.onNext();
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: () {
          _searchFocus.unfocus();
          if (_dropdownVisible) setState(() => _dropdownVisible = false);
        },
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchField(),
                      if (_dropdownVisible) ...[
                        const SizedBox(height: 4),
                        _buildDropdown(),
                      ],
                      if (_selectedSchool != null && !_dropdownVisible) ...[
                        const SizedBox(height: 8),
                        _buildSelectedChip(),
                      ],
                      const SizedBox(height: 24),
                      _buildLabel('Mwaka wa Kuhitimu'),
                      const SizedBox(height: 10),
                      YearChipSelector(
                        defaultYear: widget.defaultGradYear,
                        startYear: 1950,
                        endYear: 2030,
                        selectedYear: _graduationYear,
                        onYearSelected: (y) => setState(() => _graduationYear = y),
                      ),
                      if (_isPostsecondary && _selectedSchool != null) ...[
                        const SizedBox(height: 24),
                        _buildProgrammeField(),
                      ],
                      if (widget.showCombination && _selectedSchool != null) ...[
                        const SizedBox(height: 24),
                        _buildCombinationSection(),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              _buildActionRow(),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Sub-builders
  // -------------------------------------------------------------------------

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.question,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: _primary,
            height: 1.2,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        const Text(
          'Andika jina la shule ili utafute',
          style: TextStyle(
            fontSize: 15,
            color: _secondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

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

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
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
      child: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        style: const TextStyle(fontSize: 15, color: _primary),
        decoration: InputDecoration(
          hintText: 'Tafuta shule...',
          hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 15),
          prefixIcon: const Icon(Icons.search_rounded, color: _secondary, size: 20),
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _secondary,
                    ),
                  ),
                )
              : _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: _secondary),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {
                          _selectedSchool = null;
                          _suggestions = [];
                          _dropdownVisible = false;
                          _selectedCombination = null;
                        });
                      },
                    )
                  : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _suggestions.length,
        separatorBuilder: (_, i) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
        itemBuilder: (context, index) {
          final item = _suggestions[index];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _selectSchool(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.region != null || item.district != null)
                    Text(
                      [item.district, item.region]
                          .where((s) => s != null && s.isNotEmpty)
                          .join(', '),
                      style: const TextStyle(fontSize: 12, color: _secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedChip() {
    final school = _selectedSchool!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCCCCCC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: _primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              school.name,
              style: const TextStyle(
                fontSize: 13,
                color: _primary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (school.region != null && school.region!.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              school.region!,
              style: const TextStyle(fontSize: 12, color: _secondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgrammeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Programme / Kozi'),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _surface,
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
          child: TextField(
            controller: _programmeCtrl,
            style: const TextStyle(fontSize: 15, color: _primary),
            decoration: const InputDecoration(
              hintText: 'mfano: Electrical Installation, Ualimu Daraja A...',
              hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
              prefixIcon: Icon(Icons.school_rounded, color: _secondary, size: 20),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildCombinationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Mchanganyiko (Combination)'),
        const SizedBox(height: 10),
        if (_isLoadingCombinations)
          const Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: _secondary),
            ),
          )
        else if (_combinations.isEmpty)
          const Text(
            'Hakuna mchanganyiko uliopo',
            style: TextStyle(fontSize: 13, color: _secondary),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _combinations.length,
              separatorBuilder: (_, i) =>
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
              itemBuilder: (context, index) {
                final combo = _combinations[index];
                final isSelected = _selectedCombination?.code == combo.code;
                return InkWell(
                  onTap: () => setState(() => _selectedCombination = combo),
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
                            children: [
                              Text(
                                combo.code,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? _primary : _secondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                combo.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _secondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: _primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildActionRow() {
    final hasSkip = widget.onSkip != null;
    return Row(
      children: [
        if (hasSkip) ...[
          Expanded(
            child: _buildSkipButton(),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: hasSkip ? 2 : 1,
          child: _buildNextButton(),
        ),
      ],
    );
  }

  Widget _buildSkipButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: widget.onSkip,
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: const BorderSide(color: Color(0xFFCCCCCC)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          widget.skipText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _secondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final enabled = _isComplete;
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.45,
        child: FilledButton(
          onPressed: enabled ? _submit : null,
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
              Icon(Icons.arrow_forward, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal data transfer object — normalises School / SecondarySchool / AlevelSchool
// ---------------------------------------------------------------------------

class _SchoolItem {
  final int id;
  final String code;
  final String name;
  final String type;
  final String? region;
  final String? district;

  const _SchoolItem({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.region,
    this.district,
  });
}
