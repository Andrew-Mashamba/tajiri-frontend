import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import '../../models/post_models.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/story_models.dart';
import '../../services/feed_service.dart';
import '../../services/post_service.dart';
import '../../services/media_cache_service.dart';
import '../../services/story_service.dart';
import 'package:heroicons/heroicons.dart';
import '../../widgets/post_card.dart';
import '../../widgets/share_post_sheet.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../clips/streams_screen.dart';
import '../clips/storyviewer_screen.dart';
import '../clips/createstory_screen.dart';
import 'comment_bottom_sheet.dart';
import 'edit_post_screen.dart';
import 'full_screen_post_viewer_screen.dart';
import '../../services/live_update_service.dart';

/// Estimated height for a typical post card (used for scroll optimization)
const double _kEstimatedPostHeight = 450.0;

/// Stories row fixed height (matches _buildStoriesRow)
const double _kStoriesRowHeight = 100.0;

/// Loading indicator slot height
const double _kLoadingSlotHeight = 80.0;

/// How far ahead to preload media (in pixels)
const double _kPreloadDistance = 1500.0;

/// Cache extent for smooth scrolling (prebuild offscreen items; ~2 viewports)
const double _kCacheExtent = 1600.0;

class FeedScreen extends StatefulWidget {
  final int currentUserId;

  const FeedScreen({super.key, required this.currentUserId});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  final FeedService _feedService = FeedService();
  final PostService _postService = PostService();
  final MediaCacheService _cacheService = MediaCacheService();
  late TabController _tabController;

  // Use a separate scroll controller for each tab to preserve scroll position
  final Map<int, ScrollController> _scrollControllers = {};
  ScrollController get _scrollController {
    final index = _tabController.index;
    _scrollControllers[index] ??= ScrollController()..addListener(_onScroll);
    return _scrollControllers[index]!;
  }

  // Feed types: posts (tab 0), friends (tab 1), live (tab 2)
  String _currentFeedType = 'posts';

  // Use a map to cache posts per feed type
  final Map<String, List<Post>> _postsCache = {};
  List<Post> get _posts => _postsCache[_currentFeedType] ?? [];
  set _posts(List<Post> value) => _postsCache[_currentFeedType] = value;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  // Track visible items for media preloading
  int _firstVisibleIndex = 0;
  int _lastVisibleIndex = 0;

  // Story 51: View Stories — stories row at top of feed
  final StoryService _storyService = StoryService();
  List<StoryGroup> _storyGroups = [];
  bool _storiesLoading = false;

