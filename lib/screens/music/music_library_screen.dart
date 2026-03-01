import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/music_models.dart';
import '../../services/music_service.dart';
import '../../services/audio_cache_service.dart';
import 'music_player_sheet.dart';
import '../clips/artistdetail_screen.dart';
import 'mini_player_widget.dart';

/// Spotify-inspired Music Library Screen
/// Features:
/// - Grid/List view toggle
/// - Smart filters (mood, genre, activity)
/// - Recently played section
/// - Lazy loading with shimmer placeholders
/// - Persistent mini player
/// - Audio prefetching
class MusicLibraryScreen extends StatefulWidget {
  final int currentUserId;
  final Function(MusicTrack)? onTrackSelected;

  const MusicLibraryScreen({
    super.key,
    required this.currentUserId,
    this.onTrackSelected,
  });

  @override
  State<MusicLibraryScreen> createState() => _MusicLibraryScreenState();
}

class _MusicLibraryScreenState extends State<MusicLibraryScreen>
    with TickerProviderStateMixin {
  final MusicService _musicService = MusicService();
  final AudioCacheService _audioCacheService = AudioCacheService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // View state
  bool _isGridView = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  String? _activeFilter;
  String _sortBy = 'recent';

  // Data
  List<MusicTrack> _tracks = [];
  List<MusicTrack> _recentlyPlayed = [];
  List<MusicTrack> _searchResults = [];
  List<MusicCategoryModel> _categories = [];
  List<MusicArtistModel> _featuredArtists = [];
  int _currentPage = 1;
  bool _hasMore = true;

  // Currently playing
  MusicTrack? _currentTrack;
  bool _isPlaying = false;

  // Smart filters
  final List<_SmartFilter> _smartFilters = [
    _SmartFilter('Yote', null, Icons.music_note),
    _SmartFilter('Bongo', 'bongo', Icons.music_note),
    _SmartFilter('Hip Hop', 'hiphop', Icons.headphones),
    _SmartFilter('Gospel', 'gospel', Icons.church),
    _SmartFilter('Zouk', 'zouk', Icons.nightlife),
    _SmartFilter('R&B', 'rnb', Icons.favorite),
    _SmartFilter('Taarab', 'taarab', Icons.piano),
  ];

  // Animation
  late AnimationController _filterAnimController;

  @override
  void initState() {
    super.initState();
    _filterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _filterAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _musicService.getTracks(currentUserId: widget.currentUserId),
      _musicService.getCategories(),
      _musicService.getArtists(),
      _loadRecentlyPlayed(),
    ]);

    if (mounted) {
      setState(() {
        _tracks = (results[0] as TracksResult).tracks;
        _categories = (results[1] as CategoriesResult).categories;
        _featuredArtists = (results[2] as ArtistsResult).artists.take(10).toList();
        _isLoading = false;
        _hasMore = _tracks.length >= 20;
      });

      // Prefetch audio for first few tracks
      _prefetchAudio(_tracks.take(5).toList());
    }
  }

  Future<void> _loadRecentlyPlayed() async {
    // Load from local storage or API
    final result = await _musicService.getSavedTracks(widget.currentUserId);
    if (mounted) {
      setState(() {
        _recentlyPlayed = result.tracks.take(10).toList();
      });
    }
  }

  void _prefetchAudio(List<MusicTrack> tracks) {
    for (final track in tracks) {
      if (track.audioUrl.isNotEmpty) {
        _audioCacheService.prefetchAudio(track.audioUrl);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMore();
    }

    // Prefetch as user scrolls
    final scrollPosition = _scrollController.position.pixels;
    final itemHeight = _isGridView ? 200.0 : 72.0;
    final visibleIndex = (scrollPosition / itemHeight).floor();
    final prefetchStart = (visibleIndex + 5).clamp(0, _tracks.length);
    final prefetchEnd = (visibleIndex + 10).clamp(0, _tracks.length);

    if (prefetchStart < prefetchEnd) {
      _prefetchAudio(_tracks.sublist(prefetchStart, prefetchEnd));
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    final result = await _musicService.getTracks(
      page: _currentPage,
      currentUserId: widget.currentUserId,
    );

    if (mounted) {
      setState(() {
        _tracks.addAll(result.tracks);
        _hasMore = result.tracks.length >= 20;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final result = await _musicService.searchTracks(
      query,
      currentUserId: widget.currentUserId,
    );

    if (mounted) {
      setState(() {
        _searchResults = result.tracks;
        _isSearching = false;
      });
    }
  }

  void _applyFilter(String? filter) {
    setState(() {
      _activeFilter = filter;
      _currentPage = 1;
    });
    _loadFilteredTracks();
  }

  Future<void> _loadFilteredTracks() async {
    setState(() => _isLoading = true);

    TracksResult result;
    if (_activeFilter != null) {
      // Find category by slug
      final category = _categories.firstWhere(
        (c) => c.name.toLowerCase().contains(_activeFilter!.toLowerCase()),
        orElse: () => _categories.first,
      );
      result = await _musicService.getTracksByCategory(
        category.id,
        currentUserId: widget.currentUserId,
      );
    } else {
      result = await _musicService.getTracks(currentUserId: widget.currentUserId);
    }

    if (mounted) {
      setState(() {
        _tracks = result.tracks;
        _isLoading = false;
      });
    }
  }

  void _sortTracks(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      switch (sortBy) {
        case 'recent':
          _tracks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'alphabetical':
          _tracks.sort((a, b) => a.title.compareTo(b.title));
          break;
        case 'artist':
          _tracks.sort((a, b) =>
              (a.artist?.name ?? '').compareTo(b.artist?.name ?? ''));
          break;
        case 'duration':
          _tracks.sort((a, b) => b.duration.compareTo(a.duration));
          break;
      }
    });
  }

  void _playTrack(MusicTrack track, {List<MusicTrack>? queue, int? startIndex}) {
    setState(() {
      _currentTrack = track;
      _isPlaying = true;
    });

    // Add to recently played
    if (!_recentlyPlayed.any((t) => t.id == track.id)) {
      setState(() {
        _recentlyPlayed.insert(0, track);
        if (_recentlyPlayed.length > 10) {
          _recentlyPlayed.removeLast();
        }
      });
    }

    // Determine the queue to use
    final playQueue = queue ?? (_isSearching ? _searchResults : _tracks);
    final trackIndex = startIndex ?? playQueue.indexWhere((t) => t.id == track.id);

    if (widget.onTrackSelected != null) {
      widget.onTrackSelected!(track);
      Navigator.pop(context);
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MusicPlayerSheet(
          track: track,
          currentUserId: widget.currentUserId,
          queue: playQueue,
          startIndex: trackIndex >= 0 ? trackIndex : 0,
          onClose: () {
            // Update playing state when player is closed
            setState(() {
              _isPlaying = false;
            });
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDark ? const Color(0xFF282828) : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Spotify-style App Bar
              _buildSliverAppBar(isDark),

              // Search Bar
              SliverToBoxAdapter(
                child: _buildSearchBar(isDark, cardColor),
              ),

              // Smart Filters
              SliverToBoxAdapter(
                child: _buildSmartFilters(isDark),
              ),

              // Content
              if (_searchController.text.isNotEmpty)
                _buildSearchResults(isDark, cardColor)
              else ...[
                // Recently Played Section
                if (_recentlyPlayed.isNotEmpty && _activeFilter == null)
                  SliverToBoxAdapter(
                    child: _buildRecentlyPlayedSection(isDark, cardColor),
                  ),

                // Featured Artists
                if (_featuredArtists.isNotEmpty && _activeFilter == null)
                  SliverToBoxAdapter(
                    child: _buildFeaturedArtistsSection(isDark),
                  ),

                // Main Track List Header
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    isDark,
                    _activeFilter != null
                        ? _smartFilters
                            .firstWhere((f) => f.slug == _activeFilter)
                            .name
                        : 'Muziki Wote',
                    showViewToggle: true,
                    showSort: true,
                  ),
                ),

                // Track Grid/List
                _isLoading
                    ? SliverToBoxAdapter(child: _buildLoadingShimmer(isDark))
                    : _isGridView
                        ? _buildTrackGrid(isDark, cardColor)
                        : _buildTrackList(isDark, cardColor),

                // Loading More Indicator
                if (_isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),

                // Bottom Padding for Mini Player
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ],
          ),

          // Mini Player
          if (_currentTrack != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayerWidget(
                track: _currentTrack!,
                isPlaying: _isPlaying,
                onTap: () => _playTrack(_currentTrack!),
                onPlayPause: () => setState(() => _isPlaying = !_isPlaying),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          'Maktaba ya Muziki',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () => _showRecentlyPlayed(),
          tooltip: 'Historia',
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => _showSettings(),
          tooltip: 'Mipangilio',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: 'Tafuta nyimbo, wasanii...',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _search('');
                  },
                )
              : null,
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onChanged: _search,
      ),
    );
  }

  Widget _buildSmartFilters(bool isDark) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _smartFilters.length,
        itemBuilder: (context, index) {
          final filter = _smartFilters[index];
          final isActive = _activeFilter == filter.slug;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(filter.name),
              avatar: isActive ? null : Icon(filter.icon, size: 16),
              selected: isActive,
              onSelected: (_) => _applyFilter(filter.slug),
              backgroundColor: isDark ? const Color(0xFF282828) : Colors.grey[200],
              selectedColor: const Color(0xFF1DB954), // Spotify green
              labelStyle: TextStyle(
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    bool isDark,
    String title, {
    bool showViewToggle = false,
    bool showSort = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              if (showSort)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.sort,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onSelected: _sortTracks,
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'recent', child: Text('Hivi Karibuni')),
                    const PopupMenuItem(value: 'alphabetical', child: Text('A-Z')),
                    const PopupMenuItem(value: 'artist', child: Text('Msanii')),
                    const PopupMenuItem(value: 'duration', child: Text('Muda')),
                  ],
                ),
              if (showViewToggle)
                IconButton(
                  icon: Icon(
                    _isGridView ? Icons.view_list : Icons.grid_view,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                  tooltip: _isGridView ? 'Orodha' : 'Gridi',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyPlayedSection(bool isDark, Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            'Ulichocheza Hivi Karibuni',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _recentlyPlayed.length,
            itemBuilder: (context, index) {
              final track = _recentlyPlayed[index];
              return _RecentTrackCard(
                track: track,
                isDark: isDark,
                onTap: () => _playTrack(track),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedArtistsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'Wasanii Maarufu',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _featuredArtists.length,
            itemBuilder: (context, index) {
              final artist = _featuredArtists[index];
              return _ArtistCircle(
                artist: artist,
                isDark: isDark,
                onTap: () => _openArtist(artist),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrackGrid(bool isDark, Color cardColor) {
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final track = _tracks[index];
            return _TrackGridCard(
              track: track,
              isDark: isDark,
              cardColor: cardColor,
              onTap: () => _playTrack(track),
              onSave: () => _toggleSave(track),
            );
          },
          childCount: _tracks.length,
        ),
      ),
    );
  }

  Widget _buildTrackList(bool isDark, Color cardColor) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final track = _tracks[index];
          return _TrackListTile(
            track: track,
            index: index + 1,
            isDark: isDark,
            onTap: () => _playTrack(track),
            onSave: () => _toggleSave(track),
            isPlaying: _currentTrack?.id == track.id && _isPlaying,
          );
        },
        childCount: _tracks.length,
      ),
    );
  }

  Widget _buildSearchResults(bool isDark, Color cardColor) {
    if (_isSearching) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_searchResults.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Hakuna matokeo',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final track = _searchResults[index];
          return _TrackListTile(
            track: track,
            index: index + 1,
            isDark: isDark,
            onTap: () => _playTrack(track),
            onSave: () => _toggleSave(track),
            isPlaying: _currentTrack?.id == track.id && _isPlaying,
          );
        },
        childCount: _searchResults.length,
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          6,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ShimmerTrackTile(isDark: isDark),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleSave(MusicTrack track) async {
    if (track.isSaved == true) {
      await _musicService.unsaveTrack(track.id, widget.currentUserId);
    } else {
      await _musicService.saveTrack(track.id, widget.currentUserId);
    }

    setState(() {
      // Toggle in all lists
      for (var t in _tracks) {
        if (t.id == track.id) {
          // Note: isSaved is final in the model, we'd need to update the list
        }
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(track.isSaved == true ? 'Imeondolewa' : 'Imehifadhiwa'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _openArtist(MusicArtistModel artist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArtistDetailScreen(
          artist: artist,
          currentUserId: widget.currentUserId,
          onTrackSelected: widget.onTrackSelected,
        ),
      ),
    );
  }

  void _showRecentlyPlayed() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _RecentlyPlayedSheet(
        tracks: _recentlyPlayed,
        onTrackTap: _playTrack,
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SettingsSheet(
        isGridView: _isGridView,
        sortBy: _sortBy,
        onViewChanged: (grid) => setState(() => _isGridView = grid),
        onSortChanged: _sortTracks,
      ),
    );
  }
}

// Helper class for smart filters
class _SmartFilter {
  final String name;
  final String? slug;
  final IconData icon;

  const _SmartFilter(this.name, this.slug, this.icon);
}

// Track Grid Card Widget
class _TrackGridCard extends StatelessWidget {
  final MusicTrack track;
  final bool isDark;
  final Color cardColor;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const _TrackGridCard({
    required this.track,
    required this.isDark,
    required this.cardColor,
    required this.onTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Art
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    child: track.coverUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: track.coverUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (_, __) => Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.grey,
                                size: 48,
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.grey,
                                size: 48,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.grey,
                              size: 48,
                            ),
                          ),
                  ),
                  // Play button overlay
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1DB954),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Trending badge
                  if (track.isTrending)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department,
                                size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'HOT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artist?.name ?? 'Msanii',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
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

