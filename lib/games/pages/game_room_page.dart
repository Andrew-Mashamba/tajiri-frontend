// lib/games/pages/game_room_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../core/game_definition.dart';
import '../core/game_enums.dart';
import '../models/game_session.dart';
import '../services/games_service.dart';
import '../services/game_socket_service.dart';
import 'game_play_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Waiting room: polls until opponent joins, then countdown to game start.
class GameRoomPage extends StatefulWidget {
  final GameSession session;
  final GameDefinition definition;
  final int userId;

  const GameRoomPage({
    super.key,
    required this.session,
    required this.definition,
    required this.userId,
  });

  @override
  State<GameRoomPage> createState() => _GameRoomPageState();
}

class _GameRoomPageState extends State<GameRoomPage> {
  final GamesService _service = GamesService();
  GameSocketService? _socketService;
  Timer? _elapsedTimer;
  Timer? _countdownTimer;

  late GameSession _session;
  int _elapsedSeconds = 0;
  int _countdown = 0;
  bool _isCancelling = false;

  int get _timeoutSeconds =>
      widget.session.mode == GameMode.ranked ? 60 : 300;

  @override
  void initState() {
    super.initState();
    _session = widget.session;

    // If practice mode, skip waiting — go directly
    if (_session.mode == GameMode.practice) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startCountdown());
      return;
    }

    // If opponent already assigned, skip to countdown
    if (_session.player2Id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startCountdown());
      return;
    }

    _startSocketPolling();
    _startElapsedTimer();
  }

  @override
  void dispose() {
    _socketService?.dispose();
    _elapsedTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Use GameSocketService for opponent-join detection (single polling source).
  void _startSocketPolling() {
    _socketService = GameSocketService();

    _socketService!.onPlayerJoined = (data) {
      if (!mounted) return;
      setState(() {});
      _socketService?.disconnect();
      _elapsedTimer?.cancel();
      _startCountdown();
    };

    _socketService!.onGameEnded = (data) {
      if (!mounted) return;
      _socketService?.disconnect();
      _elapsedTimer?.cancel();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Session cancelled')),
      );
    };

    _socketService!.connect(_session.id);
  }

  void _startElapsedTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);

      // Timeout check
      if (_elapsedSeconds >= _timeoutSeconds) {
        _onTimeout();
      }
    });
  }

  void _startCountdown() {
    setState(() => _countdown = 3);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown <= 0) {
        _countdownTimer?.cancel();
        _navigateToGame();
      }
    });
  }

  void _navigateToGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GamePlayPage(
          session: _session,
          definition: widget.definition,
          userId: widget.userId,
        ),
      ),
    );
  }

  void _onTimeout() async {
    _socketService?.disconnect();
    _elapsedTimer?.cancel();

    // Cancel the session and refund escrow on timeout
    await _service.endGame(
      _session.id,
      player1Score: 0,
      player2Score: 0,
    );
    if (_session.stakeAmount > 0) {
      await _service.refundEscrow(sessionId: _session.id);
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Timed out waiting for opponent / Muda umekwisha'),
      ),
    );
  }

  Future<void> _cancelSession() async {
    if (_isCancelling) return;
    setState(() => _isCancelling = true);

    _socketService?.disconnect();
    _elapsedTimer?.cancel();

    // End the session with no winner (draw/cancel)
    await _service.endGame(
      _session.id,
      player1Score: 0,
      player2Score: 0,
    );

    // Refund escrow if this was a staked game
    if (_session.stakeAmount > 0) {
      await _service.refundEscrow(sessionId: _session.id);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  String _formatElapsed() {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Waiting Room'),
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _cancelSession,
        ),
      ),
      body: _countdown > 0
          ? _buildCountdown()
          : _buildWaitingRoom(),
    );
  }

  Widget _buildCountdown() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Game Starting!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kPrimary.withValues(alpha: 0.06),
              border: Border.all(color: _kPrimary, width: 3),
            ),
            child: Center(
              child: Text(
                '$_countdown',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingRoom() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // ─── Two player cards side by side ────────────────────
          Row(
            children: [
              // Player 1 (you)
              Expanded(
                child: _PlayerSlot(
                  label: 'You',
                  sublabel: 'Wewe',
                  filled: true,
                  icon: Icons.person_rounded,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kSecondary,
                  ),
                ),
              ),
              // Player 2 (waiting)
              Expanded(
                child: _PlayerSlot(
                  label: _session.player2Id != null ? 'Opponent' : 'Waiting...',
                  sublabel: _session.player2Id != null ? 'Mpinzani' : 'Subiri...',
                  filled: _session.player2Id != null,
                  icon: _session.player2Id != null
                      ? Icons.person_rounded
                      : Icons.hourglass_top_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Status
          if (_session.player2Id == null) ...[
            const CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
            const SizedBox(height: 16),
            const Text(
              'Waiting for opponent...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Inasubiri mpinzani...',
              style: TextStyle(fontSize: 13, color: _kSecondary),
            ),
          ],

          const SizedBox(height: 24),

          // Elapsed timer
          Text(
            _formatElapsed(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Timeout: ${_timeoutSeconds}s',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
          ),

          // Room code
          if (_session.roomCode != null && _session.roomCode!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Room Code',
                    style: TextStyle(fontSize: 12, color: _kSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _session.roomCode!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                      color: _kPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),

          // Cancel button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _isCancelling ? null : _cancelSession,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCancelling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFEF4444),
                      ),
                    )
                  : const Text(
                      'Cancel / Sitisha',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PlayerSlot extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool filled;
  final IconData icon;

  const _PlayerSlot({
    required this.label,
    required this.sublabel,
    required this.filled,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: filled ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled ? _kPrimary.withValues(alpha: 0.2) : Colors.grey.shade200,
          width: filled ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: filled
                ? _kPrimary.withValues(alpha: 0.1)
                : Colors.grey.shade200,
            child: Icon(
              icon,
              size: 24,
              color: filled ? _kPrimary : _kSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
              color: filled ? _kPrimary : _kSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            sublabel,
            style: const TextStyle(fontSize: 11, color: _kSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
