import 'dart:io';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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
import '../../widgets/post_grid_cell.dart';
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
import '../messages/callhistory_screen.dart';
import '../feed/create_post_screen.dart';
import '../feed/post_detail_screen.dart';
import '../feed/videogallerywidget_screen.dart';
import '../groups/groups_screen.dart';
import '../groups/create_group_screen.dart';
import '../groups/group_detail_screen.dart';
import '../../models/group_models.dart';
import '../../models/file_models.dart';
import '../../services/group_service.dart';
import '../../services/file_service.dart';
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
        child: Stack(
          children: [
            // Main content
            CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(child: _buildProfileInfo()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Floating mini sidebar - sticky on right side, from top to just above bottom nav
  /// Contains all profile tabs for navigation
  /// Open a tab as a full page
  void _openTabPage(ProfileTabConfig tab) {
    final s = AppStringsScope.of(context);
    final label = _isOwnProfile
        ? (s?.profileTabLabelOwn(tab.id) ?? tab.label)
        : (s?.profileTabLabel(tab.id) ?? tab.label);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ProfileTabPage(
          title: label,
          icon: _tabIconData(tab.icon),
          tabId: tab.id,
          userId: widget.userId,
          currentUserId: _currentUserId,
          isOwnProfile: _isOwnProfile,
          profile: _profile,
          onRefresh: _loadProfile,
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
                case 'saved':
                  Navigator.pushNamed(context, '/saved-posts');
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
                PopupMenuItem(
                  value: 'saved',
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark_outline_rounded),
                      const SizedBox(width: 8),
                      Text(s?.savedTitle ?? 'Saved'),
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

      // Tab menu - grid of four, directly under joined date
      const SizedBox(height: sectionSpacing),
      _buildTabMenuGrid(),

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

  /// Grid of four: profile tabs - tapping opens full page
  Widget _buildTabMenuGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.88,
      ),
      itemCount: _enabledTabs.length,
      itemBuilder: (context, index) {
        final tab = _enabledTabs[index];
        return _buildTabMenuItem(tab);
      },
    );
  }

  /// Single tab menu item - icon + label, opens full page on tap (no background)
  Widget _buildTabMenuItem(ProfileTabConfig tab) {
    final s = AppStringsScope.of(context);
    final label = _isOwnProfile
        ? (s?.profileTabLabelOwn(tab.id) ?? tab.label)
        : (s?.profileTabLabel(tab.id) ?? tab.label);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openTabPage(tab),
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellHeight = constraints.maxHeight;
            final iconSize = (cellHeight * 0.45).clamp(24.0, 32.0);
            final padding = (iconSize * 0.4).roundToDouble();
            final fontSize = (cellHeight * 0.13).clamp(9.0, 12.0);
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _tabIconData(tab.icon),
                    size: iconSize,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: (cellHeight * 0.08).clamp(4.0, 10.0)),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
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

/// Full page wrapper for profile tab content
class _ProfileTabPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String tabId;
  final int userId;
  final int currentUserId;
  final bool isOwnProfile;
  final FullProfile? profile;
  final VoidCallback? onRefresh;

  const _ProfileTabPage({
    required this.title,
    required this.icon,
    required this.tabId,
    required this.userId,
    required this.currentUserId,
    required this.isOwnProfile,
    this.profile,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (tabId) {
      case 'posts':
        return _ProfilePostsPage(
          userId: userId,
          currentUserId: currentUserId,
          isOwnProfile: isOwnProfile,
        );
      case 'photos':
        return PhotoGalleryWidget(
          userId: userId,
          isOwnProfile: isOwnProfile,
          heroTagPrefix: 'profile_photo',
        );
      case 'videos':
        return VideoGalleryWidgetScreen(
          userId: userId,
          isOwnProfile: isOwnProfile,
          onUploadComplete: onRefresh,
        );
      case 'music':
        return MusicGalleryWidget(
          userId: userId,
          isOwnProfile: isOwnProfile,
          onUploadComplete: onRefresh,
        );
      case 'live':
        return LiveGalleryWidgetScreen(
          userId: userId,
          isOwnProfile: isOwnProfile,
        );
      case 'michango':
        return MichangoGalleryWidgetScreen(
          userId: userId,
          isOwnProfile: isOwnProfile,
          onCreateCampaign: isOwnProfile
              ? () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateCampaignScreen(currentUserId: userId),
                    ),
                  );
                }
              : null,
        );
      case 'groups':
        return _ProfileGroupsPage(
          userId: userId,
          currentUserId: currentUserId,
          isOwnProfile: isOwnProfile,
        );
      case 'documents':
        return _ProfileDocumentsPage(
          userId: userId,
          currentUserId: currentUserId,
          isOwnProfile: isOwnProfile,
        );
      case 'shop':
        return ShopGalleryWidget(
          userId: userId,
          isOwnProfile: isOwnProfile,
          onProductAdded: onRefresh,
        );
      case 'friends':
        return _ProfileFriendsPage(
          userId: userId,
          profile: profile,
        );
      case 'about':
        return _ProfileAboutPage(
          profile: profile,
          isOwnProfile: isOwnProfile,
        );
      default:
        return Center(
          child: Text('Tab not found: $tabId'),
        );
    }
  }
}

