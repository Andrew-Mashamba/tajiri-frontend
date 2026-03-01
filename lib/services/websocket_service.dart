import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../config/api_config.dart';
import '../models/livestream_models.dart';

/// WebSocket service for real-time livestream updates
/// Handles: viewer counts, comments, gifts, reactions, status changes
class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  bool _isConnected = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  int? _currentStreamId;
  int? _currentUserId;
  String? _pusherUrl;
  String? _pusherChannel;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  // Stream controllers for different event types
  final _viewerCountController = StreamController<Map<String, dynamic>>.broadcast();
  final _commentController = StreamController<StreamComment>.broadcast();
  final _giftController = StreamController<GiftEvent>.broadcast();
  final _reactionController = StreamController<ReactionEvent>.broadcast();
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  /// Emits a user-friendly message when connection fails (e.g. not upgraded, max retries).
  /// UI should show this and hint: "If your session has ended, please log in again."
  final _connectionErrorController = StreamController<String>.broadcast();

  // Advanced features stream controllers
  final _pollController = StreamController<PollEvent>.broadcast();
  final _pollVoteController = StreamController<PollVoteEvent>.broadcast();
  final _questionController = StreamController<QuestionEvent>.broadcast();
  final _questionUpvoteController = StreamController<QuestionUpvoteEvent>.broadcast();
  final _superChatController = StreamController<SuperChatEvent>.broadcast();
  final _battleController = StreamController<BattleEvent>.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get viewerCountStream => _viewerCountController.stream;
  Stream<StreamComment> get commentStream => _commentController.stream;
  Stream<GiftEvent> get giftStream => _giftController.stream;
  Stream<ReactionEvent> get reactionStream => _reactionController.stream;
  Stream<Map<String, dynamic>> get streamStatusStream => _statusController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<String> get connectionErrorStream => _connectionErrorController.stream;

  // Advanced features streams
  Stream<PollEvent> get pollStream => _pollController.stream;
  Stream<PollVoteEvent> get pollVoteStream => _pollVoteController.stream;
  Stream<QuestionEvent> get questionStream => _questionController.stream;
  Stream<QuestionUpvoteEvent> get questionUpvoteStream => _questionUpvoteController.stream;
  Stream<SuperChatEvent> get superChatStream => _superChatController.stream;
  Stream<BattleEvent> get battleStream => _battleController.stream;

  bool get isConnected => _isConnected;

  /// Connect to WebSocket for global streams updates (for viewer grid)
  Future<void> connect(int userId) async {
    if (_isConnected) {
      print('[WebSocket] Already connected');
      return;
    }

    try {
      _shouldReconnect = true;
      _reconnectAttempts = 0;

      // Construct WebSocket URL for global streams channel
      final wsUrl = ApiConfig.baseUrl
          .replaceAll('https://', 'wss://')
          .replaceAll('http://', 'ws://')
          .replaceAll('/api', '');

      final uri = Uri.parse('$wsUrl/streams/all?user_id=$userId');

      print('[WebSocket] 🔌 Connecting to global streams channel: $uri');
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;

      _isConnected = true;
      _connectionController.add(true);
      print('[WebSocket] ✅ Connected to global streams channel');

      // Start listening to messages
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      // Start heartbeat to keep connection alive
      _startHeartbeat();

      // Reset reconnect attempts on successful connection
      _reconnectAttempts = 0;
    } catch (e) {
      print('[WebSocket] ❌ Connection error: $e');
      _isConnected = false;
      _connectionController.add(false);
      _scheduleReconnectGlobal(userId);
    }
  }

  /// Schedule reconnection for global channel
  void _scheduleReconnectGlobal(int userId) {
    if (!_shouldReconnect || _reconnectAttempts >= _maxReconnectAttempts) {
      print('[WebSocket] Max reconnection attempts reached or reconnection disabled');
      return;
    }

    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts;

    print('[WebSocket] Scheduling reconnection attempt $_reconnectAttempts in ${delay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      connect(userId);
    });
  }

  /// Connect using Pusher-compatible URL and channel from API (GET /streams/{id} or join response).
  /// Use this instead of connectToStream when you have websocket.url and websocket.channel from the backend.
  Future<void> connectToPusher(String wsUrl, String channel) async {
    if (_isConnected && _pusherUrl == wsUrl && _pusherChannel == channel) {
      return;
    }
    if (_isConnected) {
      await disconnect();
    }

    try {
      _shouldReconnect = true;
      _reconnectAttempts = 0;
      _pusherUrl = wsUrl;
      _pusherChannel = channel;
      _currentStreamId = null;
      _currentUserId = null;

      final uri = Uri.parse(wsUrl);
      print('Connecting to WebSocket (Pusher): $uri, channel: $channel');
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;

      _isConnected = true;

      // Subscribe to channel (Pusher protocol)
      _channel!.sink.add(jsonEncode({
        'event': 'pusher:subscribe',
        'data': {'channel': channel},
      }));

      _connectionController.add(true);
      print('WebSocket (Pusher) connected, subscribed to $channel');

      _subscription = _channel!.stream.listen(
        _handlePusherMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _startHeartbeat();
      _reconnectAttempts = 0;
    } catch (e) {
      print('WebSocket (Pusher) connection error: $e');
      _isConnected = false;
      _pusherUrl = null;
      _pusherChannel = null;
      _connectionController.add(false);
      _connectionErrorController.add(_userFriendlyConnectionError(e));
      _scheduleReconnectPusher();
    }
  }

  void _handlePusherMessage(dynamic message) {
    try {
      final decoded = jsonDecode(message as String) as Map<String, dynamic>;
      final event = decoded['event'] as String? ?? '';
      dynamic data = decoded['data'];

      // Internal Pusher events — ignore or log
      if (event == 'pusher:connection_established' || event.startsWith('pusher_internal:')) {
        return;
      }

      // App events: data may be JSON string
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }
      _handleMessage(jsonEncode({'event': event, 'data': data}));
    } catch (e) {
      print('Error parsing Pusher message: $e');
    }
  }

  void _scheduleReconnectPusher() {
    if (!_shouldReconnect || _pusherUrl == null || _pusherChannel == null || _reconnectAttempts >= _maxReconnectAttempts) {
      if (_reconnectAttempts >= _maxReconnectAttempts) {
        _connectionErrorController.add('max_reconnect_reached');
      }
      return;
    }
    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts;
    print('Scheduling reconnection attempt $_reconnectAttempts in ${delay.inSeconds}s');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      connectToPusher(_pusherUrl!, _pusherChannel!);
    });
  }

  /// Connect to WebSocket for a specific stream (legacy: builds URL from ApiConfig).
  /// Prefer connectToPusher(websocket.url, websocket.channel) when API returns websocket object.
  Future<void> connectToStream(int streamId, int userId) async {
    if (_isConnected && _currentStreamId == streamId && _currentUserId == userId) {
      return;
    }
    if (_isConnected) {
      await disconnect();
    }

    try {
      _shouldReconnect = true;
      _reconnectAttempts = 0;
      _currentStreamId = streamId;
      _currentUserId = userId;
      _pusherUrl = null;
      _pusherChannel = null;

      final wsUrl = ApiConfig.baseUrl
          .replaceAll('https://', 'wss://')
          .replaceAll('http://', 'ws://')
          .replaceAll('/api', '');
      final uri = Uri.parse('$wsUrl/streams/$streamId?user_id=$userId');

      print('Connecting to WebSocket: $uri');
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;

      _isConnected = true;
      _connectionController.add(true);
      print('WebSocket connected successfully');

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _startHeartbeat();
      _reconnectAttempts = 0;
    } catch (e) {
      print('WebSocket connection error: $e');
      _isConnected = false;
      _currentStreamId = null;
      _currentUserId = null;
      _connectionController.add(false);
      _connectionErrorController.add(_userFriendlyConnectionError(e));
      _scheduleReconnect(streamId, userId);
    }
  }

  /// Map raw connection errors to a message the UI can show (e.g. "not upgraded" → session/network hint).
  static String _userFriendlyConnectionError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('not upgraded') || s.contains('websocket') || s.contains('101')) {
      return 'connection_not_upgraded';
    }
    if (s.contains('401') || s.contains('unauthorized') || s.contains('403') || s.contains('forbidden')) {
      return 'session_invalid';
    }
    return 'connection_failed';
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final event = data['event'] as String;
      final payload = data['data'];

      switch (event) {
        case 'viewer_count_updated':
          // Send as Map for flexibility
          _viewerCountController.add({
            'current_viewers': payload['current_viewers'] as int,
            'peak_viewers': payload['peak_viewers'] as int,
            'stream_id': payload['stream_id'],
            'viewers_count': payload['viewers_count'],
            'timestamp': DateTime.now().toIso8601String(),
          });
          break;

        case 'new_comment':
          final comment = StreamComment.fromJson(payload);
          _commentController.add(comment);
          break;

        case 'gift_sent':
          final giftEvent = GiftEvent(
            sender: payload['sender'] != null ? StreamUser.fromJson(payload['sender']) : null,
            gift: VirtualGift.fromJson(payload['gift']),
            quantity: payload['quantity'] as int? ?? 1,
            message: payload['message'] as String?,
            timestamp: DateTime.now(),
          );
          _giftController.add(giftEvent);
          break;

        case 'reaction':
          final reactionEvent = ReactionEvent(
            userId: payload['user_id'] as int,
            reactionType: payload['reaction_type'] as String,
            timestamp: DateTime.now(),
          );
          _reactionController.add(reactionEvent);
          break;

        case 'status_changed':
          // Backend sends: stream_id, old_status, status, started_at, ended_at, duration, playback_url, timestamp
          _statusController.add({
            'stream_id': payload['stream_id'],
            'old_status': payload['old_status'] as String?,
            'new_status': payload['status'] as String?,
            'status': payload['status'] as String?,
            'started_at': payload['started_at'] as String?,
            'ended_at': payload['ended_at'] as String?,
            'duration': payload['duration'],
            'playback_url': payload['playback_url'] as String?,
            'timestamp': payload['timestamp'] as String? ?? DateTime.now().toIso8601String(),
          });
          break;

        case 'pong':
          // Heartbeat response - connection is alive
          print('Heartbeat acknowledged');
          break;

        // ==================== POLL EVENTS ====================
        case 'poll_created':
          final pollEvent = PollEvent(
            pollId: payload['poll_id'] as int,
            question: payload['question'] as String,
            options: (payload['options'] as List).map((opt) => PollOptionData(
              id: opt['id'] as int,
              text: opt['text'] as String,
              votes: opt['votes'] as int? ?? 0,
            )).toList(),
            createdBy: payload['created_by'] as int,
            timestamp: DateTime.now(),
          );
          _pollController.add(pollEvent);
          break;

        case 'poll_vote':
          final voteEvent = PollVoteEvent(
            pollId: payload['poll_id'] as int,
            optionId: payload['option_id'] as int,
            userId: payload['user_id'] as int,
            votes: payload['votes'] as int,
            timestamp: DateTime.now(),
          );
          _pollVoteController.add(voteEvent);
          break;

        case 'poll_closed':
          final pollEvent = PollEvent(
            pollId: payload['poll_id'] as int,
            question: payload['question'] as String,
            options: (payload['options'] as List).map((opt) => PollOptionData(
              id: opt['id'] as int,
              text: opt['text'] as String,
              votes: opt['votes'] as int? ?? 0,
            )).toList(),
            createdBy: payload['created_by'] as int,
            isClosed: true,
            timestamp: DateTime.now(),
          );
          _pollController.add(pollEvent);
          break;

        // ==================== Q&A EVENTS ====================
        case 'question_submitted':
          final questionEvent = QuestionEvent(
            questionId: payload['question_id'] as int,
            userId: payload['user_id'] as int,
            username: payload['username'] as String,
            question: payload['question'] as String,
            upvotes: payload['upvotes'] as int? ?? 0,
            isAnswered: payload['is_answered'] as bool? ?? false,
            timestamp: DateTime.now(),
          );
          _questionController.add(questionEvent);
          break;

        case 'question_upvoted':
          final upvoteEvent = QuestionUpvoteEvent(
            questionId: payload['question_id'] as int,
            upvotes: payload['upvotes'] as int,
            timestamp: DateTime.now(),
          );
          _questionUpvoteController.add(upvoteEvent);
          break;

        case 'question_answered':
          final questionEvent = QuestionEvent(
            questionId: payload['question_id'] as int,
            userId: payload['user_id'] as int,
            username: payload['username'] as String,
            question: payload['question'] as String,
            upvotes: payload['upvotes'] as int? ?? 0,
            isAnswered: true,
            timestamp: DateTime.now(),
          );
          _questionController.add(questionEvent);
          break;

        // ==================== SUPER CHAT EVENTS ====================
        case 'super_chat_sent':
          final superChatEvent = SuperChatEvent(
            userId: payload['user_id'] as int,
            username: payload['username'] as String,
            message: payload['message'] as String,
            amount: (payload['amount'] as num).toDouble(),
            tier: _parseSuperChatTier(payload['tier'] as String),
            duration: payload['duration'] as int? ?? 5,
            timestamp: DateTime.now(),
          );
          _superChatController.add(superChatEvent);
          break;

        // ==================== BATTLE MODE EVENTS ====================
        case 'battle_invite':
          final battleEvent = BattleEvent(
            type: BattleEventType.invite,
            battleId: payload['battle_id'] as int,
            opponentId: payload['opponent_id'] as int,
            opponentName: payload['opponent_name'] as String,
            timestamp: DateTime.now(),
          );
          _battleController.add(battleEvent);
          break;

        case 'battle_accepted':
          final battleEvent = BattleEvent(
            type: BattleEventType.accepted,
            battleId: payload['battle_id'] as int,
            opponentId: payload['opponent_id'] as int,
            opponentName: payload['opponent_name'] as String,
            timestamp: DateTime.now(),
          );
          _battleController.add(battleEvent);
          break;

        case 'battle_score_update':
          final battleEvent = BattleEvent(
            type: BattleEventType.scoreUpdate,
            battleId: payload['battle_id'] as int,
            myScore: payload['my_score'] as int,
            opponentScore: payload['opponent_score'] as int,
            timestamp: DateTime.now(),
          );
          _battleController.add(battleEvent);
          break;

        case 'battle_ended':
          final battleEvent = BattleEvent(
            type: BattleEventType.ended,
            battleId: payload['battle_id'] as int,
            winnerId: payload['winner_id'] as int?,
            myScore: payload['my_score'] as int,
            opponentScore: payload['opponent_score'] as int,
            timestamp: DateTime.now(),
          );
          _battleController.add(battleEvent);
          break;

        case 'pusher:error':
          final Object? code = payload is Map<String, dynamic>
              ? (payload['code'] ?? payload['message'] ?? payload['data'])
              : payload;
          print('WebSocket Pusher error: $code');
          _connectionErrorController.add('pusher_error');
          break;

        case 'pusher:connection_established':
        case 'pusher_internal:subscription_succeeded':
          break;

        default:
          if (!event.startsWith('pusher') && !event.startsWith('pusher_internal')) {
            print('Unknown WebSocket event: $event');
          }
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  /// Handle WebSocket errors
  void _handleError(error) {
    print('WebSocket error: $error');
    _isConnected = false;
    _connectionController.add(false);
  }

  /// Handle WebSocket disconnect
  void _handleDisconnect() {
    print('WebSocket disconnected');
    _isConnected = false;
    _connectionController.add(false);
    _stopHeartbeat();

    if (_shouldReconnect) {
      if (_pusherUrl != null && _pusherChannel != null) {
        _scheduleReconnectPusher();
      } else {
        print('WebSocket disconnected - caller should handle reconnection');
      }
    }
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect(int streamId, int userId) {
    if (!_shouldReconnect || _reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnection attempts reached or reconnection disabled');
      _connectionErrorController.add('max_reconnect_reached');
      return;
    }

    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts;

    print('Scheduling reconnection attempt $_reconnectAttempts in ${delay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      connectToStream(streamId, userId);
    });
  }

  /// Send a message through WebSocket
  void send(String event, Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) {
      print('Cannot send message - WebSocket not connected');
      return;
    }

    try {
      final message = jsonEncode({
        'event': event,
        'data': data,
      });
      _channel!.sink.add(message);
    } catch (e) {
      print('Error sending WebSocket message: $e');
    }
  }

  // ==================== HELPER METHODS FOR SENDING EVENTS ====================

  /// Send a reaction to the stream
  void sendReaction(String reactionType) {
    send('reaction', {'reaction_type': reactionType});
  }

  /// Create a poll
  void createPoll(String question, List<String> options) {
    send('create_poll', {
      'question': question,
      'options': options,
    });
  }

  /// Vote on a poll
  void votePoll(int pollId, int optionId) {
    send('vote_poll', {
      'poll_id': pollId,
      'option_id': optionId,
    });
  }

  /// Close a poll (broadcaster only)
  void closePoll(int pollId) {
    send('close_poll', {'poll_id': pollId});
  }

  /// Submit a question (Q&A mode)
  void submitQuestion(String question) {
    send('submit_question', {'question': question});
  }

  /// Upvote a question
  void upvoteQuestion(int questionId) {
    send('upvote_question', {'question_id': questionId});
  }

  /// Mark question as answered (broadcaster only)
  void answerQuestion(int questionId) {
    send('answer_question', {'question_id': questionId});
  }

  /// Send super chat
  void sendSuperChat(String message, double amount) {
    send('send_super_chat', {
      'message': message,
      'amount': amount,
    });
  }

  /// Invite to battle
  void inviteBattle(int opponentStreamId) {
    send('invite_battle', {'opponent_stream_id': opponentStreamId});
  }

  /// Accept battle invitation
  void acceptBattle(int battleId) {
    send('accept_battle', {'battle_id': battleId});
  }

  /// Decline battle invitation
  void declineBattle(int battleId) {
    send('decline_battle', {'battle_id': battleId});
  }

  /// Helper to parse super chat tier
  String _parseSuperChatTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'low':
        return 'low';
      case 'medium':
        return 'medium';
      case 'high':
        return 'high';
      default:
        return 'low';
    }
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_isConnected) {
        send('ping', {'timestamp': DateTime.now().toIso8601String()});
      }
    });
  }

  /// Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    print('Disconnecting WebSocket');
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _stopHeartbeat();

    await _subscription?.cancel();
    await _channel?.sink.close(status.normalClosure);

    _channel = null;
    _subscription = null;
    _isConnected = false;
    _currentStreamId = null;
    _currentUserId = null;
    _pusherUrl = null;
    _pusherChannel = null;
    _connectionController.add(false);
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    _viewerCountController.close();
    _commentController.close();
    _giftController.close();
    _reactionController.close();
    _statusController.close();
    _connectionController.close();
    _connectionErrorController.close();
    _pollController.close();
    _pollVoteController.close();
    _questionController.close();
    _questionUpvoteController.close();
    _superChatController.close();
    _battleController.close();
  }
}