// Track List Tile Widget
class _TrackListTile extends StatelessWidget {
  final MusicTrack track;
  final int index;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onSave;
  final bool isPlaying;

  const _TrackListTile({
    required this.track,
    required this.index,
    required this.isDark,
    required this.onTap,
    required this.onSave,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            child: isPlaying
                ? const _PlayingIndicator()
                : Text(
                    '$index',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 48,
              height: 48,
              child: track.coverUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: track.coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.music_note, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.music_note, color: Colors.grey),
                    ),
            ),
          ),
        ],
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isPlaying
              ? const Color(0xFF1DB954)
              : (isDark ? Colors.white : Colors.black),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Row(
        children: [
          if (track.isTrending) ...[
            const Icon(Icons.local_fire_department,
                size: 12, color: Colors.orange),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              track.artist?.name ?? 'Msanii',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            track.durationFormatted,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          IconButton(
            icon: Icon(
              track.isSaved == true ? Icons.favorite : Icons.favorite_border,
              color: track.isSaved == true ? const Color(0xFF1DB954) : null,
              size: 20,
            ),
            onPressed: onSave,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () => _showTrackOptions(context),
          ),
        ],
      ),
    );
  }

  void _showTrackOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF282828) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Ongeza kwenye Playlist'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Shiriki'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Tazama Msanii'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Pakua'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