/// Instagram-style posts grid — 3-column, 1px gaps, square thumbnails.
///
/// Features:
/// - Pinned posts (up to 3) always shown first with pin icon overlay
/// - Infinite scroll with prefetch at ~70% of current batch
/// - Long-press peek preview with dimmed backdrop
/// - Shimmer loading placeholders
/// - Post type indicators (carousel, video, audio, pin)
/// - Pull-to-refresh
/// - Scroll-direction-aware thumbnail prefetching
class _ProfilePostsPage extends StatefulWidget {
  final int userId;
  final int currentUserId;
  final bool isOwnProfile;

  const _ProfilePostsPage({
    required this.userId,
    required this.currentUserId,
    required this.isOwnProfile,
  });

  @override
  State<_ProfilePostsPage> createState() => _ProfilePostsPageState();
}

class _ProfilePostsPageState extends State<_ProfilePostsPage> {
  final PostService _postService = PostService();
  final ScrollController _scrollController = ScrollController();

  List<Post> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  double _lastScrollOffset = 0;
  static const int _perPage = 24; // 8 rows of 3

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPosts();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Prefetch next page at ~70% scroll through current content.
  void _onScroll() {
    if (!_hasMore || _isLoadingMore) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.7) {
      _loadMorePosts();
    }

    // Prefetch thumbnails for upcoming rows
    _prefetchVisibleThumbnails();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _page = 1;
    });

    final result = await _postService.getPosts(
      userId: widget.currentUserId,
      profileUserId: widget.userId,
      page: 1,
      perPage: _perPage,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _posts = _sortWithPinnedFirst(result.posts);
          final meta = result.meta;
          _hasMore = meta != null
              ? meta.currentPage < meta.lastPage
              : result.posts.length >= _perPage;
          _page = 2;
        }
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final result = await _postService.getPosts(
      userId: widget.currentUserId,
      profileUserId: widget.userId,
      page: _page,
      perPage: _perPage,
    );

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.success) {
          // Append new posts (pinned are only in first page)
          _posts.addAll(result.posts);
          final meta = result.meta;
          _hasMore = meta != null
              ? meta.currentPage < meta.lastPage
              : result.posts.length >= _perPage;
          _page++;
        }
      });
    }
  }

  /// Sort posts so pinned posts (up to 3) appear first, rest reverse-chronological.
  List<Post> _sortWithPinnedFirst(List<Post> posts) {
    final pinned = posts.where((p) => p.isPinned).take(3).toList();
    final unpinned = posts.where((p) => !p.isPinned || !pinned.contains(p)).toList();
    return [...pinned, ...unpinned];
  }

  /// Scroll-direction-aware prefetch: prefetches thumbnails 2-3 rows ahead
  /// in the direction the user is scrolling. Lower priority than on-screen loads
  /// (handled by ImagePreloader's sequential processing with delays).
  void _prefetchVisibleThumbnails() {
    if (!mounted || _posts.isEmpty) return;
    final cellSize = (MediaQuery.of(context).size.width - 2) / 3;
    if (cellSize <= 0) return;

    final scrollOffset = _scrollController.position.pixels;
    final viewportHeight = _scrollController.position.viewportDimension;
    final scrollingDown = scrollOffset >= _lastScrollOffset;
    _lastScrollOffset = scrollOffset;

    final rowHeight = cellSize + 1; // cell + 1px gap

    if (scrollingDown) {
      // Prefetch 3 rows below the viewport
      final bottomRow = ((scrollOffset + viewportHeight) / rowHeight).ceil();
      final prefetchStartIndex = (bottomRow * 3).clamp(0, _posts.length);
      final prefetchEndIndex = ((bottomRow + 3) * 3).clamp(0, _posts.length);

      if (prefetchStartIndex >= _posts.length) return;

      final urls = <String?>[];
      for (int i = prefetchStartIndex; i < prefetchEndIndex; i++) {
        urls.add(_posts[i].thumbnailUrl);
      }
      ImagePreloader.precacheImages(context, urls);
    } else {
      // Prefetch 3 rows above the viewport
      final topRow = (scrollOffset / rowHeight).floor();
      final prefetchStartRow = (topRow - 3).clamp(0, (_posts.length / 3).ceil());
      final prefetchEndRow = topRow.clamp(0, (_posts.length / 3).ceil());
      final prefetchStartIndex = (prefetchStartRow * 3).clamp(0, _posts.length);
      final prefetchEndIndex = (prefetchEndRow * 3).clamp(0, _posts.length);

      if (prefetchStartIndex >= prefetchEndIndex) return;

      final urls = <String?>[];
      for (int i = prefetchStartIndex; i < prefetchEndIndex; i++) {
        urls.add(_posts[i].thumbnailUrl);
      }
      ImagePreloader.precacheImages(context, urls);
    }
  }

  void _onPostTap(Post post) {
    final index = _posts.indexWhere((p) => p.id == post.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(
          postId: post.id,
          currentUserId: widget.currentUserId,
          initialPost: post,
          posts: _posts,
          initialIndex: index >= 0 ? index : 0,
        ),
      ),
    ).then((result) {
      if (result == true && mounted) _loadPosts();
    });
  }

  void _onPostLongPress(Post post) {
    showPostPeekPreview(context, post);
  }

  @override
  Widget build(BuildContext context) {
    // Shimmer loading state
    if (_isLoading && _posts.isEmpty) {
      return _buildShimmerGrid(context);
    }

    // Empty state
    if (_posts.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: CustomScrollView(
        controller: _scrollController,
        // Increase cache extent for smoother scrolling (pre-build ~4 rows off-screen)
        cacheExtent: (MediaQuery.of(context).size.width / 3) * 4,
        slivers: [
          // Posts management header (own profile only)
          if (widget.isOwnProfile)
            SliverToBoxAdapter(child: _buildPostsHeader(context)),
          // Posts grid
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = _posts[index];
                return PostGridCell(
                  post: post,
                  onTap: () => _onPostTap(post),
                  onLongPress: () => _onPostLongPress(post),
                );
              },
              childCount: _posts.length,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: false, // We handle RepaintBoundary in PostGridCell
            ),
          ),
          // Loading more indicator
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Shimmer placeholder grid while loading.
  Widget _buildShimmerGrid(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1.0,
      ),
      itemCount: 18, // 6 rows
      itemBuilder: (context, index) {
        return _ShimmerCell(index: index);
      },
    );
  }

  Widget _buildPostsHeader(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFFFAFAFA),
      child: Row(
        children: [
          // Post count
          Text(
            '${_posts.length} ${s?.post ?? 'Posts'}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const Spacer(),
          // Create post
          _PostsHeaderButton(
            icon: Icons.add_rounded,
            label: s?.createPost ?? 'Create post',
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => CreatePostScreen(currentUserId: widget.currentUserId),
                ),
              );
              if (result == true && mounted) _loadPosts();
            },
          ),
          const SizedBox(width: 8),
          // Saved posts
          _PostsHeaderButton(
            icon: Icons.bookmark_outline_rounded,
            label: s?.savedTitle ?? 'Saved',
            onTap: () => Navigator.pushNamed(context, '/saved-posts'),
          ),
          const SizedBox(width: 8),
          // Drafts
          _PostsHeaderButton(
            icon: Icons.edit_note_rounded,
            label: s?.drafts ?? 'Drafts',
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => CreatePostScreen(currentUserId: widget.currentUserId),
                ),
              );
              if (result == true && mounted) _loadPosts();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grid_on_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            widget.isOwnProfile
                ? (AppStringsScope.of(context)?.noPostsMe ?? "You haven't posted yet")
                : (AppStringsScope.of(context)?.noPosts ?? 'No posts'),
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          if (widget.isOwnProfile) ...[
            const SizedBox(height: 8),
            Text(
              'Share your first photo or video',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreatePostScreen(currentUserId: widget.currentUserId),
                  ),
                );
                if (result == true && mounted) _loadPosts();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text(AppStringsScope.of(context)?.createPostNow ?? 'Post now'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact header button for posts management toolbar.
class _PostsHeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PostsHeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1A1A1A)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated shimmer placeholder cell for loading grid.
class _ShimmerCell extends StatefulWidget {
  final int index;
  const _ShimmerCell({required this.index});

