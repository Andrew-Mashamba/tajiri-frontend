import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../models/people_search_models.dart';
import '../../services/friend_service.dart';
import '../../services/message_service.dart';
import '../../services/people_search_service.dart';
import '../../widgets/user_avatar.dart';
import '../../l10n/app_strings_scope.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kOnline = Color(0xFF22C55E);
const Duration _debounceDuration = Duration(milliseconds: 400);

/// Keys that are sent as separate filter params, not as sort.
const _relevanceFilterKeys = {'verified', 'possible_business_connection', 'possible_employer'};

/// All relevance options: sort orders + Verified, Possible Business Connection, Possible Employer.
const _relevanceOptions = [
  ('relevance', 'Relevance'),
  ('newest', 'Newest'),
  ('last_seen', 'Recently Active'),
  ('most_active', 'Most Active'),
  ('friends_count', 'Most Friends'),
  ('least_connected', 'Least Connected'),
  ('most_mutual_friends', 'Most Mutual Friends'),
  ('similar_to_me', 'Similar to me'),
  ('single_first', 'Single first'),
  ('same_area_first', 'Same area first'),
  ('most_shared_interests', 'Most shared interests'),
  ('least_male_friends', 'Less male friends'),
  ('least_female_friends', 'Less female friends'),
  ('verified', 'Verified'),
  ('possible_business_connection', 'Possible Business Connection'),
  ('possible_employer', 'Possible Employer'),
];

/// People → People tab: GET /api/people/search with gender, sort, filters, and friendship actions.
class PeopleSearchTab extends StatefulWidget {
  final int userId;
  final FriendService friendService;
  final MessageService messageService;
  final bool isCurrentTab;

  const PeopleSearchTab({
    super.key,
    required this.userId,
    required this.friendService,
    required this.messageService,
    this.isCurrentTab = false,
  });

  @override
  State<PeopleSearchTab> createState() => _PeopleSearchTabState();
}

class _PeopleSearchTabState extends State<PeopleSearchTab> {
  final PeopleSearchService _searchService = PeopleSearchService();
  final TextEditingController _queryController = TextEditingController();
  Timer? _debounce;

  List<PersonSearchResult> _results = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;

  bool _initialSearchDone = false;

  String? _gender; // null = All
  List<String> _selectedRelevances = []; // Relevance: None by default
  bool _onlineOnly = false;
  bool _hasPhotoOnly = false;
  int? _ageMin;
  int? _ageMax;
  String _locationFilter = '';
  String _schoolFilter = '';
  String _employerFilter = '';
  String _sectorFilter = '';
  bool _student = false;
  String? _relationshipStatus; // null = any, single, married, etc.
  bool _hasInterests = false;
  bool _profileComplete = false;
  bool _friendsOfFriendsOnly = false;

  bool get _hasActiveFilters =>
      _onlineOnly ||
      _hasPhotoOnly ||
      _ageMin != null ||
      _ageMax != null ||
      _locationFilter.isNotEmpty ||
      _schoolFilter.isNotEmpty ||
      _employerFilter.isNotEmpty ||
      _sectorFilter.isNotEmpty ||
      _student ||
      _relationshipStatus != null ||
      _hasInterests ||
      _profileComplete ||
      _friendsOfFriendsOnly;

  int get _activeFilterCount {
    int n = 0;
    if (_onlineOnly) n++;
    if (_hasPhotoOnly) n++;
    if (_ageMin != null || _ageMax != null) n++;
    if (_locationFilter.isNotEmpty) n++;
    if (_schoolFilter.isNotEmpty) n++;
    if (_employerFilter.isNotEmpty) n++;
    if (_sectorFilter.isNotEmpty) n++;
    if (_student) n++;
    if (_relationshipStatus != null) n++;
    if (_hasInterests) n++;
    if (_profileComplete) n++;
    if (_friendsOfFriendsOnly) n++;
    return n;
  }

