import 'package:flutter/material.dart';
import '../../models/group_models.dart';
import '../../models/post_models.dart';
import '../../services/group_service.dart';
import '../../widgets/post_card.dart';
import '../feed/post_detail_screen.dart';
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
                      shadowColor: Colors.black.withOpacity(0.1),
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
                      shadowColor: Colors.black.withOpacity(0.1),
                      child: InkWell(
                        onTap: () {
                          // TODO: Share group
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
        color: color.withOpacity(0.1),
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
            onLike: () {},
            onComment: () {},
            onShare: () {},
            onUserTap: () {},
            onMenuTap: () {},
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
