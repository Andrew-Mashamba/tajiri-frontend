/// Battle Mode (PK Battle) Service - Real-time Competitive Streaming
/// Two streamers compete, viewers support with gifts, highest score wins
import 'dart:async';
import 'websocket_service.dart';

class BattleModeService {
  final WebSocketService _webSocketService;

  BattleModeService(this._webSocketService);

  // Battle state
  BattleState? _currentBattle;
  StreamSubscription? _battleSubscription;

  // Stream controllers
  final _battleStateController = StreamController<BattleState>.broadcast();
  final _battleInviteController = StreamController<BattleInvite>.broadcast();

  // Public streams
  Stream<BattleState> get battleStateStream => _battleStateController.stream;
  Stream<BattleInvite> get battleInviteStream => _battleInviteController.stream;

  // Getters
  BattleState? get currentBattle => _currentBattle;
  bool get isInBattle => _currentBattle != null && _currentBattle!.status == BattleStatus.active;

  /// Initialize battle mode and listen to events
  void initialize() {
    print('[BattleMode] Initializing battle mode service');

    _battleSubscription = _webSocketService.battleStream.listen((event) {
      _handleBattleEvent(event);
    });
  }

  /// Handle battle events from WebSocket
  void _handleBattleEvent(BattleEvent event) {
    print('[BattleMode] Received event: ${event.type}');

    switch (event.type) {
      case BattleEventType.invite:
        _handleBattleInvite(event);
        break;

      case BattleEventType.accepted:
        _handleBattleAccepted(event);
        break;

      case BattleEventType.declined:
        _handleBattleDeclined(event);
        break;

      case BattleEventType.scoreUpdate:
        _handleScoreUpdate(event);
        break;

      case BattleEventType.ended:
        _handleBattleEnded(event);
        break;
    }
  }

  /// Handle incoming battle invite
  void _handleBattleInvite(BattleEvent event) {
    final invite = BattleInvite(
      battleId: event.battleId,
      opponentId: event.opponentId!,
      opponentName: event.opponentName!,
      timestamp: event.timestamp,
    );

    _battleInviteController.add(invite);
    print('[BattleMode] Battle invite from: ${invite.opponentName}');
  }

  /// Handle battle accepted
  void _handleBattleAccepted(BattleEvent event) {
    _currentBattle = BattleState(
      battleId: event.battleId,
      opponentId: event.opponentId!,
      opponentName: event.opponentName!,
      myScore: 0,
      opponentScore: 0,
      status: BattleStatus.active,
      startTime: DateTime.now(),
    );

    _battleStateController.add(_currentBattle!);
    print('[BattleMode] Battle started! ID: ${event.battleId}');
  }

  /// Handle battle declined
  void _handleBattleDeclined(BattleEvent event) {
    print('[BattleMode] Battle declined by opponent');
  }

  /// Handle score update during battle
  void _handleScoreUpdate(BattleEvent event) {
    if (_currentBattle == null) {
      print('[BattleMode] Score update received but no active battle');
      return;
    }

    _currentBattle = _currentBattle!.copyWith(
      myScore: event.myScore ?? _currentBattle!.myScore,
      opponentScore: event.opponentScore ?? _currentBattle!.opponentScore,
    );

    _battleStateController.add(_currentBattle!);
    print('[BattleMode] Score updated - Me: ${_currentBattle!.myScore}, Opponent: ${_currentBattle!.opponentScore}');
  }

  /// Handle battle ended
  void _handleBattleEnded(BattleEvent event) {
    if (_currentBattle == null) {
      print('[BattleMode] Battle ended but no active battle');
      return;
    }

    _currentBattle = _currentBattle!.copyWith(
      myScore: event.myScore ?? _currentBattle!.myScore,
      opponentScore: event.opponentScore ?? _currentBattle!.opponentScore,
      status: BattleStatus.ended,
      winnerId: event.winnerId,
      endTime: DateTime.now(),
    );

    _battleStateController.add(_currentBattle!);

    final isWinner = event.winnerId == null ? false : true; // TODO: Check against current user ID
    print('[BattleMode] Battle ended! Winner: ${isWinner ? "You" : "Opponent"}');

    // Clear battle after a delay
    Future.delayed(const Duration(seconds: 10), () {
      _currentBattle = null;
    });
  }

