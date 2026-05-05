import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/music_models.dart';
import '../../services/music_service.dart';
import '../../services/local_storage_service.dart';
import '../../screens/clips/musicupload_screen.dart';
import '../../screens/music/music_player_sheet.dart';

/// Spotify-style music gallery for profile page
/// Features:
/// - Grid/List layout toggle
/// - Play count and duration overlay
/// - Upload functionality for own profile
/// - Smooth playback integration
class MusicGalleryWidget extends StatefulWidget {
  final int userId;
  final bool isOwnProfile;
  final Function(MusicTrack)? onTrackTap;
  final VoidCallback? onUploadComplete;

  const MusicGalleryWidget({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
    this.onTrackTap,
    this.onUploadComplete,
  });

  @override
  State<MusicGalleryWidget> createState() => _MusicGalleryWidgetState();
}

class _MusicGalleryWidgetState extends State<MusicGalleryWidget> {
  final MusicService _musicService = MusicService();
  final ScrollController _scrollController = ScrollController();

  List<MusicTrack> _tracks = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  int? _currentUserId;

  // Layout mode
  _GalleryLayout _layoutMode = _GalleryLayout.grid;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadTracks();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadCurrentUser() async {
    final storage = await LocalStorageService.getInstance();
    final user = storage.getUser();
    if (mounted && user?.userId != null) {
      setState(() {
        _currentUserId = user!.userId;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTracks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _musicService.getUserTracks(widget.userId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _tracks = result.tracks;
          _hasMore = result.hasMore;
        } else {
          _error = result.message;
        }
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    _currentPage++;
    final result = await _musicService.getUserTracks(widget.userId, page: _currentPage);

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.success) {
          _tracks.addAll(result.tracks);
          _hasMore = result.hasMore;
        }
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMore();
    }
  }

  void _openMusicPlayer(MusicTrack track, int index) {
    if (widget.onTrackTap != null) {
      widget.onTrackTap!(track);
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MusicPlayerSheet(
          track: track,
          currentUserId: _currentUserId ?? widget.userId,
          queue: _tracks,
          startIndex: index,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_currentUserId != null || widget.isOwnProfile || _tracks.isNotEmpty)
          _buildHeader(),

        // Content
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  /// Header matches Me -> Photos/Posts/Video: Container(12,8), Row(count, Spacer(), actions).
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            '${_tracks.length} muziki',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          SegmentedButton<_GalleryLayout>(
            segments: const [
              ButtonSegment(
                value: _GalleryLayout.grid,
                icon: Icon(Icons.grid_view, size: 18),
              ),
              ButtonSegment(
                value: _GalleryLayout.list,
                icon: Icon(Icons.view_list, size: 18),
              ),
            ],
            selected: {_layoutMode},
            onSelectionChanged: (selected) {
              setState(() => _layoutMode = selected.first);
            },
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          if (widget.isOwnProfile) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: _navigateToUploadScreen,
              icon: const Icon(Icons.upload, size: 22),
              iconSize: 22,
              tooltip: 'Pakia Muziki',
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToUploadScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicUploadScreen(
          currentUserId: widget.userId,
          onUploadComplete: () {
            widget.onUploadComplete?.call();
            _loadTracks();
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadTracks,
              child: const Text('Jaribu tena'),
            ),
          ],
        ),
      );
    }

    if (_tracks.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadTracks,
      child: _layoutMode == _GalleryLayout.grid
          ? _buildGridLayout()
          : _buildListLayout(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_note_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Muziki',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isOwnProfile ? 'Hujapakia muziki bado' : 'Hakuna muziki',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          if (widget.isOwnProfile) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToUploadScreen,
              icon: const Icon(Icons.upload),
              label: const Text('Pakia Muziki'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridLayout() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: _tracks.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _tracks.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildGridItem(_tracks[index], index);
      },
    );
  }

  Widget _buildGridItem(MusicTrack track, int index) {
    return GestureDetector(
      onTap: () => _openMusicPlayer(track, index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover art
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: track.coverUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: track.coverUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey.shade800,
                              child: const Icon(Icons.music_note, color: Colors.grey, size: 48),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade800,
                              child: const Icon(Icons.music_note, color: Colors.grey, size: 48),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade800,
                            child: const Icon(Icons.music_note, color: Colors.grey, size: 48),
                          ),
                  ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Play button
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1DB954),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                    ),
                  ),
                  // Duration badge
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        track.durationFormatted,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  // Plays count
                  if (track.playsCount > 0)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.headphones, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              _formatCount(track.playsCount),
                              style: const TextStyle(color: Colors.white, fontSize: 11),
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
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist?.name ?? 'Msanii',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListLayout() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _tracks.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _tracks.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _buildListItem(_tracks[index], index);
      },
    );
  }

  Widget _buildListItem(MusicTrack track, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade900,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openMusicPlayer(track, index),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Track number
              SizedBox(
                width: 28,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
              ),
              // Cover art
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: track.coverUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: track.coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.grey.shade800,
                            child: const Icon(Icons.music_note, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.music_note, color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          track.artist?.name ?? 'Msanii',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                        if (track.playsCount > 0) ...[
                          Text(' • ', style: TextStyle(color: Colors.grey.shade600)),
                          Icon(Icons.headphones, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 2),
                          Text(
                            _formatCount(track.playsCount),
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Duration
              Text(
                track.durationFormatted,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              const SizedBox(width: 8),
              // Play button
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF1DB954),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

enum _GalleryLayout { grid, list }
