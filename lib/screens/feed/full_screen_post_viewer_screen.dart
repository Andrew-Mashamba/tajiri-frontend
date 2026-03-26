import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../models/post_models.dart';
import '../../models/poll_models.dart';
import '../../widgets/share_post_sheet.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/video_player_widget.dart';
import '../../widgets/cached_media_image.dart';
import '../../widgets/audio_player_widget.dart';
import 'comment_bottom_sheet.dart';
import 'edit_post_screen.dart';
import '../../services/post_service.dart';
import '../../services/poll_service.dart';
import '../../services/event_tracking_service.dart';
import '../../l10n/app_strings_scope.dart';

/// Full-screen TikTok-style post viewer: one post per viewport, vertical swipe, snap.
/// Media fills screen by aspect ratio with black letterboxing; overlay UI like TikTok.
class FullScreenPostViewerScreen extends StatefulWidget {
  final List<Post> posts;
  final int initialIndex;
  final int currentUserId;

  const FullScreenPostViewerScreen({
    super.key,
    required this.posts,
    this.initialIndex = 0,
    required this.currentUserId,
  });

  @override
  State<FullScreenPostViewerScreen> createState() =>
      _FullScreenPostViewerScreenState();
}

class _FullScreenPostViewerScreenState extends State<FullScreenPostViewerScreen> {
  late PageController _pageController;
  final PostService _postService = PostService();
  late List<Post> _posts;
  int? _likingPostId;
  int? _savingPostId;

  DateTime? _currentPostEnteredAt;
  int? _currentPostId;
  int? _currentCreatorId;

  int _postsViewed = 0;
  bool _autoPlayEnabled = false;
  Timer? _countdownTimer;
  int _countdownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _posts = List<Post>.from(widget.posts);
    _pageController = PageController(initialPage: widget.initialIndex.clamp(0, _posts.length - 1));

