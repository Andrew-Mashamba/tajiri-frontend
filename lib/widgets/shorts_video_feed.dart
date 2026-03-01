import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/post_models.dart';
import 'user_avatar.dart';

/// TikTok/Reels/Shorts style vertical video feed
/// Fullscreen, one video at a time, swipe up/down to navigate
class ShortsVideoFeed extends StatefulWidget {
  final List<Post> posts;
  final int initialIndex;
  final int currentUserId;
  final Function(Post)? onLike;
  final Function(Post, ReactionType)? onReaction;
  final Function(Post)? onComment;
  final Function(Post)? onShare;
  final Function(Post)? onSave;
  final Function(Post)? onUserTap;
  final Function(Post, int watchTime, double percentage)? onViewComplete;
  final VoidCallback? onLoadMore;
  final bool isLoading;
  /// When false, back button is hidden (e.g. when used as Feed tab).
  final bool showBackButton;

  const ShortsVideoFeed({
    super.key,
    required this.posts,
    this.initialIndex = 0,
    required this.currentUserId,
    this.onLike,
    this.onReaction,
    this.onComment,
    this.onShare,
    this.onSave,
    this.onUserTap,
    this.onViewComplete,
    this.onLoadMore,
    this.isLoading = false,
    this.showBackButton = true,
  });

  @override
  State<ShortsVideoFeed> createState() => _ShortsVideoFeedState();
}

class _ShortsVideoFeedState extends State<ShortsVideoFeed> {
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, DateTime> _viewStartTimes = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _preloadVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _preloadVideos() {
    // Preload current and next 2 videos
    for (int i = _currentIndex; i < _currentIndex + 3 && i < widget.posts.length; i++) {
      _initializeVideo(i);
    }
  }

  Future<void> _initializeVideo(int index) async {
    if (_videoControllers.containsKey(index)) return;
    if (index >= widget.posts.length) return;

    final post = widget.posts[index];
    final videoMedia = post.primaryVideo;
    if (videoMedia == null) return;

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoMedia.fileUrl),
      );
      _videoControllers[index] = controller;
      await controller.initialize();
      controller.setLooping(true);

      if (index == _currentIndex && mounted) {
        controller.play();
        _viewStartTimes[index] = DateTime.now();
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing video at index $index: $e');
    }
  }

  void _onPageChanged(int index) {
    // Report view completion for previous video
    _reportViewComplete(_currentIndex);

    // Pause previous video
    _videoControllers[_currentIndex]?.pause();

    setState(() {
      _currentIndex = index;
    });

    // Play current video
    if (_videoControllers.containsKey(index)) {
      _videoControllers[index]?.play();
      _viewStartTimes[index] = DateTime.now();
    } else {
      _initializeVideo(index);
    }

    // Preload next videos
    for (int i = index + 1; i < index + 3 && i < widget.posts.length; i++) {
      _initializeVideo(i);
    }

    // Dispose old videos to save memory
    final keysToRemove = _videoControllers.keys
        .where((key) => (key - index).abs() > 2)
        .toList();
    for (final key in keysToRemove) {
      _videoControllers[key]?.dispose();
      _videoControllers.remove(key);
    }

    // Load more when near end
    if (index >= widget.posts.length - 3 && !widget.isLoading) {
      widget.onLoadMore?.call();
    }
  }

  void _reportViewComplete(int index) {
    if (!_viewStartTimes.containsKey(index)) return;

    final startTime = _viewStartTimes[index]!;
    final watchTime = DateTime.now().difference(startTime).inSeconds;
    final post = widget.posts[index];
    final totalDuration = post.videoDuration;
    final percentage = totalDuration > 0 ? (watchTime / totalDuration * 100).clamp(0.0, 100.0) : 0.0;

    widget.onViewComplete?.call(post, watchTime, percentage);
    _viewStartTimes.remove(index);
  }

  void _togglePlayPause() {
    final controller = _videoControllers[_currentIndex];
    if (controller == null) return;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
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
            itemCount: widget.posts.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return _buildVideoPage(widget.posts[index], index);
            },
          ),
          // Top gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Back button (min 48dp touch target; hidden when embedded as tab)
          if (widget.showBackButton)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
              ),
            ),
          // Loading indicator
          if (widget.isLoading)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPage(Post post, int index) {
    final controller = _videoControllers[index];
    final isCurrentPage = index == _currentIndex;

    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTap: () => widget.onLike?.call(post),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video or thumbnail
          if (controller != null && controller.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            )
          else if (post.thumbnailUrl != null)
            Image.network(
              post.thumbnailUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Play/Pause overlay
          if (controller != null && !controller.value.isPlaying && isCurrentPage)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),

          // Bottom gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // User info and caption
          Positioned(
            left: 16,
            right: 80,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // User info
                GestureDetector(
                  onTap: () => widget.onUserTap?.call(post),
                  child: Row(
                    children: [
                      UserAvatar(
                        photoUrl: post.user?.profilePhotoUrl,
                        name: post.user?.fullName,
                        radius: 18,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          '@${post.user?.username ?? post.user?.fullName ?? 'unknown'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Fuata',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Caption
                if (post.content != null && post.content!.isNotEmpty)
                  Text(
                    post.content!,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                // Hashtags
                if (post.hashtags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: post.hashtags.take(3).map((tag) {
                      return Text(
                        '#${tag.name}',
                        style: TextStyle(
                          color: Colors.blue.shade300,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          // Right side action buttons
          Positioned(
            right: 12,
            bottom: MediaQuery.of(context).padding.bottom + 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Like
                _buildActionButton(
                  icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                  label: _formatCount(post.likesCount),
                  color: post.isLiked ? Colors.red : Colors.white,
                  onTap: () => widget.onLike?.call(post),
                ),
                const SizedBox(height: 20),
                // Comment
                _buildActionButton(
                  icon: Icons.comment,
                  label: _formatCount(post.commentsCount),
                  color: Colors.white,
                  onTap: () => widget.onComment?.call(post),
                ),
                const SizedBox(height: 20),
                // Save
                _buildActionButton(
                  icon: post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  label: _formatCount(post.savesCount),
                  color: post.isSaved ? Colors.orange : Colors.white,
                  onTap: () => widget.onSave?.call(post),
                ),
                const SizedBox(height: 20),
                // Share
                _buildActionButton(
                  icon: Icons.share,
                  label: _formatCount(post.sharesCount),
                  color: Colors.white,
                  onTap: () => widget.onShare?.call(post),
                ),
              ],
            ),
          ),

          // Progress bar at bottom
          if (controller != null && controller.value.isInitialized)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Action button with min 48x48dp touch target (DOCS/DESIGN.md).
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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