// Playing indicator animation
class _PlayingIndicator extends StatefulWidget {
  const _PlayingIndicator();

  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (((_controller.value + delay) % 1.0) * 2 - 1).abs();
            return Container(
              width: 3,
              height: 8 + (value * 8),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }
}

// Recent Track Card
class _RecentTrackCard extends StatelessWidget {
  final MusicTrack track;
  final bool isDark;
  final VoidCallback onTap;

  const _RecentTrackCard({
    required this.track,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album art with shadow
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: track.coverUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: track.coverUrl,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.grey,
                          size: 48,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            Text(
              track.artist?.name ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Artist Circle Widget
class _ArtistCircle extends StatelessWidget {
  final MusicArtistModel artist;
  final bool isDark;
  final VoidCallback onTap;

  const _ArtistCircle({
    required this.artist,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            // Circular image
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: artist.photoUrl != null && artist.photoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: artist.photoUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              artist.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shimmer loading tile
class _ShimmerTrackTile extends StatelessWidget {
  final bool isDark;

  const _ShimmerTrackTile({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final shimmerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: shimmerColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 12,
                width: 100,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Recently Played Bottom Sheet
class _RecentlyPlayedSheet extends StatelessWidget {
  final List<MusicTrack> tracks;
  final Function(MusicTrack) onTrackTap;

  const _RecentlyPlayedSheet({
    required this.tracks,
    required this.onTrackTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF282828),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Historia ya Kusikiliza',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: track.coverUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: track.coverUrl,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  title: Text(
                    track.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    track.artist?.name ?? '',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onTrackTap(track);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Settings Bottom Sheet
class _SettingsSheet extends StatelessWidget {
  final bool isGridView;
  final String sortBy;
  final Function(bool) onViewChanged;
  final Function(String) onSortChanged;

  const _SettingsSheet({
    required this.isGridView,
    required this.sortBy,
    required this.onViewChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF282828),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Mipangilio ya Maktaba',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.grid_view, color: Colors.white),
            title: const Text('Muonekano wa Gridi',
                style: TextStyle(color: Colors.white)),
            trailing: Switch(
              value: isGridView,
              onChanged: (value) {
                onViewChanged(value);
                Navigator.pop(context);
              },
              activeColor: const Color(0xFF1DB954),
            ),
          ),
          const Divider(color: Colors.grey),
          const ListTile(
            title: Text('Panga kwa:', style: TextStyle(color: Colors.grey)),
          ),
          ...[
            ('recent', 'Hivi Karibuni'),
            ('alphabetical', 'A-Z'),
            ('artist', 'Msanii'),
            ('duration', 'Muda'),
          ].map((option) => ListTile(
                title: Text(
                  option.$2,
                  style: TextStyle(
                    color: sortBy == option.$1 ? const Color(0xFF1DB954) : Colors.white,
                  ),
                ),
                trailing: sortBy == option.$1
                    ? const Icon(Icons.check, color: Color(0xFF1DB954))
                    : null,
                onTap: () {
                  onSortChanged(option.$1);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
