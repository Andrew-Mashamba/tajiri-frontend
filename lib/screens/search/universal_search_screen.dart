import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/content_engine_models.dart';
import '../../services/content_engine_service.dart';
import '../../widgets/content_result_card.dart';
import '../../widgets/trending_digest_card.dart';

class UniversalSearchScreen extends StatefulWidget {
  final int currentUserId;

  const UniversalSearchScreen({super.key, required this.currentUserId});

  @override
  State<UniversalSearchScreen> createState() => _UniversalSearchScreenState();
}

class _UniversalSearchScreenState extends State<UniversalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  int get _currentUserId => widget.currentUserId;
  bool _isLoading = false;
  String? _activeQuery;

  // Pre-search state
  TrendingDigest? _digest;
  bool _digestLoading = true;

  // Search results
  ContentEngineResult? _searchResult;
  String _selectedType = 'all';
  int _currentPage = 1;
  bool _loadingMore = false;
  final ScrollController _scrollController = ScrollController();

  Timer? _debounce;

  static const _typeFilters = [
    'all',
    'post',
    'clip',
    'music',
    'user_profile',
    'event',
    'group',
    'campaign',
    'product',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _loadDigest();
  }

  Future<void> _loadDigest() async {
    final digest = await ContentEngineService.getTrendingDigest();
    if (mounted) {
      setState(() {
        _digest = digest;
        _digestLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _activeQuery = null;
        _searchResult = null;
        _currentPage = 1;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query, reset: true);
    });
  }

  Future<void> _performSearch(String query, {bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _activeQuery = query;
      });
    }

    final types = _selectedType == 'all' ? null : [_selectedType];
    final result = await ContentEngineService.search(
      query: query,
      userId: _currentUserId,
      types: types,
      page: _currentPage,
    );

    if (mounted) {
      setState(() {
        if (reset || _searchResult == null) {
          _searchResult = result;
        } else {
          // Append for pagination
          _searchResult = ContentEngineResult(
            items: [..._searchResult!.items, ...result.items],
            meta: result.meta,
          );
        }
        _isLoading = false;
        _loadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 300) {
      if (!_loadingMore &&
          _activeQuery != null &&
          (_searchResult?.meta.hasMore ?? false)) {
        setState(() {
          _loadingMore = true;
          _currentPage++;
        });
        _performSearch(_activeQuery!);
      }
    }
  }

  void _onTypeFilterChanged(String type) {
    if (type == _selectedType) return;
    setState(() => _selectedType = type);
    if (_activeQuery != null) {
      _performSearch(_activeQuery!, reset: true);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context) ?? AppStrings('en');

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            autofocus: true,
            decoration: InputDecoration(
              hintText: strings.searchEverything,
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 15),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: Colors.black38),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.black38),
                      onPressed: () {
                        _searchController.clear();
                        _searchFocus.requestFocus();
                      },
                    )
                  : null,
            ),
            onSubmitted: (q) {
              if (q.trim().isNotEmpty) _performSearch(q.trim(), reset: true);
            },
          ),
        ),
      ),
      body: SafeArea(
        child: _activeQuery == null
            ? _buildPreSearchState(strings)
            : _buildSearchResults(strings),
      ),
    );
  }

  /// State 1: Before typing — show trending digest + suggestions
  Widget _buildPreSearchState(AppStrings strings) {
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        // Trending digest card
        if (_digestLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF1A1A1A))),
          )
        else if (_digest != null)
          TrendingDigestCard(
            digest: _digest!,
            onStoryTap: (docId) {
              // Navigate to post/document detail
              Navigator.pushNamed(context, '/post/$docId');
            },
          ),

        // Trending searches section (placeholder — populated by backend)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            strings.trendingSearches,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF1A1A1A)),
          ),
        ),
        // Placeholder for trending hashtags
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            strings.noData,
            style: const TextStyle(color: Colors.black38, fontSize: 13),
          ),
        ),
      ],
    );
  }

  /// State 3: After search — type filter tabs + results list
  Widget _buildSearchResults(AppStrings strings) {
    return Column(
      children: [
        // Type filter chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: _typeFilters.length,
            itemBuilder: (context, index) {
              final type = _typeFilters[index];
              final isSelected = type == _selectedType;
              return ChoiceChip(
                label: Text(_typeLabel(type, strings)),
                selected: isSelected,
                onSelected: (_) => _onTypeFilterChanged(type),
                selectedColor: const Color(0xFF1A1A1A),
                backgroundColor: Colors.grey[100],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: BorderSide.none,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              );
            },
          ),
        ),

        // Query expansion info
        if (_searchResult?.meta.queryExpansion != null &&
            (_searchResult!.meta.queryExpansion!.expandedQueries.isNotEmpty))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Pia tumetafuta: ${_searchResult!.meta.queryExpansion!.expandedQueries.take(3).join(", ")}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.black38),
            ),
          ),

        // Results list
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF1A1A1A)))
              : _searchResult == null || _searchResult!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 48, color: Colors.black26),
                          const SizedBox(height: 12),
                          Text(strings.noResults,
                              style:
                                  const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 32),
                      itemCount: _searchResult!.items.length +
                          (_loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _searchResult!.items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF1A1A1A))),
                          );
                        }
                        final item = _searchResult!.items[index];
                        return ContentResultCard(
                          result: item,
                          currentUserId: _currentUserId,
                          onPostTap: (post) => Navigator.pushNamed(
                              context, '/post/${post.id}'),
                          onHashtagTap: (tag) {
                            _searchController.text = '#$tag';
                            _performSearch('#$tag', reset: true);
                          },
                          onUserTap: (userId) => Navigator.pushNamed(
                              context, '/profile/$userId'),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  String _typeLabel(String type, AppStrings strings) {
    switch (type) {
      case 'all':
        return strings.ceAllTypes;
      case 'post':
        return strings.posts;
      case 'clip':
        return strings.clips;
      case 'music':
        return strings.musicType;
      case 'user_profile':
        return strings.people;
      case 'event':
        return strings.eventsType;
      case 'group':
        return strings.groupsType;
      case 'campaign':
        return strings.campaignsType;
      case 'product':
        return strings.productsType;
      default:
        return type;
    }
  }
}
