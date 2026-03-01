import 'dart:io';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_strings_scope.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../../models/profile_models.dart';
import '../../models/post_models.dart';
import '../../models/profile_tab_config.dart';
import '../../services/profile_service.dart';
import '../../services/post_service.dart';
import '../../services/friend_service.dart';
import '../../services/message_service.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/share_post_sheet.dart';
import '../../widgets/cached_media_image.dart';
import '../../widgets/gallery/photo_gallery_widget.dart';
import '../../widgets/gallery/music_gallery_widget.dart';
import '../../widgets/gallery/shop_gallery_widget.dart';
import '../feed/livegallerywidget_screen.dart';
import '../michangogallerywidget_screen.dart';
import '../campaigns/create_campaign_screen.dart';
import '../registration/registration_screen.dart';
import '../settings/settings_screen.dart';
import '../wallet/wallet_screen.dart';
import '../wallet/subscribe_to_creator_screen.dart';
import '../wallet/send_tip_screen.dart';
import '../messages/callhistory_screen.dart';
import '../feed/create_post_screen.dart';
import '../feed/edit_post_screen.dart';
import '../feed/post_detail_screen.dart';
import '../feed/comment_bottom_sheet.dart';
import '../feed/videogallerywidget_screen.dart';
import '../groups/groups_screen.dart';
import '../groups/create_group_screen.dart';
import 'profile_stats_bottom_sheet.dart';
class ProfileScreen extends StatefulWidget {
  final int userId;
  final int? currentUserId;

