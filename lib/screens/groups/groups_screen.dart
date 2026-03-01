import 'package:flutter/material.dart';
import '../../models/group_models.dart';
import '../../services/group_service.dart';
import '../../widgets/cached_media_image.dart';
import 'group_detail_screen.dart';
import 'create_group_screen.dart';

// Design: DOCS/DESIGN.md — monochrome, touch 48dp min, SafeArea
// Navigation: Discover/Profile → Groups → GroupsScreen (DOCS/NAVIGATION.md)

class GroupsScreen extends StatefulWidget {
  final int currentUserId;

  const GroupsScreen({super.key, required this.currentUserId});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GroupService _groupService = GroupService();

  List<Group> _discoverGroups = [];
  List<Group> _myGroups = [];
  bool _isLoadingDiscover = true;
  bool _isLoadingMyGroups = true;
  String? _errorDiscover;
  String? _errorMyGroups;

  static const Color _bgPrimary = Color(0xFFFAFAFA);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF666666);
  static const Color _accent = Color(0xFF999999);
  static const Color _cardBg = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    _loadDiscoverGroups();
    _loadMyGroups();
  }

  Future<void> _loadDiscoverGroups() async {
    if (!mounted) return;
    setState(() {
      _isLoadingDiscover = true;
      _errorDiscover = null;
    });
    final result = await _groupService.getGroups(
      currentUserId: widget.currentUserId,
    );
    if (mounted) {
      setState(() {
        _isLoadingDiscover = false;
        if (result.success) {
          _discoverGroups = result.groups;
        } else {
          _errorDiscover = result.message ?? 'Imeshindwa kupakia vikundi';
        }
      });
    }
  }

  Future<void> _loadMyGroups() async {
    if (!mounted) return;
    setState(() {
      _isLoadingMyGroups = true;
      _errorMyGroups = null;
    });
    final result = await _groupService.getUserGroups(widget.currentUserId);
    if (mounted) {
      setState(() {
        _isLoadingMyGroups = false;
        if (result.success) {
          _myGroups = result.groups;
        } else {
          _errorMyGroups = result.message ?? 'Imeshindwa kupakia vikundi vyako';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPrimary,
      appBar: AppBar(
        backgroundColor: _cardBg,
        foregroundColor: _textPrimary,
        elevation: 0,
        title: const Text(
          'Vikundi',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _textPrimary,
          unselectedLabelColor: _textSecondary,
          indicatorColor: _textPrimary,
          tabs: const [
            Tab(text: 'Gundua'),
            Tab(text: 'Vikundi Vyangu'),
          ],
        ),
        actions: [
          SemanticButton(
            button: IconButton(
              icon: const Icon(Icons.search, color: _textPrimary),
              onPressed: _openSearch,
              iconSize: 24,
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
              ),
            ),
            label: 'Tafuta vikundi',
          ),
        ],
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDiscoverTab(),
            _buildMyGroupsTab(),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFab() {
    return SemanticButton(
      button: FloatingActionButton(
        heroTag: 'groups_fab',
        onPressed: _createGroup,
        backgroundColor: _textPrimary,
        foregroundColor: _cardBg,
        child: const Icon(Icons.add),
      ),
      label: 'Unda kikundi',
    );
  }

  Future<void> _createGroup() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateGroupScreen(creatorId: widget.currentUserId),
      ),
    );
    if (result == true && mounted) {
      _loadGroups();
    }
  }

  void _openSearch() {
    showSearch<String>(
      context: context,
      delegate: _GroupSearchDelegate(
        groupService: _groupService,
        currentUserId: widget.currentUserId,
        onGroupTap: (group) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailScreen(
                groupId: group.id,
                currentUserId: widget.currentUserId,
              ),
            ),
          ).then((_) => _loadGroups());
        },
      ),
    );
  }

  Widget _buildDiscoverTab() {
    if (_isLoadingDiscover) {
      return const Center(
        child: CircularProgressIndicator(color: _textPrimary),
      );
    }

    if (_errorDiscover != null) {
      return _buildErrorState(
        message: _errorDiscover!,
        onRetry: _loadDiscoverGroups,
      );
    }

    if (_discoverGroups.isEmpty) {
      return _buildEmptyState(
        icon: Icons.group_outlined,
        message: 'Hakuna vikundi',
        onAction: null,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDiscoverGroups,
      color: _textPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _discoverGroups.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildGroupCard(_discoverGroups[index]),
          );
        },
      ),
    );
  }

  Widget _buildMyGroupsTab() {
    if (_isLoadingMyGroups) {
      return const Center(
        child: CircularProgressIndicator(color: _textPrimary),
      );
    }

    if (_errorMyGroups != null) {
      return _buildErrorState(
        message: _errorMyGroups!,
        onRetry: _loadMyGroups,
      );
    }

    if (_myGroups.isEmpty) {
      return _buildEmptyState(
        icon: Icons.group_outlined,
        message: 'Hujajiunga na kikundi chochote',
        actionLabel: 'Gundua Vikundi',
        onAction: () => _tabController.animateTo(0),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyGroups,
      color: _textPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _myGroups.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildGroupCard(_myGroups[index], showRole: true),
          );
        },
      ),
    );
  }

  Widget _buildErrorState({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: _textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: Material(
                color: _cardBg,
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                child: InkWell(
                  onTap: onRetry,
                  borderRadius: BorderRadius.circular(12),
                  child: const Center(
                    child: Text('Jaribu tena', style: TextStyle(color: _textPrimary)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: _accent),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(minHeight: 48),
                width: double.infinity,
                child: Material(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.1),
                  child: InkWell(
                    onTap: onAction,
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: Text(
                        actionLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(Group group, {bool showRole = false}) {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailScreen(
                groupId: group.id,
                currentUserId: widget.currentUserId,
              ),
            ),
          ).then((_) {
            if (mounted) _loadGroups();
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: group.coverPhotoUrl != null &&
                        group.coverPhotoUrl!.isNotEmpty
                    ? CachedMediaImage(
                        imageUrl: group.coverPhotoUrl!,
                        width: double.infinity,
                        height: 100,
                        fit: BoxFit.cover,
                        backgroundColor: _accent.withOpacity(0.2),
                      )
                    : Container(
                        color: _accent.withOpacity(0.2),
                        child: Icon(
                          Icons.group,
                          size: 48,
                          color: _textSecondary,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildPrivacyBadge(group.privacy),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, size: 14, color: _textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${group.membersCount} wanachama',
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      if (showRole && group.userRole != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _textSecondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getRoleLabel(group.userRole!),
                            style: const TextStyle(
                              color: _cardBg,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (group.description != null &&
                      group.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      group.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyBadge(String privacy) {
    IconData icon;
    switch (privacy) {
      case 'private':
        icon = Icons.lock;
        break;
      case 'secret':
        icon = Icons.visibility_off;
        break;
      default:
        icon = Icons.public;
    }
    return Icon(icon, size: 16, color: _textSecondary);
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Msimamizi';
      case 'moderator':
        return 'Mdhibiti';
      default:
        return 'Mwanachama';
    }
  }
}

/// Wrapper to satisfy semantic label requirement (accessibility).
class SemanticButton extends StatelessWidget {
  const SemanticButton({
    super.key,
    required this.button,
    required this.label,
  });

  final Widget button;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: button,
    );
  }
}

/// Search delegate for groups (Gundua).
class _GroupSearchDelegate extends SearchDelegate<String> {
  _GroupSearchDelegate({
    required this.groupService,
    required this.currentUserId,
    required this.onGroupTap,
  });

  final GroupService groupService;
  final int currentUserId;
  final void Function(Group group) onGroupTap;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Andika jina la kikundi'));
    }
    return FutureBuilder<GroupListResult>(
      future: groupService.searchGroups(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final result = snapshot.data;
        if (result == null || !result.success) {
          return Center(
            child: Text(
              result?.message ?? 'Imeshindwa kutafuta',
              style: const TextStyle(color: Color(0xFF666666)),
            ),
          );
        }
        final groups = result.groups;
        if (groups.isEmpty) {
          return const Center(
            child: Text(
              'Hakuna vikundi vilivyopatikana',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return ListTile(
              minVerticalPadding: 12,
              contentPadding: EdgeInsets.zero,
              title: Text(
                group.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${group.membersCount} wanachama',
                style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
              ),
              onTap: () => onGroupTap(group),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
