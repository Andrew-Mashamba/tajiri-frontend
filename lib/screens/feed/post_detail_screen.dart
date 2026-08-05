import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/post_models.dart';
import '../../services/comments_cache_service.dart';
import '../../services/feed_cache_service.dart';
import '../../services/post_service.dart';
import '../../services/live_update_service.dart';
import '../../services/user_posts_cache_service.dart';
import '../../widgets/motion_tokens.dart';
import '../../widgets/post_card.dart';
import '../../widgets/share_post_sheet.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../../widgets/user_avatar.dart';
import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import 'edit_post_screen.dart';
import '../../creator/screens/post_earnings_screen.dart';
import '../../services/event_tracking_service.dart';
import '../search/hashtag_screen.dart';
import '../search/search_screen.dart';
import '../wallet/subscribe_to_creator_screen.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFE5E5E5);
const Color _kSurface = Colors.white;
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kDanger = Color(0xFFD32F2F);

/// Instagram-style post detail screen with:
/// - Scrollable feed of posts (when [posts] list provided)
/// - Double-tap to like with heart animation
/// - Enhanced 3-dot menu (pin/archive/copy link for own posts)
/// - Comment like buttons with optimistic updates
/// - Pinned comments shown first
/// - Reply threading with parent_id
class PostDetailScreen extends StatefulWidget {
  final int postId;
  final int currentUserId;

  /// If provided (e.g. from feed), show immediately and refresh in background.
  final Post? initialPost;

  /// Optional list of posts for scrollable feed mode.
  /// When provided, the screen shows a vertical feed starting at [initialIndex].
  final List<Post>? posts;

  /// Starting index in [posts] list. Defaults to 0.
  final int initialIndex;

  /// UN-003 — when arrived via shared link (`?share_uid=...`), this is
  /// forwarded to FullScreenPostViewer for the entire §III sharer chain.
  final String? shareUid;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.currentUserId,
    this.initialPost,
    this.posts,
    this.initialIndex = 0,
    this.shareUid,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostService _postService = PostService();

  /// Feed mode: PageController for scrollable post feed.
  late final PageController _pageController;

