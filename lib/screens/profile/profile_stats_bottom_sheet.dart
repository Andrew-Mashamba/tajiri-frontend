import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/friend_models.dart';
import '../../services/friend_service.dart';
import '../../services/message_service.dart';
import '../../widgets/user_avatar.dart';

/// Type of stats list to display
enum ProfileStatsType {
  followers,
  following,
  subscribers,
  friends,
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

  /// Show the bottom sheet
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

  List<FollowUser> _users = [];
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
    switch (widget.statsType) {
      case ProfileStatsType.followers:
        return s?.followers ?? 'Followers';
      case ProfileStatsType.following:
        return s?.following ?? 'Following';
      case ProfileStatsType.subscribers:
        return s?.subscribers ?? 'Subscribers';
      case ProfileStatsType.friends:
        return s?.friends ?? 'Friends';
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
    }
  }

  String get _emptyMessage {
    final s = AppStringsScope.of(context);
    switch (widget.statsType) {
      case ProfileStatsType.followers:
        return s?.noFollowers ?? 'No followers yet';
      case ProfileStatsType.following:
        return s?.noFollowing ?? 'Not following anyone yet';
      case ProfileStatsType.subscribers:
        return s?.noSubscribers ?? 'No subscribers yet';
      case ProfileStatsType.friends:
        return s?.noFriends ?? 'No friends yet';
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$_title (${widget.initialCount})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
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

    if (_users.isEmpty) {
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
