import 'package:flutter/material.dart';
import '../../models/post_models.dart';
import '../../services/post_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/app_strings_scope.dart';

/// Saved (bookmarked) posts screen. Story 25.
/// Navigation: Home → Feed/Profile → Post → Bookmark icon; or Feed app bar → Saved.
class SavedPostsScreen extends StatefulWidget {
  final int currentUserId;

  const SavedPostsScreen({super.key, required this.currentUserId});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final PostService _postService = PostService();
  final ScrollController _scrollController = ScrollController();

  List<Post> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSaved();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _loadSaved() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _hasMore = true;
    });

    final result = await _postService.getSavedPosts(
      userId: widget.currentUserId,
      page: 1,
      perPage: 20,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _posts = result.posts;
        _hasMore = result.meta?.hasMore ?? false;
      } else {
        _error = result.message;
      }
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final result = await _postService.getSavedPosts(
      userId: widget.currentUserId,
      page: _currentPage + 1,
      perPage: 20,
    );

    if (!mounted) return;
    setState(() {
      _isLoadingMore = false;
      if (result.success) {
        _posts.addAll(result.posts);
        _currentPage++;
        _hasMore = result.meta?.hasMore ?? false;
      }
    });
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
      setState(() {
        _posts[index] = post;
      });
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? (s?.saveUpdateFailed ?? 'Failed to update save')),
        ),
      );
    } else {
      if (wasSaved) {
        setState(() => _posts.removeAt(index));
      }
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

  Future<void> _onLike(Post post) async {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;

    final wasLiked = post.isLiked;

    setState(() {
      _posts[index] = post.copyWith(
        isLiked: !wasLiked,
        likesCount: wasLiked ? post.likesCount - 1 : post.likesCount + 1,
      );
    });

    final result = wasLiked
        ? await _postService.unlikePost(post.id, widget.currentUserId)
        : await _postService.likePost(post.id, widget.currentUserId);

    if (!mounted) return;
    if (!result.success) {
      setState(() => _posts[index] = post);
    }
  }

  void _onComment(Post post) {
    Navigator.pushNamed(context, '/post/${post.id}');
  }

  void _onShare(Post post) {
    // Share from saved list
  }

  void _onUserTap(Post post) {
    Navigator.pushNamed(context, '/profile/${post.userId}');
  }

  void _onMenuTap(Post post) {
    // Optional menu for post in saved list
  }

  void _onTap(Post post) {
    Navigator.pushNamed(context, '/post/${post.id}');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: TajiriAppBar(title: s?.savedTitle ?? 'Saved'),
      body: SafeArea(
        child: _buildBody(s),
      ),
    );
  }

  Widget _buildBody(AppStrings? s) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loadSaved,
                  child: Text(s?.retry ?? 'Retry'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              s?.noSavedPosts ?? 'No saved posts',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              s?.noSavedPostsHint ?? 'Tap bookmark on a post to save it',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSaved,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
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

          final post = _posts[index];
          return RepaintBoundary(
            key: ValueKey('saved_post_${post.id}'),
            child: PostCard(
              key: ValueKey('saved_postcard_${post.id}'),
              post: post,
              currentUserId: widget.currentUserId,
              onLike: () => _onLike(post),
              onComment: () => _onComment(post),
              onShare: () => _onShare(post),
              onSave: () => _onSave(post),
              onUserTap: () => _onUserTap(post),
              onMenuTap: () => _onMenuTap(post),
              onTap: () => _onTap(post),
            ),
          );
        },
      ),
    );
  }
}
