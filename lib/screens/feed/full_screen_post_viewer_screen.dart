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
import '../../services/post_service.dart';
import '../../services/friend_service.dart';
import '../../services/poll_service.dart';
import '../../services/event_tracking_service.dart';
import 'video_reply_screen.dart';
import 'video_stitch_screen.dart';

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
  final FriendService _friendService = FriendService();
  late List<Post> _posts;
  int? _likingPostId;
  int? _savingPostId;

  DateTime? _currentPostEnteredAt;
  int? _currentPostId;
  int? _currentCreatorId;

  bool _autoPlayEnabled = false;
  Timer? _countdownTimer;
  int _countdownSeconds = 0;

  // Follow state: track per-user follow status locally
  final Map<int, bool> _followingStatus = {};
  final Set<int> _followingInProgress = {};

  // Comment input
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _sendingComment = false;

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

  Post? _getNextPost() {
    final currentPage = _pageController.page?.round() ?? 0;
    if (currentPage < _posts.length - 1) {
      return _posts[currentPage + 1];
    }
    return null;
  }

  @override
  void dispose() {
    _emitDwellForCurrentPost();
    _countdownTimer?.cancel();
    _pageController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
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

  bool _countdownPaused = false;

  void _startAutoPlayCountdown() {
    _countdownTimer?.cancel();
    _countdownPaused = false;
    if (!_autoPlayEnabled) return;

    // Determine countdown based on content type
    final currentPage = _pageController.page?.round() ?? 0;
    if (currentPage >= _posts.length) return;
    final post = _posts[currentPage];

    int seconds;
    if (post.hasVideo) {
      // Video: use video duration (minimum 10s, so the overlay isn't too brief)
      seconds = post.videoDuration > 0 ? post.videoDuration : 10;
    } else if (post.hasAudio) {
      // Audio: use audio duration
      seconds = (post.audioDuration ?? 0) > 0 ? post.audioDuration! : 10;
    } else {
      // Image/text: 10 seconds
      seconds = 10;
    }

    setState(() => _countdownSeconds = seconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_countdownPaused) return; // Skip tick while paused
      setState(() => _countdownSeconds--);
      if (_countdownSeconds <= 0) {
        timer.cancel();
        _autoAdvance();
      }
    });
  }

  void _pauseCountdown() {
    setState(() => _countdownPaused = true);
  }

  void _resumeCountdown() {
    setState(() => _countdownPaused = false);
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _countdownSeconds = 0;
      _countdownPaused = false;
    });
  }

  void _toggleAutoPlay() {
    setState(() {
      _autoPlayEnabled = !_autoPlayEnabled;
      if (_autoPlayEnabled) {
        _startAutoPlayCountdown();
      } else {
        _countdownTimer?.cancel();
        _countdownSeconds = 0;
        _countdownPaused = false;
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

  bool _isFollowing(Post post) {
    if (post.userId == widget.currentUserId) return true;
    return _followingStatus[post.userId] ?? post.user?.isFollowing ?? false;
  }

  void _onFollow(Post post) async {
    if (_followingInProgress.contains(post.userId)) return;
    if (post.userId == widget.currentUserId) return;
    final isCurrentlyFollowing = _isFollowing(post);
    setState(() {
      _followingInProgress.add(post.userId);
      _followingStatus[post.userId] = !isCurrentlyFollowing;
    });
    try {
      final success = isCurrentlyFollowing
          ? await _friendService.unfollowUser(widget.currentUserId, post.userId)
          : await _friendService.followUser(widget.currentUserId, post.userId);
      if (!mounted) return;
      setState(() {
        _followingInProgress.remove(post.userId);
        if (!success) _followingStatus[post.userId] = isCurrentlyFollowing;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _followingInProgress.remove(post.userId);
        _followingStatus[post.userId] = isCurrentlyFollowing;
      });
    }
  }

  void _onSendComment(Post post) async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _sendingComment) return;
    setState(() => _sendingComment = true);
    try {
      final result = await _postService.addComment(post.id, widget.currentUserId, text);
      if (!mounted) return;
      if (result.success) {
        _commentController.clear();
        _commentFocusNode.unfocus();
        setState(() {
          _sendingComment = false;
          final i = _posts.indexWhere((p) => p.id == post.id);
          if (i >= 0) {
            _posts[i] = post.copyWith(commentsCount: post.commentsCount + 1);
          }
        });
      } else {
        setState(() => _sendingComment = false);
        _showErrorSnackBar('Could not post comment. Try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sendingComment = false);
      _showErrorSnackBar(_networkErrorMessage(e));
    }
  }

  void _onUserTap(Post post) {
    Navigator.pushNamed(context, '/profile/${post.userId}');
  }

  void _onMoreOptions(Post post) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PostOptionsSheet(
        post: post,
        currentUserId: widget.currentUserId,
        onReport: () => _reportPost(post),
        onNotInterested: () => _notInterested(post),
        onReply: () => _openReply(post),
        onStitch: () => _openStitch(post),
      ),
    );
  }

  void _openReply(Post post) {
    Navigator.pop(context); // close sheet
    Navigator.push(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => VideoReplyScreen(
          originalPost: post,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  void _openStitch(Post post) {
    Navigator.pop(context); // close sheet
    if (!post.hasVideo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Stitch inapatikana tu kwa video'),
          backgroundColor: Colors.grey.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => VideoStitchScreen(
          originalPost: post,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  void _reportPost(Post post) async {
    Navigator.pop(context); // close the sheet
    // Show report reason dialog
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _ReportReasonDialog(),
    );
    if (reason == null || !mounted) return;
    final result = await _postService.reportPost(post.id, widget.currentUserId, reason: reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? 'Ripoti imetumwa. Asante!' : (result.message ?? 'Imeshindikana kutuma ripoti')),
        backgroundColor: Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _notInterested(Post post) async {
    Navigator.pop(context); // close the sheet
    // Track "not_interested" event for algorithm
    EventTrackingService.getInstance().then((tracker) {
      tracker.trackEvent(
        eventType: 'not_interested',
        postId: post.id,
        creatorId: post.userId,
      );
    });
    // Hide from feed by calling API
    _postService.hidePost(post.id, widget.currentUserId);
    // Remove from local list
    setState(() {
      _posts.removeWhere((p) => p.id == post.id);
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Hutaona chapisho kama hili tena'),
        backgroundColor: Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Rejesha',
          textColor: Colors.white,
          onPressed: () {
            // Re-add the post
            setState(() {
              _posts.add(post);
            });
          },
        ),
      ),
    );
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
            physics: _autoPlayEnabled
                ? const _EasierSwipePhysics(parent: ClampingScrollPhysics())
                : const BouncingScrollPhysics(parent: ClampingScrollPhysics()),
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
                  isFollowing: _isFollowing(post),
                  followInProgress: _followingInProgress.contains(post.userId),
                  onLike: () => _onLike(post),
                  onComment: () => _onComment(post),
                  onShare: () => _onShare(post),
                  onSave: () => _onSave(post),
                  onUserTap: () => _onUserTap(post),
                  onFollow: () => _onFollow(post),
                  autoPlayEnabled: _autoPlayEnabled,
                  onToggleAutoPlay: _toggleAutoPlay,
                  onMoreOptions: () => _onMoreOptions(post),
                  formatCount: _formatCount,
                ),
              );
            },
          ),
          // Top bar: close button + Up Next info + action icons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 12, top: 4),
              child: Row(
                children: [
                  // Close button
                  Material(
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
                  // Up Next info (shown when countdown active)
                  if (_countdownSeconds > 0 && _getNextPost() != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            // Countdown number
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white38, width: 1.5),
                              ),
                              child: Center(
                                child: _countdownPaused
                                    ? const Icon(Icons.pause_rounded, color: Colors.white, size: 12)
                                    : Text(
                                        '$_countdownSeconds',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Next post info
                            Expanded(
                              child: Text(
                                _countdownPaused
                                    ? 'Paused'
                                    : '${_getNextPost()!.user?.fullName ?? 'Next'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Pause/Resume icon
                            GestureDetector(
                              onTap: () {
                                if (_countdownPaused) {
                                  _resumeCountdown();
                                } else {
                                  _pauseCountdown();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  _countdownPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            // Skip icon
                            GestureDetector(
                              onTap: () {
                                _countdownTimer?.cancel();
                                _autoAdvance();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                            // Cancel icon
                            GestureDetector(
                              onTap: _cancelCountdown,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                ],
              ),
            ),
          ),
          // Comment input bar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _commentController,
                          focusNode: _commentFocusNode,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            final currentPage = _pageController.page?.round() ?? 0;
                            if (currentPage < _posts.length) {
                              _onSendComment(_posts[currentPage]);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _sendingComment
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                          )
                        : GestureDetector(
                            onTap: () {
                              final currentPage = _pageController.page?.round() ?? 0;
                              if (currentPage < _posts.length) {
                                _onSendComment(_posts[currentPage]);
                              }
                            },
                            child: const Icon(Icons.send_rounded, color: Colors.white70, size: 24),
                          ),
                  ],
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
  final bool isFollowing;
  final bool followInProgress;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onUserTap;
  final VoidCallback onFollow;
  final bool autoPlayEnabled;
  final VoidCallback onToggleAutoPlay;
  final VoidCallback onMoreOptions;
  final String Function(int) formatCount;

  const _FullScreenPostPage({
    super.key,
    required this.post,
    required this.currentUserId,
    this.likingPostId,
    this.savingPostId,
    this.isFollowing = false,
    this.followInProgress = false,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onSave,
    required this.onUserTap,
    required this.onFollow,
    this.autoPlayEnabled = false,
    required this.onToggleAutoPlay,
    required this.onMoreOptions,
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

  String _buildSocialProofText(List<String> names, int totalCount) {
    if (names.length == 1) {
      final others = totalCount - 1;
      if (others > 0) return 'Followed by ${names[0]} and $others others';
      return 'Followed by ${names[0]}';
    }
    if (names.length >= 2) {
      final others = totalCount - 2;
      if (others > 0) return 'Followed by ${names[0]}, ${names[1]} and $others others';
      return 'Followed by ${names[0]} and ${names[1]}';
    }
    return '';
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
          primaryVideo != null
              ? Center(
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: VideoPlayerWidget(
                      videoUrl: primaryVideo.fileUrl,
                      thumbnailUrl: primaryVideo.thumbnailUrl,
                      aspectRatio: aspectRatio,
                      showControls: true,
                      showBufferIndicator: true,
                    ),
                  ),
                )
              : SizedBox.expand(
                  child: CachedMediaImage(
                    imageUrl: primaryImage!.fileUrl,
                    fit: BoxFit.cover,
                    cacheWidth: cacheSize,
                    cacheHeight: cacheSize,
                    errorWidget: Container(
                      color: Colors.black,
                      child: const Center(
                        child: HeroIcon(HeroIcons.photo, style: HeroIconStyle.outline, size: 48, color: Colors.white54),
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

        // 2) Right side action bar: avatar, like, comment, share, save, menu
        Positioned(
          right: 12,
          bottom: 100,
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
              const SizedBox(height: 16),
              // Auto-play toggle
              _ActionItem(
                icon: Icon(
                  autoPlayEnabled ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                  size: 28,
                  color: autoPlayEnabled ? Colors.amber : Colors.white,
                ),
                onTap: onToggleAutoPlay,
              ),
              const SizedBox(height: 16),
              // More options (3-dot menu)
              _ActionItem(
                icon: HeroIcon(HeroIcons.ellipsisHorizontal, style: HeroIconStyle.outline, size: 28, color: Colors.white),
                onTap: onMoreOptions,
              ),
              ],
            ),
          ),
        ),

        // 3) Bottom-left: username + follow + caption + music + social proof
        Positioned(
          left: 12,
          right: 80,
          bottom: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Username row with Follow button
                  Row(
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
                      // Follow button (hidden for own posts or if already following)
                      if (post.userId != currentUserId && !isFollowing) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: followInProgress ? null : onFollow,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: followInProgress
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                                  )
                                : const Text(
                                    'Follow',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      shadows: [
                                        Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Caption (expandable)
                  if (post.content != null && post.content!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _ExpandableCaption(text: post.content!),
                  ],
                  // Music track row (tappable → creator's music)
                  if (post.hasMusic && post.musicTrack != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile/${post.userId}/music'),
                      child: Row(
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
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 16),
                        ],
                      ),
                    ),
                  ],
                  // Social proof: "Followed by X and Y others"
                  if (post.user != null &&
                      post.user!.mutualFollowerNames != null &&
                      post.user!.mutualFollowerNames!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _buildSocialProofText(post.user!.mutualFollowerNames!, post.user!.mutualFollowersCount ?? 0),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        shadows: [
                          Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // 5) Thread CTA for gossip thread posts
        if (post.threadId != null)
          Positioned(
            left: 16,
            bottom: 160,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/thread/${post.threadId}'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HeroIcon(HeroIcons.chatBubbleLeftRight, style: HeroIconStyle.outline, size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      post.commentsCount > 0
                          ? '${post.commentsCount} ${post.commentsCount == 1 ? 'comment' : 'comments'} · Join thread'
                          : 'Join thread',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 16),
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
  final String? label;
  final VoidCallback onTap;
  final bool isLoading;

  const _ActionItem({
    required this.icon,
    this.label,
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
            if (label != null && label!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                label!,
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

/// Expandable caption: shows 3 lines with "more" tap, full text when expanded.
class _ExpandableCaption extends StatefulWidget {
  final String text;
  const _ExpandableCaption({required this.text});

  @override
  State<_ExpandableCaption> createState() => _ExpandableCaptionState();
}

class _ExpandableCaptionState extends State<_ExpandableCaption> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.white,
      fontSize: 14,
      height: 1.3,
      shadows: [
        Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4),
        Shadow(color: Colors.black87, offset: Offset(0, 1), blurRadius: 8),
      ],
    );

    if (_expanded) {
      return GestureDetector(
        onTap: () => setState(() => _expanded = false),
        child: Text(widget.text, style: style),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: 3,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final overflow = tp.didExceedMaxLines;

        return GestureDetector(
          onTap: overflow ? () => setState(() => _expanded = true) : null,
          child: RichText(
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: style,
              children: [
                TextSpan(text: widget.text),
                if (overflow)
                  const TextSpan(
                    text: ' more',
                    style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Instagram-style post options bottom sheet.
class _PostOptionsSheet extends StatelessWidget {
  final Post post;
  final int currentUserId;
  final VoidCallback onReport;
  final VoidCallback onNotInterested;
  final VoidCallback onReply;
  final VoidCallback onStitch;

  const _PostOptionsSheet({
    required this.post,
    required this.currentUserId,
    required this.onReport,
    required this.onNotInterested,
    required this.onReply,
    required this.onStitch,
  });

  @override
  Widget build(BuildContext context) {
    final isOwnPost = post.userId == currentUserId;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Top action row: Reply + Stitch (like Instagram's Save/Remix/Sequence)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _TopActionButton(
                    icon: Icons.reply_rounded,
                    label: 'Reply',
                    onTap: onReply,
                  ),
                  const SizedBox(width: 12),
                  if (post.hasVideo)
                    _TopActionButton(
                      icon: Icons.content_cut_rounded,
                      label: 'Stitch',
                      onTap: onStitch,
                    ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            if (!isOwnPost) ...[
              // Not interested
              _OptionTile(
                icon: Icons.not_interested_rounded,
                label: 'Sipendi hii',
                subtitle: 'Hutaona machapisho kama haya',
                onTap: onNotInterested,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              // Report
              _OptionTile(
                icon: Icons.flag_outlined,
                label: 'Ripoti',
                labelColor: Colors.red.shade700,
                iconColor: Colors.red.shade700,
                onTap: onReport,
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Top action button in the options sheet (Instagram-style icon + label).
class _TopActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TopActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: const Color(0xFF1A1A1A)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single option tile in the post options sheet.
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;

  const _OptionTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 24, color: iconColor ?? const Color(0xFF1A1A1A)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: labelColor ?? const Color(0xFF1A1A1A),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Report reason dialog with predefined categories.
class _ReportReasonDialog extends StatelessWidget {
  static const _reasons = [
    'Maudhui yasiyofaa (Inappropriate content)',
    'Uchochezi (Hate speech)',
    'Udanganyifu (Spam/Scam)',
    'Unyanyasaji (Harassment)',
    'Maudhui ya watu wazima (Adult content)',
    'Habari za uongo (Misinformation)',
    'Sababu nyingine (Other)',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFAFAFA),
      title: const Text(
        'Ripoti chapisho',
        style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 17, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _reasons.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) => Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(ctx, _reasons[i]),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Text(
                  _reasons[i],
                  style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Ghairi', style: TextStyle(color: Color(0xFF666666))),
        ),
      ],
    );
  }
}

/// Custom scroll physics with lower mass and fling threshold for easier swiping
/// after the user has viewed 3+ posts (auto-play mode).
class _EasierSwipePhysics extends PageScrollPhysics {
  const _EasierSwipePhysics({super.parent});

  @override
  _EasierSwipePhysics applyTo(ScrollPhysics? ancestor) {
    return _EasierSwipePhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 50,      // Lower mass = easier to swipe (default is 100)
    stiffness: 100,
    damping: 1,
  );

  @override
  double get minFlingVelocity => 50.0; // Lower threshold = easier flings (default ~365)
}