// Event models for WebSocket updates

class ViewerCountUpdate {
  final int currentViewers;
  final int peakViewers;
  final DateTime timestamp;

  ViewerCountUpdate({
    required this.currentViewers,
    required this.peakViewers,
    required this.timestamp,
  });
}

class GiftEvent {
  final StreamUser? sender;
  final VirtualGift gift;
  final int quantity;
  final String? message;
  final DateTime timestamp;

  GiftEvent({
    this.sender,
    required this.gift,
    required this.quantity,
    this.message,
    required this.timestamp,
  });
}

class ReactionEvent {
  final int userId;
  final String reactionType;
  final DateTime timestamp;

  ReactionEvent({
    required this.userId,
    required this.reactionType,
    required this.timestamp,
  });
}

class StatusChangeEvent {
  final String oldStatus;
  final String newStatus;
  final DateTime timestamp;

  StatusChangeEvent({
    required this.oldStatus,
    required this.newStatus,
    required this.timestamp,
  });
}

// ==================== ADVANCED FEATURES EVENT MODELS ====================

/// Poll event (created or closed)
class PollEvent {
  final int pollId;
  final String question;
  final List<PollOptionData> options;
  final int createdBy;
  final bool isClosed;
  final DateTime timestamp;

  PollEvent({
    required this.pollId,
    required this.question,
    required this.options,
    required this.createdBy,
    this.isClosed = false,
    required this.timestamp,
  });

