import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/education_models.dart';
import '../../../models/registration_models.dart';
import '../../../services/education_service.dart';
import '../../../widgets/tap_chip_selector.dart';
import '../../../widgets/year_chip_selector.dart';

/// Chapter 3: University → College → Department → Programme → Degree → Year.
///
/// Cascading selection: each level filters the next. Writes result to
/// [state.universityEducation] before calling [onNext].
class UniversityStep extends StatefulWidget {
  final RegistrationState state;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  /// Centre year for the graduation [YearChipSelector].
  final int defaultGradYear;

  const UniversityStep({
    super.key,
    required this.state,
    required this.onNext,
    this.onBack,
    this.onSkip,
    required this.defaultGradYear,
  });

  @override
  State<UniversityStep> createState() => _UniversityStepState();
}

// ---------------------------------------------------------------------------
// Degree level enum
// ---------------------------------------------------------------------------
enum _DegreeLevel { bachelor, masters, phd }

extension _DegreeLevelX on _DegreeLevel {
  String get label {
    switch (this) {
      case _DegreeLevel.bachelor:
        return 'Shahada';
      case _DegreeLevel.masters:
        return 'Uzamili';
      case _DegreeLevel.phd:
        return 'Uzamivu';
    }
  }

  String get apiValue {
    switch (this) {
      case _DegreeLevel.bachelor:
        return 'bachelor';
      case _DegreeLevel.masters:
        return 'masters';
      case _DegreeLevel.phd:
        return 'phd';
    }
  }

