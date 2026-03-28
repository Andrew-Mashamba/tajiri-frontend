import 'package:flutter/material.dart';
import '../../models/gossip_models.dart';
import '../../models/post_models.dart';
import '../../services/gossip_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/event_tracking_service.dart';
import '../../services/post_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/share_post_sheet.dart';
import '../../l10n/app_strings_scope.dart';
import 'comment_bottom_sheet.dart';
import '../search/hashtag_screen.dart';
import '../search/search_screen.dart';
import '../wallet/subscribe_to_creator_screen.dart';

/// Full-screen view of a gossip thread showing the seed post and related posts.
class ThreadViewerScreen extends StatefulWidget {
  final int threadId;
  final int currentUserId;
  final List<int>? threadIds;

  const ThreadViewerScreen({
    super.key,
    required this.threadId,
    required this.currentUserId,
    this.threadIds,
  });

  @override
  State<ThreadViewerScreen> createState() => _ThreadViewerScreenState();
}

class _ThreadViewerScreenState extends State<ThreadViewerScreen> {
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    if (widget.threadIds != null && widget.threadIds!.length > 1) {
      final initialIndex = widget.threadIds!.indexOf(widget.threadId).clamp(0, widget.threadIds!.length - 1);
      _pageController = PageController(initialPage: initialIndex);
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Single thread mode (no threadIds or single item)
    if (widget.threadIds == null || widget.threadIds!.length <= 1) {
      return _SingleThreadView(
        threadId: widget.threadId,
        currentUserId: widget.currentUserId,
      );
    }

    // Multi-thread swipe mode
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.threadIds!.length,
        itemBuilder: (context, index) {
          return _SingleThreadView(
            threadId: widget.threadIds![index],
            currentUserId: widget.currentUserId,
          );
        },
      ),
    );
  }
}

/// Self-contained view for a single gossip thread. Used both standalone
/// and as a page inside the swipeable PageView.
class _SingleThreadView extends StatefulWidget {
  final int threadId;
  final int currentUserId;

  const _SingleThreadView({
    required this.threadId,
    required this.currentUserId,
  });

  @override
  State<_SingleThreadView> createState() => _SingleThreadViewState();
}

class _SingleThreadViewState extends State<_SingleThreadView> {
  final GossipService _gossipService = GossipService();
  final PostService _postService = PostService();
  GossipThreadDetail? _detail;
  bool _loading = true;
  String? _error;

  // Tracks in-flight like/save requests to prevent double-taps
  final Set<int> _likingPostIds = {};
  final Set<int> _savingPostIds = {};

  @override
  void initState() {
    super.initState();
    _loadThread();
    _trackView();
  }

  Future<void> _trackView() async {
    final tracker = await EventTrackingService.getInstance();
    tracker.trackEvent(
      eventType: 'view',
      postId: 0,
      creatorId: 0,
      metadata: {'thread_id': widget.threadId},
    );
  }

