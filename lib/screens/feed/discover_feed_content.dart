// Discover Feed (Story 29): trending and recommended content
// Navigation: Home → Feed → Tab [Discover] → Events (Story 90)
// Design: DOCS/DESIGN.md (layout, touch targets 48dp min, colors)
// APIs: GET /api/feed/discover, GET /api/feed/trending, GET /api/feed/nearby

import 'package:flutter/material.dart';
import '../../models/post_models.dart';
import '../../services/feed_service.dart';
import '../../services/post_service.dart';
import '../../widgets/post_card.dart';
import '../groups/events_screen.dart';
import 'comment_bottom_sheet.dart';
import 'edit_post_screen.dart';
import 'post_detail_screen.dart';

/// Section type for the Discover tab
enum DiscoverSection {
  discover,
  trending,
  nearby,
}

/// Content for the Discover tab: discover (recommended), trending, and nearby.
/// Uses GET /api/feed/discover, /api/feed/trending, /api/feed/nearby.
class DiscoverFeedContent extends StatefulWidget {
  final int currentUserId;

  const DiscoverFeedContent({super.key, required this.currentUserId});

  @override
  State<DiscoverFeedContent> createState() => _DiscoverFeedContentState();
}

class _DiscoverFeedContentState extends State<DiscoverFeedContent> {
  final FeedService _feedService = FeedService();
  final PostService _postService = PostService();

  List<Post> _discoverPosts = [];
  List<Post> _trendingPosts = [];
  List<Post> _nearbyPosts = [];

  bool _loadingDiscover = true;
  bool _loadingTrending = true;
  bool _loadingNearby = true;

