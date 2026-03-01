import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/post_models.dart';
import '../../services/post_service.dart';
import '../../services/live_update_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/share_post_sheet.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../../widgets/user_avatar.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/app_strings_scope.dart';
import 'edit_post_screen.dart';

/// Full post detail screen: expand media, all comments, like/comment/share.
/// Navigation: Home → Feed/Profile → Tap post card → this screen.
/// Video auto-plays when in view (TikTok-style). Comments lazy-load.
class PostDetailScreen extends StatefulWidget {
  final int postId;
  final int currentUserId;
  /// If provided (e.g. from feed), show immediately and refresh in background.
  final Post? initialPost;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.currentUserId,
    this.initialPost,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostService _postService = PostService();
  final ScrollController _mainScrollController = ScrollController();

  Post? _post;
  bool _isLoadingPost = true;
  String? _postError;

  final List<Comment> _comments = [];
  bool _isLoadingComments = false;
  bool _hasMoreComments = true;
  int _commentsPage = 1;
  static const int _commentsPerPage = 20;
  String? _commentsError;

  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;

  StreamSubscription<LiveUpdateEvent>? _liveUpdateSubscription;

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
    _mainScrollController.addListener(_onMainScroll);
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
    _mainScrollController.removeListener(_onMainScroll);
    _mainScrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onMainScroll() {
    if (!_hasMoreComments || _isLoadingComments) return;
    if (!_mainScrollController.hasClients) return;
    final pos = _mainScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMoreComments();
    }
  }

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

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSubmittingComment || _post == null) return;

    setState(() => _isSubmittingComment = true);
    _commentController.clear();

    final result = await _postService.addComment(
      widget.postId,
      widget.currentUserId,
      content,
    );

    if (!mounted) return;
    setState(() => _isSubmittingComment = false);
    if (result.success && result.comment != null) {
      setState(() {
        _comments.insert(0, result.comment!);
        _post = _post!.copyWith(
          commentsCount: _post!.commentsCount + 1,
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
              onTap: () async {
                Navigator.pop(context);
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
              final success = await _postService.deletePost(post.id);
              if (!mounted) return;
              if (success) {
                Navigator.pop(context, post.id);
                final s2 = AppStringsScope.of(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s2?.postDeleted ?? 'Post deleted')),
                );
              } else {
                final s2 = AppStringsScope.of(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(s2?.deletePostFailed ?? 'Failed to delete post'),
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
      appBar: TajiriAppBar(title: s?.post ?? 'Post'),
      body: SafeArea(
        child: _buildBody(s),
      ),
    );
  }

  Widget _buildBody(AppStrings? s) {
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
            controller: _mainScrollController,
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PostCard(
                  post: post,
                  currentUserId: widget.currentUserId,
                  onLike: () => _onLike(post),
                  onComment: () {
                    // Focus comment field if we add one in app bar, or no-op (already on detail)
                  },
                  onShare: () => _onShare(post),
                  onSave: () => _onSave(post),
                  onUserTap: () => _onUserTap(post),
                  onMenuTap: post.userId == widget.currentUserId
                      ? () => _onMenuTap(post)
                      : null,
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
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 13,
              ),
            ),
          ),
        if (_comments.isEmpty && !_isLoadingComments && _commentsError == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Text(
              s?.noCommentsYet ?? 'No comments yet. Be the first to comment.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length + (_hasMoreComments && _isLoadingComments ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _comments.length) {
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
              return _CommentTile(comment: _comments[index]);
            },
          ),
      ],
    );
  }

  Widget _buildCommentInput(Post post, AppStrings? s) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: s?.writeComment ?? 'Write a comment...',
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
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            photoUrl: comment.user?.profilePhotoUrl,
            name: comment.user?.fullName,
            radius: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.user?.fullName ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                      ),
                      overflow: TextOverflow.ellipsis,
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                    height: 1.35,
                  ),
                ),
                if (comment.likesCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${comment.likesCount} like${comment.likesCount == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Sasa hivi';
    if (diff.inMinutes < 60) return 'Dakika ${diff.inMinutes}';
    if (diff.inHours < 24) return 'Saa ${diff.inHours}';
    if (diff.inDays < 7) return 'Siku ${diff.inDays}';
    return '${time.day}/${time.month}/${time.year}';
  }
}
