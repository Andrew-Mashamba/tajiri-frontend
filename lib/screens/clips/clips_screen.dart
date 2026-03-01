import 'package:flutter/material.dart' hide Clip;
import 'package:flutter/material.dart' as material show Clip;
import 'package:video_player/video_player.dart';
import '../../models/clip_models.dart';
import '../../services/clip_service.dart';
import '../../services/video_cache_service.dart';
import 'create_clip_screen.dart';

class ClipsScreen extends StatefulWidget {
  final int currentUserId;

  const ClipsScreen({super.key, required this.currentUserId});

  @override
  State<ClipsScreen> createState() => _ClipsScreenState();
}

class _ClipsScreenState extends State<ClipsScreen> {
  final ClipService _clipService = ClipService();
  final VideoCacheService _videoCacheService = VideoCacheService();
  final PageController _pageController = PageController();
  List<Clip> _clips = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _currentIndex = 0;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _loadClips();
  }

  Future<void> _loadClips() async {
    setState(() => _isLoading = true);
    final result = await _clipService.getClips(
      page: _currentPage,
      currentUserId: widget.currentUserId,
      perPage: 20,
    );
    if (result.success) {
      setState(() {
        _clips = result.clips;
        _isLoading = false;
      });
      if (_clips.isNotEmpty) {
        _videoCacheService.preloadForFeed(_clips, 0);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreClips() async {
    final result = await _clipService.getClips(
      page: _currentPage + 1,
      currentUserId: widget.currentUserId,
      perPage: 20,
    );
    if (result.success && result.clips.isNotEmpty) {
      setState(() {
        _clips.addAll(result.clips);
        _currentPage++;
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _videoCacheService.preloadForFeed(_clips, index);
    if (index >= _clips.length - 2) {
      _loadMoreClips();
    }
  }

  void _createClip() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateClipScreen(userId: widget.currentUserId),
      ),
    ).then((_) => _loadClips());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Klipu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _isMuted = !_isMuted),
            tooltip: _isMuted ? 'Zima sauti' : 'Washa sauti',
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
            tooltip: 'Tafuta',
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            onPressed: _createClip,
            tooltip: 'Unda Klipu',
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _clips.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        'Hakuna klipu',
                        style: TextStyle(color: Colors.grey[400], fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _createClip,
                        icon: const Icon(Icons.add),
                        label: const Text('Unda Klipu'),
                      ),
                    ],
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: _clips.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    return ClipItem(
                      clip: _clips[index],
                      isActive: index == _currentIndex,
                      isMuted: _isMuted,
                      currentUserId: widget.currentUserId,
                      onLikeChanged: (isLiked) {
                        setState(() {
                          _clips[index] = Clip(
                            id: _clips[index].id,
                            userId: _clips[index].userId,
                            videoPath: _clips[index].videoPath,
                            thumbnailPath: _clips[index].thumbnailPath,
                            caption: _clips[index].caption,
                            duration: _clips[index].duration,
                            musicId: _clips[index].musicId,
                            musicStart: _clips[index].musicStart,
                            hashtags: _clips[index].hashtags,
                            mentions: _clips[index].mentions,
                            locationName: _clips[index].locationName,
                            latitude: _clips[index].latitude,
                            longitude: _clips[index].longitude,
                            privacy: _clips[index].privacy,
                            allowComments: _clips[index].allowComments,
                            allowDuet: _clips[index].allowDuet,
                            allowStitch: _clips[index].allowStitch,
                            allowDownload: _clips[index].allowDownload,
                            viewsCount: _clips[index].viewsCount,
                            likesCount: _clips[index].likesCount + (isLiked ? 1 : -1),
                            commentsCount: _clips[index].commentsCount,
                            sharesCount: _clips[index].sharesCount,
                            savesCount: _clips[index].savesCount,
                            duetsCount: _clips[index].duetsCount,
                            isFeatured: _clips[index].isFeatured,
                            status: _clips[index].status,
                            originalClipId: _clips[index].originalClipId,
                            clipType: _clips[index].clipType,
                            createdAt: _clips[index].createdAt,
                            user: _clips[index].user,
                            music: _clips[index].music,
                            originalClip: _clips[index].originalClip,
                            isLiked: isLiked,
                            isSaved: _clips[index].isSaved,
                          );
                        });
                      },
                    );
                  },
                ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class ClipItem extends StatefulWidget {
  final Clip clip;
  final bool isActive;
  final bool isMuted;
  final int currentUserId;
  final Function(bool) onLikeChanged;

  const ClipItem({
    super.key,
    required this.clip,
    required this.isActive,
    required this.isMuted,
    required this.currentUserId,
    required this.onLikeChanged,
  });

  @override
  State<ClipItem> createState() => _ClipItemState();
}

class _ClipItemState extends State<ClipItem> {
  final ClipService _clipService = ClipService();
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.clip.videoUrl),
    );
    await _videoController!.initialize();
    _videoController!.setLooping(true);
    _videoController!.setVolume(widget.isMuted ? 0.0 : 1.0);
    setState(() => _isInitialized = true);
    if (widget.isActive) {
      _videoController!.play();
    }
  }

  @override
  void didUpdateWidget(ClipItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _videoController?.play();
      } else {
        _videoController?.pause();
      }
    }
    if (widget.isMuted != oldWidget.isMuted && _videoController != null) {
      _videoController!.setVolume(widget.isMuted ? 0.0 : 1.0);
    }
  }

  void _onDoubleTap() {
    if (widget.clip.isLiked != true) {
      _toggleLike();
    }
    setState(() => _showHeart = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  Future<void> _toggleLike() async {
    final isLiked = widget.clip.isLiked == true;
    if (isLiked) {
      await _clipService.unlikeClip(widget.clip.id, widget.currentUserId);
    } else {
      await _clipService.likeClip(widget.clip.id, widget.currentUserId);
    }
    widget.onLikeChanged(!isLiked);
  }

  Future<void> _toggleSave() async {
    final isSaved = widget.clip.isSaved == true;
    if (isSaved) {
      await _clipService.unsaveClip(widget.clip.id, widget.currentUserId);
    } else {
      await _clipService.saveClip(widget.clip.id, widget.currentUserId);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isSaved ? 'Imeondolewa' : 'Imehifadhiwa')),
    );
  }

  void _shareClip() async {
    await _clipService.shareClip(widget.clip.id, widget.currentUserId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshirikiwa!')),
      );
    }
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(
        clipId: widget.clip.id,
        currentUserId: widget.currentUserId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      onTap: () {
        if (_videoController != null) {
          if (_videoController!.value.isPlaying) {
            _videoController!.pause();
          } else {
            _videoController!.play();
          }
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          if (_isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Double tap heart
          if (_showHeart)
            Center(
              child: Icon(
                Icons.favorite,
                color: Colors.white.withOpacity(0.9),
                size: 100,
              ),
            ),

          // Right side actions
          Positioned(
            right: 12,
            bottom: 100,
            child: Column(
              children: [
                // User avatar
                GestureDetector(
                  onTap: () {
                    // Navigate to user profile
                  },
                  child: Stack(
                    clipBehavior: material.Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: widget.clip.user?.avatarUrl.isNotEmpty == true
                            ? NetworkImage(widget.clip.user!.avatarUrl)
                            : null,
                        child: (widget.clip.user == null ||
                                widget.clip.user!.avatarUrl.isEmpty)
                            ? Text(
                                widget.clip.user != null &&
                                        widget.clip.user!.firstName.isNotEmpty
                                    ? widget.clip.user!.firstName[0]
                                    : (widget.clip.user != null &&
                                            widget.clip.user!.lastName.isNotEmpty
                                        ? widget.clip.user!.lastName[0]
                                        : '?'),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: -6,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.pink,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Like
                _ActionButton(
                  icon: widget.clip.isLiked == true ? Icons.favorite : Icons.favorite_border,
                  label: _formatCount(widget.clip.likesCount),
                  color: widget.clip.isLiked == true ? Colors.red : Colors.white,
                  onTap: _toggleLike,
                ),
                const SizedBox(height: 16),

                // Comment
                _ActionButton(
                  icon: Icons.comment,
                  label: _formatCount(widget.clip.commentsCount),
                  onTap: _showComments,
                ),
                const SizedBox(height: 16),

                // Save
                _ActionButton(
                  icon: widget.clip.isSaved == true ? Icons.bookmark : Icons.bookmark_border,
                  label: _formatCount(widget.clip.savesCount),
                  color: widget.clip.isSaved == true ? Colors.yellow : Colors.white,
                  onTap: _toggleSave,
                ),
                const SizedBox(height: 16),

                // Share
                _ActionButton(
                  icon: Icons.share,
                  label: _formatCount(widget.clip.sharesCount),
                  onTap: _shareClip,
                ),
                const SizedBox(height: 16),

                // Music disc
                if (widget.clip.music != null)
                  GestureDetector(
                    onTap: () {
                      // Navigate to music clips
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 8),
                        image: widget.clip.music!.coverUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(widget.clip.music!.coverUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: widget.clip.music!.coverUrl.isEmpty
                          ? const Icon(Icons.music_note, color: Colors.white, size: 20)
                          : null,
                    ),
                  ),
              ],
            ),
          ),

          // Bottom info
          Positioned(
            left: 12,
            right: 80,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username
                Text(
                  '@${widget.clip.user?.displayName ?? 'mtumiaji'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),

                // Caption
                if (widget.clip.caption != null)
                  Text(
                    widget.clip.caption!,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),

                // Hashtags
                if (widget.clip.hashtags != null && widget.clip.hashtags!.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: widget.clip.hashtags!
                        .take(3)
                        .map((tag) => Text(
                              '#$tag',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 8),

                // Music
                if (widget.clip.music != null)
                  Row(
                    children: [
                      const Icon(Icons.music_note, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.clip.music!.displayTitle,
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
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

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
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

  /// Minimum touch target 48dp per DESIGN.md
  static const double _minTouchTarget = 48.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: _minTouchTarget,
          height: _minTouchTarget,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final int clipId;
  final int currentUserId;

  const _CommentsSheet({required this.clipId, required this.currentUserId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final ClipService _clipService = ClipService();
  final TextEditingController _commentController = TextEditingController();
  List<ClipComment> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final result = await _clipService.getComments(widget.clipId);
    if (result.success) {
      setState(() {
        _comments = result.comments;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;

    final result = await _clipService.addComment(
      widget.clipId,
      widget.currentUserId,
      _commentController.text,
    );
    if (result.success && result.comment != null) {
      setState(() {
        _comments.insert(0, result.comment!);
      });
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Maoni ${_comments.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? const Center(child: Text('Hakuna maoni bado'))
                    : ListView.builder(
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: comment.user?.avatarUrl.isNotEmpty == true
                                  ? NetworkImage(comment.user!.avatarUrl)
                                  : null,
                              child: (comment.user == null ||
                                      comment.user!.avatarUrl.isEmpty)
                                  ? Text(
                                      comment.user != null &&
                                              comment.user!.firstName.isNotEmpty
                                          ? comment.user!.firstName[0]
                                          : (comment.user != null &&
                                                  comment.user!.lastName.isNotEmpty
                                              ? comment.user!.lastName[0]
                                              : '?'),
                                    )
                                  : null,
                            ),
                            title: Text(comment.user?.displayName ?? 'Mtumiaji'),
                            subtitle: Text(comment.content),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    comment.isLiked == true
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 18,
                                    color: comment.isLiked == true ? Colors.red : null,
                                  ),
                                  onPressed: () {
                                    _clipService.likeComment(
                                        widget.clipId, comment.id, widget.currentUserId);
                                  },
                                ),
                                Text('${comment.likesCount}'),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Andika maoni...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
