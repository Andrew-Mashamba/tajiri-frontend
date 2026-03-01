import 'package:flutter/material.dart';
import '../../models/clip_models.dart' as models;
import '../../services/clip_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/video_cache_service.dart';
import '../../screens/clips/upload_video_screen.dart';
import '../cached_media_image.dart';
import '../video_player_widget.dart';

/// YouTube/TikTok-style video gallery for profile page
/// Features:
/// - Grid layout with thumbnails
/// - View count overlay
/// - Duration badge
/// - Preloading on scroll
/// - Upload functionality
class VideoGalleryWidget extends StatefulWidget {
  final int userId;
  final bool isOwnProfile;
  final Function(models.Clip)? onVideoTap;
  final VoidCallback? onUploadComplete;

  const VideoGalleryWidget({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
    this.onVideoTap,
    this.onUploadComplete,
  });

  @override
  State<VideoGalleryWidget> createState() => _VideoGalleryWidgetState();
}

class _VideoGalleryWidgetState extends State<VideoGalleryWidget> {
  final ClipService _clipService = ClipService();
  final VideoCacheService _videoCacheService = VideoCacheService();
  final ScrollController _scrollController = ScrollController();

  List<models.Clip> _clips = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  // ignore: unused_field - reserved for pagination
  int _currentPage = 1;
  String? _error;
  int? _currentUserId;

  // Layout mode
  _GalleryLayout _layoutMode = _GalleryLayout.grid;

