import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/api_config.dart';
import '../../models/group_models.dart';
import '../../models/post_models.dart';
import '../../services/group_service.dart';
import '../../services/post_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/share_post_sheet.dart';
import '../feed/comment_bottom_sheet.dart';
import '../feed/edit_post_screen.dart';
import '../feed/post_detail_screen.dart';
import '../feed/thread_viewer_screen.dart';
import '../search/hashtag_screen.dart';
import '../search/search_screen.dart';
import '../wallet/subscribe_to_creator_screen.dart';
import 'create_group_post_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final int groupId;
  final int currentUserId;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.currentUserId,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> with SingleTickerProviderStateMixin {
  final GroupService _groupService = GroupService();
  final PostService _postService = PostService();
  late TabController _tabController;

  Group? _group;
  List<Post> _posts = [];
  List<GroupMember> _members = [];
  bool _isLoading = true;
  bool _isLoadingPosts = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGroup();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    setState(() => _isLoading = true);
    final result = await _groupService.getGroup(
      widget.groupId.toString(),
      currentUserId: widget.currentUserId,
    );
    if (mounted && result.success) {
      setState(() {
        _group = result.group;
        _isLoading = false;
      });
      _loadPosts();
      _loadMembers();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    setState(() => _isLoadingPosts = true);
    final result = await _groupService.getGroupPosts(widget.groupId);
    if (mounted) {
      setState(() {
        _isLoadingPosts = false;
        if (result.success) _posts = result.posts;
      });
    }
  }

  Future<void> _loadMembers() async {
    final result = await _groupService.getMembers(widget.groupId);
    if (mounted && result.success) {
      setState(() => _members = result.members);
    }
  }

  Future<void> _handleJoinLeave() async {
    if (_group == null) return;

    setState(() => _isJoining = true);
    try {
      if (_group!.isMember == true) {
        final success = await _groupService.leaveGroup(widget.groupId, widget.currentUserId);
        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Umeondoka kwenye kikundi')),
          );
          await _loadGroup();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imeshindwa kuondoka. Jaribu tena.')),
          );
        }
      } else {
        final result = await _groupService.joinGroup(widget.groupId, widget.currentUserId);
        if (!mounted) return;
        if (result.success) {
          final bool isPending = result.status == 'pending';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isPending
                    ? 'Ombi limesafirishwa. Unasubiri idhini ya msimamizi.'
                    : (result.message ?? 'Umejiunga'),
              ),
            ),
          );
          await _loadGroup();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Imeshindwa kujiunga. Jaribu tena.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  static const Color _background = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _background,
        appBar: AppBar(backgroundColor: _background),
        body: const SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    if (_group == null) {
      return Scaffold(
        backgroundColor: _background,
        appBar: AppBar(backgroundColor: _background),
        body: SafeArea(
          child: Center(
            child: Text('Kikundi hakipatikani', style: const TextStyle(color: _primaryText)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      floatingActionButton: _group!.isMember == true
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateGroupPostScreen(
                      groupId: widget.groupId,
                      currentUserId: widget.currentUserId,
                      groupName: _group!.name,
                    ),
                  ),
                );
                if (result == true && mounted) {
                  await _loadPosts();
                  await _loadGroup();
                }
              },
              backgroundColor: _primaryText,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: SafeArea(
        child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: _group!.coverPhotoUrl != null
                    ? Image.network(_group!.coverPhotoUrl!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.blue.shade100,
                        child: Icon(Icons.group, size: 80, color: Colors.blue.shade300),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: _primaryText,
                  unselectedLabelColor: _secondaryText,
                  tabs: const [
                    Tab(text: 'Machapisho'),
                    Tab(text: 'Kuhusu'),
                    Tab(text: 'Wanachama'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsTab(),
            _buildAboutTab(),
            _buildMembersTab(),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _group!.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _primaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildPrivacyBadge(_group!.privacy),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.people, size: 16, color: _secondaryText),
              const SizedBox(width: 4),
              Text(
                '${_group!.membersCount} wanachama',
                style: const TextStyle(color: _secondaryText, fontSize: 12),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.article, size: 16, color: _secondaryText),
              const SizedBox(width: 4),
              Text(
                '${_group!.postsCount} machapisho',
                style: const TextStyle(color: _secondaryText, fontSize: 12),
              ),
            ],
          ),
          if (!_group!.isSystem) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 2,
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                      child: InkWell(
                        onTap: _isJoining ? null : _handleJoinLeave,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isJoining)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                Icon(
                                  _group!.isMember == true ? Icons.exit_to_app : Icons.group_add,
                                  color: _primaryText,
                                  size: 24,
                                ),
                              const SizedBox(width: 12),
                              Text(
                                _group!.membershipStatus == 'pending'
                                    ? 'Ombi Linasubiri'
                                    : _group!.isMember == true
                                        ? 'Ondoka'
                                        : 'Jiunga',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_group!.isMember == true) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 2,
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                      child: InkWell(
                        onTap: () {
                          final groupUrl = '${ApiConfig.baseUrl.replaceFirst('/api', '')}/groups/${widget.groupId}';
                          SharePlus.instance.share(
                            ShareParams(text: '${_group!.name}\n$groupUrl'),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: const Icon(Icons.share, color: _primaryText),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrivacyBadge(String privacy) {
    String label;
    IconData icon;
    Color color;
    switch (privacy) {
      case 'private':
        label = 'Binafsi';
        icon = Icons.lock;
        color = Colors.orange;
        break;
      case 'secret':
        label = 'Siri';
        icon = Icons.visibility_off;
        color = Colors.red;
        break;
      default:
        label = 'Wazi';
        icon = Icons.public;
        color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  // ── Post callbacks ──

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
      reactionType: reaction.value,
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
            _posts.insert(0, sharedPost);
          });
        }
      },
    );
  }

  void _onUserTap(Post post) {
    Navigator.pushNamed(context, '/profile/${post.userId}');
  }

  void _onMenuTap(Post post) {
    final isOwner = post.userId == widget.currentUserId;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner) ...[
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
                      final index = _posts.indexWhere((p) => p.id == updated.id);
                      if (index != -1) {
                        setState(() => _posts[index] = updated);
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
                  _confirmDelete(post);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.flag_rounded),
                title: const Text('Ripoti'),
                onTap: () {
                  Navigator.pop(ctx);
                  _postService.reportPost(post.id, widget.currentUserId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ripoti imetumwa')),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Post post) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Futa chapisho'),
        content: const Text('Una uhakika unataka kufuta chapisho hili?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hapana'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final result = await _postService.deletePost(post.id, userId: widget.currentUserId);
              if (!mounted) return;
              if (result.success) {
                setState(() => _posts.removeWhere((p) => p.id == post.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chapisho limefutwa')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Imeshindwa kufuta chapisho')),
                );
              }
            },
            child: const Text('Futa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Posts tab ──

  Widget _buildPostsTab() {
    if (_isLoadingPosts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Hakuna machapisho',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (_group!.isMember == true) ...[
              const SizedBox(height: 8),
              Text(
                'Bofya + ili kuchapisha',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return PostCard(
            post: post,
            currentUserId: widget.currentUserId,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(
                    postId: post.id,
                    currentUserId: widget.currentUserId,
                    initialPost: post,
                  ),
                ),
              );
            },
            onLike: () => _onLike(post),
            onComment: () => _onComment(post),
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
            onThreadTap: () {
              if (post.threadId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ThreadViewerScreen(
                      threadId: post.threadId!,
                      currentUserId: widget.currentUserId,
                    ),
                  ),
                );
              }
            },
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
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_group!.description != null) ...[
            const Text(
              'Maelezo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_group!.description!),
            const SizedBox(height: 24),
          ],
          if (_group!.rules != null && _group!.rules!.isNotEmpty) ...[
            const Text(
              'Sheria za Kikundi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...List.generate(_group!.rules!.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${index + 1}. '),
                    Expanded(child: Text(_group!.rules![index])),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
          if (_group!.creator != null) ...[
            const Text(
              'Mwanzilishi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => Navigator.pushNamed(context, '/profile/${_group!.creator!.id}'),
              leading: CircleAvatar(
                backgroundImage: _group!.creator!.profilePhotoPath != null
                    ? NetworkImage(_group!.creator!.profilePhotoPath!)
                    : null,
                child: _group!.creator!.profilePhotoPath == null
                    ? Text(_group!.creator!.firstName[0])
                    : null,
              ),
              title: Text(_group!.creator!.fullName),
              subtitle: _group!.creator!.username != null
                  ? Text('@${_group!.creator!.username}')
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    if (_members.isEmpty) {
      return const Center(child: Text('Hakuna wanachama'));
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          return ListTile(
            onTap: () => Navigator.pushNamed(context, '/profile/${member.id}'),
            leading: CircleAvatar(
              backgroundImage: member.profilePhotoPath != null
                  ? NetworkImage(member.profilePhotoPath!)
                  : null,
              child: member.profilePhotoPath == null
                  ? Text(member.firstName[0])
                  : null,
            ),
            title: Text(member.fullName),
            subtitle: member.username != null ? Text('@${member.username}') : null,
            trailing: member.isAdmin || member.isModerator
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: member.isAdmin ? Colors.purple : Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      member.isAdmin ? 'Msimamizi' : 'Mdhibiti',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
