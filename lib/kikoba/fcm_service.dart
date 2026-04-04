import 'dart:ui' show Color;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'HttpService.dart';
import 'DataStore.dart';
import 'pages/VotingListScreen.dart';
import 'pages/VotingDetailScreens.dart';

/// Service class to handle Firebase Cloud Messaging operations
class FCMService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Callback for navigation when notification is tapped
  static void Function(Map<String, dynamic> data)? onNotificationTap;

  // Global navigator key for navigation without context
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Topic name format matching backend
  static String _getTopicName(String kikobaId) {
    return 'kikoba_${kikobaId.replaceAll('-', '_')}';
  }

  /// Initialize notifications - call this in main.dart
  static Future<void> initialize() async {
    try {
      _logger.i('Initializing FCM Service...');

      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.i('User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        _logger.i('User granted provisional notification permission');
      } else {
        _logger.w('User declined notification permission');
      }

      // Initialize local notifications for foreground
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      await _createNotificationChannel();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background/terminated notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _logger.i('App opened from notification');
        _handleNotificationTap(initialMessage);
      }

      _logger.i('FCM Service initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('Error initializing FCM', error: e, stackTrace: stackTrace);
    }
  }

  /// Create notification channel for Android
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'voting_channel',
      'Voting Notifications',
      description: 'Notifications for voting on kikoba matters',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Get FCM token and send it to the server
  static Future<void> updateFCMToken() async {
    try {
      _logger.i('Requesting FCM token...');

      // Get the FCM token
      String? fcmToken = await _messaging.getToken();

      if (fcmToken != null) {
        _logger.i('FCM Token retrieved successfully');
        _logger.d('Token: ${fcmToken.substring(0, 20)}...');

        // Send token to server
        await _sendTokenToServer(fcmToken);
      } else {
        _logger.w('Failed to get FCM token');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _logger.i('FCM token refreshed');
        _sendTokenToServer(newToken);
      });

    } catch (e, stackTrace) {
      _logger.e('Error updating FCM token', error: e, stackTrace: stackTrace);
    }
  }

  /// Send FCM token to server
  static Future<void> _sendTokenToServer(String fcmToken) async {
    try {
      if (DataStore.currentUserId == null || DataStore.currentUserId!.isEmpty) {
        _logger.w('User ID not available, skipping token update');
        return;
      }

      _logger.i('Sending FCM token to server...');

      String result = await HttpService.updateFCMToken(fcmToken);

      _logger.i('FCM token update response: $result');

      if (result == 'success') {
        _logger.i('FCM token successfully saved to server');
      } else {
        _logger.w('FCM token update returned: $result');
      }
    } catch (e, stackTrace) {
      _logger.e('Error sending token to server', error: e, stackTrace: stackTrace);
    }
  }

  /// Subscribe to a kikoba's notifications
  static Future<void> subscribeToKikoba(String kikobaId) async {
    try {
      String topic = _getTopicName(kikobaId);
      await _messaging.subscribeToTopic(topic);
      _logger.i('✅ Subscribed to topic: $topic');
    } catch (e) {
      _logger.e('Error subscribing to kikoba: $e');
    }
  }

  /// Unsubscribe from a kikoba's notifications
  static Future<void> unsubscribeFromKikoba(String kikobaId) async {
    try {
      String topic = _getTopicName(kikobaId);
      await _messaging.unsubscribeFromTopic(topic);
      _logger.i('🚫 Unsubscribed from topic: $topic');
    } catch (e) {
      _logger.e('Error unsubscribing from kikoba: $e');
    }
  }

  /// Subscribe to all user's kikobas
  static Future<void> subscribeToAllKikobas(List<String> kikobaIds) async {
    _logger.i('Subscribing to ${kikobaIds.length} kikoba topics...');
    for (String kikobaId in kikobaIds) {
      await subscribeToKikoba(kikobaId);
    }
    _logger.i('Subscribed to all kikoba topics');
  }

  /// Unsubscribe from all kikobas
  static Future<void> unsubscribeFromAllKikobas(List<String> kikobaIds) async {
    _logger.i('Unsubscribing from ${kikobaIds.length} kikoba topics...');
    for (String kikobaId in kikobaIds) {
      await unsubscribeFromKikoba(kikobaId);
    }
    _logger.i('Unsubscribed from all kikoba topics');
  }

  /// Handle foreground messages - show local notification
  static void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('📬 Foreground message received');
    _logger.d('Title: ${message.notification?.title}');
    _logger.d('Body: ${message.notification?.body}');
    _logger.d('Data: ${message.data}');

    RemoteNotification? notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'voting_channel',
            'Voting Notifications',
            channelDescription: 'Notifications for voting on kikoba matters',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFF6B4EAA),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: _encodePayload(message.data),
      );
    }
  }

  /// Handle notification tap (background/terminated)
  static void _handleNotificationTap(RemoteMessage message) {
    _logger.i('👆 Notification tapped');
    _logger.d('Data: ${message.data}');
    _navigateBasedOnData(message.data.cast<String, dynamic>());
  }

  /// Handle local notification tap (foreground)
  static void _onNotificationTapped(NotificationResponse response) {
    _logger.i('👆 Local notification tapped');
    if (response.payload != null) {
      Map<String, dynamic> data = _decodePayload(response.payload!);
      _navigateBasedOnData(data);
    }
  }

  /// Navigate based on notification data
  static void _navigateBasedOnData(Map<String, dynamic> data) {
    _logger.i('Processing notification navigation...');
    _logger.d('Action: ${data['action']}');
    _logger.d('Type: ${data['type']}');
    _logger.d('Kikoba ID: ${data['kikoba_id']}');

    // Call the custom navigation callback if set
    if (onNotificationTap != null) {
      onNotificationTap!(data);
      return;
    }

    // Default navigation handling
    final action = data['action']?.toString();
    final type = data['type']?.toString();
    final kikobaId = data['kikoba_id']?.toString();
    final requestId = data['request_id']?.toString();

    // Check if we have a navigator key for navigation
    if (navigatorKey?.currentState == null) {
      _logger.w('No navigator key set, cannot navigate');
      return;
    }

    final navigator = navigatorKey!.currentState!;

    // Handle loan_application_voting type (from notification payload)
    final applicationId = data['application_id']?.toString();

    if (type == 'loan_application_voting' && applicationId != null) {
      navigator.push(MaterialPageRoute(
        builder: (context) => LoanApplicationVotingScreen(
          kikobaId: kikobaId,
          applicationId: applicationId,
        ),
      ));
      return;
    }

    if (action == 'vote' && kikobaId != null) {
      // Navigate to appropriate voting screen based on type
      switch (type) {
        case 'membership_request':
          navigator.push(MaterialPageRoute(
            builder: (context) => MembershipRequestVotingScreen(
              kikobaId: kikobaId,
              requestId: requestId,
            ),
          ));
          break;

        case 'membership_removal_request':
        case 'membership_removal':
          navigator.push(MaterialPageRoute(
            builder: (context) => MembershipRemovalVotingScreen(
              kikobaId: kikobaId,
              requestId: requestId,
            ),
          ));
          break;

        case 'expense_request':
          navigator.push(MaterialPageRoute(
            builder: (context) => ExpenseRequestVotingScreen(
              kikobaId: kikobaId,
              requestId: requestId,
            ),
          ));
          break;

        case 'katiba_change_request':
        case 'katiba_change':
          navigator.push(MaterialPageRoute(
            builder: (context) => KatibaChangeVotingScreen(
              kikobaId: kikobaId,
              requestId: requestId,
            ),
          ));
          break;

        case 'fine_approval_request':
        case 'fine_approval':
          navigator.push(MaterialPageRoute(
            builder: (context) => FineApprovalVotingScreen(
              kikobaId: kikobaId,
              requestId: requestId,
            ),
          ));
          break;

        case 'loan_application':
        case 'loan_application_voting':
          navigator.push(MaterialPageRoute(
            builder: (context) => LoanApplicationVotingScreen(
              kikobaId: kikobaId,
              applicationId: requestId ?? applicationId,
            ),
          ));
          break;

        default:
          // Navigate to general voting list screen
          navigator.push(MaterialPageRoute(
            builder: (context) => VotingListScreen(
              kikobaId: kikobaId,
              initialType: type,
            ),
          ));
          break;
      }
    } else if (kikobaId != null) {
      // No specific action, just open voting list for this kikoba
      navigator.push(MaterialPageRoute(
        builder: (context) => VotingListScreen(kikobaId: kikobaId),
      ));
    } else {
      _logger.w('Not enough data to navigate');
    }
  }

  /// Set navigation callback - call this from your main app
  static void setNotificationTapHandler(void Function(Map<String, dynamic> data) handler) {
    onNotificationTap = handler;
    _logger.i('Notification tap handler set');
  }

  /// Set navigator key for default navigation handling
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
    _logger.i('Navigator key set');
  }

  static String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  static Map<String, dynamic> _decodePayload(String payload) {
    Map<String, dynamic> data = {};
    payload.split('&').forEach((item) {
      var parts = item.split('=');
      if (parts.length == 2) {
        data[parts[0]] = parts[1];
      }
    });
    return data;
  }

  /// Initialize FCM listeners for foreground messages (legacy - kept for compatibility)
  static void initializeFCMListeners() {
    _logger.i('FCM listeners initialized via initialize() method');
  }
}