  /// Send battle invite to another streamer
  void inviteBattle(int opponentStreamId) {
    print('[BattleMode] Sending battle invite to stream: $opponentStreamId');
    _webSocketService.inviteBattle(opponentStreamId);
  }

  /// Accept battle invitation
  void acceptBattle(int battleId) {
    print('[BattleMode] Accepting battle: $battleId');
    _webSocketService.acceptBattle(battleId);
  }

  /// Decline battle invitation
  void declineBattle(int battleId) {
    print('[BattleMode] Declining battle: $battleId');
    _webSocketService.declineBattle(battleId);
  }

  /// Cancel/forfeit current battle
  void forfeitBattle() {
    if (_currentBattle == null) {
      print('[BattleMode] No active battle to forfeit');
      return;
    }

    print('[BattleMode] Forfeiting battle: ${_currentBattle!.battleId}');

    // Send forfeit event
    _webSocketService.send('forfeit_battle', {
      'battle_id': _currentBattle!.battleId,
    });

    // End battle immediately
    _currentBattle = _currentBattle!.copyWith(
      status: BattleStatus.ended,
      endTime: DateTime.now(),
    );

    _battleStateController.add(_currentBattle!);

    // Clear battle
    Future.delayed(const Duration(seconds: 3), () {
      _currentBattle = null;
    });
  }

  /// Get battle duration
  Duration? getBattleDuration() {
    if (_currentBattle == null || _currentBattle!.startTime == null) {
      return null;
    }

    final endTime = _currentBattle!.endTime ?? DateTime.now();
    return endTime.difference(_currentBattle!.startTime!);
  }

  /// Get score difference
  int getScoreDifference() {
    if (_currentBattle == null) return 0;
    return _currentBattle!.myScore - _currentBattle!.opponentScore;
  }

  /// Check if winning
  bool isWinning() {
    return getScoreDifference() > 0;
  }

  /// Get win percentage
  double getWinPercentage() {
    if (_currentBattle == null) return 0.5;

    final totalScore = _currentBattle!.myScore + _currentBattle!.opponentScore;
    if (totalScore == 0) return 0.5;

    return _currentBattle!.myScore / totalScore;
  }

  /// Dispose resources
  void dispose() {
    print('[BattleMode] Disposing battle mode service');
    _battleSubscription?.cancel();
    _battleStateController.close();
    _battleInviteController.close();
  }
}

// ==================== DATA MODELS ====================

/// Battle status
enum BattleStatus {
  pending,
  active,
  ended,
}

/// Battle state
class BattleState {
  final int battleId;
  final int opponentId;
  final String opponentName;
  final int myScore;
  final int opponentScore;
  final BattleStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? winnerId;

  BattleState({
    required this.battleId,
    required this.opponentId,
    required this.opponentName,
    required this.myScore,
    required this.opponentScore,
    required this.status,
    this.startTime,
    this.endTime,
    this.winnerId,
  });

  BattleState copyWith({
    int? battleId,
    int? opponentId,
    String? opponentName,
    int? myScore,
    int? opponentScore,
    BattleStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    int? winnerId,
  }) {
    return BattleState(
      battleId: battleId ?? this.battleId,
      opponentId: opponentId ?? this.opponentId,
      opponentName: opponentName ?? this.opponentName,
      myScore: myScore ?? this.myScore,
      opponentScore: opponentScore ?? this.opponentScore,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      winnerId: winnerId ?? this.winnerId,
    );
  }

  Duration? get duration {
    if (startTime == null) return null;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
  }

  int get totalScore => myScore + opponentScore;

  double get myPercentage {
    if (totalScore == 0) return 0.5;
    return myScore / totalScore;
  }

  double get opponentPercentage {
    if (totalScore == 0) return 0.5;
    return opponentScore / totalScore;
  }

  bool get isWinning => myScore > opponentScore;

  int get scoreDifference => myScore - opponentScore;
}

/// Battle invite
class BattleInvite {
  final int battleId;
  final int opponentId;
  final String opponentName;
  final DateTime timestamp;

  BattleInvite({
    required this.battleId,
    required this.opponentId,
    required this.opponentName,
    required this.timestamp,
  });
}