    // Track initial post view
    if (_posts.isNotEmpty) {
      final initialIndex = widget.initialIndex.clamp(0, _posts.length - 1);
      final initialPost = _posts[initialIndex];
      _currentPostId = initialPost.id;
      _currentCreatorId = initialPost.userId;
      _currentPostEnteredAt = DateTime.now();
      EventTrackingService.getInstance().then((tracker) {
        tracker.trackEvent(
          eventType: 'view',
          postId: initialPost.id,
          creatorId: initialPost.userId,
        );
      });
    }
  }

  @override
  void dispose() {
    _emitDwellForCurrentPost();
    _countdownTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _emitDwellForCurrentPost() {
    if (_currentPostEnteredAt != null && _currentPostId != null) {
      final dwellMs = DateTime.now().difference(_currentPostEnteredAt!).inMilliseconds;
      if (dwellMs > 1000) {
        EventTrackingService.getInstance().then((tracker) {
          tracker.trackEvent(
            eventType: 'dwell',
            postId: _currentPostId!,
            creatorId: _currentCreatorId ?? 0,
            durationMs: dwellMs,
          );
        });
      }
    }
  }

  void _startAutoPlayCountdown() {
    _countdownTimer?.cancel();
    if (!_autoPlayEnabled) return;
    setState(() => _countdownSeconds = 3);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _countdownSeconds--);
      if (_countdownSeconds <= 0) {
        timer.cancel();
        _autoAdvance();
      }
    });
  }

  void _autoAdvance() {
    final currentPage = _pageController.page?.round() ?? 0;
    if (currentPage < _posts.length - 1) {
      _pageController.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  static String _networkErrorMessage(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('socket') || s.contains('connection') || s.contains('network')) {
      return 'No connection. Check your network and try again.';
    }
    if (s.contains('timeout') || s.contains('timed out')) {
      return 'Request took too long. Try again.';
    }
    return 'Something went wrong. Try again.';
  }

  void _onLike(Post post) async {
    if (_likingPostId != null) return;
    setState(() => _likingPostId = post.id);
    try {
      final result = post.isLiked
          ? await _postService.unlikePost(post.id, widget.currentUserId)
          : await _postService.likePost(post.id, widget.currentUserId);
      if (!mounted) return;
      setState(() => _likingPostId = null);
      if (result.success) {
        setState(() {
          final i = _posts.indexWhere((p) => p.id == post.id);
          if (i >= 0) {
            _posts[i] = post.copyWith(
              isLiked: !post.isLiked,
              likesCount: result.likesCount ?? post.likesCount,
            );
          }
        });
      } else {
        _showErrorSnackBar(
          _networkErrorMessage(Exception('like failed')),
          retry: () => _onLike(post),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _likingPostId = null);
      _showErrorSnackBar(_networkErrorMessage(e), retry: () => _onLike(post));
    }
  }

  void _showErrorSnackBar(String message, {VoidCallback? retry}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        action: retry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Theme.of(context).colorScheme.primary,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  retry();
                },
              )
            : null,
      ),
    );
  }

  void _onComment(Post post) {
    CommentBottomSheet.show(
      context,
      postId: post.id,
      currentUserId: widget.currentUserId,
      initialPost: post,
      onCommentsCountUpdated: (newCount) {
        if (!mounted) return;
        setState(() {
          final i = _posts.indexWhere((p) => p.id == post.id);
          if (i >= 0) {
            _posts[i] = post.copyWith(commentsCount: newCount);
          }
        });
      },
    );
  }

  void _onShare(Post post) {
    showSharePostBottomSheet(
      context,
      post: post,
      userId: widget.currentUserId,
      postService: _postService,
    );
  }

  void _onSave(Post post) async {
    if (_savingPostId != null) return;
    setState(() => _savingPostId = post.id);
    try {
      final result = post.isSaved
          ? await _postService.unsavePost(post.id, widget.currentUserId)
          : await _postService.savePost(post.id, widget.currentUserId);
      if (!mounted) return;
      setState(() => _savingPostId = null);
      if (result.success) {
        setState(() {
          final i = _posts.indexWhere((p) => p.id == post.id);
          if (i >= 0) {
            _posts[i] = post.copyWith(isSaved: result.isSaved);
          }
        });
      } else {
        final msg = result.message ?? _networkErrorMessage(Exception('save failed'));
        _showErrorSnackBar(msg, retry: () => _onSave(post));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingPostId = null);
      _showErrorSnackBar(_networkErrorMessage(e), retry: () => _onSave(post));
    }
  }

  void _onUserTap(Post post) {
    Navigator.pushNamed(context, '/profile/${post.userId}');
  }

  void _onMenuTap(Post post) async {
    final s = AppStringsScope.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (post.userId == widget.currentUserId)
              ListTile(
                leading: HeroIcon(HeroIcons.pencilSquare, style: HeroIconStyle.outline, size: 24, color: const Color(0xFF1A1A1A)),
                title: Text(s?.editPost ?? 'Edit post'),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
            ListTile(
              leading: HeroIcon(HeroIcons.share, style: HeroIconStyle.outline, size: 24, color: const Color(0xFF1A1A1A)),
              title: Text(s?.share ?? 'Share'),
              onTap: () => Navigator.pop(ctx, 'share'),
            ),
            if (post.userId == widget.currentUserId)
              ListTile(
                leading: HeroIcon(HeroIcons.trash, style: HeroIconStyle.outline, size: 24, color: const Color(0xFF1A1A1A)),
                title: Text(s?.deletePost ?? 'Delete post'),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') {
      final updated = await Navigator.push<Post>(
        context,
        MaterialPageRoute(
          builder: (_) => EditPostScreen(post: post),
        ),
      );
      if (updated != null) {
        setState(() {
          final i = _posts.indexWhere((p) => p.id == post.id);
          if (i >= 0) _posts[i] = updated;
        });
      }
    } else if (action == 'share') {
      _onShare(post);
    } else if (action == 'delete') {
      try {
        final result = await _postService.deletePost(post.id);
        if (!mounted) return;
        if (result.success) {
          setState(() => _posts.removeWhere((p) => p.id == post.id));
          if (_posts.isEmpty) Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Post deleted'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.grey.shade800,
            ),
          );
        } else {
          _showErrorSnackBar('Could not delete post. Try again.');
        }
      } catch (e) {
        if (!mounted) return;
        _showErrorSnackBar(_networkErrorMessage(e));
      }
    }
  }

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_posts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: HeroIcon(HeroIcons.xMark, style: HeroIconStyle.outline, size: 24, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('No posts', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            pageSnapping: true,
            physics: const BouncingScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            onPageChanged: (index) {
              _emitDwellForCurrentPost();
              final post = _posts[index];
              _currentPostId = post.id;
              _currentCreatorId = post.userId;
              _currentPostEnteredAt = DateTime.now();
              EventTrackingService.getInstance().then((tracker) {
                tracker.trackEvent(
                  eventType: 'view',
                  postId: post.id,
                  creatorId: post.userId,
                );
              });
              _postsViewed++;
              if (_postsViewed >= 3 && !_autoPlayEnabled) {
                _autoPlayEnabled = true;
              }
              if (_autoPlayEnabled) {
                _startAutoPlayCountdown();
              }
            },
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              final post = _posts[index];
              return RepaintBoundary(
                key: ValueKey('fullscreen_post_${post.id}'),
                child: _FullScreenPostPage(
                  key: ValueKey('fullscreen_page_${post.id}'),
                  post: post,
                  currentUserId: widget.currentUserId,
                  likingPostId: _likingPostId,
                  savingPostId: _savingPostId,
                  onLike: () => _onLike(post),
                  onComment: () => _onComment(post),
                  onShare: () => _onShare(post),
                  onSave: () => _onSave(post),
                  onUserTap: () => _onUserTap(post),
                  onMenuTap: () => _onMenuTap(post),
                  formatCount: _formatCount,
                ),
              );
            },
          ),
          // Autoplay "Up Next" countdown overlay
          if (_countdownSeconds > 0)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xCC1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Up Next in $_countdownSeconds...',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          // Global close button (top-left) with tap effect
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(24),
                    splashColor: Colors.white24,
                    highlightColor: Colors.white12,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: HeroIcon(HeroIcons.xMark, style: HeroIconStyle.outline, size: 26, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single full-screen post page: media fit to screen with black letterboxing, TikTok-style overlays.
class _FullScreenPostPage extends StatelessWidget {
  final Post post;
  final int currentUserId;
  final int? likingPostId;
  final int? savingPostId;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onUserTap;
  final VoidCallback onMenuTap;
  final String Function(int) formatCount;

  const _FullScreenPostPage({
    super.key,
    required this.post,
    required this.currentUserId,
    this.likingPostId,
    this.savingPostId,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onSave,
    required this.onUserTap,
    required this.onMenuTap,
    required this.formatCount,
  });

  double _mediaAspectRatio(PostMedia? media) {
    if (media == null) return 9 / 16;
    if (media.width != null && media.height != null && media.height! > 0) {
      return media.width! / media.height!;
    }
    return 9 / 16;
  }

  /// Text-only / colored text: full-screen frame like one "image" (no card).
  Widget _buildTextOnlyContent(Post post) {
    Color bgColor = Colors.black;
    if (post.backgroundColor != null) {
      try {
        final s = post.backgroundColor!.replaceAll('#', '');
        bgColor = Color(int.parse('FF$s', radix: 16));
      } catch (_) {}
    } else {
      bgColor = const Color(0xFF1A1A2E);
    }
    final textColor = bgColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
    final content = post.content ?? '';
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: bgColor,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Text(
              content.isEmpty ? '' : content,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: content.length < 80 ? 26 : (content.length < 200 ? 20 : 16),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Audio: full-screen cover image with audio player overlaid at bottom.
  Widget _buildAudioContent(BuildContext context, Post post, int cacheSize) {
    String? audioUrl = post.audioUrl;
    int? duration = post.audioDuration;
    if (audioUrl == null || audioUrl.isEmpty) {
      final m = post.media.where((e) => e.mediaType == MediaType.audio).firstOrNull;
      if (m != null) {
        audioUrl = m.fileUrl;
        duration = m.duration;
      }
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen cover / album art
        Positioned.fill(
          child: post.coverImageUrl != null && post.coverImageUrl!.isNotEmpty
              ? CachedMediaImage(
                  imageUrl: post.coverImageUrl,
                  fit: BoxFit.cover,
                  cacheWidth: cacheSize,
                  cacheHeight: cacheSize,
                  errorWidget: Container(
                    color: const Color(0xFF0D0D12),
                    child: Center(
                      child: HeroIcon(HeroIcons.musicalNote, style: HeroIconStyle.outline, size: 120, color: Colors.white24),
                    ),
                  ),
                )
              : Container(
                  color: const Color(0xFF0D0D12),
                  child: Center(
                    child: HeroIcon(HeroIcons.musicalNote, style: HeroIconStyle.outline, size: 120, color: Colors.white24),
                  ),
                ),
        ),
        // Dark gradient overlay for readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54, Colors.black87],
            ),
          ),
        ),
        // Audio player card at bottom
        Positioned(
          left: 16,
          right: 16,
          bottom: 100,
          child: Material(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: audioUrl != null && audioUrl.isNotEmpty
                  ? AudioPlayerWidget(
                      audioUrl: audioUrl,
                      duration: duration,
                      title: post.postType == PostType.audioText ? 'Sauti + Maandishi' : 'Sauti',
                    )
                  : const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Sauti haipatikani', style: TextStyle(color: Colors.white70)),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// Max decode size for full-screen images (smooth scroll, avoid over-decode).
  static int _cacheSize(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final w = (size.width * dpr).round().clamp(400, 1080);
    final h = (size.height * dpr).round().clamp(400, 1080);
    return w > h ? w : h;
  }

  @override
  Widget build(BuildContext context) {
    final hasVisualMedia = post.hasVideo || post.hasImage;
    final primaryVideo = post.primaryVideo;
    final primaryImage = post.primaryImage;
    final primaryMedia = primaryVideo ?? primaryImage;
    final aspectRatio = _mediaAspectRatio(primaryMedia);
    final cacheSize = _cacheSize(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1) Black background + media (aspect-fit, black fill where media doesn't cover)
        Container(color: Colors.black),
        if (hasVisualMedia && primaryMedia != null)
          Center(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: primaryVideo != null
                  ? VideoPlayerWidget(
                      videoUrl: primaryVideo.fileUrl,
                      thumbnailUrl: primaryVideo.thumbnailUrl,
                      aspectRatio: aspectRatio,
                      showControls: true,
                      showBufferIndicator: true,
                    )
                  : CachedMediaImage(
                      imageUrl: primaryImage!.fileUrl,
                      fit: BoxFit.contain,
                      cacheWidth: cacheSize,
                      cacheHeight: cacheSize,
                      errorWidget: Container(
                        color: Colors.black,
                        child: const Center(
                          child: HeroIcon(HeroIcons.photo, style: HeroIconStyle.outline, size: 48, color: Colors.white54),
                        ),
                      ),
                    ),
            ),
          )
        else if (post.isAudioPost)
          _buildAudioContent(context, post, cacheSize)
        else if (post.postType == PostType.poll && post.pollId != null)
          _FullScreenPollContent(
            pollId: post.pollId!,
            currentUserId: currentUserId,
          )
        else
          // Text-only / colored text: full-screen frame (treat as one "image")
          _buildTextOnlyContent(post),

        // 2) TikTok-style right side: avatar, like, comment, share, save
        Positioned(
          right: 12,
          bottom: 120,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile avatar (tap → profile) with ripple
                _TapWrap(
                onTap: onUserTap,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: UserAvatar(
                    photoUrl: post.user?.profilePhotoUrl,
                    name: post.user?.fullName,
                    radius: 24,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _ActionItem(
                icon: HeroIcon(
                  HeroIcons.heart,
                  style: post.isLiked ? HeroIconStyle.solid : HeroIconStyle.outline,
                  size: 28,
                  color: post.isLiked ? Colors.red : Colors.white,
                ),
                label: formatCount(post.likesCount),
                onTap: onLike,
                isLoading: likingPostId == post.id,
              ),
              const SizedBox(height: 16),
              _ActionItem(
                icon: HeroIcon(HeroIcons.chatBubbleLeft, style: HeroIconStyle.outline, size: 28, color: Colors.white),
                label: formatCount(post.commentsCount),
                onTap: onComment,
              ),
              const SizedBox(height: 16),
              _ActionItem(
                icon: HeroIcon(HeroIcons.paperAirplane, style: HeroIconStyle.outline, size: 28, color: Colors.white),
                label: formatCount(post.sharesCount),
                onTap: onShare,
              ),
              const SizedBox(height: 16),
              _ActionItem(
                icon: HeroIcon(
                  HeroIcons.bookmark,
                  style: post.isSaved ? HeroIconStyle.solid : HeroIconStyle.outline,
                  size: 28,
                  color: post.isSaved ? Colors.amber : Colors.white,
                ),
                label: formatCount(post.savesCount),
                onTap: onSave,
                isLoading: savingPostId == post.id,
              ),
              ],
            ),
          ),
        ),

        // 3) Menu (three dots) top-right with tap effect
        Positioned(
          top: 0,
          right: 12,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _TapWrap(
            onTap: onMenuTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(24),
              ),
              child: HeroIcon(HeroIcons.ellipsisVertical, style: HeroIconStyle.outline, size: 26, color: Colors.white),
            ),
          ),
            ),
          ),
        ),

        // 4) Bottom-left: username + caption (TikTok-style)
        Positioned(
          left: 12,
          right: 80,
          bottom: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _TapWrap(
                onTap: onUserTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '@${post.user?.username ?? 'user${post.userId}'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      shadows: [
                        Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4),
                        Shadow(color: Colors.black87, offset: Offset(0, 1), blurRadius: 8),
                      ],
                    ),
                  ),
                ),
              ),
              if (post.content != null && post.content!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  post.content!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.3,
                    shadows: [
                      Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4),
                      Shadow(color: Colors.black87, offset: Offset(0, 1), blurRadius: 8),
                    ],
                  ),
                ),
              ],
              if (post.hasMusic && post.musicTrack != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    HeroIcon(HeroIcons.musicalNote, style: HeroIconStyle.outline, size: 16, color: Colors.white70),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        post.musicTrack!.displayName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          shadows: [
                            Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Wraps a child with Material + InkWell for ripple and highlight on tap.
class _TapWrap extends StatelessWidget {
  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final Widget child;

  const _TapWrap({
    required this.onTap,
    required this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: Colors.white24,
        highlightColor: Colors.white12,
        child: child,
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return _TapWrap(
      onTap: isLoading ? () {} : onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      ),
                    )
                  : Center(child: icon),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen creative poll: dark gradient, big question, option chips.
class _FullScreenPollContent extends StatefulWidget {
  final int pollId;
  final int currentUserId;

  const _FullScreenPollContent({
    required this.pollId,
    required this.currentUserId,
  });

  @override
  State<_FullScreenPollContent> createState() => _FullScreenPollContentState();
}

class _FullScreenPollContentState extends State<_FullScreenPollContent> {
  final PollService _pollService = PollService();
  Poll? _poll;
  bool _loading = true;
  bool _voting = false;
  int? _pendingOptionId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _pollService.getPoll(
      '${widget.pollId}',
      currentUserId: widget.currentUserId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _poll = result.poll;
      _error = result.success ? null : (result.message ?? 'Imeshindwa kupakia kura');
    });
  }

  Future<void> _vote(int optionId) async {
    if (_poll == null) return;
    setState(() {
      _voting = true;
      _pendingOptionId = optionId;
    });
    final result = await _pollService.vote(
      widget.pollId,
      widget.currentUserId,
      [optionId],
    );
    if (!mounted) return;
    setState(() {
      _voting = false;
      _pendingOptionId = null;
      if (result.success) _poll = result.poll;
    });
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Umepiga kura. Asante!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindikana kupiga kura')),
      );
    }
  }

  Future<void> _unvote() async {
    if (_poll == null || _poll!.userVotedOptionId == null) return;
    setState(() => _voting = true);
    final result = await _pollService.unvote(widget.pollId, widget.currentUserId);
    if (!mounted) return;
    setState(() {
      _voting = false;
      if (result.success) _poll = result.poll;
    });
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kura yako imeondolewa')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: const Color(0xFF0D0D12),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white70),
        ),
      );
    }
    if (_error != null || _poll == null) {
      return Container(
        color: const Color(0xFF0D0D12),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HeroIcon(HeroIcons.chartBar, style: HeroIconStyle.outline, size: 48, color: Colors.white38),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Kura haipatikani',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _load,
                  icon: HeroIcon(HeroIcons.arrowPath, style: HeroIconStyle.outline, size: 20, color: Colors.white),
                  label: const Text('Jaribu tena', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final totalVotes = _poll!.totalVotes;
    final hasVoted = _poll!.userVotedOptionId != null;
    final isExpired = _poll!.hasEnded;
    final canVote = !isExpired && _poll!.status == 'active' && !_voting;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF0D0D12), Color(0xFF16213E)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: HeroIcon(HeroIcons.chartBar, style: HeroIconStyle.outline, size: 28, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _poll!.question,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              if (_poll!.description != null && _poll!.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _poll!.description!,
                  style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 28),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(_poll!.options.length, (i) {
                      final option = _poll!.options[i];
                      final pct = totalVotes > 0 ? (option.votesCount / totalVotes) : 0.0;
                      final voted = option.id == _poll!.userVotedOptionId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: canVote ? () => _vote(option.id) : null,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: voted ? Colors.amber : Colors.white24,
                                  width: voted ? 2 : 1,
                                ),
                                color: voted ? Colors.amber.withValues(alpha: 0.15) : Colors.white10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (canVote)
                                        Radio<int>(
                                          value: option.id,
                                          groupValue: _poll!.userVotedOptionId ?? _pendingOptionId,
                                          onChanged: canVote ? (_) => _vote(option.id) : null,
                                          activeColor: Colors.amber,
                                        )
                                      else if (voted)
                                        HeroIcon(HeroIcons.checkCircle, style: HeroIconStyle.solid, size: 24, color: Colors.amber),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          option.optionText,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: voted ? FontWeight.w600 : FontWeight.w500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (hasVoted || isExpired)
                                        Text(
                                          '${option.votesCount} (${(pct * 100).toStringAsFixed(0)}%)',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (hasVoted || isExpired) ...[
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        backgroundColor: Colors.white12,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              if (hasVoted && canVote)
                Center(
                  child: TextButton.icon(
                    onPressed: _voting ? null : _unvote,
                    icon: HeroIcon(HeroIcons.arrowUturnLeft, style: HeroIconStyle.outline, size: 18, color: Colors.white70),
                    label: const Text('Ondoa kura yangu', style: TextStyle(color: Colors.white70)),
                  ),
                ),
              if (totalVotes > 0)
                Center(
                  child: Text(
                    'Jumla: $totalVotes kura',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
