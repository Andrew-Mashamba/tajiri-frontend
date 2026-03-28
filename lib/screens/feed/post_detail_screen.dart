import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/post_models.dart';
import '../../services/post_service.dart';
import '../../services/live_update_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/share_post_sheet.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../../widgets/user_avatar.dart';
import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import 'edit_post_screen.dart';
import '../../services/event_tracking_service.dart';
import '../search/hashtag_screen.dart';
import '../search/search_screen.dart';
import '../wallet/subscribe_to_creator_screen.dart';

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

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.currentUserId,
    this.initialPost,
    this.posts,
    this.initialIndex = 0,
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
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
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
              );
            },
          ),
        ),
      );
    }

    // Single post mode (route navigation: /post/:id)
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: TajiriAppBar(title: s?.post ?? 'Post'),
      body: SafeArea(
        child: _PostDetailPage(
          postId: widget.postId,
          currentUserId: widget.currentUserId,
          initialPost: widget.initialPost,
          postService: _postService,
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

  const _PostDetailPage({
    super.key,
    required this.postId,
    required this.currentUserId,
    this.initialPost,
    required this.postService,
  });

  @override
  State<_PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<_PostDetailPage> {
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

  @override
  void initState() {
    super.initState();
    if (widget.initialPost != null && widget.initialPost!.id == widget.postId) {
      _post = widget.initialPost;
      _isLoadingPost = false;
      _loadPostInBackground();
    } else {
      _loadPost();
    }
    _loadComments();
    _loadEarningsIfOwner();
    _scrollController.addListener(_onScroll);
    _liveUpdateSubscription = LiveUpdateService.instance.stream.listen((event) {
      if (!mounted) return;
      if (event is PostUpdateEvent && event.postId == widget.postId) {
        _loadPost();
      }
    });
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
    if (!result.isEmpty) {
      setState(() => _earnings = result);
    }
  }

  Future<void> _loadComments() async {
    if (_isLoadingComments) return;
    setState(() {
      _isLoadingComments = true;
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
        _commentsError = result.message ?? (AppStringsScope.of(context)?.commentsNotFound ?? 'Comments could not be loaded');
      }
    });
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
    );

    if (!mounted) return;
    setState(() {
      _isSubmittingComment = false;
      _replyingTo = null;
    });
    if (result.success && result.comment != null) {
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
    } else {
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? (s?.addCommentFailed ?? 'Failed to add comment')),
        ),
      );
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
        : await _postService.likePost(post.id, widget.currentUserId);

    if (!mounted) return;
    if (!result.success) {
      setState(() => _post = post);
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.likeUpdateFailed ?? 'Failed to update like')),
      );
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

    setState(() => _showHeartAnimation = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showHeartAnimation = false);
    });

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
        : await _postService.savePost(post.id, widget.currentUserId);

    if (!mounted) return;
    if (!result.success) {
      setState(() => _post = post);
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? (s?.saveUpdateFailed ?? 'Failed to update save')),
        ),
      );
    } else {
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasSaved ? (s?.removedFromSaved ?? 'Removed from saved') : (s?.savedSuccess ?? 'Saved'),
          ),
        ),
      );
    }
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
            if (isOwner) ...[
              ListTile(
                leading: Icon(
                  post.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                  color: const Color(0xFF1A1A1A),
                ),
                title: Text(post.isPinned ? (s?.unpinPost ?? 'Unpin post') : (s?.pinToProfile ?? 'Pin to your profile')),
                onTap: () {
                  Navigator.pop(ctx);
                  _togglePin(post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined, color: Color(0xFF1A1A1A)),
                title: Text(s?.archive ?? 'Archive'),
                onTap: () {
                  Navigator.pop(ctx);
                  _archivePost(post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Color(0xFF1A1A1A)),
                title: Text(s?.edit ?? 'Edit'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final updated = await Navigator.push<Post>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPostScreen(post: post),
                    ),
                  );
                  if (updated != null && mounted) {
                    setState(() => _post = updated);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: Text(s?.delete ?? 'Delete', style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(post);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.link_rounded, color: Color(0xFF1A1A1A)),
              title: Text(s?.copyLink ?? 'Copy link'),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: '${ApiConfig.baseUrl.replaceFirst(RegExp(r'/api$'), '')}/post/${post.id}'));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s?.linkCopied ?? 'Link copied')),
                );
              },
            ),
            if (!isOwner) ...[
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Color(0xFF1A1A1A)),
                title: Text(s?.reportPost ?? 'Report'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await _postService.reportPost(post.id, widget.currentUserId);
                  if (!mounted) return;
                  final s2 = AppStringsScope.of(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(
                      result.success
                          ? (s2?.reportSubmitted ?? 'Report submitted')
                          : (result.message ?? (s2?.reportSubmitted ?? 'Report submitted')),
                    )),
                  );
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
      setState(() => _post = _post!.copyWith(isPinned: !wasPinned));
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(wasPinned ? (s?.postUnpinned ?? 'Post unpinned') : (s?.postPinned ?? 'Post pinned to profile'))),
      );
    } else {
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? (s?.pinUpdateFailed ?? 'Failed to update pin'))),
      );
    }
  }

  Future<void> _archivePost(Post post) async {
    final result = await _postService.archivePost(post.id, widget.currentUserId);
    if (!mounted) return;
    if (result.success) {
      final s = AppStringsScope.of(context);
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, post.id);
      messenger.showSnackBar(
        SnackBar(content: Text(s?.postArchived ?? 'Post archived')),
      );
    } else {
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? (s?.archiveFailed ?? 'Failed to archive post'))),
      );
    }
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
              final result = await _postService.deletePost(post.id, userId: widget.currentUserId);
              if (!mounted) return;
              if (result.success) {
                final s2 = AppStringsScope.of(context);
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context, post.id);
                messenger.showSnackBar(
                  SnackBar(content: Text(s2?.postDeleted ?? 'Post deleted')),
                );
              } else {
                final s2 = AppStringsScope.of(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message ?? (s2?.deletePostFailed ?? 'Failed to delete post')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(s?.yes ?? 'Yes', style: const TextStyle(color: Colors.red)),
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
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);

    if (_isLoadingPost && _post == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_postError != null && _post == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _postError!,
                style: const TextStyle(color: Color(0xFF666666), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loadPost,
                  child: Text(s?.retry ?? 'Retry'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final post = _post!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Creator stats panel (own posts only)
                if (post.userId == widget.currentUserId && _earnings != null)
                  _CreatorStatsPanel(earnings: _earnings!, post: post),
                _DoubleTapLikeWrapper(
                  showHeart: _showHeartAnimation,
                  onDoubleTap: _onDoubleTapLike,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _commentsError!,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
            ),
          ),
        if (_comments.isEmpty && !_isLoadingComments && _commentsError == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Text(
              s?.noCommentsYet ?? 'No comments yet. Be the first to comment.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          )
        else ...[
          // Pinned comments first (with their reply threads)
          for (final pinned in pinnedComments)
            _buildCommentThread(pinned, isPinned: true),
          // Regular top-level comments with threads
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: regularComments.length + (_hasMoreComments && _isLoadingComments ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == regularComments.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return _buildCommentThread(regularComments[index]);
            },
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
                      child: CircularProgressIndicator(strokeWidth: 1.5),
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

  Widget _buildCommentInput(Post post, AppStrings? s) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
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
              Material(
                color: const Color(0xFF1A1A1A),
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
                        : const Icon(Icons.send, color: Colors.white, size: 22),
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
      duration: const Duration(milliseconds: 800),
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
                        color: comment.isLiked ? Colors.red : Colors.grey.shade400,
                      ),
                      if (comment.likesCount > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatCount(comment.likesCount),
                          style: TextStyle(
                            fontSize: 11,
                            color: comment.isLiked ? Colors.red : Colors.grey.shade400,
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

// ═══════════════════════════════════════════════════════════════════════
// Creator Stats Panel — shown above own posts with earnings & engagement
// ═══════════════════════════════════════════════════════════════════════

class _CreatorStatsPanel extends StatelessWidget {
  final PostEarningsResult earnings;
  final Post post;

  const _CreatorStatsPanel({required this.earnings, required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 1),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Earnings headline
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${earnings.currency} ${_formatAmount(earnings.estimatedEarnings)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'estimated earnings',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF999999),
                ),
              ),
              const Spacer(),
              // Badges
              if (post.isTrending)
                _badge('Trending', const Color(0xFFFF6B00)),
              if (post.isViral)
                Padding(
                  padding: EdgeInsets.only(left: post.isTrending ? 4 : 0),
                  child: _badge('Viral', const Color(0xFFE91E63)),
                ),
              if (post.isFeatured)
                Padding(
                  padding: EdgeInsets.only(left: (post.isTrending || post.isViral) ? 4 : 0),
                  child: _badge('Featured', const Color(0xFF2196F3)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Engagement stats row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statChip(Icons.visibility_outlined, _formatCount(post.viewsCount), 'Views'),
                const SizedBox(width: 6),
                _statChip(Icons.favorite_outline, _formatCount(post.likesCount), 'Likes'),
                const SizedBox(width: 6),
                _statChip(Icons.chat_bubble_outline, _formatCount(post.commentsCount), 'Comments'),
                const SizedBox(width: 6),
                _statChip(Icons.repeat_rounded, _formatCount(post.sharesCount), 'Shares'),
                const SizedBox(width: 6),
                _statChip(Icons.bookmark_outline, _formatCount(post.savesCount), 'Saves'),
                if (post.watchTimeSeconds > 0) ...[
                  const SizedBox(width: 6),
                  _statChip(Icons.timer_outlined, _formatDuration(post.watchTimeSeconds), 'Watch'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Performance row
          Row(
            children: [
              _performancePill(
                'Engagement',
                '${earnings.engagementRate.toStringAsFixed(1)}%',
              ),
              const SizedBox(width: 8),
              _performancePill(
                'Reach',
                _formatCount(earnings.impressions),
              ),
            ],
          ),
          // Earnings breakdown (expandable)
          const SizedBox(height: 8),
          _EarningsBreakdown(earnings: earnings),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF666666)),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  Widget _performancePill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  String _formatDuration(int seconds) {
    if (seconds >= 3600) {
      return '${(seconds / 3600).toStringAsFixed(1)}h';
    } else if (seconds >= 60) {
      return '${(seconds / 60).toStringAsFixed(0)}m';
    }
    return '${seconds}s';
  }
}

/// Expandable earnings breakdown showing per-metric contributions.
class _EarningsBreakdown extends StatefulWidget {
  final PostEarningsResult earnings;
  const _EarningsBreakdown({required this.earnings});

  @override
  State<_EarningsBreakdown> createState() => _EarningsBreakdownState();
}

class _EarningsBreakdownState extends State<_EarningsBreakdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Text(
                  'Earnings breakdown',
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: const Color(0xFF666666),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 4),
          _row('Views', widget.earnings.views),
          _row('Likes', widget.earnings.likes),
          _row('Comments', widget.earnings.comments),
          _row('Shares', widget.earnings.shares),
          _row('Saves', widget.earnings.saves),
          if (widget.earnings.watchTime.count > 0)
            _row('Watch time', widget.earnings.watchTime),
        ],
      ],
    );
  }

  Widget _row(String label, EarningsMetric metric) {
    if (metric.count == 0 && metric.amount == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
          ),
          Text(
            '${metric.count} × ${widget.earnings.currency} ${metric.rate}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
          ),
          const Spacer(),
          Text(
            '${widget.earnings.currency} ${metric.amount.toStringAsFixed(1)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}