  @override
  State<_ShimmerCell> createState() => _ShimmerCellState();
}

class _ShimmerCellState extends State<_ShimmerCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: 0.04, end: 0.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          color: Color.lerp(
            Colors.grey.shade200,
            Colors.grey.shade300,
            _animation.value / 0.12,
          ),
        );
      },
    );
  }
}

/// Groups page content - full management for own profile
class _ProfileGroupsPage extends StatefulWidget {
  final int userId;
  final int currentUserId;
  final bool isOwnProfile;

  const _ProfileGroupsPage({
    required this.userId,
    required this.currentUserId,
    required this.isOwnProfile,
  });

  @override
  State<_ProfileGroupsPage> createState() => _ProfileGroupsPageState();
}

class _ProfileGroupsPageState extends State<_ProfileGroupsPage> {
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
          _error = result.message ?? 'Imeshindwa kupakia vikundi';
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
          child: _QuickActionButton(
            icon: Icons.add,
            label: s?.createGroup ?? 'Unda Kikundi',
            onTap: _createGroup,
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
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
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _QuickActionButton({
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

/// Documents/Files page content - Dropbox-like file management
class _ProfileDocumentsPage extends StatefulWidget {
  final int userId;
  final int currentUserId;
  final bool isOwnProfile;

  const _ProfileDocumentsPage({
    required this.userId,
    required this.currentUserId,
    required this.isOwnProfile,
  });

  @override
  State<_ProfileDocumentsPage> createState() => _ProfileDocumentsPageState();
}

class _ProfileDocumentsPageState extends State<_ProfileDocumentsPage> {
  final FileService _fileService = FileService();

  List<UserFile> _files = [];
  List<UserFile> _recentFiles = [];
  List<UserFile> _starredFiles = [];
  StorageQuota? _quota;
  bool _isLoading = true;
  String? _error;

  FileCategory _selectedCategory = FileCategory.all;
  int? _currentFolderId;
  String _currentPath = '/';
  final List<_BreadcrumbItem> _breadcrumbs = [_BreadcrumbItem(name: 'Nyaraka', folderId: null, path: '/')];

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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await Future.wait([
      _loadFiles(),
      if (widget.isOwnProfile) _loadRecentFiles(),
      if (widget.isOwnProfile) _loadStarredFiles(),
      if (widget.isOwnProfile) _loadQuota(),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFiles() async {
    final result = await _fileService.getFiles(
      userId: widget.userId,
      folderId: _currentFolderId,
      path: _currentPath,
      category: _selectedCategory,
    );

    if (mounted) {
      setState(() {
        if (result.success) {
          _files = result.files;
          _error = null; // Clear any previous error on success
          if (result.quota != null) _quota = result.quota;
        } else {
          _error = result.message;
        }
      });
    }
  }

  Future<void> _loadRecentFiles() async {
    final result = await _fileService.getRecentFiles(widget.userId, limit: 10);
    if (mounted && result.success) {
      setState(() => _recentFiles = result.files);
    }
  }

  Future<void> _loadStarredFiles() async {
    final result = await _fileService.getStarredFiles(widget.userId);
    if (mounted && result.success) {
      setState(() => _starredFiles = result.files);
    }
  }

  Future<void> _loadQuota() async {
    final quota = await _fileService.getStorageQuota(widget.userId);
    if (mounted && quota != null) {
      setState(() => _quota = quota);
    }
  }

  void _navigateToFolder(UserFile folder) {
    setState(() {
      _currentFolderId = folder.id;
      _currentPath = folder.path;
      _breadcrumbs.add(_BreadcrumbItem(
        name: folder.title,
        folderId: folder.id,
        path: folder.path,
      ));
    });
    _loadFiles();
  }

  void _navigateToBreadcrumb(int index) {
    if (index >= _breadcrumbs.length - 1) return;
    setState(() {
      final crumb = _breadcrumbs[index];
      _currentFolderId = crumb.folderId;
      _currentPath = crumb.path;
      _breadcrumbs.removeRange(index + 1, _breadcrumbs.length);
    });
    _loadFiles();
  }

  void _onCategoryChanged(FileCategory category) {
    setState(() => _selectedCategory = category);
    _loadFiles();
  }

  Future<void> _uploadFile() async {
    final s = AppStringsScope.of(context);

    try {
      // Pick files - allow documents and archives only
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          // Documents
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
          'txt', 'csv', 'rtf', 'odt', 'ods', 'odp',
          // Archives
          'zip', 'rar', '7z', 'tar', 'gz',
        ],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      // Show uploading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s?.uploading ?? 'Inapakia'} ${result.files.length} ${s?.files ?? 'faili'}...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Upload each file
      int successCount = 0;
      int failCount = 0;

      for (final platformFile in result.files) {
        if (platformFile.path == null) continue;

        final file = File(platformFile.path!);
        final uploadResult = await _fileService.uploadFile(
          userId: widget.currentUserId,
          file: file,
          folderId: _currentFolderId,
          path: _currentPath,
          displayName: platformFile.name,
        );

        if (uploadResult.success) {
          successCount++;
        } else {
          failCount++;
        }
      }

      // Show result and refresh
      if (mounted) {
        String message;
        if (failCount == 0) {
          message = '${s?.uploadSuccess ?? 'Imepakiwa'}: $successCount ${s?.files ?? 'faili'}';
        } else {
          message = '${s?.uploaded ?? 'Imepakiwa'}: $successCount, ${s?.failed ?? 'Imeshindwa'}: $failCount';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );

        _loadData(); // Refresh file list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s?.error ?? 'Hitilafu'}: $e')),
        );
      }
    }
  }

  Future<void> _createFolder() async {
    final s = AppStringsScope.of(context);
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s?.createFolder ?? 'Unda Folda'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: s?.folderName ?? 'Jina la folda',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s?.cancel ?? 'Ghairi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(s?.create ?? 'Unda'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final result = await _fileService.createFolder(
        userId: widget.currentUserId,
        name: name,
        parentFolderId: _currentFolderId,
        path: _currentPath,
      );

      if (mounted) {
        if (result.success) {
          _loadFiles();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Imeshindwa kuunda folda')),
          );
        }
      }
    }
  }

  Future<void> _toggleStar(UserFile file) async {
    final result = await _fileService.toggleStar(file.id);
    if (mounted && result.success) {
      _loadData();
    }
  }

  Future<void> _deleteFile(UserFile file) async {
    final s = AppStringsScope.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s?.delete ?? 'Futa'),
        content: Text('${s?.deleteConfirm ?? 'Una uhakika unataka kufuta'} "${file.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s?.cancel ?? 'Ghairi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(s?.delete ?? 'Futa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _fileService.deleteFile(file.id);
      if (mounted) {
        if (success) {
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s?.actionFailed ?? 'Imeshindwa')),
          );
        }
      }
    }
  }

  void _showFileOptions(UserFile file) {
    final s = AppStringsScope.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(file.isStarred ? Icons.star : Icons.star_border),
              title: Text(file.isStarred
                  ? (s?.removeFromStarred ?? 'Ondoa nyota')
                  : (s?.addToStarred ?? 'Weka nyota')),
              onTap: () {
                Navigator.pop(context);
                _toggleStar(file);
              },
            ),
            if (!file.isFolder)
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(s?.share ?? 'Shiriki'),
                onTap: () {
                  Navigator.pop(context);
                  // Share functionality
                },
              ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: Text(s?.rename ?? 'Badilisha jina'),
              onTap: () {
                Navigator.pop(context);
                // Rename functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move),
              title: Text(s?.moveTo ?? 'Hamisha'),
              onTap: () {
                Navigator.pop(context);
                // Move functionality
              },
            ),
            if (widget.isOwnProfile)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(s?.delete ?? 'Futa', style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteFile(file);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _files.isEmpty) {
      return _buildErrorState(s);
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadData,
            color: _textPrimary,
            child: CustomScrollView(
              slivers: [
                // Storage quota indicator (own profile only)
                if (widget.isOwnProfile && _quota != null)
                  SliverToBoxAdapter(child: _buildStorageIndicator(s)),

                // Category filter tabs
                SliverToBoxAdapter(child: _buildCategoryTabs(s)),

                // Breadcrumbs (when in subfolder)
                if (_breadcrumbs.length > 1)
                  SliverToBoxAdapter(child: _buildBreadcrumbs()),

                // Quick access sections (only at root and own profile)
                if (_currentFolderId == null && widget.isOwnProfile) ...[
                  // Recent files section
                  if (_recentFiles.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildHorizontalSection(
                        s?.recentFiles ?? 'Hivi Karibuni',
                        Icons.access_time,
                        _recentFiles.take(5).toList(),
                      ),
                    ),

                  // Starred files section
                  if (_starredFiles.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildHorizontalSection(
                        s?.starredFiles ?? 'Zenye Nyota',
                        Icons.star,
                        _starredFiles.take(5).toList(),
                      ),
                    ),
                ],

                // Main file list
                if (_files.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState(s))
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildFileItem(_files[index]),
                        childCount: _files.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // FAB for upload (own profile only)
          if (widget.isOwnProfile)
            Positioned(
              right: 16,
              bottom: 16 + bottomPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'create_folder',
                    onPressed: _createFolder,
                    backgroundColor: _cardBg,
                    foregroundColor: _textPrimary,
                    child: const Icon(Icons.create_new_folder),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'upload_file',
                    onPressed: _uploadFile,
                    backgroundColor: _textPrimary,
                    foregroundColor: _cardBg,
                    child: const Icon(Icons.upload_file),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStorageIndicator(AppStrings? s) {
    if (_quota == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s?.storage ?? 'Hifadhi',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              Text(
                '${_quota!.formattedUsed} / ${_quota!.formattedTotal}',
                style: const TextStyle(fontSize: 12, color: _textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _quota!.usagePercent / 100,
              backgroundColor: _accent.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                _quota!.usagePercent > 90 ? Colors.red : _textPrimary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_quota!.fileCount} ${s?.filesCount ?? 'faili'} | ${_quota!.folderCount} ${s?.foldersCount ?? 'folda'}',
            style: const TextStyle(fontSize: 11, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(AppStrings? s) {
    final categories = [
      (FileCategory.all, s?.allFiles ?? 'Zote', Icons.folder),
      (FileCategory.document, s?.documents ?? 'Nyaraka', Icons.description),
      (FileCategory.archive, s?.archives ?? 'Kumbukumbu', Icons.archive),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat.$3, size: 16),
                  const SizedBox(width: 4),
                  Text(cat.$2),
                ],
              ),
              onSelected: (_) => _onCategoryChanged(cat.$1),
              selectedColor: _textPrimary.withOpacity(0.15),
              checkmarkColor: _textPrimary,
              labelStyle: TextStyle(
                color: isSelected ? _textPrimary : _textSecondary,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _breadcrumbs.asMap().entries.map((entry) {
          final index = entry.key;
          final crumb = entry.value;
          final isLast = index == _breadcrumbs.length - 1;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: isLast ? null : () => _navigateToBreadcrumb(index),
                child: Text(
                  crumb.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                    color: isLast ? _textPrimary : _textSecondary,
                  ),
                ),
              ),
              if (!isLast) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 16, color: _textSecondary),
                const SizedBox(width: 4),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHorizontalSection(String title, IconData icon, List<UserFile> files) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: _textSecondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: files.length,
            itemBuilder: (context, index) => _buildCompactFileCard(files[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactFileCard(UserFile file) {
    return GestureDetector(
      onTap: () {
        if (file.isFolder) {
          _navigateToFolder(file);
        }
        // Else open file preview
      },
      onLongPress: () => _showFileOptions(file),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getFileColor(file).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: file.thumbnailUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedMediaImage(
                        imageUrl: file.thumbnailUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      _getFileIcon(file),
                      size: 28,
                      color: _getFileColor(file),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              file.title,
              style: const TextStyle(fontSize: 11, color: _textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(UserFile file) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            if (file.isFolder) {
              _navigateToFolder(file);
            }
            // Else open file preview
          },
          onLongPress: () => _showFileOptions(file),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // File icon/thumbnail
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getFileColor(file).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: file.thumbnailUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedMediaImage(
                            imageUrl: file.thumbnailUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          _getFileIcon(file),
                          size: 24,
                          color: _getFileColor(file),
                        ),
                ),
                const SizedBox(width: 12),
                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              file.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (file.isStarred)
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        file.isFolder
                            ? _formatDate(file.updatedAt)
                            : '${file.formattedSize} • ${_formatDate(file.updatedAt)}',
                        style: const TextStyle(fontSize: 12, color: _textSecondary),
                      ),
                    ],
                  ),
                ),
                // More options
                IconButton(
                  icon: const Icon(Icons.more_vert, color: _textSecondary),
                  onPressed: () => _showFileOptions(file),
                  iconSize: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(UserFile file) {
    if (file.isFolder) return Icons.folder;

    switch (file.category) {
      case FileCategory.document:
        final ext = file.extension;
        if (ext == 'pdf') return Icons.picture_as_pdf;
        if (['doc', 'docx'].contains(ext)) return Icons.description;
        if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart;
        if (['ppt', 'pptx'].contains(ext)) return Icons.slideshow;
        if (['txt', 'md', 'rtf'].contains(ext)) return Icons.article;
        return Icons.description;
      case FileCategory.archive:
        return Icons.archive;
      case FileCategory.all:
      case FileCategory.other:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(UserFile file) {
    if (file.isFolder) return Colors.amber.shade700;

    switch (file.category) {
      case FileCategory.document:
        final ext = file.extension;
        if (ext == 'pdf') return Colors.red.shade700;
        if (['doc', 'docx'].contains(ext)) return Colors.blue;
        if (['xls', 'xlsx'].contains(ext)) return Colors.green.shade700;
        if (['ppt', 'pptx'].contains(ext)) return Colors.orange;
        return Colors.blueGrey;
      case FileCategory.archive:
        return Colors.brown;
      case FileCategory.all:
      case FileCategory.other:
        return _textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Leo';
    } else if (diff.inDays == 1) {
      return 'Jana';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} siku zilizopita';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: Text(s?.retry ?? 'Jaribu tena'),
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
            Icon(
              _currentFolderId != null ? Icons.folder_open : Icons.cloud_upload_outlined,
              size: 64,
              color: _accent,
            ),
            const SizedBox(height: 16),
            Text(
              _currentFolderId != null
                  ? (s?.emptyFolder ?? 'Folda tupu')
                  : (s?.noFiles ?? 'Hakuna faili'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isOwnProfile
                  ? (s?.uploadFilesHint ?? 'Bonyeza + kupakia faili')
                  : (s?.noData ?? 'Hakuna data'),
              style: const TextStyle(fontSize: 14, color: _textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Breadcrumb item for folder navigation
class _BreadcrumbItem {
  final String name;
  final int? folderId;
  final String path;

  _BreadcrumbItem({
    required this.name,
    required this.folderId,
    required this.path,
  });
}

/// Friends page content
class _ProfileFriendsPage extends StatelessWidget {
  final int userId;
  final FullProfile? profile;

  const _ProfileFriendsPage({
    required this.userId,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Marafiki ${profile?.stats.friendsCount ?? 0}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Orodha ya marafiki inakuja hivi karibuni',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

/// About page content
class _ProfileAboutPage extends StatelessWidget {
  final FullProfile? profile;
  final bool isOwnProfile;

  const _ProfileAboutPage({
    this.profile,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Info
          _buildSection(
            context,
            title: 'Taarifa Binafsi',
            icon: Icons.person,
            children: [
              if (profile?.dateOfBirth != null)
                _buildRow('Tarehe ya Kuzaliwa', _formatFullDate(profile!.dateOfBirth!)),
              if (profile?.genderLabel != null)
                _buildRow('Jinsia', profile!.genderLabel!),
              if (profile?.relationshipStatusLabel != null)
                _buildRow('Hali ya Uhusiano', profile!.relationshipStatusLabel!),
              if (profile?.phoneNumber != null)
                _buildRow('Simu', profile!.phoneNumber!),
            ],
          ),

          // Location
          if (profile?.location != null) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: 'Mahali',
              icon: Icons.location_on,
              children: [
                if (profile!.location!.regionName != null)
                  _buildRow('Mkoa', profile!.location!.regionName!),
                if (profile!.location!.districtName != null)
                  _buildRow('Wilaya', profile!.location!.districtName!),
                if (profile!.location!.wardName != null)
                  _buildRow('Kata', profile!.location!.wardName!),
              ],
            ),
          ],

          // Education
          if (profile?.hasEducation == true) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: 'Elimu',
              icon: Icons.school,
              children: [
                if (profile?.universityEducation != null)
                  _buildEducationItem(
                    'Chuo Kikuu',
                    profile!.universityEducation!.universityName ?? '',
                    profile!.universityEducation!.programmeName,
                  ),
                if (profile?.secondarySchool != null)
                  _buildEducationItem(
                    'Sekondari',
                    profile!.secondarySchool!.schoolName ?? '',
                    null,
                  ),
                if (profile?.primarySchool != null)
                  _buildEducationItem(
                    'Msingi',
                    profile!.primarySchool!.schoolName ?? '',
                    null,
                  ),
              ],
            ),
          ],

          // Career
          if (profile?.currentEmployer != null) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              title: 'Kazi',
              icon: Icons.work,
              children: [
                _buildRow(
                  profile!.currentEmployer!.jobTitle ?? 'Kazi',
                  profile!.currentEmployer!.employerName ?? '',
                ),
              ],
            ),
          ],

          // Account
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: 'Akaunti',
            icon: Icons.info_outline,
            children: [
              _buildRow(
                'Alijiunga',
                _formatFullDate(profile?.createdAt ?? DateTime.now()),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final nonEmpty = children.where((w) => w is! SizedBox || (w.height ?? 0) > 0).toList();
    if (nonEmpty.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...nonEmpty,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationItem(String level, String institution, String? detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(level, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 4),
          Text(institution, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          if (detail != null) ...[
            const SizedBox(height: 2),
            Text(detail, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
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
