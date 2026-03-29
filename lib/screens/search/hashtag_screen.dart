import 'package:flutter/material.dart';
import '../../models/post_models.dart';
import '../../services/post_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/share_post_sheet.dart';
import '../feed/comment_bottom_sheet.dart';
import '../wallet/subscribe_to_creator_screen.dart';
import 'search_screen.dart';
import '../../models/ad_models.dart';
import '../../services/ad_service.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/native_ad_card.dart';

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

  List<ServedAd> _hashtagAds = [];
  static const int _adInterval = 6;

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
    _loadHashtagAds();
  }

  Future<void> _loadHashtagAds() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final ads = await AdService.getServedAds(token, 'hashtag', 2);
      if (mounted && ads.isNotEmpty) {
        setState(() => _hashtagAds = ads);
      }
    } catch (_) {
      // Non-critical
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

  Future<void> _onReaction(Post post, ReactionType reaction) async {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;

    setState(() {
      _posts[index] = post.copyWith(
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
      setState(() => _posts[index] = post);
    } else if (result.likesCount != null) {
      setState(() {
        _posts[index] = _posts[index].copyWith(likesCount: result.likesCount!);
      });
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
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Failed to update save')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(wasSaved ? 'Removed from saved' : 'Saved')),
      );
    }
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
                color: _kAccent.withValues(alpha: 0.2),
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

    // Ad slots are inserted after every _adInterval posts.
    // Ad positions in the list (0-indexed): _adInterval, 2*_adInterval+1, 3*_adInterval+2, ...
    // i.e. position = k * _adInterval + (k - 1) for k = 1, 2, 3, ...
    // Simplified: position p is an ad when (p + 1) % (_adInterval + 1) == 0
    final bool hasAds = _hashtagAds.isNotEmpty;
    final int adSlots = hasAds ? (_posts.length ~/ _adInterval) : 0;
    final int totalItems = _posts.length + adSlots + (_hasMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: _loadPosts,
      color: _kPrimaryText,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: totalItems,
        itemBuilder: (context, index) {
          // Loading indicator at the end
          if (index >= _posts.length + adSlots) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          // Determine if this index is an ad or a post.
          // Ad slots sit at indices: _adInterval, 2*(_adInterval+1)-1, ...
          // Simple formula: every (_adInterval+1)-th item is an ad.
          if (hasAds && index >= _adInterval && (index + 1) % (_adInterval + 1) == 0) {
            final adNum = (index + 1) ~/ (_adInterval + 1); // 1-based ad number
            final adIdx = (adNum - 1) % _hashtagAds.length;
            final ad = _hashtagAds[adIdx];
            return NativeAdCard(
              key: ValueKey('hashtag_ad_${ad.campaignId}_${ad.creativeId}_$index'),
              servedAd: ad,
              onImpression: () {
                AdService.recordAdEvent(
                  null, ad.campaignId, ad.creativeId,
                  widget.currentUserId, 'hashtag', 'impression',
                );
              },
              onClick: () {
                AdService.recordAdEvent(
                  null, ad.campaignId, ad.creativeId,
                  widget.currentUserId, 'hashtag', 'click',
                );
              },
            );
          }

          // Map list index to post index (subtract ad slots before this position)
          final int adsBefore = hasAds
              ? (index + 1) ~/ (_adInterval + 1)
              : 0;
          final int postIndex = index - adsBefore;

          if (postIndex < 0 || postIndex >= _posts.length) {
            return const SizedBox.shrink();
          }

          final post = _posts[postIndex];
          return _buildPostCard(post);
        },
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return PostCard(
      post: post,
      currentUserId: widget.currentUserId,
      onTap: () => Navigator.pushNamed(context, '/post/${post.id}'),
      onLike: () => _onLike(post),
      onComment: () => _onComment(post),
      onShare: () => _onShare(post),
      onSave: () => _onSave(post),
      onUserTap: () {
        Navigator.pushNamed(context, '/profile/${post.userId}');
      },
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
      onMentionTap: _onMentionTap,
      onReaction: (reaction) => _onReaction(post, reaction),
      onThreadTap: post.threadId != null
          ? () => Navigator.pushNamed(context, '/thread/${post.threadId}')
          : null,
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
  }
}
