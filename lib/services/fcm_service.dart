// FCM: foreground/background/opened handlers. Payload contract: new_message -> open chat; call_incoming -> open incoming call screen.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tajiri/calls/call_channel_service.dart';
import 'package:tajiri/screens/calls/incoming_call_flow_screen.dart';
import 'local_storage_service.dart';

class FcmService {
  static final FcmService instance = FcmService._();
  FcmService._();

  static GlobalKey<NavigatorState>? _navigatorKey;
  static void setNavigatorKey(GlobalKey<NavigatorState>? key) {
    _navigatorKey = key;
  }

  RemoteMessage? _pendingInitialMessage;

  Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission();
    final token = await FirebaseMessaging.instance.getToken();
    if (kDebugMode && token != null) debugPrint('[FCM] Token: $token');

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _pendingInitialMessage = initial;
  }

  void _onForegroundMessage(RemoteMessage message) {
    if (kDebugMode) debugPrint('[FCM] Foreground: ${message.messageId}');
    _handlePayload(message.data, _navigatorKey?.currentState);
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
  }

  /// Opens new incoming call flow (IncomingCallFlowScreen + CallSignalingService).
  /// Payload (same flat fields as WebSocket): call_id, caller_id, caller_name, caller_avatar_url, type (voice|video).
  /// type must be "call_incoming" for routing. ongoing: true = group-add (user already in call); else 1:1.
  Future<void> _openIncomingCall(Map<String, dynamic> data, NavigatorState navigator) async {
    final callId = data['call_id'] as String? ?? data['callId'] as String?;
    if (callId == null || callId.isEmpty) return;
    final userId = await _currentUserId();
    if (userId == null) return;
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
    final incoming = CallIncomingEvent(
      callId: callId,
      callerId: callerId,
      callerName: callerName,
      callerAvatarUrl: callerAvatarUrl,
      type: type,
      createdAt: createdAt,
      isGroupAdd: isGroupAdd,
    );
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
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    // TODO: POST to your backend e.g. POST /api/users/me/push-token or /api/devices
    if (kDebugMode) debugPrint('[FCM] Token for user $userId (register with backend): $token');
  }
}
