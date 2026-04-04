// Persistent WebSocket subscription to private-user.{userId} for receiving
// incoming call events when the app is in the foreground.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import '../calls/call_channel_service.dart'; // for CallIncomingEvent
import 'local_storage_service.dart';

class UserChannelService {
  UserChannelService._();
  static final UserChannelService instance = UserChannelService._();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  String? _socketId;
  bool _subscribed = false;
  int? _userId;
  String? _authToken;
  Timer? _reconnectTimer;

  final StreamController<CallIncomingEvent> _callIncomingController =
      StreamController<CallIncomingEvent>.broadcast();

  Stream<CallIncomingEvent> get onCallIncoming => _callIncomingController.stream;
  bool get isConnected => _channel != null && _socketId != null;

  /// Map backend dot-notation event names to PascalCase.
  static const _eventNameMap = <String, String>{
    'call.incoming': 'CallIncoming',
  };

  /// Start persistent subscription to private-user.{userId}.
  /// Fetches auth token from local storage if not provided.
  Future<void> start({required int userId, String? authToken}) async {
    if (_subscribed && _userId == userId) return; // already running
    _userId = userId;
    if (authToken != null && authToken.isNotEmpty) {
      _authToken = authToken;
    } else {
      final storage = await LocalStorageService.getInstance();
      _authToken = storage.getAuthToken();
    }
    await _connect();
  }

  Future<void> _connect() async {
    final userId = _userId;
    if (userId == null) return;

    await _disconnect(reconnect: false);

    final wsUrl = ApiConfig.reverbWsUrl ?? ApiConfig.reverbWsUrlResolved;
    if (wsUrl == null || wsUrl.isEmpty) {
      debugPrint('[UserChannel] No WebSocket URL — cannot subscribe');
      return;
    }

    try {
      final uri = Uri.parse(wsUrl);
      debugPrint('[UserChannel] Connecting to $uri for user $userId');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      debugPrint('[UserChannel] ✓ Connected');

      _subscription = _channel!.stream.listen((msg) async {
        try {
          final decoded = jsonDecode(msg as String) as Map<String, dynamic>;
          final event = decoded['event'] as String? ?? '';

          if (event == 'pusher:connection_established') {
            final data = decoded['data'];
            if (data is String) {
              final dataMap = jsonDecode(data) as Map<String, dynamic>;
              _socketId = dataMap['socket_id'] as String?;
            } else if (data is Map) {
              _socketId = data['socket_id'] as String?;
            }
            debugPrint('[UserChannel] socketId=$_socketId');
            if (_socketId != null) {
              final channelName = 'private-user.$userId';
              final auth = await _authChannel(channelName);
              if (auth != null && auth.isNotEmpty && _channel != null) {
                _channel!.sink.add(jsonEncode({
                  'event': 'pusher:subscribe',
                  'data': {
                    'channel': channelName,
                    'auth': auth,
                  },
                }));
                debugPrint('[UserChannel] → Sent pusher:subscribe for $channelName');
              }
            }
            return;
          }

          if (event == 'pusher_internal:subscription_succeeded') {
            _subscribed = true;
            debugPrint('[UserChannel] ✓ Subscribed to private-user.$userId');
            return;
          }

          if (event == 'pusher:pong') return; // suppress pong noise
          if (event.startsWith('pusher:') || event.startsWith('pusher_internal:')) {
            debugPrint('[UserChannel] Internal event: $event');
            return;
          }

          // Handle call.incoming event
          debugPrint('[UserChannel] ← Event: $event, data keys: ${decoded['data'] is Map ? (decoded['data'] as Map).keys.toList() : 'string'}');
          _handleEvent(event, decoded);
        } catch (e) {
          debugPrint('[UserChannel] ✗ Parse error: $e');
        }
      }, onError: (e) {
        debugPrint('[UserChannel] ✗ WebSocket error: $e');
        _scheduleReconnect();
      }, onDone: () {
        debugPrint('[UserChannel] WebSocket closed');
        _subscribed = false;
        _scheduleReconnect();
      }, cancelOnError: false);
    } catch (e) {
      debugPrint('[UserChannel] ✗ Connect failed: $e');
      _scheduleReconnect();
    }
  }

  void _handleEvent(String event, Map<String, dynamic> decoded) {
    final normalized = _eventNameMap[event] ?? event;
    if (normalized != 'CallIncoming') return;

    dynamic data = decoded['data'];
    if (data is String) {
      try { data = jsonDecode(data); } catch (_) {}
    }
    final payload = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    debugPrint('[UserChannel] ← CallIncoming: callId=${payload['call_id']}, caller=${payload['caller_name']}');

    _callIncomingController.add(CallIncomingEvent(
      callId: payload['call_id']?.toString() ?? '',
      callerId: payload['caller_id'] as int? ?? 0,
      callerName: payload['caller_name']?.toString() ?? '',
      callerAvatarUrl: payload['caller_avatar_url']?.toString(),
      type: payload['type']?.toString() ?? 'voice',
      createdAt: payload['created_at'] != null
          ? DateTime.tryParse(payload['created_at'].toString())
          : null,
      isGroupAdd: payload['ongoing'] == true,
    ));
  }

  Future<String?> _authChannel(String channelName) async {
    if (_socketId == null) return null;
    final url = '${ApiConfig.baseUrl}/broadcasting/auth';
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (_authToken != null && _authToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_authToken';
      }
      final body = <String, dynamic>{
        'socket_id': _socketId,
        'channel_name': channelName,
      };
      if (_userId != null) body['user_id'] = _userId;
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      debugPrint('[UserChannel] Auth response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['auth'] != null) {
          return data['auth'] as String;
        }
      }
    } catch (e) {
      debugPrint('[UserChannel] ✗ Auth error: $e');
    }
    return null;
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_userId != null) _connect();
    });
  }

  Future<void> _disconnect({bool reconnect = false}) async {
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscription = null;
    _socketId = null;
    _subscribed = false;
  }

  Future<void> stop() async {
    _userId = null;
    _authToken = null;
    await _disconnect();
  }

  void dispose() {
    stop();
    _callIncomingController.close();
  }
}
