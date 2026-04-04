import 'dart:async';
import 'package:flutter/material.dart';
import '../feed/feed_screen.dart';
import '../friends/friends_screen.dart';
import '../messages/conversations_screen.dart';
import '../shop/shop_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/message_service.dart';
import '../../services/live_update_service.dart';
import '../../services/fcm_service.dart';
import '../../l10n/app_strings_scope.dart';
import '../../widgets/tajiri_bottom_nav_bar.dart';
import '../../widgets/lazy_indexed_stack.dart';

/// Story 71: Bottom Navigation — 5 tabs: Feed, Messages, People, Shop, Profile.
/// Design: DOCS/DESIGN.md (colors, 48dp min touch targets). Navigation: DOCS/NAVIGATION.md.
class HomeScreen extends StatefulWidget {
  final int currentUserId;

  /// When set, the tab at this index is selected on first build (e.g. 1 = Messages).
  final int? initialIndex;

  /// When on Messages tab: 0 = Chats, 1 = Groups, 2 = Calls. Used only when initialIndex == 1.
  final int? initialMessagesTab;

  const HomeScreen({
    super.key,
    required this.currentUserId,
    this.initialIndex,
    this.initialMessagesTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  int _unreadMessages = 0;
  final MessageService _messageService = MessageService();
  StreamSubscription<LiveUpdateEvent>? _liveUpdateSubscription;

  /// DESIGN.md: background #FAFAFA.
  static const Color _background = Color(0xFFFAFAFA);

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = (widget.initialIndex != null &&
            widget.initialIndex! >= 0 &&
            widget.initialIndex! < 5)
        ? widget.initialIndex!
        : 0;
    _screens = [
      FeedScreen(currentUserId: widget.currentUserId),
      ConversationsScreen(
        currentUserId: widget.currentUserId,
        initialTabIndex: widget.initialMessagesTab ?? 0,
      ),
      FriendsScreen(
        currentUserId: widget.currentUserId,
        isCurrentTab: false, // updated in build from _currentIndex
      ),
      ShopScreen(currentUserId: widget.currentUserId),
      ProfileScreen(
        userId: widget.currentUserId,
        currentUserId: widget.currentUserId,
      ),
    ];
    _loadUnreadCount();
    LiveUpdateService.instance.start(widget.currentUserId);
    _liveUpdateSubscription = LiveUpdateService.instance.stream.listen((event) {
      if (event is MessagesUpdateEvent && mounted) _loadUnreadCount();
    });
    FcmService.instance.sendTokenToBackend(widget.currentUserId);
    FcmService.instance.processPendingInitialMessage();
  }

  @override
  void dispose() {
    _liveUpdateSubscription?.cancel();
    LiveUpdateService.instance.stop();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    final count = await _messageService.getUnreadCount(widget.currentUserId);
    if (mounted) {
      setState(() => _unreadMessages = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    if (s == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LazyIndexedStack(
          index: _currentIndex,
          builders: [
            () => _screens[0],
            () => _screens[1],
            () => FriendsScreen(
              currentUserId: widget.currentUserId,
              isCurrentTab: _currentIndex == 2,
            ),
            () => _screens[3],
            () => _screens[4],
          ],
        ),
      ),
      bottomNavigationBar: TajiriBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) _loadUnreadCount();
        },
        labels: [
          s.postsTab,
          s.messagesTab,
          s.peopleTab,
          s.shopTab,
          s.profileTab,
        ],
        unreadMessagesCount: _unreadMessages,
      ),
    );
  }
}