  @override
  void initState() {
    super.initState();
    _videoCacheService.initialize();
    _loadCurrentUser();
    _loadClips();
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

  Future<void> _loadClips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _clipService.getUserClips(widget.userId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _clips = result.clips;
          _hasMore = result.clips.length >= 20;
          // Preload first few videos
          _preloadVideos(0);
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
    final result = await _clipService.getUserClips(widget.userId);

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.success) {
          _clips.addAll(result.clips);
          _hasMore = result.clips.length >= 20;
        }
      });
    }
  }

  void _onScroll() {
    // Load more when near bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMore();
    }

    // Preload videos based on scroll position
    final itemHeight = 180.0;
    final visibleIndex = (_scrollController.position.pixels / itemHeight).floor();
    _preloadVideos(visibleIndex);
  }

  void _preloadVideos(int centerIndex) {
    // Skip if no clips to preload
    if (_clips.isEmpty) return;

    // Preload videos around visible area
    final startIdx = (centerIndex - 2).clamp(0, _clips.length - 1);
    final endIdx = (centerIndex + 6).clamp(0, _clips.length - 1);

    for (var i = startIdx; i <= endIdx; i++) {
      if (i < _clips.length) {
        _videoCacheService.preloadForFeed(_clips, i);
      }
    }
  }

  void _openVideoPlayer(models.Clip clip, int index) {
    if (widget.onVideoTap != null) {
      widget.onVideoTap!(clip);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _FullscreenVideoPlayer(
            clips: _clips,
            initialIndex: index,
            isOwnProfile: widget.isOwnProfile,
            currentUserId: _currentUserId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Layout toggle and upload button
        if (widget.isOwnProfile || _clips.isNotEmpty)
          _buildHeader(),

        // Content
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  /// Header matches Me -> Photos/Posts: Container(12,8), Row(count, Spacer(), actions).
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            '${_clips.length} video',
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
            style: ButtonStyle(
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
              tooltip: 'Pakia Video',
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
        builder: (context) => UploadVideoScreen(
          userId: widget.userId,
          onUploadComplete: () {
            widget.onUploadComplete?.call();
            _loadClips();
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
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadClips,
              child: const Text('Jaribu tena'),
            ),
          ],
        ),
      );
    }

    if (_clips.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadClips,
      child: _layoutMode == _GalleryLayout.grid
          ? _buildGridLayout()
          : _buildListLayout(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Video',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isOwnProfile ? 'Hujapakia video bado' : 'Hakuna video',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (widget.isOwnProfile) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _navigateToUploadScreen,
                icon: const Icon(Icons.upload),
                label: const Text('Pakia Video'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGridLayout() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 9 / 16,
      ),
      itemCount: _clips.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _clips.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildGridItem(_clips[index], index);
      },
    );
  }

  Widget _buildGridItem(models.Clip clip, int index) {
    return GestureDetector(
      onTap: () => _openVideoPlayer(clip, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail
          if (clip.thumbnailUrl.isNotEmpty)
            CachedMediaImage(
              imageUrl: clip.thumbnailUrl,
              fit: BoxFit.cover,
            )
          else
            Container(
              color: Colors.grey.shade900,
              child: const Center(
                child: Icon(Icons.videocam, color: Colors.white54),
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

          // Views count
          Positioned(
            bottom: 8,
            left: 8,
            child: Row(
              children: [
                const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                const SizedBox(width: 2),
                Text(
                  _formatViews(clip.viewsCount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Duration badge
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                _formatDuration(clip.duration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Add to my videos button (for non-owners)
          if (!widget.isOwnProfile && _currentUserId != null)
            Positioned(
              top: 4,
              right: 4,
              child: _buildAddToMyVideosButton(clip),
            ),
        ],
      ),
    );
  }

  Widget _buildAddToMyVideosButton(models.Clip clip) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAddToMyVideosDialog(clip),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_circle_outline,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  void _showAddToMyVideosDialog(models.Clip clip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Video info
            Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: clip.thumbnailUrl.isNotEmpty
                      ? CachedMediaImage(
                          imageUrl: clip.thumbnailUrl,
                          width: 80,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 80,
                          height: 120,
                          color: Colors.grey[800],
                          child: const Icon(Icons.videocam, color: Colors.white54),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clip.caption ?? 'Video',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatViews(clip.viewsCount)} views • ${_formatDuration(clip.duration)}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Add to my videos button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _addToMyVideos(clip),
                icon: const Icon(Icons.add_to_photos),
                label: const Text('Ongeza kwenye Video Zangu'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ghairi'),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Future<void> _addToMyVideos(models.Clip clip) async {
    Navigator.pop(context); // Close the dialog

    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tafadhali ingia kwanza'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Inaongeza video...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    final result = await _clipService.addToMyVideos(clip.id, _currentUserId!);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(result.message ?? 'Imeongezwa kwenye video zako!')),
              ],
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Angalia',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to own profile videos tab
              },
            ),
          ),
        );
      } else if (result.alreadyAdded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(result.message ?? 'Video hii tayari ipo kwenye mkusanyiko wako')),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(result.message ?? 'Imeshindwa kuongeza video')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildListLayout() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _clips.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _clips.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _buildListItem(_clips[index], index);
      },
    );
  }

  Widget _buildListItem(models.Clip clip, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openVideoPlayer(clip, index),
        child: Row(
          children: [
            // Thumbnail
            SizedBox(
              width: 120,
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (clip.thumbnailUrl.isNotEmpty)
                    CachedMediaImage(
                      imageUrl: clip.thumbnailUrl,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: Colors.grey.shade900,
                      child: const Icon(Icons.videocam, color: Colors.white54),
                    ),
                  // Duration
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        _formatDuration(clip.duration),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (clip.caption != null && clip.caption!.isNotEmpty)
                      Text(
                        clip.caption!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Text(
                        'Video #${clip.id}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.visibility, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatViews(clip.viewsCount)} views',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.favorite, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${clip.likesCount}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    // Add to my videos button (for non-owners)
                    if (!widget.isOwnProfile && _currentUserId != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddToMyVideosDialog(clip),
                          icon: const Icon(Icons.add_to_photos, size: 16),
                          label: const Text('Ongeza kwenye Video Zangu'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

enum _GalleryLayout { grid, list }

/// Fullscreen video player with vertical swipe navigation
class _FullscreenVideoPlayer extends StatefulWidget {
  final List<models.Clip> clips;
  final int initialIndex;
  final bool isOwnProfile;
  final int? currentUserId;

  const _FullscreenVideoPlayer({
    required this.clips,
    required this.initialIndex,
    this.isOwnProfile = false,
    this.currentUserId,
  });

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  late PageController _pageController;
  late int _currentIndex;
  final ClipService _clipService = ClipService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video PageView
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.clips.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final clip = widget.clips[index];
              return _buildVideoPage(clip, index == _currentIndex);
            },
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ),
          // Page indicator
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentIndex + 1}/${widget.clips.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPage(models.Clip clip, bool isActive) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player
        Center(
          child: VideoPlayerWidget(
            videoUrl: clip.videoUrl,
            thumbnailUrl: clip.thumbnailUrl,
            autoPlayOnVisible: isActive,
            looping: true,
            aspectRatio: 9 / 16,
            muted: false,
          ),
        ),
        // Overlay info
        Positioned(
          bottom: 80,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info
              if (clip.user != null)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: clip.user!.avatarUrl.isNotEmpty
                          ? NetworkImage(clip.user!.avatarUrl)
                          : null,
                      child: clip.user!.avatarUrl.isEmpty
                          ? Text(clip.user!.fullName[0])
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        clip.user!.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              // Caption
              if (clip.caption != null && clip.caption!.isNotEmpty)
                Text(
                  clip.caption!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              // Music info
              if (clip.music != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        clip.music!.displayTitle,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        // Action buttons (right side)
        Positioned(
          right: 8,
          bottom: 100,
          child: Column(
            children: [
              _ActionButton(
                icon: clip.isLiked == true ? Icons.favorite : Icons.favorite_border,
                label: '${clip.likesCount}',
                color: clip.isLiked == true ? Colors.red : Colors.white,
                onTap: () {
                  // TODO: Implement like
                },
              ),
              const SizedBox(height: 16),
              _ActionButton(
                icon: Icons.comment,
                label: '${clip.commentsCount}',
                onTap: () {
                  // TODO: Show comments
                },
              ),
              const SizedBox(height: 16),
              _ActionButton(
                icon: clip.isSaved == true ? Icons.bookmark : Icons.bookmark_border,
                label: 'Hifadhi',
                onTap: () {
                  // TODO: Implement save
                },
              ),
              const SizedBox(height: 16),
              _ActionButton(
                icon: Icons.share,
                label: 'Shiriki',
                onTap: () {
                  // TODO: Implement share
                },
              ),
              // Add to my videos button (for non-owners)
              if (!widget.isOwnProfile && widget.currentUserId != null) ...[
                const SizedBox(height: 16),
                _ActionButton(
                  icon: Icons.add_to_photos,
                  label: 'Ongeza',
                  onTap: () => _addToMyVideos(clip),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addToMyVideos(models.Clip clip) async {
    if (widget.currentUserId == null) return;

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Inaongeza video...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    final result = await _clipService.addToMyVideos(clip.id, widget.currentUserId!);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(result.message ?? 'Imeongezwa kwenye video zako!')),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result.alreadyAdded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(result.message ?? 'Video hii tayari ipo kwenye mkusanyiko wako')),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(result.message ?? 'Imeshindwa kuongeza video')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
