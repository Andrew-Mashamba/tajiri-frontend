import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/friend_models.dart';
import '../../my_family/models/my_family_models.dart';
import '../../my_family/services/my_family_service.dart';
import '../../services/friend_service.dart';
import '../../services/message_service.dart';
import '../../widgets/user_avatar.dart';

/// Type of stats list to display
enum ProfileStatsType {
  followers,
  following,
  subscribers,
  friends,
  family,
}

/// Bottom sheet to display profile stats lists (followers, following, subscribers, friends)
class ProfileStatsBottomSheet extends StatefulWidget {
  final int userId;
  final int currentUserId;
  final ProfileStatsType statsType;
  final int initialCount;

  const ProfileStatsBottomSheet({
    super.key,
    required this.userId,
    required this.currentUserId,
    required this.statsType,
    required this.initialCount,
  });

  /// Show the bottom sheet. Read-only public view — no add/edit
  /// affordances. Family management lives in MyFamilyModule.
  static Future<void> show(
    BuildContext context, {
    required int userId,
    required int currentUserId,
    required ProfileStatsType statsType,
    required int initialCount,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProfileStatsBottomSheet(
        userId: userId,
        currentUserId: currentUserId,
        statsType: statsType,
        initialCount: initialCount,
      ),
    );
  }

  @override
  State<ProfileStatsBottomSheet> createState() => _ProfileStatsBottomSheetState();
}

class _ProfileStatsBottomSheetState extends State<ProfileStatsBottomSheet> {
  static const Color _kPrimary = Color(0xFF1A1A1A);

  final FriendService _friendService = FriendService();
  final MessageService _messageService = MessageService();
  final MyFamilyService _familyService = MyFamilyService();

  List<FollowUser> _users = [];
  /// Family-specific list. Populated when [statsType] == family. We keep a
  /// separate list because FamilyMember doesn't map cleanly to FollowUser
  /// (no follow/friendship state, has relationship label, may not be a
  /// linked TAJIRI account).
  List<FamilyMember> _familyMembers = [];
  bool _isLoading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Family is a separate non-paginated branch.
    if (widget.statsType == ProfileStatsType.family) {
      final familyResult = await _familyService.getMembers(widget.userId);
      if (!mounted) return;
      if (familyResult.success) {
        setState(() {
          _isLoading = false;
          _familyMembers = familyResult.items;
          _lastPage = 1; // family list isn't paginated
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = familyResult.message;
        });
      }
      return;
    }

    FollowListResult result;

    switch (widget.statsType) {
      case ProfileStatsType.followers:
        result = await _friendService.getFollowers(
          userId: widget.userId,
          currentUserId: widget.currentUserId,
          page: _page,
        );
        break;
      case ProfileStatsType.following:
        result = await _friendService.getFollowing(
          userId: widget.userId,
          currentUserId: widget.currentUserId,
          page: _page,
        );
        break;
      case ProfileStatsType.subscribers:
        result = await _friendService.getSubscribers(
          userId: widget.userId,
          currentUserId: widget.currentUserId,
          page: _page,
        );
        break;
      case ProfileStatsType.family:
        // Already handled above the switch.
        return;
      case ProfileStatsType.friends:
        // For friends, convert UserProfile to FollowUser
        final friendsResult = await _friendService.getFriends(
          userId: widget.userId,
          page: _page,
        );
        if (!mounted) return;
        if (friendsResult.success) {
          final followUsers = friendsResult.friends.map((u) => FollowUser(
            id: u.id,
            firstName: u.firstName,
            lastName: u.lastName,
            username: u.username,
            profilePhotoPath: u.profilePhotoPath,
            bio: u.bio,
            locationString: u.location,
            isOnline: u.isOnline,
            isFriend: true,
            friendshipStatus: 'friends',
            mutualFriendsCount: u.mutualFriendsCount,
          )).toList();
          setState(() {
            _isLoading = false;
            _users = followUsers;
            _lastPage = friendsResult.meta?.lastPage ?? 1;
          });
        } else {
          setState(() {
            _isLoading = false;
            _error = friendsResult.message;
          });
        }
        return;
    }