  StreamSubscription<LiveUpdateEvent>? _liveUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadFeed();
    _loadStories();
    // Initialize first scroll controller
    _scrollControllers[0] = ScrollController()..addListener(_onScroll);
    _liveUpdateSubscription = LiveUpdateService.instance.stream.listen((event) {
      if (!mounted) return;
      if (event is FeedUpdateEvent) {
        _loadFeed();
        if (_currentFeedType == 'friends') _loadStories();
      } else if (event is StoriesUpdateEvent) {
        _loadStories();
      }
    });
  }

  @override
  void dispose() {
    _liveUpdateSubscription?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    final feedTypes = ['posts', 'friends', 'live'];
    final newType = feedTypes[_tabController.index];

    if (newType != _currentFeedType) {
      setState(() {
        _currentFeedType = newType;
        _currentPage = 1;
        _hasMore = true;
      });
      // Only load if no cached posts for this feed type
      if (_posts.isEmpty) {
        _loadFeed();
      } else {
        setState(() => _isLoading = false);
      }
      if (newType == 'posts' || newType == 'friends') {
        _loadStories();
      }
    }
  }

  Future<void> _loadStories() async {
    if (_storiesLoading) return;
    setState(() => _storiesLoading = true);
    final result = await _storyService.getStories(
      currentUserId: widget.currentUserId,
    );
    if (!mounted) return;
    setState(() {
      _storiesLoading = false;
      _storyGroups = result.success ? result.groups : [];
    });
  }

  void _openStoryViewer(StoryGroup group) {
    if (_storyGroups.isEmpty) return;
    final index = _storyGroups.indexOf(group);
    if (index < 0) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerScreen(
          storyGroups: _storyGroups,
          initialGroupIndex: index,
          currentUserId: widget.currentUserId,
        ),
      ),
    ).then((_) {
      if (mounted) _loadStories();
    });
  }

  void _openCreateStory() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateStoryScreen(userId: widget.currentUserId),
      ),
    ).then((_) {
      if (mounted) _loadStories();
    });
  }

  Widget _buildAddStoryTile(BuildContext context, double rowHeight, double avatarSize, double minTapSize) {
    final s = AppStringsScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openCreateStory,
          borderRadius: BorderRadius.circular(avatarSize / 2 + 8),
          child: SizedBox(
            width: avatarSize + 24,
            height: rowHeight - 16,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: avatarSize + 4,
                  height: avatarSize + 4,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                  ),
                  child: Icon(Icons.add, size: 28, color: const Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    s?.addButton ?? 'Add',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onScroll() {
    final controller = _scrollController;
    if (!controller.hasClients) return;

    // Pagination trigger
    if (controller.position.pixels >= controller.position.maxScrollExtent - 500) {
      _loadMore();
    }

    // Preload media for items coming into view
    _preloadVisibleMedia();
  }

  /// Preload media for posts that are about to come into view
  void _preloadVisibleMedia() {
    if (_posts.isEmpty) return;

    final controller = _scrollController;
    if (!controller.hasClients) return;

    final scrollPosition = controller.position.pixels;
    final viewportHeight = controller.position.viewportDimension;

    // Calculate visible range with preload buffer
    final startPixel = scrollPosition - _kPreloadDistance;
    final endPixel = scrollPosition + viewportHeight + _kPreloadDistance;

    // Estimate which items are in range
    final startIndex = (startPixel / _kEstimatedPostHeight).floor().clamp(0, _posts.length - 1);
    final endIndex = (endPixel / _kEstimatedPostHeight).ceil().clamp(0, _posts.length - 1);

    // Only preload if range changed
    if (startIndex != _firstVisibleIndex || endIndex != _lastVisibleIndex) {
      _firstVisibleIndex = startIndex;
      _lastVisibleIndex = endIndex;

      // Schedule preloading to avoid blocking scroll
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _preloadMediaForRange(startIndex, endIndex);
      });
    }
  }

  /// Preload media URLs for posts in range
  void _preloadMediaForRange(int start, int end) {
    final mediaUrls = <String>[];

    for (int i = start; i <= end && i < _posts.length; i++) {
      final post = _posts[i];

      // Collect all media URLs from this post
      for (final media in post.media) {
        if (media.thumbnailUrl != null) {
          mediaUrls.add(media.thumbnailUrl!);
        }
        // For videos, preload thumbnail first, then video
        if (media.mediaType == MediaType.video && media.fileUrl.isNotEmpty) {
          mediaUrls.add(media.fileUrl);
        }
        // For images, preload the image
        if (media.mediaType == MediaType.image && media.fileUrl.isNotEmpty) {
          mediaUrls.add(media.fileUrl);
        }
      }

      // Audio posts
      if (post.audioPath != null && post.audioPath!.isNotEmpty) {
        mediaUrls.add(post.audioUrl!);
      }
    }

    // Preload in background
    if (mediaUrls.isNotEmpty) {
      _cacheService.preloadMediaList(mediaUrls);
    }
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _feedService.getFeed(
      userId: widget.currentUserId,
      page: 1,
      feedType: _currentFeedType,
    );

    setState(() {
      _isLoading = false;
      if (result.success) {
        _posts = result.posts;
        _currentPage = 1;
        _hasMore = result.meta?.hasMore ?? false;
      } else {
        _error = result.message;
      }
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final result = await _feedService.getFeed(
      userId: widget.currentUserId,
      page: _currentPage + 1,
      feedType: _currentFeedType,
    );

    setState(() {
      _isLoadingMore = false;
      if (result.success) {
        _posts.addAll(result.posts);
        _currentPage++;
        _hasMore = result.meta?.hasMore ?? false;
      }
    });
  }

  Future<void> _onLike(Post post) async {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;

    final wasLiked = post.isLiked;

    // Optimistic update
    setState(() {
      _posts[index] = post.copyWith(
        isLiked: !wasLiked,
        likesCount: wasLiked ? post.likesCount - 1 : post.likesCount + 1,
      );
    });

    final result = wasLiked
        ? await _postService.unlikePost(post.id, widget.currentUserId)
        : await _postService.likePost(post.id, widget.currentUserId);

    if (!result.success) {
      // Revert on failure
      setState(() {
        _posts[index] = post;
      });
    } else if (result.likesCount != null) {
      // Sync with server likes_count
      setState(() {
        _posts[index] = _posts[index].copyWith(likesCount: result.likesCount!);
      });
    }
  }

  Future<void> _onSave(Post post) async {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;

    final wasSaved = post.isSaved;

    setState(() {
      _posts[index] = post.copyWith(
        isSaved: !wasSaved,
        savesCount: wasSaved ? post.savesCount - 1 : post.savesCount + 1,
      );
    });

    final result = wasSaved
        ? await _postService.unsavePost(post.id, widget.currentUserId)
        : await _postService.savePost(post.id, widget.currentUserId);

    if (!mounted) return;
    if (!result.success) {
      setState(() => _posts[index] = post);
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

  void _onComment(Post post) {
    CommentBottomSheet.show(
      context,
      postId: post.id,
      currentUserId: widget.currentUserId,
      initialPost: post,
      onCommentsCountUpdated: (newCount) {
        final idx = _posts.indexWhere((p) => p.id == post.id);
        if (idx >= 0 && mounted) {
          setState(() {
            _posts[idx] = _posts[idx].copyWith(commentsCount: newCount);
          });
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
        if (sharedPost != null && mounted) {
          setState(() {
            final list = List<Post>.from(_posts);
            list.insert(0, sharedPost);
            _posts = list;
          });
        }
      },
    );
  }

  void _onUserTap(Post post) {
    Navigator.pushNamed(context, '/profile/${post.userId}');
  }

  void _onMenuTap(Post post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(AppStringsScope.of(context)?.edit ?? 'Edit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push<Post>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditPostScreen(post: post),
                  ),
                ).then((updated) {
                  if (updated != null && mounted) {
                    final index = _posts.indexWhere((p) => p.id == updated.id);
                    if (index != -1) {
                      setState(() {
                        _posts[index] = updated;
                      });
                    }
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(AppStringsScope.of(context)?.delete ?? 'Delete', style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(post);
              },
            ),
          ],
        ),
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
              final result = await _postService.deletePost(post.id);
              if (!mounted) return;
              if (result.success) {
                setState(() => _posts.removeWhere((p) => p.id == post.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s?.postDeleted ?? 'Post deleted')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(s?.deletePostFailed ?? 'Failed to delete post'),
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

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: TajiriAppBar(
        title: s?.appName ?? 'Tajiri',
        automaticallyImplyLeading: false,
        actions: [
          TajiriAppBar.action(
            icon: HeroIcons.bookmark,
            tooltip: s?.savedTooltip ?? 'Saved',
            onPressed: () => Navigator.pushNamed(context, '/saved-posts'),
          ),
          TajiriAppBar.action(
            icon: HeroIcons.magnifyingGlass,
            tooltip: s?.search ?? 'Search',
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
          TajiriAppBar.action(
            icon: HeroIcons.bell,
            tooltip: s?.notifications ?? 'Notifications',
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
        bottom: _FeedTabBar(
          controller: _tabController,
          labels: [
            s?.postsTab ?? 'Posts',
            s?.friendsFeed ?? 'Friends',
            s?.live ?? 'Live',
          ],
        ),
      ),
      body: SafeArea(child: _buildBody(s)),
    );
  }

  Widget _buildBody(AppStrings? s) {
    // Story 89: Feed Live tab → StreamsScreen (browse live streams, Live/All tabs, Go Live FAB)
    if (_currentFeedType == 'live') {
      return StreamsScreen(currentUserId: widget.currentUserId);
    }

    // Regular feed content for 'posts' and 'friends' tabs
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1A1A1A),
          strokeWidth: 2,
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState(s);
    }

    if (_posts.isEmpty) {
      return _buildEmptyState(s);
    }

    // Instagram-style: ListView for both Posts and Friends (no snapping in feed)
    // Stories row only on Friends tab
    final showStoriesRow =
        _currentFeedType == 'friends' &&
        (_storyGroups.isNotEmpty || _storiesLoading);
    final storiesSlot = showStoriesRow ? 1 : 0;
    final postCount = _posts.length;
    final loadingSlot = _hasMore ? 1 : 0;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadFeed();
        if (showStoriesRow) await _loadStories();
      },
      child: ListView.builder(
        controller: _scrollController,
        key: PageStorageKey<String>('feed_$_currentFeedType'),
        cacheExtent: _kCacheExtent,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemExtentBuilder: (int index, SliverLayoutDimensions dimensions) {
          if (index == 0 && showStoriesRow) return _kStoriesRowHeight;
          final postIndex = index - storiesSlot;
          if (postIndex >= postCount) return _kLoadingSlotHeight;
          return _kEstimatedPostHeight;
        },
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        addSemanticIndexes: false,
        itemCount: storiesSlot + postCount + loadingSlot,
        itemBuilder: (context, index) {
          if (index == 0 && showStoriesRow) {
            return _buildStoriesRow(context);
          }
          final postIndex = index - storiesSlot;
          if (postIndex >= postCount) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1A1A1A),
                  strokeWidth: 2,
                ),
              ),
            );
          }

          final post = _posts[postIndex];
          return RepaintBoundary(
            key: ValueKey('post_${post.id}'),
            child: PostCard(
              key: ValueKey('postcard_${post.id}'),
              post: post,
              currentUserId: widget.currentUserId,
              onTap: () => _openFullScreenPostViewer(post),
              onLike: () => _onLike(post),
              onComment: () => _onComment(post),
              onShare: () => _onShare(post),
              onSave: () => _onSave(post),
              onUserTap: () => _onUserTap(post),
              onMenuTap: () => _onMenuTap(post),
            ),
          );
        },
      ),
    );
  }

  void _openFullScreenPostViewer(Post post) {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index < 0) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FullScreenPostViewerScreen(
          posts: List<Post>.from(_posts),
          initialIndex: index,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  /// DESIGN.md: empty state — tertiary icon, bodySmall/caption typography.
  /// Posts tab: no posts / follow people. Friends tab: no posts from friends / add friends.
  Widget _buildEmptyState(AppStrings? s) {
    final isFriendsTab = _currentFeedType == 'friends';
    final title = isFriendsTab
        ? (s?.noPostsFromFriends ?? 'No posts from friends')
        : (s?.noPosts ?? 'No posts');
    final subtitle = isFriendsTab
        ? (s?.friendsFeedEmptyHint ?? 'Add friends to see their posts here')
        : (s?.followPeopleHint ?? 'Follow people to see their posts');
    final icon = isFriendsTab ? HeroIcons.users : HeroIcons.newspaper;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HeroIcon(
              icon,
              style: HeroIconStyle.outline,
              size: 64,
              color: const Color(0xFF999999),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// DESIGN.md: error state — retry with primary styling.
  Widget _buildErrorState(AppStrings? s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HeroIcon(
              HeroIcons.exclamationTriangle,
              style: HeroIconStyle.outline,
              size: 64,
              color: const Color(0xFF999999),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: TextButton.icon(
                onPressed: _loadFeed,
                icon: HeroIcon(
                  HeroIcons.arrowPath,
                  style: HeroIconStyle.outline,
                  size: 20,
                  color: TajiriAppBar.primaryTextColor,
                ),
                label: Text(
                  s?.retry ?? 'Retry',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Story 51: Stories row at top — tap to view. Min touch target 48dp.
  Widget _buildStoriesRow(BuildContext context) {
    const double rowHeight = 100;
    const double avatarSize = 56;
    const double minTapSize = 48;

    if (_storiesLoading && _storyGroups.isEmpty) {
      return SizedBox(
        height: rowHeight,
        child: const Center(child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )),
      );
    }

    return Container(
      height: rowHeight,
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        cacheExtent: 200,
        itemCount: _storyGroups.length,
        itemBuilder: (context, index) {
          final group = _storyGroups[index];
          final hasUnviewed =
              group.stories.any((s) => !(s.hasViewed ?? false));
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openStoryViewer(group),
                borderRadius: BorderRadius.circular(avatarSize / 2 + 8),
                child: SizedBox(
                  width: avatarSize + 24,
                  height: rowHeight - 16,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: avatarSize + 4,
                        height: avatarSize + 4,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hasUnviewed
                                ? const Color(0xFF1A1A1A)
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: avatarSize / 2,
                          backgroundColor: const Color(0xFF1A1A1A),
                          backgroundImage:
                              group.user.avatarUrl.isNotEmpty
                                  ? NetworkImage(group.user.avatarUrl)
                                  : null,
                          child: group.user.avatarUrl.isEmpty
                              ? Text(
                                  group.user.firstName.isNotEmpty
                                      ? group.user.firstName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: minTapSize / 2,
                        child: Text(
                          group.user.displayName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Feed tab bar: DESIGN.md colors, Heroicons (outline/solid by state), 48dp height.
class _FeedTabBar extends StatefulWidget implements PreferredSizeWidget {
  const _FeedTabBar({
    required this.controller,
    required this.labels,
  });

  final TabController controller;
  final List<String> labels;

  static const double _kHeight = 48.0;
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const double _iconSize = 22.0;
  static const double _fontSize = 12.0;

  @override
  Size get preferredSize => const Size.fromHeight(_kHeight);

  @override
  State<_FeedTabBar> createState() => _FeedTabBarState();
}

class _FeedTabBarState extends State<_FeedTabBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _FeedTabBar._kHeight,
      child: Row(
        children: List.generate(3, (index) {
          final selected = widget.controller.index == index;
          final color = selected ? _FeedTabBar._primary : _FeedTabBar._secondary;
          final style = selected ? HeroIconStyle.solid : HeroIconStyle.outline;
          final icon = _iconFor(index, style, color);
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.controller.animateTo(index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon,
                    const SizedBox(height: 4),
                    Text(
                      widget.labels[index],
                      style: TextStyle(
                        fontSize: _FeedTabBar._fontSize,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _iconFor(int index, HeroIconStyle style, Color color) {
    switch (index) {
      case 0:
        return HeroIcon(HeroIcons.newspaper, style: style, size: _FeedTabBar._iconSize, color: color);
      case 1:
        return HeroIcon(HeroIcons.users, style: style, size: _FeedTabBar._iconSize, color: color);
      case 2:
        return HeroIcon(HeroIcons.signal, style: style, size: _FeedTabBar._iconSize, color: color);
      default:
        return const SizedBox.shrink();
    }
  }
}

