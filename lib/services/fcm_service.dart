// FCM: foreground/background/opened handlers. Payload contract: new_message -> open chat; call_incoming -> open incoming call screen.

import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:tajiri/calls/call_channel_service.dart';
import 'package:tajiri/screens/calls/incoming_call_flow_screen.dart';
import '../config/api_config.dart';
import 'local_storage_service.dart';
import 'message_service.dart';
import 'callkit_service.dart';
import '../widgets/milestone_overlay.dart';

class FcmService {
  static final FcmService instance = FcmService._();
  FcmService._();

  static GlobalKey<NavigatorState>? _navigatorKey;
  static void setNavigatorKey(GlobalKey<NavigatorState>? key) {
    _navigatorKey = key;
  }

  RemoteMessage? _pendingInitialMessage;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission();
    final token = await FirebaseMessaging.instance.getToken();
    if (kDebugMode && token != null) debugPrint('[FCM] Token: $token');

    // Initialize local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android notification channels
    await _createNotificationChannels();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _pendingInitialMessage = initial;
  }

  // ---------------------------------------------------------------------------
  // Notification channels (Android)
  // ---------------------------------------------------------------------------

  Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'messages',
        'Ujumbe',
        description: 'Arifa za ujumbe mpya',
        importance: Importance.high,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'groups',
        'Vikundi',
        description: 'Arifa za vikundi',
        importance: Importance.high,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'calls',
        'Simu',
        description: 'Simu zinazoingia',
        importance: Importance.max,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'missed_calls',
        'Simu zilizokosa',
        description: 'Simu zilizokosa',
        importance: Importance.high,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'social',
        'Mitandao',
        description: 'Wafuasi, maoni, na likes',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'system',
        'Mfumo',
        description: 'Arifa za mfumo',
        importance: Importance.low,
      ),
    ];

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    for (final channel in channels) {
      await androidPlugin?.createNotificationChannel(channel);
    }
  }

  // ---------------------------------------------------------------------------
  // Channel routing helpers
  // ---------------------------------------------------------------------------

  static String _getChannelForType(String type) {
    switch (type) {
      case 'new_message':
        return 'messages';
      case 'group_message':
        return 'groups';
      case 'call_incoming':
        return 'calls';
      case 'call_missed':
        return 'missed_calls';
      case 'follow':
      case 'like':
      case 'comment':
      case 'reaction':
        return 'social';
      default:
        return 'system';
    }
  }

  static String _getChannelName(String channelId) {
    switch (channelId) {
      case 'messages':
        return 'Ujumbe';
      case 'groups':
        return 'Vikundi';
      case 'calls':
        return 'Simu';
      case 'missed_calls':
        return 'Simu zilizokosa';
      case 'social':
        return 'Mitandao';
      default:
        return 'Mfumo';
    }
  }

  static String _getTitleForType(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'new_message':
        return data['sender_name'] as String? ?? 'Ujumbe mpya';
      case 'group_message':
        return data['group_name'] as String? ?? 'Kikundi';
      case 'call_incoming':
        return data['caller_name'] as String? ?? 'Simu inayoingia';
      case 'call_missed':
        return data['caller_name'] as String? ?? 'Simu iliyokosa';
      case 'follow':
        return 'Mfuasi mpya';
      case 'like':
        return 'Like mpya';
      case 'comment':
        return 'Maoni mapya';
      case 'reaction':
        return 'Reaction mpya';
      default:
        return 'Tajiri';
    }
  }

  // ---------------------------------------------------------------------------
  // Show local notification for foreground messages
  // ---------------------------------------------------------------------------

  void _showLocalNotification(RemoteMessage message) {
    final type = message.data['type'] as String? ?? '';
    final channelId = _getChannelForType(type);
    final groupKey =
        message.data['conversation_id'] as String? ?? type;

    final isMessageType = type == 'new_message' || type == 'group_message';

    // Build Android notification details
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      importance: Importance.high,
      priority: Priority.high,
      groupKey: 'tajiri_$groupKey',
      setAsGroupSummary: false,
      actions: isMessageType
          ? <AndroidNotificationAction>[
              AndroidNotificationAction(
                'reply_${message.data['conversation_id'] ?? ''}',
                'Jibu',
                inputs: <AndroidNotificationActionInput>[
                  const AndroidNotificationActionInput(
                      label: 'Andika ujumbe...'),
                ],
                showsUserInterface: false,
              ),
              AndroidNotificationAction(
                'mark_read_${message.data['conversation_id'] ?? ''}',
                'Soma',
                showsUserInterface: false,
              ),
            ]
          : null,
    );

    // iOS notification details — threadIdentifier handles grouping
    final iosDetails = DarwinNotificationDetails(
      threadIdentifier: groupKey,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    _localNotifications.show(
      message.hashCode,
      message.notification?.title ??
          _getTitleForType(type, message.data),
      message.notification?.body ?? message.data['body'] as String? ?? '',
      details,
      payload: jsonEncode(message.data),
    );

    // Show Android group summary notification
    _showGroupSummary(channelId, groupKey);
  }

  /// Show a summary notification that groups individual notifications on Android.
  void _showGroupSummary(String channelId, String groupKey) {
    final summaryDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      groupKey: 'tajiri_$groupKey',
      setAsGroupSummary: true,
      styleInformation:
          const InboxStyleInformation([], contentTitle: 'Tajiri'),
    );

    _localNotifications.show(
      groupKey.hashCode,
      null,
      null,
      NotificationDetails(android: summaryDetails),
    );
  }

  // ---------------------------------------------------------------------------
  // Notification tap / action handling
  // ---------------------------------------------------------------------------

  void _onNotificationTap(NotificationResponse response) {
    // Quick-reply action
    if (response.actionId?.startsWith('reply_') == true) {
      final conversationId =
          response.actionId!.replaceFirst('reply_', '');
      final replyText = response.input;
      if (replyText != null &&
          replyText.isNotEmpty &&
          conversationId.isNotEmpty) {
        _sendQuickReply(int.tryParse(conversationId), replyText);
      }
      return;
    }
    // Mark-as-read action
    if (response.actionId?.startsWith('mark_read_') == true) {
      final conversationId =
          response.actionId!.replaceFirst('mark_read_', '');
      if (conversationId.isNotEmpty) {
        _markConversationRead(int.tryParse(conversationId));
      }
      return;
    }
    // Normal tap — navigate
    if (response.payload != null) {
      try {
        final data =
            jsonDecode(response.payload!) as Map<String, dynamic>;
        _handlePayload(data, _navigatorKey?.currentState);
      } catch (_) {}
    }
  }

  Future<void> _sendQuickReply(
      int? conversationId, String text) async {
    if (conversationId == null || conversationId <= 0) return;
    try {
      final userId = await _currentUserId();
      if (userId == null) return;
      final service = MessageService();
      await service.sendMessage(
        conversationId: conversationId,
        userId: userId,
        content: text,
      );
      if (kDebugMode) {
        debugPrint(
            '[FCM] Quick reply sent to conversation $conversationId');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] Quick reply failed: $e');
    }
  }

  Future<void> _markConversationRead(int? conversationId) async {
    if (conversationId == null || conversationId <= 0) return;
    try {
      final userId = await _currentUserId();
      if (userId == null) return;
      final service = MessageService();
      await service.markAsRead(conversationId, userId);
      if (kDebugMode) {
        debugPrint(
            '[FCM] Marked conversation $conversationId as read');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] Mark read failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // FCM handlers
  // ---------------------------------------------------------------------------

  void _onForegroundMessage(RemoteMessage message) {
    if (kDebugMode) debugPrint('[FCM] Foreground: ${message.messageId}');
    _showLocalNotification(message);
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) debugPrint('[FCM] Opened: ${message.messageId}');
    _handlePayload(message.data, _navigatorKey?.currentState);
  }

  void _handlePayload(Map<String, dynamic> data, NavigatorState? navigator) {
    if (navigator == null) return;
    final type = data['type'] as String?;
    if (type == 'call_incoming') {
      _openIncomingCall(data, navigator);
      return;
    }
    if (type == 'new_message') {
      _openChat(data, navigator);
      return;
    }
    // Flywheel notification types — route to appropriate screens
    if (type == 'digest') {
      _openDigest(data, navigator);
      return;
    }
    if (type == 'thread_trending') {
      _openThread(data, navigator);
      return;
    }
    if (type == 'weekly_report') {
      _openWeeklyReport(data, navigator);
      return;
    }
    if (type == 'milestone') {
      _showMilestone(data, navigator);
      return;
    }
    if (type == 'streak_warning') {
      _openProfile(data, navigator);
      return;
    }
    if (type == 'battle_invitation') {
      _openBattle(data, navigator);
      return;
    }
    if (type == 'collaboration_suggestion') {
      _openProfile(data, navigator);
      return;
    }
  }

  /// Opens new incoming call flow (IncomingCallFlowScreen + CallSignalingService).
  /// Payload (same flat fields as WebSocket): call_id, caller_id, caller_name, caller_avatar_url, type (voice|video).
  /// type must be "call_incoming" for routing. ongoing: true = group-add (user already in call); else 1:1.
  Future<void> _openIncomingCall(Map<String, dynamic> data, NavigatorState navigator) async {
    debugPrint('[FCM] ═══ _openIncomingCall ═══');
    debugPrint('[FCM] Raw payload: $data');
    final callId = data['call_id'] as String? ?? data['callId'] as String?;
    if (callId == null || callId.isEmpty) {
      debugPrint('[FCM] ✗ No call_id in payload — aborting');
      return;
    }
    final userId = await _currentUserId();
    if (userId == null) {
      debugPrint('[FCM] ✗ No currentUserId — aborting');
      return;
    }
    final storage = await LocalStorageService.getInstance();
    final authToken = storage.getAuthToken();
    final callerId = _intFrom(data, 'caller_id') ?? _intFrom(data, 'callerId') ?? 0;
    final callerName = data['caller_name'] as String? ?? data['callerName'] as String? ?? 'Caller';
    final callerAvatarUrl = data['caller_avatar_url'] as String? ?? data['callerAvatarUrl'] as String?;
    final callType = data['call_type'] as String? ?? data['type'] as String? ?? 'voice';
    final type = (callType == 'video') ? 'video' : 'voice';
    final createdAt = data['created_at'] != null
        ? DateTime.tryParse(data['created_at'].toString())
        : null;
    final isGroupAdd = data['ongoing'] == true;
    debugPrint('[FCM] callId=$callId, callerId=$callerId, callerName=$callerName, type=$type, isGroupAdd=$isGroupAdd');
    final incoming = CallIncomingEvent(
      callId: callId,
      callerId: callerId,
      callerName: callerName,
      callerAvatarUrl: callerAvatarUrl,
      type: type,
      createdAt: createdAt,
      isGroupAdd: isGroupAdd,
    );
    // Show native incoming call UI (CallKit on iOS, ConnectionService on Android).
    // Works even when app is backgrounded or screen is locked.
    debugPrint('[FCM] Showing native CallKit UI...');
    await CallKitService.instance.showIncomingCall(
      callId: callId,
      callerName: callerName,
      callerAvatarUrl: callerAvatarUrl,
      type: type,
      callerId: callerId,
    );
    debugPrint('[FCM] ✓ CallKit shown, navigating to IncomingCallFlowScreen (mounted=${navigator.mounted})');
    if (!navigator.mounted) return;
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => IncomingCallFlowScreen(
          currentUserId: userId,
          authToken: authToken,
          incoming: incoming,
        ),
      ),
    );
  }

  Future<void> _openChat(Map<String, dynamic> data, NavigatorState navigator) async {
    final convId = _intFrom(data, 'conversation_id') ?? _intFrom(data, 'conversationId');
    if (convId != null && convId > 0 && navigator.mounted) {
      navigator.pushNamed('/chat/$convId');
    }
  }

  /// Opens digest screen.
  void _openDigest(Map<String, dynamic> data, NavigatorState navigator) {
    if (navigator.mounted) {
      navigator.pushNamed('/digest');
    }
  }

  /// Opens gossip thread from notification.
  void _openThread(Map<String, dynamic> data, NavigatorState navigator) {
    final threadId = _intFrom(data, 'thread_id');
    if (threadId != null && threadId > 0 && navigator.mounted) {
      navigator.pushNamed('/thread/$threadId');
    } else if (navigator.mounted) {
      navigator.pushNamed('/feed');
    }
  }

  /// Opens profile for streak/report/milestone notifications.
  Future<void> _openProfile(Map<String, dynamic> data, NavigatorState navigator) async {
    final userId = await _currentUserId();
    if (userId != null && navigator.mounted) {
      navigator.pushNamed('/profile/$userId');
    }
  }

  /// Opens weekly report screen.
  Future<void> _openWeeklyReport(Map<String, dynamic> data, NavigatorState navigator) async {
    final userId = await _currentUserId();
    if (userId != null && navigator.mounted) {
      navigator.pushNamed('/weekly-report/$userId');
    }
  }

  void _openBattle(Map<String, dynamic> data, NavigatorState navigator) {
    final battleId = _intFrom(data, 'battle_id');
    if (battleId != null && battleId > 0 && navigator.mounted) {
      navigator.pushNamed('/battle/$battleId');
    }
  }

  /// Shows milestone overlay.
  void _showMilestone(Map<String, dynamic> data, NavigatorState navigator) {
    final milestoneText = data['milestone'] as String? ?? data['message'] as String? ?? '';
    if (milestoneText.isEmpty) return;
    final context = navigator.context;
    MilestoneOverlay.show(context, milestone: milestoneText);
  }

  int? _intFrom(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v is int) return v;
    if (v != null) return int.tryParse(v.toString());
    return null;
  }

  Future<int?> _currentUserId() async {
    final storage = await LocalStorageService.getInstance();
    return storage.getUser()?.userId;
  }

  /// Process initial message (app opened from terminated state by tapping notification).
  void processPendingInitialMessage() {
    final msg = _pendingInitialMessage;
    if (msg == null) return;
    _pendingInitialMessage = null;
    final navigator = _navigatorKey?.currentState;
    if (navigator != null) _handlePayload(msg.data, navigator);
  }

  /// Send FCM token to backend so it can target this device. Call after login.
  Future<void> sendTokenToBackend(int userId) async {
    // On iOS, APNS token must be available before getting FCM token.
    // It's provisioned asynchronously after launch — wait for it.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null) {
        // Wait briefly for APNS provisioning, then retry once
        await Future.delayed(const Duration(seconds: 3));
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          if (kDebugMode) debugPrint('[FCM] APNS token not available yet, skipping FCM registration');
          return;
        }
      }
    }
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;
    try {
      final storage = await LocalStorageService.getInstance();
      final authToken = storage.getAuthToken();
      if (authToken == null) return;
      final url = Uri.parse('${ApiConfig.baseUrl}/users/$userId/fcm-token');
      final response = await http.post(
        url,
        headers: {...ApiConfig.authHeaders(authToken), 'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'token': fcmToken,
          'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        }),
      );
      if (kDebugMode) debugPrint('[FCM] Token registered for user $userId (${response.statusCode})');
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] Token registration failed: $e');
    }
  }
}
