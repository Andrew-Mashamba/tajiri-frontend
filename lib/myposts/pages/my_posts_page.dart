// lib/screens/profile/posts/profile_posts_page.dart
//
// Posts grid page — the body of the `posts` tab inside the profile
// tab grid (chrome lives in _ProfileTabPage in profile_screen.dart).
// Renders a 3-column thumbnail grid with infinite scroll, prefetch,
// pinned-first ordering, and (own profile only) a header strip with
// Create / Saved / Drafts pills.
//
// Playbook compliance: monochrome, 48dp targets, no SnackBars (delete
// success is silent — list update is the confirmation; failure shows
// an AlertDialog), `_rounded` icons, `RefreshIndicator(color:#1A1A1A)`,
// dark loading spinners, FilledButton(#1A1A1A) primary CTA in empty
// state, semantic red `#D32F2F` for destructive actions.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../models/post_models.dart';
import '../../services/post_service.dart';
import '../../services/user_posts_cache_service.dart';
import '../../widgets/cached_media_image.dart';
import '../../widgets/motion_tokens.dart';
import '../../widgets/post_grid_cell.dart';
import '../../screens/feed/create_post_screen.dart';
import '../../screens/feed/edit_post_screen.dart';
import '../../screens/feed/post_detail_screen.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kDanger = Color(0xFFD32F2F);
const Color _kPillBg = Color(0xFFF0F0F0);

class MyPostsPage extends StatefulWidget {
  final int userId;
  final int currentUserId;
  final bool isOwnProfile;

  const MyPostsPage({
    super.key,
    required this.userId,
    required this.currentUserId,
    required this.isOwnProfile,
  });

  @override
  State<MyPostsPage> createState() => _ProfilePostsPageState();
}