  bool get _canSearch {
    final q = _queryController.text.trim();
    if (q.length >= 2) return true;
    if (_hasActiveFilters) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_onQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Only run discovery when this tab is actually visible (avoids running while user is on Feed).
      if (widget.isCurrentTab && !_initialSearchDone) {
        _initialSearchDone = true;
        _page = 1;
        _performSearch(forceInitial: true);
      }
    });
  }

  @override
  void didUpdateWidget(PeopleSearchTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Run discovery when user navigates to People (tab becomes visible).
    if (widget.isCurrentTab && !oldWidget.isCurrentTab && !_initialSearchDone) {
      _initialSearchDone = true;
      _page = 1;
      _performSearch(forceInitial: true);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      if (_canSearch) {
        _page = 1;
        _performSearch();
      } else {
        setState(() {
          _results = [];
          _error = null;
          _lastPage = 1;
          _total = 0;
        });
      }
    });
  }

  Future<void> _performSearch({bool forceInitial = false}) async {
    if (!forceInitial && !_canSearch) return;
    if (_page == 1) setState(() => _loading = true);
    if (_page > 1) setState(() => _loadingMore = true);
    _error = null;

    final sortOnly = _selectedRelevances
        .where((s) => !_relevanceFilterKeys.contains(s))
        .toList();
    final sortValues = sortOnly.isEmpty ? ['relevance'] : sortOnly;
    final result = await _searchService.search(
      userId: widget.userId,
      query: _queryController.text.trim().isEmpty ? null : _queryController.text.trim(),
      page: _page,
      perPage: 20,
      sort: sortValues.first,
      gender: _gender,
      online: _onlineOnly ? true : null,
      location: _locationFilter.isEmpty ? null : _locationFilter,
      employer: _employerFilter.isEmpty ? null : _employerFilter,
      school: _schoolFilter.isEmpty ? null : _schoolFilter,
      hasPhoto: _hasPhotoOnly ? true : null,
      ageMin: _ageMin,
      ageMax: _ageMax,
      student: _student ? true : null,
      relationshipStatus: _relationshipStatus,
      sector: _sectorFilter.isEmpty ? null : _sectorFilter,
      hasInterests: _hasInterests ? true : null,
      profileComplete: _profileComplete ? true : null,
      friendsOfFriendsOnly: _friendsOfFriendsOnly ? true : null,
      verified: _selectedRelevances.contains('verified') ? true : null,
      possibleBusinessConnection: _selectedRelevances.contains('possible_business_connection') ? true : null,
      possibleEmployer: _selectedRelevances.contains('possible_employer') ? true : null,
      sortValues: sortValues,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadingMore = false;
      if (result.success && result.response != null) {
        final r = result.response!;
        if (_page == 1) {
          _results = r.people;
        } else {
          _results = [..._results, ...r.people];
        }
        _lastPage = r.lastPage;
        _total = r.total;
        _error = null;
      } else {
        _error = result.message ?? 'Something went wrong. Tap to retry.';
        if (_page == 1) _results = [];
      }
    });
  }

  void _applyFiltersFromSheet({
    bool? onlineOnly,
    bool? hasPhotoOnly,
    int? ageMin,
    int? ageMax,
    String? location,
    String? school,
    String? employer,
    String? sector,
    bool? student,
    String? relationshipStatus,
    bool? hasInterests,
    bool? profileComplete,
    bool? friendsOfFriendsOnly,
  }) {
    setState(() {
      if (onlineOnly != null) _onlineOnly = onlineOnly;
      if (hasPhotoOnly != null) _hasPhotoOnly = hasPhotoOnly;
      if (ageMin != null) _ageMin = ageMin;
      if (ageMax != null) _ageMax = ageMax;
      if (location != null) _locationFilter = location;
      if (school != null) _schoolFilter = school;
      if (employer != null) _employerFilter = employer;
      if (sector != null) _sectorFilter = sector;
      if (student != null) _student = student;
      _relationshipStatus = relationshipStatus; // sheet always passes this (null = Any)
      if (hasInterests != null) _hasInterests = hasInterests;
      if (profileComplete != null) _profileComplete = profileComplete;
      if (friendsOfFriendsOnly != null) _friendsOfFriendsOnly = friendsOfFriendsOnly;
      _page = 1;
    });
    if (_canSearch) _performSearch();
  }

  void _updatePersonInList(int id, PersonSearchResult updated) {
    setState(() {
      final i = _results.indexWhere((p) => p.id == id);
      if (i >= 0) _results[i] = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchBar(),
        _buildFilterRow(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildSearchBar() {
    final s = AppStringsScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _queryController,
        decoration: InputDecoration(
          hintText: s?.search ?? 'Search people...',
          prefixIcon: const Icon(Icons.search, color: _kSecondary, size: 22),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        style: const TextStyle(color: _kPrimary, fontSize: 15),
        onSubmitted: (_) {
          if (_canSearch) {
            _page = 1;
            _performSearch();
          }
        },
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _GenderDropdown(
            value: _gender,
            onChanged: (v) => setState(() {
              _gender = v;
              if (_canSearch) { _page = 1; _performSearch(); }
            }),
          ),
          const SizedBox(width: 8),
          _RelevanceMultiSelect(
            selected: _selectedRelevances,
            onChanged: (list) => setState(() {
              _selectedRelevances = list;
              if (_canSearch) { _page = 1; _performSearch(); }
            }),
          ),
          const SizedBox(width: 4),
          _AgeRangePicker(
            ageMin: _ageMin,
            ageMax: _ageMax,
            onChanged: (min, max) => setState(() {
              _ageMin = min;
              _ageMax = max;
              if (_canSearch) { _page = 1; _performSearch(); }
            }),
          ),
          IconButton(
            onPressed: () => _showFiltersSheet(context),
            icon: Badge(
              isLabelVisible: _activeFilterCount > 0,
              label: Text('$_activeFilterCount'),
              child: const Icon(Icons.more_vert, color: _kPrimary),
            ),
            tooltip: 'More filters',
          ),
        ],
      ),
    );
  }

  void _showFiltersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _FiltersSheet(
        onlineOnly: _onlineOnly,
        hasPhotoOnly: _hasPhotoOnly,
        ageMin: _ageMin,
        ageMax: _ageMax,
        location: _locationFilter,
        school: _schoolFilter,
        employer: _employerFilter,
        sector: _sectorFilter,
        student: _student,
        relationshipStatus: _relationshipStatus,
        hasInterests: _hasInterests,
        profileComplete: _profileComplete,
        friendsOfFriendsOnly: _friendsOfFriendsOnly,
        onApply: (o, h, aMin, aMax, loc, sch, emp, sec, stu, rel, hasInt, profComplete, fof) {
          Navigator.pop(ctx);
          _applyFiltersFromSheet(
            onlineOnly: o,
            hasPhotoOnly: h,
            ageMin: aMin,
            ageMax: aMax,
            location: loc,
            school: sch,
            employer: emp,
            sector: sec,
            student: stu,
            relationshipStatus: rel,
            hasInterests: hasInt,
            profileComplete: profComplete,
            friendsOfFriendsOnly: fof,
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    // 1. Loading and no results yet → skeletons
    if (_loading && _results.isEmpty) return _buildSkeletons();
    // 2. Error and no results → error view
    if (_error != null && _results.isEmpty) return _buildError();
    // 3. Have results (discovery or search) → show list (do this before _canSearch so discovery results display)
    if (_results.isNotEmpty) return _buildList();
    // 4. No results and user can't search yet (no query, no filters) → empty prompt
    if (!_canSearch) return _buildEmptyPrompt();
    // 5. Search ran but returned no results
    return _buildNoResults();
  }

  Widget _buildEmptyPrompt() {
    final q = _queryController.text.trim();
    final showShortHint = q.isNotEmpty && q.length < 2 && !_hasActiveFilters;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showShortHint ? Icons.info_outline : Icons.person_search,
              size: 64,
              color: _kSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              showShortHint
                  ? 'Type at least 2 characters to search'
                  : 'Search for people by name, school, location, or employer',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kSecondary, fontSize: 15),
            ),
            if (!showShortHint && !_hasActiveFilters)
              const SizedBox(height: 8),
            if (!showShortHint && !_hasActiveFilters)
              Text(
                'Or use filters above to discover people',
                style: TextStyle(color: _kSecondary.withValues(alpha: 0.8), fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletons() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 8,
      itemBuilder: (_, __) => const _PersonCardSkeleton(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: _kSecondary),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _performSearch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: _kSecondary),
            const SizedBox(height: 16),
            Text(
              _hasActiveFilters
                  ? 'No matches for these filters. Try broadening your search.'
                  : 'No people found. Try different keywords or filters.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kSecondary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  void _loadMore() {
    if (_loadingMore || _page >= _lastPage) return;
    _page++;
    _performSearch();
  }

  /// Pull-to-refresh keeps current query and all filters; only resets page to 1 and refetches.
  Future<void> _onRefresh() async {
    _page = 1;
    await _performSearch();
  }

  Widget _buildResultsHeader() {
    final total = _total;
    final shown = _results.length;
    final hasMore = _page < _lastPage;
    String subtitle;
    if (total == 0) {
      subtitle = 'No results';
    } else if (hasMore) {
      subtitle = 'Showing $shown of $total';
    } else {
      subtitle = total == 1 ? '1 person' : '$total people';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          Text(
            subtitle,
            style: const TextStyle(
              color: _kSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (_hasActiveFilters)
            Text(
              'Filters on',
              style: TextStyle(
                color: _kPrimary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final hasMore = _page < _lastPage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildResultsHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: _kPrimary,
            strokeWidth: 2.5,
            child: ListView.builder(
              physics: AlwaysScrollableScrollPhysics(
                parent: Theme.of(context).platform == TargetPlatform.iOS
                    ? BouncingScrollPhysics()
                    : ClampingScrollPhysics(),
              ),
              cacheExtent: 600,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _results.length + (hasMore || _loadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _results.length) {
                  if (_loadingMore) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2.5),
                        ),
                      ),
                    );
                  }
                  if (hasMore) _loadMore();
                  return const SizedBox.shrink();
                }
                final person = _results[index];
                return RepaintBoundary(
                  key: ValueKey(person.id),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PersonCard(
                      person: person,
                      currentUserId: widget.userId,
                      friendService: widget.friendService,
                      messageService: widget.messageService,
                      onStatusChanged: (updated) => _updatePersonInList(person.id, updated),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// --- Dropdowns ---

class _RelevanceMultiSelect extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _RelevanceMultiSelect({required this.selected, required this.onChanged});

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _RelevanceSheet(
        selected: List.from(selected),
        options: _relevanceOptions,
        onApply: (list) {
          Navigator.pop(ctx);
          onChanged(list.isEmpty ? ['relevance'] : list);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = selected.length == 1 && selected.first == 'relevance'
        ? 'Relevance'
        : 'Relevance (${selected.length})';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _openSheet(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(color: _kPrimary, fontSize: 14)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: _kSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _RelevanceSheet extends StatefulWidget {
  final List<String> selected;
  final List<(String, String)> options;
  final void Function(List<String>) onApply;

  const _RelevanceSheet({
    required this.selected,
    required this.options,
    required this.onApply,
  });

  @override
  State<_RelevanceSheet> createState() => _RelevanceSheetState();
}

class _RelevanceSheetState extends State<_RelevanceSheet> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selected);
  }

  void _toggle(String value) {
    if (_selected.contains(value)) {
      final sortOnly = _selected.where((s) => !_relevanceFilterKeys.contains(s)).toList();
      if (sortOnly.length == 1 && sortOnly.first == value) return; // keep at least one sort
      setState(() => _selected.remove(value));
    } else {
      setState(() => _selected.add(value));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Relevance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Choose one or more. Backend uses first as primary sort; others as tie-breakers or filters.',
                  style: TextStyle(fontSize: 12, color: _kSecondary)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: widget.options.map((o) {
                  final value = o.$1;
                  final label = o.$2;
                  final isChecked = _selected.contains(value);
                  return CheckboxListTile(
                    value: isChecked,
                    onChanged: (v) => _toggle(value),
                    title: Text(label),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => widget.onApply(_selected),
                  style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
                  child: const Text('Apply'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgeRangePicker extends StatelessWidget {
  final int? ageMin;
  final int? ageMax;
  final void Function(int? min, int? max) onChanged;

  const _AgeRangePicker({
    required this.ageMin,
    required this.ageMax,
    required this.onChanged,
  });

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AgeRangeSheet(
        ageMin: ageMin,
        ageMax: ageMax,
        onApply: (min, max) {
          Navigator.pop(ctx);
          onChanged(min, max);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = (ageMin == null && ageMax == null)
        ? 'Age'
        : (ageMin != null && ageMax != null)
            ? '$ageMin–$ageMax'
            : ageMin != null
                ? '$ageMin+'
                : '–$ageMax';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _openSheet(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(color: _kPrimary, fontSize: 14)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: _kSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgeRangeSheet extends StatefulWidget {
  final int? ageMin;
  final int? ageMax;
  final void Function(int? min, int? max) onApply;

  const _AgeRangeSheet({
    required this.ageMin,
    required this.ageMax,
    required this.onApply,
  });

  @override
  State<_AgeRangeSheet> createState() => _AgeRangeSheetState();
}

class _AgeRangeSheetState extends State<_AgeRangeSheet> {
  static const int _minAge = 18;
  static const int _maxAge = 99;

  int? _min;
  int? _max;
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _min = widget.ageMin;
    _max = widget.ageMax;
    _minController.text = _min?.toString() ?? '';
    _maxController.text = _max?.toString() ?? '';
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _applyFromFields() {
    final minStr = _minController.text.trim();
    final maxStr = _maxController.text.trim();
    final min = minStr.isEmpty ? null : int.tryParse(minStr);
    final max = maxStr.isEmpty ? null : int.tryParse(maxStr);
    if (min != null && (min < _minAge || min > _maxAge)) return;
    if (max != null && (max < _minAge || max > _maxAge)) return;
    if (min != null && max != null && min > max) return;
    widget.onApply(min, max);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Age range', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min',
                      hintText: '18',
                      border: OutlineInputBorder(),
                      suffixText: 'years',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max',
                      hintText: '99',
                      border: OutlineInputBorder(),
                      suffixText: 'years',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                TextButton(
                  onPressed: () {
                    _minController.clear();
                    _maxController.clear();
                    setState(() { _min = null; _max = null; });
                  },
                  child: const Text('Any age'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFromFields,
                    style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _GenderDropdown extends StatelessWidget {
  final String? value; // null = All, "male" = Men, "female" = Women
  final ValueChanged<String?> onChanged;

  const _GenderDropdown({required this.value, required this.onChanged});

  static const _options = [
    (null, 'All'),
    ('male', 'Men'),
    ('female', 'Women'),
  ];

  @override
  Widget build(BuildContext context) {
    final label = _options.firstWhere(
      (e) => e.$1 == value,
      orElse: () => _options.first,
    ).$2;
    return PopupMenuButton<String?>(
      onSelected: onChanged,
      itemBuilder: (_) => _options
          .map((o) => PopupMenuItem<String?>(
                value: o.$1,
                child: Text(o.$2),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(color: _kPrimary, fontSize: 14)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: _kSecondary),
          ],
        ),
      ),
    );
  }
}

// --- Filters bottom sheet ---

class _FiltersSheet extends StatefulWidget {
  final bool onlineOnly;
  final bool hasPhotoOnly;
  final int? ageMin;
  final int? ageMax;
  final String location;
  final String school;
  final String employer;
  final String sector;
  final bool student;
  final String? relationshipStatus;
  final bool hasInterests;
  final bool profileComplete;
  final bool friendsOfFriendsOnly;
  final void Function(bool, bool, int?, int?, String, String, String, String, bool, String?, bool, bool, bool) onApply;

  const _FiltersSheet({
    required this.onlineOnly,
    required this.hasPhotoOnly,
    required this.ageMin,
    required this.ageMax,
    required this.location,
    required this.school,
    required this.employer,
    required this.sector,
    required this.student,
    required this.relationshipStatus,
    required this.hasInterests,
    required this.profileComplete,
    required this.friendsOfFriendsOnly,
    required this.onApply,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late bool _onlineOnly;
  late bool _hasPhotoOnly;
  late bool _student;
  late bool _hasInterests;
  late bool _profileComplete;
  late bool _friendsOfFriendsOnly;
  late String? _relationshipStatus;
  late TextEditingController _location;
  late TextEditingController _school;
  late TextEditingController _employer;
  late TextEditingController _sector;

  @override
  void initState() {
    super.initState();
    _onlineOnly = widget.onlineOnly;
    _hasPhotoOnly = widget.hasPhotoOnly;
    _student = widget.student;
    _hasInterests = widget.hasInterests;
    _profileComplete = widget.profileComplete;
    _friendsOfFriendsOnly = widget.friendsOfFriendsOnly;
    _relationshipStatus = widget.relationshipStatus;
    _location = TextEditingController(text: widget.location);
    _school = TextEditingController(text: widget.school);
    _employer = TextEditingController(text: widget.employer);
    _sector = TextEditingController(text: widget.sector);
  }

  @override
  void dispose() {
    _location.dispose();
    _school.dispose();
    _employer.dispose();
    _sector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  SwitchListTile(
                    title: const Text('Online now'),
                    value: _onlineOnly,
                    onChanged: (v) => setState(() => _onlineOnly = v),
                  ),
                  SwitchListTile(
                    title: const Text('Has profile photo'),
                    value: _hasPhotoOnly,
                    onChanged: (v) => setState(() => _hasPhotoOnly = v),
                  ),
                  SwitchListTile(
                    title: const Text('Student'),
                    subtitle: const Text('Student (e.g. has education, no employer)'),
                    value: _student,
                    onChanged: (v) => setState(() => _student = v),
                  ),
                  SwitchListTile(
                    title: const Text('Has interests'),
                    subtitle: const Text('At least one interest set'),
                    value: _hasInterests,
                    onChanged: (v) => setState(() => _hasInterests = v),
                  ),
                  SwitchListTile(
                    title: const Text('Complete profile'),
                    subtitle: const Text('Has photo, bio, and key details'),
                    value: _profileComplete,
                    onChanged: (v) => setState(() => _profileComplete = v),
                  ),
                  SwitchListTile(
                    title: const Text('Friends of friends only'),
                    subtitle: const Text('Only 2nd-degree connections'),
                    value: _friendsOfFriendsOnly,
                    onChanged: (v) => setState(() => _friendsOfFriendsOnly = v),
                  ),
                  const SizedBox(height: 12),
                  const Text('Relationship status', style: TextStyle(fontWeight: FontWeight.w600)),
                  DropdownButtonFormField<String?>(
                    value: _relationshipStatus,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Any')),
                      DropdownMenuItem(value: 'single', child: Text('Single')),
                      DropdownMenuItem(value: 'in_relationship', child: Text('In a relationship')),
                      DropdownMenuItem(value: 'engaged', child: Text('Engaged')),
                      DropdownMenuItem(value: 'married', child: Text('Married')),
                      DropdownMenuItem(value: 'complicated', child: Text('Complicated')),
                      DropdownMenuItem(value: 'divorced', child: Text('Divorced')),
                      DropdownMenuItem(value: 'widowed', child: Text('Widowed')),
                    ],
                    onChanged: (v) => setState(() => _relationshipStatus = v),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _location,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'e.g. Dar-es-salaam',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _school,
                    decoration: const InputDecoration(
                      labelText: 'School',
                      hintText: 'Type school name...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _employer,
                    decoration: const InputDecoration(
                      labelText: 'Employer',
                      hintText: 'Type employer name...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _sector,
                    decoration: const InputDecoration(
                      labelText: 'Sector / industry',
                      hintText: 'e.g. Tech, Education, Health',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => widget.onApply(
                        _onlineOnly,
                        _hasPhotoOnly,
                        widget.ageMin,
                        widget.ageMax,
                        _location.text.trim(),
                        _school.text.trim(),
                        _employer.text.trim(),
                        _sector.text.trim(),
                        _student,
                        _relationshipStatus,
                        _hasInterests,
                        _profileComplete,
                        _friendsOfFriendsOnly,
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Skeleton (matches _PersonCard layout) ---

class _PersonCardSkeleton extends StatelessWidget {
  const _PersonCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_kCardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: _kAvatarRadius * 2,
              height: _kAvatarRadius * 2,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 17,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 13,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Person card with friendship actions ---

const double _kCardRadius = 16;
const double _kAvatarRadius = 28;
const double _kOnlineBadgeSize = 12;

class _PersonCard extends StatelessWidget {
  final PersonSearchResult person;
  final int currentUserId;
  final FriendService friendService;
  final MessageService messageService;
  final void Function(PersonSearchResult) onStatusChanged;

  const _PersonCard({
    required this.person,
    required this.currentUserId,
    required this.friendService,
    required this.messageService,
    required this.onStatusChanged,
  });

  IconData _iconForInCommon(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('district') || lower.contains('region')) return Icons.location_on_outlined;
    if (lower.contains('employer')) return Icons.work_outline;
    if (lower.contains('university') || lower.contains('school')) return Icons.school_outlined;
    if (lower.contains('interest')) return Icons.favorite_border;
    return Icons.tag;
  }

  @override
  Widget build(BuildContext context) {
    final isSelf = person.id == currentUserId;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/profile/${person.id}'),
        borderRadius: BorderRadius.circular(_kCardRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_kCardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  UserAvatar(
                    photoUrl: person.profilePhotoUrl,
                    name: person.fullName,
                    radius: _kAvatarRadius,
                  ),
                  if (person.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: _kOnlineBadgeSize,
                        height: _kOnlineBadgeSize,
                        decoration: BoxDecoration(
                          color: _kOnline,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: _kOnline.withValues(alpha: 0.5), blurRadius: 4)],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.fullName,
                      style: const TextStyle(
                        color: _kPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (person.username != null)
                          Flexible(
                            child: Text(
                              '@${person.username}',
                              style: const TextStyle(color: _kSecondary, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (person.username != null && person.genderAgeLine != null)
                          const Text(' · ', style: TextStyle(color: _kSecondary, fontSize: 13)),
                        if (person.genderAgeLine != null)
                          Text(
                            person.genderAgeLine!,
                            style: const TextStyle(color: _kSecondary, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    if (person.contextLine != null && person.contextLine!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.work_outline, size: 14, color: _kSecondary.withValues(alpha: 0.9)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              person.contextLine!,
                              style: TextStyle(
                                color: _kSecondary.withValues(alpha: 0.95),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (person.locationString != null && person.locationString!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: _kSecondary.withValues(alpha: 0.9)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              person.locationString!,
                              style: TextStyle(color: _kSecondary.withValues(alpha: 0.9), fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (person.inCommon.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: person.inCommon.take(4).map((text) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_iconForInCommon(text), size: 12, color: _kSecondary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    text,
                                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    if (person.mutualFriendsCount > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${person.mutualFriendsCount} mutual friend${person.mutualFriendsCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: _kSecondary.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (!isSelf) const SizedBox(width: 12),
              if (!isSelf)
                _FriendshipAction(
                  person: person,
                  currentUserId: currentUserId,
                  friendService: friendService,
                  messageService: messageService,
                  onStatusChanged: onStatusChanged,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendshipAction extends StatefulWidget {
  final PersonSearchResult person;
  final int currentUserId;
  final FriendService friendService;
  final MessageService messageService;
  final void Function(PersonSearchResult) onStatusChanged;

  const _FriendshipAction({
    required this.person,
    required this.currentUserId,
    required this.friendService,
    required this.messageService,
    required this.onStatusChanged,
  });

  @override
  State<_FriendshipAction> createState() => _FriendshipActionState();
}

class _FriendshipActionState extends State<_FriendshipAction> {
  String get _status => widget.person.friendshipStatus;

  Future<void> _sendRequest() async {
    final ok = await widget.friendService.sendFriendRequest(widget.currentUserId, widget.person.id);
    if (!mounted) return;
    if (ok) {
      widget.onStatusChanged(widget.person.copyWith(friendshipStatus: 'pending_sent'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStringsScope.of(context)?.friendRequestSent ?? 'Friend request sent')),
      );
    }
  }

  Future<void> _cancelRequest() async {
    final ok = await widget.friendService.cancelFriendRequest(widget.currentUserId, widget.person.id);
    if (!mounted) return;
    if (ok) {
      widget.onStatusChanged(widget.person.copyWith(friendshipStatus: 'none'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request cancelled')),
      );
    }
  }

  Future<void> _accept() async {
    final ok = await widget.friendService.acceptFriendRequest(widget.currentUserId, widget.person.id);
    if (!mounted) return;
    if (ok) {
      widget.onStatusChanged(widget.person.copyWith(friendshipStatus: 'friends'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStringsScope.of(context)?.nowFriends ?? 'Now friends!')),
      );
    }
  }

  Future<void> _decline() async {
    final ok = await widget.friendService.declineFriendRequest(widget.currentUserId, widget.person.id);
    if (!mounted) return;
    if (ok) {
      widget.onStatusChanged(widget.person.copyWith(friendshipStatus: 'none'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request declined')),
      );
    }
  }

  Future<void> _openChat() async {
    final result = await widget.messageService.getPrivateConversation(
      widget.currentUserId,
      widget.person.id,
    );
    if (!mounted) return;
    if (result.success && result.conversation != null) {
      Navigator.pushNamed(
        context,
        '/chat/${result.conversation!.id}',
        arguments: <String, dynamic>{'conversation': result.conversation},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Could not open chat')),
      );
    }
  }

  Widget _buildChatButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openChat,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kPrimary.withValues(alpha: 0.15)),
          ),
          child: HeroIcon(HeroIcons.chatBubbleLeftRight, style: HeroIconStyle.outline, size: 20, color: _kPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_status == 'none') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Material(
              color: _kPrimary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _sendRequest,
                customBorder: const CircleBorder(),
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildChatButton(),
        ],
      );
    }
    if (_status == 'friends') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 18, color: _kSecondary),
                SizedBox(width: 4),
                Text('Friends', style: TextStyle(color: _kSecondary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildChatButton(),
        ],
      );
    }
    if (_status == 'pending_sent') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: _cancelRequest,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kSecondary),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: const Text('Requested', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(width: 8),
          _buildChatButton(),
        ],
      );
    }
    if (_status == 'pending_received') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: _accept,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOnline,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: const Text('Accept', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: _decline,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kSecondary,
                side: const BorderSide(color: _kSecondary),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Decline', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(width: 8),
          _buildChatButton(),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
