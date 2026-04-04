// Video & Audio Calls — WebSocket channel (docs/video-audio-calls, 1.F.3)
// Subscribes to private-call.{callId} for CallIncoming, CallAccepted, CallRejected,
// CallEnded, SignalingOffer, SignalingAnswer, SignalingIceCandidate.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';

class CallChannelService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  String? _socketId;
  String? _currentCallId;
  bool _subscribed = false;

  // Reconnection state
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  String? _lastAuthToken;
  int? _lastUserId;

  final StreamController<CallIncomingEvent> _callIncomingController =
      StreamController<CallIncomingEvent>.broadcast();
  final StreamController<CallAcceptedEvent> _callAcceptedController =
      StreamController<CallAcceptedEvent>.broadcast();
  final StreamController<CallRejectedEvent> _callRejectedController =
      StreamController<CallRejectedEvent>.broadcast();
  final StreamController<CallEndedEvent> _callEndedController =
      StreamController<CallEndedEvent>.broadcast();
  final StreamController<SignalingOfferEvent> _signalingOfferController =
      StreamController<SignalingOfferEvent>.broadcast();
  final StreamController<SignalingAnswerEvent> _signalingAnswerController =
      StreamController<SignalingAnswerEvent>.broadcast();
  final StreamController<SignalingIceCandidateEvent> _signalingIceController =
      StreamController<SignalingIceCandidateEvent>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<CallReactionEvent> _callReactionController =
      StreamController<CallReactionEvent>.broadcast();
  final StreamController<RaiseHandEvent> _raiseHandController =
      StreamController<RaiseHandEvent>.broadcast();
  final StreamController<ParticipantAddedEvent> _participantAddedController =
      StreamController<ParticipantAddedEvent>.broadcast();

  Stream<CallIncomingEvent> get onCallIncoming => _callIncomingController.stream;
  Stream<CallAcceptedEvent> get onCallAccepted => _callAcceptedController.stream;
  Stream<CallRejectedEvent> get onCallRejected => _callRejectedController.stream;
  Stream<CallEndedEvent> get onCallEnded => _callEndedController.stream;
  Stream<SignalingOfferEvent> get onSignalingOffer => _signalingOfferController.stream;
  Stream<SignalingAnswerEvent> get onSignalingAnswer => _signalingAnswerController.stream;
  Stream<SignalingIceCandidateEvent> get onSignalingIceCandidate =>
      _signalingIceController.stream;
  Stream<bool> get onConnection => _connectionController.stream;
  Stream<CallReactionEvent> get onCallReaction => _callReactionController.stream;
  Stream<RaiseHandEvent> get onRaiseHand => _raiseHandController.stream;
  Stream<ParticipantAddedEvent> get onParticipantAdded => _participantAddedController.stream;

  bool get isConnected => _channel != null && _socketId != null;
  bool get isSubscribed => _subscribed;
  String? get currentCallId => _currentCallId;

  /// Connect and subscribe to private-call.{callId}.
  /// [wsUrl] — Reverb WebSocket URL (e.g. ApiConfig.reverbWsUrl). If null, only REST is used.
  /// [authToken] — Bearer token for /broadcasting/auth.
  Future<bool> subscribe({
    required String callId,
    String? wsUrl,
    String? authToken,
    int? userId,
  }) async {
    _lastAuthToken = authToken;
    _lastUserId = userId;
    wsUrl ??= ApiConfig.reverbWsUrl ?? ApiConfig.reverbWsUrlResolved;
    if (wsUrl == null || wsUrl.isEmpty) {
      debugPrint('[CallFlow][WS] ✗ No WebSocket URL');
      return false;
    }

    if (_currentCallId == callId && _subscribed) return true;

    await disconnect();

    final subscriptionCompleter = Completer<bool>();

    try {
      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _currentCallId = callId;

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
            if (_socketId != null) {
              final auth = await _authChannel('private-call.$callId', authToken, userId);
              if (auth != null && auth.isNotEmpty && _channel != null) {
                _channel!.sink.add(jsonEncode({
                  'event': 'pusher:subscribe',
                  'data': {
                    'channel': 'private-call.$callId',
                    'auth': auth,
                  },
                }));
              } else {
                debugPrint('[CallFlow][WS] ✗ Channel auth failed — cannot subscribe');
                if (!subscriptionCompleter.isCompleted) subscriptionCompleter.complete(false);
              }
            }
            return;
          }
          if (event == 'pusher_internal:subscription_succeeded') {
            debugPrint('[CallFlow][WS] ✓ Subscribed to private-call.$callId');
            _subscribed = true;
            _reconnectAttempts = 0;
            _startPingTimer();
            if (!subscriptionCompleter.isCompleted) {
              subscriptionCompleter.complete(true);
            }
            return;
          }
          if (event == 'pusher:error') {
            debugPrint('[CallFlow][WS] ✗ Pusher error: ${decoded['data']}');
          }
          _handleMessage(msg);
        } catch (e) {
          debugPrint('[CallFlow][WS] ✗ Message parse error: $e');
        }
      }, onError: (e) {
        debugPrint('[CallFlow][WS] ✗ WebSocket error: $e');
        _connectionController.add(false);
        if (!subscriptionCompleter.isCompleted) {
          subscriptionCompleter.complete(false);
        }
        _scheduleReconnect();
      }, onDone: () {
        debugPrint('[CallFlow][WS] WebSocket closed (onDone)');
        _connectionController.add(false);
        _subscribed = false;
        if (!subscriptionCompleter.isCompleted) {
          subscriptionCompleter.complete(false);
        }
        _scheduleReconnect();
      }, cancelOnError: false);

      _connectionController.add(true);

      return subscriptionCompleter.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[CallFlow][WS] ✗ Subscription timeout (10s)');
          if (!subscriptionCompleter.isCompleted) subscriptionCompleter.complete(false);
          return false;
        },
      );
    } catch (e) {
      debugPrint('[CallFlow][WS] ✗ WebSocket connect FAILED: $e');
      await disconnect();
      return false;
    }
  }

  Future<String?> _authChannel(String channelName, String? authToken, int? userId) async {
    if (_socketId == null) return null;
    final url = '${ApiConfig.baseUrl}/broadcasting/auth';
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      final body = <String, dynamic>{
        'socket_id': _socketId,
        'channel_name': channelName,
      };
      if (userId != null) body['user_id'] = userId;
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['auth'] != null) {
          return data['auth'] as String;
        }
        debugPrint('[CallFlow][WS] ✗ _authChannel: 200 but no auth in body');
      } else {
        debugPrint('[CallFlow][WS] ✗ _authChannel: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[CallFlow][WS] ✗ _authChannel exception: $e');
    }
    return null;
  }

  /// Map backend dot-notation event names to PascalCase.
  static const _eventNameMap = <String, String>{
    'call.incoming': 'CallIncoming',
    'call.accepted': 'CallAccepted',
    'call.rejected': 'CallRejected',
    'call.ended': 'CallEnded',
    'signaling.offer': 'SignalingOffer',
    'signaling.answer': 'SignalingAnswer',
    'signaling.ice_candidate': 'SignalingIceCandidate',
    'call.reaction': 'CallReaction',
    'raise.hand': 'RaiseHand',
    'participant.added': 'ParticipantAdded',
    'call_state_changed': 'CallStateChanged',
  };

  static String _normalizeEventName(String event) =>
      _eventNameMap[event] ?? event;

  void _handleMessage(dynamic message) {
    try {
      final decoded = jsonDecode(message as String) as Map<String, dynamic>;
      final event = decoded['event'] as String? ?? '';
      dynamic data = decoded['data'];

      if (event == 'pusher_internal:subscription_succeeded') {
        return;
      }
      if (event.startsWith('pusher:') || event.startsWith('pusher_internal:')) {
        debugPrint('[CallFlow][WS] Internal event: $event');
        return;
      }

      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }
      final payload = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

      // Normalize event names: backend uses dot-notation (e.g. 'call.incoming'),
      // map to PascalCase for backward compatibility.
      final normalizedEvent = _normalizeEventName(event);

      switch (normalizedEvent) {
        case 'CallIncoming':
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
          break;
        case 'CallAccepted':
          _callAcceptedController.add(CallAcceptedEvent(
            callId: payload['call_id']?.toString() ?? '',
            acceptedByUserId: payload['accepted_by_user_id'] as int? ?? 0,
            acceptedAt: payload['accepted_at'] != null
                ? DateTime.tryParse(payload['accepted_at'].toString())
                : null,
            sdpAnswer: payload['sdp_answer'] is Map
                ? Map<String, dynamic>.from(payload['sdp_answer'] as Map<String, dynamic>)
                : null,
          ));
          break;
        case 'CallRejected':
          _callRejectedController.add(CallRejectedEvent(
            callId: payload['call_id']?.toString() ?? '',
            rejectedByUserId: payload['rejected_by_user_id'] as int? ?? 0,
            rejectedAt: payload['rejected_at'] != null
                ? DateTime.tryParse(payload['rejected_at'].toString())
                : null,
          ));
          break;
        case 'CallEnded':
          _callEndedController.add(CallEndedEvent(
            callId: payload['call_id']?.toString() ?? '',
            endedByUserId: payload['ended_by_user_id'] as int? ?? 0,
            endedAt: payload['ended_at'] != null
                ? DateTime.tryParse(payload['ended_at'].toString())
                : null,
            reason: payload['reason']?.toString(),
          ));
          break;
        case 'SignalingOffer':
          final sdp = payload['sdp'];
          _signalingOfferController.add(SignalingOfferEvent(
            callId: payload['call_id']?.toString() ?? '',
            fromUserId: payload['from_user_id'] as int? ?? 0,
            sdp: sdp is Map ? Map<String, dynamic>.from(sdp) : null,
          ));
          break;
        case 'SignalingAnswer':
          final sdp = payload['sdp'];
          _signalingAnswerController.add(SignalingAnswerEvent(
            callId: payload['call_id']?.toString() ?? '',
            fromUserId: payload['from_user_id'] as int? ?? 0,
            sdp: sdp is Map ? Map<String, dynamic>.from(sdp) : null,
          ));
          break;
        case 'SignalingIceCandidate':
          final candidate = payload['candidate'];
          _signalingIceController.add(SignalingIceCandidateEvent(
            callId: payload['call_id']?.toString() ?? '',
            fromUserId: payload['from_user_id'] as int? ?? 0,
            candidate: candidate is Map
                ? Map<String, dynamic>.from(candidate as Map<String, dynamic>)
                : null,
          ));
          break;
        case 'CallReaction':
          _callReactionController.add(CallReactionEvent(
            callId: payload['call_id']?.toString() ?? '',
            fromUserId: payload['from_user_id'] as int? ?? 0,
            fromUserName: payload['from_user_name']?.toString(),
            emoji: payload['emoji']?.toString() ?? '👍',
            sentAt: payload['sent_at'] != null
                ? DateTime.tryParse(payload['sent_at'].toString())
                : null,
          ));
          break;
        case 'RaiseHand':
          _raiseHandController.add(RaiseHandEvent(
            callId: payload['call_id']?.toString() ?? '',
            userId: payload['user_id'] as int? ?? 0,
            raised: payload['raised'] == true,
          ));
          break;
        case 'ParticipantAdded':
          _participantAddedController.add(ParticipantAddedEvent(
            callId: payload['call_id']?.toString() ?? '',
            userId: payload['user_id'] as int? ?? 0,
            userName: payload['user_name']?.toString(),
            userAvatarUrl: payload['user_avatar_url']?.toString(),
          ));
          break;
        default:
          break;
      }
    } catch (_) {}
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[CallFlow][WS] ✗ Max reconnect attempts ($_maxReconnectAttempts) reached — giving up');
      return;
    }
    if (_currentCallId == null) {
      debugPrint('[CallFlow][WS] No active callId — skipping reconnect');
      return;
    }
    final delay = Duration(seconds: 2 * (_reconnectAttempts + 1));
    _reconnectAttempts++;
    debugPrint('[CallFlow][WS] Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_currentCallId != null) {
        debugPrint('[CallFlow][WS] Reconnecting...');
        subscribe(
          callId: _currentCallId!,
          authToken: _lastAuthToken,
          userId: _lastUserId,
        );
      }
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_channel != null) {
        _channel!.sink.add(jsonEncode({'event': 'pusher:ping', 'data': {}}));
      }
    });
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    await _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscription = null;
    _socketId = null;
    _currentCallId = null;
    _subscribed = false;
    _reconnectAttempts = 0;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    _callIncomingController.close();
    _callAcceptedController.close();
    _callRejectedController.close();
    _callEndedController.close();
    _signalingOfferController.close();
    _signalingAnswerController.close();
    _signalingIceController.close();
    _connectionController.close();
    _callReactionController.close();
    _raiseHandController.close();
    _participantAddedController.close();
  }
}