  String? _errorDiscover;
  String? _errorTrending;
  String? _errorNearby;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loadingDiscover = true;
      _loadingTrending = true;
      _loadingNearby = true;
      _errorDiscover = null;
      _errorTrending = null;
      _errorNearby = null;
    });

    await Future.wait([
      _loadDiscover(),
      _loadTrending(),
      _loadNearby(),
    ]);
  }

  Future<void> _loadDiscover() async {
    final result = await _feedService.getDiscoverFeed(
      userId: widget.currentUserId,
      page: 1,
      perPage: 20,
    );
    if (!mounted) return;
    setState(() {
      _loadingDiscover = false;
      if (result.success) {
        _discoverPosts = result.posts;
        _errorDiscover = null;
      } else {
        _errorDiscover = result.message ?? 'Imeshindwa kupakia';
      }
    });
  }

  Future<void> _loadTrending() async {
    final result = await _feedService.getTrendingFeed(
      userId: widget.currentUserId,
      page: 1,
      perPage: 20,
    );
    if (!mounted) return;
    setState(() {
      _loadingTrending = false;
      if (result.success) {
        _trendingPosts = result.posts;
        _errorTrending = null;
      } else {
        _errorTrending = result.message ?? 'Imeshindwa kupakia';
      }
    });
  }

  Future<void> _loadNearby() async {
    final result = await _feedService.getNearbyFeed(
      userId: widget.currentUserId,
      page: 1,
      perPage: 20,
    );
    if (!mounted) return;
    setState(() {
      _loadingNearby = false;
      if (result.success) {
        _nearbyPosts = result.posts;
        _errorNearby = null;
      } else {
        _errorNearby = result.message ?? 'Imeshindwa kupakia';
      }
    });
  }

  void _onLike(Post post, DiscoverSection section) {
    final list = _listForSection(section);
    final index = list.indexWhere((p) => p.id == post.id);
    if (index == -1) return;
    final wasLiked = post.isLiked;
    setState(() {
      _updateList(section, index, post.copyWith(
        isLiked: !wasLiked,
        likesCount: wasLiked ? post.likesCount - 1 : post.likesCount + 1,
      ));
    });
    final result = wasLiked
        ? _postService.unlikePost(post.id, widget.currentUserId)
        : _postService.likePost(post.id, widget.currentUserId);
    result.then((r) {
      if (!mounted) return;
      if (!r.success) {
        setState(() => _updateList(section, index, post));
      } else if (r.likesCount != null) {
        setState(() {
          final current = _listForSection(section);
          if (index < current.length) {
            _updateList(section, index, current[index].copyWith(likesCount: r.likesCount!));
          }
        });
      }
    });
  }

  void _onComment(Post post, DiscoverSection section) {
    CommentBottomSheet.show(
      context,
      postId: post.id,
      currentUserId: widget.currentUserId,
      initialPost: post,
      onCommentsCountUpdated: (newCount) {
        final list = _listForSection(section);
        final idx = list.indexWhere((p) => p.id == post.id);
        if (idx >= 0 && mounted) {
          setState(() {
            _updateList(section, idx, list[idx].copyWith(commentsCount: newCount));
          });
        }
      },
    );
  }

  void _onShare(Post post) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('Shiriki kwenye ukuta wako'),
              onTap: () {
                Navigator.pop(ctx);
                _postService.sharePost(post.id, widget.currentUserId).then((r) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(r.success ? 'Umeshiriki chapisho' : 'Imeshindwa kushiriki')),
                    );
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Nakili kiungo'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSave(Post post, DiscoverSection section) async {
    final list = _listForSection(section);
    final index = list.indexWhere((p) => p.id == post.id);
    if (index == -1) return;
    final wasSaved = post.isSaved;
    setState(() {
      _updateList(section, index, post.copyWith(
        isSaved: !wasSaved,
        savesCount: wasSaved ? post.savesCount - 1 : post.savesCount + 1,
      ));
    });
    final result = wasSaved
        ? await _postService.unsavePost(post.id, widget.currentUserId)
        : await _postService.savePost(post.id, widget.currentUserId);
    if (!mounted) return;
    if (!result.success) {
      setState(() => _updateList(section, index, post));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kusasisha hifadhi')),
      );
    }
  }

  void _openPostDetail(Post post, DiscoverSection section) {
    Navigator.push<int?>(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(
          postId: post.id,
          currentUserId: widget.currentUserId,
          initialPost: post,
        ),
      ),
    ).then((deletedPostId) {
      if (!mounted) return;
      if (deletedPostId != null) {
        setState(() {
          _discoverPosts.removeWhere((p) => p.id == deletedPostId);
          _trendingPosts.removeWhere((p) => p.id == deletedPostId);
          _nearbyPosts.removeWhere((p) => p.id == deletedPostId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chapisho limefutwa')),
        );
        return;
      }
      final list = _listForSection(section);
      final idx = list.indexWhere((p) => p.id == post.id);
      if (idx == -1) return;
      _postService.getPost(post.id, currentUserId: widget.currentUserId).then((r) {
        if (mounted && r.success && r.post != null) {
          setState(() => _updateList(section, idx, r.post!));
        }
      });
    });
  }

  void _onUserTap(Post post) {
    Navigator.pushNamed(context, '/profile/${post.userId}');
  }

  void _onMenuTap(Post post, DiscoverSection section) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (post.userId == widget.currentUserId) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Hariri'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push<Post>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditPostScreen(post: post),
                    ),
                  ).then((updated) {
                    if (updated != null && mounted) {
                      final list = _listForSection(section);
                      final idx = list.indexWhere((p) => p.id == updated.id);
                      if (idx != -1) {
                        setState(() => _updateList(section, idx, updated));
                      }
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Futa', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(post, section);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Post post, DiscoverSection section) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Futa Chapisho'),
        content: const Text('Una uhakika unataka kufuta chapisho hili?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hapana'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await _postService.deletePost(post.id);
              if (!mounted) return;
              if (success) {
                setState(() {
                  _discoverPosts.removeWhere((p) => p.id == post.id);
                  _trendingPosts.removeWhere((p) => p.id == post.id);
                  _nearbyPosts.removeWhere((p) => p.id == post.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chapisho limefutwa')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Imeshindwa kufuta chapisho'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Ndio', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  static const double _minTouchTarget = 48.0;

  Widget _buildDiscoverShortcut({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: _minTouchTarget,
            minWidth: _minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
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

  List<Post> _listForSection(DiscoverSection section) {
    switch (section) {
      case DiscoverSection.discover:
        return _discoverPosts;
      case DiscoverSection.trending:
        return _trendingPosts;
      case DiscoverSection.nearby:
        return _nearbyPosts;
    }
  }

  void _updateList(DiscoverSection section, int index, Post post) {
    switch (section) {
      case DiscoverSection.discover:
        if (index < _discoverPosts.length) {
          _discoverPosts = List.from(_discoverPosts)..[index] = post;
        }
        break;
      case DiscoverSection.trending:
        if (index < _trendingPosts.length) {
          _trendingPosts = List.from(_trendingPosts)..[index] = post;
        }
        break;
      case DiscoverSection.nearby:
        if (index < _nearbyPosts.length) {
          _nearbyPosts = List.from(_nearbyPosts)..[index] = post;
        }
        break;
    }
  }

  void _openEvents() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => EventsScreen(currentUserId: widget.currentUserId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  _buildDiscoverShortcut(
                    icon: Icons.event,
                    label: 'Matukio',
                    onTap: _openEvents,
                  ),
                ],
              ),
            ),
          ),
          _buildSection(
            title: 'Gundua',
            subtitle: 'Mapendekezo kwa wewe',
            posts: _discoverPosts,
            loading: _loadingDiscover,
            error: _errorDiscover,
            section: DiscoverSection.discover,
            onRetry: _loadDiscover,
          ),
          _buildSection(
            title: 'Vinavyoongezeka',
            subtitle: 'Machapisho yanayovuma',
            posts: _trendingPosts,
            loading: _loadingTrending,
            error: _errorTrending,
            section: DiscoverSection.trending,
            onRetry: _loadTrending,
          ),
          _buildSection(
            title: 'Karibu nawe',
            subtitle: 'Kutoka eneo lako',
            posts: _nearbyPosts,
            loading: _loadingNearby,
            error: _errorNearby,
            section: DiscoverSection.nearby,
            onRetry: _loadNearby,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<Post> posts,
    required bool loading,
    required String? error,
    required DiscoverSection section,
    required VoidCallback onRetry,
  }) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Section header: min 48dp touch target (DESIGN.md)
          Semantics(
            label: '$title. $subtitle',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: const BoxConstraints(minHeight: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF666666),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Text(error, style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: onRetry,
                        child: const Text('Jaribu tena'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (posts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Hakuna machapisho',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ...posts.map((post) => RepaintBoundary(
                  key: ValueKey('discover_${section.name}_${post.id}'),
                  child: PostCard(
                    key: ValueKey('postcard_${post.id}'),
                    post: post,
                    currentUserId: widget.currentUserId,
                    onLike: () => _onLike(post, section),
                    onComment: () => _onComment(post, section),
                    onShare: () => _onShare(post),
                    onSave: () => _onSave(post, section),
                    onUserTap: () => _onUserTap(post),
                    onMenuTap: () => _onMenuTap(post, section),
                    onTap: () => _openPostDetail(post, section),
                  ),
                )),
        ],
      ),
    );
  }
}
