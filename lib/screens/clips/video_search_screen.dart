import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/clip_models.dart' as models;
import '../../services/clip_service.dart';
import '../../services/local_storage_service.dart';
import 'clip_player_screen.dart';

class VideoSearchScreen extends StatefulWidget {
  const VideoSearchScreen({super.key});

  @override
  State<VideoSearchScreen> createState() => _VideoSearchScreenState();
}

class _VideoSearchScreenState extends State<VideoSearchScreen>
    with SingleTickerProviderStateMixin {
  // DESIGN.md: primary #1A1A1A, background #FAFAFA, secondary #666666, accent #999999
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _background = Color(0xFFFAFAFA);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _accent = Color(0xFF999999);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ClipService _clipService = ClipService();

  late TabController _tabController;

  bool _isSearching = false;
  bool _showSuggestions = true;
  String _currentQuery = '';

  // Search results
  ClipSearchResult? _searchResult;
  List<SearchSuggestion> _suggestions = [];
  List<String> _recentSearches = [];

  // Pagination
  int _currentPage = 1;
  bool _hasMoreResults = true;
  bool _isLoadingMore = false;

  // Current search type
  SearchType _searchType = SearchType.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadRecentSearches();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    final types = [
      SearchType.all,
      SearchType.clips,
      SearchType.users,
      SearchType.hashtags,
    ];

    if (_searchType != types[_tabController.index]) {
      setState(() {
        _searchType = types[_tabController.index];
        _currentPage = 1;
        _hasMoreResults = true;
      });

      if (_currentQuery.isNotEmpty) {
        _performSearch();
      }
    }
  }

  Future<void> _loadRecentSearches() async {
    final storage = await LocalStorageService.getInstance();
    final user = storage.getUser();
    if (user?.userId != null) {
      final searches = await _clipService.getRecentSearches(user!.userId!);
      if (mounted) {
        setState(() {
          _recentSearches = searches;
        });
      }
    }
  }

  Future<void> _loadSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = true;
      });
      return;
    }

    final suggestions = await _clipService.getSearchSuggestions(query);
    if (mounted && _currentQuery == query) {
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = true;
      });
    }
  }

  Future<void> _performSearch({bool loadMore = false}) async {
    if (_currentQuery.isEmpty) return;

    if (!loadMore) {
      setState(() {
        _isSearching = true;
        _currentPage = 1;
        _hasMoreResults = true;
        _showSuggestions = false;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final storage = await LocalStorageService.getInstance();
      final user = storage.getUser();
      final result = await _clipService.searchClips(
        query: _currentQuery,
        type: _searchType,
        page: loadMore ? _currentPage + 1 : 1,
        perPage: 20,
        currentUserId: user?.userId,
      );

      if (mounted) {
        setState(() {
          if (loadMore && _searchResult != null) {
            // Append results
            _searchResult = ClipSearchResult(
              success: true,
              clips: [..._searchResult!.clips, ...result.clips],
              users: [..._searchResult!.users, ...result.users],
              hashtags: [..._searchResult!.hashtags, ...result.hashtags],
              query: result.query,
              meta: result.meta,
            );
            _currentPage++;
          } else {
            _searchResult = result;
            _currentPage = 1;
          }

          _hasMoreResults = _hasMoreClipsToLoad();
          _isSearching = false;
          _isLoadingMore = false;
        });

        // Save search to history
        if (!loadMore && user?.userId != null) {
          _clipService.saveSearch(user!.userId!, _currentQuery);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hitilafu: ${e.toString()}')),
        );
      }
    }
  }

  bool _hasMoreClipsToLoad() {
    if (_searchResult == null) return false;

    final meta = _searchResult!.meta;
    if (meta == null) return false;
    return meta.hasMore;
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _currentQuery = query.trim();
      _showSuggestions = false;
    });
    _searchFocusNode.unfocus();
    _performSearch();
  }

  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    _onSearchSubmitted(suggestion);
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _currentQuery = '';
      _searchResult = null;
      _suggestions = [];
      _showSuggestions = true;
    });
    _searchFocusNode.requestFocus();
  }

  Future<void> _clearSearchHistory() async {
    final storage = await LocalStorageService.getInstance();
    final user = storage.getUser();
    if (user?.userId != null) {
      await _clipService.clearSearchHistory(user!.userId!);
      setState(() {
        _recentSearches = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: _primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: _buildSearchField(),
        titleSpacing: 0,
        bottom: _showSuggestions
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: _primary,
                labelColor: _primary,
                unselectedLabelColor: _secondaryText,
                tabs: const [
                  Tab(text: 'Zote'),
                  Tab(text: 'Video'),
                  Tab(text: 'Watumiaji'),
                  Tab(text: 'Hashtag'),
                ],
              ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildSearchField() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _searchController,
      builder: (context, value, _) {
        return Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accent.withOpacity(0.3)),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: const TextStyle(color: _primary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Tafuta video, watumiaji, hashtag...',
              hintStyle: const TextStyle(color: _secondaryText),
              prefixIcon: const Icon(Icons.search, color: _secondaryText, size: 24),
              suffixIcon: value.text.isNotEmpty
                  ? SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton(
                        icon: const Icon(Icons.clear, color: _secondaryText, size: 20),
                        onPressed: _clearSearch,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            textInputAction: TextInputAction.search,
            onChanged: (value) {
              setState(() {
                _currentQuery = value;
              });
              _loadSuggestions(value);
            },
            onSubmitted: _onSearchSubmitted,
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_showSuggestions) {
      return _buildSuggestionsView();
    }

    if (_isSearching && _searchResult == null) {
      return const Center(
        child: CircularProgressIndicator(color: _primary),
      );
    }

    if (_searchResult == null) {
      return _buildEmptyState();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllResultsTab(),
        _buildClipsTab(),
        _buildUsersTab(),
        _buildHashtagsTab(),
      ],
    );
  }

  Widget _buildSuggestionsView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 16),
          ..._suggestions.map((suggestion) => _buildSearchSuggestionTile(suggestion)),
        ],
        if (_recentSearches.isNotEmpty && _suggestions.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Utafutaji wa Hivi Karibuni',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: _clearSearchHistory,
                    child: const Text('Futa', style: TextStyle(color: _primary)),
                  ),
                ),
              ],
            ),
          ),
          ..._recentSearches.map((search) => _buildSuggestionTile(
                search,
                Icons.history,
                isRecent: true,
              )),
        ],
        if (_suggestions.isEmpty && _recentSearches.isEmpty) ...[
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(Icons.search, size: 64, color: _accent),
                const SizedBox(height: 16),
                const Text(
                  'Tafuta video, watumiaji, au hashtag',
                  style: TextStyle(color: _secondaryText, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestionTile(String text, IconData icon, {bool isRecent = false}) {
    return ListTile(
      minLeadingWidth: 48,
      minVerticalPadding: 12,
      leading: Icon(icon, color: _secondaryText),
      title: Text(
        text,
        style: const TextStyle(color: _primary, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isRecent
          ? SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                icon: const Icon(Icons.north_west, color: _secondaryText, size: 18),
                onPressed: () {
                  _searchController.text = text;
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: text.length),
                  );
                },
              ),
            )
          : null,
      onTap: () => _onSuggestionTap(text),
    );
  }

  Widget _buildSearchSuggestionTile(SearchSuggestion suggestion) {
    IconData icon;
    switch (suggestion.type) {
      case SearchSuggestionType.hashtag:
        icon = Icons.tag;
      case SearchSuggestionType.user:
        icon = Icons.person;
      case SearchSuggestionType.sound:
        icon = Icons.music_note;
      default:
        icon = Icons.search;
    }

    return ListTile(
      minLeadingWidth: 48,
      minVerticalPadding: 12,
      leading: suggestion.imageUrl != null
          ? CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(suggestion.imageUrl!),
              backgroundColor: _accent.withOpacity(0.2),
            )
          : Icon(icon, color: _secondaryText),
      title: Text(
        suggestion.text,
        style: const TextStyle(color: _primary, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: suggestion.count != null
          ? Text(
              '${_formatViewCount(suggestion.count!)} video',
              style: const TextStyle(color: _secondaryText, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: () => _onSuggestionTap(suggestion.text),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: _accent),
            const SizedBox(height: 16),
            Text(
              'Hakuna matokeo ya "$_currentQuery"',
              style: const TextStyle(color: _primary, fontSize: 15),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            const Text(
              'Jaribu maneno mengine',
              style: TextStyle(color: _secondaryText, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllResultsTab() {
    final result = _searchResult!;
    final hasResults = result.clips.isNotEmpty ||
        result.users.isNotEmpty ||
        result.hashtags.isNotEmpty;

    if (!hasResults) {
      return _buildEmptyState();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            _hasMoreResults &&
            !_isLoadingMore) {
          _performSearch(loadMore: true);
        }
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Clips section
          if (result.clips.isNotEmpty) ...[
            _buildSectionHeader('Video', result.clips.length),
            _buildClipsGrid(result.clips.take(6).toList()),
            if (result.clips.length > 6)
              _buildSeeAllButton('Ona video zote', () {
                _tabController.animateTo(1);
              }),
            const SizedBox(height: 24),
          ],

          // Users section
          if (result.users.isNotEmpty) ...[
            _buildSectionHeader('Watumiaji', result.users.length),
            ...result.users.take(5).map(_buildUserTile),
            if (result.users.length > 5)
              _buildSeeAllButton('Ona watumiaji wote', () {
                _tabController.animateTo(2);
              }),
            const SizedBox(height: 24),
          ],

          // Hashtags section
          if (result.hashtags.isNotEmpty) ...[
            _buildSectionHeader('Hashtag', result.hashtags.length),
            ...result.hashtags.take(5).map(_buildHashtagTile),
            if (result.hashtags.length > 5)
              _buildSeeAllButton('Ona hashtag zote', () {
                _tabController.animateTo(3);
              }),
          ],

          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildClipsTab() {
    final clips = _searchResult?.clips ?? [];

    if (clips.isEmpty) {
      return _buildEmptyState();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            _hasMoreResults &&
            !_isLoadingMore) {
          _performSearch(loadMore: true);
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 9 / 16,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: clips.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= clips.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildClipCard(clips[index], index);
        },
      ),
    );
  }

  Widget _buildUsersTab() {
    final users = _searchResult?.users ?? [];

    if (users.isEmpty) {
      return _buildEmptyState();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            _hasMoreResults &&
            !_isLoadingMore) {
          _performSearch(loadMore: true);
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= users.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildUserTile(users[index]);
        },
      ),
    );
  }

  Widget _buildHashtagsTab() {
    final hashtags = _searchResult?.hashtags ?? [];

    if (hashtags.isEmpty) {
      return _buildEmptyState();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            _hasMoreResults &&
            !_isLoadingMore) {
          _performSearch(loadMore: true);
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: hashtags.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= hashtags.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildHashtagTile(hashtags[index]);
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _primary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(color: _secondaryText, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClipsGrid(List<models.Clip> clips) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 9 / 16,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: clips.length,
      itemBuilder: (context, index) => _buildClipCard(clips[index], index),
    );
  }

  Widget _buildClipCard(models.Clip clip, int index) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClipPlayerScreen(
                clips: _searchResult?.clips ?? [clip],
                initialIndex: index,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (clip.thumbnailUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: clip.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: _accent.withOpacity(0.2),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: _accent.withOpacity(0.2),
                    child: Icon(Icons.video_library, color: _accent),
                  ),
                )
              else
                Container(
                  color: _accent.withOpacity(0.2),
                  child: Icon(Icons.video_library, color: _accent),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        _primary.withValues(alpha: 0.7),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (clip.caption?.isNotEmpty == true)
                      Text(
                        clip.caption!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.play_arrow, color: Colors.white70, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          _formatViewCount(clip.viewsCount),
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (clip.duration > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(clip.duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile(models.ClipUser user) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 48,
      minVerticalPadding: 12,
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: user.avatarUrl.isNotEmpty
            ? CachedNetworkImageProvider(user.avatarUrl)
            : null,
        backgroundColor: _accent.withOpacity(0.2),
        child: user.avatarUrl.isEmpty
            ? const Icon(Icons.person, color: _secondaryText)
            : null,
      ),
      title: Text(
        user.displayName,
        style: const TextStyle(
          color: _primary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: user.username != null
          ? Text(
              '@${user.username}',
              style: const TextStyle(color: _secondaryText, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: () {
            // Navigate to user profile
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('Fuata', style: TextStyle(fontSize: 14)),
        ),
      ),
      onTap: () {
        // Navigate to user profile
      },
    );
  }

  Widget _buildHashtagTile(models.ClipHashtag hashtag) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 48,
      minVerticalPadding: 12,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.tag, color: _primary),
      ),
      title: Text(
        hashtag.displayTag,
        style: const TextStyle(
          color: _primary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${_formatViewCount(hashtag.clipsCount)} video',
        style: const TextStyle(color: _secondaryText, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        _onSearchSubmitted(hashtag.displayTag);
      },
    );
  }

  Widget _buildSeeAllButton(String text, VoidCallback onTap) {
    return SizedBox(
      height: 48,
      child: TextButton(
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: const TextStyle(color: _primary, fontSize: 14)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward, size: 16, color: _primary),
          ],
        ),
      ),
    );
  }

  String _formatViewCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