class ParticipantAddedEvent {
  final String callId;
  final int userId;
  final String? userName;
  final String? userAvatarUrl;

  ParticipantAddedEvent({
    required this.callId,
    required this.userId,
    this.userName,
    this.userAvatarUrl,
  });
}

class CallReactionEvent {
  final String callId;
  final int fromUserId;
  final String? fromUserName;
  final String emoji;
  final DateTime? sentAt;

  CallReactionEvent({
    required this.callId,
    required this.fromUserId,
    this.fromUserName,
    required this.emoji,
    this.sentAt,
  });
}

class RaiseHandEvent {
  final String callId;
  final int userId;
  final bool raised;

  RaiseHandEvent({
    required this.callId,
    required this.userId,
    required this.raised,
  });
}

// Event DTOs
/// Incoming call from WebSocket or FCM. Same flat fields: call_id, caller_id, caller_name, caller_avatar_url, type.
/// [isGroupAdd]: when true (backend sends ongoing: true), user is already in a call and this is a participant-added; else 1:1 incoming.
class CallIncomingEvent {
  final String callId;
  final int callerId;
  final String callerName;
  final String? callerAvatarUrl;
  final String type;
  final DateTime? createdAt;
  /// True when backend sends ongoing: true (group-add to existing call); false = new 1:1 incoming.
  final bool isGroupAdd;

