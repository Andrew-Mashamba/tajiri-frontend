import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/clip_models.dart' as models;
import '../../services/clip_service.dart';
import '../../services/video_cache_service.dart';
import '../../services/local_storage_service.dart';

class ClipPlayerScreen extends StatefulWidget {
  final List<models.Clip> clips;
  final int initialIndex;

  const ClipPlayerScreen({
    super.key,
    required this.clips,
    this.initialIndex = 0,
  });

  @override
  State<ClipPlayerScreen> createState() => _ClipPlayerScreenState();
}

class _ClipPlayerScreenState extends State<ClipPlayerScreen> {
  late PageController _pageController;
  final ClipService _clipService = ClipService();
  final VideoCacheService _cacheService = VideoCacheService();

  final Map<int, VideoPlayerController> _controllers = {};
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showControls = true;
  bool _isMuted = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Set fullscreen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _loadCurrentUser();
    _initializeCurrentVideo();
    _preloadAdjacentVideos();
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
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

  Future<void> _initializeCurrentVideo() async {
    await _initializeVideo(_currentIndex);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _controllers[_currentIndex]?.play();
    }
  }

  Future<void> _initializeVideo(int index) async {
    if (index < 0 || index >= widget.clips.length) return;
    if (_controllers.containsKey(index)) return;

    final clip = widget.clips[index];
    try {
      final controller = await _cacheService.getControllerForClip(clip);
      if (!controller.value.isInitialized) {
        await controller.initialize();
      }
      controller.setLooping(true);
      controller.setVolume(_isMuted ? 0.0 : 1.0);

      if (mounted) {
        setState(() {
          _controllers[index] = controller;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video at index $index: $e');
    }
  }

  Future<void> _preloadAdjacentVideos() async {
    // Preload next and previous videos
    final indicesToPreload = [
      _currentIndex - 1,
      _currentIndex + 1,
      _currentIndex + 2,
    ];

    for (final index in indicesToPreload) {
      if (index >= 0 && index < widget.clips.length) {
        _initializeVideo(index);
      }
    }
  }

  void _onPageChanged(int index) {
    // Pause current video
    _controllers[_currentIndex]?.pause();

    setState(() {
      _currentIndex = index;
      _isLoading = !_controllers.containsKey(index);
    });

    // Play new video
    if (_controllers.containsKey(index)) {
      _controllers[index]!.setVolume(_isMuted ? 0.0 : 1.0);
      _controllers[index]!.seekTo(Duration.zero);
      _controllers[index]!.play();
    } else {
      _initializeVideo(index).then((_) {
        if (mounted && _currentIndex == index) {
          setState(() {
            _isLoading = false;
          });
          _controllers[index]?.setVolume(_isMuted ? 0.0 : 1.0);
          _controllers[index]?.play();
        }
      });
    }

    // Track view
    _clipService.viewClip(widget.clips[index].id);

    // Preload adjacent videos
    _preloadAdjacentVideos();

    // Cleanup distant videos to save memory
    _cleanupDistantVideos();
  }

  void _cleanupDistantVideos() {
    final keysToRemove = <int>[];
    for (final key in _controllers.keys) {
      if ((key - _currentIndex).abs() > 3) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _controllers[key]?.dispose();
      _controllers.remove(key);
    }
  }

  void _togglePlayPause() {
    final controller = _controllers[_currentIndex];
    if (controller == null) return;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      for (final c in _controllers.values) {
        c.setVolume(_isMuted ? 0.0 : 1.0);
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
            onPageChanged: _onPageChanged,
            itemCount: widget.clips.length,
            itemBuilder: (context, index) => _buildVideoPage(index),
          ),

          // Top bar
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(),
            ),

          // Side actions
          if (_showControls)
            Positioned(
              right: 8,
              bottom: MediaQuery.of(context).size.height * 0.25,
              child: _buildSideActions(),
            ),

          // Bottom info
          if (_showControls)
            Positioned(
              left: 16,
              right: 80,
              bottom: 32,
              child: _buildBottomInfo(),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPage(int index) {
    final clip = widget.clips[index];
    final controller = _controllers[index];

    // Check if content is locked (subscribers-only and user not subscribed)
    final isOwnClip = _currentUserId != null && clip.userId == _currentUserId;
    final isContentLocked = !isOwnClip &&
        clip.privacy == 'subscribers' &&
        !clip.isSubscribedToAuthor;

    return GestureDetector(
      onTap: isContentLocked ? null : _toggleControls,
      onDoubleTap: isContentLocked ? null : () {
        // Like on double tap
        _likeClip(clip);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail as placeholder
          if (clip.thumbnailUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: clip.thumbnailUrl,
              fit: BoxFit.cover,
            ),

          // Video player (only show if not locked)
          if (!isContentLocked && controller != null && controller.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            )
          else if (!isContentLocked && _isLoading && index == _currentIndex)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Subscriber-only overlay
          if (isContentLocked)
            _buildSubscriberOverlay(clip),

          // Play/Pause indicator (only show if not locked)
          if (!isContentLocked && controller != null && !controller.value.isPlaying && index == _currentIndex)
            Center(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the subscriber-only overlay for clips
  Widget _buildSubscriberOverlay(models.Clip clip) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star,
                  size: 56,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Kwa Wasajili Pekee',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Jisajili kwa ${clip.user?.fullName ?? 'msanii huyu'}\nkuona video hii',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => _navigateToSubscribe(clip),
                icon: const Icon(Icons.star, size: 22),
                label: const Text(
                  'Jisajili Sasa',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSubscribe(models.Clip clip) {
    // Navigate to the user's profile to subscribe
    if (clip.user != null) {
      Navigator.pushNamed(
        context,
        '/profile',
        arguments: {'userId': clip.userId},
      );
    }
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black54,
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
            ),
            onPressed: _toggleMute,
            tooltip: _isMuted ? 'Zima sauti' : 'Washa sauti',
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Tafuta',
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideActions() {
    final clip = widget.clips[_currentIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // User avatar
        GestureDetector(
          onTap: () {
            // Navigate to user profile
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: clip.user != null &&
                        clip.user!.avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(clip.user!.avatarUrl)
                    : null,
                backgroundColor: Colors.grey[800],
                child: clip.user == null || clip.user!.avatarUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              Positioned(
                bottom: -8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Like button
        _buildActionButton(
          icon: clip.isLiked == true ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(clip.likesCount),
          color: clip.isLiked == true ? Colors.red : Colors.white,
          onTap: () => _likeClip(clip),
        ),
        const SizedBox(height: 16),

        // Comment button
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          label: _formatCount(clip.commentsCount),
          onTap: () => _showComments(clip),
        ),
        const SizedBox(height: 16),

        // Share button
        _buildActionButton(
          icon: Icons.share,
          label: 'Shiriki',
          onTap: () => _shareClip(clip),
        ),
        const SizedBox(height: 16),

        // Save/Bookmark button
        _buildActionButton(
          icon: clip.isSaved == true ? Icons.bookmark : Icons.bookmark_border,
          label: clip.isSaved == true ? 'Imehifadhiwa' : 'Hifadhi',
          color: clip.isSaved == true ? Colors.amber : Colors.white,
          onTap: () => _saveClip(clip),
        ),
      ],
    );
  }

  /// Minimum touch target 48dp per DESIGN.md
  static const double _minTouchTarget = 48.0;

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: _minTouchTarget,
          height: _minTouchTarget,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInfo() {
    final clip = widget.clips[_currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Username
        Row(
          children: [
            Text(
              '@${clip.user?.displayName ?? 'user'}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Caption
        if (clip.caption?.isNotEmpty == true)
          Text(
            clip.caption!,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

        // Hashtags
        if (clip.hashtags != null && clip.hashtags!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: clip.hashtags!.take(5).map((tag) {
              return GestureDetector(
                onTap: () {
                  // Search for hashtag
                },
                child: Text(
                  '#$tag',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],

        // Music/Sound
        if (clip.music != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.music_note, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  clip.music!.displayTitle,
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],

        // Progress indicator
        const SizedBox(height: 12),
        _buildProgressBar(),
      ],
    );
  }

  Widget _buildProgressBar() {
    final controller = _controllers[_currentIndex];
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox(height: 2);
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final progress = value.duration.inMilliseconds > 0
            ? value.position.inMilliseconds / value.duration.inMilliseconds
            : 0.0;

        return Container(
          height: 2,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      },
    );
  }

  void _likeClip(models.Clip clip) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali ingia kwanza')),
      );
      return;
    }

    final wasLiked = clip.isLiked == true;

    // Optimistic update - just trigger rebuild
    setState(() {});

    // API call
    try {
      if (wasLiked) {
        await _clipService.unlikeClip(clip.id, _currentUserId!);
      } else {
        await _clipService.likeClip(clip.id, _currentUserId!);
      }
      // Refresh state after API call
      if (mounted) setState(() {});
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindwa: ${e.toString()}')),
        );
      }
    }
  }

  void _saveClip(models.Clip clip) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali ingia kwanza')),
      );
      return;
    }

    final wasSaved = clip.isSaved == true;

    // Optimistic update - just trigger rebuild
    setState(() {});

    try {
      if (wasSaved) {
        await _clipService.unsaveClip(clip.id, _currentUserId!);
      } else {
        await _clipService.saveClip(clip.id, _currentUserId!);
      }
      // Refresh state after API call
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindwa: ${e.toString()}')),
        );
      }
    }
  }

  void _showComments(models.Clip clip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCommentsSheet(clip),
    );
  }

  Widget _buildCommentsSheet(models.Clip clip) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Maoni ${clip.commentsCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.grey),
          // Comments list
          Expanded(
            child: Center(
              child: Text(
                'Maoni yatakuja hivi karibuni...',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ),
          // Comment input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(color: Colors.grey[800]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Andika maoni...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                  onPressed: () {
                    // Send comment
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareClip(models.Clip clip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(Icons.link, 'Nakili Link'),
                _buildShareOption(Icons.download, 'Pakua'),
                _buildShareOption(Icons.send, 'WhatsApp'),
                _buildShareOption(Icons.more_horiz, 'Zaidi'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ghairi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label - hivi karibuni')),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
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
