import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../models/people_search_models.dart';
import '../../services/friend_service.dart';
import '../../services/message_service.dart';
import '../../services/people_search_service.dart';
import '../../services/people_cache_service.dart';
import '../../services/perf_logger.dart';
import '../../services/event_tracking_service.dart';
import '../../services/local_storage_service.dart';
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
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  List<PersonSearchResult> _results = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;

  bool _initialSearchDone = false;

  // Performance: prefetch next page
  List<PersonSearchResult>? _prefetchedNextPage;
  bool _isPrefetching = false;

  // Performance: in-memory page cache (Task 5.2)
  Map<int, List<PersonSearchResult>> _pageCache = {};

  // Performance: local filtering for search-as-you-type (Task 5.4)
  String _previousQuery = '';
  List<PersonSearchResult>? _lastFullResults;
  // Performance: stale-while-revalidate for discovery
  bool _showingCached = false;

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

  // Quick-chip filters (Task 4.2)
  final Set<String> _activeChips = {};

  // User profile data for quick-chips
  String? _userDistrict;
  int? _userAge;
  bool _userDataLoaded = false;

  // Scroll depth tracking (Task 4.6)
  
  int _lastTrackedDepth = 0;

  // Shuffle flag for pull-to-refresh (Task 4.5)
  bool _shuffleOnRefresh = false;

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
    _scrollController.addListener(_onScroll);
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.isCurrentTab && !_initialSearchDone) {
        _initialSearchDone = true;
        _page = 1;
        _loadDiscoveryWithCache();
      }
    });
  }

  /// Load current user's district and age for quick-chip filters.
  Future<void> _loadUserData() async {
    if (_userDataLoaded) return;
    try {
      final storage = await LocalStorageService.getInstance();
      final user = storage.getUser();
      if (user != null) {
        _userDistrict = user.location?.districtName;
        final dob = user.dateOfBirth;
        if (dob != null) {
          final now = DateTime.now();
          int age = now.year - dob.year;
          if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
            age--;
          }
          _userAge = age;
        }
      }
      _userDataLoaded = true;

      // Load persisted active chips from Hive (Gap 3)
      final saved = storage.getString('people_active_chips');
      if (saved != null && mounted) {
        try {
          final list = (jsonDecode(saved) as List).cast<String>();
          if (list.isNotEmpty) {
            setState(() {
              _activeChips.addAll(list);
              // Re-apply chip filters to state
              _onlineOnly = _activeChips.contains('online');
              _hasPhotoOnly = _activeChips.contains('has_photo');
              _student = _activeChips.contains('student');
              if (_activeChips.contains('nearby') && _userDistrict != null) {
                _locationFilter = _userDistrict!;
              }
              if (_activeChips.contains('my_age') && _userAge != null) {
                _ageMin = _userAge! - 3;
                _ageMax = _userAge! + 3;
              }
            });
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(PeopleSearchTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentTab && !oldWidget.isCurrentTab && !_initialSearchDone) {
      _initialSearchDone = true;
      _page = 1;
      _loadDiscoveryWithCache();
    }
  }

  /// Stale-while-revalidate: show cached discovery instantly, refresh in background.
  Future<void> _loadDiscoveryWithCache() async {
    final sw = PerfLogger.startTiming();

    // 1. Try cache first
    final cached = await PeopleCacheService.instance.getDiscovery();
    if (cached != null && cached.isNotEmpty && mounted) {
      PerfLogger.log('people_cache_hit', {'count': cached.length});
      setState(() {
        _results = cached;
        _showingCached = true;
        _loading = false;
      });
      // Prefetch avatars for visible results
      _prefetchAvatars(cached);
    } else {
      PerfLogger.log('people_cache_miss');
    }

    // 2. Fetch fresh data in background
    _performSearch(forceInitial: true).then((_) {
      PerfLogger.endTiming(sw, 'people_load_total', {'count': _results.length});
    });
  }

  /// Prefetch avatar images for first N people results with size constraints.
  void _prefetchAvatars(List<PersonSearchResult> people) {
    final urls = people
        .take(10)
        .map((p) => p.profilePhotoUrl)
        .whereType<String>()
        .toList();
    if (urls.isEmpty) return;
    for (final url in urls) {
      if (url.isNotEmpty) {
        final image = ResizeImage(
          NetworkImage(url),
          width: 150,
          height: 150,
        );
        precacheImage(image, context).then((_) {
          PerfLogger.log('avatar_preload_hit', {'url': url});
        }).catchError((_) {
          PerfLogger.log('avatar_preload_miss', {'url': url});
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // Prefetch at 60% scroll depth
    if (pos.pixels > pos.maxScrollExtent * 0.6) {
      _maybePrefetchNextPage();
    }
    // Track scroll depth every 10 profiles (Task 4.6)
    if (_results.isNotEmpty && pos.maxScrollExtent > 0) {
      final approxVisible = (pos.pixels / (pos.maxScrollExtent / _results.length)).round().clamp(0, _results.length);
      if (approxVisible >= _lastTrackedDepth + 10) {
        _lastTrackedDepth = (approxVisible ~/ 10) * 10;
        EventTrackingService.getInstance().then((t) {
          t.trackEvent(
            eventType: 'discovery_scroll_depth',
            metadata: {
              'source': 'discovery',
              'depth': _lastTrackedDepth,
            },
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    final currentQuery = _queryController.text.trim().toLowerCase();

    // Task 5.4: If new query extends the previous query, filter locally for instant feedback
    if (currentQuery.length >= 2 &&
        _previousQuery.isNotEmpty &&
        currentQuery.startsWith(_previousQuery) &&
        _lastFullResults != null &&
        _lastFullResults!.isNotEmpty) {
      final filtered = _lastFullResults!.where((p) {
        final name = p.fullName.toLowerCase();
        final username = (p.username ?? '').toLowerCase();
        final employer = (p.employer ?? '').toLowerCase();
        final location = (p.locationString ?? '').toLowerCase();
        return name.contains(currentQuery) ||
            username.contains(currentQuery) ||
            employer.contains(currentQuery) ||
            location.contains(currentQuery);
      }).toList();
      setState(() {
        _results = filtered;
      });
      PerfLogger.log('people_local_filter', {
        'query': currentQuery,
        'from': _lastFullResults!.length,
        'to': filtered.length,
      });
    }

    _debounce = Timer(_debounceDuration, () {
      if (_canSearch) {
        _page = 1;
        _pageCache = {};
        _performSearch();
      } else {
        setState(() {
          _results = [];
          _error = null;
          _lastPage = 1;
          _total = 0;
          _lastFullResults = null;
          _previousQuery = '';
        });
      }
    });
  }

  Future<void> _performSearch({bool forceInitial = false}) async {
    if (!forceInitial && !_canSearch) return;

    // Task 5.2: Check in-memory page cache before fetching
    if (_page > 1 && _pageCache.containsKey(_page)) {
      PerfLogger.log('people_page_cache_hit', {'page': _page});
      setState(() {
        _results = [..._results, ..._pageCache[_page]!];
        _loadingMore = false;
      });
      return;
    }

    if (_page == 1) setState(() => _loading = true);
    if (_page > 1) setState(() => _loadingMore = true);
    _error = null;

    // Track search queries (not discovery)
    final queryText = _queryController.text.trim();
    if (queryText.length >= 2 && _page == 1) {
      EventTrackingService.getInstance().then((t) {
        t.trackSearch(queryText, 0);
      });
    }

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
      hasBusiness: _activeChips.contains('has_business') ? true : null,
      relationshipStatus: _relationshipStatus,
      sector: _sectorFilter.isEmpty ? null : _sectorFilter,
      hasInterests: _hasInterests ? true : null,
      profileComplete: _profileComplete ? true : null,
      friendsOfFriendsOnly: _friendsOfFriendsOnly ? true : null,
      verified: _selectedRelevances.contains('verified') ? true : null,
      possibleBusinessConnection: _selectedRelevances.contains('possible_business_connection') ? true : null,
      possibleEmployer: _selectedRelevances.contains('possible_employer') ? true : null,
      sortValues: sortValues,
      shuffle: _shuffleOnRefresh ? true : null,
    );

    // Reset shuffle flag after use
    _shuffleOnRefresh = false;
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadingMore = false;
      _showingCached = false;
      if (result.success && result.response != null) {
        final r = result.response!;
        // Task 5.2: Store page results in cache
        _pageCache[r.currentPage] = r.people;
        if (_page == 1) {
          _results = r.people;
          // Task 5.4: Store full results for local filtering
          _lastFullResults = List.from(r.people);
          _previousQuery = queryText.toLowerCase();
          // Cache discovery results (page 1, no query, no filters)
          if (forceInitial || (!_canSearch && r.people.isNotEmpty)) {
            PeopleCacheService.instance.saveDiscovery(r.people);
          }
          // Prefetch avatars for fresh results
          _prefetchAvatars(r.people);
        } else {
          _results = [..._results, ...r.people];
          // Task 5.4: Extend full results for broader local filtering
          _lastFullResults = List.from(_results);
        }
        _lastPage = r.lastPage;
        _total = r.total;
        _error = null;
        // Reset prefetch for new result set
        _prefetchedNextPage = null;
      } else {
        _error = result.message ?? 'Something went wrong. Tap to retry.';
        if (_page == 1 && !_showingCached) _results = [];
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
      _pageCache = {};
      _lastFullResults = null;
      _previousQuery = '';
    });
    if (_canSearch) _performSearch();
  }

  void _updatePersonInList(int id, PersonSearchResult updated) {
    setState(() {
      final i = _results.indexWhere((p) => p.id == id);
      if (i >= 0) _results[i] = updated;
    });
  }

  /// Toggle a quick-chip filter and re-search (Task 4.2).
  void _toggleChip(String chip) {
    setState(() {
      if (_activeChips.contains(chip)) {
        _activeChips.remove(chip);
      } else {
        _activeChips.add(chip);
      }
      // Apply chip filters to state
      _onlineOnly = _activeChips.contains('online');
      _hasPhotoOnly = _activeChips.contains('has_photo');
      _student = _activeChips.contains('student');

      if (_activeChips.contains('nearby') && _userDistrict != null) {
        _locationFilter = _userDistrict!;
      } else if (!_activeChips.contains('nearby')) {
        _locationFilter = '';
      }

      if (_activeChips.contains('my_age') && _userAge != null) {
        _ageMin = _userAge! - 3;
        _ageMax = _userAge! + 3;
      } else if (!_activeChips.contains('my_age')) {
        _ageMin = null;
        _ageMax = null;
      }

      // has_business chip
      // Note: hasBusiness is passed directly in _performSearch
    });
    // Persist active chips to Hive (Gap 3)
    _saveActiveChips();
    _page = 1;
    _performSearch();
  }

  /// Persist active chip selections to Hive for session continuity.
  void _saveActiveChips() {
    LocalStorageService.getInstance().then((storage) {
      storage.setString('people_active_chips', jsonEncode(_activeChips.toList()));
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchBar(),
        _buildQuickChips(),
        _buildFilterRow(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  /// Discovery mode indicator + quick filter chips (Task 4.1, 4.2).
  Widget _buildQuickChips() {
    final query = _queryController.text.trim();
    final isDiscovery = query.length < 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Discovery mode indicator (Task 4.1)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: isDiscovery
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'People you might like',
                      style: TextStyle(
                        color: _kPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Based on your location, interests, and connections',
                      style: TextStyle(
                        color: _kSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Search results for \'$query\'',
                  style: TextStyle(
                    color: _kPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        // Quick filter chips (Task 4.2)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              // "Clear filters" pill — only visible when filters are active (Gap 6)
              if (_activeChips.isNotEmpty || _hasActiveFilters) ...[
                _buildClearFiltersChip(),
                const SizedBox(width: 6),
              ],
              _buildChip('Nearby', 'nearby', enabled: _userDistrict != null),
              const SizedBox(width: 6),
              _buildChip('My Age', 'my_age', enabled: _userAge != null),
              const SizedBox(width: 6),
              _buildChip('Online', 'online'),
              const SizedBox(width: 6),
              _buildChip('With Photo', 'has_photo'),
              const SizedBox(width: 6),
              _buildChip('Students', 'student'),
              const SizedBox(width: 6),
              _buildChip('Business', 'has_business'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, String key, {bool enabled = true}) {
    final isActive = _activeChips.contains(key);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : _kPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isActive,
      showCheckmark: false,
      onSelected: enabled ? (_) => _toggleChip(key) : null,
      backgroundColor: Colors.white,
      selectedColor: _kPrimary,
      side: BorderSide(
        color: isActive ? _kPrimary : const Color(0xFFE0E0E0),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  /// "Clear filters" pill that appears when any chip or advanced filter is active.
  Widget _buildClearFiltersChip() {
    return ActionChip(
      avatar: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
      label: const Text(
        'Clear all',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: _clearAllFilters,
      labelPadding: const EdgeInsets.only(left: 2, right: 4),
      backgroundColor: _kPrimary,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  /// Reset all quick-chip and advanced filters, persist, and re-search.
  void _clearAllFilters() {
    setState(() {
      _activeChips.clear();
      _onlineOnly = false;
      _hasPhotoOnly = false;
      _student = false;
      _locationFilter = '';
      _ageMin = null;
      _ageMax = null;
      _schoolFilter = '';
      _employerFilter = '';
      _sectorFilter = '';
      _relationshipStatus = null;
      _hasInterests = false;
      _profileComplete = false;
      _friendsOfFriendsOnly = false;
    });
    _saveActiveChips();
    _page = 1;
    _pageCache = {};
    _performSearch();
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
              if (_canSearch) { _page = 1; _pageCache = {}; _performSearch(); }
            }),
          ),
          const SizedBox(width: 8),
          _RelevanceMultiSelect(
            selected: _selectedRelevances,
            onChanged: (list) => setState(() {
              _selectedRelevances = list;
              if (_canSearch) { _page = 1; _pageCache = {}; _performSearch(); }
            }),
          ),
          const SizedBox(width: 4),
          _AgeRangePicker(
            ageMin: _ageMin,
            ageMax: _ageMax,
            onChanged: (min, max) => setState(() {
              _ageMin = min;
              _ageMax = max;
              if (_canSearch) { _page = 1; _pageCache = {}; _performSearch(); }
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

    // Use prefetched page if available
    if (_prefetchedNextPage != null && _prefetchedNextPage!.isNotEmpty) {
      PerfLogger.prefetchHits++;
      PerfLogger.log('people_prefetch_hit', {'page': _page});
      setState(() {
        _results = [..._results, ..._prefetchedNextPage!];
        _prefetchedNextPage = null;
      });
      return;
    }

    PerfLogger.prefetchMisses++;
    _performSearch();
  }

  /// Prefetch next page in background when user scrolls past 60%.
  void _maybePrefetchNextPage() {
    if (_isPrefetching || _prefetchedNextPage != null) return;
    if (_page >= _lastPage) return;
    _isPrefetching = true;

    final nextPage = _page + 1;
    final sortOnly = _selectedRelevances
        .where((s) => !_relevanceFilterKeys.contains(s))
        .toList();
    final sortValues = sortOnly.isEmpty ? ['relevance'] : sortOnly;

    _searchService.search(
      userId: widget.userId,
      query: _queryController.text.trim().isEmpty ? null : _queryController.text.trim(),
      page: nextPage,
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
    ).then((result) {
      _isPrefetching = false;
      if (result.success && result.response != null && result.response!.people.isNotEmpty) {
        _prefetchedNextPage = result.response!.people;
        PerfLogger.log('people_prefetch_ready', {'page': nextPage, 'count': _prefetchedNextPage!.length});
      }
    });
  }

  /// Pull-to-refresh keeps current query and all filters; only resets page to 1 and refetches.
  Future<void> _onRefresh() async {
    _page = 1;
    _prefetchedNextPage = null;
    _pageCache = {};
    _lastFullResults = null;
    _previousQuery = '';
    _shuffleOnRefresh = true;
    _lastTrackedDepth = 0;
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
              controller: _scrollController,
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
                return Dismissible(
                  key: ValueKey('dismiss_${person.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(_kCardRadius),
                    ),
                    child: const Text(
                      'Not interested',
                      style: TextStyle(
                        color: Color(0xFF991B1B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  onDismissed: (_) {
                    // Track not_interested event (Task 4.4)
                    EventTrackingService.getInstance().then((t) {
                      t.trackEvent(
                        eventType: 'not_interested',
                        creatorId: person.id,
                        metadata: {'target_user_id': person.id, 'source': 'discovery_swipe'},
                      );
                    });
                    setState(() {
                      _results.removeAt(index);
                    });
                  },
                  child: RepaintBoundary(
                    key: ValueKey(person.id),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PersonCard(
                        person: person,
                        currentUserId: widget.userId,
                        friendService: widget.friendService,
                        messageService: widget.messageService,
                        onStatusChanged: (updated) => _updatePersonInList(person.id, updated),
                        userDistrict: _userDistrict,
                      ),
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

  void _resetAll() {
    setState(() {
      _onlineOnly = false;
      _hasPhotoOnly = false;
      _student = false;
      _hasInterests = false;
      _profileComplete = false;
      _friendsOfFriendsOnly = false;
      _relationshipStatus = null;
      _location.clear();
      _school.clear();
      _employer.clear();
      _sector.clear();
    });
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
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Text('More Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: _resetAll,
                    child: Text('Reset', style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                  ),
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
  final String? userDistrict;

  const _PersonCard({
    required this.person,
    required this.currentUserId,
    required this.friendService,
    required this.messageService,
    required this.onStatusChanged,
    this.userDistrict,
  });

  IconData _iconForInCommon(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('district') || lower.contains('region')) return Icons.location_on_outlined;
    if (lower.contains('employer')) return Icons.work_outline;
    if (lower.contains('university') || lower.contains('school')) return Icons.school_outlined;
    if (lower.contains('interest')) return Icons.favorite_border;
    return Icons.tag;
  }


  /// Count shared interests from inCommon list (Task 4.3).
  int get _sharedInterestsCount {
    return person.inCommon.where((t) => t.toLowerCase().contains('interest')).length;
  }

  /// Location tag: "Same area" if same district, district name otherwise (Task 4.3).
  String? get _locationTag {
    if (person.districtName == null || person.districtName!.isEmpty) return null;
    if (userDistrict != null && person.districtName == userDistrict) {
      return 'Same area';
    }
    return person.districtName;
  }

  /// Small badge chip for mutual friends, shared interests, location (Task 4.3).
  Widget _badgeChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _kSecondary),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            color: _kSecondary.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    final isSelf = person.id == currentUserId;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          EventTrackingService.getInstance().then((t) {
            t.trackEvent(eventType: 'profile_viewed', creatorId: person.id);
          });
          Navigator.pushNamed(context, '/profile/${person.id}');
        },
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
                    // Enhanced badges row (Task 4.3)
                    if (person.mutualFriendsCount > 0 || person.inCommon.isNotEmpty || _locationTag != null) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (person.mutualFriendsCount > 0)
                            _badgeChip(
                              Icons.people_outline,
                              '${person.mutualFriendsCount} mutual friend${person.mutualFriendsCount == 1 ? '' : 's'}',
                            ),
                          if (_sharedInterestsCount > 0)
                            _badgeChip(
                              Icons.favorite_border,
                              '$_sharedInterestsCount shared interest${_sharedInterestsCount == 1 ? '' : 's'}',
                            ),
                          if (_locationTag != null)
                            _badgeChip(
                              Icons.location_on_outlined,
                              _locationTag!,
                            ),
                        ],
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
      EventTrackingService.getInstance().then((t) {
        t.trackEvent(eventType: 'follow', creatorId: widget.person.id);
      });
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
      EventTrackingService.getInstance().then((t) {
        t.trackEvent(eventType: 'unfollow', creatorId: widget.person.id);
      });
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
      EventTrackingService.getInstance().then((t) {
        t.trackEvent(eventType: 'follow', creatorId: widget.person.id, metadata: {'action': 'accept'});
      });
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
      EventTrackingService.getInstance().then((t) {
        t.trackEvent(eventType: 'unfollow', creatorId: widget.person.id, metadata: {'action': 'decline'});
      });
      widget.onStatusChanged(widget.person.copyWith(friendshipStatus: 'none'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request declined')),
      );
    }
  }

  Future<void> _openChat() async {
    EventTrackingService.getInstance().then((t) {
      t.trackEvent(eventType: 'message_sent', creatorId: widget.person.id, metadata: {'source': 'people_tab'});
    });
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
