import 'package:flutter/material.dart';
import '../../models/post_models.dart';
import '../../services/post_service.dart';
import '../../widgets/post_card.dart';

// DESIGN.md: background #FAFAFA, primary #1A1A1A, secondary #666666, accent #999999, min touch 48dp
const Color _kBg = Color(0xFFFAFAFA);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kAccent = Color(0xFF999999);

class HashtagScreen extends StatefulWidget {
  final String hashtag;
  final int currentUserId;

  const HashtagScreen({
    super.key,
    required this.hashtag,
    required this.currentUserId,
  });

  @override
  State<HashtagScreen> createState() => _HashtagScreenState();
}

class _HashtagScreenState extends State<HashtagScreen> {
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
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _postService.searchByHashtag(
      hashtag: widget.hashtag,
      currentUserId: widget.currentUserId,
      page: 1,
    );

    if (mounted) {
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
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final result = await _postService.searchByHashtag(
      hashtag: widget.hashtag,
      currentUserId: widget.currentUserId,
      page: _currentPage + 1,
    );

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.success) {
          _posts.addAll(result.posts);
          _currentPage++;
          _hasMore = result.meta?.hasMore ?? false;
        }
      });
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

    if (!result.success) {
      setState(() {
        _posts[index] = post;
      });
    } else if (result.likesCount != null) {
      setState(() {
        _posts[index] = _posts[index].copyWith(likesCount: result.likesCount!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text('#${widget.hashtag}', style: const TextStyle(color: _kPrimaryText, fontSize: 15)),
        backgroundColor: _kBg,
        elevation: 0,
        foregroundColor: _kPrimaryText,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              _isLoading
                  ? 'Inatafuta...'
                  : '${_posts.length} machapisho${_hasMore ? '+' : ''}',
              style: const TextStyle(color: _kSecondaryText, fontSize: 14),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimaryText));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: _kAccent),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: _kSecondaryText, fontSize: 14)),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loadPosts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryText,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Jaribu tena'),
              ),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.tag, size: 48, color: _kAccent),
            ),
            const SizedBox(height: 16),
            Text(
              '#${widget.hashtag}',
              style: const TextStyle(
                color: _kPrimaryText,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hakuna machapisho yenye hashtag hii',
              style: TextStyle(color: _kSecondaryText, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kuwa wa kwanza kuandika!',
              style: TextStyle(color: _kSecondaryText, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      color: _kPrimaryText,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final post = _posts[index];
          return PostCard(
            post: post,
            currentUserId: widget.currentUserId,
            onLike: () => _onLike(post),
            onComment: () {
              // Navigate to post detail
            },
            onShare: () {},
            onUserTap: () {
              Navigator.pushNamed(context, '/profile/${post.userId}');
            },
            onMenuTap: () {},
            onHashtagTap: (hashtag) {
              if (hashtag != widget.hashtag) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HashtagScreen(
                      hashtag: hashtag,
                      currentUserId: widget.currentUserId,
                    ),
                  ),
                );
              }
            },
            onMentionTap: (username) {
              // Navigate to user profile
            },
          );
        },
      ),
    );
  }
}
