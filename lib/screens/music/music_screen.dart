import 'package:flutter/material.dart';
import '../../models/music_models.dart';
import '../../services/music_service.dart';
import 'music_player_sheet.dart';

class MusicScreen extends StatefulWidget {
  final int currentUserId;
  final Function(MusicTrack)? onTrackSelected;

  const MusicScreen({
    super.key,
    required this.currentUserId,
    this.onTrackSelected,
  });

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> with SingleTickerProviderStateMixin {
  final MusicService _musicService = MusicService();
  late TabController _tabController;

  List<MusicTrack> _featuredTracks = [];
  List<MusicTrack> _trendingTracks = [];
  List<MusicCategoryModel> _categories = [];
  List<MusicTrack> _savedTracks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  List<MusicTrack> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _musicService.getFeaturedTracks(currentUserId: widget.currentUserId),
      _musicService.getTrendingTracks(currentUserId: widget.currentUserId),
      _musicService.getCategories(),
      _musicService.getSavedTracks(widget.currentUserId),
    ]);

    setState(() {
      _featuredTracks = (results[0] as TracksResult).tracks;
      _trendingTracks = (results[1] as TracksResult).tracks;
      _categories = (results[2] as CategoriesResult).categories;
      _savedTracks = (results[3] as TracksResult).tracks;
      _isLoading = false;
    });
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
    final result = await _musicService.searchTracks(query, currentUserId: widget.currentUserId);
    setState(() {
      _searchResults = result.tracks;
      _isSearching = false;
    });
  }

  void _openTrack(MusicTrack track) {
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
        ),
      );
    }
  }

  Future<void> _toggleSave(MusicTrack track) async {
    if (track.isSaved == true) {
      await _musicService.unsaveTrack(track.id, widget.currentUserId);
      setState(() {
        _savedTracks.removeWhere((t) => t.id == track.id);
      });
    } else {
      await _musicService.saveTrack(track.id, widget.currentUserId);
      setState(() {
        _savedTracks.add(track);
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(track.isSaved == true ? 'Imeondolewa' : 'Imehifadhiwa'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        title: const Text('Muziki', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tafuta muziki...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _searchQuery = '');
                              _search('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _search(value);
                  },
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Bora'),
                  Tab(text: 'Trending'),
                  Tab(text: 'Aina'),
                  Tab(text: 'Zilizohifadhiwa'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: _searchQuery.isNotEmpty
            ? _buildSearchResults()
            : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTrackList(_featuredTracks, 'Hakuna muziki bora'),
                    _buildTrackList(_trendingTracks, 'Hakuna trending'),
                    _buildCategories(),
                    _buildTrackList(_savedTracks, 'Hujahifadhi muziki'),
                  ],
                ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Hakuna matokeo',
              style: const TextStyle(color: Color(0xFF666666), fontSize: 14),
            ),
          ],
        ),
      );
    }
    return _buildTrackList(_searchResults, '');
  }

  Widget _buildTrackList(List<MusicTrack> tracks, String emptyMessage) {
    if (tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return _TrackTile(
            track: track,
            onTap: () => _openTrack(track),
            onSave: () => _toggleSave(track),
          );
        },
      ),
    );
  }

  Widget _buildCategories() {
    if (_categories.isEmpty) {
      return Center(
        child: Text(
          'Hakuna aina',
          style: const TextStyle(color: Color(0xFF666666), fontSize: 14),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _CategoryCard(
          category: category,
          onTap: () => _openCategory(category),
        );
      },
    );
  }

  void _openCategory(MusicCategoryModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CategoryTracksScreen(
          category: category,
          currentUserId: widget.currentUserId,
          onTrackSelected: widget.onTrackSelected,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _TrackTile extends StatelessWidget {
  final MusicTrack track;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const _TrackTile({
    required this.track,
    required this.onTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      minLeadingWidth: 56,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 56,
          height: 56,
          color: Colors.grey[300],
          child: track.coverUrl.isNotEmpty
              ? Image.network(track.coverUrl, fit: BoxFit.cover)
              : const Icon(Icons.music_note, color: Colors.grey),
        ),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              track.artist?.name ?? 'Msanii haijulikani',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            track.durationFormatted,
            style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (track.isTrending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF999999).withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '🔥',
                style: TextStyle(fontSize: 12),
              ),
            ),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              icon: Icon(
                track.isSaved == true ? Icons.bookmark : Icons.bookmark_border,
                color: track.isSaved == true ? const Color(0xFF1A1A1A) : const Color(0xFF666666),
              ),
              onPressed: onSave,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final MusicCategoryModel category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (category.icon != null)
              Text(category.icon!, style: const TextStyle(fontSize: 24)),
            const Spacer(),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _CategoryTracksScreen extends StatefulWidget {
  final MusicCategoryModel category;
  final int currentUserId;
  final Function(MusicTrack)? onTrackSelected;

  const _CategoryTracksScreen({
    required this.category,
    required this.currentUserId,
    this.onTrackSelected,
  });

  @override
  State<_CategoryTracksScreen> createState() => _CategoryTracksScreenState();
}

class _CategoryTracksScreenState extends State<_CategoryTracksScreen> {
  final MusicService _musicService = MusicService();
  List<MusicTrack> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    final result = await _musicService.getTracksByCategory(
      widget.category.id,
      currentUserId: widget.currentUserId,
    );
    setState(() {
      _tracks = result.tracks;
      _isLoading = false;
    });
  }

  void _openTrack(MusicTrack track) {
    if (widget.onTrackSelected != null) {
      widget.onTrackSelected!(track);
      Navigator.pop(context);
      Navigator.pop(context);
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MusicPlayerSheet(
          track: track,
          currentUserId: widget.currentUserId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tracks.isEmpty
              ?               Center(
                  child: Text(
                    'Hakuna muziki katika aina hii',
                    style: const TextStyle(color: Color(0xFF666666), fontSize: 14),
                  ),
                )
              : ListView.builder(
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    final track = _tracks[index];
                    return _TrackTile(
                      track: track,
                      onTap: () => _openTrack(track),
                      onSave: () async {
                        if (track.isSaved == true) {
                          await _musicService.unsaveTrack(track.id, widget.currentUserId);
                        } else {
                          await _musicService.saveTrack(track.id, widget.currentUserId);
                        }
                        _loadTracks();
                      },
                    );
                  },
                ),
    );
  }
}