  int get totalVotes => options.fold(0, (sum, option) => sum + option.votes);
}

class PollOptionData {
  final int id;
  final String text;
  final int votes;

  PollOptionData({
    required this.id,
    required this.text,
    required this.votes,
  });

  double getPercentage(int totalVotes) {
    if (totalVotes == 0) return 0.0;
    return (votes / totalVotes) * 100;
  }
}

/// Poll vote event
class PollVoteEvent {
  final int pollId;
  final int optionId;
  final int userId;
  final int votes;
  final DateTime timestamp;

  PollVoteEvent({
    required this.pollId,
    required this.optionId,
    required this.userId,
    required this.votes,
    required this.timestamp,
  });
}

/// Question event (Q&A mode)
class QuestionEvent {
  final int questionId;
  final int userId;
  final String username;
  final String question;
  final int upvotes;
  final bool isAnswered;
  final DateTime timestamp;

  QuestionEvent({
    required this.questionId,
    required this.userId,
    required this.username,
    required this.question,
    required this.upvotes,
    required this.isAnswered,
    required this.timestamp,
  });
}

/// Question upvote event
class QuestionUpvoteEvent {
  final int questionId;
  final int upvotes;
  final DateTime timestamp;

  QuestionUpvoteEvent({
    required this.questionId,
    required this.upvotes,
    required this.timestamp,
  });
}

/// Super chat event
class SuperChatEvent {
  final int userId;
  final String username;
  final String message;
  final double amount;
  final String tier; // 'low', 'medium', 'high'
  final int duration; // seconds to display
  final DateTime timestamp;

  SuperChatEvent({
    required this.userId,
    required this.username,
    required this.message,
    required this.amount,
    required this.tier,
    required this.duration,
    required this.timestamp,
  });
}

/// Battle mode event types
enum BattleEventType {
  invite,
  accepted,
  declined,
  scoreUpdate,
  ended,
}

/// Battle event
class BattleEvent {
  final BattleEventType type;
  final int battleId;
  final int? opponentId;
  final String? opponentName;
  final int? myScore;
  final int? opponentScore;
  final int? winnerId;
  final DateTime timestamp;

  BattleEvent({
    required this.type,
    required this.battleId,
    this.opponentId,
    this.opponentName,
    this.myScore,
    this.opponentScore,
    this.winnerId,
    required this.timestamp,
  });
}
