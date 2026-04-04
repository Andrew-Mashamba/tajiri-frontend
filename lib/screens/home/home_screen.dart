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
import '../../services/tea_warmup_service.dart';
import '../../services/presence_service.dart';
import '../../services/people_cache_service.dart';
import '../../services/message_sync_service.dart';
import '../../services/user_channel_service.dart';
import '../../services/callkit_service.dart';
import '../../calls/call_channel_service.dart';
import '../calls/incoming_call_flow_screen.dart';
import '../../services/local_storage_service.dart';
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
  StreamSubscription<CallIncomingEvent>? _incomingCallSubscription;
  Timer? _heartbeatTimer;

  /// DESIGN.md: background #FAFAFA.
  static const Color _background = Color(0xFFFAFAFA);

  late final List<Widget Function()> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = (widget.initialIndex != null &&
            widget.initialIndex! >= 0 &&
            widget.initialIndex! < 5)
        ? widget.initialIndex!
        : 0;
    _screens = [
      () => FeedScreen(currentUserId: widget.currentUserId),
      () => ConversationsScreen(
        currentUserId: widget.currentUserId,
        initialTabIndex: widget.initialMessagesTab ?? 0,
      ),
      () => FriendsScreen(
        currentUserId: widget.currentUserId,
        isCurrentTab: true,
      ),
      () => ShopScreen(currentUserId: widget.currentUserId),
      () => ProfileScreen(
        userId: widget.currentUserId,
        currentUserId: widget.currentUserId,
      ),
    ];
    _loadUnreadCount();
    CallKitService.instance.init();
    PresenceService.heartbeat(widget.currentUserId);
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      PresenceService.heartbeat(widget.currentUserId);
    });
    LiveUpdateService.instance.start(widget.currentUserId);
    _liveUpdateSubscription = LiveUpdateService.instance.stream.listen((event) {
      if (event is MessagesUpdateEvent && mounted) _loadUnreadCount();
    });
    FcmService.instance.sendTokenToBackend(widget.currentUserId);
    FcmService.instance.processPendingInitialMessage();
    TeaWarmupService.instance.warmUp();
    PeopleCacheService.instance.warmCache(widget.currentUserId);
    MessageSyncService.instance.flushPendingMessages(widget.currentUserId);
    _startUserChannel();
  }

  Future<void> _startUserChannel() async {
    debugPrint('[HomeScreen] ═══ Starting UserChannelService for userId=${widget.currentUserId} ═══');
    await UserChannelService.instance.start(userId: widget.currentUserId);
    debugPrint('[HomeScreen] ✓ UserChannelService started, listening for incoming calls');
    _incomingCallSubscription = UserChannelService.instance.onCallIncoming.listen((event) {
      if (!mounted) return;
      debugPrint('[HomeScreen] ═══ INCOMING CALL ═══');
      debugPrint('[HomeScreen]   callId=${event.callId}');
      debugPrint('[HomeScreen]   callerId=${event.callerId}, callerName=${event.callerName}');
      debugPrint('[HomeScreen]   type=${event.type}, isGroupAdd=${event.isGroupAdd}');
      debugPrint('[HomeScreen]   callerAvatarUrl=${event.callerAvatarUrl}');
      _openIncomingCall(event);
    });
  }

  Future<void> _openIncomingCall(CallIncomingEvent event) async {
    if (!mounted) return;
    debugPrint('[HomeScreen] _openIncomingCall: fetching auth token...');
    final storage = await LocalStorageService.getInstance();
    final authToken = storage.getAuthToken();
    debugPrint('[HomeScreen] _openIncomingCall: hasToken=${authToken != null && authToken.isNotEmpty}, mounted=$mounted');
    if (!mounted) return;
    debugPrint('[HomeScreen] → Navigating to IncomingCallFlowScreen');
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IncomingCallFlowScreen(
          currentUserId: widget.currentUserId,
          authToken: authToken,
          incoming: event,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _liveUpdateSubscription?.cancel();
    _incomingCallSubscription?.cancel();
    UserChannelService.instance.stop();
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

