// lib/mygroups/pages/my_groups_page.dart
//
// Profile "Groups" tab body. Extracted from profile_screen.dart's
// inline `_ProfileGroupsPage`. Renamed to `MyGroupsPage` and made
// public so the profile tab + standalone navigation can both use it.
//
// Includes the `_QuickActionButton` helper used inside the page (it
// was a private widget in profile_screen.dart used only by this page).

import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/group_models.dart';
import '../../widgets/cached_media_image.dart';
import '../../services/group_service.dart';
import '../../screens/groups/groups_screen.dart';
import '../../screens/groups/create_group_screen.dart';
import '../../screens/groups/group_detail_screen.dart';

class MyGroupsPage extends StatefulWidget {
  final int userId;
  final int currentUserId;
  final bool isOwnProfile;

  const MyGroupsPage({
    required this.userId,
    required this.currentUserId,
    required this.isOwnProfile,
  });

  @override
  State<MyGroupsPage> createState() => MyGroupsPageState();
}

class MyGroupsPageState extends State<MyGroupsPage> {
  final GroupService _groupService = GroupService();

  List<Group> _allGroups = [];
  List<GroupInvitation> _invitations = [];
  bool _isLoading = true;
  String? _error;

  // Categorized groups
  List<Group> get _adminGroups => _allGroups.where((g) =>
      g.userRole == 'admin' || g.creatorId == widget.currentUserId).toList();
  List<Group> get _systemGroups => _allGroups.where((g) => g.isSystem).toList();
  List<Group> get _memberGroups => _allGroups.where((g) =>
      !g.isSystem &&
      g.userRole != 'admin' &&
      g.creatorId != widget.currentUserId).toList();

  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF666666);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _accent = Color(0xFF999999);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadGroups(),
      if (widget.isOwnProfile) _loadInvitations(),
    ]);
  }

  Future<void> _loadGroups() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _groupService.getUserGroups(widget.userId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _allGroups = result.groups;
        } else {
          _error = result.message ?? (AppStringsScope.of(context)?.failedToLoadGroups ?? 'Failed to load groups');
        }
      });
    }
  }

  Future<void> _loadInvitations() async {
    if (!mounted || !widget.isOwnProfile) return;

    final result = await _groupService.getUserInvitations(widget.currentUserId);

    if (mounted) {
      setState(() {
        if (result.success) {
          _invitations = result.invitations;
        }
      });
    }
  }

  Future<void> _handleInvitation(GroupInvitation invitation, String response) async {
    final success = await _groupService.respondToInvitation(invitation.id, response);
    if (mounted) {
      final s = AppStringsScope.of(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response == 'accepted'
                ? (s?.joinedGroup ?? 'Umejiunga na kikundi')
                : (s?.declinedInvitation ?? 'Umekataa mwaliko')),
          ),
        );
        _loadData(); // Refresh both groups and invitations
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s?.actionFailed ?? 'Imeshindwa. Jaribu tena.')),
        );
      }
    }
  }

  void _openGroupDetail(Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailScreen(
          groupId: group.id,
          currentUserId: widget.currentUserId,
        ),
      ),
    ).then((_) {
      if (mounted) _loadData();
    });
  }

  void _createGroup() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGroupScreen(creatorId: widget.currentUserId),
      ),
    );
    if (result == true && mounted) {
      _loadData();
    }
  }

  void _discoverGroups() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupsScreen(currentUserId: widget.currentUserId),
      ),
    ).then((_) {
      if (mounted) _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState(s);
    }

    final hasAnyContent = _allGroups.isNotEmpty || _invitations.isNotEmpty;

    if (!hasAnyContent) {
      return _buildEmptyState(s);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _textPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Quick actions for own profile
          if (widget.isOwnProfile) ...[
            _buildQuickActions(s),
            const SizedBox(height: 16),
          ],

          // Pending invitations section
          if (widget.isOwnProfile && _invitations.isNotEmpty) ...[
            _buildSectionHeader(
              s?.groupInvitations ?? 'Mialiko',
              Icons.mail_outline,
              count: _invitations.length,
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            ..._invitations.map((inv) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildInvitationCard(inv, s),
            )),
            const SizedBox(height: 16),
          ],

          // Admin/Created groups section
          if (_adminGroups.isNotEmpty) ...[
            _buildSectionHeader(
              s?.groupsICreated ?? 'Nilivyounda',
              Icons.admin_panel_settings_outlined,
              count: _adminGroups.length,
            ),
            const SizedBox(height: 8),
            ..._adminGroups.map((group) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildGroupCard(group, s, showAdminBadge: true),
            )),
            const SizedBox(height: 16),
          ],

          // System groups section
          if (_systemGroups.isNotEmpty) ...[
            _buildSectionHeader(
              s?.systemGroups ?? 'Vikundi vya Mfumo',
              Icons.school_outlined,
              count: _systemGroups.length,
              subtitle: s?.systemGroupsSubtitle ?? 'Shule, Mahali, Mwajiri',
            ),
            const SizedBox(height: 8),
            ..._systemGroups.map((group) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildGroupCard(group, s, isSystem: true),
            )),
            const SizedBox(height: 16),
          ],

          // Other member groups section
          if (_memberGroups.isNotEmpty) ...[
            _buildSectionHeader(
              s?.otherGroups ?? 'Vikundi Vingine',
              Icons.group_outlined,
              count: _memberGroups.length,
            ),
            const SizedBox(height: 8),
            ..._memberGroups.map((group) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildGroupCard(group, s),
            )),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuickActions(AppStrings? s) {
    return Row(
      children: [
        Expanded(
          child: _GroupsQuickActionButton(
            icon: Icons.add,
            label: s?.createGroup ?? 'Unda Kikundi',
            onTap: _createGroup,
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GroupsQuickActionButton(
            icon: Icons.search,
            label: s?.discoverGroups ?? 'Gundua',
            onTap: _discoverGroups,
            isPrimary: false,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon, {
    int? count,
    String? subtitle,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? _textPrimary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color ?? _textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (color ?? _textSecondary).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color ?? _textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: _textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Group group, AppStrings? s, {bool showAdminBadge = false, bool isSystem = false}) {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        onTap: () => _openGroupDetail(group),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Group avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSystem ? Colors.blue.shade50 : _accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: group.coverPhotoUrl != null && group.coverPhotoUrl!.isNotEmpty
                    ? CachedMediaImage(
                        imageUrl: group.coverPhotoUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        isSystem ? _getSystemGroupIcon(group.name) : Icons.group,
                        size: 28,
                        color: isSystem ? Colors.blue.shade400 : _textSecondary,
                      ),
              ),
              const SizedBox(width: 12),
              // Group info
              Expanded(
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
                        if (showAdminBadge)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s?.adminBadge ?? 'Msimamizi',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        if (isSystem)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s?.systemBadge ?? 'Mfumo',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 14, color: _textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          s?.membersCount(group.membersCount) ?? '${group.membersCount} wanachama',
                          style: const TextStyle(fontSize: 12, color: _textSecondary),
                        ),
                        const SizedBox(width: 12),
                        _buildPrivacyIndicator(group.privacy, s),
                      ],
                    ),
                    if (group.description != null && group.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        group.description!,
                        style: const TextStyle(fontSize: 12, color: _textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow indicator
              Icon(Icons.chevron_right, color: _accent, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationCard(GroupInvitation invitation, AppStrings? s) {
    final group = invitation.group;
    final inviter = invitation.inviter;

    return Material(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Group avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: group?.coverPhotoUrl != null && group!.coverPhotoUrl!.isNotEmpty
                      ? CachedMediaImage(
                          imageUrl: group.coverPhotoUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.group, size: 24, color: _textSecondary),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group?.name ?? (s?.groups ?? 'Kikundi'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        inviter != null
                            ? (s?.invitedBy(inviter.fullName) ?? 'Umealikwa na ${inviter.fullName}')
                            : (s?.invitedToJoin ?? 'Umealikwa kujiunga'),
                        style: const TextStyle(fontSize: 12, color: _textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _handleInvitation(invitation, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textSecondary,
                        side: BorderSide(color: _accent.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(s?.declineInvitation ?? 'Kataa'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: () => _handleInvitation(invitation, 'accepted'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(s?.acceptInvitation ?? 'Kubali'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyIndicator(String privacy, AppStrings? s) {
    IconData icon;
    String label;
    switch (privacy) {
      case 'private':
        icon = Icons.lock_outline;
        label = s?.privacyPrivate ?? 'Binafsi';
        break;
      case 'secret':
        icon = Icons.visibility_off_outlined;
        label = s?.privacySecret ?? 'Siri';
        break;
      default:
        icon = Icons.public;
        label = s?.privacyPublic ?? 'Wazi';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _textSecondary),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: _textSecondary)),
      ],
    );
  }

  IconData _getSystemGroupIcon(String groupName) {
    final nameLower = groupName.toLowerCase();
    if (nameLower.contains('shule') || nameLower.contains('school') || nameLower.contains('msingi')) {
      return Icons.school_outlined;
    }
    if (nameLower.contains('chuo') || nameLower.contains('university')) {
      return Icons.account_balance_outlined;
    }
    if (nameLower.contains('kazi') || nameLower.contains('employer') || nameLower.contains('mwajiri')) {
      return Icons.work_outline;
    }
    if (nameLower.contains('mkoa') || nameLower.contains('wilaya') || nameLower.contains('location')) {
      return Icons.location_on_outlined;
    }
    return Icons.groups_outlined;
  }

  Widget _buildErrorState(AppStrings? s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: _textSecondary),
            const SizedBox(height: 16),
            Text(
              _error ?? (s?.somethingWrong ?? 'Kuna tatizo'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: Text(s?.retry ?? 'Jaribu tena'),
                style: FilledButton.styleFrom(
                  backgroundColor: _textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppStrings? s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 64, color: _accent),
            const SizedBox(height: 16),
            Text(
              s?.groups ?? 'Vikundi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isOwnProfile
                  ? (s?.noGroupsYet ?? 'Hujajiunga na kikundi chochote bado')
                  : (s?.noGroups ?? 'Hakuna vikundi'),
              style: const TextStyle(fontSize: 14, color: _textSecondary),
              textAlign: TextAlign.center,
            ),
            if (widget.isOwnProfile) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _discoverGroups,
                  icon: const Icon(Icons.search),
                  label: Text(s?.searchGroups ?? 'Tafuta Vikundi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textPrimary,
                    side: const BorderSide(color: _textPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _createGroup,
                  icon: const Icon(Icons.add),
                  label: Text(s?.createGroup ?? 'Unda Kikundi'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
}

/// Quick action button for groups page
class _GroupsQuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _GroupsQuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF1A1A1A);
    const cardBg = Color(0xFFFFFFFF);

    return Material(
      color: isPrimary ? textPrimary : cardBg,
      borderRadius: BorderRadius.circular(12),
      elevation: isPrimary ? 0 : 1,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: isPrimary
              ? null
              : BoxDecoration(
                  border: Border.all(color: textPrimary.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isPrimary ? cardBg : textPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? cardBg : textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
