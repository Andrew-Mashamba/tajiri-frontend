import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import '../DataStore.dart';

/// Service for handling chat-specific push notifications
class ChatNotificationService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _chatChannelId = 'chat_messages';
  static const String _chatChannelName = 'Chat Messages';
  static const String _chatChannelDesc = 'Notifications for new chat messages';

  // Callback for when a notification is tapped
  static Function(String conversationId)? onNotificationTapped;

  /// Initialize the chat notification service
  static Future<void> initialize() async {
    _logger.i('Initializing ChatNotificationService...');

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      _chatChannelId,
      _chatChannelName,
      description: _chatChannelDesc,
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Set up FCM message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Check if app was opened from a notification
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }

    _logger.i('ChatNotificationService initialized');
  }

  /// Handle foreground messages - show local notification
  static void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('Received foreground chat message');

    final data = message.data;

    // Check if this is a chat message
    if (data['type'] != 'chat_message') return;

    final conversationId = data['conversation_id'];
    final senderId = data['sender_id'];

    // Don't show notification for own messages
    if (senderId == DataStore.currentUserId) return;

    // Don't show if user is viewing the same conversation
    // This would require tracking current open conversation
    // For now, we'll show all notifications

    final senderName = data['sender_name'] ?? 'New Message';
    final messageContent = message.notification?.body ?? data['content'] ?? '';
    final messageType = data['message_type'] ?? 'text';

    // Format message preview based on type
    String preview;
    switch (messageType) {
      case 'image':
        preview = 'Picha';
        break;
      case 'file':
        preview = 'Faili';
        break;
      default:
        preview = messageContent;
    }

    _showLocalNotification(
      title: senderName,
      body: preview,
      payload: conversationId,
    );
  }

  /// Handle background messages - navigate to chat
  static void _handleBackgroundMessage(RemoteMessage message) {
    _logger.i('Handling background chat message tap');

    final data = message.data;

    if (data['type'] != 'chat_message') return;

    final conversationId = data['conversation_id'];
    if (conversationId != null && onNotificationTapped != null) {
      onNotificationTapped!(conversationId);
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    _logger.i('Chat notification tapped');

    final conversationId = response.payload;
    if (conversationId != null && onNotificationTapped != null) {
      onNotificationTapped!(conversationId);
    }
  }

  /// Show a local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _chatChannelId,
      _chatChannelName,
      channelDescription: _chatChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      category: AndroidNotificationCategory.message,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );

    _logger.i('Local notification shown: $title');
  }

  /// Show a notification for a new message (can be called manually)
  static Future<void> showNewMessageNotification({
    required String senderName,
    required String message,
    required String conversationId,
    String? senderAvatarUrl,
  }) async {
    await _showLocalNotification(
      title: senderName,
      body: message,
      payload: conversationId,
    );
  }

  /// Cancel all chat notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Cancel notifications for a specific conversation
  static Future<void> cancelNotificationsForConversation(String conversationId) async {
    // This would require tracking notification IDs per conversation
    // For now, we don't have this capability
  }

  /// Update badge count (iOS)
  static Future<void> updateBadgeCount(int count) async {
    // iOS badge count update would go here
  }
}

/// Background message handler for FCM (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This handler is called when a message is received while the app is in the background
  // We don't need to show a notification here as FCM will handle it automatically
  // Just log it for debugging
  final data = message.data;
  if (data['type'] == 'chat_message') {
    // Could store pending messages locally here for offline support
  }
}