  static _DegreeLevel? fromApiValue(String? value) {
    if (value == null) return null;
    for (final level in _DegreeLevel.values) {
      if (level.apiValue == value) return level;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _UniversityStepState extends State<UniversityStep> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const Color _border = Color(0xFFE0E0E0);
  static const Color _fieldBg = Colors.white;

  final _uniService = UniversityDetailedService();

  // --- controllers
  final TextEditingController _uniSearchCtrl = TextEditingController();
  final TextEditingController _progSearchCtrl = TextEditingController();

  // --- university search
  List<UniversityDetailed> _uniResults = [];
  bool _uniSearching = false;
  Timer? _uniDebounce;

  // --- selected university
  UniversityDetailed? _selectedUniversity;

  // --- college (loaded after university selected)
  List<UniversityCollege> _colleges = [];
  bool _collegesLoading = false;
  UniversityCollege? _selectedCollege;

  // --- department (loaded after college selected)
  List<UniversityDepartment> _departments = [];
  bool _departmentsLoading = false;
  UniversityDepartment? _selectedDepartment;

  // --- programme search (filtered by department → college → university)
  List<UniversityProgramme> _progResults = [];
  bool _progSearching = false;
  Timer? _progDebounce;

  // --- selected programme
  UniversityProgramme? _selectedProgramme;

  // --- degree level
  _DegreeLevel? _degreeLevel;

  // --- "still studying"
  bool _isCurrentStudent = false;

  // --- graduation year
  int? _graduationYear;

  @override
  void initState() {
    super.initState();
    _preload();
  }

  void _preload() {
    final existing = widget.state.universityEducation;
    if (existing == null) return;

    // University
    if (existing.universityId != null) {
      _selectedUniversity = UniversityDetailed(
        id: existing.universityId!,
        code: existing.universityCode ?? '',
        name: existing.universityName ?? '',
        type: '',
      );
      _uniSearchCtrl.text = existing.universityName ?? '';

      // Load colleges for pre-selected university
      _loadColleges(existing.universityId!);
    }

    // College
    if (existing.collegeId != null) {
      _selectedCollege = UniversityCollege(
        id: existing.collegeId!,
        code: '',
        name: existing.collegeName ?? '',
        universityId: existing.universityId ?? 0,
      );
      _loadDepartments(existing.collegeId!);
    }

    // Department
    if (existing.departmentId != null) {
      _selectedDepartment = UniversityDepartment(
        id: existing.departmentId!,
        code: '',
        name: existing.departmentName ?? '',
        collegeId: existing.collegeId ?? 0,
      );
    }

    // Programme
    if (existing.programmeId != null) {
      _selectedProgramme = UniversityProgramme(
        id: existing.programmeId!,
        code: '',
        name: existing.programmeName ?? '',
        levelCode: existing.degreeLevel ?? '',
        duration: 0,
        universityId: existing.universityId ?? 0,
      );
      _progSearchCtrl.text = existing.programmeName ?? '';
    }

    _degreeLevel = _DegreeLevelX.fromApiValue(existing.degreeLevel);
    _isCurrentStudent = existing.isCurrentStudent;
    _graduationYear = existing.graduationYear;
  }

  @override
  void dispose() {
    _uniSearchCtrl.dispose();
    _progSearchCtrl.dispose();
    _uniDebounce?.cancel();
    _progDebounce?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // University search
  // ---------------------------------------------------------------------------

  void _onUniQueryChanged(String query) {
    _uniDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _uniResults = []);
      return;
    }
    _uniDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchUniversities(query.trim());
    });
  }

  Future<void> _searchUniversities(String query) async {
    if (!mounted) return;
    setState(() => _uniSearching = true);
    try {
      final results = await _uniService.search(query);
      if (!mounted) return;
      setState(() {
        _uniResults = results;
        _uniSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _uniSearching = false);
    }
  }

  void _selectUniversity(UniversityDetailed uni) {
    setState(() {
      _selectedUniversity = uni;
      _uniSearchCtrl.text = uni.displayName;
      _uniResults = [];
      // Reset all downstream
      _selectedCollege = null;
      _colleges = [];
      _selectedDepartment = null;
      _departments = [];
      _selectedProgramme = null;
      _progSearchCtrl.clear();
      _progResults = [];
      _degreeLevel = null;
    });
    _loadColleges(uni.id);
  }

  void _clearUniversity() {
    setState(() {
      _selectedUniversity = null;
      _uniSearchCtrl.clear();
      _uniResults = [];
      _selectedCollege = null;
      _colleges = [];
      _selectedDepartment = null;
      _departments = [];
      _selectedProgramme = null;
      _progSearchCtrl.clear();
      _progResults = [];
      _degreeLevel = null;
    });
  }

  // ---------------------------------------------------------------------------
  // College loading
  // ---------------------------------------------------------------------------

  Future<void> _loadColleges(int universityId) async {
    setState(() => _collegesLoading = true);
    try {
      final results = await _uniService.getColleges(universityId);
      if (!mounted) return;
      setState(() {
        _colleges = results;
        _collegesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _collegesLoading = false);
    }
  }

  void _selectCollege(UniversityCollege college) {
    setState(() {
      _selectedCollege = college;
      // Reset downstream
      _selectedDepartment = null;
      _departments = [];
      _selectedProgramme = null;
      _progSearchCtrl.clear();
      _progResults = [];
      _degreeLevel = null;
    });
    _loadDepartments(college.id);
  }

  void _clearCollege() {
    setState(() {
      _selectedCollege = null;
      _selectedDepartment = null;
      _departments = [];
      _selectedProgramme = null;
      _progSearchCtrl.clear();
      _progResults = [];
      _degreeLevel = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Department loading
  // ---------------------------------------------------------------------------

  Future<void> _loadDepartments(int collegeId) async {
    setState(() => _departmentsLoading = true);
    try {
      final results = await _uniService.getDepartments(collegeId);
      if (!mounted) return;
      setState(() {
        _departments = results;
        _departmentsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _departmentsLoading = false);
    }
  }

  void _selectDepartment(UniversityDepartment dept) {
    setState(() {
      _selectedDepartment = dept;
      // Reset downstream
      _selectedProgramme = null;
      _progSearchCtrl.clear();
      _progResults = [];
      _degreeLevel = null;
    });
  }

  void _clearDepartment() {
    setState(() {
      _selectedDepartment = null;
      _selectedProgramme = null;
      _progSearchCtrl.clear();
      _progResults = [];
      _degreeLevel = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Programme search
  // ---------------------------------------------------------------------------

  void _onProgQueryChanged(String query) {
    _progDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _progResults = []);
      return;
    }
    _progDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchProgrammes(query.trim());
    });
  }

  Future<void> _searchProgrammes(String query) async {
    if (!mounted) return;
    setState(() => _progSearching = true);
    try {
      List<UniversityProgramme> results;

      if (_selectedDepartment != null) {
        // Filter by department
        results = await _uniService
            .getProgrammesByDepartment(_selectedDepartment!.id)
            .then((all) => all
                .where((p) =>
                    p.name.toLowerCase().contains(query.toLowerCase()))
                .toList());
      } else if (_selectedUniversity != null) {
        // Filter by university
        results = await _uniService.searchProgrammes(query).then((all) => all
            .where((p) => p.universityId == _selectedUniversity!.id)
            .toList());
      } else {
        results = await _uniService.searchProgrammes(query);
      }

      if (!mounted) return;
      setState(() {
        _progResults = results;
        _progSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _progSearching = false);
    }
  }

  void _selectProgramme(UniversityProgramme prog) {
    // Infer degree level from programme's levelCode if none chosen yet.
    _DegreeLevel? inferred;
    final lc = prog.levelCode.toUpperCase();
    if (lc.contains('PHD') || lc == 'DOCTORATE') {
      inferred = _DegreeLevel.phd;
    } else if (lc.contains('MSC') || lc.contains('MASTER')) {
      inferred = _DegreeLevel.masters;
    } else if (lc.contains('BSC') || lc.contains('BACHELOR') ||
        lc.contains('BENG') || lc.contains('MD')) {
      inferred = _DegreeLevel.bachelor;
    }

    setState(() {
      _selectedProgramme = prog;
      _progSearchCtrl.text = prog.name;
      _progResults = [];
      if (inferred != null && _degreeLevel == null) {
        _degreeLevel = inferred;
      }
    });
  }

  void _clearProgramme() {
    setState(() {
      _selectedProgramme = null;
      _progSearchCtrl.clear();
      _progResults = [];
    });
  }

  // ---------------------------------------------------------------------------
  // Form validity
  // ---------------------------------------------------------------------------

  bool get _canContinue =>
      _selectedUniversity != null &&
      _selectedProgramme != null &&
      _degreeLevel != null &&
      (_isCurrentStudent || _graduationYear != null);

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  void _handleNext() {
    if (!_canContinue) return;

    widget.state.universityEducation = UniversityEducation(
      universityId: _selectedUniversity!.id,
      universityCode: _selectedUniversity!.code,
      universityName: _selectedUniversity!.displayName,
      collegeId: _selectedCollege?.id,
      collegeName: _selectedCollege?.name,
      departmentId: _selectedDepartment?.id,
      departmentName: _selectedDepartment?.name,
      programmeId: _selectedProgramme!.id,
      programmeName: _selectedProgramme!.name,
      degreeLevel: _degreeLevel!.apiValue,
      startYear: null,
      graduationYear: _isCurrentStudent ? null : _graduationYear,
      isCurrentStudent: _isCurrentStudent,
    );

    widget.onNext();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeading(),
                  const SizedBox(height: 32),
                  _buildUniversitySection(),
                  if (_selectedUniversity != null) ...[
                    const SizedBox(height: 20),
                    _buildCollegeSection(),
                  ],
                  if (_selectedCollege != null) ...[
                    const SizedBox(height: 20),
                    _buildDepartmentSection(),
                  ],
                  if (_selectedDepartment != null ||
                      (_selectedUniversity != null && _colleges.isEmpty && !_collegesLoading)) ...[
                    const SizedBox(height: 20),
                    _buildProgrammeSection(),
                  ],
                  if (_selectedProgramme != null) ...[
                    const SizedBox(height: 20),
                    _buildDegreeLevelSection(),
                    const SizedBox(height: 20),
                    _buildCurrentStudentToggle(),
                    const SizedBox(height: 20),
                    _buildGradYearSection(),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section builders
  // ---------------------------------------------------------------------------

  Widget _buildHeading() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chuo Kikuu gani?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: _primary,
            height: 1.2,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Na programme yako',
          style: TextStyle(
            fontSize: 15,
            color: _secondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildUniversitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Chuo Kikuu'),
        const SizedBox(height: 6),
        _buildSearchField(
          controller: _uniSearchCtrl,
          hint: 'Tafuta chuo kikuu (mfano: UDSM, Dar es Salaam)...',
          isLoading: _uniSearching,
          isSelected: _selectedUniversity != null,
          onChanged: _selectedUniversity == null ? _onUniQueryChanged : null,
          onClear: _clearUniversity,
        ),
        if (_uniResults.isNotEmpty)
          _buildDropdownList<UniversityDetailed>(
            items: _uniResults,
            labelBuilder: (u) => u.displayName,
            subtitleBuilder: (u) => u.typeLabel,
            onTap: _selectUniversity,
          ),
      ],
    );
  }

  Widget _buildCollegeSection() {
    if (_collegesLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('College / Faculty'),
          const SizedBox(height: 10),
          const Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: _secondary),
            ),
          ),
        ],
      );
    }

    if (_colleges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('College / Faculty'),
        const SizedBox(height: 6),
        _buildSelectionList<UniversityCollege>(
          items: _colleges,
          selectedItem: _selectedCollege,
          labelBuilder: (c) => c.name,
          subtitleBuilder: (c) => c.typeLabel,
          isSelected: (c) => _selectedCollege?.id == c.id,
          onTap: _selectCollege,
          onClear: _clearCollege,
        ),
      ],
    );
  }

  Widget _buildDepartmentSection() {
    if (_departmentsLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Department'),
          const SizedBox(height: 10),
          const Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: _secondary),
            ),
          ),
        ],
      );
    }

    if (_departments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Department'),
        const SizedBox(height: 6),
        _buildSelectionList<UniversityDepartment>(
          items: _departments,
          selectedItem: _selectedDepartment,
          labelBuilder: (d) => d.name,
          subtitleBuilder: (_) => '',
          isSelected: (d) => _selectedDepartment?.id == d.id,
          onTap: _selectDepartment,
          onClear: _clearDepartment,
        ),
      ],
    );
  }

  Widget _buildProgrammeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Programme'),
        const SizedBox(height: 6),
        _buildSearchField(
          controller: _progSearchCtrl,
          hint: 'Tafuta programme (mfano: Economics, Medicine)...',
          isLoading: _progSearching,
          isSelected: _selectedProgramme != null,
          onChanged: _selectedProgramme == null ? _onProgQueryChanged : null,
          onClear: _clearProgramme,
        ),
        if (_progResults.isNotEmpty)
          _buildDropdownList<UniversityProgramme>(
            items: _progResults,
            labelBuilder: (p) => p.name,
            subtitleBuilder: (p) => '${p.levelLabel} • ${p.duration} yr',
            onTap: _selectProgramme,
          ),
      ],
    );
  }

  Widget _buildDegreeLevelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Kiwango cha shahada'),
        const SizedBox(height: 10),
        TapChipSelector<_DegreeLevel>(
          options: _DegreeLevel.values,
          selectedOption: _degreeLevel,
          labelBuilder: (d) => d.label,
          onSelected: (d) => setState(() => _degreeLevel = d),
          horizontal: true,
        ),
      ],
    );
  }

  Widget _buildCurrentStudentToggle() {
    return Container(
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
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        title: const Text(
          'Bado nasoma',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _primary,
          ),
        ),
        subtitle: const Text(
          'Still studying',
          style: TextStyle(fontSize: 12, color: _secondary),
        ),
        value: _isCurrentStudent,
        activeThumbColor: _primary,
        activeTrackColor: _primary.withValues(alpha: 0.5),
        onChanged: (val) => setState(() {
          _isCurrentStudent = val;
          if (val) _graduationYear = null;
        }),
      ),
    );
  }

  Widget _buildGradYearSection() {
    final label =
        _isCurrentStudent ? 'Mwaka wa kuhitimu (unatarajiwa)' : 'Mwaka wa kuhitimu';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 10),
        YearChipSelector(
          defaultYear: widget.defaultGradYear,
          startYear: 1950,
          endYear: 2030,
          selectedYear: _graduationYear,
          onYearSelected: (y) => setState(() => _graduationYear = y),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNextButton(),
          if (widget.onSkip != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: widget.onSkip,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Sijaenda chuo kikuu',
                  style: TextStyle(
                    fontSize: 14,
                    color: _secondary,
                    decoration: TextDecoration.underline,
                    decorationColor: _secondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared sub-builders
  // ---------------------------------------------------------------------------

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

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required bool isLoading,
    required bool isSelected,
    ValueChanged<String>? onChanged,
    required VoidCallback onClear,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? _primary : _border,
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Icon(Icons.search_rounded, size: 20, color: _secondary),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: isSelected,
              style: const TextStyle(fontSize: 15, color: _primary),
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFFBBBBBB),
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 14,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (isSelected || controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.only(right: 14),
                child: Icon(Icons.close_rounded, size: 20, color: _secondary),
              ),
            ),
        ],
      ),
    );
  }

  /// Scrollable list for selecting from a pre-loaded set (colleges, departments).
  Widget _buildSelectionList<T>({
    required List<T> items,
    required T? selectedItem,
    required String Function(T) labelBuilder,
    required String Function(T) subtitleBuilder,
    required bool Function(T) isSelected,
    required void Function(T) onTap,
    required VoidCallback onClear,
  }) {
    if (selectedItem != null) {
      // Show selected chip with clear button
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _primary, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, size: 18, color: _primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                labelBuilder(selectedItem),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _primary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.close_rounded, size: 20, color: _secondary),
              ),
            ),
          ],
        ),
      );
    }

    // Show scrollable list
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
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
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
        itemBuilder: (context, index) {
          final item = items[index];
          final subtitle = subtitleBuilder(item);
          return InkWell(
            onTap: () => onTap(item),
            borderRadius: index == 0
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : index == items.length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(12))
                    : BorderRadius.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    labelBuilder(item),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _primary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: _secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdownList<T>({
    required List<T> items,
    required String Function(T) labelBuilder,
    required String Function(T) subtitleBuilder,
    required void Function(T) onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: _fieldBg,
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
        itemCount: items.length,
        separatorBuilder: (context, i) =>
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () => onTap(item),
            borderRadius: index == 0
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : index == items.length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(12))
                    : BorderRadius.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    labelBuilder(item),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _primary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleBuilder(item),
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

  Widget _buildNextButton() {
    final enabled = _canContinue;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.45,
        child: FilledButton(
          onPressed: enabled ? _handleNext : null,
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