  /// Whether we're in feed mode (multiple posts) or single-post mode.
  bool get _isFeedMode => widget.posts != null && widget.posts!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);

    if (_isFeedMode) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: _kBackground,
          appBar: TajiriAppBar(title: s?.post ?? 'Post'),
          body: SafeArea(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: widget.posts!.length,
              itemBuilder: (context, index) {
                final post = widget.posts![index];
                return _PostDetailPage(
                  key: ValueKey(post.id),
                  postId: post.id,
                  currentUserId: widget.currentUserId,
                  initialPost: post,
                  postService: _postService,
                  shareUid: widget.shareUid,
                );
              },
            ),
          ),
        ),
      );
    }

    // Single post mode (route navigation: /post/:id)
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _kBackground,
        appBar: TajiriAppBar(title: s?.post ?? 'Post'),
        body: SafeArea(
          child: _PostDetailPage(
            postId: widget.postId,
            currentUserId: widget.currentUserId,
            initialPost: widget.initialPost,
            postService: _postService,
            shareUid: widget.shareUid,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Individual post detail page — used both standalone and inside feed
// ═══════════════════════════════════════════════════════════════════════

class _PostDetailPage extends StatefulWidget {
  final int postId;
  final int currentUserId;
  final Post? initialPost;
  final PostService postService;
  final String? shareUid;

  const _PostDetailPage({
    super.key,
    required this.postId,
    required this.currentUserId,
    this.initialPost,
    required this.postService,
    this.shareUid,
  });

  @override
  State<_PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<_PostDetailPage>
    with AutomaticKeepAliveClientMixin<_PostDetailPage> {
  @override
  bool get wantKeepAlive => true;

  late final PostService _postService = widget.postService;
  final ScrollController _scrollController = ScrollController();

  Post? _post;
  bool _isLoadingPost = true;
  String? _postError;

  /// Creator earnings data (loaded for own posts only).
  PostEarningsResult? _earnings;

  final List<Comment> _comments = [];
  bool _isLoadingComments = false;
  bool _hasMoreComments = true;
  int _commentsPage = 1;
  static const int _commentsPerPage = 20;
  String? _commentsError;

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _isSubmittingComment = false;

  /// Reply mode state.
  Comment? _replyingTo;

  /// Tracks which comment threads are expanded (by parent comment ID).
  final Set<int> _expandedReplies = {};

  /// Tracks which comment threads are currently loading replies.
  final Set<int> _loadingReplies = {};

  StreamSubscription<LiveUpdateEvent>? _liveUpdateSubscription;

  /// Double-tap heart animation state.
  bool _showHeartAnimation = false;

  /// Transient error shown as a dismissible banner above the comment
  /// composer. Replaces SnackBars per playbook §99. Cleared on next
  /// successful action or by the user tapping the close icon.
  String? _formError;

  /// Bumps to retrigger a brief shake animation on whichever icon
  /// just failed (like / save). Used as a key on TweenAnimationBuilder
  /// so the animation replays on each failure.
  int _shakeNonce = 0;

  @override
  void initState() {
    super.initState();
    _hydratePost();
    _hydrateAndRefreshComments();
    _loadEarningsIfOwner();
    _scrollController.addListener(_onScroll);
    _liveUpdateSubscription = LiveUpdateService.instance.stream.listen((event) {
      if (!mounted) return;
      if (event is PostUpdateEvent && event.postId == widget.postId) {
        _loadPost();
      }
    });
    // UN-001 row 1 — fire view·author for backend earnings.
    // PostService.recordView is fire-and-forget.
    unawaited(widget.postService.recordView(
      postId: widget.postId,
      userId: widget.currentUserId,
      via: widget.shareUid,
    ));
    // UN-016 row 73 — PostDetailScreen is reached from non-feed surfaces
    // (search, saved-posts, collections, profiles, deep links). All of
    // these qualify as "reference revisit" per the spec.
    unawaited(widget.postService.recordReferenceRevisit(
      postId: widget.postId,
      userId: widget.currentUserId,
    ));
  }

  /// Layered hydrate for the post payload. Tries (in order):
  ///   1. widget.initialPost — passed by the navigator pusher
  ///   2. UserPostsCacheService — RAM-fast for own posts
  ///   3. FeedCacheService — RAM-fast for posts seen in feed
  ///   4. Network — always; silent if cache hydrated something
  /// See playbook → "Local-first list pages — layered cache & SWR".
  void _hydratePost() {
    Post? hot;
    if (widget.initialPost != null &&
        widget.initialPost!.id == widget.postId) {
      hot = widget.initialPost;
    } else {
      // Same-session: try the user-posts hot cache (covers own-post
      // tap from My Posts grid). Feed cache is async + the navigator
      // pusher already supplies initialPost from feed surfaces.
      hot = _findInUserPostsCache(widget.postId);
    }
    if (hot != null) {
      _post = hot;
      _isLoadingPost = false;
      _loadPostInBackground(); // silent refresh
    } else {
      _loadPost();
    }
  }

  Post? _findInUserPostsCache(int postId) {
    // The cache is keyed by userId; we don't know which user owns this
    // post until the post itself loads, so we scan the hot map. Cheap
    // for typical user counts; falls through fast if nothing matches.
    final cache = UserPostsCacheService.instance;
    final hotByMe = cache.getSync(widget.currentUserId);
    if (hotByMe != null) {
      for (final p in hotByMe) {
        if (p.id == postId) return p;
      }
    }
    return null;
  }

  Future<void> _hydrateAndRefreshComments() async {
    final cache = CommentsCacheService.instance;

    // 1. In-memory hit — same-session re-visit.
    final hot = cache.getSync(widget.postId);
    if (hot != null && hot.isNotEmpty) {
      setState(() {
        _comments
          ..clear()
          ..addAll(hot);
        _hasMoreComments = true;
      });
    } else {
      // 2. Disk hit — across cold-starts.
      final cold = await cache.getCached(widget.postId);
      if (!mounted) return;
      if (cold != null && cold.isNotEmpty) {
        setState(() {
          _comments
            ..clear()
            ..addAll(cold);
          _hasMoreComments = true;
        });
      }
    }

    // 3. Network — always. silent:true skips spinner over cached rows.
    await _loadComments(silent: _comments.isNotEmpty);
  }

  @override
  void dispose() {
    _liveUpdateSubscription?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMoreComments || _isLoadingComments) return;
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMoreComments();
    }
  }

  // ─── Data loading ──────────────────────────────────────────────────

  Future<void> _loadPost() async {
    setState(() {
      _isLoadingPost = true;
      _postError = null;
    });

    final result = await _postService.getPost(
      widget.postId,
      currentUserId: widget.currentUserId,
    );

    if (!mounted) return;
    setState(() {
      _isLoadingPost = false;
      if (result.success) {
        _post = result.post;
        _postError = null;
      } else {
        _postError = result.message ?? (AppStringsScope.of(context)?.postNotFound ?? 'Post not found');
      }
    });
    // Re-check earnings now that post ownership is known
    if (result.success) _loadEarningsIfOwner();
  }

  Future<void> _loadPostInBackground() async {
    final result = await _postService.getPost(
      widget.postId,
      currentUserId: widget.currentUserId,
    );
    if (!mounted) return;
    if (result.success && result.post != null) {
      setState(() => _post = result.post);
    }
  }

  Future<void> _loadEarningsIfOwner() async {
    // Check ownership from initialPost or wait for post to load
    final post = _post;
    if (post == null) return;
    final isOwner = post.userId == widget.currentUserId;
    if (!isOwner) return;

    final result = await _postService.getPostEarnings(widget.postId);
    if (!mounted) return;
    // Always set — empty result still drives the "0 TSh / 0 views"
    // bar so the creator sees the strip from day one.
    setState(() => _earnings = result);
  }

  Future<void> _loadComments({bool silent = false}) async {
    if (_isLoadingComments) return;
    setState(() {
      if (!silent) _isLoadingComments = true;
      _commentsError = null;
    });

    final result = await _postService.getComments(
      widget.postId,
      page: 1,
      perPage: _commentsPerPage,
    );

    if (!mounted) return;
    setState(() {
      _isLoadingComments = false;
      if (result.success) {
        _comments.clear();
        _comments.addAll(result.comments);
        _commentsPage = 1;
        _hasMoreComments = result.meta?.hasMore ?? false;
        _commentsError = null;
      } else {
        _commentsError = result.message ??
            (AppStringsScope.of(context)?.commentsNotFound ??
                'Comments could not be loaded');
      }
    });

    // Persist for next hydrate (in-memory + disk).
    if (result.success) {
      CommentsCacheService.instance.save(widget.postId, _comments);
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingComments || !_hasMoreComments) return;
    setState(() => _isLoadingComments = true);

    final result = await _postService.getComments(
      widget.postId,
      page: _commentsPage + 1,
      perPage: _commentsPerPage,
    );

    if (!mounted) return;
    setState(() {
      _isLoadingComments = false;
      if (result.success) {
        _comments.addAll(result.comments);
        _commentsPage++;
        _hasMoreComments = result.meta?.hasMore ?? false;
      }
    });
    if (result.success) {
      CommentsCacheService.instance.save(widget.postId, _comments);
    }
  }

  // ─── Actions ───────────────────────────────────────────────────────

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSubmittingComment || _post == null) return;

    final parentId = _replyingTo?.id;

    setState(() => _isSubmittingComment = true);
    _commentController.clear();

    final result = await _postService.addComment(
      widget.postId,
      widget.currentUserId,
      content,
      parentId: parentId,
      shareUid: widget.shareUid,
    );

    if (!mounted) return;
    setState(() {
      _isSubmittingComment = false;
      _replyingTo = null;
    });
    if (result.success && result.comment != null) {
      // Meaningful submit per playbook §2364 — mediumImpact.
      HapticFeedback.mediumImpact();
      setState(() {
        if (parentId != null) {
          // Add reply to comments list
          _comments.add(result.comment!);
          // Auto-expand the parent thread
          _expandedReplies.add(parentId);
          // Update parent's reply count
          final parentIndex = _comments.indexWhere((c) => c.id == parentId);
          if (parentIndex >= 0) {
            _comments[parentIndex] = _comments[parentIndex].copyWith(
              replyCount: _comments[parentIndex].replyCount + 1,
            );
          }
        } else {
          _comments.insert(0, result.comment!);
        }
        _post = _post!.copyWith(
          commentsCount: _post!.commentsCount + 1,
        );
      });
      EventTrackingService.getInstance().then((tracker) {
        tracker.trackEvent(
          eventType: 'comment',
          postId: widget.postId,
          creatorId: _post?.userId,
        );
      });
      // Mirror new comment into the cache so the next hydrate is fresh.
      CommentsCacheService.instance.save(widget.postId, _comments);
    } else {
      final s = AppStringsScope.of(context);
      final isSw = s?.isSwahili ?? false;
      setState(() {
        _formError = result.message ??
            (isSw
                ? 'Imeshindwa kutuma maoni — angalia muunganisho na ujaribu tena.'
                : "Couldn't post your comment — check your connection and try again.");
      });
    }
  }

  Future<void> _onLike(Post post) async {
    final wasLiked = post.isLiked;
    setState(() {
      _post = post.copyWith(
        isLiked: !wasLiked,
        likesCount: wasLiked ? post.likesCount - 1 : post.likesCount + 1,
      );
    });

    final result = wasLiked
        ? await _postService.unlikePost(post.id, widget.currentUserId)
        : await _postService.likePost(post.id, widget.currentUserId, shareUid: widget.shareUid);

    if (!mounted) return;
    if (!result.success) {
      // Optimistic revert + brief shake on the heart — playbook §1568
      // (no SnackBar; the revert + shake IS the failure signal).
      setState(() {
        _post = post;
        _shakeNonce++;
      });
    } else if (result.likesCount != null) {
      setState(() => _post = _post!.copyWith(likesCount: result.likesCount!));
    }
  }

  Future<void> _onReaction(Post post, ReactionType reaction) async {
    setState(() {
      _post = post.copyWith(
        isLiked: true,
        likesCount: post.isLiked ? post.likesCount : post.likesCount + 1,
      );
    });

    final result = await _postService.likePost(
      post.id,
      widget.currentUserId,
      reactionType: reaction.name,
      shareUid: widget.shareUid,
    );

    if (!mounted) return;
    if (!result.success) {
      setState(() => _post = post);
    } else if (result.likesCount != null) {
      setState(() => _post = _post!.copyWith(likesCount: result.likesCount!));
    }
  }

  /// Double-tap to like — triggers heart animation + like if not already liked.
  void _onDoubleTapLike() {
    final post = _post;
    if (post == null) return;

    HapticFeedback.lightImpact();

    // Skip the visual animation when reduce-motion is on; just like.
    if (!MotionTokens.reduced(context)) {
      setState(() => _showHeartAnimation = true);
      Future.delayed(MotionTokens.emph + MotionTokens.short, () {
        if (mounted) setState(() => _showHeartAnimation = false);
      });
    }

    if (!post.isLiked) {
      _onLike(post);
    }
  }

  Future<void> _onSave(Post post) async {
    final wasSaved = post.isSaved;
    setState(() {
      _post = post.copyWith(
        isSaved: !wasSaved,
        savesCount: wasSaved ? post.savesCount - 1 : post.savesCount + 1,
      );
    });

    final result = wasSaved
        ? await _postService.unsavePost(post.id, widget.currentUserId)
        : await _postService.savePost(post.id, widget.currentUserId, shareUid: widget.shareUid);

    if (!mounted) return;
    if (!result.success) {
      // Optimistic revert + shake — no SnackBar.
      setState(() {
        _post = post;
        _shakeNonce++;
      });
    }
    // Success path is silent — bookmark icon already toggled inline,
    // which IS the confirmation per playbook §99.
  }

  void _onShare(Post post) {
    showSharePostBottomSheet(
      context,
      post: post,
      userId: widget.currentUserId,
      postService: _postService,
      onShared: (Post? sharedPost) {
        if (sharedPost != null && mounted && _post != null) {
          setState(() => _post = _post!.copyWith(sharesCount: _post!.sharesCount + 1));
        }
      },
    );
  }

  void _onUserTap(Post post) {
    Navigator.pushNamed(context, '/profile/${post.userId}');
  }

  // ─── Enhanced 3-dot menu (Instagram-style) ─────────────────────────

  void _onMenuTap(Post post) {
    HapticFeedback.heavyImpact(); // Long-press menu open (§2364).
    final s = AppStringsScope.of(context);
    final isOwner = post.userId == widget.currentUserId;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Note: Edit / Pin / Archive / Delete moved to the sticky
            // owner action row below the AppBar — see
            // _buildOwnerActionRow. This menu now only carries
            // ambient actions (Copy link, Report).
            ListTile(
              leading: const Icon(Icons.link_rounded, color: Color(0xFF1A1A1A)),
              title: Text(s?.copyLink ?? 'Copy link'),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(
                  text:
                      '${ApiConfig.baseUrl.replaceFirst(RegExp(r'/api$'), '')}/post/${post.id}',
                ));
                // Silent ack — sheet popped + system haptic per
                // playbook §1421 (visual-only ack for clipboard).
                HapticFeedback.lightImpact();
              },
            ),
            if (!isOwner) ...[
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Color(0xFF1A1A1A)),
                title: Text(s?.reportPost ?? 'Report'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _postService.reportPost(
                      post.id, widget.currentUserId);
                  // Silent — the sheet pop is the user's signal that
                  // the action completed. Idempotent server-side.
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePin(Post post) async {
    final wasPinned = post.isPinned;
    final result = wasPinned
        ? await _postService.unpinPost(post.id, widget.currentUserId)
        : await _postService.pinPost(post.id, widget.currentUserId);

    if (!mounted) return;
    if (result.success) {
      // Silent on success — the inline pin badge updating IS the
      // confirmation per playbook §99.
      setState(() => _post = _post!.copyWith(isPinned: !wasPinned));
    } else {
      final s = AppStringsScope.of(context);
      await _showFailureDialog(
        s?.pinUpdateFailed ?? 'Could not update pin. Try again.',
        result.message,
      );
    }
  }

  Future<void> _archivePost(Post post) async {
    final result =
        await _postService.archivePost(post.id, widget.currentUserId);
    if (!mounted) return;
    if (result.success) {
      // Invalidate caches so the parent grid refetches without the
      // archived post — matches the project-wide save→pop→refresh chain.
      UserPostsCacheService.instance.invalidate(widget.currentUserId);
      FeedCacheService.instance.clear();
      // Silent + pop(true) — the parent's reload is the confirmation.
      Navigator.pop(context, post.id);
    } else {
      final s = AppStringsScope.of(context);
      await _showFailureDialog(
        s?.archiveFailed ?? 'Could not archive the post. Try again.',
        result.message,
      );
    }
  }

  /// Strip developer noise from raw error strings before showing them
  /// — playbook §100 "never raw error strings".
  String _sanitizeError(String raw) {
    final stripped =
        raw.startsWith('Exception: ') ? raw.substring(11) : raw;
    if (stripped.contains('SocketException') ||
        stripped.contains('Failed host lookup')) {
      final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
      return isSw
          ? 'Hakuna intaneti. Hakikisha umeunganishwa.'
          : "Can't reach the server. Check your connection.";
    }
    if (stripped.contains('TimeoutException')) {
      final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
      return isSw
          ? 'Muda umeisha. Jaribu tena.'
          : 'Request timed out. Try again.';
    }
    return stripped;
  }

  /// Generic failure dialog used to replace transient SnackBars on
  /// non-recoverable errors (pin/archive/delete fail).
  Future<void> _showFailureDialog(
      String defaultMessage, String? serverMessage) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(
          serverMessage ?? defaultMessage,
          style: const TextStyle(color: _kPrimary, fontSize: 14),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Post post) {
    final s = AppStringsScope.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(s?.deletePostConfirmTitle ?? 'Delete post'),
        content: Text(s?.deletePostConfirmMessage ?? 'Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s?.no ?? 'No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final result = await _postService.deletePost(post.id,
                  userId: widget.currentUserId);
              if (!mounted) return;
              if (result.success) {
                UserPostsCacheService.instance
                    .invalidate(widget.currentUserId);
                FeedCacheService.instance.clear();
                CommentsCacheService.instance.invalidate(post.id);
                // Silent + pop(true) — the parent's reload reflects
                // the deletion, which IS the confirmation.
                Navigator.pop(context, post.id);
              } else {
                final s2 = AppStringsScope.of(context);
                await _showFailureDialog(
                  s2?.deletePostFailed ??
                      'Could not delete the post. Try again.',
                  result.message,
                );
              }
            },
            child: Text(s?.yes ?? 'Yes',
                style: const TextStyle(color: _kDanger)),
          ),
        ],
      ),
    );
  }

  // ─── Reply threading ─────────────────────────────────────────────

  /// Get top-level comments (no parentId).
  List<Comment> get _topLevelComments =>
      _comments.where((c) => c.parentId == null).toList();

  /// Get replies for a given parent comment ID.
  List<Comment> _getRepliesFor(int parentId) =>
      _comments.where((c) => c.parentId == parentId).toList();

  /// Toggle expand/collapse of replies for a comment.
  void _toggleReplies(Comment comment) {
    setState(() {
      if (_expandedReplies.contains(comment.id)) {
        _expandedReplies.remove(comment.id);
      } else {
        _expandedReplies.add(comment.id);
        // Load replies from API if we don't have them yet
        final existingReplies = _getRepliesFor(comment.id);
        if (existingReplies.isEmpty && comment.replyCount > 0) {
          _loadRepliesFor(comment);
        }
      }
    });
  }

  /// Fetch replies for a specific parent comment from the API.
  Future<void> _loadRepliesFor(Comment parent) async {
    if (_loadingReplies.contains(parent.id)) return;
    setState(() => _loadingReplies.add(parent.id));

    final result = await _postService.getReplies(
      widget.postId,
      parent.id,
      perPage: 50,
    );

    if (!mounted) return;
    setState(() {
      _loadingReplies.remove(parent.id);
      if (result.success) {
        // Remove existing replies for this parent, then add fresh ones
        _comments.removeWhere((c) => c.parentId == parent.id);
        _comments.addAll(result.comments);
      }
    });
  }

  // ─── Comment like ──────────────────────────────────────────────────

  Future<void> _onCommentLike(Comment comment) async {
    final wasLiked = comment.isLiked;
    final index = _comments.indexWhere((c) => c.id == comment.id);
    if (index < 0) return;

    setState(() {
      _comments[index] = comment.copyWith(
        isLiked: !wasLiked,
        likesCount: wasLiked ? comment.likesCount - 1 : comment.likesCount + 1,
      );
    });

    final result = wasLiked
        ? await _postService.unlikeComment(comment.id, widget.currentUserId)
        : await _postService.likeComment(comment.id, widget.currentUserId);

    if (!mounted) return;
    if (!result.success) {
      // Rollback
      final rollbackIndex = _comments.indexWhere((c) => c.id == comment.id);
      if (rollbackIndex >= 0) {
        setState(() => _comments[rollbackIndex] = comment);
      }
    } else if (result.likesCount >= 0) {
      // Sync with server count
      final syncIndex = _comments.indexWhere((c) => c.id == comment.id);
      if (syncIndex >= 0) {
        setState(() {
          _comments[syncIndex] = _comments[syncIndex].copyWith(
            likesCount: result.likesCount,
          );
        });
      }
      CommentsCacheService.instance.save(widget.postId, _comments);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final s = AppStringsScope.of(context);

    if (_isLoadingPost && _post == null) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _kPrimary,
        ),
      );
    }

    if (_postError != null && _post == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                _sanitizeError(_postError!),
                style: const TextStyle(color: _kSecondary, fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loadPost,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: const BorderSide(color: _kPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                child: Text(s?.retry ?? 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final post = _post!;
    final isOwner = post.userId == widget.currentUserId;
    // Always show the earnings strip for own posts (even at 0 TSh /
    // 0 views) — gives the creator a clear "this is what it's earning
    // so far". Hidden only while earnings are still loading.
    final hasEarnings = isOwner && _earnings != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isOwner) _buildOwnerActionRow(post, s),
        if (hasEarnings) _buildEarningsBar(post, _earnings!, s),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DoubleTapLikeWrapper(
                  showHeart: _showHeartAnimation,
                  onDoubleTap: _onDoubleTapLike,
                  child: _ShakeOnFailure(
                    nonce: _shakeNonce,
                    child: PostCard(
                    post: post,
                    currentUserId: widget.currentUserId,
                    onLike: () => _onLike(post),
                    onComment: () {
                      _commentFocusNode.requestFocus();
                    },
                    onShare: () => _onShare(post),
                    onSave: () => _onSave(post),
                    onUserTap: () => _onUserTap(post),
                    onMenuTap: () => _onMenuTap(post),
                    onHashtagTap: (hashtag) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HashtagScreen(
                            hashtag: hashtag,
                            currentUserId: widget.currentUserId,
                          ),
                        ),
                      );
                    },
                    onMentionTap: (username) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SearchScreen(
                            currentUserId: widget.currentUserId,
                            initialQuery: username,
                            initialTab: 0,
                          ),
                        ),
                      );
                    },
                    onSubscribe: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubscribeToCreatorScreen(
                            creatorId: post.userId,
                            currentUserId: widget.currentUserId,
                            creatorDisplayName: post.user?.fullName,
                          ),
                        ),
                      );
                    },
                    onReaction: (reaction) => _onReaction(post, reaction),
                    onThreadTap: post.threadId != null
                        ? () => Navigator.pushNamed(context, '/thread/${post.threadId}')
                        : null,
                  ),
                  ),
                ),
                const Divider(height: 1),
                _buildCommentsSection(s),
              ],
            ),
          ),
        ),
        _buildCommentInput(post, s),
      ],
    );
  }

  Widget _buildCommentsSection(AppStrings? s) {
    final topLevel = _topLevelComments;
    final pinnedComments = topLevel.where((c) => c.isPinned).toList();
    final regularComments = topLevel.where((c) => !c.isPinned).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            '${s?.comments ?? 'Comments'} (${_post?.commentsCount ?? 0})',
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (_commentsError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text(
                  _sanitizeError(_commentsError!),
                  style: const TextStyle(color: _kSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _loadComments,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(s?.retry ?? 'Retry'),
                ),
              ],
            ),
          ),
        if (_comments.isEmpty && !_isLoadingComments && _commentsError == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text(
                  s?.noCommentsYet ??
                      'No comments yet. Be the first to comment.',
                  style: const TextStyle(color: _kSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        else ...[
          // Pinned comments first (with their reply threads)
          for (final pinned in pinnedComments)
            _buildCommentThread(pinned, isPinned: true),
          // Regular top-level comments — direct spread into the parent
          // SingleChildScrollView per playbook §2627 (no shrinkWrap +
          // NeverScrollableScrollPhysics inside another scroll view).
          for (final c in regularComments) _buildCommentThread(c),
          if (_hasMoreComments && _isLoadingComments)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _kPrimary),
                ),
              ),
            ),
        ],
      ],
    );
  }

  /// Builds a comment with its reply thread (YouTube-style).
  Widget _buildCommentThread(Comment comment, {bool isPinned = false}) {
    final replies = _getRepliesFor(comment.id);
    final isExpanded = _expandedReplies.contains(comment.id);
    final isLoading = _loadingReplies.contains(comment.id);
    final replyCount = comment.replyCount > 0
        ? comment.replyCount
        : replies.length;
    final hasReplies = replyCount > 0 || replies.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Parent comment
        _CommentTile(
          comment: comment,
          isPinned: isPinned,
          isReply: false,
          onLike: () => _onCommentLike(comment),
          onReply: () {
            setState(() => _replyingTo = comment);
            _commentController.text = '@${comment.user?.fullName ?? ''} ';
          },
        ),
        // "View X replies" / "Hide replies" toggle
        if (hasReplies)
          Padding(
            padding: const EdgeInsets.only(left: 52, bottom: 4),
            child: GestureDetector(
              onTap: () => _toggleReplies(comment),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 1,
                    color: const Color(0xFF1A1A1A),
                    margin: const EdgeInsets.only(right: 8),
                  ),
                  if (isLoading)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: _kPrimary),
                    )
                  else
                    Text(
                      isExpanded
                          ? (AppStringsScope.of(context)?.hideReplies ?? 'Hide replies')
                          : '${AppStringsScope.of(context)?.viewReplies ?? 'View'} $replyCount ${replyCount == 1 ? (AppStringsScope.of(context)?.replyAction ?? 'reply') : (AppStringsScope.of(context)?.repliesLabel ?? 'replies')}',
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        // Expanded replies with thread line
        if (isExpanded && replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Thread connector line
                  Container(
                    width: 2,
                    margin: const EdgeInsets.only(left: 4, right: 0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  // Reply tiles
                  Expanded(
                    child: Column(
                      children: replies.map((reply) {
                        return _CommentTile(
                          comment: reply,
                          isPinned: false,
                          isReply: true,
                          onLike: () => _onCommentLike(reply),
                          onReply: () {
                            // Reply to the parent thread, not the reply itself (YouTube-style: max 1 level)
                            setState(() => _replyingTo = comment);
                            _commentController.text = '@${reply.user?.fullName ?? ''} ';
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Sticky earnings strip — directly under the owner CRUD row.
  /// Shows the headline figure + impressions; tap opens the full
  /// breakdown sheet (engagement, per-metric earnings, etc.).
  Widget _buildEarningsBar(
      Post post, PostEarningsResult e, AppStrings? s) {
    final isSw = s?.isSwahili ?? false;
    final amount = '${_fmtCurrency(e.estimatedEarnings)} ${e.currency}';
    return Material(
      color: _kSurface,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostEarningsScreen(
              postId: post.id,
              currentUserId: widget.currentUserId,
              initialEarnings: e,
              post: post,
            ),
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _kBorder)),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  size: 20,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isSw ? 'Mapato ya chapisho' : 'This post has earned',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _kSecondary,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      amount,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSw
                          ? '${_fmtCount(e.impressions)} mwoneko · ${e.engagementRate.toStringAsFixed(1)}% mwingiliano'
                          : '${_fmtCount(e.impressions)} views · ${e.engagementRate.toStringAsFixed(1)}% engagement',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: _kSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtCurrency(double v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(v >= 10000000 ? 0 : 1)}M';
    }
    if (v >= 10000) return '${(v / 1000).toStringAsFixed(0)}K';
    final s = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
    // Add comma separators for thousands when below the K cutoff.
    final parts = s.split('.');
    final intPart = parts[0];
    final reversed = intPart.split('').reversed.toList();
    final out = StringBuffer();
    for (var i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) out.write(',');
      out.write(reversed[i]);
    }
    final formatted = out.toString().split('').reversed.join('');
    return parts.length > 1 ? '$formatted.${parts[1]}' : formatted;
  }

  String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  /// Sticky CRUD row directly under the AppBar — owner-only. Edit /
  /// Pin·Unpin / Archive / Delete. Replaces the same actions in the
  /// 3-dot menu so they're one tap away instead of two.
  Widget _buildOwnerActionRow(Post post, AppStrings? s) {
    final isSw = s?.isSwahili ?? false;
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _CrudPill(
              icon: Icons.edit_rounded,
              label: s?.edit ?? 'Edit',
              onTap: () async {
                final updated = await Navigator.push<Post>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditPostScreen(post: post),
                  ),
                );
                if (updated != null && mounted) {
                  setState(() => _post = updated);
                }
              },
            ),
            const SizedBox(width: 8),
            _CrudPill(
              icon: post.isPinned
                  ? Icons.push_pin_outlined
                  : Icons.push_pin_rounded,
              label: post.isPinned
                  ? (s?.unpinPost ?? 'Unpin')
                  : (s?.pinToProfile ?? 'Pin'),
              onTap: () => _togglePin(post),
            ),
            const SizedBox(width: 8),
            _CrudPill(
              icon: Icons.archive_outlined,
              label: s?.archive ?? 'Archive',
              onTap: () => _archivePost(post),
            ),
            const SizedBox(width: 8),
            _CrudPill(
              icon: Icons.delete_outline_rounded,
              label: isSw ? 'Futa' : 'Delete',
              onTap: () => _confirmDelete(post),
              danger: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput(Post post, AppStrings? s) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Inline error banner (replaces SnackBars on comment failures).
          if (_formError != null) ...[
            _InlineErrorBanner(
              message: _formError!,
              onDismiss: () => setState(() => _formError = null),
            ),
            const SizedBox(height: 8),
          ],
          // Reply indicator
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    '${s?.replyingTo ?? 'Replying to'} ${_replyingTo!.user?.fullName ?? (s?.commentNoun ?? 'comment')}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() {
                      _replyingTo = null;
                      _commentController.clear();
                    }),
                    child: Icon(Icons.close, size: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  decoration: InputDecoration(
                    hintText: _replyingTo != null
                        ? '${s?.replyToHint ?? 'Reply to'} ${_replyingTo!.user?.fullName ?? (s?.commentNoun ?? 'comment')}...'
                        : (s?.writeComment ?? 'Write a comment...'),
                    hintStyle: const TextStyle(color: Color(0xFF999999)),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitComment(),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: s?.send ?? 'Send',
                child: Semantics(
                  button: true,
                  label: s?.send ?? 'Send',
                  child: Material(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _isSubmittingComment ? null : _submitComment,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: _isSubmittingComment
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded,
                                color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Double-tap like overlay — shows animated heart on double-tap
// ═══════════════════════════════════════════════════════════════════════

class _DoubleTapLikeWrapper extends StatelessWidget {
  final Widget child;
  final bool showHeart;
  final VoidCallback onDoubleTap;

  const _DoubleTapLikeWrapper({
    required this.child,
    required this.showHeart,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          child,
          if (showHeart)
            const IgnorePointer(child: _HeartAnimation()),
        ],
      ),
    );
  }
}

/// Animated heart icon: scales up, holds, then fades out.
class _HeartAnimation extends StatefulWidget {
  const _HeartAnimation();

  @override
  State<_HeartAnimation> createState() => _HeartAnimationState();
}

class _HeartAnimationState extends State<_HeartAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionTokens.emph,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _controller.forward();
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
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: const Icon(
        Icons.favorite_rounded,
        size: 80,
        color: Colors.white,
        shadows: [
          Shadow(color: Colors.black38, blurRadius: 12),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Comment tile — with like button, pinned badge, reply indent, and reply action
// ═══════════════════════════════════════════════════════════════════════

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isPinned;
  final bool isReply;
  final VoidCallback onLike;
  final VoidCallback onReply;

  const _CommentTile({
    required this.comment,
    this.isPinned = false,
    this.isReply = false,
    required this.onLike,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isPinned)
          Padding(
            padding: const EdgeInsets.only(left: 48, top: 8, bottom: 2),
            child: Row(
              children: [
                Icon(Icons.push_pin_rounded, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  s?.pinnedComment ?? 'Pinned',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.only(
            left: isReply ? 12 : 16,
            right: 16,
            top: isReply ? 6 : 10,
            bottom: isReply ? 6 : 10,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/profile/${comment.userId}');
                },
                child: UserAvatar(
                  photoUrl: comment.user?.profilePhotoUrl,
                  name: comment.user?.fullName,
                  radius: isReply ? 14 : 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            comment.user?.fullName ?? (s?.unknownUser ?? 'Unknown'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isReply ? 13 : 14,
                              color: const Color(0xFF1A1A1A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(comment.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comment.content,
                      style: TextStyle(
                        fontSize: isReply ? 13 : 14,
                        color: const Color(0xFF1A1A1A),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onReply,
                      child: Text(
                        s?.replyAction ?? 'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onLike,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    children: [
                      Icon(
                        comment.isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 16,
                        color: comment.isLiked ? _kDanger : Colors.grey.shade400,
                      ),
                      if (comment.likesCount > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatCount(comment.likesCount),
                          style: TextStyle(
                            fontSize: 11,
                            color: comment.isLiked ? _kDanger : Colors.grey.shade400,
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
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${diff.inDays ~/ 7}w';
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

/// Outlined pill used in the owner-only CRUD row below the AppBar.
/// Playbook §110 spec: `circular(20)`, padding `(14, 8)`, 12px label.
/// `danger:true` switches to semantic red `_kDanger`.
class _CrudPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _CrudPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = danger ? _kDanger : _kPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 36,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: fg.withValues(alpha: 0.40)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
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
}

/// Brief shake animation that fires whenever [nonce] changes — used
/// to signal optimistic-update failures (like / save) without a
/// SnackBar (playbook §1568). Suppressed when reduce-motion is on.
class _ShakeOnFailure extends StatelessWidget {
  final int nonce;
  final Widget child;
  const _ShakeOnFailure({required this.nonce, required this.child});

  @override
  Widget build(BuildContext context) {
    if (MotionTokens.reduced(context)) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(nonce),
      tween: Tween<double>(begin: 0, end: 1),
      duration: MotionTokens.medium,
      builder: (context, t, c) {
        // Damped 3-cycle horizontal shake — playbook §1131.
        final dx = nonce == 0 ? 0.0 : (1 - t) * 6.0 * (t < 0.05 ? 0 : 1) *
            (t < 0.5 ? 1 : -1) *
            ((t * 6).floor().isEven ? 1 : -1);
        return Transform.translate(offset: Offset(dx, 0), child: c);
      },
      child: child,
    );
  }
}

/// Inline error banner shown above the comment composer when a save
/// fails. Replaces SnackBars per playbook §99. Wrapped in
/// [Semantics(liveRegion: true)] so screen readers announce on appear.
class _InlineErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _InlineErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(
          color: _kDanger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kDanger.withValues(alpha: 0.20)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 18, color: _kDanger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _kDanger,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded,
                  size: 18, color: _kDanger),
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 36, minHeight: 36),
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }
}