  CallIncomingEvent({
    required this.callId,
    required this.callerId,
    required this.callerName,
    this.callerAvatarUrl,
    required this.type,
    this.createdAt,
    this.isGroupAdd = false,
  });
}

class CallAcceptedEvent {
  final String callId;
  final int acceptedByUserId;
  final DateTime? acceptedAt;
  final Map<String, dynamic>? sdpAnswer;

  CallAcceptedEvent({
    required this.callId,
    required this.acceptedByUserId,
    this.acceptedAt,
    this.sdpAnswer,
  });
}

class CallRejectedEvent {
  final String callId;
  final int rejectedByUserId;
  final DateTime? rejectedAt;

  CallRejectedEvent({
    required this.callId,
    required this.rejectedByUserId,
    this.rejectedAt,
  });
}

class CallEndedEvent {
  final String callId;
  final int endedByUserId;
  final DateTime? endedAt;
  final String? reason;

  CallEndedEvent({
    required this.callId,
    required this.endedByUserId,
    this.endedAt,
    this.reason,
  });
}

class SignalingOfferEvent {
  final String callId;
  final int fromUserId;
  final Map<String, dynamic>? sdp;

  SignalingOfferEvent({
    required this.callId,
    required this.fromUserId,
    this.sdp,
  });
}

class SignalingAnswerEvent {
  final String callId;
  final int fromUserId;
  final Map<String, dynamic>? sdp;

  SignalingAnswerEvent({
    required this.callId,
    required this.fromUserId,
    this.sdp,
  });
}

class SignalingIceCandidateEvent {
  final String callId;
  final int fromUserId;
  final Map<String, dynamic>? candidate;

  SignalingIceCandidateEvent({
    required this.callId,
    required this.fromUserId,
    this.candidate,
  });
}