    if (!mounted) return;
    if (result.success) {
      setState(() {
        _isLoading = false;
        _users = result.users;
        _lastPage = result.meta?.lastPage ?? 1;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = result.message;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _lastPage) return;

    setState(() => _loadingMore = true);
    _page++;

    // Handle friends case separately since it uses a different result type
    if (widget.statsType == ProfileStatsType.friends) {
      final friendsResult = await _friendService.getFriends(
        userId: widget.userId,
        page: _page,
      );
      if (!mounted) return;
      if (friendsResult.success) {
        final followUsers = friendsResult.friends.map((u) => FollowUser(
          id: u.id,
          firstName: u.firstName,
          lastName: u.lastName,
          username: u.username,
          profilePhotoPath: u.profilePhotoPath,
          bio: u.bio,
          locationString: u.location,
          isOnline: u.isOnline,
          isFriend: true,
          friendshipStatus: 'friends',
          mutualFriendsCount: u.mutualFriendsCount,
        )).toList();
        setState(() {
          _loadingMore = false;
          _users.addAll(followUsers);
        });
      } else {
        setState(() => _loadingMore = false);
      }
      return;
    }

    // Handle followers/following/subscribers
    late final FollowListResult result;
    switch (widget.statsType) {
      case ProfileStatsType.followers:
        result = await _friendService.getFollowers(
          userId: widget.userId,
          currentUserId: widget.currentUserId,
          page: _page,
        );
        break;
      case ProfileStatsType.following:
        result = await _friendService.getFollowing(
          userId: widget.userId,
          currentUserId: widget.currentUserId,
          page: _page,
        );
        break;
      case ProfileStatsType.subscribers:
        result = await _friendService.getSubscribers(
          userId: widget.userId,
          currentUserId: widget.currentUserId,
          page: _page,
        );
        break;
      case ProfileStatsType.friends:
      case ProfileStatsType.family:
        // Already handled above
        return;
    }

    if (!mounted) return;
    if (result.success) {
      setState(() {
        _loadingMore = false;
        _users.addAll(result.users);
      });
    } else {
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    _page = 1;
    await _loadData();
  }

  void _updateUserInList(int userId, FollowUser updated) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1 && mounted) {
      setState(() {
        _users[index] = updated;
      });
    }
  }

  String get _title {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    switch (widget.statsType) {
      case ProfileStatsType.followers:
        return s?.followers ?? 'Followers';
      case ProfileStatsType.following:
        return s?.following ?? 'Following';
      case ProfileStatsType.subscribers:
        return s?.subscribers ?? 'Subscribers';
      case ProfileStatsType.friends:
        return s?.friends ?? 'Friends';
      case ProfileStatsType.family:
        return isSw ? 'Familia' : 'Family';
    }
  }

  IconData get _emptyIcon {
    switch (widget.statsType) {
      case ProfileStatsType.followers:
        return Icons.people_outline;
      case ProfileStatsType.following:
        return Icons.person_add_outlined;
      case ProfileStatsType.subscribers:
        return Icons.card_membership_outlined;
      case ProfileStatsType.friends:
        return Icons.group_outlined;
      case ProfileStatsType.family:
        return Icons.family_restroom_outlined;
    }
  }

  String get _emptyMessage {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    switch (widget.statsType) {
      case ProfileStatsType.followers:
        return s?.noFollowers ?? 'No followers yet';
      case ProfileStatsType.following:
        return s?.noFollowing ?? 'Not following anyone yet';
      case ProfileStatsType.subscribers:
        return s?.noSubscribers ?? 'No subscribers yet';
      case ProfileStatsType.friends:
        return s?.noFriends ?? 'No friends yet';
      case ProfileStatsType.family:
        return isSw ? 'Hakuna familia bado' : 'No family members yet';
    }
  }

  @override
  Widget build(BuildContext context) {
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
            _buildHeader(),
            const Divider(height: 1),
            Expanded(child: _buildContent()),
          ],
        ),
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

  Widget _buildHeader() {
    // Family count tracks the loaded list (so a fresh refetch is reflected
    // even if the owner edited the list elsewhere). Other types keep the
    // initialCount that was passed in.
    final count = widget.statsType == ProfileStatsType.family
        ? _familyMembers.length
        : widget.initialCount;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$_title ($count)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            iconSize: 24,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loadData,
                child: Text(AppStringsScope.of(context)?.retry ?? 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final isFamily = widget.statsType == ProfileStatsType.family;
    final isEmpty = isFamily ? _familyMembers.isEmpty : _users.isEmpty;

    if (isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_emptyIcon, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _emptyMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (isFamily) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: _familyMembers.length,
          itemBuilder: (context, index) {
            final member = _familyMembers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FamilyMemberCard(member: member),
            );
          },
        ),
      );
    }

    final hasMore = _page < _lastPage;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _users.length + (hasMore || _loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _users.length) {
            if (_loadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              );
            }
            if (hasMore) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
            }
            return const SizedBox.shrink();
          }

          final user = _users[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _UserCard(
              user: user,
              currentUserId: widget.currentUserId,
              statsType: widget.statsType,
              friendService: _friendService,
              messageService: _messageService,
              onStatusChanged: (updated) => _updateUserInList(user.id, updated),
            ),
          );
        },
      ),
    );
  }
}