  const ProfileScreen({
    super.key,
    required this.userId,
    this.currentUserId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final ProfileService _profileService = ProfileService();
  final PostService _postService = PostService();
  final FriendService _friendService = FriendService();
  final MessageService _messageService = MessageService();
  final ImagePicker _imagePicker = ImagePicker();

  TabController? _tabController;

  FullProfile? _profile;
  bool _isLoading = true;
  String? _error;

  // Tab configuration
  List<ProfileTabConfig> _allTabs = [];
  List<ProfileTabConfig> _enabledTabs = [];

  // Posts tab data
  List<Post> _posts = [];
  bool _isLoadingPosts = false;
  // ignore: unused_field - used for future load-more pagination
  bool _hasMorePosts = true;
  int _postsPage = 1;

  // Profile photo upload
  bool _isUploadingPhoto = false;
  // Cover photo upload
  bool _isUploadingCoverPhoto = false;
  // Send friend request in progress
  bool _isSendingFriendRequest = false;

  int get _currentUserId => widget.currentUserId ?? widget.userId;
  bool get _isOwnProfile => widget.userId == _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadTabsAndProfile();
  }

  Future<void> _loadTabsAndProfile() async {
    debugPrint('[ProfileScreen] _loadTabsAndProfile started for userId: ${widget.userId}');

    final storage = await LocalStorageService.getInstance();
    debugPrint('[ProfileScreen] LocalStorageService loaded');

    _allTabs = storage.getProfileTabs();
    debugPrint('[ProfileScreen] All tabs loaded: ${_allTabs.length}');

    _enabledTabs = _allTabs.where((t) => t.enabled).toList();
    debugPrint('[ProfileScreen] Enabled tabs: ${_enabledTabs.length}');

    // Dispose old controller if exists (e.g., during hot restart)
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();

    if (_enabledTabs.isNotEmpty) {
      _tabController = TabController(
        length: _enabledTabs.length,
        vsync: this,
        animationDuration: const Duration(milliseconds: 280),
      );
      _tabController!.addListener(_onTabChanged);
      debugPrint('[ProfileScreen] TabController created');
    } else {
      debugPrint('[ProfileScreen] WARNING: No enabled tabs!');
    }

    if (mounted) {
      setState(() {});
      _loadProfile();
    } else {
      debugPrint('[ProfileScreen] Widget not mounted, skipping profile load');
    }
  }

  Future<void> _refreshTabs() async {
    if (!mounted) return;

    final storage = await LocalStorageService.getInstance();
    final newTabs = storage.getProfileTabs();
    final newEnabledTabs = newTabs.where((t) => t.enabled).toList();

    // Check if tabs have actually changed
    final tabsChanged = _enabledTabs.length != newEnabledTabs.length ||
        !_enabledTabs.every((t) => newEnabledTabs.any((n) => n.id == t.id && n.order == t.order));

    if (tabsChanged && mounted) {
      // Store old controller to dispose after frame
      final oldController = _tabController;

      _allTabs = newTabs;
      _enabledTabs = newEnabledTabs;

      // Create new controller
      _tabController = TabController(
        length: _enabledTabs.length,
        vsync: this,
        animationDuration: const Duration(milliseconds: 280),
      );
      _tabController!.addListener(_onTabChanged);

      setState(() {});

      // Dispose old controller after the frame completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldController?.removeListener(_onTabChanged);
        oldController?.dispose();
      });
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _tabController = null;
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController == null || _enabledTabs.isEmpty) return;
    setState(() {}); // Update custom tab bar selected state (e.g. after swipe)
    final currentTabId = _enabledTabs[_tabController!.index].id;
    if (currentTabId == 'posts' && _posts.isEmpty && !_isLoadingPosts) {
      _loadPosts();
    }
    // Photos tab is now handled by PhotoGalleryWidget internally
  }

  Future<void> _loadProfile() async {
    debugPrint('[ProfileScreen] _loadProfile started');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    debugPrint('[ProfileScreen] Calling profileService.getProfile for userId: ${widget.userId}');
    final result = await _profileService.getProfile(
      userId: widget.userId,
      currentUserId: _currentUserId,
    );
    debugPrint('[ProfileScreen] getProfile returned: success=${result.success}, message=${result.message}');

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _profile = result.profile;
          debugPrint('[ProfileScreen] Profile loaded: ${_profile?.fullName}');
          // Load initial posts
          _loadPosts();
        } else {
          _error = result.message;
          debugPrint('[ProfileScreen] Profile error: $_error');
        }
      });
    } else {
      debugPrint('[ProfileScreen] Widget not mounted after profile load');
    }
  }

  Future<void> _loadPosts() async {
    debugPrint('[ProfileScreen] _loadPosts called, userId: ${widget.userId}, page: $_postsPage');
    if (_isLoadingPosts) {
      debugPrint('[ProfileScreen] Already loading posts, skipping');
      return;
    }

    setState(() => _isLoadingPosts = true);

    final currentUserId = widget.currentUserId ?? widget.userId;
    final result = await _postService.getPosts(
      userId: currentUserId,
      profileUserId: widget.userId,
      page: _postsPage,
      perPage: 20,
    );

    debugPrint('[ProfileScreen] Posts result: success=${result.success}, count=${result.posts.length}');
    if (!result.success) {
      debugPrint('[ProfileScreen] Error: ${result.message}');
    }

    if (mounted) {
      setState(() {
        _isLoadingPosts = false;
        if (result.success) {
          _posts = result.posts;
          _hasMorePosts = result.meta?.hasMore ?? false;
          debugPrint('[ProfileScreen] Posts loaded: ${_posts.length} posts');
        }
      });
    }
  }


  Future<void> _updateProfilePhoto() async {
    if (_isUploadingPhoto || !_isOwnProfile) return;

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);

    final result = await _profileService.updateProfilePhoto(
      userId: widget.userId,
      photo: File(image.path),
    );

    if (!mounted) return;

    setState(() => _isUploadingPhoto = false);

    if (result.success) {
      // Update local user so profile photo reflects across the app
      final storage = await LocalStorageService.getInstance();
      final user = storage.getUser();
      if (user != null && result.photoUrl != null && user.userId == widget.userId) {
        user.applyServerProfile({'profile_photo_url': result.photoUrl});
        await storage.saveUser(user);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStringsScope.of(context)?.photoUpdated ?? 'Photo updated')),
      );
      _loadProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? (AppStringsScope.of(context)?.photoUpdateFailed ?? 'Failed to update photo'))),
      );
    }
  }

  Future<void> _updateCoverPhoto() async {
    if (_isUploadingCoverPhoto || !_isOwnProfile) return;

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image == null || !mounted) return;

    setState(() => _isUploadingCoverPhoto = true);

    final result = await _profileService.updateCoverPhoto(
      userId: widget.userId,
      photo: File(image.path),
    );

    if (!mounted) return;

    setState(() => _isUploadingCoverPhoto = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStringsScope.of(context)?.coverPhotoUpdated ?? 'Cover photo updated')),
      );
      _loadProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? (AppStringsScope.of(context)?.coverPhotoUpdateFailed ?? 'Failed to update photo'))),
      );
    }
  }

  Future<void> _openChatWithProfileUser() async {
    final result = await _messageService.getPrivateConversation(
      _currentUserId,
      widget.userId,
    );
    if (!mounted) return;
    if (result.success && result.conversation != null) {
      Navigator.pushNamed(
        context,
        '/chat/${result.conversation!.id}',
        arguments: <String, dynamic>{'conversation': result.conversation},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Could not open chat')),
      );
    }
  }

  Future<void> _handleFriendAction() async {
    if (_profile == null) return;

    final status = _profile!.friendshipStatus;

    switch (status) {
      case FriendshipStatus.none:
        // Send friend request
        if (_isSendingFriendRequest) return;
        setState(() => _isSendingFriendRequest = true);
        final result = await _friendService.sendFriendRequest(
          _currentUserId,
          widget.userId,
        );
        if (!mounted) return;
        setState(() => _isSendingFriendRequest = false);
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStringsScope.of(context)?.friendRequestSent ?? 'Friend request sent')),
          );
          _loadProfile();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStringsScope.of(context)?.friendRequestFailed ?? 'Failed to send friend request. Try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
      case FriendshipStatus.pending:
        // Accept friend request
        final result = await _friendService.acceptFriendRequest(
          _currentUserId,
          widget.userId,
        );
        if (mounted && result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStringsScope.of(context)?.nowFriends ?? 'Now friends!')),
          );
          _loadProfile();
        }
        break;
      case FriendshipStatus.requested:
        // Cancel request
        final result = await _friendService.cancelFriendRequest(
          _currentUserId,
          widget.userId,
        );
        if (mounted && result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStringsScope.of(context)?.requestCancelled ?? 'Request cancelled')),
          );
          _loadProfile();
        }
        break;
      case FriendshipStatus.friends:
        // Show unfriend dialog
        _showUnfriendDialog();
        break;
      case FriendshipStatus.self:
      case null:
        // Edit profile
        _showEditProfileDialog();
        break;
    }
  }

  void _showUnfriendDialog() {
    final s = AppStringsScope.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s?.removeFriendTitle ?? 'Remove friend'),
        content: Text(s?.removeFriendMessage(_profile?.firstName ?? '') ?? 'Are you sure you want to remove this friend?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s?.no ?? 'No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _friendService.removeFriend(
                _currentUserId,
                widget.userId,
              );
              if (mounted && result) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s?.friendRemoved ?? 'Friend removed')),
                );
                _loadProfile();
              }
            },
            child: Text(s?.yes ?? 'Yes', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final s = AppStringsScope.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s?.editProfileComingSoon ?? 'Edit profile - Coming soon')),
    );
  }

  void _showLogoutDialog() {
    final s = AppStringsScope.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s?.logoutConfirmTitle ?? 'Log out'),
        content: Text(s?.logoutConfirmMessage ?? 'Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s?.no ?? 'No'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final storage = await LocalStorageService.getInstance();
                await storage.clearUser();
              } catch (e) {
                debugPrint('Error clearing user: $e');
              }
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const RegistrationScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
            child: Text(s?.yesLogout ?? 'Yes, log out'),
          ),
        ],
      ),
    );
  }

  static const Color _backgroundLight = Color(0xFFFAFAFA);
  static const Color _secondaryText = Color(0xFF666666);

  /// Format count for profile stats (e.g. 1200 → 1.2K, 1500000 → 1.5M)
  static String _formatStatCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}K';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _backgroundLight,
        body: SafeArea(
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: _backgroundLight,
        appBar: AppBar(backgroundColor: Colors.white),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: _secondaryText, fontSize: 14),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loadProfile,
                      child: Text(AppStringsScope.of(context)?.retry ?? 'Retry'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Wait for tabs to load
    if (_tabController == null || _enabledTabs.isEmpty) {
      return Scaffold(
        backgroundColor: _backgroundLight,
        body: SafeArea(
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundLight,
      body: SafeArea(
        child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildProfileInfo()),
            SliverPersistentHeader(
              pinned: true,
              delegate: _ProfileTabBarDelegate(
                child: _buildCustomProfileTabBar(context),
                height: _kProfileTabBarHeight,
                selectedIndex: _tabController?.index ?? 0,
              ),
            ),
          ];
        },
        body: TabBarView(
          key: ValueKey('tabview_${_enabledTabs.map((t) => t.id).join(',')}'),
          controller: _tabController,
          children: _enabledTabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            final isActive = (_tabController?.index ?? 0) == index;
            return IgnorePointer(
              ignoring: !isActive,
              child: _buildTabContent(tab.id),
            );
          }).toList(),
        ),
      ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final s = AppStringsScope.of(context);
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: TajiriAppBar.surfaceColor,
      foregroundColor: TajiriAppBar.primaryTextColor,
      iconTheme: TajiriAppBar.iconTheme,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        _isOwnProfile ? (s?.profileTab ?? 'Me') : (_profile?.fullName ?? ''),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: [
        if (_isOwnProfile) ...[
          TajiriAppBar.action(
            icon: HeroIcons.cog6Tooth,
            tooltip: AppStringsScope.of(context)?.settings ?? 'Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(currentUserId: _currentUserId),
                ),
              );
              // Refresh profile (e.g. username) and tabs when returning from settings
              if (mounted) {
                _loadProfile();
                _refreshTabs();
              }
            },
          ),
          PopupMenuButton<String>(
            icon: HeroIcon(
              HeroIcons.ellipsisVertical,
              style: HeroIconStyle.outline,
              size: TajiriAppBar.actionIconSize,
              color: TajiriAppBar.primaryTextColor,
            ),
            onSelected: (value) {
              switch (value) {
                case 'edit_profile':
                  _showEditProfileDialog();
                  break;
                case 'wallet':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WalletScreen(currentUserId: _currentUserId),
                    ),
                  );
                  break;
                case 'calls':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CallHistoryScreen(currentUserId: _currentUserId),
                    ),
                  );
                  break;
                case 'logout':
                  _showLogoutDialog();
                  break;
              }
            },
            itemBuilder: (ctx) {
              final s = AppStringsScope.of(ctx);
              return [
                PopupMenuItem(
                  value: 'edit_profile',
                  child: Row(
                    children: [
                      const Icon(Icons.edit),
                      const SizedBox(width: 8),
                      Text(s?.editProfile ?? 'Edit profile'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'wallet',
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet),
                      const SizedBox(width: 8),
                      Text(s?.tajiriPay ?? 'Tajiri Pay'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'calls',
                  child: Row(
                    children: [
                      const Icon(Icons.phone),
                      const SizedBox(width: 8),
                      Text(s?.calls ?? 'Calls'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(s?.logout ?? 'Log out', style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover Photo
            _profile?.coverPhotoUrl != null && _profile!.coverPhotoUrl!.isNotEmpty
                ? CachedMediaImage(
                    imageUrl: _profile!.coverPhotoUrl,
                    fit: BoxFit.cover,
                    errorWidget: _buildDefaultCover(),
                  )
                : _buildDefaultCover(),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // Edit cover button (min 48dp touch target)
            if (_isOwnProfile)
              Positioned(
                right: 16,
                bottom: 100,
                child: IconButton(
                  onPressed: _updateCoverPhoto,
                  icon: const Icon(Icons.camera_alt),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ),

            // Profile photo and name
            Positioned(
              left: 16,
              bottom: 16,
              right: 16,
              child: Row(
                children: [
                  // Profile photo — circular display; whole avatar tappable (≥48dp)
                  Semantics(
                    button: _isOwnProfile,
                    label: _isOwnProfile ? (AppStringsScope.of(context)?.changeProfilePhoto ?? 'Change profile photo') : null,
                    child: GestureDetector(
                      onTap: _isOwnProfile ? _updateProfilePhoto : null,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _profile?.profilePhotoUrl != null &&
                                      _profile!.profilePhotoUrl!.isNotEmpty
                                  ? CachedMediaImage(
                                      imageUrl: _profile!.profilePhotoUrl!,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      child: Text(
                                        _profile?.initials ?? '?',
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          if (_isOwnProfile)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 48,
                                height: 48,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          if (_isUploadingPhoto)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black54,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Name and username
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile?.fullName ?? '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_profile?.username != null)
                          Text(
                            '@${_profile!.username}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
    );
  }

  /// Custom horizontal icon + label tab row (no Material TabBar = no overlay/ripple).
  /// Soft circular background for icons, iOS-like spacing.
  static const double _kProfileTabBarHeight = 112;
  static const double _kProfileTabItemWidth = 80;

  Widget _buildCustomProfileTabBar(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final selectedIndex = _tabController?.index ?? 0;

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Container(
        height: _kProfileTabBarHeight,
        padding: EdgeInsets.zero,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _enabledTabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final tab = _enabledTabs[index];
            final isSelected = selectedIndex == index;
            return SizedBox(
              width: _kProfileTabItemWidth,
              child: Container(
                decoration: BoxDecoration(
                  border: isSelected
                      ? const Border(
                          bottom: BorderSide(color: Colors.black, width: 2),
                        )
                      : null,
                ),
                child: _ProfileCustomTab(
                  icon: _tabIconData(tab.icon),
                  label: AppStringsScope.of(context)?.profileTabLabel(tab.id) ?? tab.label,
                  isSelected: isSelected,
                  primary: primary,
                  onTap: () => _tabController?.animateTo(index),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static IconData _tabIconData(String iconName) {
    switch (iconName) {
      case 'article': return Icons.article_outlined;
      case 'photo_library': return Icons.photo_library_outlined;
      case 'video_library': return Icons.video_library_outlined;
      case 'music_note': return Icons.music_note_outlined;
      case 'live_tv': return Icons.live_tv_outlined;
      case 'volunteer_activism': return Icons.volunteer_activism_outlined;
      case 'group': return Icons.group_outlined;
      case 'folder': return Icons.folder_outlined;
      case 'storefront': return Icons.storefront_outlined;
      case 'people': return Icons.people_outlined;
      case 'info': return Icons.info_outlined;
      default: return Icons.circle_outlined;
    }
  }

  Widget _buildProfileInfo() {
    const cardRadius = 24.0;
    const horizontalPadding = 20.0;
    const sectionSpacing = 20.0;

    final followersCount = _profile?.stats.followersCount ?? 0;
    final followingCount = _profile?.stats.followingCount ?? 0;
    final subscribersCount = _profile?.stats.subscribersCount ?? 0;
    final friendsCount = _profile?.stats.friendsCount ?? 0;

    final List<Widget> columnChildren = <Widget>[
      // 1. Stats row
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _buildStatItem(
            _formatStatCount(followersCount),
            AppStringsScope.of(context)?.followers ?? 'Followers',
            onTap: () => _openStatsBottomSheet(ProfileStatsType.followers, followersCount),
          ),
          _buildStatDivider(),
          _buildStatItem(
            _formatStatCount(followingCount),
            AppStringsScope.of(context)?.following ?? 'Following',
            onTap: () => _openStatsBottomSheet(ProfileStatsType.following, followingCount),
          ),
          _buildStatDivider(),
          _buildStatItem(
            _formatStatCount(subscribersCount),
            AppStringsScope.of(context)?.subscribers ?? 'Subscribers',
            onTap: () => _openStatsBottomSheet(ProfileStatsType.subscribers, subscribersCount),
          ),
          _buildStatDivider(),
          _buildStatItem(
            _formatStatCount(friendsCount),
            AppStringsScope.of(context)?.friends ?? 'Friends',
            onTap: () => _openStatsBottomSheet(ProfileStatsType.friends, friendsCount),
          ),
        ],
      ),
      const SizedBox(height: sectionSpacing),

      // 2. Me page: quick links (Edit left, Settings center, Wallet right) — each in Expanded for bounded layout
      if (_isOwnProfile) ...[
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _MeQuickLink(
                  icon: Icons.edit_outlined,
                  label: AppStringsScope.of(context)?.edit ?? 'Edit',
                  onTap: _showEditProfileDialog,
                ),
              ),
              Expanded(
                child: Center(
                  child: _MeQuickLink(
                    icon: Icons.settings_outlined,
                    label: AppStringsScope.of(context)?.settings ?? 'Settings',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(currentUserId: _currentUserId),
                        ),
                      );
                      if (mounted) {
                        _loadProfile();
                        _refreshTabs();
                      }
                    },
                  ),
                ),
              ),
              Expanded(
                child: _MeQuickLink(
                  icon: Icons.account_balance_wallet_outlined,
                  label: AppStringsScope.of(context)?.wallet ?? 'Wallet',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WalletScreen(currentUserId: _currentUserId),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: sectionSpacing),
      ],

      // 3. Action buttons (when viewing someone else)
      if (!_isOwnProfile)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: ElevatedButton.icon(
                    onPressed: _isSendingFriendRequest ? null : _handleFriendAction,
                    icon: _isSendingFriendRequest
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(_getActionIcon(), size: 18),
                    label: Text(
                      _isSendingFriendRequest
                          ? (AppStringsScope.of(context)?.sending ?? 'Sending...')
                          : _getFollowButtonLabel(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      backgroundColor: _getActionButtonColor(),
                      foregroundColor: _getActionButtonForegroundColor(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubscribeToCreatorScreen(
                            creatorId: widget.userId,
                            currentUserId: _currentUserId,
                            creatorDisplayName: _profile?.fullName,
                          ),
                        ),
                      );
                      if (result == true && mounted) _loadProfile();
                    },
                    icon: const Icon(Icons.card_membership, size: 18),
                    label: const Text('Subscribe'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: OutlinedButton.icon(
                    onPressed: _openChatWithProfileUser,
                    icon: const Icon(Icons.message_outlined, size: 18),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

      // 4. Bio
      if (_profile?.bio != null && _profile!.bio!.isNotEmpty) ...[
        const SizedBox(height: sectionSpacing),
        Text(
          _profile!.bio!,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: Colors.grey.shade700,
          ),
        ),
      ],

      // 5. Interests
      if (_profile?.interests != null && _profile!.interests!.isNotEmpty) ...[
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _profile!.interests!
              .map<Widget>((String interest) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      interest,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],

      // 6. Info section (location, work, education, relationship, joined, mutual friends)
      if (_profile?.location != null ||
          _profile?.currentEmployer != null ||
          _profile?.universityEducation != null ||
          _profile?.relationshipStatus != null) ...[
        const SizedBox(height: sectionSpacing),
        if (_profile?.location != null)
          _buildInfoItem(Icons.location_on_outlined, _profile!.location!.displayText),
        if (_profile?.currentEmployer != null)
          _buildInfoItem(
            Icons.work_outline,
            _profile!.currentEmployer!.jobTitle != null
                ? '${_profile!.currentEmployer!.jobTitle} - ${_profile!.currentEmployer!.employerName}'
                : _profile!.currentEmployer!.employerName ?? '',
          ),
        if (_profile?.universityEducation != null)
          _buildInfoItem(
            Icons.school_outlined,
            _profile!.universityEducation!.universityName ?? '',
          ),
        if (_profile?.relationshipStatus != null)
          _buildInfoItem(Icons.favorite_border, _profile!.relationshipStatusLabel ?? ''),
      ],
      _buildInfoItem(
        Icons.calendar_today_outlined,
        '${AppStringsScope.of(context)?.joined ?? 'Joined'} ${_formatDate(_profile?.createdAt ?? DateTime.now())}',
      ),
      if (!_isOwnProfile &&
          _profile?.mutualFriendsCount != null &&
          _profile!.mutualFriendsCount! > 0) ...[
        const SizedBox(height: 14),
        Material(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.people_outline, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  '${_profile!.mutualFriendsCount} ${AppStringsScope.of(context)?.mutualFriendsCount ?? 'mutual friends'}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(cardRadius),
          topRight: Radius.circular(cardRadius),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: columnChildren,
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 32,
      color: Colors.grey.shade300,
    );
  }


  Widget _buildStatItem(String count, String label, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Text(
                count,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openStatsBottomSheet(ProfileStatsType statsType, int count) {
    ProfileStatsBottomSheet.show(
      context,
      userId: widget.userId,
      currentUserId: _currentUserId,
      statsType: statsType,
      initialCount: count,
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFollowButtonLabel() {
    if (_isOwnProfile) {
      return AppStringsScope.of(context)?.editProfile ?? 'Edit profile';
    }
    switch (_profile?.friendshipStatus) {
      case FriendshipStatus.none:
        return 'Follow';
      case FriendshipStatus.pending:
        return 'Accept';
      case FriendshipStatus.requested:
        return 'Requested';
      case FriendshipStatus.friends:
        return 'Following';
      case FriendshipStatus.self:
      case null:
        return 'Follow';
    }
  }

  IconData _getActionIcon() {
    switch (_profile?.friendshipStatus) {
      case FriendshipStatus.none:
        return Icons.person_add;
      case FriendshipStatus.pending:
        return Icons.check;
      case FriendshipStatus.requested:
        return Icons.hourglass_empty;
      case FriendshipStatus.friends:
        return Icons.people;
      case FriendshipStatus.self:
      case null:
        return Icons.edit;
    }
  }

  Color _getActionButtonColor() {
    switch (_profile?.friendshipStatus) {
      case FriendshipStatus.none:
        return Theme.of(context).colorScheme.primary;
      case FriendshipStatus.pending:
        return Colors.green;
      case FriendshipStatus.requested:
        return const Color(0xFFF9FAFB); // Tailwind bg-gray-50
      case FriendshipStatus.friends:
        return Colors.green;
      case FriendshipStatus.self:
      case null:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _getActionButtonForegroundColor() {
    switch (_profile?.friendshipStatus) {
      case FriendshipStatus.requested:
        return const Color(0xFF6B7280); // Tailwind text-gray-500 for contrast on light bg
      case FriendshipStatus.none:
      case FriendshipStatus.pending:
      case FriendshipStatus.friends:
      case FriendshipStatus.self:
      case null:
        return Colors.white;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
      'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  /// Build tab content based on tab ID
  Widget _buildTabContent(String tabId) {
    switch (tabId) {
      case 'posts':
        return _buildPostsTab();
      case 'photos':
        return _buildPhotosTab();
      case 'videos':
        return _buildVideosTab();
      case 'music':
        return _buildMusicTab();
      case 'live':
        return _buildLiveTab();
      case 'michango':
        return _buildMichangoTab();
      case 'groups':
        return _buildGroupsTab();
      case 'documents':
        return _buildDocumentsTab();
      case 'shop':
        return _buildShopTab();
      case 'friends':
        return _buildFriendsTab();
      case 'about':
        return _buildAboutTab();
      default:
        return Center(
          child: Text('Tab not found: $tabId'),
        );
    }
  }

  Widget _buildPostsTab() {
    if (_isLoadingPosts && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      // No header when empty (same as Photos tab empty state)
      return SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.article_outlined, size: 64, color: Colors.grey.shade600),
                      const SizedBox(height: 16),
                      Text(
                        _isOwnProfile
                            ? (AppStringsScope.of(context)?.noPostsMe ?? "You haven't posted yet")
                            : (AppStringsScope.of(context)?.noPosts ?? 'No posts'),
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                        textAlign: TextAlign.center,
                      ),
                      if (_isOwnProfile) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _openCreatePostFromPostsTab,
                          icon: const Icon(Icons.add),
                          label: Text(AppStringsScope.of(context)?.createPostNow ?? 'Post now'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Same structure as Photos tab: Column with header then Expanded(list)
    // Use LayoutBuilder to handle edge cases with small constraints
    return LayoutBuilder(
      builder: (context, constraints) {
        // If constraints are too small, just show the list without header
        if (constraints.maxHeight < 100) {
          return RefreshIndicator(
            onRefresh: () async {
              _postsPage = 1;
              await _loadPosts();
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return PostCard(
                  post: post,
                  currentUserId: _currentUserId,
                  onLike: () => _handleLike(post),
                  onComment: () => _openCommentSheet(post),
                  onShare: () => _onSharePost(post),
                  onSave: () => _handleSave(post),
                  onUserTap: () {},
                  onMenuTap: _isOwnProfile ? () => _onPostMenuTap(post) : null,
                  onTap: () => _openPostDetail(post),
                );
              },
            ),
          );
        }
        return Column(
          children: [
            _buildPostsTabHeader(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _postsPage = 1;
                  await _loadPosts();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return PostCard(
                      post: post,
                      currentUserId: _currentUserId,
                      onLike: () => _handleLike(post),
                      onComment: () => _openCommentSheet(post),
                      onShare: () => _onSharePost(post),
                      onSave: () => _handleSave(post),
                      onUserTap: () {},
                      onMenuTap: _isOwnProfile ? () => _onPostMenuTap(post) : null,
                      onTap: () => _openPostDetail(post),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Header for Me -> Posts tab. Same structure as PhotoGalleryWidget._buildHeader():
  /// Container(padding: 12,8) -> Row(left text, Spacer(), action IconButton).
  Widget _buildPostsTabHeader(BuildContext context) {
    final s = AppStringsScope.of(context);
    final postsLabel = (s?.profileTabLabel('posts') ?? 'Posts').toLowerCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            '${_posts.length} $postsLabel',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          if (_isOwnProfile)
            IconButton(
              onPressed: _openCreatePostFromPostsTab,
              icon: const Icon(Icons.add_circle_outline, size: 28),
              iconSize: 28,
              tooltip: s?.createPostNow ?? 'Post now',
            ),
        ],
      ),
    );
  }

  Future<void> _openCreatePostFromPostsTab() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(currentUserId: _currentUserId),
      ),
    );
    if (result == true && mounted) {
      _postsPage = 1;
      _loadPosts();
    }
  }

  void _onPostMenuTap(Post post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Hariri'),
              onTap: () {
                Navigator.pop(context);
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
                Navigator.pop(context);
                _confirmDeletePost(post);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePost(Post post) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Futa Chapisho'),
        content: const Text('Una uhakika unataka kufuta chapisho hili?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hapana'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await _postService.deletePost(post.id);
              if (!mounted) return;
              if (success) {
                setState(() => _posts.removeWhere((p) => p.id == post.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chapisho limefutwa')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Imeshindwa kufuta chapisho'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Ndio', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openCommentSheet(Post post) {
    CommentBottomSheet.show(
      context,
      postId: post.id,
      currentUserId: _currentUserId,
      initialPost: post,
      onCommentsCountUpdated: (newCount) {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index >= 0 && mounted) {
          setState(() {
            _posts[index] = _posts[index].copyWith(commentsCount: newCount);
          });
        }
      },
    );
  }

  void _onSharePost(Post post) {
    showSharePostBottomSheet(
      context,
      post: post,
      userId: _currentUserId,
      postService: _postService,
      onShared: (Post? sharedPost) {
        if (sharedPost != null && mounted) {
          setState(() {
            final list = List<Post>.from(_posts);
            list.insert(0, sharedPost);
            _posts = list;
          });
        }
      },
    );
  }

  void _openPostDetail(Post post) {
    Navigator.push<int?>(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(
          postId: post.id,
          currentUserId: _currentUserId,
          initialPost: post,
        ),
      ),
    ).then((deletedPostId) {
      if (!mounted) return;
      if (deletedPostId != null) {
        setState(() => _posts.removeWhere((p) => p.id == deletedPostId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chapisho limefutwa')),
        );
        return;
      }
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index == -1) return;
      _postService.getPost(post.id, currentUserId: _currentUserId).then((result) {
        if (mounted && result.success && result.post != null) {
          setState(() => _posts[index] = result.post!);
        }
      });
    });
  }

  Future<void> _handleLike(Post post) async {
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
        ? await _postService.unlikePost(post.id, _currentUserId)
        : await _postService.likePost(post.id, _currentUserId);

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

  Future<void> _handleSave(Post post) async {
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
        ? await _postService.unsavePost(post.id, _currentUserId)
        : await _postService.savePost(post.id, _currentUserId);

    if (!mounted) return;
    if (!result.success) {
      setState(() => _posts[index] = post);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Imeshindwa kusasisha hifadhi'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasSaved ? 'Imeondolewa kwenye hifadhi' : 'Imehifadhiwa',
          ),
        ),
      );
    }
  }

  Widget _buildPhotosTab() {
    // Use the modern Pinterest-style photo gallery
    return PhotoGalleryWidget(
      userId: widget.userId,
      isOwnProfile: _isOwnProfile,
      heroTagPrefix: 'profile_photo',
    );
  }

  Widget _buildVideosTab() {
    return VideoGalleryWidgetScreen(
      userId: widget.userId,
      isOwnProfile: _isOwnProfile,
      onUploadComplete: () {
        _loadProfile();
      },
    );
  }

  Widget _buildMusicTab() {
    return MusicGalleryWidget(
      userId: widget.userId,
      isOwnProfile: _isOwnProfile,
      onUploadComplete: () {
        // Refresh profile to update music count
        _loadProfile();
      },
    );
  }

  Widget _buildLiveTab() {
    return LiveGalleryWidgetScreen(
      userId: widget.userId,
      isOwnProfile: _isOwnProfile,
    );
  }

  Widget _buildMichangoTab() {
    return MichangoGalleryWidgetScreen(
      userId: widget.userId,
      isOwnProfile: _isOwnProfile,
      onCreateCampaign: _isOwnProfile
          ? () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateCampaignScreen(currentUserId: widget.userId),
                ),
              );
            }
          : null,
    );
  }

  Widget _buildGroupsTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Vikundi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isOwnProfile
                        ? (AppStringsScope.of(context)?.noGroupsMe ?? "You haven't joined any groups")
                        : (AppStringsScope.of(context)?.noGroups ?? 'No groups'),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  if (_isOwnProfile) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupsScreen(currentUserId: _currentUserId),
                          ),
                        );
                        if (result == true && mounted) {
                          _refreshTabs();
                        }
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Tafuta Vikundi'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/messages/groups');
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Mazungumzo ya Vikundi'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateGroupScreen(creatorId: _currentUserId),
                          ),
                        );
                        if (result == true && mounted) {
                          _refreshTabs();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Unda Kikundi'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentsTab() {
    // TODO: Implement documents list
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Nyaraka',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isOwnProfile
                        ? (AppStringsScope.of(context)?.noDocsMe ?? "You haven't uploaded any documents")
                        : (AppStringsScope.of(context)?.noData ?? 'No data'),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  if (_isOwnProfile) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to upload documents screen
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Pakia Nyaraka'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShopTab() {
    return ShopGalleryWidget(
      userId: widget.userId,
      isOwnProfile: _isOwnProfile,
      onProductAdded: () {
        // Refresh profile stats when product is added
        _loadProfile();
      },
    );
  }

  Widget _buildFriendsTab() {
    // TODO: Implement friends list
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Marafiki ${_profile?.stats.friendsCount ?? 0}',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Info Section
          _buildAboutSection(
            title: 'Taarifa Binafsi',
            icon: Icons.person,
            children: [
              if (_profile?.dateOfBirth != null)
                _buildAboutRow('Tarehe ya Kuzaliwa', _formatFullDate(_profile!.dateOfBirth!)),
              if (_profile?.genderLabel != null)
                _buildAboutRow('Jinsia', _profile!.genderLabel!),
              if (_profile?.relationshipStatusLabel != null)
                _buildAboutRow('Hali ya Uhusiano', _profile!.relationshipStatusLabel!),
              if (_profile?.phoneNumber != null)
                _buildAboutRow('Simu', _profile!.phoneNumber!),
            ],
          ),

          // Location Section
          if (_profile?.location != null) ...[
            const SizedBox(height: 16),
            _buildAboutSection(
              title: 'Mahali',
              icon: Icons.location_on,
              children: [
                if (_profile!.location!.regionName != null)
                  _buildAboutRow('Mkoa', _profile!.location!.regionName!),
                if (_profile!.location!.districtName != null)
                  _buildAboutRow('Wilaya', _profile!.location!.districtName!),
                if (_profile!.location!.wardName != null)
                  _buildAboutRow('Kata', _profile!.location!.wardName!),
              ],
            ),
          ],

          // Education Section
          if (_profile?.hasEducation == true) ...[
            const SizedBox(height: 16),
            _buildAboutSection(
              title: 'Elimu',
              icon: Icons.school,
              children: [
                _buildEducationTimeline(),
              ],
            ),
          ],

          // Career Section
          if (_profile?.currentEmployer != null) ...[
            const SizedBox(height: 16),
            _buildAboutSection(
              title: 'Kazi',
              icon: Icons.work,
              children: [
                _buildCareerCard(_profile!.currentEmployer!),
              ],
            ),
          ],

          // Member Since
          const SizedBox(height: 16),
          _buildAboutSection(
            title: 'Akaunti',
            icon: Icons.info_outline,
            children: [
              _buildAboutRow(
                'Alijiunga',
                _formatFullDate(_profile?.createdAt ?? DateTime.now()),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAboutSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    // Filter out empty placeholders (e.g. SizedBox.shrink() from _buildAboutRow)
    final nonEmptyChildren = children.where((w) {
      if (w is! SizedBox) return true;
      final h = w.height;
      return h != null && h > 0;
    }).toList();
    if (nonEmptyChildren.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...nonEmptyChildren,
        ],
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationTimeline() {
    final educationItems = <_EducationTimelineItem>[];

    if (_profile?.universityEducation != null) {
      educationItems.add(_EducationTimelineItem(
        level: 'Chuo Kikuu',
        institution: _profile!.universityEducation!.universityName ?? '',
        detail: _profile!.universityEducation!.programmeName,
        year: _profile!.universityEducation!.graduationYear,
        icon: Icons.account_balance,
        color: Colors.purple,
      ));
    }

    if (_profile?.postsecondaryEducation != null) {
      educationItems.add(_EducationTimelineItem(
        level: 'Chuo/Taasisi',
        institution: _profile!.postsecondaryEducation!.schoolName ?? '',
        year: _profile!.postsecondaryEducation!.graduationYear,
        icon: Icons.school,
        color: Colors.blue,
      ));
    }

    if (_profile?.alevelEducation != null) {
      educationItems.add(_EducationTimelineItem(
        level: 'A-Level',
        institution: _profile!.alevelEducation!.schoolName ?? '',
        detail: _profile!.alevelEducation!.combinationCode,
        year: _profile!.alevelEducation!.graduationYear,
        icon: Icons.menu_book,
        color: Colors.orange,
      ));
    }

    if (_profile?.secondarySchool != null) {
      educationItems.add(_EducationTimelineItem(
        level: 'Sekondari (O-Level)',
        institution: _profile!.secondarySchool!.schoolName ?? '',
        year: _profile!.secondarySchool!.graduationYear,
        icon: Icons.menu_book,
        color: Colors.green,
      ));
    }

    if (_profile?.primarySchool != null) {
      educationItems.add(_EducationTimelineItem(
        level: 'Shule ya Msingi',
        institution: _profile!.primarySchool!.schoolName ?? '',
        year: _profile!.primarySchool!.graduationYear,
        icon: Icons.child_care,
        color: Colors.teal,
      ));
    }

    if (educationItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Hakuna taarifa za elimu',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return Column(
      children: educationItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == educationItems.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line and dot
              SizedBox(
                width: 60,
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: item.color, width: 2),
                      ),
                      child: Icon(item.icon, size: 18, color: item.color),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(0, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.level,
                              style: TextStyle(
                                fontSize: 12,
                                color: item.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (item.year != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.institution,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.detail != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.detail!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCareerCard(ProfileEmployer employer) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.business,
              color: Colors.blue.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (employer.jobTitle != null)
                  Text(
                    employer.jobTitle!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (employer.employerName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    employer.employerName!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                if (employer.sector != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      employer.sector!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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

  String _formatFullDate(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
      'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Me page: compact quick link (Settings, Wallet, Calls). DESIGN.md §13.4 — 48dp min height.
class _MeQuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MeQuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.start,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Single tab: icon in soft circular background + label below (iOS-style).
class _ProfileCustomTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color primary;
  final VoidCallback? onTap;

  const _ProfileCustomTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? primary : Colors.grey.shade200,
            ),
            child: Icon(
              icon,
              size: 26,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? primary : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final int selectedIndex;

  _ProfileTabBarDelegate({
    required this.child,
    required this.height,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _ProfileTabBarDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.selectedIndex != selectedIndex;
}

class _EducationTimelineItem {
  final String level;
  final String institution;
  final String? detail;
  final int? year;
  final IconData icon;
  final Color color;

  _EducationTimelineItem({
    required this.level,
    required this.institution,
    this.detail,
    this.year,
    required this.icon,
    required this.color,
  });
}