  Future<void> _loadThread() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        setState(() {
          _error = 'Not authenticated';
          _loading = false;
        });
        return;
      }
      final detail = await _gossipService.getThread(
        token: token,
        threadId: widget.threadId,
      );
      if (mounted) {
        setState(() {
          _detail = detail;
          _loading = false;
          if (detail == null) _error = 'Thread not found';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _loading = false;
        });
      }
    }
  }

  // ─── Action helpers ────────────────────────────────────────────────

  void _updatePost(Post updated) {
    final posts = _detail?.posts;
    if (posts == null) return;
    final idx = posts.indexWhere((p) => p.id == updated.id);
    if (idx >= 0 && mounted) {
      setState(() {
        final newPosts = List<Post>.from(posts);
        newPosts[idx] = updated;
        _detail = GossipThreadDetail(thread: _detail!.thread, posts: newPosts);
      });
    }
  }

  Future<void> _onLike(Post post) async {
    if (_likingPostIds.contains(post.id)) return;
    _likingPostIds.add(post.id);
    final wasLiked = post.isLiked;
    _updatePost(post.copyWith(
      isLiked: !wasLiked,
      likesCount: wasLiked ? post.likesCount - 1 : post.likesCount + 1,
    ));

    final result = wasLiked
        ? await _postService.unlikePost(post.id, widget.currentUserId)
        : await _postService.likePost(post.id, widget.currentUserId);

    _likingPostIds.remove(post.id);
    if (!mounted) return;
    if (!result.success) {
      _updatePost(post); // revert
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.likeUpdateFailed ?? 'Failed to update like')),
      );
    } else if (result.likesCount != null) {
      final posts = _detail?.posts;
      if (posts != null) {
        final idx = posts.indexWhere((p) => p.id == post.id);
        if (idx >= 0) {
          _updatePost(posts[idx].copyWith(likesCount: result.likesCount!));
        }
      }
    }
  }

  Future<void> _onReaction(Post post, ReactionType reaction) async {
    _updatePost(post.copyWith(
      isLiked: true,
      likesCount: post.isLiked ? post.likesCount : post.likesCount + 1,
    ));

    final result = await _postService.likePost(
      post.id,
      widget.currentUserId,
      reactionType: reaction.name,
    );

    if (!mounted) return;
    if (!result.success) {
      _updatePost(post);
    } else if (result.likesCount != null) {
      final posts = _detail?.posts;
      if (posts != null) {
        final idx = posts.indexWhere((p) => p.id == post.id);
        if (idx >= 0) {
          _updatePost(posts[idx].copyWith(likesCount: result.likesCount!));
        }
      }
    }
  }

  void _onComment(Post post) {
    CommentBottomSheet.show(
      context,
      postId: post.id,
      currentUserId: widget.currentUserId,
      initialPost: post,
      onCommentsCountUpdated: (newCount) {
        final posts = _detail?.posts;
        if (posts == null) return;
        final idx = posts.indexWhere((p) => p.id == post.id);
        if (idx >= 0 && mounted) {
          _updatePost(posts[idx].copyWith(commentsCount: newCount));
        }
      },
    );
  }

  void _onShare(Post post) {
    showSharePostBottomSheet(
      context,
      post: post,
      userId: widget.currentUserId,
      postService: _postService,
      onShared: (Post? sharedPost) {
        if (sharedPost != null) {
          final posts = _detail?.posts;
          if (posts == null) return;
          final idx = posts.indexWhere((p) => p.id == post.id);
          if (idx >= 0 && mounted) {
            _updatePost(posts[idx].copyWith(sharesCount: posts[idx].sharesCount + 1));
          }
        }
      },
    );
  }

  Future<void> _onSave(Post post) async {
    if (_savingPostIds.contains(post.id)) return;
    _savingPostIds.add(post.id);
    final wasSaved = post.isSaved;
    _updatePost(post.copyWith(
      isSaved: !wasSaved,
      savesCount: wasSaved ? post.savesCount - 1 : post.savesCount + 1,
    ));

    final result = wasSaved
        ? await _postService.unsavePost(post.id, widget.currentUserId)
        : await _postService.savePost(post.id, widget.currentUserId);

    _savingPostIds.remove(post.id);
    if (!mounted) return;
    if (!result.success) {
      _updatePost(post); // revert
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
            wasSaved
                ? (s?.removedFromSaved ?? 'Removed from saved')
                : (s?.savedSuccess ?? 'Saved'),
          ),
        ),
      );
    }
  }

  void _onUserTap(Post post) {
    Navigator.pushNamed(context, '/profile/${post.userId}');
  }

  void _onHashtagTap(String hashtag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HashtagScreen(
          hashtag: hashtag,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  void _onMentionTap(String username) {
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
  }

  // ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final isSwahili = strings?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          _detail?.thread.title(isSwahili: isSwahili) ?? strings?.trendingNow ?? 'Trending Now',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1A1A1A)),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFF666666)),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _loadThread,
                          child: Text(strings?.retry ?? 'Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadThread,
                    color: const Color(0xFF1A1A1A),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 32),
                      itemCount: (_detail?.posts.length ?? 0) + 1, // +1 for header
                      itemBuilder: (context, index) {
                        if (index == 0) return _buildHeader(strings, isSwahili);
                        final post = _detail!.posts[index - 1];
                        return PostCard(
                          post: post,
                          currentUserId: widget.currentUserId,
                          onTap: () {
                            Navigator.pushNamed(context, '/post/${post.id}');
                          },
                          onLike: () => _onLike(post),
                          onComment: () => _onComment(post),
                          onShare: () => _onShare(post),
                          onSave: () => _onSave(post),
                          onUserTap: () => _onUserTap(post),
                          onHashtagTap: _onHashtagTap,
                          onMentionTap: _onMentionTap,
                          onThreadTap: post.threadId != null
                              ? () => Navigator.pushNamed(context, '/thread/${post.threadId}')
                              : null,
                          onReaction: (reaction) => _onReaction(post, reaction),
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
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader(AppStrings? strings, bool isSwahili) {
    final thread = _detail!.thread;
    final postsLabel = strings?.threadPosts ?? 'Posts';
    final participantsLabel = strings?.threadParticipants ?? 'Participants';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category + velocity row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  thread.category.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.local_fire_department_rounded,
                size: 16,
                color: Color(0xFF666666),
              ),
              const SizedBox(width: 4),
              Text(
                thread.velocityScore.toStringAsFixed(0),
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              const Icon(Icons.article_outlined, size: 14, color: Color(0xFF999999)),
              const SizedBox(width: 4),
              Text(
                '${thread.postCount} $postsLabel',
                style: const TextStyle(color: Color(0xFF999999), fontSize: 13),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.people_outline_rounded,
                size: 14,
                color: Color(0xFF999999),
              ),
              const SizedBox(width: 4),
              Text(
                '${thread.participantCount} $participantsLabel',
                style: const TextStyle(color: Color(0xFF999999), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFE0E0E0)),
        ],
      ),
    );
  }
}