/// Individual user card with avatar, info, and action buttons
class _UserCard extends StatelessWidget {
  final FollowUser user;
  final int currentUserId;
  final ProfileStatsType statsType;
  final FriendService friendService;
  final MessageService messageService;
  final void Function(FollowUser) onStatusChanged;

  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);
  static const Color _kOnline = Color(0xFF22C55E);
  static const double _kCardRadius = 12.0;
  static const double _kAvatarRadius = 24.0;

  const _UserCard({
    required this.user,
    required this.currentUserId,
    required this.statsType,
    required this.friendService,
    required this.messageService,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelf = user.id == currentUserId;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/profile/${user.id}');
        },
        borderRadius: BorderRadius.circular(_kCardRadius),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_kCardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar with online indicator
              Stack(
                clipBehavior: Clip.none,
                children: [
                  UserAvatar(
                    photoUrl: user.profilePhotoUrl,
                    name: user.fullName,
                    radius: _kAvatarRadius,
                  ),
                  if (user.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _kOnline,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        color: _kPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.username != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                          color: _kSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (user.mutualFriendsCount != null && user.mutualFriendsCount! > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${user.mutualFriendsCount} mutual friends',
                        style: TextStyle(
                          color: _kSecondary.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Action buttons
              if (!isSelf)
                _ActionButton(
                  user: user,
                  currentUserId: currentUserId,
                  statsType: statsType,
                  friendService: friendService,
                  messageService: messageService,
                  onStatusChanged: onStatusChanged,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Action button (Follow/Unfollow/Add Friend/etc.)
class _ActionButton extends StatefulWidget {
  final FollowUser user;
  final int currentUserId;
  final ProfileStatsType statsType;
  final FriendService friendService;
  final MessageService messageService;
  final void Function(FollowUser) onStatusChanged;

  const _ActionButton({
    required this.user,
    required this.currentUserId,
    required this.statsType,
    required this.friendService,
    required this.messageService,
    required this.onStatusChanged,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);
  static const Color _kOnline = Color(0xFF22C55E);

  bool _isLoading = false;

  Future<void> _handleFollow() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final isCurrentlyFollowing = widget.user.isFollowing;
    final success = isCurrentlyFollowing
        ? await widget.friendService.unfollowUser(widget.currentUserId, widget.user.id)
        : await widget.friendService.followUser(widget.currentUserId, widget.user.id);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      widget.onStatusChanged(
        widget.user.copyWith(isFollowing: !isCurrentlyFollowing),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCurrentlyFollowing
                ? (AppStringsScope.of(context)?.unfollowed ?? 'Unfollowed')
                : (AppStringsScope.of(context)?.followed ?? 'Following'),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleFriendRequest() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final status = widget.user.friendshipStatus ?? 'none';
    bool success = false;
    String? newStatus;
    String? message;

    switch (status) {
      case 'none':
        success = await widget.friendService.sendFriendRequest(
          widget.currentUserId,
          widget.user.id,
        );
        newStatus = 'pending_sent';
        message = AppStringsScope.of(context)?.friendRequestSent ?? 'Friend request sent';
        break;
      case 'pending_sent':
        success = await widget.friendService.cancelFriendRequest(
          widget.currentUserId,
          widget.user.id,
        );
        newStatus = 'none';
        message = AppStringsScope.of(context)?.requestCancelled ?? 'Request cancelled';
        break;
      case 'pending_received':
        success = await widget.friendService.acceptFriendRequest(
          widget.currentUserId,
          widget.user.id,
        );
        newStatus = 'friends';
        message = AppStringsScope.of(context)?.nowFriends ?? 'Now friends!';
        break;
      case 'friends':
        success = await widget.friendService.removeFriend(
          widget.currentUserId,
          widget.user.id,
        );
        newStatus = 'none';
        message = AppStringsScope.of(context)?.friendRemoved ?? 'Friend removed';
        break;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success && newStatus != null) {
      widget.onStatusChanged(
        widget.user.copyWith(
          friendshipStatus: newStatus,
          isFriend: newStatus == 'friends',
        ),
      );
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine which button to show based on stats type and current state
    switch (widget.statsType) {
      case ProfileStatsType.followers:
      case ProfileStatsType.following:
        return _buildFollowButton();
      case ProfileStatsType.subscribers:
        return _buildSubscribeButton();
      case ProfileStatsType.friends:
        return _buildFriendButton();
      case ProfileStatsType.family:
        // Family list never renders this _ActionButton — has its own card.
        return const SizedBox.shrink();
    }
  }

  Widget _buildFollowButton() {
    final isFollowing = widget.user.isFollowing;

    if (_isLoading) {
      return Container(
        width: 90,
        height: 36,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (isFollowing) {
      return OutlinedButton(
        onPressed: _handleFollow,
        style: OutlinedButton.styleFrom(
          foregroundColor: _kSecondary,
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(90, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          AppStringsScope.of(context)?.following ?? 'Following',
          style: const TextStyle(fontSize: 13),
        ),
      );
    }

    return ElevatedButton(
      onPressed: _handleFollow,
      style: ElevatedButton.styleFrom(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(90, 36),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        AppStringsScope.of(context)?.follow ?? 'Follow',
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildSubscribeButton() {
    // For subscribers, show follow button as well
    return _buildFollowButton();
  }

  Widget _buildFriendButton() {
    final status = widget.user.friendshipStatus ?? 'none';

    if (_isLoading) {
      return Container(
        width: 90,
        height: 36,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    switch (status) {
      case 'friends':
        return OutlinedButton(
          onPressed: _handleFriendRequest,
          style: OutlinedButton.styleFrom(
            foregroundColor: _kSecondary,
            side: BorderSide(color: Colors.grey.shade300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(80, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, size: 16),
              const SizedBox(width: 4),
              Text(
                AppStringsScope.of(context)?.friends ?? 'Friends',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        );

      case 'pending_sent':
        return OutlinedButton(
          onPressed: _handleFriendRequest,
          style: OutlinedButton.styleFrom(
            foregroundColor: _kSecondary,
            side: BorderSide(color: Colors.grey.shade300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(80, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            AppStringsScope.of(context)?.requested ?? 'Requested',
            style: const TextStyle(fontSize: 13),
          ),
        );

      case 'pending_received':
        return ElevatedButton(
          onPressed: _handleFriendRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kOnline,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(80, 36),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            AppStringsScope.of(context)?.accept ?? 'Accept',
            style: const TextStyle(fontSize: 13),
          ),
        );

      case 'none':
      default:
        return ElevatedButton.icon(
          onPressed: _handleFriendRequest,
          icon: const Icon(Icons.person_add, size: 16),
          label: Text(
            AppStringsScope.of(context)?.addFriend ?? 'Add',
            style: const TextStyle(fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(80, 36),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
    }
  }
}

/// Card for one family member inside the family bottom sheet.
/// Shows avatar + name + relationship label + (when linked) a "Tajiri" badge.
/// Tapping a *linked* member opens their profile screen via /profile/:id.
class _FamilyMemberCard extends StatelessWidget {
  final FamilyMember member;
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);

  const _FamilyMemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    final isLinked = member.isLinked && member.userId != null && member.userId! > 0;
    final relationshipLabel = _localizedRelationship(member.relationship, isSw);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLinked
            ? () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile/${member.userId}');
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              UserAvatar(
                photoUrl: member.photoUrl,
                name: member.name,
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        color: _kPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            relationshipLabel,
                            style: const TextStyle(
                              color: _kSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLinked) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'TAJIRI',
                              style: TextStyle(
                                color: Color(0xFF1B5E20),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isLinked)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: _kSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _localizedRelationship(Relationship r, bool isSw) {
    switch (r) {
      case Relationship.parent:
        return isSw ? 'Mzazi' : 'Parent';
      case Relationship.child:
        return isSw ? 'Mtoto' : 'Child';
      case Relationship.spouse:
        return isSw ? 'Mke/Mume' : 'Spouse';
      case Relationship.sibling:
        return isSw ? 'Ndugu' : 'Sibling';
      case Relationship.grandparent:
        return isSw ? 'Babu/Bibi' : 'Grandparent';
      case Relationship.grandchild:
        return isSw ? 'Mjukuu' : 'Grandchild';
      case Relationship.aunt:
        return isSw ? 'Shangazi' : 'Aunt';
      case Relationship.uncle:
        return isSw ? 'Mjomba' : 'Uncle';
      case Relationship.cousin:
        return isSw ? 'Binamu' : 'Cousin';
      case Relationship.niece:
        return isSw ? 'Mpwa wa kike' : 'Niece';
      case Relationship.nephew:
        return isSw ? 'Mpwa wa kiume' : 'Nephew';
      case Relationship.inLaw:
        return isSw ? 'Mwana wa ndugu' : 'In-law';
      case Relationship.stepChild:
        return isSw ? 'Mtoto wa kambo' : 'Step-child';
      case Relationship.stepParent:
        return isSw ? 'Mzazi wa kambo' : 'Step-parent';
      case Relationship.guardian:
        return isSw ? 'Mlezi' : 'Guardian';
      case Relationship.other:
        return isSw ? 'Mwingine' : 'Other';
    }
  }
}
