import 'package:flutter/material.dart';
import '../l10n/app_strings_scope.dart';
import '../models/education_models.dart';
import '../services/education_service.dart';

/// Design: DOCS/DESIGN.md — layout, touch targets 48dp min, colors.
/// API: GET /api/universities-detailed/* (colleges, departments, programmes).
/// Used by RegistrationScreen Step 7 (UniversityStep).
class UniversityProgrammePicker extends StatefulWidget {
  final void Function(UniversityDetailed?, UniversityProgramme?, int? graduationYear, int? startYear)
      onComplete;
  final VoidCallback onSkip;

  const UniversityProgrammePicker({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<UniversityProgrammePicker> createState() =>
      _UniversityProgrammePickerState();
}

class _UniversityProgrammePickerState extends State<UniversityProgrammePicker> {
  final UniversityDetailedService _service = UniversityDetailedService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _programmeSearchController =
      TextEditingController();

  List<UniversityDetailed> _universities = [];
  List<UniversityCollege> _colleges = [];
  List<UniversityDepartment> _departments = [];
  List<UniversityProgramme> _programmes = [];
  List<UniversityProgramme> _searchResults = [];

  UniversityDetailed? _selectedUniversity;
  UniversityCollege? _selectedCollege;
  UniversityDepartment? _selectedDepartment;
  UniversityProgramme? _selectedProgramme;
  int? _startYear;
  int? _graduationYear;

  bool _isLoading = true;
  bool _isLoadingColleges = false;
  bool _isLoadingDepartments = false;
  bool _isLoadingProgrammes = false;
  bool _isSearching = false;
  bool _useSearch = false;
  String? _error;

  static const Color _bgPrimary = Color(0xFFFAFAFA);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF666666);
  static const Color _accent = Color(0xFF999999);
  static const double _minTouchTarget = 48.0;

  final List<int> _years =
      List.generate(40, (i) => DateTime.now().year - i);

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _programmeSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadUniversities() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });
    try {
      final universities = await _service.getAll();
      if (!mounted) return;
      setState(() {
        _universities = universities;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'universities';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadColleges(int universityId) async {
    setState(() {
      _isLoadingColleges = true;
      _colleges = [];
      _departments = [];
      _programmes = [];
      _selectedCollege = null;
      _selectedDepartment = null;
      _selectedProgramme = null;
    });
    try {
      final colleges = await _service.getColleges(universityId);
      if (!mounted) return;
      setState(() {
        _colleges = colleges;
        _isLoadingColleges = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingColleges = false);
    }
  }

  Future<void> _loadDepartments(int collegeId) async {
    setState(() {
      _isLoadingDepartments = true;
      _departments = [];
      _programmes = [];
      _selectedDepartment = null;
      _selectedProgramme = null;
    });
    try {
      final departments = await _service.getDepartments(collegeId);
      if (!mounted) return;
      setState(() {
        _departments = departments;
        _isLoadingDepartments = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingDepartments = false);
    }
  }

  Future<void> _loadProgrammes(int departmentId) async {
    setState(() {
      _isLoadingProgrammes = true;
      _programmes = [];
      _selectedProgramme = null;
    });
    try {
      final programmes =
          await _service.getProgrammesByDepartment(departmentId);
      if (!mounted) return;
      setState(() {
        _programmes = programmes;
        _isLoadingProgrammes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingProgrammes = false);
    }
  }

  Future<void> _searchProgrammes(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await _service.searchProgrammes(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  void _searchUniversities(String query) {
    if (query.length < 2) {
      _loadUniversities();
      return;
    }
    setState(() => _isLoading = true);
    _service.search(query).then((results) {
      if (!mounted) return;
      setState(() {
        _universities = results;
        _isLoading = false;
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    });
  }

  void _handleContinue() {
    widget.onComplete(_selectedUniversity, _selectedProgramme, _graduationYear, _startYear);
  }

  void _selectProgrammeFromSearch(UniversityProgramme programme) {
    setState(() {
      _selectedProgramme = programme;
      _programmeSearchController.text = programme.name;
      _searchResults = [];
    });
  }

  bool get _canContinue =>
      _selectedUniversity != null || _selectedProgramme != null;

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(
            s?.pickerUniversity ?? 'University',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                  fontSize: 15,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            s?.pickerSelectUniversityHeader ??
                'Select the university and programme you studied',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _textSecondary,
                  fontSize: 12,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          _buildModeToggle(),
          const SizedBox(height: 24),
          if (_error != null)
            _buildError()
          else if (_useSearch)
            _buildProgrammeSearch()
          else
            _buildHierarchySelection(),
          const SizedBox(height: 32),
          _buildActionButtons(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    final s = AppStringsScope.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SemanticButton(
              minHeight: _minTouchTarget,
              onTap: () => setState(() => _useSearch = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_useSearch ? _textPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  s?.pickerBrowse ?? 'Browse',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight:
                        !_useSearch ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                    color: !_useSearch ? Colors.white : _textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SemanticButton(
              minHeight: _minTouchTarget,
              onTap: () => setState(() => _useSearch = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _useSearch ? _textPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  s?.pickerSearchProgrammeToggle ?? 'Search programmes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight:
                        _useSearch ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                    color: _useSearch ? Colors.white : _textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    final s = AppStringsScope.of(context);
    final message = _error == 'universities'
        ? (s?.pickerErrLoadUniversities ?? 'Could not load universities')
        : (_error ?? '');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            message,
            style: const TextStyle(color: _textPrimary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              child: InkWell(
                onTap: _loadUniversities,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Text(
                    s?.pickerTryAgain ?? 'Try again',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgrammeSearch() {
    final s = AppStringsScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _programmeSearchController,
          decoration: InputDecoration(
            hintText: s?.pickerSearchProgrammeHint ??
                'Search programme (e.g. Economics, Medicine)…',
            hintStyle: const TextStyle(color: _textSecondary, fontSize: 12),
            prefixIcon: const Icon(Icons.search, color: _textPrimary),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _programmeSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _programmeSearchController.clear();
                          setState(() {
                            _searchResults = [];
                            _selectedProgramme = null;
                          });
                        },
                      )
                    : null,
          ),
          onChanged: _searchProgrammes,
        ),
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _accent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              separatorBuilder: (BuildContext context, int index) =>
                const Divider(height: 1),
              itemBuilder: (context, index) {
                final prog = _searchResults[index];
                return ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: _minTouchTarget),
                  child: ListTile(
                    minVerticalPadding: 12,
                    minLeadingWidth: 0,
                    title: Text(
                    prog.name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${prog.university ?? ''} • ${prog.levelLabel}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${prog.duration} yr',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => _selectProgrammeFromSearch(prog),
                ),
                );
              },
            ),
          ),
        ],
        if (_selectedProgramme != null) ...[
          const SizedBox(height: 24),
          _buildSelectedSummary(),
          const SizedBox(height: 24),
          _buildYearSelection(),
        ],
      ],
    );
  }

  Widget _buildHierarchySelection() {
    final s = AppStringsScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: s?.pickerSearchUniversityHint ?? 'Search university…',
            hintStyle: const TextStyle(color: _textSecondary, fontSize: 12),
            prefixIcon: const Icon(Icons.search, color: _textPrimary),
          ),
          onChanged: _searchUniversities,
        ),
        const SizedBox(height: 16),
        _buildDropdown<UniversityDetailed>(
          label: s?.pickerUniversity ?? 'University',
          hint: s?.pickerSelectUniversity ?? 'Select university',
          value: _selectedUniversity,
          items: _universities,
          isLoading: _isLoading,
          itemLabel: (u) => u.displayName,
          itemSubtitle: (u) => u.typeLabel,
          onChanged: (uni) {
            setState(() {
              _selectedUniversity = uni;
              _selectedCollege = null;
              _selectedDepartment = null;
              _selectedProgramme = null;
            });
            if (uni != null) {
              _loadColleges(uni.id);
            }
          },
        ),
        if (_selectedUniversity != null) ...[
          const SizedBox(height: 16),
          _buildDropdown<UniversityCollege>(
            label: s?.pickerCollegeOrSchool ?? 'School/College',
            hint: s?.pickerSelectCollege ?? 'Select school or college',
            value: _selectedCollege,
            items: _colleges,
            isLoading: _isLoadingColleges,
            itemLabel: (c) => c.name,
            itemSubtitle: (c) => c.typeLabel,
            onChanged: (college) {
              setState(() {
                _selectedCollege = college;
                _selectedDepartment = null;
                _selectedProgramme = null;
              });
              if (college != null) {
                _loadDepartments(college.id);
              }
            },
          ),
        ],
        if (_selectedCollege != null) ...[
          const SizedBox(height: 16),
          _buildDropdown<UniversityDepartment>(
            label: s?.pickerDepartment ?? 'Department',
            hint: s?.pickerSelectDepartment ?? 'Select department',
            value: _selectedDepartment,
            items: _departments,
            isLoading: _isLoadingDepartments,
            itemLabel: (d) => d.name,
            onChanged: (dept) {
              setState(() {
                _selectedDepartment = dept;
                _selectedProgramme = null;
              });
              if (dept != null) {
                _loadProgrammes(dept.id);
              }
            },
          ),
        ],
        if (_selectedDepartment != null) ...[
          const SizedBox(height: 16),
          _buildDropdown<UniversityProgramme>(
            label: s?.pickerProgramme ?? 'Programme',
            hint: s?.pickerSelectProgramme ?? 'Select programme',
            value: _selectedProgramme,
            items: _programmes,
            isLoading: _isLoadingProgrammes,
            itemLabel: (p) => p.name,
            itemSubtitle: (p) => '${p.levelLabel} • ${p.duration} ${s?.isSwahili ?? false ? 'miaka' : 'years'}',
            onChanged: (prog) {
              setState(() => _selectedProgramme = prog);
            },
          ),
        ],
        if (_selectedProgramme != null || _selectedUniversity != null) ...[
          const SizedBox(height: 24),
          _buildSelectedSummary(),
          const SizedBox(height: 24),
          _buildYearSelection(),
        ],
      ],
    );
  }

  Widget _buildSelectedSummary() {
    final s = AppStringsScope.of(context);
    final prog = _selectedProgramme;
    final uni = _selectedUniversity;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: _textPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                s?.pickerSelectionSummary ?? 'Your selection',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (prog != null) ...[
            Text(
              prog.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              prog.levelLabel,
              style: const TextStyle(color: _textSecondary, fontSize: 12),
            ),
            Text(
              s?.pickerDurationYears(prog.duration) ??
                  'Duration: ${prog.duration} years',
              style: const TextStyle(color: _textSecondary, fontSize: 11),
            ),
          ],
          if (uni != null)
            Text(
              uni.displayName,
              style: const TextStyle(color: _textSecondary, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildYearSelection() {
    final s = AppStringsScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s?.pickerStartYear ?? 'Start year',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _startYear,
          decoration: InputDecoration(
            hintText: s?.pickerSelectYearHint ?? 'Select year',
            hintStyle: const TextStyle(color: _textSecondary),
          ),
          items: _years
              .map((year) => DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() => _startYear = value);
          },
        ),
        const SizedBox(height: 16),
        Text(
          s?.pickerGraduationYear ?? 'Graduation year',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _graduationYear,
          decoration: InputDecoration(
            hintText: s?.pickerSelectYearHint ?? 'Select year',
            hintStyle: const TextStyle(color: _textSecondary),
          ),
          items: _years
              .map((year) => DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() => _graduationYear = value);
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
    String Function(T)? itemSubtitle,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _accent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent),
            ),
            child: Text(
              AppStringsScope.of(context)?.pickerNoData ?? 'No data',
              style: const TextStyle(color: _textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _accent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = value == item;
                return ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: _minTouchTarget),
                  child: ListTile(
                    minVerticalPadding: 12,
                    minLeadingWidth: 0,
                    dense: true,
                    selected: isSelected,
                  selectedTileColor:
                      _textPrimary.withValues(alpha: 0.08),
                  title: Text(
                    itemLabel(item),
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                      color: _textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: itemSubtitle != null
                      ? Text(
                          itemSubtitle(item),
                          style: const TextStyle(
                            fontSize: 11,
                            color: _textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: _textPrimary, size: 20)
                      : null,
                  onTap: () => onChanged(item),
                ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final s = AppStringsScope.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildButton(
            label: s?.pickerSkip ?? 'Skip',
            onTap: widget.onSkip,
            outlined: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _buildButton(
            label: s?.pickerContinue ?? 'Continue',
            onTap: _canContinue ? _handleContinue : null,
            outlined: false,
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback? onTap,
    required bool outlined,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: onTap != null ? _textPrimary : _textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wrapper to ensure minimum 48dp touch target (DOCS/DESIGN.md).
class SemanticButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final double minHeight;

  const SemanticButton({
    super.key,
    required this.onTap,
    required this.child,
    this.minHeight = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: child,
        ),
      ),
    );
  }
}
