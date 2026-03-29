import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../models/post_models.dart';
import '../../services/post_service.dart';
import '../../widgets/mention_text_field.dart';
import '../../widgets/rich_comment_content.dart';
import '../../widgets/user_avatar.dart';
import '../search/search_screen.dart';
import '../search/hashtag_screen.dart';
import '../../models/ad_models.dart';
import '../../services/ad_service.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/native_ad_card.dart';

void _log(String message) => debugPrint('[CommentBottomSheet] $message');

enum CommentSortOption { newest, oldest, top }

/// Comment bottom sheet: Home → Feed/Profile → Post → Comment icon.
/// Shows comments list with threaded replies, input to add comment/reply.
/// DESIGN: 48dp min touch targets, #FAFAFA background, #1A1A1A primary.
class CommentBottomSheet extends StatefulWidget {
  final int postId;
  final int currentUserId;
  final Post? initialPost;
  final void Function(int newCount)? onCommentsCountUpdated;

  const CommentBottomSheet({
    super.key,
    required this.postId,
    required this.currentUserId,
    this.initialPost,
    this.onCommentsCountUpdated,
  });

  /// Show the sheet from a BuildContext (e.g. from Feed or Profile).
  static Future<void> show(
    BuildContext context, {
    required int postId,
    required int currentUserId,
    Post? initialPost,
    void Function(int newCount)? onCommentsCountUpdated,
  }) {
    _log('Opening: postId=$postId currentUserId=$currentUserId initialCommentsCount=${initialPost?.commentsCount ?? "?"}');
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentBottomSheet(
        postId: postId,
        currentUserId: currentUserId,
        initialPost: initialPost,
        onCommentsCountUpdated: onCommentsCountUpdated,
      ),
    );
  }

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final PostService _postService = PostService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();

  List<Comment> _comments = [];
  bool _isLoadingComments = false;
  bool _hasMoreComments = true;
  int _commentsPage = 1;
  static const int _commentsPerPage = 20;
  String? _commentsError;

  bool _isSubmittingComment = false;
  Comment? _replyingTo;
  int _commentsCount = 0;

  CommentSortOption _sortOption = CommentSortOption.newest;
  List<int> _mentionedUserIds = [];
  int? _loadingLikeCommentId;
  int? _loadingRepliesParentId;
  final Set<int> _expandedReplyParents = {};
  int? _pinnedCommentId;

  /// Ads served in the comments list (inserted after every 8 comments).
  List<ServedAd> _commentAds = [];

  @override
  void initState() {
    super.initState();
    _commentsCount = widget.initialPost?.commentsCount ?? 0;
    _log('initState: postId=${widget.postId} displayCount=$_commentsCount');
    _loadComments();
    _loadCommentAds();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMoreComments || _isLoadingComments) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMoreComments();
    }
  }

  /// Top-level comments (no parent), sorted. Pinned first if any.
  List<Comment> get _topLevelComments {
    final list = _comments.where((c) => c.parentId == null).toList();
    switch (_sortOption) {
      case CommentSortOption.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case CommentSortOption.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case CommentSortOption.top:
        list.sort((a, b) {
          final cmp = b.likesCount.compareTo(a.likesCount);
          return cmp != 0 ? cmp : b.createdAt.compareTo(a.createdAt);
        });
        break;
    }
    final pinnedCandidates = list.where((c) => c.isPinned).toList();
    final pinnedId = _pinnedCommentId ?? (pinnedCandidates.isNotEmpty ? pinnedCandidates.first.id : null);
    if (pinnedId != null) {
      final pinned = list.where((c) => c.id == pinnedId).toList();
      if (pinned.isNotEmpty) {
        list.remove(pinned.first);
        list.insert(0, pinned.first);
      }
    }
    return list;
  }

  List<Comment> _repliesFor(Comment parent) {
    final list = _comments.where((c) => c.parentId == parent.id).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  bool get _allowComments => widget.initialPost?.allowComments ?? true;

  /// Fetch ads for the comments placement.
  Future<void> _loadCommentAds() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final ads = await AdService.getServedAds(token, 'comments', 1);
      if (mounted && ads.isNotEmpty) {
        setState(() => _commentAds = ads);
      }
    } catch (e) {
      _log('_loadCommentAds error: $e');
    }
  }

  void _recordCommentAdImpression(ServedAd ad) async {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    AdService.recordAdEvent(
      token, ad.campaignId, ad.creativeId,
      widget.currentUserId, 'comments', 'impression',
    );
  }

  void _recordCommentAdClick(ServedAd ad) async {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    AdService.recordAdEvent(
      token, ad.campaignId, ad.creativeId,
      widget.currentUserId, 'comments', 'click',
    );
  }

  Future<void> _loadComments() async {
    _log('loadComments: start postId=${widget.postId} _isLoadingComments=$_isLoadingComments');
    if (_isLoadingComments) return;
    _log('loadComments: requesting API page=1 perPage=$_commentsPerPage');
    setState(() {
      _isLoadingComments = true;
      _commentsError = null;
    });

    try {
      final result = await _postService.getComments(
        widget.postId,
        page: 1,
        perPage: _commentsPerPage,
      );

      if (!mounted) return;
      if (result.success) {
        _log('loadComments: success count=${result.comments.length} hasMore=${result.meta?.hasMore} total=${result.meta?.total}');
      } else {
        _log('loadComments: failed message=${result.message}');
      }
      setState(() {
        _isLoadingComments = false;
        if (result.success) {
          _comments = _buildCommentTree(result.comments);
          _commentsPage = 1;
          _hasMoreComments = result.meta?.hasMore ?? false;
          _commentsError = null;
        } else {
          _commentsError = result.message ?? 'Maoni hayakupatikana';
        }
      });
    } catch (e, stack) {
      if (!mounted) return;
      _log('loadComments: error $e');
      if (kDebugMode) _log('stack: $stack');
      setState(() {
        _isLoadingComments = false;
        _commentsError = _commentErrorMessage(e);
      });
    }
  }

  static String _commentErrorMessage(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('socket') || s.contains('connection') || s.contains('network')) {
      return 'Hakuna muunganisho. Angalia mtandao na jaribu tena.';
    }
    if (s.contains('timeout') || s.contains('timed out')) {
      return 'Ombi limechukua muda mrefu. Jaribu tena.';
    }
    return 'Maoni hayakupatikana. Jaribu tena.';
  }

  /// Flatten API list: support both flat (parent_id on each) and nested (replies inside comment).
  List<Comment> _buildCommentTree(List<Comment> raw) {
    final flat = <Comment>[];
    void addWithReplies(Comment c) {
      flat.add(c);
      for (final r in c.replies) {
        addWithReplies(r);
      }
    }
    final topLevel = raw.where((c) => c.parentId == null).toList();
    for (final c in topLevel) {
      addWithReplies(c);
    }
    for (final c in raw) {
      if (c.parentId != null && !flat.any((x) => x.id == c.id)) {
        flat.add(c);
      }
    }
    flat.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return flat;
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingComments || !_hasMoreComments) return;
    final nextPage = _commentsPage + 1;
    _log('loadMoreComments: postId=${widget.postId} page=$nextPage');
    setState(() => _isLoadingComments = true);

    try {
      final result = await _postService.getComments(
        widget.postId,
        page: nextPage,
        perPage: _commentsPerPage,
      );

      if (!mounted) return;
      if (result.success) {
        _log('loadMoreComments: success loaded=${result.comments.length} hasMore=${result.meta?.hasMore}');
      } else {
        _log('loadMoreComments: failed message=${result.message}');
      }
      setState(() {
        _isLoadingComments = false;
        if (result.success) {
          final merged = _buildCommentTree([..._comments, ...result.comments]);
          _comments = merged;
          _commentsPage++;
          _hasMoreComments = result.meta?.hasMore ?? false;
        }
      });
    } catch (e, stack) {
      if (!mounted) return;
      _log('loadMoreComments: error $e');
      if (kDebugMode) _log('stack: $stack');
      setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSubmittingComment) return;

    setState(() => _isSubmittingComment = true);
    final parentId = _replyingTo?.id;
    final mentionIds = List<int>.from(_mentionedUserIds);
    _commentController.clear();
    final wasReplyingTo = _replyingTo;
    setState(() {
      _replyingTo = null;
      _mentionedUserIds = [];
    });

    final result = await _postService.addComment(
      widget.postId,
      widget.currentUserId,
      content,
      parentId: parentId,
      mentionIds: mentionIds.isNotEmpty ? mentionIds : null,
    );

    if (!mounted) return;
    setState(() => _isSubmittingComment = false);
    if (result.success && result.comment != null) {
      setState(() {
        _comments.add(result.comment!);
        _commentsCount++;
      });
      widget.onCommentsCountUpdated?.call(_commentsCount);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Imeshindwa kuongeza maoni'),
        ),
      );
      if (wasReplyingTo != null) {
        setState(() => _replyingTo = wasReplyingTo);
      }
    }
  }

  Future<void> _likeComment(Comment comment) async {
    if (_loadingLikeCommentId != null) return;
    setState(() => _loadingLikeCommentId = comment.id);
    final result = comment.isLiked
        ? await _postService.unlikeComment(comment.id, widget.currentUserId)
        : await _postService.likeComment(comment.id, widget.currentUserId);
    if (!mounted) return;
    setState(() => _loadingLikeCommentId = null);
    if (result.success) {
      setState(() {
        final idx = _comments.indexWhere((c) => c.id == comment.id);
        if (idx >= 0) {
          _comments[idx] = comment.copyWith(likesCount: result.likesCount, isLiked: result.isLiked);
        }
      });
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Futa maoni'),
        content: const Text('Una uhakika unataka kufuta maoni yako?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ghairi')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Futa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await _postService.deleteComment(comment.id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _comments.removeWhere((c) => c.id == comment.id);
        _commentsCount = (_commentsCount - 1).clamp(0, 0x7fffffff);
      });
      widget.onCommentsCountUpdated?.call(_commentsCount);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maoni yamefutwa')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imeshindwa kufuta maoni')));
    }
  }

  Future<void> _editComment(Comment comment) async {
    final controller = TextEditingController(text: comment.content);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _EditCommentDialog(
        controller: controller,
        currentUserId: widget.currentUserId,
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    final res = await _postService.updateComment(
      comment.id,
      result['content'] as String,
      mentionIds: result['mention_ids'] as List<int>?,
    );
    if (!mounted) return;
    if (res.success && res.comment != null) {
      setState(() {
        final idx = _comments.indexWhere((c) => c.id == comment.id);
        if (idx >= 0) _comments[idx] = res.comment!;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maoni yamebadilishwa')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message ?? 'Imeshindwa kubadilisha')));
    }
  }

  Future<void> _pinComment(Comment comment) async {
    final res = await _postService.pinComment(widget.postId, comment.id);
    if (!mounted) return;
    if (res.success) {
      setState(() => _pinnedCommentId = comment.id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maoni yamebandika')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message ?? 'Imeshindwa kuweka')));
    }
  }

  Future<void> _reportComment(Comment comment) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _ReportCommentDialog(),
    );
    if (reason == null || !mounted) return;
    final ok = await _postService.reportComment(comment.id, reason: reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Imesafirishwa. Asante.' : 'Imeshindwa kusafirisha')),
    );
  }

  Future<void> _loadMoreReplies(Comment parent) async {
    if (_loadingRepliesParentId != null) return;
    setState(() => _loadingRepliesParentId = parent.id);
    final result = await _postService.getReplies(widget.postId, parent.id, page: 1, perPage: 20);
    if (!mounted) return;
    setState(() => _loadingRepliesParentId = null);
    if (result.success && result.comments.isNotEmpty) {
      setState(() {
        _expandedReplyParents.add(parent.id);
        for (final c in result.comments) {
          if (!_comments.any((x) => x.id == c.id)) _comments.add(c);
        }
      });
    }
  }

  void _startReply(Comment comment) {
    setState(() => _replyingTo = comment);
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Text(
                    'Maoni ($_commentsCount)',
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _buildSortChip(),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: _buildCommentsList(),
            ),
            if (_allowComments && _replyingTo != null) _buildReplyingChip(),
            if (_allowComments) _buildCommentInput(bottomPadding, safeBottom),
            if (!_allowComments) _buildCommentsDisabledFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsDisabledFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border(top: BorderSide(color: const Color(0xFF999999).withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          HeroIcon(HeroIcons.lockClosed, style: HeroIconStyle.outline, size: 20, color: const Color(0xFF666666)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Maoni yamezuiwa kwa chapisho hili.',
              style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFF999999),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSortChip() {
    return PopupMenuButton<CommentSortOption>(
      initialValue: _sortOption,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 160),
      onSelected: (v) => setState(() => _sortOption = v),
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: CommentSortOption.newest, child: Text('Hivi karibuni')),
        const PopupMenuItem(value: CommentSortOption.oldest, child: Text('Zilizo zamani')),
        const PopupMenuItem(value: CommentSortOption.top, child: Text('Juu zaidi')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HeroIcon(HeroIcons.chevronUpDown, style: HeroIconStyle.outline, size: 16, color: const Color(0xFF666666)),
            const SizedBox(width: 4),
            Text(
              _sortOption == CommentSortOption.newest
                  ? 'Hivi karibuni'
                  : _sortOption == CommentSortOption.oldest
                      ? 'Zilizo zamani'
                      : 'Juu zaidi',
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyingChip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFFAFAFA),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Inajibu ${_replyingTo?.user?.fullName ?? "..."}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _cancelReply,
              borderRadius: BorderRadius.circular(24),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: HeroIcon(HeroIcons.xMark, style: HeroIconStyle.outline, size: 22, color: const Color(0xFF666666)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    if (_commentsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _commentsError!,
                style: const TextStyle(color: Color(0xFF666666), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: _loadComments,
                  child: const Text('Jaribu tena'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Hakuna maoni bado. Kuwa wa kwanza kutoa maoni.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final topLevel = _topLevelComments;
    final commentCount = _listItemCount(topLevel);
    // Insert a compact ad after every 8 comments
    final adSlots = _commentAds.isNotEmpty ? (commentCount ~/ 8) : 0;
    final totalCount = commentCount + adSlots;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        // Check if this index is an ad slot (positions 8, 17, 26, ...)
        if (_commentAds.isNotEmpty && index > 0 && (index + 1) % 9 == 0) {
          final adIndex = ((index + 1) ~/ 9 - 1) % _commentAds.length;
          final ad = _commentAds[adIndex];
          return NativeAdCard(
            servedAd: ad,
            onImpression: () => _recordCommentAdImpression(ad),
            onClick: () => _recordCommentAdClick(ad),
          );
        }
        // Map visual index to comment index by subtracting ad slots before it
        final adsBefore = _commentAds.isNotEmpty ? ((index + 1) ~/ 9) : 0;
        final commentIndex = index - adsBefore;
        return _buildCommentItemAtIndex(commentIndex, topLevel);
      },
    );
  }

  int _listItemCount(List<Comment> topLevel) {
    int n = 0;
    for (final c in topLevel) {
      n += 1;
      n += _repliesFor(c).length;
    }
    return n;
  }

  Widget _buildCommentItemAtIndex(int index, List<Comment> topLevel) {
    int i = 0;
    for (final parent in topLevel) {
      if (i == index) {
        return _CommentTile(
          comment: parent,
          isReply: false,
          currentUserId: widget.currentUserId,
          postAuthorId: widget.initialPost?.userId,
          isLikeLoading: _loadingLikeCommentId == parent.id,
          onReply: () => _startReply(parent),
          onLike: () => _likeComment(parent),
          onDelete: () => _deleteComment(parent),
          onEdit: () => _editComment(parent),
          onPin: () => _pinComment(parent),
          onReport: () => _reportComment(parent),
          repliesCount: _repliesFor(parent).length,
          replyCountFromApi: parent.replyCount,
          hasLoadedMoreReplies: _expandedReplyParents.contains(parent.id),
          isLoadingMoreReplies: _loadingRepliesParentId == parent.id,
          onLoadMoreReplies: () => _loadMoreReplies(parent),
        );
      }
      i++;
      for (final reply in _repliesFor(parent)) {
        if (i == index) {
          return _CommentTile(
            comment: reply,
            isReply: true,
            currentUserId: widget.currentUserId,
            postAuthorId: widget.initialPost?.userId,
            isLikeLoading: _loadingLikeCommentId == reply.id,
            onReply: () => _startReply(reply),
            onLike: () => _likeComment(reply),
            onDelete: () => _deleteComment(reply),
            onEdit: () => _editComment(reply),
            onPin: null,
            onReport: () => _reportComment(reply),
            repliesCount: 0,
            replyCountFromApi: 0,
            hasLoadedMoreReplies: false,
            isLoadingMoreReplies: false,
            onLoadMoreReplies: null,
          );
        }
        i++;
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildCommentInput(double bottomPadding, double safeBottom) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 8 + safeBottom + bottomPadding,
      ),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: MentionTextField(
              controller: _commentController,
              currentUserId: widget.currentUserId,
              hintText: 'Andika maoni... @ #',
              maxLines: 3,
              minLines: 1,
              onChanged: (_) {},
              onSubmitted: _submitComment,
              onMentionSelected: (user) => setState(() {
                if (!_mentionedUserIds.contains(user.id)) _mentionedUserIds.add(user.id);
              }),
              decoration: const InputDecoration(
                hintStyle: TextStyle(color: Color(0xFF999999)),
                filled: true,
                fillColor: Color(0xFFFAFAFA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
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
                    : HeroIcon(HeroIcons.paperAirplane, style: HeroIconStyle.solid, size: 22, color: Colors.white),
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
  final bool isReply;
  final int currentUserId;
  final int? postAuthorId;
  final bool isLikeLoading;
  final VoidCallback onReply;
  final VoidCallback onLike;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onPin;
  final VoidCallback onReport;
  final int repliesCount;
  final int replyCountFromApi;
  final bool hasLoadedMoreReplies;
  final bool isLoadingMoreReplies;
  final VoidCallback? onLoadMoreReplies;

  const _CommentTile({
    required this.comment,
    required this.isReply,
    required this.currentUserId,
    this.postAuthorId,
    this.isLikeLoading = false,
    required this.onReply,
    required this.onLike,
    required this.onDelete,
    required this.onEdit,
    this.onPin,
    required this.onReport,
    this.repliesCount = 0,
    this.replyCountFromApi = 0,
    this.hasLoadedMoreReplies = false,
    this.isLoadingMoreReplies = false,
    this.onLoadMoreReplies,
  });

  @override
  Widget build(BuildContext context) {
    final isOwn = comment.userId == currentUserId;
    final canPin = postAuthorId == currentUserId && !isReply && onPin != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(isReply ? 48 : 16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (comment.userId > 0) {
                Navigator.pushNamed(context, '/profile/${comment.userId}');
              }
            },
            child: UserAvatar(
              photoUrl: comment.user?.profilePhotoUrl,
              name: comment.user?.fullName,
              radius: 20,
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
                      child: GestureDetector(
                        onTap: () {
                          if (comment.userId > 0) {
                            Navigator.pushNamed(context, '/profile/${comment.userId}');
                          }
                        },
                        child: Text(
                          comment.user?.fullName ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (comment.isPinned) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Iliyobandikwa',
                          style: TextStyle(fontSize: 10, color: Color(0xFF666666), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(comment.createdAt),
                      style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
                    ),
                    const Spacer(),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showCommentMenu(
                          context,
                          isOwn: isOwn,
                          canPin: canPin,
                          onReply: onReply,
                          onEdit: onEdit,
                          onDelete: onDelete,
                          onPin: onPin,
                          onReport: onReport,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: HeroIcon(HeroIcons.ellipsisHorizontal, style: HeroIconStyle.outline, size: 20, color: const Color(0xFF999999)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                RichCommentContent(
                  text: comment.content,
                  onMentionTap: (username) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SearchScreen(
                          currentUserId: currentUserId,
                          initialQuery: username,
                          initialTab: 0,
                        ),
                      ),
                    );
                  },
                  onHashtagTap: (hashtag) {
                    final tag = hashtag.startsWith('#') ? hashtag.substring(1) : hashtag;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HashtagScreen(
                          hashtag: tag,
                          currentUserId: currentUserId,
                        ),
                      ),
                    );
                  },
                ),
                if (comment.editedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      ' (ilihaririwa)',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isLikeLoading ? null : onLike,
                        borderRadius: BorderRadius.circular(24),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HeroIcon(
                                HeroIcons.heart,
                                style: comment.isLiked ? HeroIconStyle.solid : HeroIconStyle.outline,
                                size: 18,
                                color: comment.isLiked ? const Color(0xFF1A1A1A) : const Color(0xFF666666),
                              ),
                              if (comment.likesCount > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${comment.likesCount}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onReply,
                        borderRadius: BorderRadius.circular(24),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Text(
                            'Jibu',
                            style: TextStyle(fontSize: 13, color: Color(0xFF666666), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (onLoadMoreReplies != null &&
                    replyCountFromApi > 0 &&
                    repliesCount < replyCountFromApi &&
                    !hasLoadedMoreReplies) ...[
                  const SizedBox(height: 4),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isLoadingMoreReplies ? null : onLoadMoreReplies,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: isLoadingMoreReplies
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'Onyesha majibu ${replyCountFromApi - repliesCount} zaidi',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF666666), fontWeight: FontWeight.w500),
                              ),
                      ),
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

  void _showCommentMenu(
    BuildContext context, {
    required bool isOwn,
    required bool canPin,
    required VoidCallback onReply,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback? onPin,
    required VoidCallback onReport,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: HeroIcon(HeroIcons.chatBubbleLeft, style: HeroIconStyle.outline, size: 24, color: const Color(0xFF1A1A1A)),
                title: const Text('Jibu', style: TextStyle(fontSize: 15, color: Color(0xFF1A1A1A))),
                onTap: () {
                  Navigator.pop(ctx);
                  onReply();
                },
              ),
              if (isOwn) ...[
                ListTile(
                  leading: HeroIcon(HeroIcons.pencilSquare, style: HeroIconStyle.outline, size: 24, color: const Color(0xFF1A1A1A)),
                  title: const Text('Hariri', style: TextStyle(fontSize: 15, color: Color(0xFF1A1A1A))),
                  onTap: () {
                    Navigator.pop(ctx);
                    onEdit();
                  },
                ),
                ListTile(
                  leading: HeroIcon(HeroIcons.trash, style: HeroIconStyle.outline, size: 24, color: const Color(0xFF1A1A1A)),
                  title: const Text('Futa maoni', style: TextStyle(fontSize: 15, color: Color(0xFF1A1A1A))),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete();
                  },
                ),
              ],
              if (canPin && onPin != null)
                ListTile(
                  leading: HeroIcon(HeroIcons.bookmark, style: HeroIconStyle.outline, size: 24, color: const Color(0xFF1A1A1A)),
                  title: const Text('Bandika maoni', style: TextStyle(fontSize: 15, color: Color(0xFF1A1A1A))),
                  onTap: () {
                    Navigator.pop(ctx);
                    onPin();
                  },
                ),
              ListTile(
                leading: HeroIcon(HeroIcons.flag, style: HeroIconStyle.outline, size: 24, color: const Color(0xFF1A1A1A)),
                title: const Text('Ripoti', style: TextStyle(fontSize: 15, color: Color(0xFF1A1A1A))),
                onTap: () {
                  Navigator.pop(ctx);
                  onReport();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Sasa hivi';
    if (diff.inMinutes < 60) return 'Dakika ${diff.inMinutes}';
    if (diff.inHours < 24) return 'Saa ${diff.inHours}';
    if (diff.inDays < 7) return 'Siku ${diff.inDays}';
    return '${time.day}/${time.month}/${time.year}';
  }
}

class _EditCommentDialog extends StatefulWidget {
  final TextEditingController controller;
  final int currentUserId;

  const _EditCommentDialog({
    required this.controller,
    required this.currentUserId,
  });

  @override
  State<_EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends State<_EditCommentDialog> {
  final List<int> _mentionIds = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hariri maoni'),
      content: SingleChildScrollView(
        child: MentionTextField(
          controller: widget.controller,
          currentUserId: widget.currentUserId,
          hintText: 'Andika maoni... @ #',
          maxLines: 4,
          minLines: 2,
          onMentionSelected: (user) {
            if (!_mentionIds.contains(user.id)) setState(() => _mentionIds.add(user.id));
          },
          decoration: const InputDecoration(
            filled: true,
            fillColor: Color(0xFFFAFAFA),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Ghairi'),
        ),
        TextButton(
          onPressed: () {
            final content = widget.controller.text.trim();
            if (content.isEmpty) return;
            Navigator.pop(context, {'content': content, 'mention_ids': _mentionIds.isEmpty ? null : List<int>.from(_mentionIds)});
          },
          child: const Text('Hifadhi'),
        ),
      ],
    );
  }
}

class _ReportCommentDialog extends StatefulWidget {
  @override
  State<_ReportCommentDialog> createState() => _ReportCommentDialogState();
}

class _ReportCommentDialogState extends State<_ReportCommentDialog> {
  String? _selectedReason;
  final _otherController = TextEditingController();

  static const List<String> _reasons = [
    'Maudhui yasiyofaa',
    'Ukatili',
    'Ubaguzi',
    'Uhariri / udanganyifu',
    'Spam',
    'Nyingine',
  ];

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ripoti maoni'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chagua sababu ya kuripoti:',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 12),
            ..._reasons.map((r) => RadioListTile<String>(
                  title: Text(r, style: const TextStyle(fontSize: 14)),
                  value: r,
                  groupValue: _selectedReason,
                  onChanged: (v) => setState(() => _selectedReason = v),
                )),
            if (_selectedReason == 'Nyingine') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _otherController,
                decoration: const InputDecoration(
                  hintText: 'Eleza...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Ghairi'),
        ),
        TextButton(
          onPressed: () {
            final reason = _selectedReason == 'Nyingine'
                ? _otherController.text.trim().isEmpty
                    ? 'Nyingine'
                    : _otherController.text.trim()
                : _selectedReason ?? 'Nyingine';
            Navigator.pop(context, reason);
          },
          child: const Text('Tuma'),
        ),
      ],
    );
  }
}