class _ProfilePostsPageState extends State<MyPostsPage>
    with
        AutomaticKeepAliveClientMixin<MyPostsPage>,
        SingleTickerProviderStateMixin<MyPostsPage> {
  static const int _perPage = 24; // 8 rows of 3

  final PostService _postService = PostService();
  final ScrollController _scrollController = ScrollController();

  List<Post> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  double _lastScrollOffset = 0;

  // Cached layout values — recomputed in didChangeDependencies, not on
  // every scroll event. Reading MediaQuery.of(context) in a scroll
  // callback rebuilds InheritedWidget chains per frame.
  double _cellSize = 0;
  double _rowHeight = 0;
  double _cacheExtent = 0;

  // Debounces _prefetchVisibleThumbnails so it doesn't run on every
  // scroll pixel — playbook §2068 (Debounce scroll handlers).
  Timer? _prefetchDebounce;

  // Single shared shimmer animation driving every placeholder cell —
  // replaces N independent AnimationControllers.
  late final AnimationController _shimmerCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  // Keep the State alive across tab switches so a return to the Posts
  // tab doesn't re-fetch from scratch — playbook Phase 3 (lazy tabs).
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _hydrateAndRefresh();
  }

  /// Stale-while-revalidate. Layered cache → instant first paint
  /// from RAM (same session), or from disk (across cold-starts), or
  /// shimmer (first-ever visit). API fires in parallel and writes
  /// back to both layers on success.
  Future<void> _hydrateAndRefresh() async {
    final cache = UserPostsCacheService.instance;

    // 1. In-memory hit (~0ms): same-session re-visit.
    final hot = cache.getSync(widget.userId);
    if (hot != null && hot.isNotEmpty) {
      setState(() {
        _posts = hot;
        _isLoading = false;
        _page = 2; // assume more pages exist; corrected by API response
        _hasMore = true;
      });
    } else {
      // 2. Disk hit (~10-50ms): warm-from-cold.
      final cold = await cache.getCached(widget.userId);
      if (!mounted) return;
      if (cold != null && cold.isNotEmpty) {
        setState(() {
          _posts = cold;
          _isLoading = false;
          _page = 2;
          _hasMore = true;
        });
      }
    }

    // 3. Network — always fetch fresh on entry. If we already painted
    // from cache, the user sees the swap silently when this completes.
    await _loadPosts(silent: _posts.isNotEmpty);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final w = MediaQuery.of(context).size.width;
    _cellSize = (w - 2) / 3;
    _rowHeight = _cellSize + 1;
    _cacheExtent = _cellSize * 4;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _prefetchDebounce?.cancel();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  /// Prefetch next page at ~70% scroll through current content.
  /// Heavy work (thumbnail prefetch) is debounced — playbook §2068.
  void _onScroll() {
    if (_hasMore && !_isLoadingMore) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (currentScroll >= maxScroll * 0.7) {
        _loadMorePosts();
      }
    }
    _prefetchDebounce?.cancel();
    _prefetchDebounce = Timer(const Duration(milliseconds: 80), () {
      if (mounted) _prefetchVisibleThumbnails();
    });
  }

  /// Fetches page 1 from the network. When [silent] is true, leaves
  /// the existing list visible until the response arrives (used by the
  /// stale-while-revalidate hydrate path so the user never sees a
  /// "loading then content" flicker).
  Future<void> _loadPosts({bool silent = false}) async {
    setState(() {
      if (!silent) _isLoading = true;
      _page = 1;
    });

    final result = await _postService.getPosts(
      userId: widget.currentUserId,
      profileUserId: widget.userId,
      page: 1,
      perPage: _perPage,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _posts = _sortWithPinnedFirst(result.posts);
        final meta = result.meta;
        _hasMore = meta != null
            ? meta.currentPage < meta.lastPage
            : result.posts.length >= _perPage;
        _page = 2;
      }
    });

    // Persist for next hydrate (both layers).
    if (result.success) {
      UserPostsCacheService.instance.save(widget.userId, _posts);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final result = await _postService.getPosts(
      userId: widget.currentUserId,
      profileUserId: widget.userId,
      page: _page,
      perPage: _perPage,
    );

    if (!mounted) return;
    setState(() {
      _isLoadingMore = false;
      if (result.success) {
        _posts.addAll(result.posts);
        final meta = result.meta;
        _hasMore = meta != null
            ? meta.currentPage < meta.lastPage
            : result.posts.length >= _perPage;
        _page++;
      }
    });

    // Persist the appended state so a navigator pop/repush within the
    // session keeps the user's scroll-back history (in-memory layer
    // holds the full list; disk caps at 100).
    if (result.success) {
      UserPostsCacheService.instance.save(widget.userId, _posts);
    }
  }

  /// Sort posts so pinned posts (up to 3) appear first, rest reverse-chronological.
  List<Post> _sortWithPinnedFirst(List<Post> posts) {
    final pinned = posts.where((p) => p.isPinned).take(3).toList();
    final unpinned =
        posts.where((p) => !p.isPinned || !pinned.contains(p)).toList();
    return [...pinned, ...unpinned];
  }

  /// Scroll-direction-aware prefetch: prefetches thumbnails 2-3 rows
  /// ahead in the direction the user is scrolling. Lower priority than
  /// on-screen loads (handled by ImagePreloader's sequential processing).
  void _prefetchVisibleThumbnails() {
    if (!mounted || _posts.isEmpty || _cellSize <= 0) return;

    final scrollOffset = _scrollController.position.pixels;
    final viewportHeight = _scrollController.position.viewportDimension;
    final scrollingDown = scrollOffset >= _lastScrollOffset;
    _lastScrollOffset = scrollOffset;

    final rowHeight = _rowHeight; // cached cell + 1px gap

    if (scrollingDown) {
      final bottomRow = ((scrollOffset + viewportHeight) / rowHeight).ceil();
      final start = (bottomRow * 3).clamp(0, _posts.length);
      final end = ((bottomRow + 3) * 3).clamp(0, _posts.length);
      if (start >= _posts.length) return;
      final urls = <String?>[
        for (int i = start; i < end; i++) _posts[i].thumbnailUrl,
      ];
      ImagePreloader.precacheImages(context, urls);
    } else {
      final topRow = (scrollOffset / rowHeight).floor();
      final startRow = (topRow - 3).clamp(0, (_posts.length / 3).ceil());
      final endRow = topRow.clamp(0, (_posts.length / 3).ceil());
      final start = (startRow * 3).clamp(0, _posts.length);
      final end = (endRow * 3).clamp(0, _posts.length);
      if (start >= end) return;
      final urls = <String?>[
        for (int i = start; i < end; i++) _posts[i].thumbnailUrl,
      ];
      ImagePreloader.precacheImages(context, urls);
    }
  }

  // ── tap / long-press / actions ──

  void _onPostTap(Post post) {
    final index = _posts.indexWhere((p) => p.id == post.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(
          postId: post.id,
          currentUserId: widget.currentUserId,
          initialPost: post,
          posts: _posts,
          initialIndex: index >= 0 ? index : 0,
        ),
      ),
    ).then((result) {
      if (result == true && mounted) _loadPosts();
    });
  }

  void _onPostLongPress(Post post) {
    if (widget.isOwnProfile) {
      _showPostOptionsMenu(post);
    } else {
      showPostPeekPreview(context, post);
    }
  }

  void _showPostOptionsMenu(Post post) {
    final s = AppStringsScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: _kPrimary),
              title: Text(s?.edit ?? 'Edit'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _editPost(post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: _kDanger),
              title: Text(
                s?.delete ?? 'Delete',
                style: const TextStyle(color: _kDanger),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _confirmDeletePost(post);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _editPost(Post post) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditPostScreen(post: post)),
    );
    if (result == true && mounted) _loadPosts();
  }

  Future<void> _confirmDeletePost(Post post) async {
    final s = AppStringsScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(s?.deletePostConfirmTitle ?? 'Delete post'),
        content: Text(
          s?.deletePostConfirmMessage ??
              'Are you sure you want to delete this post?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(s?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(foregroundColor: _kDanger),
            child: Text(s?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      _deletePost(post);
    }
  }

  Future<void> _deletePost(Post post) async {
    final result = await _postService.deletePost(
      post.id,
      userId: widget.currentUserId,
    );
    if (!mounted) return;

    if (result.success) {
      setState(() => _posts.removeWhere((p) => p.id == post.id));
      // Mirror the deletion into the cache so the next hydrate doesn't
      // briefly show the removed post before the API confirms.
      UserPostsCacheService.instance.save(widget.userId, _posts);
      return; // silent — list update IS the confirmation per playbook §99
    }

    final s = AppStringsScope.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(
          result.message ?? s?.deletePostFailed ?? 'Failed to delete post',
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

  // ── build ──

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    if (_isLoading && _posts.isEmpty) {
      return _buildShimmerGrid(context);
    }
    if (_posts.isEmpty) {
      return _buildEmptyState(context);
    }
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _loadPosts,
      child: CustomScrollView(
        controller: _scrollController,
        cacheExtent: _cacheExtent,
        slivers: [
          if (widget.isOwnProfile)
            SliverToBoxAdapter(child: _buildPostsHeader(context)),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = _posts[index];
                return PostGridCell(
                  post: post,
                  onTap: () => _onPostTap(post),
                  onLongPress: () => _onPostLongPress(post),
                );
              },
              childCount: _posts.length,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: false,
            ),
          ),
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1.0,
      ),
      itemCount: 18, // 6 rows
      itemBuilder: (context, index) => _ShimmerCell(controller: _shimmerCtrl),
    );
  }

  Widget _buildPostsHeader(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _kBackground,
      child: Row(
        children: [
          Text(
            '${_posts.length} ${s?.post ?? 'Posts'}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          _PostsHeaderButton(
            icon: Icons.add_rounded,
            label: s?.createPost ?? 'Create post',
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CreatePostScreen(currentUserId: widget.currentUserId),
                ),
              );
              if (result == true && mounted) _loadPosts();
            },
          ),
          const SizedBox(width: 8),
          _PostsHeaderButton(
            icon: Icons.bookmark_outline_rounded,
            label: s?.savedTitle ?? 'Saved',
            onTap: () => Navigator.pushNamed(context, '/saved-posts'),
          ),
          const SizedBox(width: 8),
          _PostsHeaderButton(
            icon: Icons.edit_note_rounded,
            label: s?.drafts ?? 'Drafts',
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CreatePostScreen(currentUserId: widget.currentUserId),
                ),
              );
              if (result == true && mounted) _loadPosts();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grid_on_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            widget.isOwnProfile
                ? (s?.noPostsMe ?? "You haven't posted yet")
                : (s?.noPosts ?? 'No posts'),
            style: const TextStyle(
              fontSize: 16,
              color: _kSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.isOwnProfile) ...[
            const SizedBox(height: 8),
            Text(
              isSw
                  ? 'Shiriki picha au video yako ya kwanza'
                  : 'Share your first photo or video',
              style: const TextStyle(fontSize: 13, color: _kTertiary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreatePostScreen(currentUserId: widget.currentUserId),
                  ),
                );
                if (result == true && mounted) _loadPosts();
              },
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(s?.createPostNow ?? 'Post now'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact pill button for posts management toolbar. Minimum 48dp tap
/// target via the InkWell wrapper's parent height; visual padding is
/// the playbook §110 spec (14×8, circular(20)).
class _PostsHeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PostsHeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kPillBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: _kPrimary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated shimmer placeholder cell for loading grid. Consumes a
/// shared [AnimationController] so the whole 18-cell shimmer grid
/// runs on a single ticker (was 18 — playbook §2092 RepaintBoundary
/// + perf best practices). Suppresses animation when the OS has
/// reduce-motion enabled.
class _ShimmerCell extends StatelessWidget {
  final Animation<double> controller;
  const _ShimmerCell({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (MotionTokens.reduced(context)) {
      return Container(color: Colors.grey.shade200);
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // controller.value goes 0→1; map to a curve and into the
        // grey200..grey300 band.
        final t = Curves.easeInOut.transform(controller.value);
        return Container(
          color: Color.lerp(
            Colors.grey.shade200,
            Colors.grey.shade300,
            t,
          ),
        );
      },
    );
  }
}
