import 'package:flutter/material.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/education_models.dart';
import '../../../services/education_service.dart';

class PostsecondaryStep extends StatefulWidget {
  final void Function(PostsecondaryInstitution? institution, int? graduationYear, int? startYear) onComplete;
  final VoidCallback onSkip;

  const PostsecondaryStep({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<PostsecondaryStep> createState() => _PostsecondaryStepState();
}

class _PostsecondaryStepState extends State<PostsecondaryStep> {
  final _service = PostsecondaryService();
  final _searchController = TextEditingController();

  Map<String, String> _categories = {};
  String? _selectedCategory;
  List<PostsecondaryInstitution> _institutions = [];
  PostsecondaryInstitution? _selectedInstitution;
  int? _startYear;
  int? _graduationYear;

  bool _isLoading = true;
  bool _isLoadingInstitutions = false;
  bool _isSearching = false;
  String? _error;

  final List<int> _years = List.generate(
    40,
    (i) => DateTime.now().year - i,
  );

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _service.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'institutionTypes';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInstitutions(String category) async {
    setState(() {
      _isLoadingInstitutions = true;
      _selectedInstitution = null;
    });

    try {
      final institutions = await _service.getByCategory(category);
      setState(() {
        _institutions = institutions;
        _isLoadingInstitutions = false;
      });
    } catch (e) {
      setState(() {
        _error = 'institutions';
        _isLoadingInstitutions = false;
      });
    }
  }

  Future<void> _searchInstitutions(String query) async {
    if (query.length < 2) {
      setState(() {
        _institutions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final institutions = await _service.search(query);
      setState(() {
        _institutions = institutions;
        _isSearching = false;
        _selectedCategory = null;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _handleContinue() {
    widget.onComplete(_selectedInstitution, _graduationYear, _startYear);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final String? errorMessage;
    if (_error == 'institutionTypes') {
      errorMessage = s?.pickerErrLoadInstitutionTypes ??
          'Could not load institution types';
    } else if (_error == 'institutions') {
      errorMessage = s?.pickerErrLoadInstitutions ??
          'Could not load institutions';
    } else {
      errorMessage = _error;
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),

          // Header
          Text(
            s?.pickerPostsecondaryHeader ?? 'Vocational / College education',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            s?.pickerPostsecondarySubheader ??
                'Select the college or institution you attended after secondary',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(
              child: Column(
                children: [
                  Text(errorMessage ?? '',
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadCategories,
                    child: Text(s?.pickerTryAgain ?? 'Try again'),
                  ),
                ],
              ),
            )
          else ...[
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: s?.pickerSearchInstitutionHint ??
                    'Search institution…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _institutions = [];
                              });
                            },
                          )
                        : null,
              ),
              onChanged: _searchInstitutions,
            ),
            const SizedBox(height: 24),

            // Category chips
            Text(
              s?.pickerOrSelectType ?? 'Or pick a type:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.entries.map((entry) {
                final isSelected = _selectedCategory == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = entry.key;
                        _searchController.clear();
                      });
                      _loadInstitutions(entry.key);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Institutions list
            if (_isLoadingInstitutions)
              const Center(child: CircularProgressIndicator())
            else if (_institutions.isNotEmpty) ...[
              Text(
                s?.pickerInstitutionsCount(_institutions.length) ??
                    'Institutions (${_institutions.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _institutions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final inst = _institutions[index];
                    final isSelected = _selectedInstitution?.id == inst.id;
                    return ListTile(
                      title: Text(
                        inst.displayName,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(inst.categoryLabel),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      selected: isSelected,
                      onTap: () {
                        setState(() => _selectedInstitution = inst);
                      },
                    );
                  },
                ),
              ),
            ],

            // Start year and graduation year
            if (_selectedInstitution != null) ...[
              const SizedBox(height: 24),
              Text(
                s?.pickerStartYear ?? 'Start year',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _startYear,
                decoration: InputDecoration(
                  hintText: s?.pickerSelectYearHint ?? 'Select year',
                ),
                items: _years.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _startYear = value);
                },
              ),
              const SizedBox(height: 16),
              Text(
                s?.pickerGraduationYear ?? 'Graduation year',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _graduationYear,
                decoration: InputDecoration(
                  hintText: s?.pickerSelectYearHint ?? 'Select year',
                ),
                items: _years.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _graduationYear = value);
                },
              ),
            ],
          ],

          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onSkip,
                  child: Text(s?.pickerSkip ?? 'Skip'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _selectedInstitution != null ? _handleContinue : null,
                  child: Text(s?.pickerContinue ?? 'Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
